extends RefCounted

## helsinki_central_station. Registry entry and model in one file.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "helsinki_central_station", "name": "Helsinki Central Station", "lat": 60.17091, "lon": 24.94148,
	"radius_m": 5000.0, "wiki_title": "Helsinki Central Station", "height_m": 48.5, "clear_m": 80.0,
	"yaw_deg": -2.0, "kind": "Station", "aliases": ["helsinki central station",
		"helsinki central railway station", "helsingin päärautatieasema", "helsingfors centralstation"]}

## Eliel Saarinen's station (1919), origin at the OSM footprint centre
## (way 122595198), front +Z on Kaivokatu (registry yaw -2), built from the
## OSM 3D outline: the hall whose flat granite front is pierced by the
## great glazed arch (stepped archivolts, copper rim) over a copper canopy
## and four Lantern Bearers on pillars, a small copper cupola on top; the
## two wings either side under dark sheet-metal mansards with round-headed
## attic windows; the wings running north along the tracks; and the 48.5 m
## clock tower faced with red Hanko granite, its green copper crown and the
## four dials. From the Commons photos in
## visual-plan/refs/landmarks/helsinki_central_station/: warm pink-red
## granite, dark mansard roofs, a flat slab front.
##
## Measured: heights and plan after OSM (the wing and tower plan, 48.5 m
## tower: published figure; LoD2 reads 50.4 m for the whole complex).
## Estimated: the front slab height (22.4 m, scaled from a photo), attic
## window spacing. Night: the front and tower are floodlit warm white.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9A8272", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#B8A398", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#7A9A88", 2.0, 0.5, 0.3))
	# The hall and wing roofs are dark sheet metal; copper green is kept for
	# the gable's arch frame, the trims and the tower top.
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#3C4042", 2.0))
	lm.use("Glass", LandmarkMaterials.paint("#3E4A52", 0.3, 0.4))
	# The lamp globes are milky glass in a dark bronze cage of ribs.
	lm.use("Lamp", LandmarkMaterials.lit("#E4E4DA", 0.08))
	lm.use("Bronze", LandmarkMaterials.pbr("sheet_metal", "#3A3530", 2.0))
	lm.use("Dial", LandmarkMaterials.lit("#ECE8DA", 0.1))
	# Main hall: walls, barrel roof along the hall, the gable front.
	var hx := 0.55
	var hw := 18.1
	# The hall rises well over the wings: walls to 16 m under a tall vault.
	var hwall := 17.0
	var hrise := 3.6
	var slab := 22.4
	lm.box("Granite", Vector3(hx, hwall * 0.5, 0.05), Vector3(hw, hwall, 36.1))
	_barrel(lm, "Roof", Vector3(hx, hwall, -18.0), Vector3(hx, hwall, 18.0), hw * 0.5 + 0.4, hrise)
	var fz := 18.05
	# The front is a flat granite slab to a copper cornice and a little
	# cupola, the arch set low in it; the vault runs back behind.
	lm.box("Granite", Vector3(hx, (hwall + slab) * 0.5, fz - 0.5), Vector3(hw + 0.8, slab - hwall, 1.4))
	lm.box("Copper", Vector3(hx, slab + 0.3, fz - 0.2), Vector3(hw + 1.6, 0.6, 2.2))
	lm.frustum("Copper", Vector3(hx, slab + 0.6, fz - 4.0), 2.2, 1.6, 0.8, 12)
	lm.lathe("Copper", Vector3(hx, slab + 1.4, fz - 4.0), FhU.dome_prof(1.6, 1.1), 12)
	for sx in [-1.0, 1.0]:
		var x: float = hx + sx * hw * 0.5
		FhP.pierce(lm, "Granite", "Glass", Vector3(x, 0, -17.0), Vector3(x, 0, 2.5), Vector3(sx, 0, 0), 11.0, 2.8, 5,
			1, Vector2(2.0, 1.8), 0.4, 3.0, 0.3)
	# Wings: [x0, x1, z0, z1] under round roofs (14 m) along X.
	for wg in [[-52.6, -8.4, -16.1, 3.1], [9.4, 56.2, -9.0, 2.7]]:
		var x0: float = wg[0]
		var x1: float = wg[1]
		var z0: float = wg[2]
		var z1: float = wg[3]
		FhU.blk(lm, "Granite", (x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5, x1 - x0, 11.0, z1 - z0)
		_mansard(lm, x0, x1, z0, z1, 11.0)
		FhU.openings(lm, "Glass", Vector3(x0 + 2.0, 0, z1 + 0.02), Vector3(x1 - 2.0, 0, z1 + 0.02), Vector3(0, 0, 1), 11.1,
			int((x1 - x0) / 5.2), 1.6, 1.8, true, 0.0)
		FhP.pierce(lm, "Granite", "Glass", Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(0, 0, 1), 0.0, 10.4,
			int((x1 - x0) / 4.2), 2, Vector2(1.9, 3.4), 1.4, 4.6, 0.35)
		FhP.strips(lm, "Trim", Vector3(x0 + 0.5, 0, z1), Vector3(x1 - 0.5, 0, z1), Vector3(0, 0, 1), 0.0, 10.4,
			int((x1 - x0) / 4.2) + 1, 0.5, 0.45)
		FhP.band(lm, "Trim", Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(0, 0, 1), 10.4, 0.6, 0.6)
		FhP.band(lm, "Trim", Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(0, 0, 1), 0.0, 1.0, 0.3)
	# The two wings north along the tracks (east wing on Rautatientori).
	for wn in [[-59.0, -45.2, -45.0, -16.1], [46.4, 56.1, -45.0, -18.8]]:
		var x0: float = wn[0]
		var x1: float = wn[1]
		var z0: float = wn[2]
		var z1: float = wn[3]
		FhU.blk(lm, "Granite", (x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5, x1 - x0, 11.0, z1 - z0)
		_mansard(lm, x0, x1, z0, z1, 11.0)
		var ox := Vector3(signf(x0 + x1), 0, 0)
		var ex: float = x1 if ox.x > 0.0 else x0
		FhP.pierce(lm, "Granite", "Glass", Vector3(ex, 0, z0), Vector3(ex, 0, z1), ox, 0.0, 10.4,
			int((z1 - z0) / 4.2), 2, Vector2(1.9, 3.4), 1.4, 4.6, 0.35)
	var zf := 18.1
	# The great portal fills the gable: a tall glazed arch (10 m span,
	# 14.5 m high) inside three thin recessed rings, a broad plain granite
	# band, then five stepped outer rings rising to the vault's crown with
	# the copper rim along the outermost. Each arch is [half-span, spring
	# height, rise]; each band steps further out from the gable.
	var e0 := Vector3(5.0, 9.0, 5.5)
	var e_top := Vector3(8.6, 10.0, 8.6)
	var arcs: Array = [e0]
	for k in 3:
		arcs.append(e0 + Vector3(0.35, 0.05, 0.4) * float(k + 1))
	var e_field := Vector3(7.0, 9.5, 7.0)
	arcs.append(e_field)
	for k in 5:
		arcs.append(e_field.lerp(e_top, float(k + 1) / 5.0))
	var zs: Array = [0.3, 0.55, 0.8, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25]
	_ell_glass(lm, Vector3(hx, 0.0, zf + 0.04), e0)
	for k in arcs.size() - 1:
		var zb: float = 0.04 if k == 0 else zs[k - 1]
		_ell_band(lm, "Granite", Vector3(hx, 0.0, zf), arcs[k], arcs[k + 1], zb, zs[k], k == arcs.size() - 2)
	_ell_band(lm, "Copper", Vector3(hx, 0.0, zf), e_top, e_top + Vector3(0.45, 0.0, 0.1), 0.0, 2.45, true)
	# Mullions and transoms of the glazing, clipped to the arch.
	for k in 9:
		var x := (float(k) - 4.0) * 1.1
		var top := e0.y + e0.z * sqrt(maxf(1.0 - pow(x / e0.x, 2.0), 0.0))
		lm.box("Trim", Vector3(hx + x, (5.6 + top) * 0.5, zf + 0.12), Vector3(0.16, top - 5.6, 0.16), Basis(), 0.0)
	for k in 8:
		var y := 6.4 + 1.1 * float(k)
		var half := e0.x if y <= e0.y else e0.x * sqrt(maxf(1.0 - pow((y - e0.y) / e0.z, 2.0), 0.0))
		if half > 0.3:
			lm.box("Trim", Vector3(hx, y, zf + 0.12), Vector3(half * 2.0, 0.16, 0.16), Basis(), 0.0)
	# The clock over the canopy, the canopy with its lettered copper fascia,
	# and the doors beneath.
	_portal_clock(lm, Vector3(hx, 7.4, zf + 0.2))
	lm.box("Copper", Vector3(hx, 5.0, zf + 2.2), Vector3(15.0, 0.4, 4.4))
	lm.box("Copper", Vector3(hx, 5.0, zf + 4.35), Vector3(15.0, 1.1, 0.2))
	lm.box("Trim", Vector3(hx, 5.25, zf + 4.47), Vector3(11.0, 0.45, 0.05), Basis(), 0.0)
	for k in 4:
		lm.box("Glass", Vector3(hx + (float(k) - 1.5) * 2.4, 1.6, zf + 0.12), Vector3(2.0, 3.2, 0.08), Basis(), 0.0)
	FhU.steps(lm, "Trim", Vector3(hx, 0, zf + 0.4), Vector3(0, 0, 1), 14.0, 0.6, 0.15, 3)
	# Granite piers either side of the hall, each fronted by a pair of
	# Lantern Bearers (pillars and figures about 10.5 m to the globes' top)
	# and topped by the louvred copper vents.
	for sx in [-1.0, 1.0]:
		var px: float = hx + sx * (hw * 0.5 + 3.0)
		lm.box("Granite", Vector3(px, 7.5, (3.0 + zf + 1.0) * 0.5), Vector3(6.0, 15.0, zf + 1.0 - 3.0))
		FhP.strips(lm, "Granite", Vector3(px - 2.6, 0, zf + 1.0), Vector3(px + 2.6, 0, zf + 1.0), Vector3(0, 0, 1),
			0.0, 14.0, 5, 0.35, 0.25)
		lm.box("Copper", Vector3(px, 15.6, (3.0 + zf + 1.0) * 0.5), Vector3(6.4, 1.2, zf + 1.4 - 3.0))
		for k in 3:
			lm.box("Roof", Vector3(px + (float(k) - 1.0) * 1.9, 15.6, zf + 1.72), Vector3(1.4, 0.8, 0.05), Basis(), 0.0)
		lm.box("Trim", Vector3(px, 0.75, zf + 2.6), Vector3(6.2, 1.5, 3.0))
		for gx in [-1.5, 1.5]:
			_lantern_bearer(lm, Vector3(px + float(gx), 1.5, zf + 2.7), 10.5)
	# Clock tower: corner piers, vertical slits, balconies, dials, the
	# stepped copper top and the globe on four winged wheels.
	var tx := 51.05
	var tz := -13.9
	var tw := 10.1
	var td := 9.8
	FhU.blk(lm, "Granite", tx, 0.0, tz, tw, 36.2, td)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Granite", Vector3(tx + sx * (tw * 0.5 - 0.4), 17.0, tz + sz * (td * 0.5 - 0.4)), Vector3(1.4, 34.0, 1.4))
	for face in FhP.faces(tx, tz, tw, td):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		var m := (fa + fb) * 0.5
		FhU.openings(lm, "Glass", m - fa.direction_to(fb) * 1.4, m + fa.direction_to(fb) * 1.4, fo, 12.0, 3, 0.5, 9.0,
			false, 0.04)
		FhU.openings(lm, "Glass", m - fa.direction_to(fb) * 1.4, m + fa.direction_to(fb) * 1.4, fo, 23.0, 3, 0.5, 2.6,
			false, 0.04)
		# Corbelled balcony with its parapet, then the dial in a granite ring.
		lm.box("Granite", m + fo * 0.7 + Vector3(0, 26.4, 0), Vector3(4.0 if absf(fo.z) > 0.5 else 4.0, 0.5, 1.4),
			Basis(Vector3.UP, atan2(fo.x, fo.z)))
		lm.box("Granite", m + fo * 1.3 + Vector3(0, 27.2, 0), Vector3(4.0, 1.1, 0.25), Basis(Vector3.UP, atan2(fo.x, fo.z)))
		for k in 3:
			lm.box("Granite", m + fo * 0.5 + fa.direction_to(fb) * (float(k) - 1.0) * 1.6 + Vector3(0, 25.8, 0),
				Vector3(0.4, 0.8, 1.0), Basis(Vector3.UP, atan2(fo.x, fo.z)))
		lm.disc("Dial", m + fo * 0.06 + Vector3(0, 31.4, 0), fo, 1.5, 24)
		FhP.ring(lm, "Trim", m + fo * 0.02 + Vector3(0, 31.4, 0), fo, 1.5, 1.85, 0.25, 24)
		for k in 12:
			var a := TAU * float(k) / 12.0
			var mk := m + fo * 0.1 + Vector3(0, 31.4, 0) + (fa.direction_to(fb) * cos(a) + Vector3.UP * sin(a)) * 1.3
			lm.box("Roof", mk, Vector3(0.14, 0.14, 0.06), Basis(Vector3.UP, atan2(fo.x, fo.z)), 0.0)
		var fb2 := Basis(Vector3.UP, atan2(fo.x, fo.z))
		for hand in [[deg_to_rad(-60.0), 0.75, 0.12], [deg_to_rad(60.0), 1.15, 0.08]]:
			var a: float = hand[0]
			var ln: float = hand[1]
			var hd := fa.direction_to(fb) * sin(a) + Vector3.UP * cos(a)
			lm.box("Roof", m + fo * 0.12 + Vector3(0, 31.4, 0) + hd * ln * 0.45, Vector3(hand[2], ln, 0.04),
				fb2 * Basis(Vector3(0, 0, 1), -a * signf(fa.direction_to(fb).dot(fb2.x))), 0.0)
		FhP.ribs(lm, "Granite", fa.lerp(fb, 0.12), fa.lerp(fb, 0.88), fo, 1.0, 22.0, 0.9, 0.3, 0.2)
	FhU.blk(lm, "Trim", tx, 35.6, tz, tw + 0.8, 0.8, td + 0.8)
	var s2 := 1.4142
	# The copper crown in upright tiers, each a little narrower, stepping
	# in at short ledges, and a rounded cap under the globe.
	lm.lathe("Copper", Vector3(tx, 36.4, tz), PackedVector2Array([Vector2(5.0 * s2, 0), Vector2(5.0 * s2, 2.2),
		Vector2(4.1 * s2, 2.6), Vector2(4.1 * s2, 4.8), Vector2(3.2 * s2, 5.2), Vector2(3.2 * s2, 7.0),
		Vector2(2.3 * s2, 7.4), Vector2(2.3 * s2, 8.8), Vector2(1.1 * s2, 9.7), Vector2(0.5 * s2, 10.0)]), 4, 1.0, 1.0,
		PI * 0.25, false)
	# Tall openings in each tier's faces.
	for k in 4:
		var a := PI * 0.5 * float(k)
		var d := Vector3(sin(a), 0, cos(a))
		var r := Vector3.UP.cross(d)
		for tier in [[5.0, 0.4], [4.1, 3.0], [3.2, 5.6]]:
			var half: float = tier[0]
			var y: float = tier[1]
			FhU.openings(lm, "Glass", Vector3(tx, 36.4, tz) + d * (half + 0.02) - r * half * 0.5,
				Vector3(tx, 36.4, tz) + d * (half + 0.02) + r * half * 0.5, d, y, 3, 0.45, 1.5, true, 0.03)
	var gb := Vector3(tx, 46.4, tz)
	lm.frustum("Copper", gb, 0.35, 0.3, 0.6, 8)
	lm.lathe("Copper", gb + Vector3(0, 1.0, 0), FhU.ball(0.55), 14)
	for k in 4:
		var a := PI * 0.5 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		var wc := gb + Vector3(0, 0.9, 0) + d * 0.55
		var wb := Basis(Vector3.UP, -a)
		for sp in 6:
			var t := TAU * float(sp) / 6.0
			lm.box("Copper", wc + (wb.z * cos(t) + Vector3.UP * sin(t)) * 0.2, Vector3(0.05, 0.42, 0.05),
				Basis(wb.x, t), 0.0)
		lm.box("Copper", wc + d * 0.25 + Vector3(0, 0.25, 0), Vector3(0.06, 0.35, 0.6), wb, 0.0)
	lm.commit(model)
	# Night: the front and the clock tower are floodlit warm white from the
	# square (spot: position, target, cone angle, energy, range, colour).
	var warm := Color(1.0, 0.86, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(hx - 9.0, 3.5, zf + 20.0), Vector3(hx, 11.0, zf), 46.0, 1.0, 55.0, warm],
		[Vector3(hx + 9.0, 3.5, zf + 20.0), Vector3(hx, 11.0, zf), 46.0, 1.0, 55.0, warm],
		[Vector3(51.0, 3.0, 12.0), Vector3(51.05, 30.0, -13.9), 22.0, 1.1, 60.0, warm],
		[Vector3(30.0, 3.0, 12.0), Vector3(40.0, 9.0, -6.0), 40.0, 0.7, 40.0, warm],
	])

