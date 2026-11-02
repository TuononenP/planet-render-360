class_name LandmarkLpPersia
extends RefCounted

## Two ancient Near Eastern gateways in true metres: Persepolis (the Gate
## of All Nations and the Apadana on the terrace) and the reconstructed
## Ishtar Gate of Babylon.

# --- Persepolis ---

## Height of the terrace top above the Marvdasht plain.
const PLATFORM_H := 12.5

## Compass frame, y = 0 on the plain. A 215 x 170 m piece of the dark-grey
## limestone terrace with the Great Stairway climbing its west face; on it
## the Gate of All Nations (25 m square hall, three portals, a pair of
## lamassu at the west and east doors, column bases) and the Apadana on its
## own 2.6 m terrace with the two double stairs (north, east) and the 14
## columns (19.2 m) that stand today: both rows of the north portico and two
## of the hall. Top of the columns 34.3 m.
static func persepolis(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#7D786E", 4.0))
	lm.use("Terrace", LandmarkMaterials.pbr("rock", "#6E675B", 8.0))
	lm.use("Door", LandmarkMaterials.pbr("concrete", "#1B1713", 3.0, 0.92))
	var ph := PLATFORM_H
	lm.box("Terrace", Vector3(7.5, ph * 0.5, 0), Vector3(215, ph, 170))
	LandmarkLpParts.steps(lm, "Marble", Vector3(-130.0, 0, -15.0), Vector3(1, 0, 0), 14.0, 30.0, ph, 20)
	_gate_of_all_nations(lm, Vector3(-62.5, ph, -15.0))
	var a := Vector3(32.0, ph, 11.0)
	var ay := ph + 2.6
	lm.box("Marble", Vector3(a.x, ph + 1.3, a.z), Vector3(110, 2.6, 110))
	for s in [-1.0, 1.0]:
		LandmarkLpParts.steps(lm, "Marble", Vector3(a.x + s * 22.0, ph, a.z - 68.0), Vector3(0, 0, 1),
			6.5, 13.0, 2.6, 13)
		LandmarkLpParts.steps(lm, "Marble", Vector3(a.x + 68.0, ph, a.z + s * 22.0), Vector3(-1, 0, 0),
			6.5, 13.0, 2.6, 13)
	for row in [-46.0, -35.0]:
		for i in 6:
			_column(lm, "Marble", Vector3(a.x - 27.5 + 11.0 * i, ay, a.z + row), 19.2)
	for x in [-27.5, 27.5]:
		_column(lm, "Marble", Vector3(a.x + x, ay, a.z - 24.0), 19.2)
	lm.commit(model)

## The 25 m square Gate of Xerxes: thick walls pierced by the west, south
## and east portals (5 m wide, 8 m tall under a lintel), column bases
## inside and the four colossal bulls at the west and east doors.
static func _gate_of_all_nations(lm: LandmarkMesh, g: Vector3) -> void:
	for s in [-1.0, 1.0]:
		for t in [-1.0, 1.0]:
			lm.box("Marble", g + Vector3(s * 10.0, 4.75, t * 7.5), Vector3(5.0, 9.5, 10.0))
			lm.box("Marble", g + Vector3(t * 7.5, 4.75, s * 10.0), Vector3(10.0, 9.5, 5.0))
		lm.box("Marble", g + Vector3(s * 10.0, 8.75, 0), Vector3(5.0, 1.5, 6.4))
	lm.box("Marble", g + Vector3(0, 4.75, -10.0), Vector3(15.0, 9.5, 5.0))
	lm.box("Marble", g + Vector3(0, 8.75, 10.0), Vector3(6.4, 1.5, 5.0))
	lm.box("Door", g + Vector3(0, 0.05, 0), Vector3(20.0, 0.1, 20.0))
	for x in [-5.5, 5.5]:
		for z in [-5.5, 5.5]:
			lm.frustum("Marble", g + Vector3(x, 0, z), 1.5, 1.2, 1.6, 10)
	for s in [-1.0, 1.0]:
		_lamassu(lm, "Marble", g + Vector3(-10.6, 0, 3.7 * s), -1.0)
		_lamassu(lm, "Marble", g + Vector3(10.6, 0, 3.7 * s), 1.0)

## Colossal winged human-headed bull, 5.9 m tall, facing `dir` along X.
static func _lamassu(lm: LandmarkMesh, key: String, base: Vector3, dir: float) -> void:
	lm.box(key, base + Vector3(-dir * 0.3, 1.55, 0), Vector3(4.4, 3.1, 1.7))
	lm.box(key, base + Vector3(dir * 1.9, 2.0, 0), Vector3(1.6, 4.0, 1.5))
	lm.box(key, base + Vector3(-dir * 0.4, 3.7, 0), Vector3(3.2, 1.7, 0.4))
	lm.lathe(key, base + Vector3(dir * 2.1, 4.0, 0), LandmarkLpParts.dome_profile(0.75, 1.0, 4), 10)
	lm.frustum(key, base + Vector3(dir * 2.1, 4.8, 0), 0.8, 0.55, 1.1, 10)
	lm.box(key, base + Vector3(dir * 2.55, 3.7, 0), Vector3(0.45, 0.9, 0.7))

## Fluted Achaemenid column of height h: bell (inverted lotus) base, faceted
## shaft, palm-leaf neck and a double-scroll capital block.
static func _column(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	var cap_h := 4.4
	var shaft_h := h - 2.3 - cap_h
	lm.lathe(key, base, PackedVector2Array([Vector2(1.6, 0.0), Vector2(1.6, 0.5), Vector2(1.3, 1.1),
		Vector2(1.05, 1.9), Vector2(0.95, 2.3)]), 14)
	lm.lathe(key, base + Vector3(0, 2.3, 0), PackedVector2Array([Vector2(0.95, 0.0),
		Vector2(0.78, shaft_h)]), 20, 1.0, 1.0, 0.0, false, false)
	var cb := base + Vector3(0, h - cap_h, 0)
	lm.lathe(key, cb, PackedVector2Array([Vector2(0.8, 0.0), Vector2(1.0, 0.5), Vector2(1.4, 1.4),
		Vector2(1.55, 2.0)]), 14)
	lm.box(key, cb + Vector3(0, 2.6, 0), Vector3(3.6, 1.2, 1.6))
	for s in [-1.0, 1.0]:
		lm.frustum(key, cb + Vector3(s * 1.8, 2.6, 0), 0.75, 0.75, 1.6, 10, 0.0, 1.0, 1.0)
	lm.box(key, cb + Vector3(0, 3.8, 0), Vector3(2.8, 1.2, 1.5))

# --- Ishtar Gate ---

## Iraqi reconstruction beside the Babylon ruins (about 14 m): a smaller
## outer gate and the main gate behind it, blue glazed brick with rows of
## ochre bulls (Adad) and dragons (Marduk) between white bands, the toothed
## crenellated top and the lion-reliefed walls of the Processional Way.
## Main gate at z = -38 (north), approach from the south (+Z).
static func ishtar_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Blue", LandmarkMaterials.pbr("render", "#1E4F9C", 2.0, 0.38))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#C9A24A", 2.0, 0.5))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#E8DFC4", 2.0, 0.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B98A5A", 3.0))
	var gz := -38.0
	lm.box("Brick", Vector3(0, -0.5, 0.0), Vector3(44, 1.0, 94))
	# Main gate: 30 m wide, 14 m deep, round-arched passage, flanking towers.
	var arch := [[0.0, 3.4, 5.6, 3.4]]
	LandmarkLpParts.slab(lm, "Blue", LandmarkLpParts.arcade_outline(30.0, 12.5, arch, 10),
		Vector3(0, 0, gz + 7.0), 0.0, 14.0)
	for s in [-1.0, 1.0]:
		lm.box("Blue", Vector3(s * 11.0, 6.25, gz + 8.0), Vector3(8.0, 12.5, 2.0))
		lm.box("Blue", Vector3(s * 11.0, 6.25, gz - 8.0), Vector3(8.0, 12.5, 2.0))
		lm.box("Cream", Vector3(s * 11.0, 12.6, gz + 8.0), Vector3(8.4, 0.25, 2.4))
	var top := Vector3(-15.0, 12.5, gz + 7.0)
	LandmarkLpParts.merlons(lm, "Blue", top, Vector3(15.0, 12.5, gz + 7.0), 1.4, 1.5, 1.2, 2.6)
	LandmarkLpParts.merlons(lm, "Blue", Vector3(-15.0, 12.5, gz - 7.0), Vector3(15.0, 12.5, gz - 7.0),
		1.4, 1.5, 1.2, 2.6)
	for s in [-1.0, 1.0]:
		LandmarkLpParts.merlons(lm, "Blue", Vector3(s * 15.0, 12.5, gz - 7.0),
			Vector3(s * 15.0, 12.5, gz + 7.0), 1.4, 1.5, 1.2, 2.6)
	_animal_rows(lm, gz + 7.06, 30.0, 12.5, 3.9, 6.0, 7.0, 2.0)
	# Outer gate: 22 m wide, 9 m deep, 9.5 m tall.
	var oz := gz + 26.0
	LandmarkLpParts.slab(lm, "Blue", LandmarkLpParts.arcade_outline(22.0, 8.5, [[0.0, 2.8, 4.0, 2.8]], 8),
		Vector3(0, 0, oz + 4.5), 0.0, 9.0)
	LandmarkLpParts.merlons(lm, "Blue", Vector3(-11.0, 8.5, oz + 4.5), Vector3(11.0, 8.5, oz + 4.5),
		1.2, 1.2, 1.0, 2.4)
	LandmarkLpParts.merlons(lm, "Blue", Vector3(-11.0, 8.5, oz - 4.5), Vector3(11.0, 8.5, oz - 4.5),
		1.2, 1.2, 1.0, 2.4)
	_animal_rows(lm, oz + 4.56, 22.0, 8.5, 2.9, 4.0, 99.0, 0.0)
	# Processional Way walls, 6.5 m with striding lions.
	for s in [-1.0, 1.0]:
		lm.box("Blue", Vector3(s * 8.5, 3.25, oz + 31.0), Vector3(3.0, 6.5, 52.0))
		for i in 13:
			var p := Vector3(s * 6.95, 3.4, oz + 8.0 + 3.6 * float(i))
			lm.box("Ochre", p, Vector3(0.14, 1.2, 2.5))
			lm.box("Cream", p + Vector3(0, -1.0, 0), Vector3(0.12, 0.2, 3.2))
	lm.commit(model)

## Rows of ochre bulls and dragons alternating along a gate face (z = zf,
## width w, rows up to height h) around a passage of half-width `gap` below
## `gap_top` m, separated by thin cream bands; beyond |x| > tower_x the face
## stands tower_dz proud (the flanking towers).
static func _animal_rows(lm: LandmarkMesh, zf: float, w: float, h: float, gap: float,
		gap_top: float, tower_x: float, tower_dz: float) -> void:
	var rows := int((h - 1.0) / 1.6)
	for r in rows:
		var y := 1.0 + 1.6 * float(r) + 0.7
		lm.box("Cream", Vector3(0, y + 0.8, zf), Vector3(w - 0.6, 0.14, 0.1))
		var n := int((w - 1.0) / 2.5)
		for i in n:
			var x := -w * 0.5 + 0.5 + 2.5 * (float(i) + 0.5) + (w - 1.0 - 2.5 * float(n)) * 0.5
			if absf(x) < gap + 1.0 and y < gap_top + 2.4:
				continue
			var dragon := (i + r) % 2 == 1
			var z := zf + (tower_dz if absf(x) > tower_x else 0.0)
			lm.box("Ochre", Vector3(x, y, z), Vector3(1.8, 1.2 if dragon else 0.9, 0.1))
			lm.box("Ochre", Vector3(x + (0.7 if dragon else -0.5), y + (0.8 if dragon else 0.4), z),
				Vector3(0.4, 0.6 if dragon else 0.35, 0.1))
