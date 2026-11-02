class_name LandmarkFhHelsinkiCity
extends RefCounted

## Four landmarks of the Helsinki city centre in true metres: the Central
## Station (Saarinen's granite National Romantic hall, 48.5 m clock
## tower), the 1931 Hotel Torni, the Old Market Hall by the South Harbour
## and the National Library (Engel's rotunda). Footprints and part
## heights follow OpenStreetMap.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

# --- Helsinki Central Station ----------------------------------------

## Eliel Saarinen's station (1919), origin at the OSM footprint centre,
## front +Z on Kaivokatu (registry yaw -2), parts after the OSM 3D
## outline: the barrel-vaulted main hall (18 m) whose gable front holds
## the great arched portal with Wikström's four Lantern Bearers (granite
## figures on patterned pillars holding globe lamps), the round-roofed
## wings either side (14 m), the wings running north along the tracks,
## and the 48.5 m clock tower faced with about 3600 blocks of red Hanko
## granite: 3 m dials on all four sides over the four balconies, the
## stepped copper roof (base 4.5 m wide) and the globe borne by four
## winged wheels.
static func station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9C8C84", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#B9B1A8", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#7A9A88", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8B0", 0.9))
	lm.use("Dial", LandmarkMaterials.lit("#F2EEE0", 0.35))
	# Main hall: walls, barrel roof along the hall, the gable front.
	var hx := 0.55
	var hw := 18.1
	lm.box("Granite", Vector3(hx, 6.9, 0.05), Vector3(hw, 13.8, 36.1))
	_barrel(lm, "Copper", Vector3(hx, 13.8, -18.0), Vector3(hx, 13.8, 18.0), hw * 0.5 + 0.4, 4.2)
	var fz := 18.05
	for sx in [-1.0, 1.0]:
		var x: float = hx + sx * hw * 0.5
		FhP.pierce(lm, "Granite", "Glass", Vector3(x, 0, -17.0), Vector3(x, 0, 17.0), Vector3(sx, 0, 0), 11.0, 2.8, 9,
			1, Vector2(2.0, 1.8), 0.4, 3.0, 0.3)
	# Wings: [x0, x1, z0, z1] under round roofs (14 m) along X.
	for wg in [[-52.6, -8.4, -16.1, 3.1], [9.4, 56.2, -9.0, 2.7]]:
		var x0: float = wg[0]
		var x1: float = wg[1]
		var z0: float = wg[2]
		var z1: float = wg[3]
		FhU.blk(lm, "Granite", (x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5, x1 - x0, 11.0, z1 - z0)
		_barrel(lm, "Copper", Vector3(x0, 11.0, (z0 + z1) * 0.5), Vector3(x1, 11.0, (z0 + z1) * 0.5),
			(z1 - z0) * 0.5 + 0.4, 3.0)
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
		_barrel(lm, "Copper", Vector3((x0 + x1) * 0.5, 11.0, z0), Vector3((x0 + x1) * 0.5, 11.0, z1),
			(x1 - x0) * 0.5 + 0.4, 2.6)
		var ox := Vector3(signf(x0 + x1), 0, 0)
		var ex: float = x1 if ox.x > 0.0 else x0
		FhP.pierce(lm, "Granite", "Glass", Vector3(ex, 0, z0), Vector3(ex, 0, z1), ox, 0.0, 10.4,
			int((z1 - z0) / 4.2), 2, Vector2(1.9, 3.4), 1.4, 4.6, 0.35)
	# The great portal: a round-headed arch of 11 m span and 13 m rise in
	# stepped granite rings, glazed, between stepped buttress piers.
	var aw := 5.6
	var ah := 13.2
	for k in 12:
		var y0 := ah * float(k) / 12.0
		var y1 := ah * float(k + 1) / 12.0
		var w0 := aw * sqrt(1.0 - y0 / ah)
		var w1 := aw * sqrt(1.0 - y1 / ah)
		lm.quad("Glass", Vector3(hx - w0, y0, fz - 0.6), Vector3(hx + w0, y0, fz - 0.6), Vector3(hx + w1, y1, fz - 0.6),
			Vector3(hx - w1, y1, fz - 0.6), Vector3(0, 0, 1))
		for ring in 3:
			var off := 0.5 + 1.0 * float(ring)
			var dz := fz - 0.6 + 0.35 * float(ring)
			for s in [-1.0, 1.0]:
				lm.beam("Granite", Vector3(hx + s * (w0 + off), maxf(y0, 0.3), dz), Vector3(hx + s * (w1 + off), y1 + 0.001, dz),
					0.95, 0.8, Vector3.RIGHT)
	# Glazing bars of the arch.
	for k in 5:
		var x := hx + (float(k) - 2.0) * 2.0
		var top := ah * (1.0 - pow((x - hx) / aw, 2.0))
		lm.box("Trim", Vector3(x, top * 0.5, fz - 0.5), Vector3(0.18, top, 0.2), Basis(), 0.0)
	for k in 4:
		var y := 2.8 * float(k + 1)
		var ww := aw * sqrt(1.0 - y / ah) * 2.0
		lm.box("Trim", Vector3(hx, y, fz - 0.5), Vector3(ww, 0.18, 0.2), Basis(), 0.0)
	FhP.strips(lm, "Granite", Vector3(hx - hw * 0.5 + 0.8, 0, fz), Vector3(hx + hw * 0.5 - 0.8, 0, fz),
		Vector3(0, 0, 1), 0.0, 17.0, 2, 1.6, 0.9)
	FhP.band(lm, "Trim", Vector3(hx - hw * 0.5, 0, fz), Vector3(hx + hw * 0.5, 0, fz), Vector3(0, 0, 1), 0.0, 0.9, 0.4)
	FhU.steps(lm, "Trim", Vector3(hx, 0, fz + 0.4), Vector3(0, 0, 1), 14.0, 0.6, 0.15, 3)
	# The Lantern Bearers: pairs either side of the arch.
	for gx in [-9.6, -7.0, 8.1, 10.7]:
		_lantern_bearer(lm, Vector3(float(gx), 0.0, fz + 1.2), 6.2)
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
			lm.box("Trim", mk, Vector3(0.12, 0.12, 0.06), Basis(Vector3.UP, atan2(fo.x, fo.z)), 0.0)
		FhP.ribs(lm, "Granite", fa.lerp(fb, 0.12), fa.lerp(fb, 0.88), fo, 1.0, 22.0, 0.9, 0.3, 0.2)
	FhU.blk(lm, "Trim", tx, 35.6, tz, tw + 0.8, 0.8, td + 0.8)
	var s2 := 1.4142
	lm.lathe("Copper", Vector3(tx, 36.4, tz), PackedVector2Array([Vector2(5.3 * s2, 0), Vector2(4.2 * s2, 2.6),
		Vector2(4.2 * s2, 3.3), Vector2(3.2 * s2, 5.6), Vector2(3.2 * s2, 6.2), Vector2(2.25 * s2, 8.0),
		Vector2(2.25 * s2, 8.5), Vector2(1.2 * s2, 9.6), Vector2(0.5 * s2, 10.0)]), 4, 1.0, 1.0, PI * 0.25, false)
	# Ridges down the hips of the copper top.
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Copper", Vector3(tx, 36.5, tz) + d * 5.3 * s2, Vector3(tx, 46.4, tz) + d * 0.5 * s2, 0.25, 0.2)
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
	lm.lathe("Lamp", lamp - Vector3(0, h * 0.09, 0), FhU.ball(h * 0.09), 12)

# --- Hotel Torni --------------------------------------------------------

## Jung & Jung's Torni (1931), 13 storeys and 70 m, the tallest building
## in Helsinki on completion; origin at the OSM footprint centre (registry
## yaw -35, the block turned onto Yrjönkatu), parts after the OSM 3D
## outline: the 30 m square six-storey base with its shopfront plinth,
## the setback storey and the flanking wings (24 m), the slender 7.6 x
## 19.7 m Art Deco tower slab ribbed by vertical piers to 45 m, the glazed
## Ateljee Bar storey and terraces (49 m), the lantern (58 m) and the mast.
static func torni(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D8D0BC", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EDE6D2", 2.5))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Sign", LandmarkMaterials.lit("#D8322A", 0.6))
	# Base block: granite shopfront storey, five rendered storeys, cornice.
	var bx := 0.2
	var bz := 1.15
	var bw := 29.8
	var bd := 30.3
	FhU.blk(lm, "Plinth", bx, 0.0, bz, bw + 0.3, 4.2, bd + 0.3)
	FhU.blk(lm, "Wall", bx, 4.2, bz, bw, 14.6, bd)
	for face in FhP.faces(bx, bz, bw, bd):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		FhP.pierce(lm, "Wall", "Glass", fa, fb, fo, 4.2, 14.2, 9, 4, Vector2(1.5, 1.9), 0.9, 3.4, 0.25)
		FhU.openings(lm, "Glass", fa, fb, fo, 0.4, 5, 3.6, 3.0, false, 0.04)
		FhP.band(lm, "Trim", fa, fb, fo, 4.0, 0.4, 0.3)
		LandmarkDetail.cornice(lm, "Trim", fa + Vector3(0, 18.2, 0), fb + Vector3(0, 18.2, 0), fo, 0.6, false)
	# Setback storey and the wings either side of the tower.
	FhU.blk(lm, "Wall", -0.95, 18.8, 0.95, 27.5, 2.2, 26.7)
	FhU.blk(lm, "Trim", -0.95, 20.8, 0.95, 27.9, 0.25, 27.1)
	for wg in [[-9.05, -5.2, 11.3, 7.4], [6.9, 0.95, 5.6, 19.7], [-6.05, 7.2, 5.5, 7.0]]:
		FhU.blk(lm, "Wall", float(wg[0]), 21.0, float(wg[1]), float(wg[2]), 3.0, float(wg[3]))
		FhU.blk(lm, "Trim", float(wg[0]), 23.8, float(wg[1]), float(wg[2]) + 0.3, 0.25, float(wg[3]) + 0.3)
	# The tower slab, its vertical piers and windows between them.
	var tx := 0.3
	var tz := 0.95
	var tw := 7.6
	var td := 19.7
	FhU.blk(lm, "Wall", tx, 21.0, tz, tw, 24.0, td)
	for face in FhP.faces(tx, tz, tw, td):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		var n := 2 if fa.distance_to(fb) < 10.0 else 5
		FhP.pierce(lm, "Wall", "Glass", fa, fb, fo, 24.0, 20.6, n, 6, Vector2(1.3, 2.0), 0.6, 3.3, 0.2)
		FhP.ribs(lm, "Trim", fa, fb, fo, 24.0, 44.6, fa.distance_to(fb) / float(n), 0.45, 0.45)
	# Side fins rising the tower's full height on the long faces.
	for s in [-1.0, 1.0]:
		FhU.blk(lm, "Wall", tx + s * 4.5, 21.0, 1.05, 1.4, 24.0, 8.0)
	FhU.blk(lm, "Trim", tx, 44.6, tz, tw + 0.6, 0.4, td + 0.6)
	# Ateljee Bar: glazed storey with the terrace rails round it.
	FhU.blk(lm, "Glass", tx, 45.0, 1.0, 7.4, 3.6, 10.4)
	FhP.ribs(lm, "Trim", Vector3(tx - 3.7, 0, 6.2), Vector3(tx + 3.7, 0, 6.2), Vector3(0, 0, 1), 45.0, 48.6, 1.2, 0.15, 0.1)
	FhP.ribs(lm, "Trim", Vector3(tx + 3.7, 0, -4.2), Vector3(tx - 3.7, 0, -4.2), Vector3(0, 0, -1), 45.0, 48.6, 1.2, 0.15,
		0.1)
	for s in [-1.0, 1.0]:
		FhP.ribs(lm, "Trim", Vector3(tx + s * 3.7, 0, -4.2), Vector3(tx + s * 3.7, 0, 6.2), Vector3(s, 0, 0), 45.0, 48.6,
			1.3, 0.15, 0.1)
	FhU.blk(lm, "Trim", tx, 48.6, 1.0, 7.8, 0.4, 10.8)
	for z in [-6.6, 8.6]:
		lm.box("Trim", Vector3(tx, 45.55, z), Vector3(7.4, 1.1, 0.1), Basis(), 0.0)
	# Lantern: stepped shaft with vertical slits, copper cap, mast.
	FhU.blk(lm, "Wall", 0.35, 49.0, 1.05, 4.2, 3.0, 4.2)
	FhU.blk(lm, "Wall", 0.35, 52.0, 1.05, 2.9, 5.0, 3.0)
	for face in FhP.faces(0.35, 1.05, 2.9, 3.0):
		FhU.openings(lm, "Glass", face[0], face[1], face[2], 52.6, 2, 0.4, 3.6, false, 0.03)
	FhU.blk(lm, "Trim", 0.35, 57.0, 1.05, 3.3, 0.3, 3.4)
	FhU.hip(lm, "Copper", Vector3(0.35, 57.3, 1.05), 3.1, 3.2, 1.2, 0.3)
	lm.frustum("Copper", Vector3(0.4, 58.5, 1.0), 0.35, 0.08, 11.0, 8)
	lm.lathe("Copper", Vector3(0.4, 69.2, 1.0), FhU.ball(0.15), 8)
	# The red sign band on the tower's street face.
	lm.box("Sign", Vector3(tx, 42.4, tz + td * 0.5 + 0.3), Vector3(6.0, 1.2, 0.15))
	lm.commit(model)

