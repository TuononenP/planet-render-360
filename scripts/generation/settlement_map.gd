class_name SettlementMap
extends RefCounted

## T5.4 / T4.5 — where a place is built up, from real data only.
## A CELL_M grid around the viewpoint out to RADIUS_M scores each cell
## 0..1 as settlement from two free sources:
##  - far OSM built-up landuse (LocationData.far_landuse: residential /
##    commercial / industrial / retail polygons from FarCityFetcher's one
##    ring query): a score floor and the fabric class (industrial sheds
##    vs apartment blocks) imagery cannot tell;
##  - the far imagery drapes (LocationData.far_drapes, Esri ~12 m/px to
##    9.5 km, ~50 m/px beyond): per cell a SAMPLES² pixel probe gives
##    mean luminance L, greenness G = g − (r+b)/2 and luminance texture.
##    Esri mosaics carry a per-scene colour cast (Paris reads green-grey
##    everywhere), so cells are judged RELATIVE to the drape's own
##    medians L0/G0: built = less green than typical, not dark, busy
##    (roofs + streets + shadows); vegetation = greener than typical;
##    water / deep shadow = dark and not green. Calibrated on the Paris
##    z13 drape (inner city G 0.047 / L 0.37 / std 0.17, Bois de
##    Boulogne G 0.077 / L 0.28, Seine L 0.21, forest G 0.079 / std
##    0.06; medians L0 0.33, G0 0.05).
## Vegetation- or water-dominated cells are blocked outright (parks,
## forest, rivers, sea) even inside a landuse polygon. With neither
## source the map is empty — the distant city then does not continue
## (absence, never invented).

const CELL_M := 100.0
const RADIUS_M := 12000.0
const SAMPLES := 5
## OSM landuse floors under the imagery score.
const OSM_SCORE := {"residential": 0.5, "commercial": 0.75,
	"retail": 0.75, "industrial": 0.65}
enum Cls { NONE, RESIDENTIAL, COMMERCIAL, INDUSTRIAL }
const DRAPE_ONLY := 0.55

var n := 0
var half := 0
var score := PackedFloat32Array()
var cls := PackedByteArray()
## 0 open, 1 vegetation, 2 water / dark
var blocked := PackedByteArray()
## "drape+osm" | "drape" | "osm" | "" (no source → empty map)
var source := ""

static func build(data: LocationData) -> SettlementMap:
	var m := SettlementMap.new()
	m.half = int(ceil(RADIUS_M / CELL_M))
	m.n = m.half * 2
	m.score.resize(m.n * m.n)
	m.cls.resize(m.n * m.n)
	m.blocked.resize(m.n * m.n)
	var has_drape := false
	for d in data.far_drapes:
		if d is Dictionary and (d as Dictionary).get("image", null) is Image:
			has_drape = true
	if has_drape:
		m._from_drapes(data)
	var has_osm := not data.far_landuse.is_empty()
	if has_osm:
		var in_osm := m._from_landuse(data)
		# Where OSM maps landuse at all, imagery alone is weaker evidence
		# (dry grass, scree and rock read busy and un-green too): cells
		# outside every polygon keep DRAPE_ONLY of their imagery score.
		for k in m.score.size():
			if in_osm[k] == 0:
				m.score[k] *= DRAPE_ONLY
	m.source = ("drape" if has_drape else "") \
		+ ("+osm" if has_drape and has_osm else ("osm" if has_osm else ""))
	return m

func index(i: int, j: int) -> int:
	return j * n + i

## Cell (column i east, row j south) containing metre XZ; (-1,-1) outside.
func cell_of(x: float, z: float) -> Vector2i:
	var i := int(floor(x / CELL_M)) + half
	var j := int(floor(z / CELL_M)) + half
	if i < 0 or j < 0 or i >= n or j >= n:
		return Vector2i(-1, -1)
	return Vector2i(i, j)

func centre(i: int, j: int) -> Vector2:
	return Vector2((float(i - half) + 0.5) * CELL_M, (float(j - half) + 0.5) * CELL_M)

func score_at(x: float, z: float) -> float:
	var c := cell_of(x, z)
	return 0.0 if c.x < 0 else score[index(c.x, c.y)]