## The dark sheet-metal mansard of a wing: an attic storey 2.2 m high
## (its round-headed windows are set in it by the caller) under a hip of
## the same dark metal.
static func _mansard(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, y: float) -> void:
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	FhU.blk(lm, "Granite", cx, y, cz, x1 - x0 - 0.6, 2.2, z1 - z0 - 0.6)
	FhU.hip(lm, "Roof", Vector3(cx, y + 2.2, cz), x1 - x0 + 0.8, z1 - z0 + 0.8, 3.0, 0.22)

## Half-round (segmental) roof of rise `rise` and half-span `r` along a..b.
static func _barrel(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, r: float, rise: float) -> void:
	var dir := (b - a).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var rows: Array = []
	for k in 13:
		var t := PI * float(k) / 12.0
		var off := side * cos(t) * r + Vector3.UP * sin(t) * rise
		rows.append(PackedVector3Array([a + off, b + off]))
	lm.grid(key, rows, (a + b) * 0.5 - Vector3.UP * rise, true)
	# Standing seams of the copper sheet across the vault.
	var n_seams := int(a.distance_to(b) / 1.6)
	for i in range(1, n_seams):
		var c := a.lerp(b, float(i) / float(n_seams))
		var prev := c + side * r
		for k in range(1, 13):
			var t := PI * float(k) / 12.0
			var p := c + side * cos(t) * r * 1.01 + Vector3.UP * sin(t) * rise * 1.01
			lm.beam(key, prev, p, 0.08, 0.1, dir)
			prev = p
	for e in [a, b]:
		var n := -dir if e == a else dir
		for k in 12:
			var t0 := PI * float(k) / 12.0
			var t1 := PI * float(k + 1) / 12.0
			lm.tri(key, e, e + side * cos(t0) * r + Vector3.UP * sin(t0) * rise,
				e + side * cos(t1) * r + Vector3.UP * sin(t1) * rise, n, n, n, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)

