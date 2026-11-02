class_name LandmarkAeJapan
extends RefCounted

## Landmarks of Japan in true metres: Kinkaku-ji (12.5 m: the three-storey
## Golden Pavilion with its phoenix), Himeji Castle (46.4 m: the white
## main keep on its battered stone base, five tiled roofs, two small
## keeps) and the Itsukushima torii (16.6 m: vermilion camphor-wood gate
## standing in the sea, base: water). Halls face south (+Z).

# --- Kinkaku-ji ---

static func kinkakuji(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A857A", 3.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#CDB98F", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shingle", LandmarkMaterials.pbr("wood", "#5E5346", 1.5))
	lm.use("Shadow", LandmarkMaterials.paint("#2A231C", 0.9, 0.0))
	lm.box("Stone", Vector3(0, -0.45, 0), Vector3(14.0, 2.1, 12.0))
	# Shinden-style ground floor: pale wood, dark openings between posts.
	lm.box("Wood", Vector3(0, 2.1, 0), Vector3(11.0, 3.0, 9.0))
	_slots(lm, Vector3(11.0, 1.8, 9.0), 2.1, 4)
	LandmarkAeParts.hip_roof(lm, "Shingle", Vector3(0, 3.6, 0), Vector2(15.4, 13.4), Vector2(9.6, 7.6), 1.0, 0.4)
	# Second and third floors are gilded; each has its own roof.
	lm.box("Gold", Vector3(0, 5.65, 0), Vector3(8.6, 2.7, 7.0))
	_slots(lm, Vector3(8.6, 1.4, 7.0), 5.65, 3)
	LandmarkAeParts.hip_roof(lm, "Shingle", Vector3(0, 7.0, 0), Vector2(12.4, 10.8), Vector2(7.0, 5.4), 1.0, 0.4)
	lm.box("Gold", Vector3(0, 8.65, 0), Vector3(6.2, 2.1, 6.2))
	_slots(lm, Vector3(6.2, 1.2, 6.2), 8.65, 2)
	LandmarkAeParts.hip_roof(lm, "Shingle", Vector3(0, 9.7, 0), Vector2(9.8, 9.8), Vector2(1.0, 1.0), 1.9, 0.4)
	# The bronze phoenix on the peak.
	lm.lathe("Gold", Vector3(0, 11.6, 0), PackedVector2Array([Vector2(0.45, 0), Vector2(0.35, 0.5),
		Vector2(0.05, 12.5 - 11.6)]), 8)
	lm.box("Gold", Vector3(0, 12.0, 0), Vector3(1.6, 0.25, 0.4))
	lm.commit(model)

## Dark window slots, `n` per face, on the four sides of a box of size
## `box` centred at height y.
static func _slots(lm: LandmarkMesh, box: Vector3, y: float, n: int) -> void:
	for s in [-1.0, 1.0]:
		for i in n:
			var f := (float(i) + 0.5) / n - 0.5
			lm.box("Shadow", Vector3(f * (box.x - 1.6), y, s * box.z * 0.5), Vector3(box.x / n * 0.6, box.y, 0.14))
			lm.box("Shadow", Vector3(s * box.x * 0.5, y, f * (box.z - 1.6)), Vector3(0.14, box.y, box.z / n * 0.6))

# --- Himeji Castle ---

const HIMEJI_M := 46.4

static func himeji(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F897D", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EEEAE0", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#4C5054", 1.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	_keep(lm, Vector2.ZERO, Vector2(22.0, 18.0), 14.85, 5, 1.0)
	_keep(lm, Vector2(-30.0, 14.0), Vector2(11.0, 9.0), 9.0, 2, 0.6)
	_keep(lm, Vector2(28.0, 17.0), Vector2(10.0, 8.0), 8.0, 2, 0.55)
	# Covered corridors tying the small keeps to the main keep.
	for c in [Vector2(-18.0, 10.0), Vector2(16.0, 12.0)]:
		lm.box("Plaster", Vector3(c.x, 4.5, c.y), Vector3(26.0, 3.0, 4.0))
		lm.box("Tile", Vector3(c.x, 6.4, c.y), Vector3(27.5, 0.8, 5.5))
	lm.commit(model)

## A keep centred at `c`: a battered stone base `stone_h` high, then
## `tiers` plastered storeys (each narrower, each under a hip roof with a
## gable) and a big gabled top roof with golden fish ornaments. `sc`
## scales the vertical dimensions (1.0 = the 46.4 m main keep).
static func _keep(lm: LandmarkMesh, c: Vector2, plan: Vector2, stone_h: float, tiers: int,
		sc: float) -> void:
	# Stone base: concave batter in six slices from below ground.
	var w0 := plan.x + 5.0
	var d0 := plan.y + 5.0
	var prev_y := -2.0
	var prev_w := w0 + 11.0
	var prev_d := d0 + 9.0
	for i in range(1, 7):
		var t := float(i) / 6.0
		var sy := lerpf(-2.0, stone_h, t)
		var k := pow(1.0 - t, 2.2)
		var sw := lerpf(w0, w0 + 11.0, k)
		var sd := lerpf(d0, d0 + 9.0, k)
		LandmarkAeParts.batter(lm, "Stone", c.x, c.y, prev_w, prev_d, sw, sd, prev_y, sy)
		prev_y = sy
		prev_w = sw
		prev_d = sd
	var y := stone_h
	for i in tiers:
		var w := plan.x - plan.x * 0.127 * i
		var d := plan.y - plan.y * 0.133 * i
		var top := i == tiers - 1
		var wall_h := (3.8 if top else 3.6) * sc
		lm.box("Plaster", Vector3(c.x, y + wall_h * 0.5, c.y), Vector3(w, wall_h, d))
		for s in [-1.0, 1.0]:
			for q in 2:
				lm.box("Shadow", Vector3(c.x + (q - 0.5) * w * 0.4, y + wall_h * 0.55, c.y + s * d * 0.5),
					Vector3(1.0 * sc + 0.3, 1.2 * sc + 0.3, 0.14))
		var roof_y := y + wall_h
		if top:
			var rise := 4.35 * sc
			lm.gable("Tile", Vector3(c.x, roof_y, c.y), d + 2.0, w + 4.0, rise, Basis(Vector3.UP, PI * 0.5), 1.0, "Plaster")
			for s in [-1.0, 1.0]:
				lm.box("Gold", Vector3(c.x + s * (w * 0.5 + 1.3), roof_y + rise + 0.5 * sc, c.y), Vector3(0.9, 1.0 * sc, 0.9))
		else:
			var rise := 2.0 * sc
			LandmarkAeParts.hip_roof(lm, "Tile", Vector3(c.x, roof_y, c.y), Vector2(w + 5.0, d + 4.4),
				Vector2(w - 2.0, d - 1.8), rise, 0.5 * sc)
			# Karahafu gable across the keep, alternating its direction.
			var gb := Basis() if i % 2 == 0 else Basis(Vector3.UP, PI * 0.5)
			var gw := 6.0 * sc + 1.0
			var gl := (d if i % 2 == 0 else w) + 4.4
			lm.gable("Tile", Vector3(c.x, roof_y, c.y), gw, gl, 2.0 * sc, gb, 0.8, "Plaster")
		y += (wall_h + 2.0 * sc) if not top else 0.0

# --- Itsukushima torii ---

const TORII_M := 16.6

static func torii(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Paint", LandmarkMaterials.paint("#C8381F", 0.55, 0.0))
	lm.use("Bark", LandmarkMaterials.pbr("wood", "#4A4036", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#6F6A60", 3.0))
	for s in [-1.0, 1.0]:
		var x: float = s * 5.4
		lm.frustum("Paint", Vector3(x, -1.0, 0), 0.95, 0.72, 15.5, 14)
		lm.box("Stone", Vector3(x, -0.3, 0), Vector3(2.4, 2.0, 2.4))
		# Two small pillars either side, tied back by a cross beam.
		for z in [-2.6, 2.6]:
			lm.frustum("Paint", Vector3(x, -1.0, z), 0.55, 0.45, 8.5, 10)
			lm.box("Bark", Vector3(x, 7.65, z), Vector3(1.4, 0.3, 1.4))
		lm.box("Paint", Vector3(x, 6.6, 0), Vector3(0.8, 0.8, 5.6))
	# Tie beam, tablet, shimaki and the upswept kasagi (bark-roofed lintel).
	lm.box("Paint", Vector3(0, 10.8, 0), Vector3(13.4, 0.9, 0.9))
	lm.box("Paint", Vector3(0, 12.2, 0), Vector3(1.0, 3.0, 0.5))
	lm.box("Bark", Vector3(0, 12.2, 0), Vector3(0.6, 2.2, 0.8))
	lm.box("Paint", Vector3(0, 13.65, 0), Vector3(23.0, 0.8, 1.2))
	var n := 24
	var half := 12.1
	for i in n:
		var x := -half + 2.0 * half * (float(i) + 0.5) / n
		var yc := 14.5 + 1.2 * pow(absf(x) / half, 3.0)
		var w := 2.0 * half / n
		lm.box("Paint", Vector3(x, yc, 0), Vector3(w, 0.9, 1.5))
		lm.box("Bark", Vector3(x, yc + 0.675, 0), Vector3(w, 0.45, 2.0))
	lm.commit(model)
