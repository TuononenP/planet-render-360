class_name LandmarkMiColonyStarlite
extends RefCounted

## Colony, Boulevard & Starlite Hotels — Ocean Drive 7th–8th St (MI-4A).
## Site: OSM ways 435587753 (736 Colony), 380861902 (740 Boulevard), 380861941
## (750 Starlite), 25.777602, -80.131563, yaw_deg 11.4.
## Local frame: +X = east (Ocean Drive / Lummus Park), +Z = north along Ocean Drive.
## Measured envelope (Commons front views, Miami Design Preservation League):
##   - Footprint 38.5 m (X) x 42.0 m (Z); three attached Deco fronts at x = +10.5,
##     behind them 21 m deep blocks, sidewalk terrace to x = +17.
##   - Colony (z -21..-7, 11.5 m, 3 storeys): crisp white stucco, cobalt-blue trim,
##     continuous eyebrows, striped café awning, stepped central sign pylon
##     (to 14.6 m) with cool-blue neon "COLONY" and roofline neon tubes.
##   - Boulevard (z -7..5, 10.0 m): pastel peach front with aqua trim, flat parapet.
##   - Starlite (z 5..21, 12.0 m): pastel-yellow / aqua ziggurat front with a
##     slender spire finial whose tip is the model top, exactly 16.5 m.

const HEIGHT_M := 16.5
const FRONT_X := 10.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#F6F3EA", 3.0))
	lm.use("Cobalt", LandmarkMaterials.paint("#1F4FA8", 0.55, 0.05))
	lm.use("Peach", LandmarkMaterials.pbr("render", "#F2CDB8", 3.0))
	lm.use("Yellow", LandmarkMaterials.pbr("render", "#F6E7A4", 3.0))
	lm.use("Aqua", LandmarkMaterials.paint("#5CC7C2", 0.55, 0.05))
	lm.use("Glass", LandmarkMaterials.glass("#26363F"))
	lm.use("Neon", LandmarkMaterials.lit("#4FC8FF", 1.4))
	lm.use("Trunk", LandmarkMaterials.pbr("concrete", "#9A9588", 2.0))
	lm.use("Frond", LandmarkMaterials.paint("#2F6B35", 0.8, 0.0))
	lm.use("Walk", LandmarkMaterials.pbr("concrete", "#C9C3B5", 3.0))

	lm.box("Walk", Vector3(4.0, -0.15, 0.0), Vector3(36.0, 0.3, 42.0))
	_hotel(lm, "Stucco", "Cobalt", -21.0, -7.0, 11.5, 3)
	_hotel(lm, "Peach", "Aqua", -7.0, 5.0, 10.0, 3)
	_hotel(lm, "Yellow", "Aqua", 5.0, 21.0, 12.0, 3)
	_colony_sign(lm)
	_awning(lm, -21.0, -7.0)
	_starlite_crown(lm)
	_terrace(lm)
	lm.commit(model)

	var cool := Color(0.62, 0.84, 1.0)
	var warm := Color(1.0, 0.88, 0.62)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(19.0, 1.5, -14.0), Vector3(FRONT_X, 9.0, -14.0), 40.0, 1.2, 34.0, cool],
		[Vector3(19.0, 1.5, 0.0), Vector3(FRONT_X, 7.0, 0.0), 40.0, 1.1, 34.0, warm],
		[Vector3(19.0, 1.5, 13.0), Vector3(FRONT_X, 9.0, 13.0), 40.0, 1.2, 36.0, warm],
	])