## Points of an arch outline at `base` (centre bottom) for `e` =
## [half-span, spring height, rise]: up the left leg, over the elliptic
## head, down the right leg; with each point its outward normal.
static func _ell_path(base: Vector3, e: Vector3) -> Array:
	var pts: Array = [[base + Vector3(-e.x, 0, 0), Vector3.LEFT]]
	for k in 21:
		var t := PI - PI * float(k) / 20.0
		var n := Vector3(cos(t) / e.x, sin(t) / e.z, 0).normalized()
		pts.append([base + Vector3(e.x * cos(t), e.y + e.z * sin(t), 0), n])
	pts.append([base + Vector3(e.x, 0, 0), Vector3.RIGHT])
	return pts

## The glazed opening inside arch `e` at `base`, facing +Z.
static func _ell_glass(lm: LandmarkMesh, base: Vector3, e: Vector3) -> void:
	var z := Vector3(0, 0, 1)
	lm.quad("Glass", base + Vector3(-e.x, 0, 0), base + Vector3(e.x, 0, 0), base + Vector3(e.x, e.y, 0),
		base + Vector3(-e.x, e.y, 0), z)
	var c := base + Vector3(0, e.y, 0)
	var pts := _ell_path(base, e)
	for k in range(1, pts.size() - 2):
		lm.tri("Glass", c, pts[k][0], pts[k + 1][0], z, z, z, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)

