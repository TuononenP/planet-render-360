class_name LandmarkChGermany
extends RefCounted

## Two German churches in true metres: the Munich Frauenkirche (brick
## Gothic hall of 1468-88, 109 x 40 m, walls about 37 m with the
## buttresses drawn inside, so the long walls are flat between very tall
## lancets; the very steep roof; the 98.6 m west towers (-X) square to
## the ridge, then octagonal, under the "welsche Hauben" of 1525) and
## the Dresden Frauenkirche (George Bahr, 1726-43, rebuilt 1994-2005:
## 50 x 42 m with cut corners holding four stair towers, the stone bell
## dome 26 m across rising from a concave skirt, lantern, gilt orb and
## cross at 91.2 m, choir apse to +X). The Berlin Cathedral is
## LandmarkChBerlin.

# --- Munich Frauenkirche ---

const MUNICH_TOP := 98.6
const MUNICH_EAVE := 37.0
const MUNICH_RISE := 29.0

static func munich(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B5654A", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CFC3A8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9B4A30", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5E8F78", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var e := MUNICH_EAVE
	# Hall: flat long walls to the eave, steep tiled roof, polygonal chevet.
	lm.box("Brick", Vector3(-10.0, e * 0.5, 0), Vector3(89.0, e, 40.0))
	lm.gable("Roof", Vector3(-10.0, e, 0), 40.0, 89.0, MUNICH_RISE, Basis(Vector3.UP, PI * 0.5), 0.5, "Brick")
	lm.lathe("Brick", Vector3(34.5, 0, 0), PackedVector2Array([Vector2(20.2, 0), Vector2(20.2, e)]), 10, 1.0, 1.0,
		0.0, false)
	lm.lathe("Roof", Vector3(34.5, e, 0), PackedVector2Array([Vector2(21.0, 0), Vector2(0.0, MUNICH_RISE)]), 10, 1.0,
		1.0, 0.0, false)
	LandmarkChParts.band(lm, "Stone", 0.0, 44.5, 20.0, 1.2, 0.3, Vector3(-10.0, 0, 0))
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		# Tuff frieze under the eave and a second one at a third of the height.
		LandmarkDetail.cornice(lm, "Stone", Vector3(-41.0, e - 1.0, sz * 20.0), Vector3(34.5, e - 1.0, sz * 20.0), n, 1.0,
			false)
		lm.box("Stone", Vector3(-3.0, 30.5, sz * 20.1), Vector3(76.0, 0.8, 0.4), Basis(), 0.0)
		for i in 12:
			var x := -36.0 + 6.0 * i
			LandmarkChParts.lancet(lm, "Stone", "Windows", Vector3(x, 5.0, sz * 20.0), n, 2.8, 24.5, 1, 0.3)
			# Brick lesenes between the windows (the buttresses are inside).
			lm.box("Brick", Vector3(x + 3.0, e * 0.5, sz * 20.25), Vector3(1.2, e - 1.0, 0.5))
		# Two side portals per long wall, with stone porches.
		for x in [-27.0, 15.0]:
			lm.box("Brick", Vector3(x, 4.5, sz * 21.5), Vector3(5.6, 9.0, 3.0))
			lm.gable("Roof", Vector3(x, 9.0, sz * 21.5), 5.6, 3.0, 3.2, Basis(), 0.25, "Brick")
			LandmarkChParts.lancet(lm, "Stone", "Windows", Vector3(x, 0.3, sz * 23.0), n, 2.6, 6.0, 1, 0.35)
			LandmarkChParts.wimperg(lm, "Stone", Vector3(x, 6.2, sz * 23.0), n, 3.6, 2.6, 0.25)
	for k in 10:
		var a := TAU * (float(k) + 0.5) / 10.0
		if cos(a) > 0.2:
			var d := Vector3(cos(a), 0, sin(a))
			LandmarkChParts.lancet(lm, "Stone", "Windows", Vector3(34.5, 5.0, 0) + d * 19.3, d, 2.8, 24.5, 1, 0.3)
	for k in 11:
		var a := TAU * float(k) / 10.0
		if cos(a) > -0.1:
			var q := Vector3(34.5 + cos(a) * 20.4, 0, sin(a) * 20.4)
			lm.box("Brick", q + Vector3(0, e * 0.5, 0), Vector3(1.4, e - 1.0, 1.4), Basis(Vector3.UP, -a))
	# Roof dormers in two tiers on both slopes.
	for sz in [-1.0, 1.0]:
		for tier in 2:
			for i in 6:
				var x := -40.0 + 12.0 * i + 6.0 * tier
				var t := 0.18 + 0.3 * tier
				var dp := Vector3(x, e + MUNICH_RISE * t, sz * 20.0 * (1.0 - t))
				var b := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
				lm.box("Roof", dp + Vector3(0, 0.8, 0), Vector3(1.4, 1.6, 1.4), b)
				lm.gable("Roof", dp + Vector3(0, 1.6, 0), 1.4, 1.4, 1.0, b, 0.1, "Roof")
	# West front between the towers: portal with porch and the tall window.
	var wx := -54.5
	lm.box("Brick", Vector3(wx - 1.2, 5.0, 0), Vector3(2.4, 10.0, 8.0))
	LandmarkChParts.lancet(lm, "Stone", "Windows", Vector3(wx - 2.4, 0.3, 0), Vector3.LEFT, 4.0, 8.0, 1, 0.4)
	LandmarkChParts.wimperg(lm, "Stone", Vector3(wx - 2.4, 8.0, 0), Vector3.LEFT, 5.0, 3.2, 0.3)
	LandmarkChParts.lancet(lm, "Stone", "Windows", Vector3(wx, 13.0, 0), Vector3.LEFT, 4.6, 20.0, 2, 0.35)
	for sz in [-1.0, 1.0]:
		_munich_tower(lm, Vector3(-47.5, 0, sz * 12.9))
	lm.commit(model)

## One tower: square brick shaft (slightly stepped in) with stone string
## courses, corner lesenes, blind and open lancets, the octagonal belfry
## and the welsche Haube with its lantern, small cap and cross.
static func _munich_tower(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Brick", p + Vector3(0, 20.0, 0), Vector3(14.0, 40.0, 14.6))
	lm.box("Brick", p + Vector3(0, 53.0, 0), Vector3(13.0, 26.0, 13.6))
	for y in [10.0, 20.0, 30.0, 40.0, 48.0, 57.0]:
		LandmarkChParts.band(lm, "Stone", y, 7.0 if y <= 40.0 else 6.5, 7.3 if y <= 40.0 else 6.8, 0.6, 0.25, p)
	LandmarkChParts.band(lm, "Stone", 65.2, 6.5, 6.8, 0.8, 0.4, p)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Brick", p + Vector3(sx * 6.9, 20.0, sz * 7.2), Vector3(1.4, 40.0, 1.4))
			lm.box("Brick", p + Vector3(sx * 6.4, 53.0, sz * 6.7), Vector3(1.3, 26.0, 1.3))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		var d := 7.3 if f % 2 == 0 else 7.0
		var face := p + b * Vector3(0, 0, d)
		LandmarkChParts.lancet(lm, "Stone", "Windows", face + Vector3(0, 12.0, 0), n, 1.4, 6.0, 0, 0.25)
		for x in [-2.6, 0.0, 2.6]:
			LandmarkChParts.lancet(lm, "Stone", "Brick", face + b * Vector3(x, 21.5, 0), n, 1.4, 7.0, 0, 0.2)
		for x in [-1.8, 1.8]:
			LandmarkChParts.lancet(lm, "Stone", "Windows", face + b * Vector3(x, 31.0, 0), n, 1.6, 7.5, 0, 0.25)
			LandmarkChParts.lancet(lm, "Stone", "Windows", face + b * Vector3(x, 49.0 - 0.0, -0.5), n, 1.8, 7.0, 1, 0.25)
		for x in [-2.6, 0.0, 2.6]:
			LandmarkChParts.lancet(lm, "Stone", "Brick", face + b * Vector3(x, 41.5, -0.5), n, 1.3, 5.5, 0, 0.2)
			LandmarkChParts.lancet(lm, "Stone", "Brick", face + b * Vector3(x, 58.5, -0.5), n, 1.3, 5.5, 0, 0.2)
	lm.frustum("Brick", p + Vector3(0, 66.0, 0), 6.82, 6.82, 10.5, 8, PI / 8.0)
	for f in 8:
		var a := PI * 0.25 * f
		var dd := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.lancet(lm, "Stone", "Windows", p + Vector3(0, 67.5, 0) + dd * 6.3, dd, 1.8, 7.0, 1, 0.25)
		var ca := a + PI / 8.0
		lm.box("Stone", p + Vector3(cos(ca), 0, sin(ca)) * 6.8 + Vector3(0, 71.2, 0), Vector3(0.6, 10.5, 0.6),
			Basis(Vector3.UP, -ca))
	LandmarkChParts.band(lm, "Stone", 76.0, 6.5, 6.5, 0.7, 0.5, p)
	var hb := p + Vector3(0, 76.5, 0)
	lm.lathe("Copper", hb, PackedVector2Array([Vector2(7.2, 0), Vector2(7.8, 1.0), Vector2(7.6, 2.0), Vector2(7.0, 3.0),
		Vector2(6.1, 4.6), Vector2(5.2, 6.0), Vector2(4.2, 7.6), Vector2(3.4, 9.0), Vector2(2.5, 11.0)]), 24)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var prev := hb + Vector3(cos(a) * 7.9, 1.0, sin(a) * 7.9)
		for q in [Vector2(7.1, 3.0), Vector2(5.3, 6.0), Vector2(3.5, 9.0), Vector2(2.6, 11.0)]:
			var nxt := hb + Vector3(cos(a) * q.x, q.y, sin(a) * q.x)
			lm.beam("Copper", prev, nxt, 0.3, 0.2)
			prev = nxt
	lm.frustum("Stone", hb + Vector3(0, 11.0, 0), 2.4, 2.2, 3.5, 8)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		LandmarkChParts.arched_window(lm, "Stone", "Windows", hb + Vector3(cos(a), 0, sin(a)) * 2.2 + Vector3(0, 11.6, 0),
			Vector3(cos(a), 0, sin(a)), 0.8, 2.2, 0.12, 4)
	lm.lathe("Copper", hb + Vector3(0, 14.5, 0), PackedVector2Array([Vector2(2.9, 0), Vector2(2.6, 0.5),
		Vector2(1.8, 1.2), Vector2(0.6, 2.4)]), 12)
	LandmarkCeParts.cross(lm, "Gilt", hb + Vector3(0, 16.9, 0), MUNICH_TOP - 93.4)

# --- Dresden Frauenkirche ---

const DRESDEN_TOP := 91.2
const DRESDEN_EAVE := 24.0

static func dresden(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B2A88F", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5F584E", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#6A7075", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E907F", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	_dresden_body(lm)
	_dresden_dome(lm)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_dresden_stair_tower(lm, Vector3(sx * 17.5, 0, sz * 17.5))
	lm.commit(model)

## Body: square with cut corners, giant pilasters, two tiers of round
## and segment-headed windows, the pedimented portals on the west,
## north and south, the main cornice and the semicircular choir apse.
static func _dresden_body(lm: LandmarkMesh) -> void:
	var e := DRESDEN_EAVE
	var poly := PackedVector2Array([Vector2(-20, -13), Vector2(-13, -20), Vector2(13, -20), Vector2(20, -13),
		Vector2(20, 13), Vector2(13, 20), Vector2(-13, 20), Vector2(-20, 13)])
	lm.poly_prism("Stone", poly, 0.0, e)
	lm.frustum("Stone", Vector3(20.0, 0, 0), 9.0, 9.0, e, 24)
	lm.lathe("Lead", Vector3(20.0, e, 0), PackedVector2Array([Vector2(9.8, 0), Vector2(7.0, 4.0), Vector2(0.0, 7.0)]), 24)
	LandmarkChParts.band(lm, "Dark", 0.0, 20.0, 20.0, 1.0, 0.3)
	LandmarkChParts.band(lm, "Dark", 12.0, 20.0, 20.0, 0.5, 0.2)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		LandmarkDetail.cornice(lm, "Stone", b * Vector3(-13.0, e - 1.2, 20.0), b * Vector3(13.0, e - 1.2, 20.0), n, 1.2)
		for i in 6:
			var x := -12.5 + 5.0 * i
			lm.box("Stone", b * Vector3(x, e * 0.5, 20.3), Vector3(1.4, e - 1.4, 0.6), b)
		for i in 5:
			var x := -10.0 + 5.0 * i
			if f == 0 and absf(x) < 3.0:
				continue
			LandmarkChParts.arched_window(lm, "Dark", "Windows", b * Vector3(x, 3.0, 20.0), n, 2.2, 6.5, 0.25)
			LandmarkChParts.arched_window(lm, "Dark", "Windows", b * Vector3(x, 14.0, 20.0), n, 2.2, 7.5, 0.25)
		if f != 0:
			# Portal with columns and a segmental pediment.
			lm.box("Stone", b * Vector3(0, 4.5, 20.6), Vector3(7.0, 9.0, 1.2), b)
			LandmarkChParts.arched_window(lm, "Dark", "Windows", b * Vector3(0, 0.2, 21.2), n, 2.8, 6.2, 0.3)
			for s in [-1.0, 1.0]:
				LandmarkDetail.column(lm, "Stone", b * Vector3(s * 2.8, 0.0, 21.6), 0.35, 8.0, "ionic", 0)
			LandmarkDetail.cornice(lm, "Stone", b * Vector3(-3.6, 8.6, 21.2), b * Vector3(3.6, 8.6, 21.2), n, 0.8)
			lm.gable("Stone", b * Vector3(0, 9.4, 20.9), 7.0, 1.4, 1.8, b, 0.1, "Stone")
	# Apse windows.
	for k in 5:
		var a := -PI * 0.4 + PI * 0.2 * k
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.arched_window(lm, "Dark", "Windows", Vector3(20.0, 3.0, 0) + d * 8.95, d, 2.0, 6.5, 0.25)
		LandmarkChParts.arched_window(lm, "Dark", "Windows", Vector3(20.0, 14.0, 0) + d * 8.95, d, 2.0, 7.0, 0.25)

## The stone bell: concave skirt from the cornice with eight dormer
## oculi, the drum band, the bell 26 m across with eight ribs, the
## lantern with its columns and openings, cupola, orb and cross.
static func _dresden_dome(lm: LandmarkMesh) -> void:
	var y0 := DRESDEN_EAVE
	var skirt := PackedVector2Array([Vector2(19.6, 0), Vector2(18.0, 2.5), Vector2(16.2, 6.0), Vector2(14.8, 10.5),
		Vector2(14.2, 14.0), Vector2(14.0, 16.0)])
	lm.lathe("Stone", Vector3(0, y0, 0), skirt, 32)
	for k in 8:
		var a := PI * 0.25 * k + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var dp := d * 16.6 + Vector3(0, y0 + 5.2, 0)
		var b := Basis(Vector3.UP, atan2(d.x, d.z))
		lm.box("Stone", dp + Vector3(0, 1.2, 0), Vector3(2.6, 2.8, 2.0), b)
		lm.lathe("Stone", dp + Vector3(0, 2.6, 0), LandmarkChParts.swell(1.4, 1.0), 8, 1.0, 1.0)
		lm.disc("Windows", dp + d * 1.02 + Vector3(0, 1.2, 0), d, 0.8, 12)
	var db := y0 + 16.0
	lm.frustum("Dark", Vector3(0, db, 0), 14.3, 14.3, 1.0, 32)
	var prof := PackedVector2Array([Vector2(13.6, 0), Vector2(13.9, 1.5), Vector2(13.7, 4.0), Vector2(12.6, 9.0),
		Vector2(10.6, 14.0), Vector2(8.2, 19.0), Vector2(6.2, 23.0), Vector2(5.0, 26.0)])
	lm.lathe("Stone", Vector3(0, db + 1.0, 0), prof, 32)
	for k in 8:
		var a := PI * 0.25 * k
		for j in prof.size() - 1:
			var p0 := Vector3(cos(a) * (prof[j].x + 0.2), db + 1.0 + prof[j].y, sin(a) * (prof[j].x + 0.2))
			var p1 := Vector3(cos(a) * (prof[j + 1].x + 0.2), db + 1.0 + prof[j + 1].y, sin(a) * (prof[j + 1].x + 0.2))
			lm.beam("Dark", p0, p1, 0.7, 0.4)
	# Lantern from the 67 m platform.
	var lb := db + 27.0
	lm.frustum("Dark", Vector3(0, lb - 0.4, 0), 5.6, 5.6, 0.8, 24)
	LandmarkDetail.balustrade(lm, "Stone", Vector3(-4.4, lb + 0.4, 4.4), Vector3(4.4, lb + 0.4, 4.4), 1.0, 2.2)
	LandmarkDetail.balustrade(lm, "Stone", Vector3(4.4, lb + 0.4, -4.4), Vector3(-4.4, lb + 0.4, -4.4), 1.0, 2.2)
	lm.frustum("Stone", Vector3(0, lb + 0.4, 0), 3.4, 3.2, 8.0, 16)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.arched_window(lm, "Dark", "Windows", Vector3(0, lb + 1.6, 0) + d * 3.25, d, 1.2, 4.4, 0.15)
		var ca := TAU * float(k) / 8.0
		LandmarkDetail.column(lm, "Stone", Vector3(cos(ca) * 3.7, lb + 0.4, sin(ca) * 3.7), 0.3, 7.0, "ionic", 0)
	LandmarkDetail.cornice(lm, "Dark", Vector3(-4.0, lb + 7.6, 4.0), Vector3(4.0, lb + 7.6, 4.0), Vector3.BACK, 0.8, false)
	lm.frustum("Dark", Vector3(0, lb + 7.4, 0), 4.3, 4.4, 1.0, 16)
	lm.lathe("Stone", Vector3(0, lb + 8.4, 0), PackedVector2Array([Vector2(4.2, 0), Vector2(3.6, 1.2), Vector2(2.4, 2.6),
		Vector2(1.2, 3.6), Vector2(0.9, 4.2)]), 16)
	lm.lathe("Copper", Vector3(0, lb + 12.6, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(1.2, 0.4),
		Vector2(0.7, 1.4), Vector2(0.3, 2.0)]), 12)
	LandmarkChParts.finial(lm, "Gilt", Vector3(0, lb + 14.6, 0), 1.6, 1.0)
	var cb := lb + 16.2
	LandmarkCeParts.cross(lm, "Gilt", Vector3(0, cb, 0), DRESDEN_TOP - cb)

## One of the four stair towers in the cut corners: round shaft with
## pilasters and windows, cornice, a stone cap with dormers and a
## lantern with its pointed copper cap.
static func _dresden_stair_tower(lm: LandmarkMesh, p: Vector3) -> void:
	var r := 4.4
	lm.frustum("Stone", p, r, r, 32.0, 24)
	LandmarkChParts.band(lm, "Dark", 24.0, r * 0.95, r * 0.95, 0.6, 0.2, p)
	lm.frustum("Dark", p + Vector3(0, 31.4, 0), r + 0.5, r + 0.6, 0.8, 24)
	var out := Vector3(p.x, 0, p.z).normalized()
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		if d.dot(out) < -0.3:
			continue
		lm.box("Stone", p + d * (r + 0.15) + Vector3(0, 16.0, 0), Vector3(0.8, 31.0, 0.4), Basis(Vector3.UP, -a + PI * 0.5))
		var wa := a + PI / 8.0
		var wd := Vector3(cos(wa), 0, sin(wa))
		for y in [6.0, 15.0, 25.5]:
			LandmarkChParts.arched_window(lm, "Dark", "Windows", p + wd * (r - 0.05) + Vector3(0, y, 0), wd, 1.0,
				2.6 if y < 25.0 else 3.6, 0.18)
	lm.lathe("Stone", p + Vector3(0, 32.2, 0), PackedVector2Array([Vector2(r + 0.4, 0), Vector2(r + 0.2, 1.0),
		Vector2(r - 0.6, 3.0), Vector2(2.4, 5.4), Vector2(1.9, 6.0)]), 16)
	for k in 4:
		var a := TAU * float(k) / 4.0 + PI * 0.25
		var d := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, atan2(d.x, d.z))
		var dp := p + d * (r - 0.4) + Vector3(0, 33.2, 0)
		lm.box("Stone", dp, Vector3(1.2, 1.6, 1.0), b)
		LandmarkChParts.arched_window(lm, "Dark", "Windows", dp + d * 0.5 - Vector3(0, 0.6, 0), d, 0.6, 1.0, 0.1, 4)
	var lb := p + Vector3(0, 38.2, 0)
	lm.frustum("Stone", lb, 1.6, 1.5, 3.0, 12)
	for k in 6:
		var a := TAU * float(k) / 6.0
		lm.frustum("Stone", lb + Vector3(cos(a), 0, sin(a)) * 1.65, 0.14, 0.12, 3.0, 6)
	lm.frustum("Dark", lb + Vector3(0, 3.0, 0), 2.0, 2.0, 0.4, 12)
	lm.lathe("Copper", lb + Vector3(0, 3.4, 0), PackedVector2Array([Vector2(1.9, 0), Vector2(1.3, 1.2),
		Vector2(0.6, 2.4), Vector2(0.2, 3.4)]), 12)
	LandmarkChParts.finial(lm, "Gilt", lb + Vector3(0, 6.8, 0), 1.8, 0.35)
