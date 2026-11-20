extends RefCounted

## Suomenlinna Church (Suomenlinnan kirkko), Iso Mustasaari. Built 1854 as
## the Russian Orthodox garrison church, a Lutheran church since 1918, and
## since the 1920s a lighthouse: the lantern in its central tower is a
## navigation light for the harbour approach.
##
## Frame: origin at the OSM footprint centre (way 117426288), the porch on
## -X and the apse on +X, the same frame the older suomenlinna_fortress
## model uses, so the registry yaw -62 (+X turned to north-north-east)
## applies to both. Measured from OSM: the 23.1 x 23.4 m main block, the
## 5.4 x 11 m porch and the round-ended 11 m wide apse (33.5 x 23.4 m in
## all). Heights are read off photographs, scaled by the 23 m front wall
## and checked against the published 42 m total (LoD2 40.6 m):
## - the render is pale sand ("lightyellow" in OSM) over a pink-grey granite
##   plinth, with a flat cornice and a thin copper flashing;
## - the front wall carries a round window with a blue glass rose over the
##   low arched door and tall round-headed windows with blue leaded glass;
## - the central square tower rises from the roof to a cornice, a dark
##   iron balustrade round a smaller clock drum, a verdigris dome and the
##   glazed lantern with its gallery rail and a spike;
## - four low round drums stand at the corners of the roof, remnants of
##   the Orthodox domes taken down for the Lutheran conversion;
## - the garden is fenced by 1870s cannon barrels, three to a granite
##   plinth, hung with heavy chains.
## Built under the registry type suomenlinna_fortress (the church is that
## anchor; a second suomenlinna_church row would stand a duplicate on it).
## Estimated, not measured: eave height, tower and drum heights, window
## counts on the long sides, the fence line.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "suomenlinna_church", "name": "Suomenlinna Church", "lat": 60.14789, "lon": 24.98641,
	"radius_m": 1500.0, "wiki_title": "Suomenlinna Church", "height_m": 42.0, "clear_m": 27.0,
	"yaw_deg": -62.0, "kind": "Church", "aliases": ["suomenlinna church", "suomenlinnan kirkko", "sveaborgs kyrka"]}

## Main block x -11.55..11.55, z -11.7..11.7; porch to x = -16.95, apse
## centred x = 11.55.
const HX := 11.55
const HZ := 11.7
const PORCH_X := 16.95
const APSE_R := 5.5
const PLINTH := 1.2
const EAVE := 15.0
## Tower shaft top, drum top, dome base and the lantern parts.
const SHAFT := 11.0
const T_TOP := 27.0
const DRUM := 29.8
const DOME_H := 3.6
const TOP := 42.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E3D2A9", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7E2D0", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A58F8A", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5F9C88", 2.0, 0.45, 0.35))
	lm.use("Roof", LandmarkMaterials.paint("#5A5E5C", 0.7))
	lm.use("Blue", LandmarkMaterials.paint("#4B7DB8", 0.3, 0.15))
	lm.use("Iron", LandmarkMaterials.paint("#26292B", 0.55, 0.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFE7A6", 1.1))
	lm.use("Gravel", LandmarkMaterials.pbr("gravel", "#B4A890", 3.0))
	_body(lm)
	_front(lm)
	_sides(lm)
	_tower(lm)
	_fence(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.HALO_META, [[Vector3(0, 35.7, 0), 5.0, Color(1.0, 0.86, 0.6)]])
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-30.0, 1.5, 0.0), Vector3(-12.0, 11.0, 0.0), 38.0, 0.9, 60.0, Color(1.0, 0.88, 0.7)],
		[Vector3(0.0, 1.5, -26.0), Vector3(0.0, 12.0, -11.7), 38.0, 0.7, 50.0, Color(1.0, 0.88, 0.7)],
		[Vector3(0.0, 1.5, 26.0), Vector3(0.0, 12.0, 11.7), 38.0, 0.7, 50.0, Color(1.0, 0.88, 0.7)]])

