extends RefCounted

## Kulturhuset with Sergels torg (Peter Celsing, 1974; plaza by Celsing and
## Edvin Ohrstrom), the Kristallvertikalaccent and the triangle-paved plaza.
## Origin at the centroid of the Kulturhuset block (OSM way 40859302,
## 160.6 x 24.8 m), long axis +X; the registry yaw (-26) turns it onto the
## mapped bearing 64. Local -Z (bearing 334) is the plaza side, so Sergels
## torg lies to -Z and the slab's glass front faces it. The registry clears
## the whole rectangle (slab, plaza, fountain) with `clear_rect_m`.
##
## Plan in this frame (from the OSM ways of docs/stockholm-landmark-sources.md):
## the slab x +-80.3, z +-12.4; the sunken plaza (way 12108162, 65 x 42.5 m)
## centred at (-36.2, -42.9); the Sergelfontänen basin (way 40095637,
## 45 x 40 m) and the obelisk (way 41235274) at (39.5, -48.9).
##
## From the photos (front, quarter, side in visual-plan/refs/landmarks/
## kulturhuset_sergels_torg/):
## - The Kulturhuset is a long five-tier slab of dark glass and raw
##   concrete: every storey is a continuous glazed band under a deep
##   concrete floor edge, and each tier steps back 0.9 m from the one
##   below, so the glass front leans back over the plaza. The rear
##   (Drottninggatan side) is a concrete wall with ribbon windows. The
##   east end carries a taller blank concrete block for the KULTURHUSET sign.
##   Red STADSTEATERN neon stands on the first floor edge. The glass is
##   translucent and set 0.85 m under each floor edge, so the floor slabs,
##   the lit back wall and the mullions read through it.
## - Before the slab lies the triangle-paved plaza: large dark and light
##   grey triangles, ringed by a granite kerb and a steel railing on the
##   far sides. The plaza is laid at street level here (the real one sinks
##   4.6 m below the deck); LandmarkStairCut holds the terrain under the
##   whole site just under the paving so the slab is never buried.
## - In the Sergelfontänen basin, ringed by a low granite rim with its
##   water jets, stands the Kristallvertikalaccent: 37.5 m of dark glass
##   blocks banded by steel collars, 5.7 m square at the foot and slimmer
##   toward the top, lit from within at night.
## Tier heights, collars and the plaza texture are scaled from the photos;
## the slab roof stands at 23.6 m, the sign block at 29 m.

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")

const HX := 80.3
const HZ := 12.4
const TIERS := [0.0, 5.2, 9.8, 14.4, 19.0, 23.6]
const EDGE := 0.9
const STEP := 0.9
const PLAZA_C := Vector2(-36.2, -42.9)
const PLAZA_HX := 32.5
const PLAZA_HZ := 21.25
const OBELISK_C := Vector2(39.5, -48.9)
const OBELISK_TOP := 37.5
const SIGN_TOP := 29.0
## Height of a glass pane: a storey less its floor edge and sill slab.
const PANE_H := 3.4
## Paving top: LandmarkStairCut holds the whole site level 0.3 m over the
## model's y = 0, so the paving is laid a low platform's height over that
## (the ground's own paving layers lie just over the terrain).
const PAVE_Y := 0.55
## The basin rim's walls reach this far under y = 0, down into the carved
## dish the mapped water polygon leaves in the terrain, so no pale gap shows
## under the rim (tests/stockholm_hero_landmarks_test.gd allows it here).
const SKIRT_Y := -2.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#737169", 3.0))
	lm.use("GlassLamp", _curtain_glass())
	lm.use("Interior", _interior())
	lm.use("Mull", LandmarkMaterials.paint("#B9BEC2", 0.4, 0.6))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A44"))
	lm.use("Steel", LandmarkMaterials.paint("#2F3235", 0.5, 0.5))
	lm.use("Pave", LandmarkMaterials.pbr("stone", "#8E8C88", 3.0))
	lm.use("Tri", _triangle_paving())
	lm.use("Water", _basin_water())
	lm.use("ObeliskLamp", _warm_glass("#5A544C", "#DDE8FF", 0.5))
	lm.use("NeonLamp", LandmarkMaterials.lit("#FF2A24", 0.7))
	lm.use("Spray", LandmarkMaterials.paint("#E8EEF0", 0.4, 0.1))
	_slab(lm)
	_rear(lm)
	_roof(lm)
	_signs(lm)
	_plaza(lm)
	_fountain(lm)
	_obelisk(lm)
	lm.commit(model)
	# Night: the plaza and the obelisk base are washed from the slab side.
	var cool := Color(0.86, 0.9, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-2.0, 3.0, -8.0), Vector3(-36.0, 0.0, -43.0), 60.0, 0.7, 70.0, cool],
		[Vector3(70.0, 2.0, -40.0), Vector3(OBELISK_C.x, 20.0, OBELISK_C.y), 30.0, 0.5, 60.0, cool]])