## A stepped archivolt band between arches `ei` and `eo` at `base`: its
## front at depth `zf_`, its inner reveal back to `zb`, and (when `outer`)
## its outer edge back to the wall.
static func _ell_band(lm: LandmarkMesh, key: String, base: Vector3, ei: Vector3, eo: Vector3, zb: float,
		zf_: float, outer: bool) -> void:
	var fz := Vector3(0, 0, zf_)
	var pi_ := _ell_path(base, ei)
	var po := _ell_path(base, eo)
	for k in pi_.size() - 1:
		var a: Vector3 = pi_[k][0]
		var b: Vector3 = pi_[k + 1][0]
		var c: Vector3 = po[k + 1][0]
		var d: Vector3 = po[k][0]
		lm.quad(key, a + fz, b + fz, c + fz, d + fz, Vector3(0, 0, 1))
		var ni: Vector3
		if k == 0 or k == pi_.size() - 2:
			ni = -(pi_[k][1] as Vector3)
		else:
			ni = -((pi_[k][1] as Vector3) + (pi_[k + 1][1] as Vector3)).normalized()
		lm.quad(key, a + Vector3(0, 0, zb), b + Vector3(0, 0, zb), b + fz, a + fz, ni)
		if outer:
			var no: Vector3 = (po[k][1] as Vector3) if k == 0 or k == po.size() - 2 \
				else ((po[k][1] as Vector3) + (po[k + 1][1] as Vector3)).normalized()
			lm.quad(key, d, c, c + fz, d + fz, no)