## Plinth, the render block, the porch, the apse and the corner drums.
static func _body(lm: LandmarkMesh) -> void:
	lm.box("Gravel", Vector3(-1.0, 0.03, 0.0), Vector3(52.0, 0.06, 40.0))
	U.blk(lm, "Granite", 0.0, 0.0, 0.0, 2.0 * HX + 0.8, PLINTH, 2.0 * HZ + 0.8)
	U.blk(lm, "Wall", 0.0, PLINTH, 0.0, 2.0 * HX, EAVE - PLINTH, 2.0 * HZ)
	# Cornice: a plain projecting band under a thin copper flashing.
	U.blk(lm, "Trim", 0.0, EAVE - 0.9, 0.0, 2.0 * HX + 0.8, 0.9, 2.0 * HZ + 0.8)
	U.blk(lm, "Copper", 0.0, EAVE, 0.0, 2.0 * HX + 1.0, 0.12, 2.0 * HZ + 1.0)
	U.blk(lm, "Roof", 0.0, EAVE + 0.12, 0.0, 2.0 * HX - 0.6, 0.3, 2.0 * HZ - 0.6)
	# Porch: a full-height render box on the front, 11 m wide, its cornice
	# level with the main one; the door and the rose window are on its face.
	var px := -(HX + PORCH_X) * 0.5
	var pw := PORCH_X - HX
	U.blk(lm, "Granite", px - 0.2, 0.0, 0.0, pw + 0.4, PLINTH, 11.4)
	U.blk(lm, "Wall", px, PLINTH, 0.0, pw, EAVE - PLINTH, 11.0)
	U.blk(lm, "Trim", px, EAVE - 0.9, 0.0, pw + 0.8, 0.9, 11.8)
	U.blk(lm, "Copper", px, EAVE, 0.0, pw + 1.0, 0.12, 12.0)
	# Apse: a half drum ending the nave, its cornice and flat roof.
	lm.frustum("Granite", Vector3(HX, 0, 0), APSE_R + 0.4, APSE_R + 0.4, PLINTH, 20)
	lm.frustum("Wall", Vector3(HX, PLINTH, 0), APSE_R, APSE_R, 9.5 - PLINTH, 20)
	lm.frustum("Trim", Vector3(HX, 8.8, 0), APSE_R + 0.4, APSE_R + 0.4, 0.7, 20)
	lm.frustum("Copper", Vector3(HX, 9.5, 0), APSE_R + 0.5, 0.2, 1.6, 20)
	for k in 3:
		var a := PI * (float(k) - 1.0) / 3.0
		var o := Vector3(cos(a), 0, sin(a))
		U.opening(lm, "Blue", Vector3(HX, 2.6, 0) + o * (APSE_R + 0.04), o, 1.3, 4.2, true)
	# Corner drums: the Orthodox dome bases, kept low with a flat cap.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(sx * (HX - 2.8), EAVE, sz * (HZ - 2.8))
			lm.frustum("Wall", c, 2.0, 2.0, 1.7, 16)
			lm.frustum("Trim", c + Vector3(0, 1.7, 0), 2.25, 2.25, 0.3, 16)
			lm.frustum("Copper", c + Vector3(0, 2.0, 0), 2.1, 0.8, 0.4, 16)
			U.opening(lm, "Blue", c + Vector3(sx * 2.02, 0.2, 0), Vector3(sx, 0, 0), 0.6, 1.2, true)