# --- Old Market Hall -----------------------------------------------------

## Gustaf Nyström's Vanha kauppahalli (1888-89), origin at the OSM
## footprint centre, front +Z toward the Market Square (registry yaw
## -93): the low-slung 85 x 17 m neo-Renaissance hall in red brick
## striped with cream courses, round-headed windows between pilasters
## along both long sides, the low metal roof with its ridge lantern, the
## gabled entrance pavilions mid-way along both sides, and the end
## gables (the year 1888 on the southern one) flanked by slim corner
## turrets under spires.
static func markethall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F4A38", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D9D0BC", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	var x0 := -42.5
	var x1 := 42.8
	var cx := (x0 + x1) * 0.5
	var z0 := -9.0
	var z1 := 7.7
	var cz := (z0 + z1) * 0.5
	var w := x1 - x0
	var d := z1 - z0
	var eave := 8.2
	FhU.blk(lm, "Plinth", cx, 0.0, cz, w + 0.4, 1.0, d + 0.4)
	FhU.blk(lm, "Brick", cx, 1.0, cz, w, eave - 1.0, d)
	# Cream stripes and the eaves cornice.
	for k in 4:
		FhP.box_band(lm, "Trim", cx, cz, w, d, 1.6 + 1.5 * float(k), 0.3, 0.04)
	FhP.box_band(lm, "Trim", cx, cz, w, d, eave - 0.6, 0.6, 0.3)
	FhU.ridge_x(lm, "Copper", "Brick", Vector3(cx, eave, cz), w, d, 4.0, 0.6)
	# Ridge lantern with its clerestory glazing.
	FhU.blk(lm, "Brick", cx, eave + 2.6, cz, w - 14.0, 1.6, 3.6)
	FhU.blk(lm, "Glass", cx, eave + 2.8, cz, w - 13.8, 1.0, 3.7)
	FhU.ridge_x(lm, "Copper", "Copper", Vector3(cx, eave + 4.2, cz), w - 14.0, 3.6, 1.0, 0.3)
	# Long sides: round-headed windows between pilasters, either side of
	# the entrance pavilions.
	for s in [-1.0, 1.0]:
		var z: float = z1 if s > 0.0 else z0
		var o := Vector3(0, 0, s)
		for seg in [[x0 + 1.0, -6.6], [7.5, x1 - 1.0]]:
			var a := Vector3(float(seg[0]), 0, z)
			var b := Vector3(float(seg[1]), 0, z)
			var n := int(a.distance_to(b) / 3.4)
			FhP.win_row(lm, "Trim", "Glass", a, b, o, 2.0, n, 1.8, 4.6, true, 0.25)
			FhP.strips(lm, "Brick", a, b, o, 1.0, eave - 1.6, n + 1, 0.6, 0.25)
		# Entrance pavilion: gable front, arched portal with filigree frame, steps.
		var ez: float = z + s * 1.25
		FhU.blk(lm, "Brick", 0.45, 0.0, ez - s * 0.6, 12.3, 10.6, 3.7)
		FhU.ridge_z(lm, "Copper", "Brick", Vector3(0.45, 10.6, ez - s * 1.6), 12.3, 5.7, 3.6, 0.3)
		FhP.box_band(lm, "Trim", 0.45, ez - s * 0.6, 12.3, 3.7, 10.0, 0.6, 0.2)
		var face := Vector3(0.45, 0, ez + s * 1.25)
		LandmarkDetail.arch(lm, "Trim", face + Vector3(0, 5.6, 0), o, 4.2, 0.5, 0.35)
		lm.quad("Glass", face + Vector3(-2.1, 1.0, s * 0.02), face + Vector3(2.1, 1.0, s * 0.02),
			face + Vector3(2.1, 5.6, s * 0.02), face + Vector3(-2.1, 5.6, s * 0.02), o)
		for k in 3:
			lm.box("Trim", face + Vector3(-1.4 + 1.4 * float(k), 3.3, s * 0.05), Vector3(0.1, 4.6, 0.1), Basis(), 0.0)
		FhP.strips(lm, "Trim", face + Vector3(-5.6, 0, 0), face + Vector3(5.6, 0, 0), o, 1.0, 9.0, 2, 0.9, 0.3)
		lm.disc("Glass", face + Vector3(0, 11.6, s * 0.03), o, 0.9, 14)
		FhP.ring(lm, "Trim", face + Vector3(0, 11.6, 0), o, 0.9, 1.2, 0.2, 14)
		lm.spire("Copper", face + Vector3(0, 14.1, -s * 0.2), 0.3, 1.6, 0.0, 4)
		FhU.steps(lm, "Plinth", face, o, 6.0, 0.4, 0.2, 3)
	# Gable ends: windows, the date panel and the corner turrets.
	for s in [-1.0, 1.0]:
		var x: float = x1 if s > 0.0 else x0
		var o := Vector3(s, 0, 0)
		FhP.win_row(lm, "Trim", "Glass", Vector3(x, 0, z0 + 2.0), Vector3(x, 0, z1 - 2.0), o, 2.0, 3, 1.8, 4.6, true)
		FhU.blk(lm, "Trim", x + s * 0.1, 9.4, cz, 0.3, 1.0, 3.4)
		lm.disc("Glass", Vector3(x + s * 0.05, 10.8, cz), o, 0.8, 14)
		for tz in [z0 + 0.9, z1 - 0.9]:
			var tc := Vector3(x - s * 0.9, 0, float(tz))
			lm.frustum("Brick", tc, 1.5, 1.5, 13.4, 8, PI / 8.0)
			lm.frustum("Trim", tc + Vector3(0, 7.6, 0), 1.65, 1.65, 0.4, 8, PI / 8.0)
			lm.frustum("Trim", tc + Vector3(0, 13.0, 0), 1.75, 1.75, 0.5, 8, PI / 8.0)
			for k in 8:
				var a := TAU * (float(k) + 0.5) / 8.0
				lm.box("Glass", tc + Vector3(cos(a), 0, sin(a)) * 1.4 + Vector3(0, 11.0, 0), Vector3(0.6, 1.6, 0.05),
					Basis.looking_at(Vector3(cos(a), 0, sin(a))), 0.0)
			lm.spire("Copper", tc + Vector3(0, 13.5, 0), 1.6, 5.2, 0.0, 8)
			lm.box("Copper", tc + Vector3(0, 18.85, 0), Vector3(0.12, 0.3, 0.12), Basis(), 0.0)
	lm.commit(model)