## The clock set in the portal's glazing: a square bronze frame round a
## pale dial with hour marks and black hands (about ten past ten).
static func _portal_clock(lm: LandmarkMesh, c: Vector3) -> void:
	var z := Vector3(0, 0, 1)
	lm.box("Bronze", c, Vector3(2.0, 2.0, 0.3))
	lm.box("Trim", c + Vector3(0, -1.15, 0), Vector3(2.3, 0.25, 0.4))
	lm.disc("Dial", c + Vector3(0, 0, 0.16), z, 0.78, 24)
	FhP.ring(lm, "Bronze", c + Vector3(0, 0, 0.17), z, 0.72, 0.8, 0.04, 24)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(sin(a), cos(a), 0)
		lm.box("Bronze", c + d * 0.62 + Vector3(0, 0, 0.19), Vector3(0.05, 0.16 if k % 3 == 0 else 0.09, 0.03),
			Basis(z, -a), 0.0)
	for hand in [[deg_to_rad(-60.0), 0.4, 0.07], [deg_to_rad(60.0), 0.6, 0.05]]:
		var a: float = hand[0]
		var d := Vector3(sin(a), cos(a), 0)
		var ln: float = hand[1]
		lm.box("Roof", c + d * ln * 0.45 + Vector3(0, 0, 0.21), Vector3(hand[2], ln, 0.03), Basis(z, -a), 0.0)

