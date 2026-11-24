class_name VnSanMarcoInterior
extends RefCounted

## San Marco interior architectural gems (`VN-4.6`):
## - Teatro La Fenice (Selva 1792: Corinthian portico, pediment & gilt phoenix emblem)
## - Palazzo Contarini del Bovolo (Candi 1499: 28 m cylindrical external spiral staircase tower!)

static func teatro_la_fenice(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#ECE6D8", 2.8))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F3E8", 2.0))
	lm.use("Stucco", LandmarkVnKit.stucco("#E2CBA8", 3.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9C6049", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#242C32"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE19E", 2.0))

	# Main opera auditorium & stage flytower block (40 x 58 m, height 24.0 m)
	lm.box("Stucco", Vector3(0.0, 9.6, -4.0), Vector3(38.0, 19.2, 52.0))
	lm.gable("Roof", Vector3(0.0, 19.2, -4.0), 38.6, 52.6, 3.8, Basis(), 0.25, "Stucco")
	lm.box("Stucco", Vector3(0.0, 21.0, -14.0), Vector3(22.0, 5.8, 18.0))
	lm.box("Trim", Vector3(0.0, 23.9, -14.0), Vector3(22.6, 0.45, 18.6))

	# Selva's crisp Neoclassical white Istrian-stone front on Campo San Fantin (+Z)
	lm.box("Stone", Vector3(0.0, 9.8, 22.8), Vector3(34.0, 19.6, 3.2))
	lm.box("Trim", Vector3(0.0, 19.8, 22.8), Vector3(35.0, 0.7, 3.8))
	# Four-column Corinthian portico + central pediment + gilded rising Phoenix emblem
	for x in [-6.0, -2.0, 2.0, 6.0]:
		LandmarkDetail.column(lm, "Trim", Vector3(float(x), 0.0, 26.2), 0.52, 11.2, "corinthian", 10)
	lm.box("Trim", Vector3(0.0, 11.9, 25.0), Vector3(15.6, 1.4, 3.4))
	lm.gable("Trim", Vector3(0.0, 12.6, 25.0), 15.8, 3.4, 3.4, Basis(), 0.25, "Stone")
	# Gilded Phoenix plaque on pediment & rooftop balustrade
	lm.disc("Gold", Vector3(0.0, 14.0, 26.75), Vector3(0, 0, 1), 1.05, 12)
	LandmarkDetail.balustrade(lm, "Trim", Vector3(-16.5, 20.15, 24.2), Vector3(16.5, 20.15, 24.2), 1.1, 3.0)
	for sx in [-12.0, 12.0]:
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(sx), 13.0, 24.45), Vector3(0, 0, 1), 2.2, 4.4, true, 0.18)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(float(sx), 4.6, 24.45), Vector3(0, 0, 1), 2.2, 4.4, true, 0.18)
	lm.box("Lamp", Vector3(0.0, 8.2, 25.2), Vector3(8.0, 0.5, 0.4))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 34.0, 52.0, 24.0, 0.9)

static func contarini_del_bovolo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#B85D43", 2.6))
	lm.use("Stone", LandmarkVnKit.istrian("#EFEBE0", 2.2))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 1.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#9E614A", 2.4))
	lm.use("Lead", LandmarkVnKit.lead_dome("#8B9298", 2.0))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE19E", 2.0))

	# Main Venetian Gothic/Renaissance brick palazzo wing (-Z, height 20.5 m)
	lm.box("Brick", Vector3(-4.0, 9.0, -4.0), Vector3(24.0, 18.0, 18.0))
	lm.gable("Roof", Vector3(-4.0, 18.0, -4.0), 18.4, 24.4, 2.6, Basis(Vector3.UP, PI * 0.5), 0.25, "Brick")
	# Multi-storey Renaissance open loggia gallery linking palazzo to the spiral tower
	for s in 5:
		var sy := 3.6 * float(s)
		lm.box("Trim", Vector3(-2.0, sy + 0.2, 6.2), Vector3(14.0, 0.35, 2.8))
		for i in 5:
			var lx := -8.0 + 3.0 * float(i)
			lm.frustum("Trim", Vector3(lx, sy + 0.35, 7.2), 0.18, 0.16, 3.2, 8)
		lm.box("Glass", Vector3(-2.0, sy + 1.8, 5.1), Vector3(13.2, 3.0, 0.15))

	# Iconic 28.0 m cylindrical external spiral staircase tower (Scala del Bovolo) at (+7.5, +6.5)
	var tc := Vector3(7.5, 0.0, 6.5)
	var r_outer := 3.65
	lm.frustum("Brick", tc, 2.15, 2.15, 22.8, 16)
	# Six spiraling helical tiers of white Istrian-stone columns, round arches & ascending balustrades
	var turns := 5.5
	var steps := 44
	for i in steps:
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var a0 := t0 * TAU * turns
		var a1 := t1 * TAU * turns
		var y0 := 0.5 + t0 * 21.5
		var y1 := 0.5 + t1 * 21.5
		var p0 := tc + Vector3(cos(a0) * r_outer, y0, sin(a0) * r_outer)
		var p1 := tc + Vector3(cos(a1) * r_outer, y1, sin(a1) * r_outer)
		# Helical stone stair rim & solid parapet ribbon
		lm.beam("Trim", p0, p1, 0.36, 0.95)
		# Slender Istrian colonnette rising to the next coil
		lm.frustum("Trim", p0 + Vector3(0, 0.45, 0), 0.16, 0.14, 3.05, 8)
		if i % 8 == 2:
			lm.box("Lamp", tc + Vector3(cos(a0) * (r_outer - 0.8), y0 + 1.4, sin(a0) * (r_outer - 0.8)),
				Vector3(0.32, 0.36, 0.32))
	# Top open belvedere colonnade + hemispherical lead cupola reaching 28.0 m
	var by := 22.6
	lm.frustum("Trim", Vector3(tc.x, by, tc.z), r_outer + 0.25, r_outer + 0.25, 0.45, 16)
	for k in 10:
		var a := TAU * float(k) / 10.0
		lm.frustum("Trim", Vector3(tc.x + cos(a) * (r_outer - 0.15), by + 0.45, tc.z + sin(a) * (r_outer - 0.15)),
			0.18, 0.16, 2.8, 8)
	lm.frustum("Trim", Vector3(tc.x, by + 3.25, tc.z), r_outer + 0.2, r_outer + 0.25, 0.4, 16)
	lm.lathe("Lead", Vector3(tc.x, by + 3.65, tc.z), LandmarkVnKit.dome_profile(r_outer - 0.1, 1.75), 16)
	lm.box("Lamp", Vector3(tc.x, by + 1.8, tc.z), Vector3(1.8, 1.4, 1.8))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(14.0, 1.5, 14.0), Vector3(7.5, 15.0, 6.5), 48.0, 1.0],
		[Vector3(2.0, 1.5, 15.0), Vector3(7.5, 15.0, 6.5), 48.0, 0.85],
	])