## Warm-lit glass: glass by day, glowing from inside at night.
static func _warm_glass(hex: String, glow: String, energy: float) -> StandardMaterial3D:
	var m := LandmarkMaterials.glass(hex).duplicate() as StandardMaterial3D
	if hex == "#5A544C":
		m.albedo_color = Color(hex)
	m.emission_enabled = true
	m.emission = Color(glow)
	m.emission_energy_multiplier = 0.0
	m.set_meta(LandmarkLights.NIGHT_GLOW_META, energy)
	return m

## The lit back wall of each storey: pale warm concrete, glowing at night.
static func _interior() -> StandardMaterial3D:
	var m := LandmarkMaterials.pbr("concrete", "#363E48", 3.0, 0.85, 0.0).duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color("#FFD9A0")
	m.emission_energy_multiplier = 0.0
	m.set_meta(LandmarkLights.NIGHT_GLOW_META, 0.6)
	return m

## The Sergelfontänen water: dark, with the sky reflection held down so the
## basin does not blow out white.
static func _basin_water() -> StandardMaterial3D:
	var m := LandmarkMaterials.pool_water("#3A5964", 0.4).duplicate() as StandardMaterial3D
	m.metallic = 0.0
	m.metallic_specular = 0.25
	return m

## The Kulturhuset's curtain wall: a pane graded per storey (the texture runs
## bottom to top in the pane's own metres), dark and clear at the sill and a
## bright sky-and-horizon reflection at the head, so the glass reads as dark
## reflective glass over the lit floors rather than a flat slate.
static func _curtain_glass() -> StandardMaterial3D:
	var h := 64
	var img := Image.create(1, h, false, Image.FORMAT_RGBA8)
	var dark := Color(0.1, 0.16, 0.2, 0.2)
	var sky := Color(0.72, 0.84, 0.93, 0.78)
	for y in h:
		# y = 0 is the sill; the sky band takes the upper half.
		var t := smoothstep(0.25, 1.0, float(y) / float(h - 1))
		img.set_pixel(0, y, dark.lerp(sky, t))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.35
	m.roughness = 0.04
	m.uv1_scale = Vector3(0.0, -1.0 / PANE_H, 1.0)
	m.texture_repeat = false
	return m