func class_at(x: float, z: float) -> int:
	var c := cell_of(x, z)
	return Cls.NONE if c.x < 0 else cls[index(c.x, c.y)]

func blocked_at(x: float, z: float) -> int:
	var c := cell_of(x, z)
	return 0 if c.x < 0 else blocked[index(c.x, c.y)]

func is_empty() -> bool:
	return source == ""

## Built score from cell features relative to the drape medians.
static func built_score(l: float, g: float, std: float, l0: float, g0: float) -> float:
	var not_green := clampf((g0 + 0.02 - g) / 0.03, 0.0, 1.0)
	var not_dark := clampf((l - 0.75 * l0) / maxf(0.25 * l0, 0.01), 0.0, 1.0)
	var busy := clampf((std - 0.06) / 0.06, 0.0, 1.0)
	return not_green * not_dark * busy

## 1 vegetation, 2 water/dark, 0 neither (relative to the medians;
## br = mean b − r flags bright lake/sea blue-cyan absolutely).
static func cover_of(l: float, g: float, l0: float, g0: float, br: float = 0.0) -> int:
	if br > 0.06:
		return 2
	if g > g0 + 0.025:
		return 1
	if l < 0.7 * l0 and g < g0 + 0.01:
		return 2
	return 0

## Cell features {l, g, std} from the finest drape covering metre XZ,
## plus the drape index, or {} where no drape covers it.
static func probe(data: LocationData, bytes: Array, x: float, z: float,
		size_m: float) -> Dictionary:
	for di in data.far_drapes.size():
		var d: Dictionary = data.far_drapes[di]
		var img: Variant = d.get("image", null)
		if not (img is Image):
			continue
		var uv := FarSurface.drape_uv(data, d, x, z)
		if uv.x <= 0.0 or uv.y <= 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
			continue
		var w := (img as Image).get_width()
		var h := (img as Image).get_height()
		var mpp := DemFetcher.metres_per_px(data.latitude, int(d["zoom"]))
		var step := size_m / float(SAMPLES) / maxf(mpp, 0.01)
		var px0 := uv.x * float(w) - step * float(SAMPLES - 1) * 0.5
		var pz0 := uv.y * float(h) - step * float(SAMPLES - 1) * 0.5
		var buf: PackedByteArray = bytes[di]
		var sl := 0.0
		var sl2 := 0.0
		var sg := 0.0
		var sbr := 0.0
		for sj in SAMPLES:
			var pz := clampi(int(pz0 + step * float(sj)), 0, h - 1)
			for si in SAMPLES:
				var px := clampi(int(px0 + step * float(si)), 0, w - 1)
				var o := (pz * w + px) * 3
				var r := float(buf[o]) / 255.0
				var g := float(buf[o + 1]) / 255.0
				var b := float(buf[o + 2]) / 255.0
				var l := 0.299 * r + 0.587 * g + 0.114 * b
				sl += l
				sl2 += l * l
				sg += g - (r + b) * 0.5
				sbr += b - r
		var k := float(SAMPLES * SAMPLES)
		var mean := sl / k
		return {"l": mean, "g": sg / k, "std": sqrt(maxf(sl2 / k - mean * mean, 0.0)),
			"br": sbr / k, "drape": di}
	return {}

## RGB8 byte views of the drapes (no per-pixel Color allocation).
static func drape_bytes(data: LocationData) -> Array:
	var out: Array = []
	for d in data.far_drapes:
		var img: Variant = (d as Dictionary).get("image", null)
		if img is Image and (img as Image).get_format() == Image.FORMAT_RGB8:
			out.append((img as Image).get_data())
		elif img is Image:
			var copy := (img as Image).duplicate() as Image
			copy.clear_mipmaps()
			copy.convert(Image.FORMAT_RGB8)
			out.append(copy.get_data())
		else:
			out.append(PackedByteArray())
	return out