## Front wall: round rose window, the low arched door and its steps, two
## tall round-headed windows.
static func _front(lm: LandmarkMesh) -> void:
	var out := Vector3(-1, 0, 0)
	var fx := -PORCH_X
	var cy := 10.2
	# Rose window: dark ring, blue glass, eight spokes.
	FhP.ring(lm, "Iron", Vector3(fx - 0.02, cy, 0), out, 0.85, 1.05, 0.12, 24)
	lm.disc("Blue", Vector3(fx - 0.04, cy, 0), out, 0.85, 24)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.beam("Iron", Vector3(fx - 0.08, cy, 0), Vector3(fx - 0.08, cy + sin(a) * 0.85, cos(a) * 0.85), 0.07, 0.05)
	FhP.ring(lm, "Trim", Vector3(fx - 0.01, cy, 0), out, 1.05, 1.3, 0.16, 24)
	# Tall windows either side of the porch.
	for s in [-1.0, 1.0]:
		FhP.win_row(lm, "Trim", "Blue", Vector3(-HX, 0, s * 8.6), Vector3(-HX, 0, s * 8.6), out, 6.2, 1, 1.6, 6.4, true, 0.2)
	# The porch door on its front face: arched, dark, with a small fanlight.
	var dx := fx
	U.opening(lm, "Iron", Vector3(dx - 0.03, PLINTH, 0), out, 1.8, 2.8, true)
	FhP.ring(lm, "Trim", Vector3(dx - 0.01, PLINTH + 1.9, 0), out, 0.9, 1.2, 0.12, 14)
	U.steps(lm, "Granite", Vector3(dx - 0.2, 0, 0), out, 4.4, 0.4, 0.2, 5)
	# Pilasters on the front wall, either side of the porch roof.
	FhP.strips(lm, "Trim", Vector3(-HX, 0, -HZ + 0.3), Vector3(-HX, 0, HZ - 0.3), out, PLINTH, EAVE - PLINTH - 0.9, 2, 0.6, 0.18)

## The long sides and the back: tall round-headed windows in blue glass.
static func _sides(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var out := Vector3(0, 0, s)
		FhP.win_row(lm, "Trim", "Blue", Vector3(-HX + 3.2, 0, s * HZ), Vector3(HX - 3.2, 0, s * HZ), out,
			4.2, 4, 1.8, 7.6, true, 0.2)
		FhP.strips(lm, "Trim", Vector3(-HX + 0.3, 0, s * HZ), Vector3(HX - 0.3, 0, s * HZ), out, PLINTH,
			EAVE - PLINTH - 0.9, 2, 0.6, 0.18)
	# Back wall, either side of the apse.
	for s in [-1.0, 1.0]:
		FhP.win_row(lm, "Trim", "Blue", Vector3(HX, 0, s * 9.2), Vector3(HX, 0, s * 9.2), Vector3(1, 0, 0),
			4.2, 1, 1.6, 7.0, true, 0.2)

## The tower: shaft with narrow windows, cornice and balustrade, the clock
## drum, the verdigris dome, and the lantern.
static func _tower(lm: LandmarkMesh) -> void:
	var w := SHAFT
	U.blk(lm, "Wall", 0.0, EAVE, 0.0, w, T_TOP - EAVE, w)
	# Narrow windows and corner strips on all four faces.
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out: Vector3 = b * Vector3(0, 0, 1)
		var rt: Vector3 = b * Vector3(1, 0, 0)
		var fc := out * (w * 0.5)
		FhP.win_row(lm, "Trim", "Blue", fc, fc, out, EAVE + 4.5, 1, 1.3, 6.0, true, 0.18)
		for s in [-1.0, 1.0]:
			lm.box("Copper", Vector3(0, (EAVE + T_TOP) * 0.5, 0) + fc + rt * s * (w * 0.5 - 0.35) + out * 0.04,
				Vector3(0.14, T_TOP - EAVE, 0.08), b)
	# Cornice and the iron balustrade.
	U.blk(lm, "Trim", 0.0, T_TOP - 0.2, 0.0, w + 1.4, 0.9, w + 1.4)
	U.blk(lm, "Copper", 0.0, T_TOP + 0.7, 0.0, w + 1.5, 0.1, w + 1.5)
	var half := w * 0.5 + 0.55
	for i in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(i))
		var a: Vector3 = b * Vector3(-half, T_TOP + 0.8, half)
		var c: Vector3 = b * Vector3(half, T_TOP + 0.8, half)
		lm.beam("Iron", a + Vector3(0, 0.95, 0), c + Vector3(0, 0.95, 0), 0.08, 0.08)
		lm.beam("Iron", a + Vector3(0, 0.25, 0), c + Vector3(0, 0.25, 0), 0.06, 0.06)
		for k in 9:
			var p := a.lerp(c, float(k) / 8.0)
			lm.beam("Iron", p, p + Vector3(0, 0.95, 0), 0.06, 0.06)
	# Clock drum with a dial on each face, and its cornice.
	var dw := 7.4
	U.blk(lm, "Wall", 0.0, T_TOP + 0.8, 0.0, dw, DRUM - T_TOP - 0.8, dw)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out: Vector3 = b * Vector3(0, 0, 1)
		lm.disc("Trim", out * (dw * 0.5 + 0.03) + Vector3(0, T_TOP + 1.9, 0), out, 0.8, 16)
		lm.disc("Iron", out * (dw * 0.5 + 0.05) + Vector3(0, T_TOP + 1.9, 0), out, 0.62, 16)
		lm.beam("Trim", out * (dw * 0.5 + 0.07) + Vector3(0, T_TOP + 1.9, 0), out * (dw * 0.5 + 0.07) + Vector3(0, T_TOP + 2.4, 0), 0.07, 0.04)
	U.blk(lm, "Trim", 0.0, DRUM - 0.1, 0.0, dw + 0.9, 0.5, dw + 0.9)
	# Dome, its neck, the gallery, the glazed lantern, cap and spike.
	var db := DRUM + 0.4
	var prof := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0 * PI * 0.5
		prof.append(Vector2(4.1 * cos(t), DOME_H * sin(t)))
	lm.lathe("Copper", Vector3(0, db, 0), prof, 24)
	var ny := db + DOME_H
	lm.frustum("Copper", Vector3(0, ny - 0.1, 0), 1.6, 1.6, 0.8, 16)
	lm.frustum("Trim", Vector3(0, ny + 0.6, 0), 2.2, 2.2, 0.2, 16)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.beam("Iron", Vector3(cos(a) * 2.1, ny + 0.8, sin(a) * 2.1), Vector3(cos(a) * 2.1, ny + 1.6, sin(a) * 2.1), 0.07, 0.07)
	lm.frustum("Iron", Vector3(0, ny + 1.6, 0), 2.18, 2.18, 0.08, 16)
	lm.frustum("Lamp", Vector3(0, ny + 0.8, 0), 1.25, 1.25, 2.2, 12)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.beam("Iron", Vector3(cos(a) * 1.27, ny + 0.8, sin(a) * 1.27), Vector3(cos(a) * 1.27, ny + 3.0, sin(a) * 1.27), 0.1, 0.1)
	var cap := ny + 3.0
	lm.frustum("Copper", Vector3(0, cap, 0), 1.7, 0.1, 1.8, 12)
	lm.lathe("Gold", Vector3(0, cap + 1.7, 0), U.ball(0.32), 8)
	lm.beam("Gold", Vector3(0, cap + 2.0, 0), Vector3(0, TOP, 0), 0.08, 0.08)