# --- National Library of Finland --------------------------------------

## Engel's university library (1845), origin at the OSM footprint centre
## (registry yaw -3): the Empire block of pale ochre render over a
## rusticated ground floor, round-arched windows below and tall windows
## above, the east front on Unioninkatu with its colonnade of six
## Corinthian columns and attic; the copper dome on its windowed drum
## over the central Dome Hall; and on the west the semicircular Rotunda
## book stack (Nyström, 1906) under its lean-to roofs and skylights.
static func natlibrary(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E4D2A4", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F0EBDD", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5A6068", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	var x0 := -8.6
	var x1 := 21.2
	var z0 := -23.2
	var z1 := 23.9
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var w := x1 - x0
	var d := z1 - z0
	var eave := 14.0
	FhU.blk(lm, "Plinth", cx, 0.0, cz, w + 0.6, 1.6, d + 0.6)
	FhU.blk(lm, "Wall", cx, 1.6, cz, w, eave - 1.6, d)
	for k in 3:
		FhP.box_band(lm, "Wall", cx, cz, w, d, 2.6 + 1.2 * float(k), 0.12, 0.06)
	FhP.box_band(lm, "Trim", cx, cz, w, d, 6.3, 0.45, 0.2)
	for face in FhP.faces(cx, cz, w, d):
		LandmarkDetail.cornice(lm, "Trim", (face[0] as Vector3) + Vector3(0, eave - 0.9, 0),
			(face[1] as Vector3) + Vector3(0, eave - 0.9, 0), face[2], 0.9, true)
	FhU.hip(lm, "Roof", Vector3(cx, eave, cz), w + 0.8, d + 0.8, 2.4, 0.3)
	# Long fronts: arched ground-floor windows, tall windows above, a
	# pilastered centre bay.
	for s in [-1.0, 1.0]:
		var z: float = z1 if s > 0.0 else z0
		var o := Vector3(0, 0, s)
		var a := Vector3(x0 + 1.0, 0, z)
		var b := Vector3(x1 - 1.0, 0, z)
		FhP.win_row(lm, "Trim", "Glass", a, b, o, 2.3, 6, 1.6, 3.2, true, 0.22)
		FhP.win_row(lm, "Trim", "Glass", a, b, o, 7.3, 6, 1.8, 4.6, false, 0.25)
		FhP.strips(lm, "Trim", Vector3(cx - 5.2, 0, z), Vector3(cx + 5.2, 0, z), o, 6.8, 6.4, 4, 0.7, 0.3)
	# East front: rusticated arcade, colonnade of six Corinthian columns,
	# entablature and attic.
	var ex := 22.5
	FhU.blk(lm, "Wall", (x1 + ex) * 0.5, 1.6, 0.6, ex - x1, eave - 1.6, 21.4)
	FhU.blk(lm, "Plinth", ex + 0.4, 0.0, 0.6, 2.2, 1.6, 22.0)
	FhU.steps(lm, "Plinth", Vector3(ex + 1.5, 0, 0.6), Vector3(1, 0, 0), 8.0, 0.4, 0.2, 4)
	FhP.win_row(lm, "Trim", "Glass", Vector3(ex, 0, -9.0), Vector3(ex, 0, 10.2), Vector3(1, 0, 0), 2.3, 5, 1.6, 3.4,
		true, 0.22)
	FhP.win_row(lm, "Trim", "Glass", Vector3(ex, 0, -9.0), Vector3(ex, 0, 10.2), Vector3(1, 0, 0), 7.6, 5, 1.6, 3.8,
		false, 0.2)
	for k in 6:
		var z := lerpf(-9.4, 10.6, float(k) / 5.0)
		LandmarkDetail.column(lm, "Trim", Vector3(ex + 0.9, 6.8, z), 0.45, 6.5, "corinthian", 20)
	FhU.blk(lm, "Trim", ex + 0.4, 13.3, 0.6, 2.0, 1.0, 22.2)
	FhU.blk(lm, "Wall", ex - 0.4, 14.3, 0.6, 2.4, 1.6, 21.4)
	LandmarkDetail.cornice(lm, "Trim", Vector3(ex + 0.8, 15.6, -10.5), Vector3(ex + 0.8, 15.6, 11.7), Vector3(1, 0, 0),
		0.6, false)
	FhP.pierce(lm, "Wall", "Glass", Vector3(x1, 0, z0), Vector3(x1, 0, -10.1), Vector3(1, 0, 0), 1.6, 12.0, 3, 2,
		Vector2(1.6, 3.6), 1.0, 5.0, 0.2)
	FhP.pierce(lm, "Wall", "Glass", Vector3(x1, 0, 11.3), Vector3(x1, 0, z1), Vector3(1, 0, 0), 1.6, 12.0, 3, 2,
		Vector2(1.6, 3.6), 1.0, 5.0, 0.2)
	# Rotunda on the west: semicircular book stack, lean-to roofs, skylights.
	var rc := Vector3(-8.3, 0.0, 0.6)
	lm.frustum("Plinth", rc, 15.0, 15.0, 1.6, 24)
	lm.frustum("Wall", rc + Vector3(0, 1.6, 0), 14.7, 14.7, 10.4, 24)
	lm.frustum("Trim", rc + Vector3(0, 11.4, 0), 15.1, 15.1, 0.6, 24)
	lm.lathe("Roof", rc + Vector3(0, 12.0, 0), PackedVector2Array([Vector2(15.2, 0), Vector2(8.0, 1.8)]), 24)
	lm.lathe("Glass", rc + Vector3(0, 13.8, 0), PackedVector2Array([Vector2(8.0, 0), Vector2(2.0, 0.9), Vector2(0.0, 1.0)]),
		24)
	for i in 11:
		var a := PI * (0.55 + 0.9 * float(i) / 10.0)
		var out := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Glass", rc + out * 14.72 + Vector3(0, 6.6, 0), out, 1.4, 6.4, true, 0.2)
		var pa := a + PI * 0.045
		lm.box("Trim", rc + Vector3(cos(pa), 0, sin(pa)) * 14.8 + Vector3(0, 6.6, 0), Vector3(0.6, 9.4, 0.3),
			Basis.looking_at(Vector3(cos(pa), 0, sin(pa))))
	# The Dome Hall: drum with windows and pilasters, copper dome, lantern.
	var dc := Vector3(7.4, 0.0, 0.0)
	lm.frustum("Wall", dc + Vector3(0, 14.4, 0), 7.1, 7.1, 6.0, 32)
	lm.frustum("Trim", dc + Vector3(0, 20.4, 0), 7.5, 7.5, 0.6, 32)
	lm.frustum("Trim", dc + Vector3(0, 14.4, 0), 7.3, 7.3, 0.5, 32)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var o := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Glass", dc + o * 7.12 + Vector3(0, 17.6, 0), o, 1.1, 2.8, true, 0.2)
		var pa := a + PI / 12.0
		lm.box("Trim", dc + Vector3(cos(pa), 0, sin(pa)) * 7.2 + Vector3(0, 17.4, 0), Vector3(0.5, 5.6, 0.25),
			Basis.looking_at(Vector3(cos(pa), 0, sin(pa))))
	LandmarkKits.dome_on_drum(lm, "Trim", "Copper", dc + Vector3(0, 21.0, 0), 5.85, 0.0, 5.2, 0.0, 32, 16)
	lm.frustum("Trim", dc + Vector3(0, 26.2, 0), 1.2, 1.1, 1.3, 16)
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.box("Glass", dc + Vector3(cos(a), 0, sin(a)) * 1.1 + Vector3(0, 26.85, 0), Vector3(0.5, 0.8, 0.05),
			Basis.looking_at(Vector3(cos(a), 0, sin(a))), 0.0)
	lm.lathe("Copper", dc + Vector3(0, 27.5, 0), PackedVector2Array([Vector2(1.3, 0), Vector2(0.6, 0.3), Vector2(0, 0.5)]), 16)
	lm.commit(model)
