class_name VnPuntaDogana
extends RefCounted

## Punta della Dogana / Dogana da Mar (Giuseppe Benoni, 1677–1682):
## Iconic triangular maritime customs house at the eastern prow of Dorsoduro
## where the Grand Canal meets the Giudecca Canal.
## Local frame: prow points +X (bearing ~100°, yaw 10°); Grand Canal flank -Z,
## Giudecca Canal flank +Z. Top of gilded Fortune weathervane = 28.0 m.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#ECE6D9", 2.8))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F6F2E8", 2.0))
	lm.use("Brick", LandmarkVnKit.brick("#B8674C", 2.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9D6048", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#242C32"))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#544936", 2.0, 0.42, 0.72))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE09A", 2.0))

	# Triangular promontory base with algae waterline skirt & rusticated white Istrian plinth
	var tri_base := PackedVector2Array([
		Vector2(-42.0, -22.0), Vector2(36.0, -7.5), Vector2(44.0, 0.0),
		Vector2(36.0, 7.5), Vector2(-42.0, 22.0),
	])
	lm.poly_prism("Algae", tri_base, -0.3, 0.5)
	lm.poly_prism("Stone", tri_base, 0.5, 2.0)

	# Long wedge-shaped warehouse halls under pitched terracotta roofs
	var tri_wall := PackedVector2Array([
		Vector2(-40.5, -20.5), Vector2(26.0, -8.5), Vector2(26.0, 8.5), Vector2(-40.5, 20.5),
	])
	lm.poly_prism("Brick", tri_wall, 2.0, 10.6)
	lm.poly_prism("Trim", tri_wall, 10.4, 11.1)

	# Parallel gabled customs bays stepping in width toward the prow
	var bays := [
		[-34.0, 13.0, 39.0], [-20.0, 13.0, 33.0], [-6.0, 13.0, 27.0],
		[8.0, 13.0, 21.0], [20.0, 11.0, 16.0],
	]
	for b in bays:
		var bx: float = b[0]
		var bw: float = b[1]
		var bd: float = b[2]
		lm.gable("Roof", Vector3(bx, 11.1, 0.0), bw, bd, 2.9, Basis(Vector3.UP, PI * 0.5), 0.25, "Brick")

	# Rusticated Istrian-stone classical entrance portico & arched colonnades at the prow (+X)
	var prow_poly := PackedVector2Array([
		Vector2(24.0, -9.2), Vector2(35.0, -6.8), Vector2(39.0, 0.0),
		Vector2(35.0, 6.8), Vector2(24.0, 9.2),
	])
	lm.poly_prism("Stone", prow_poly, 2.0, 11.2)
	lm.poly_prism("Trim", prow_poly, 10.8, 11.6)
	# Rusticated Doric arches along both angled prow faces
	for s: float in [-1.0, 1.0]:
		var nrm := Vector3(0.28, 0.0, s * 0.96).normalized()
		for i in 4:
			var px := 26.2 + 2.4 * float(i)
			var pz := s * (8.6 - 0.55 * float(i))
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(px, 5.4, pz), nrm, 1.6, 5.2, true, 0.22)
	# Prow portal & Venetian pediment facing east (+X)
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(38.9, 5.6, 0.0), Vector3(1, 0, 0), 2.8, 6.4, true, 0.28)
	lm.gable("Trim", Vector3(37.2, 11.5, 0.0), 11.0, 2.2, 2.6, Basis(Vector3.UP, PI * 0.5), 0.25, "Stone")
	# Rooftop balustrade around the prow terrace
	LandmarkDetail.balustrade(lm, "Trim", Vector3(24.0, 11.6, -9.0), Vector3(35.0, 11.6, -6.6), 1.1, 2.6)
	LandmarkDetail.balustrade(lm, "Trim", Vector3(24.0, 11.6, 9.0), Vector3(35.0, 11.6, 6.6), 1.1, 2.6)

	# Iconic square white Istrian watchtower (x = +29 m)
	var tc := Vector3(29.0, 11.4, 0.0)
	lm.box("Stone", tc + Vector3(0, 4.6, 0), Vector3(8.6, 9.2, 8.6))
	lm.box("Trim", tc + Vector3(0, 9.4, 0), Vector3(9.4, 0.7, 9.4))
	# Arched belfry/loggia windows on all 4 faces of tower
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		LandmarkDetail.window(lm, "Trim", "Glass", tc + out * 4.32 + Vector3(0, 4.8, 0), out, 2.4, 4.8, true, 0.22)
		for sx in [-3.4, 3.4]:
			lm.box("Trim", tc + out * 4.45 + r * Vector3(sx, 4.6, 0), Vector3(0.9, 8.8, 0.45), r)
	lm.box("Lamp", tc + Vector3(0, 4.8, 0), Vector3(5.6, 4.2, 5.6))

	# Twin kneeling bronze Atlases holding the gilded bronze globe + Fortune weathervane (top = 28.0 m)
	var py := tc.y + 9.75  # 21.15 m
	lm.box("Trim", Vector3(tc.x, py + 0.55, 0.0), Vector3(4.6, 1.1, 4.6))
	for sz in [-0.75, 0.75]:
		LandmarkKits.statue_figure(lm, "Bronze", Vector3(tc.x, py + 1.1, sz), 1.9)
	# Gilded bronze sphere (~2.4 m diameter)
	var ball_y := py + 2.85
	lm.lathe("Gold", Vector3(tc.x, ball_y, 0.0), LandmarkVnKit.dome_profile(1.25, 1.25), 16)
	lm.lathe("Gold", Vector3(tc.x, ball_y, 0.0), PackedVector2Array([
		Vector2(0.0, -1.25), Vector2(0.85, -0.95), Vector2(1.25, 0.0)]), 16)
	# Gilded Fortune standing atop the globe holding her billowing sail up to 28.0 m
	var fig_y := ball_y + 1.20
	LandmarkKits.statue_figure(lm, "Gold", Vector3(tc.x, fig_y, 0.0), 28.0 - fig_y, true)
	lm.box("Gold", Vector3(tc.x + 0.35, fig_y + 1.7, 0.0), Vector3(0.14, 1.9, 1.5), Basis(Vector3.UP, 0.25))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(44.0, 2.0, 0.0), Vector3(31.0, 18.0, 0.0), 50.0, 1.1],
		[Vector3(31.0, 2.0, -16.0), Vector3(29.0, 16.0, -6.0), 50.0, 0.9],
		[Vector3(31.0, 2.0, 16.0), Vector3(29.0, 16.0, 6.0), 50.0, 0.9],
	])
