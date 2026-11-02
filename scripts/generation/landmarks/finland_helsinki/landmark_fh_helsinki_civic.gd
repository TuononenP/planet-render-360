class_name LandmarkFhHelsinkiCivic
extends RefCounted

## Four public buildings of central Helsinki in true metres: the National
## Museum (National Romantic granite castle), the Parliament House (red
## granite, 14 columns), the Presidential Palace (yellow neoclassical U)
## and the Ateneum (neo-Renaissance). Footprints follow OpenStreetMap.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

# --- National Museum of Finland -------------------------------------

## Gesellius-Lindgren-Saarinen (1910), origin at the OSM footprint centre,
## front +Z (the registry yaw turns it onto Mannerheimintie): granite
## blocks round the west court under steep copper hips, the church-like
## rear apse and the 58 m tower at the front corner with its belfry and
## copper spire.
static func natmuseum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E918D", 4.0))
	lm.use("Soap", LandmarkMaterials.pbr("limestone", "#A9AFA6", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6B9A85", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	# Blocks [x0, x1, z0, z1, eave height, roof rise].
	var blocks := [[2.0, 43.0, -20.0, 15.5, 15.0, 9.0], [-15.0, 2.0, -37.7, 20.0, 15.0, 10.0],
		[-34.2, -15.0, -29.0, 3.4, 13.0, 8.0], [-13.6, 0.2, -46.9, -37.7, 11.0, 5.0]]
	for b in blocks:
		var w: float = float(b[1]) - float(b[0])
		var d: float = float(b[3]) - float(b[2])
		var cx: float = (float(b[0]) + float(b[1])) * 0.5
		var cz: float = (float(b[2]) + float(b[3])) * 0.5
		FhU.blk(lm, "Granite", cx, 0.0, cz, w, float(b[4]), d)
		FhU.blk(lm, "Soap", cx, float(b[4]) - 0.5, cz, w + 0.6, 0.7, d + 0.6)
		FhU.hip(lm, "Copper", Vector3(cx, float(b[4]) + 0.2, cz), w + 1.0, d + 1.0, float(b[5]), 0.12)
		FhU.window_grid(lm, "Glass", Vector3(float(b[0]) + 2.0, 0, float(b[3])),
				Vector3(float(b[1]) - 2.0, 0, float(b[3])),
			Vector3(0, 0, 1), 3.0, 2, 5.5, maxi(int(w / 5.0), 2), 1.4, 2.6)
	# Gabled front ends of the main block and the west wing.
	FhU.ridge_z(lm, "Copper", "Granite", Vector3(23.0, 15.0, 15.5), 12.0, 3.0, 5.0, 0.3)
	FhU.ridge_z(lm, "Copper", "Granite", Vector3(-24.0, 13.0, 3.4), 10.0, 3.0, 4.5, 0.3)
	# Entrance portal and steps at the foot of the tower.
	FhU.blk(lm, "Soap", -6.0, 0.0, 20.6, 7.0, 7.5, 1.4)
	FhU.opening(lm, "Glass", Vector3(-6.0, 0.0, 21.35), Vector3(0, 0, 1), 3.4, 5.5)
	FhU.steps(lm, "Soap", Vector3(-6.0, 0.0, 21.3), Vector3(0, 0, 1), 8.0, 0.6, 0.18, 4)
	# The tower: 7 x 9 m granite shaft, open belfry and copper spire (58 m).
	var tx := -13.2
	var tz := 9.3
	FhU.blk(lm, "Granite", tx, 0.0, tz, 7.0, 36.0, 9.0)
	FhU.blk(lm, "Soap", tx, 36.0, tz, 7.8, 0.8, 9.8)
	FhU.blk(lm, "Granite", tx, 36.8, tz, 6.2, 6.0, 8.0)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out := r * Vector3(0, 0, 1)
		var half := 4.05 if f % 2 == 0 else 3.15
		FhU.opening(lm, "Glass", Vector3(tx, 38.0, tz) + out * half + Vector3(0, 0, 0), out, 2.2, 4.4)
	FhU.opening(lm, "Glass", Vector3(tx, 20.0, tz + 4.55), Vector3(0, 0, 1), 1.2, 6.0, false)
	FhU.opening(lm, "Glass", Vector3(tx, 28.0, tz + 4.55), Vector3(0, 0, 1), 1.2, 4.0, false)
	FhU.hip(lm, "Copper", Vector3(tx, 42.8, tz), 6.8, 8.6, 14.6, 0.0)
	lm.box("Copper", Vector3(tx, 57.4, tz), Vector3(0.25, 1.2, 0.25))
	lm.commit(model)

# --- Parliament House ------------------------------------------------

## Sirén's Eduskuntatalo (1931), origin at the OSM footprint centre, front
## +Z (turned onto Mannerheimintie by the registry yaw): the 77.6 x 58.7 m
## red-granite block, 25 m tall, with the broad flight of steps and the
## colonnade of 14 Corinthian columns reaching the fourth storey.
static func parliament(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A9786C", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#C7A89B", 3.0))
	lm.use("Step", LandmarkMaterials.pbr("stone", "#9A8F88", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5A6068", 3.0))
	var cx := 3.85
	# Main block, cornice and parapet.
	FhU.blk(lm, "Granite", cx, 0.0, -2.45, 77.6, 24.2, 53.9)
	FhU.blk(lm, "Trim", cx, 24.2, -2.45, 78.6, 0.8, 55.0)
	FhU.blk(lm, "Roof", cx, 24.0, -2.45, 74.0, 0.3, 50.0)
	FhU.blk(lm, "Granite", cx, 16.5, 27.0, 77.6, 1.4, 4.6)
	# Steps and the 14 Corinthian columns with their capitals.
	FhU.steps(lm, "Step", Vector3(cx, 0.0, 29.3), Vector3(0, 0, 1), 66.0, 0.6, 0.2, 9)
	var a := Vector3(-27.0, 1.8, 27.2)
	var b := Vector3(34.5, 1.8, 27.2)
	FhU.columns(lm, "Granite", a, b, 14, 15.0, 0.8, 14)
	for i in 14:
		var p := a.lerp(b, float(i) / 13.0)
		lm.box("Trim", p + Vector3(0, 16.2, 0), Vector3(2.1, 1.0, 2.1))
		lm.box("Trim", p + Vector3(0, 0.1, 0), Vector3(2.0, 0.4, 2.0))
	FhU.blk(lm, "Trim", 3.75, 17.4, 27.0, 67.0, 1.5, 4.8)
	# Tall windows between the columns and rows on the wings and sides.
	FhU.openings(lm, "Glass", Vector3(-24.6, 1.8, 24.7), Vector3(32.1, 1.8, 24.7), Vector3(0, 0, 1), 1.5, 13,
			2.2, 11.0, false)
	FhU.window_grid(lm, "Glass", Vector3(-33.5, 0, 24.7), Vector3(-28.5, 0, 24.7), Vector3(0, 0, 1), 3.0, 4,
			5.2, 2, 1.6, 2.6)
	FhU.window_grid(lm, "Glass", Vector3(36.0, 0, 24.7), Vector3(41.0, 0, 24.7), Vector3(0, 0, 1), 3.0, 4, 5.2,
			2, 1.6, 2.6)
	FhU.window_grid(lm, "Glass", Vector3(-35.0, 0, -26.0), Vector3(-35.0, 0, 22.0), Vector3(-1, 0, 0), 3.0, 4,
			5.2, 9, 1.6, 2.6)
	FhU.window_grid(lm, "Glass", Vector3(42.7, 0, -26.0), Vector3(42.7, 0, 22.0), Vector3(1, 0, 0), 3.0, 4, 5.2,
			9, 1.6, 2.6)
	FhU.window_grid(lm, "Glass", Vector3(-33.0, 0, -29.4), Vector3(41.0, 0, -29.4), Vector3(0, 0, -1), 3.0, 4,
			5.2, 14, 1.6, 2.6)
	lm.commit(model)

# --- Presidential Palace -------------------------------------------

## The palace on the Market Square (Granstedt 1816, Engel 1843), origin
## at the OSM footprint centre, the forecourt side +Z (south on the map,
## registry yaw -3): a three-storey yellow-ochre range with a pedimented
## portico, and two wings enclosing the forecourt under low metal hips.
static func presidential(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#DDB96E", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F0EAD8", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6C7378", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8C8A84", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	var h := 16.0
	# Range [x0, x1, z0, z1]: main range and the two forecourt wings.
	var parts := [[-35.8, 12.9, -37.8, 12.9], [-35.8, -27.8, 12.9, 34.2], [4.4, 12.9, 12.9, 34.3]]
	for p in parts:
		var w: float = float(p[1]) - float(p[0])
		var d: float = float(p[3]) - float(p[2])
		var cx: float = (float(p[0]) + float(p[1])) * 0.5
		var cz: float = (float(p[2]) + float(p[3])) * 0.5
		FhU.blk(lm, "Plinth", cx, 0.0, cz, w + 0.4, 1.6, d + 0.4)
		FhU.blk(lm, "Wall", cx, 1.6, cz, w, h - 1.6, d)
		FhU.blk(lm, "Trim", cx, h - 0.4, cz, w + 0.9, 0.8, d + 0.9)
		FhU.hip(lm, "Roof", Vector3(cx, h + 0.4, cz), w + 0.6, d + 0.6, 3.6, 0.25)
	# Window rows on the court, wing and street faces.
	FhU.window_grid(lm, "Glass", Vector3(-26.5, 0, 12.95), Vector3(-20.0, 0, 12.95), Vector3(0, 0, 1), 3.0, 3,
			4.6, 2, 1.5, 2.6)
	FhU.window_grid(lm, "Glass", Vector3(-3.0, 0, 12.95), Vector3(3.4, 0, 12.95), Vector3(0, 0, 1), 3.0, 3, 4.6,
			2, 1.5, 2.6)
	FhU.window_grid(lm, "Glass", Vector3(-27.75, 0, 16.0), Vector3(-27.75, 0, 32.0), Vector3(1, 0, 0), 3.0, 3,
			4.6, 4, 1.5, 2.6)
	FhU.window_grid(lm, "Glass", Vector3(4.45, 0, 16.0), Vector3(4.45, 0, 32.0), Vector3(-1, 0, 0), 3.0, 3, 4.6,
			4, 1.5, 2.6)
	FhU.window_grid(lm, "Glass", Vector3(-35.85, 0, -34.0), Vector3(-35.85, 0, 31.0), Vector3(-1, 0, 0), 3.0, 3,
			4.6, 12, 1.5, 2.6)
	FhU.window_grid(lm, "Glass", Vector3(12.95, 0, -34.0), Vector3(12.95, 0, 10.0), Vector3(1, 0, 0), 3.0, 3,
			4.6, 9, 1.5, 2.6)
	FhU.window_grid(lm, "Glass", Vector3(-34.0, 0, -37.85), Vector3(11.0, 0, -37.85), Vector3(0, 0, -1), 3.0, 3,
			4.6, 10, 1.5, 2.6)
	# Central portico: four pilasters under a pediment.
	var pz := 14.0
	FhU.blk(lm, "Trim", -11.5, 1.6, pz + 0.3, 14.7, h - 1.6, 0.6)
	for i in 4:
		FhU.blk(lm, "Trim", -17.5 + 4.0 * float(i), 1.6, pz + 0.9, 1.0, h - 3.0, 0.6)
	FhU.ridge_z(lm, "Roof", "Trim", Vector3(-11.5, h + 0.4, pz - 1.5), 15.6, 3.0, 2.6, 0.3)
	FhU.opening(lm, "Glass", Vector3(-11.5, 1.6, pz + 1.25), Vector3(0, 0, 1), 3.2, 5.0)
	lm.commit(model)

# --- Ateneum -----------------------------------------------------------

## Höijer's Ateneum (1887), origin at the OSM footprint centre, front +Z
## (the registry yaw turns it north onto the station square): granite
## plinth, three storeys of cream render, the pedimented central bay with
## its great arched portal, the low copper roof and the glazed roof of the
## main hall.
static func ateneum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D9CFAE", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EDE6D2", 2.5))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6B9A85", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	var w := 77.8
	var d := 54.0
	var zc := 0.5
	FhU.blk(lm, "Plinth", 0.0, 0.0, zc, w + 0.6, 4.6, d + 0.6)
	FhU.blk(lm, "Wall", 0.0, 4.6, zc, w, 13.0, d)
	FhU.blk(lm, "Trim", 0.0, 17.2, zc, w + 1.2, 1.0, d + 1.2)
	# Low copper hip over the block with the glazed roof of the main hall on its flat top.
	FhU.hip(lm, "Copper", Vector3(0, 18.2, zc), w + 0.4, d + 0.4, 2.2, 0.6)
	FhU.ridge_x(lm, "Glass", "Glass", Vector3(0, 20.4, zc), 44.0, 28.0, 2.6, 0.0)
	# Central bay: projecting block, great portal, window arcade and pediment.
	FhU.blk(lm, "Wall", 0.0, 4.6, 28.1, 26.0, 13.2, 2.4)
	FhU.blk(lm, "Trim", 0.0, 17.4, 28.1, 27.0, 0.8, 3.0)
	FhU.ridge_z(lm, "Trim", "Wall", Vector3(0, 18.2, 28.1), 26.0, 2.6, 3.6, 0.4)
	FhU.opening(lm, "Glass", Vector3(0, 4.6, 29.35), Vector3(0, 0, 1), 7.0, 11.0)
	FhU.openings(lm, "Glass", Vector3(-9.0, 4.6, 29.35), Vector3(9.0, 4.6, 29.35), Vector3(0, 0, 1), 3.0, 2, 3.0, 5.0)
	for i in 5:
		FhU.blk(lm, "Trim", -10.0 + 5.0 * float(i), 4.6, 29.35, 1.0, 12.4, 0.5)
	FhU.steps(lm, "Plinth", Vector3(0, 0, 29.3), Vector3(0, 0, 1), 12.0, 0.6, 0.35, 5)
	# Window rows on the front, sides and back.
	for sx in [-1.0, 1.0]:
		FhU.window_grid(lm, "Glass", Vector3(sx * 15.5, 0, 26.6), Vector3(sx * 38.0, 0, 26.6), Vector3(0, 0, 1),
				6.0, 2, 6.0, 5, 1.9, 3.4)
		FhU.window_grid(lm, "Glass", Vector3(sx * 15.5, 0, 26.6), Vector3(sx * 38.0, 0, 26.6), Vector3(0, 0, 1),
				1.6, 1, 6.0, 5, 1.5, 2.0)
		FhU.window_grid(lm, "Glass", Vector3(sx * 38.95, 0, -24.0), Vector3(sx * 38.95, 0, 25.0),
				Vector3(sx, 0, 0), 6.0, 2, 6.0, 8, 1.9, 3.4)
	FhU.window_grid(lm, "Glass", Vector3(-36.0, 0, -26.55), Vector3(36.0, 0, -26.55), Vector3(0, 0, -1), 6.0, 2,
			6.0, 12, 1.9, 3.4)
	lm.commit(model)