## A lamp globe of radius `r` centred at `c`: milky glass held in a cage
## of eight meridian ribs and three latitude bands, with a collar on top.
static func _globe(lm: LandmarkMesh, c: Vector3, r: float) -> void:
	lm.lathe("Lamp", c - Vector3(0, r, 0), FhU.ball(r), 12)
	var w := r * 0.06
	for m in 8:
		var a := TAU * float(m) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var prev := c + Vector3(0, -r * 1.02, 0)
		for k in range(1, 9):
			var t := PI * float(k) / 8.0
			var p := c + (d * sin(t) - Vector3.UP * cos(t)) * r * 1.02
			lm.beam("Bronze", prev, p, w, w)
			prev = p
	for lat in [-0.45, 0.0, 0.45]:
		var y: float = lat * r
		var rr := sqrt(r * r - y * y) * 1.02
		var prev := c + Vector3(rr, y, 0)
		for k in range(1, 17):
			var a := TAU * float(k) / 16.0
			var p := c + Vector3(cos(a) * rr, y, sin(a) * rr)
			lm.beam("Bronze", prev, p, w, w)
			prev = p
	lm.frustum("Bronze", c + Vector3(0, r * 0.9, 0), r * 0.35, r * 0.28, r * 0.25, 8)

## One of Wikström's Lantern Bearers, `h` tall at `base`: the patterned
## granite pillar of the lower body, the bare muscular torso, the head,
## and both arms holding the globe lamp out in front.
static func _lantern_bearer(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.box("Trim", base + Vector3(0, h * 0.04, 0), Vector3(h * 0.3, h * 0.08, h * 0.3))
	lm.frustum("Granite", base + Vector3(0, h * 0.08, 0), h * 0.12, h * 0.13, h * 0.42, 8, PI / 8.0)
	for k in 4:
		lm.frustum("Granite", base + Vector3(0, h * (0.14 + 0.09 * float(k)), 0), h * 0.135, h * 0.135, h * 0.025, 8,
			PI / 8.0)
	var tb := base + Vector3(0, h * 0.5, 0)
	lm.lathe("Granite", tb, PackedVector2Array([Vector2(h * 0.12, 0), Vector2(h * 0.13, h * 0.1),
		Vector2(h * 0.17, h * 0.22), Vector2(h * 0.18, h * 0.28), Vector2(h * 0.08, h * 0.33)]), 12, 1.0, 0.7)
	lm.frustum("Granite", tb + Vector3(0, h * 0.32, 0), h * 0.05, h * 0.045, h * 0.04, 8)
	lm.lathe("Granite", tb + Vector3(0, h * 0.355, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(h * 0.05, h * 0.015),
		Vector2(h * 0.065, h * 0.06), Vector2(h * 0.06, h * 0.11), Vector2(h * 0.035, h * 0.135),
		Vector2(0.0, h * 0.145)]), 10, 1.0, 1.1)
	var lamp := tb + Vector3(0, h * 0.2, h * 0.28)
	for s in [-1.0, 1.0]:
		var sh := tb + Vector3(s * h * 0.17, h * 0.27, 0)
		var el := sh + Vector3(s * h * 0.05, -h * 0.12, h * 0.1)
		lm.beam("Granite", sh, el, h * 0.07, h * 0.07)
		lm.beam("Granite", el, lamp + Vector3(s * h * 0.09, -h * 0.02, 0), h * 0.06, h * 0.06)
	_globe(lm, lamp, h * 0.09)

# --- Hotel Torni --------------------------------------------------------

## Jung & Jung's Torni (1931), 13 storeys and 70 m, the tallest building
## in Helsinki on completion; origin at the OSM footprint centre (registry
## yaw -35, the block turned onto Yrjönkatu), parts after the OSM 3D
## outline: the 30 m square six-storey base with its shopfront plinth,
## the setback storey and the flanking wings (24 m), the slender 7.6 x
## 19.7 m Art Deco tower slab ribbed by vertical piers to 45 m, the glazed