static func _hotel(lm: LandmarkMesh, wall: String, trim: String, z0: float, z1: float,
		h: float, floors: int) -> void:
	var zc := (z0 + z1) * 0.5
	lm.box(wall, Vector3(-0.15, (h - 0.3) * 0.5, zc), Vector3(21.0, h + 0.3, z1 - z0 - 0.3))
	lm.box(trim, Vector3(FRONT_X - 0.1, h - 0.3, zc), Vector3(0.5, 0.7, z1 - z0 - 0.3))
	var fh := h / float(floors)
	var bays := maxi(2, int((z1 - z0) / 3.2))
	for f in floors:
		var yc := float(f) * fh + fh * 0.5 + 0.2
		var gh := 1.9 if f == 0 else 1.6
		for i in bays:
			var z := lerpf(z0 + 1.0, z1 - 1.0, (float(i) + 0.5) / float(bays))
			lm.box("Glass", Vector3(FRONT_X + 0.03, yc, z), Vector3(0.1, gh, 1.3))
		if f > 0:
			LandmarkMiKit.deco_eyebrow(lm, trim, Vector2(FRONT_X, z0 + 0.2),
				Vector2(FRONT_X, z1 - 0.2), float(f) * fh + fh * 0.5 + 1.15, 0.42, 0.10, Vector2(1, 0))
	for i in bays + 1:
		var zp := lerpf(z0 + 0.2, z1 - 0.2, float(i) / float(bays))
		lm.box(trim, Vector3(FRONT_X + 0.08, h * 0.5, zp), Vector3(0.18, h, 0.22))

static func _colony_sign(lm: LandmarkMesh) -> void:
	var zc := -14.0
	LandmarkMiKit.ziggurat_parapet(lm, "Stucco", "Cobalt", Vector2(FRONT_X - 0.4, zc),
		Vector2(0, 1), Vector2(1, 0), 11.5, 9.0, 0.45, 3, 0.5)
	# Stepped central sign pylon with vertical blade fin and neon letter bars.
	lm.box("Cobalt", Vector3(FRONT_X + 0.5, 9.2, zc), Vector3(0.5, 10.2, 1.8))
	lm.box("Stucco", Vector3(FRONT_X + 0.5, 14.35, zc), Vector3(0.5, 0.5, 1.2))
	LandmarkMiKit.vertical_fin(lm, "Cobalt", "Neon", Vector2(FRONT_X + 0.75, zc), Vector2(1, 0), 5.0, 14.6, 0.5, 0.3)
	for k in 6:
		lm.box("Neon", Vector3(FRONT_X + 0.8, 13.4 - float(k) * 1.2, zc), Vector3(0.1, 0.55, 1.0))
	var tube := PackedVector3Array([Vector3(FRONT_X + 0.35, 12.1, -20.8), Vector3(FRONT_X + 0.35, 12.1, -7.2)])
	LandmarkMiKit.neon_tube_line(lm, "Neon", tube, 0.10)

static func _awning(lm: LandmarkMesh, z0: float, z1: float) -> void:
	var tilt := Basis(Vector3.BACK, -0.30)
	var n := int((z1 - z0 - 1.0) / 0.8)
	for i in n:
		var z := z0 + 0.5 + (float(i) + 0.5) * (z1 - z0 - 1.0) / float(n)
		lm.box("Cobalt" if i % 2 == 0 else "Stucco", Vector3(FRONT_X + 1.1, 3.35, z),
			Vector3(2.4, 0.08, (z1 - z0 - 1.0) / float(n)), tilt)

static func _starlite_crown(lm: LandmarkMesh) -> void:
	var zc := 13.0
	LandmarkMiKit.ziggurat_parapet(lm, "Yellow", "Aqua", Vector2(FRONT_X - 0.4, zc),
		Vector2(0, 1), Vector2(1, 0), 12.0, 10.0, 0.5, 3, 0.5)
	lm.box("Aqua", Vector3(FRONT_X - 0.4, 13.65, zc), Vector3(1.2, 0.3, 1.2))
	lm.spire("Aqua", Vector3(FRONT_X - 0.4, 13.8, zc), 0.45, HEIGHT_M - 13.8, 0.04, 4)

static func _terrace(lm: LandmarkMesh) -> void:
	for z: float in [-17.0, -11.0, -3.0, 2.0, 9.0, 15.0]:
		var u := Vector3(FRONT_X + 5.5, 0.0, z)
		lm.beam("Trunk", u, u + Vector3(0, 2.3, 0), 0.08, 0.08)
		lm.frustum("Cobalt" if z < -7.0 else "Aqua", u + Vector3(0, 2.1, 0), 1.25, 0.06, 0.55, 8)
	for z: float in [-16.0, 6.0, 18.0]:
		LandmarkMiKit.royal_palm(lm, "Trunk", "Frond", Vector3(FRONT_X + 8.0, 0.0, z), 9.0, z)