## Sergels torg's pattern: a 12 x 6 m tile cut by both diagonals into four
## triangles, dark above and below, light left and right, so the tiles form
## a lattice of dark and light diamonds.
static func _triangle_paving() -> StandardMaterial3D:
	var w := 192
	var h := 96
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var dx := (float(x) + 0.5) / float(w) - 0.5
			var dy := (float(y) + 0.5) / float(h) - 0.5
			var c := Color("#CFCFCA")
			if absf(dy) > absf(dx):
				c = Color("#2C2C2F") if dy < 0.0 else Color("#4A4A4E")
			elif dx > 0.0:
				c = Color("#E4E4DF")
			var edge := minf(absf(absf(dy) - absf(dx)) * float(h), 1.0)
			img.set_pixel(x, y, c.lerp(Color("#7A7A78"), 1.0 - edge) if edge < 1.0 else c)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 0.85
	m.uv1_scale = Vector3(1.0 / 12.0, 1.0 / 6.0, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

# --- The slab ----------------------------------------------------------

## Five stepped tiers: concrete core, the recessed curtain wall, the floor
## edge and the mullions. Behind the glass stand the lit back wall and the
## floor slab of each storey.
static func _slab(lm: LandmarkMesh) -> void:
	for k in 5:
		var y0: float = TIERS[k]
		var y1: float = TIERS[k + 1]
		var zk := -HZ + STEP * float(k)
		K.rb(lm, "Concrete", -HX, HX, y0, y1, zk, HZ, 0.0)
		# The glass wall sits under the floor edge, 0.85 m before the core.
		var gz := zk - 0.85
		lm.quad("Interior", Vector3(-HX, y0 + 0.3, zk - 0.03), Vector3(HX, y0 + 0.3, zk - 0.03),
			Vector3(HX, y1 - EDGE, zk - 0.03), Vector3(-HX, y1 - EDGE, zk - 0.03), Vector3(0, 0, -1))
		# The storey's floor slab, seen through the glass.
		K.rb(lm, "Concrete", -HX, HX, y0, y0 + 0.3, gz, zk, 0.0)
		lm.quad("GlassLamp", Vector3(-HX, y0 + 0.3, gz), Vector3(HX, y0 + 0.3, gz), Vector3(HX, y1 - EDGE, gz),
			Vector3(-HX, y1 - EDGE, gz), Vector3(0, 0, -1))
		# Floor edge, projecting over the band.
		K.rb(lm, "Concrete", -HX - 0.3, HX + 0.3, y1 - EDGE, y1, zk - 0.9, zk + 0.5, 0.0)
		# Mullions every 2.4 m and a transom at the lintel.
		var centres := PackedVector3Array()
		var sizes := PackedVector3Array()
		var n := int(HX * 2.0 / 2.4)
		for i in n + 1:
			var x := -HX + 2.0 * HX * float(i) / float(n)
			centres.append(Vector3(x, (y0 + 0.3 + y1 - EDGE) * 0.5, gz - 0.05))
			sizes.append(Vector3(0.1, y1 - EDGE - y0 - 0.3, 0.12))
		lm.boxes("Mull", centres, sizes, Basis(), 0.0)
		K.rb(lm, "Mull", -HX, HX, y1 - EDGE - 0.1, y1 - EDGE, gz - 0.09, gz - 0.01, 0.0)
		# A steel handrail line on the sill.
		K.rb(lm, "Steel", -HX, HX, y0 + 1.2, y0 + 1.3, gz - 0.1, gz - 0.04, 0.0)

## The Drottninggatan side: concrete with ribbon windows in short runs.
static func _rear(lm: LandmarkMesh) -> void:
	var z := HZ + 0.03
	for k in 5:
		var y0: float = TIERS[k]
		var y1: float = TIERS[k + 1]
		var n := 26
		for i in n:
			var x0 := -HX + 3.0 + (2.0 * HX - 6.0) * float(i) / float(n)
			var x1 := x0 + (2.0 * HX - 6.0) / float(n) - 1.6
			lm.quad("Glass", Vector3(x0, y0 + 1.1, z), Vector3(x1, y0 + 1.1, z), Vector3(x1, y1 - 1.4, z),
				Vector3(x0, y1 - 1.4, z), Vector3(0, 0, 1))
		K.rb(lm, "Concrete", -HX, HX, y1 - 0.25, y1 + 0.05, HZ, HZ + 0.25, 0.0)

## Roof slab, parapet, the taller sign block at the east end and plant.
static func _roof(lm: LandmarkMesh) -> void:
	var top: float = TIERS[5]
	var z4 := -HZ + STEP * 4.0
	K.rb(lm, "Concrete", -HX - 0.3, HX + 0.3, top, top + 0.5, z4 - 0.9, HZ + 0.25, 0.0)
	# The blank sign block over the east end.
	K.rb(lm, "Concrete", 52.0, HX, top, SIGN_TOP, z4 - 0.3, HZ, 0.0)
	K.rb(lm, "Concrete", 51.4, HX + 0.4, SIGN_TOP, SIGN_TOP + 0.4, z4 - 0.7, HZ + 0.4, 0.0)
	# Plant boxes and lift overruns along the roof.
	for x in [-62.0, -38.0, -9.0, 14.0, 30.0]:
		K.rb(lm, "Concrete", x - 3.5, x + 3.5, top + 0.5, top + 2.9, -2.0, 4.5, 0.0)
	for x in [-50.0, -24.0, 3.0, 40.0]:
		K.rb(lm, "Steel", x - 1.2, x + 1.2, top + 0.5, top + 1.7, 5.0, 8.0, 0.0)

## Red neon: KULTURHUSET on the sign block, STADSTEATERN standing on the first
## floor edge, as stroke letters read from the plaza (viewer's right is -X).
static func _signs(lm: LandmarkMesh) -> void:
	var z := -HZ + STEP * 4.0 - 0.45
	_text(lm, "KULTURHUSET", Vector3(79.0, 24.4, z), 2.35, 1.6, 2.6)
	var edge_top: float = TIERS[1]
	_text(lm, "STADSTEATERN", Vector3(-27.0, edge_top, -HZ - 0.6), 2.9, 2.0, 1.5)

## Stroke glyphs on a 1 x 1 box: polylines of (u right, v up) points.
const GLYPHS := {
	"K": [[[0, 0], [0, 1]], [[1, 1], [0, 0.4]], [[0.3, 0.58], [1, 0]]],
	"U": [[[0, 1], [0, 0.15], [0.2, 0], [0.8, 0], [1, 0.15], [1, 1]]],
	"L": [[[0, 1], [0, 0], [1, 0]]],
	"T": [[[0, 1], [1, 1]], [[0.5, 1], [0.5, 0]]],
	"R": [[[0, 0], [0, 1], [0.8, 1], [1, 0.85], [1, 0.65], [0.8, 0.5], [0, 0.5]], [[0.5, 0.5], [1, 0]]],
	"H": [[[0, 0], [0, 1]], [[1, 0], [1, 1]], [[0, 0.5], [1, 0.5]]],
	"S": [[[1, 0.9], [0.8, 1], [0.2, 1], [0, 0.85], [0, 0.65], [0.2, 0.5], [0.8, 0.5], [1, 0.35], [1, 0.15],
		[0.8, 0], [0.2, 0], [0, 0.1]]],
	"E": [[[1, 1], [0, 1], [0, 0], [1, 0]], [[0, 0.5], [0.8, 0.5]]],
	"A": [[[0, 0], [0.5, 1], [1, 0]], [[0.2, 0.4], [0.8, 0.4]]],
	"N": [[[0, 0], [0, 1], [1, 0], [1, 1]]],
	"D": [[[0, 0], [0, 1], [0.7, 1], [1, 0.8], [1, 0.2], [0.7, 0], [0, 0]]],
}

## `word` in neon strokes from `p` (the left end as the plaza sees it, the
## foot of the letters), `pitch` apart, each `w` wide and `h` tall, reading
## toward -X on a face that looks to -Z.
static func _text(lm: LandmarkMesh, word: String, p: Vector3, pitch: float, w: float, h: float) -> void:
	var stroke := minf(0.22, h * 0.09)
	for i in word.length():
		var glyph: Array = GLYPHS.get(word[i], [])
		var o := p + Vector3(-pitch * float(i), 0, 0)
		for line: Array in glyph:
			for j in line.size() - 1:
				var a: Array = line[j]
				var b: Array = line[j + 1]
				lm.beam("NeonLamp", o + Vector3(-float(a[0]) * w, float(a[1]) * h, 0),
					o + Vector3(-float(b[0]) * w, float(b[1]) * h, 0), 0.14, stroke, Vector3(0, 0, -1))

# --- Plaza -----------------------------------------------------------------

## Triangle paving, the kerb, the railing and the paved strip before the slab.
static func _plaza(lm: LandmarkMesh) -> void:
	var x0 := PLAZA_C.x - PLAZA_HX
	var x1 := PLAZA_C.x + PLAZA_HX
	var z0 := PLAZA_C.y - PLAZA_HZ
	var z1 := PLAZA_C.y + PLAZA_HZ
	lm.quad("Tri", Vector3(x0, PAVE_Y, z0), Vector3(x1, PAVE_Y, z0), Vector3(x1, PAVE_Y, z1), Vector3(x0, PAVE_Y, z1), Vector3.UP)
	# Granite kerb round the plaza and a paved strip up to the slab.
	K.rb(lm, "Pave", x0 - 0.6, x1 + 0.6, 0.0, PAVE_Y + 0.04, z0 - 0.6, z0, 0.0)
	K.rb(lm, "Pave", x0 - 0.6, x0, 0.0, PAVE_Y + 0.04, z0, z1, 0.0)
	K.rb(lm, "Pave", x1, x1 + 0.6, 0.0, PAVE_Y + 0.04, z0, z1, 0.0)
	K.rb(lm, "Pave", -HX, HX, 0.0, PAVE_Y - 0.02, -HZ - 1.0, z1, 0.0)
	# Steel railing on the far (north-west) and west edges.
	_rail(lm, Vector3(x0, PAVE_Y, z0 - 0.3), Vector3(x1, PAVE_Y, z0 - 0.3))
	_rail(lm, Vector3(x0 - 0.3, PAVE_Y, z0), Vector3(x0 - 0.3, PAVE_Y, z1))

static func _rail(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	lm.beam("Steel", a + Vector3(0, 1.05, 0), b + Vector3(0, 1.05, 0), 0.08, 0.08)
	lm.beam("Steel", a + Vector3(0, 0.55, 0), b + Vector3(0, 0.55, 0), 0.05, 0.05)
	var n := int(a.distance_to(b) / 2.5)
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		lm.beam("Steel", p, p + Vector3(0, 1.05, 0), 0.07, 0.07)

# --- Fountain and obelisk ---------------------------------------------------

## The Sergelfontänen basin: granite rim, water, a ring of jets.
static func _fountain(lm: LandmarkMesh) -> void:
	var c := OBELISK_C
	var hx := 21.8
	var hz := 19.4
	K.rb(lm, "Pave", c.x - hx - 0.8, c.x + hx + 0.8, SKIRT_Y, 0.8, c.y - hz - 0.8, c.y - hz, 0.0)
	K.rb(lm, "Pave", c.x - hx - 0.8, c.x + hx + 0.8, SKIRT_Y, 0.8, c.y + hz, c.y + hz + 0.8, 0.0)
	K.rb(lm, "Pave", c.x - hx - 0.8, c.x - hx, SKIRT_Y, 0.8, c.y - hz, c.y + hz, 0.0)
	K.rb(lm, "Pave", c.x + hx, c.x + hx + 0.8, SKIRT_Y, 0.8, c.y - hz, c.y + hz, 0.0)
	lm.quad("Water", Vector3(c.x - hx, 0.55, c.y - hz), Vector3(c.x + hx, 0.55, c.y - hz),
		Vector3(c.x + hx, 0.55, c.y + hz), Vector3(c.x - hx, 0.55, c.y + hz), Vector3.UP)
	for k in 14:
		var a := TAU * float(k) / 14.0
		var r := 9.0 + 3.0 * float(k % 3)
		var p := Vector3(c.x + cos(a) * r, 0.55, c.y + sin(a) * r)
		lm.frustum("Spray", p, 0.12, 0.03, 1.6 + 1.1 * float(k % 3), 6)

## The glass obelisk: plinth, then banded blocks and collars tapering to a cap.
static func _obelisk(lm: LandmarkMesh) -> void:
	var c := OBELISK_C
	lm.box("Pave", Vector3(c.x, 0.9, c.y), Vector3(7.4, 1.8, 7.4), Basis(), 0.0)
	var y := 1.8
	var units := 8
	var unit := (OBELISK_TOP - 1.8 - 1.2) / float(units)
	for i in units:
		var t := float(i) / float(units)
		var cw := lerpf(5.7, 4.5, t)
		var bw := lerpf(4.5, 3.4, t)
		lm.box("Steel", Vector3(c.x, y + 0.45, c.y), Vector3(cw, 0.9, cw), Basis(), 0.0)
		y += 0.9
		lm.box("ObeliskLamp", Vector3(c.x, y + (unit - 0.9) * 0.5, c.y), Vector3(bw, unit - 0.9, bw), Basis(), 0.0)
		y += unit - 0.9
	lm.spire("ObeliskLamp", Vector3(c.x, y, c.y), 1.7, OBELISK_TOP - y, 0.12, 4)