func _from_drapes(data: LocationData) -> void:
	var bytes := drape_bytes(data)
	var feats := {}
	var ls := {}
	var gs := {}
	var r2 := RADIUS_M * RADIUS_M
	for j in n:
		for i in n:
			var c := centre(i, j)
			if c.length_squared() > r2:
				continue
			var p := probe(data, bytes, c.x, c.y, CELL_M)
			if p.is_empty():
				continue
			feats[index(i, j)] = p
			var di := int(p["drape"])
			if not ls.has(di):
				ls[di] = []
				gs[di] = []
			(ls[di] as Array).append(float(p["l"]))
			(gs[di] as Array).append(float(p["g"]))
	var l0 := {}
	var g0 := {}
	for di in ls:
		l0[di] = _median(ls[di])
		g0[di] = _median(gs[di])
	var raw := PackedFloat32Array()
	raw.resize(n * n)
	for k in feats:
		var p: Dictionary = feats[k]
		var di := int(p["drape"])
		var cover := cover_of(float(p["l"]), float(p["g"]), l0[di], g0[di],
			float(p["br"]))
		blocked[k] = cover
		if cover == 0:
			raw[k] = built_score(float(p["l"]), float(p["g"]), float(p["std"]),
				l0[di], g0[di])
	# 3x3 smoothing (blocked cells stay 0): settlements are contiguous,
	# a lone grey cluster in a field is not a town.
	for j in n:
		for i in n:
			var k := index(i, j)
			if blocked[k] != 0:
				continue
			var s := 0.0
			var w := 0.0
			for dj in range(-1, 2):
				for di in range(-1, 2):
					var ii := i + di
					var jj := j + dj
					if ii < 0 or jj < 0 or ii >= n or jj >= n:
						continue
					var wt := 4.0 if di == 0 and dj == 0 else 1.0
					s += raw[index(ii, jj)] * wt
					w += wt
			score[k] = s / w
			if score[k] > 0.0:
				cls[k] = Cls.RESIDENTIAL

static func _median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	a.sort()
	return float(a[a.size() / 2])

## Rasterises the landuse polygons; returns the per-cell "inside OSM
## landuse" mask.
func _from_landuse(data: LocationData) -> PackedByteArray:
	var in_osm := PackedByteArray()
	in_osm.resize(n * n)
	for poly in data.far_landuse:
		if not (poly is Dictionary):
			continue
		var pd := poly as Dictionary
		var pts: PackedVector2Array = pd.get("points", PackedVector2Array())
		if pts.size() < 3:
			continue
		var kind := str(pd.get("class", "residential"))
		var floor_s := float(OSM_SCORE.get(kind, 0.5))
		var c := Cls.INDUSTRIAL if kind == "industrial" \
			else (Cls.COMMERCIAL if kind in ["commercial", "retail"] else Cls.RESIDENTIAL)
		var bb := RingGeometry.aabb(pts)
		if bb.end.x < -RADIUS_M or bb.end.y < -RADIUS_M \
				or bb.position.x > RADIUS_M or bb.position.y > RADIUS_M:
			continue
		var i0 := clampi(int(floor(bb.position.x / CELL_M)) + half, 0, n - 1)
		var j0 := clampi(int(floor(bb.position.y / CELL_M)) + half, 0, n - 1)
		var i1 := clampi(int(floor(bb.end.x / CELL_M)) + half, 0, n - 1)
		var j1 := clampi(int(floor(bb.end.y / CELL_M)) + half, 0, n - 1)
		var holes: Array = pd.get("holes", [])
		for j in range(j0, j1 + 1):
			for i in range(i0, i1 + 1):
				var p := centre(i, j)
				if not Geometry2D.is_point_in_polygon(p, pts):
					continue
				var holed := false
				for hole in holes:
					if hole is PackedVector2Array \
							and Geometry2D.is_point_in_polygon(p, hole):
						holed = true
						break
				if holed:
					continue
				var k := index(i, j)
				in_osm[k] = 1
				# Imagery water/vegetation still wins: a river, park or
				# wood inside a landuse polygon stays open.
				if blocked[k] != 0:
					continue
				score[k] = maxf(score[k], floor_s)
				if c != Cls.RESIDENTIAL or cls[k] == Cls.NONE:
					cls[k] = c
	return in_osm