## The cannon fence: barrels three to a granite plinth, chains between.
static func _fence(lm: LandmarkMesh) -> void:
	var ring := PackedVector2Array([Vector2(-19.5, -14.5), Vector2(19.5, -14.5), Vector2(19.5, 14.5), Vector2(-19.5, 14.5)])
	var prev := Vector3.ZERO
	var first := true
	for i in 4:
		var p0 := ring[i]
		var p1 := ring[(i + 1) % 4]
		var n := maxi(int(p0.distance_to(p1) / 6.0), 1)
		for k in n:
			var p := p0.lerp(p1, float(k) / float(n))
			if absf(p.y) < 6.5 and p.x < -18.0:
				first = true  # open at the porch approach
				continue
			var base := Vector3(p.x, 0.0, p.y)
			U.blk(lm, "Granite", base.x, 0.0, base.z, 0.9, 0.7, 0.9)
			for j in 3:
				var off := Vector3((float(j) - 1.0) * 0.3, 0, 0.0) if i % 2 == 0 else Vector3(0, 0, (float(j) - 1.0) * 0.3)
				var h := 2.4 if j == 1 else 1.7
				lm.frustum("Iron", base + off + Vector3(0, 0.7, 0), 0.19, 0.15, h, 8)
				lm.lathe("Iron", base + off + Vector3(0, 0.7 + h, 0), U.ball(0.1), 6)
			var top := base + Vector3(0, 2.3, 0)
			if not first:
				var mid := (prev + top) * 0.5 - Vector3(0, 0.7, 0)
				lm.beam("Iron", prev, mid, 0.09, 0.09)
				lm.beam("Iron", mid, top, 0.09, 0.09)
			prev = top
			first = false
