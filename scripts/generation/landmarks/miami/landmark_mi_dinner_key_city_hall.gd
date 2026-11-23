class_name LandmarkMiDinnerKeyCityHall
extends RefCounted

## Miami City Hall — 1934 Pan American Airways Seaplane Terminal, Dinner Key (MI-10 Centre E).
## Delano & Aldrich. Footprint 46 x 32 m (X x Z), +X faces Biscayne Bay entrance. Height 14.5 m.
## White Streamline Moderne body, Pan-Am cobalt trim, stepped symmetrical wings, fluted piers,
## winged-globe relief over the bronze/glass entrance, porthole & frieze bands, flagpole.

const HEIGHT_M := 14.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F4F1E8", 3.5))
	lm.use("Blue", LandmarkMaterials.paint("#1F4E9C", 0.55, 0.1))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E4DDCB", 3.0))
	lm.use("Window", LandmarkMaterials.glass("#25313B"))
	lm.use("Bronze", LandmarkMaterials.paint("#5A4630", 0.4, 0.65))
	lm.use("Gold", LandmarkMaterials.gold())
	_build_body(lm)
	_build_entrance(lm)
	_build_roof(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.92, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(30.0, 1.2, -10.0), Vector3(23.0, 5.0, -2.0), 32.0, 1.1, 40.0, warm],
		[Vector3(30.0, 1.2, 10.0), Vector3(23.0, 5.0, 2.0), 32.0, 1.1, 40.0, warm],
	])

static func _build_body(lm: LandmarkMesh) -> void:
	# Stepped plan: central block, intermediate wings, low end pavilions
	lm.box("Stone", Vector3(0.0, 0.2, 0.0), Vector3(46.4, 0.9, 32.4))
	lm.box("White", Vector3(0.0, 4.5, 0.0), Vector3(22.0, 8.0, 28.0))
	for sx: float in [-1.0, 1.0]:
		lm.box("White", Vector3(sx * 15.0, 3.6, 0.0), Vector3(10.0, 6.2, 30.0))
		lm.box("White", Vector3(sx * 21.0, 2.8, 0.0), Vector3(6.0, 4.6, 32.0))
		lm.box("Blue", Vector3(sx * 15.0, 6.8, 0.0), Vector3(10.4, 0.5, 30.4), Basis(), 0.0)
		lm.box("Blue", Vector3(sx * 21.0, 5.3, 0.0), Vector3(6.4, 0.4, 32.4), Basis(), 0.0)
		# Porthole bands on the wing fronts (north & south)
		for sz: float in [-1.0, 1.0]:
			for i: int in 5:
				var px := sx * (12.0 + float(i) * 2.4)
				lm.frustum("Window", Vector3(px, 3.4, sz * 15.05), 0.45, 0.45, 0.1, 10, 0.0, 1.0, 1.0)
				lm.frustum("Blue", Vector3(px, 3.4, sz * 15.0), 0.62, 0.62, 0.06, 10)
	# Blue frieze band at central parapet and base stripe
	lm.box("Blue", Vector3(0.0, 8.7, 0.0), Vector3(22.4, 0.6, 28.4), Basis(), 0.0)
	lm.box("Blue", Vector3(0.0, 1.0, 0.0), Vector3(46.2, 0.5, 32.2), Basis(), 0.0)
	# Ground-floor window ribbon on both long wings
	for sz: float in [-1.0, 1.0]:
		lm.box("Window", Vector3(0.0, 3.0, sz * 14.02), Vector3(18.0, 1.4, 0.15), Basis(), 0.0)
		lm.box("Window", Vector3(0.0, 6.4, sz * 14.02), Vector3(18.0, 1.4, 0.15), Basis(), 0.0)

static func _build_entrance(lm: LandmarkMesh) -> void:
	# East entrance: fluted piers framing bronze/glass doors
	var fx := 11.0
	for i: int in 7:
		var z := -7.5 + float(i) * 2.5
		lm.box("Stone", Vector3(fx + 0.6, 4.2, z), Vector3(1.0, 7.6, 0.8), Basis(), 0.0)
		for f: float in [-0.2, 0.0, 0.2]:
			lm.box("White", Vector3(fx + 1.15, 4.2, z + f), Vector3(0.12, 7.4, 0.06), Basis(), 0.0)
	for i: int in 6:
		var z2 := -6.25 + float(i) * 2.5
		lm.box("Window", Vector3(fx + 0.3, 2.6, z2), Vector3(0.3, 3.8, 1.5), Basis(), 0.0)
		lm.box("Bronze", Vector3(fx + 0.4, 0.8, z2), Vector3(0.3, 0.2, 1.5), Basis(), 0.0)
	lm.box("Stone", Vector3(fx + 1.6, 8.4, 0.0), Vector3(3.2, 0.6, 19.0), Basis(), 0.0)
	lm.box("Blue", Vector3(fx + 1.6, 8.85, 0.0), Vector3(3.0, 0.3, 18.6), Basis(), 0.0)
	# Winged-globe Art Deco relief over the doors
	lm.lathe("Blue", Vector3(fx + 1.3, 6.2, 0.0), PackedVector2Array([
		Vector2(0.0, -1.0), Vector2(0.7, -0.7), Vector2(1.0, 0.0), Vector2(0.7, 0.7), Vector2(0.0, 1.0)]),
		16, 0.45, 1.0, 0.0, true, true)
	for sz: float in [-1.0, 1.0]:
		for k: int in 4:
			var f := float(k)
			lm.beam("Gold", Vector3(fx + 1.4, 6.5 - f * 0.2, sz * 1.2), Vector3(fx + 1.4, 6.9 - f * 0.35, sz * (4.0 - f * 0.3)), 0.22, 0.1)

static func _build_roof(lm: LandmarkMesh) -> void:
	# Penthouse with stepped parapet and flagpole topping 14.5 m
	lm.box("White", Vector3(0.0, 10.4, 0.0), Vector3(12.0, 2.8, 14.0))
	lm.box("Blue", Vector3(0.0, 12.0, 0.0), Vector3(12.4, 0.5, 14.4), Basis(), 0.0)
	lm.box("White", Vector3(0.0, 12.6, 0.0), Vector3(5.0, 0.8, 5.0))
	lm.box("Window", Vector3(5.52, 10.6, 0.0), Vector3(0.1, 1.4, 8.0), Basis(), 0.0)
	lm.frustum("Bronze", Vector3(0.0, 13.0, 0.0), 0.25, 0.2, 0.3, 8)
	lm.beam("Bronze", Vector3(0.0, 13.2, 0.0), Vector3(0.0, HEIGHT_M, 0.0), 0.14, 0.14, Vector3.RIGHT, true)
