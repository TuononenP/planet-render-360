class_name VnGiudecca
extends RefCounted

## Giudecca waterfront icons (`VN-6.1`–`VN-6.3`):
## - Il Redentore (Palladio 1577: interlocking white temple pediments, high ribbed dome 52 m, twin slender conical campanili)
## - Le Zitelle (Palladian white-and-ochre church with central dome 36 m & twin bell turrets)
## - Molino Stucky (1895 colossal red-brick Neo-Gothic flour mill with stepped Flemish gables & 38 m corner tower)

static func il_redentore(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F1ECE1", 2.8))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F9F6EE", 2.0))
	lm.use("Brick", LandmarkVnKit.brick("#B85B43", 2.8))
	lm.use("Roof", LandmarkVnKit.terracotta("#A0624A", 2.4))
	lm.use("Lead", LandmarkVnKit.lead_dome("#8D949A", 2.2))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A6", 2.1))

	# Broad monumental Istrian-stone flight of 15 steps (+Z facing Giudecca Canal)
	for k in 6:
		lm.box("Trim", Vector3(0.0, 0.35 + 0.35 * float(k), 34.5 - 1.1 * float(k)),
			Vector3(34.0 - 0.8 * float(k), 0.38, 1.2))
	lm.box("Stone", Vector3(0.0, 1.2, 2.0), Vector3(36.0, 2.4, 58.0))

	# Palladio's supreme interlocking triple-pediment white Istrian temple front at z = +26.5 m
	LandmarkVnKit.palladian_front(lm, "Stone", "Trim", "Glass",
		Vector3(0.0, 2.4, 26.5), Vector3.RIGHT, Vector3(0, 0, 1),
		34.0, 19.0, 21.0, 13.0, 5.8, 4)
	# Rectangular upper attic behind pediment screening the barrel vault
	lm.box("Stone", Vector3(0.0, 26.2, 24.5), Vector3(17.5, 4.4, 2.4))

	# Brick nave + side chapels + triconch choir apses
	lm.box("Brick", Vector3(0.0, 11.4, -2.0), Vector3(20.0, 18.4, 54.0))
	lm.box("Brick", Vector3(0.0, 7.6, 2.0), Vector3(33.0, 10.6, 36.0))
	lm.gable("Roof", Vector3(0.0, 20.6, 4.0), 20.6, 38.0, 4.2, Basis(), 0.25, "Brick")
	for sx in [-1.0, 1.0]:
		lm.frustum("Brick", Vector3(sx * 12.5, 2.4, -14.0), 7.8, 7.8, 17.5, 16)
		lm.frustum("Roof", Vector3(sx * 12.5, 19.9, -14.0), 8.2, 0.5, 2.8, 16)
	lm.frustum("Brick", Vector3(0.0, 2.4, -26.0), 8.2, 8.2, 17.5, 16)
	lm.frustum("Roof", Vector3(0.0, 19.9, -26.0), 8.6, 0.5, 2.8, 16)

	# High ribbed lead main dome + lantern + Christ Redeemer statue (top = 52.0 m)
	LandmarkVnKit.venetian_dome(lm, "Stone", "Trim", "Lead", "Glass", "Gold",
		Vector3(0.0, 21.0, -14.0), 9.0, 8.2, 13.2, 6.2, 3.4)
	lm.frustum("Lamp", Vector3(0.0, 42.6, -14.0), 1.8, 1.8, 3.0, 8)

	# Signature twin slender cylindrical white campanili with conical spires flanking the drum
	for sx in [-1.0, 1.0]:
		var cp := Vector3(sx * 12.5, 2.4, -21.5)
		lm.frustum("Stone", cp, 2.1, 1.95, 27.0, 12)
		lm.frustum("Trim", cp + Vector3(0, 27.0, 0), 2.2, 2.2, 0.5, 12)
		lm.frustum("Glass", cp + Vector3(0, 27.5, 0), 1.5, 1.5, 4.0, 10)
		for k in 6:
			var a := TAU * float(k) / 6.0
			lm.frustum("Trim", cp + Vector3(cos(a) * 1.8, 27.5, sin(a) * 1.8), 0.18, 0.16, 4.0, 6)
		lm.frustum("Trim", cp + Vector3(0, 31.5, 0), 2.15, 2.15, 0.45, 12)
		lm.spire("Lead", cp + Vector3(0, 31.95, 0), 1.9, 7.6, 0.08, 12)
		lm.frustum("Gold", cp + Vector3(0, 39.55, 0), 0.18, 0.06, 1.4, 6)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-10.0, 2.0, 38.0), Vector3(-6.0, 18.0, 26.5), 50.0, 1.0],
		[Vector3(10.0, 2.0, 38.0), Vector3(6.0, 18.0, 26.5), 50.0, 1.0],
		[Vector3(0.0, 22.0, 6.0), Vector3(0.0, 38.0, -14.0), 50.0, 0.9],
	])

static func le_zitelle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#F0ECE1", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F8F5EC", 2.0))
	lm.use("Stucco", LandmarkVnKit.stucco("#E4C8A2", 3.0))
	lm.use("Roof", LandmarkVnKit.terracotta("#9E614A", 2.4))
	lm.use("Lead", LandmarkVnKit.lead_dome("#8B9298", 2.2))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#252D33"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A4", 1.9))

	# Flanking ochre hospice wings + central white Palladian church front (+Z)
	for sx: float in [-1.0, 1.0]:
		lm.box("Stucco", Vector3(sx * 18.5, 6.4, -2.0), Vector3(17.0, 12.8, 36.0))
		lm.gable("Roof", Vector3(sx * 18.5, 12.8, -2.0), 17.4, 36.4, 2.6, Basis(), 0.25, "Stucco")
		for i in 4:
			var x := sx * (12.0 + 3.8 * float(i))
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 8.6, 16.06), Vector3(0, 0, 1), 1.4, 2.8, false, 0.14)
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 4.0, 16.06), Vector3(0, 0, 1), 1.4, 2.6, false, 0.14)
	# Central church cube + Palladian pediment + thermal window
	lm.box("Stone", Vector3(0.0, 8.4, 0.0), Vector3(20.0, 16.8, 32.0))
	LandmarkVnKit.palladian_front(lm, "Stone", "Trim", "Glass",
		Vector3(0.0, 0.0, 16.2), Vector3.RIGHT, Vector3(0, 0, 1),
		20.4, 15.0, 15.4, 10.0, 3.6, 4)
	# Large central dome + lantern (top = 36.0 m) flanked symmetrically by twin delicate bell turrets
	LandmarkVnKit.venetian_dome(lm, "Stone", "Trim", "Lead", "Glass", "Gold",
		Vector3(0.0, 16.8, 0.0), 7.2, 5.0, 8.4, 3.8, 2.0)
	lm.frustum("Lamp", Vector3(0.0, 30.4, 0.0), 1.4, 1.4, 2.0, 8)
	for sx in [-1.0, 1.0]:
		var tp := Vector3(sx * 9.0, 16.4, 14.5)
		lm.box("Stone", tp + Vector3(0, 3.2, 0), Vector3(2.8, 6.4, 2.8))
		lm.box("Trim", tp + Vector3(0, 6.6, 0), Vector3(3.1, 0.4, 3.1))
		lm.lathe("Lead", tp + Vector3(0, 6.8, 0), LandmarkVnKit.dome_profile(1.4, 2.6, true), 10)
		lm.frustum("Gold", tp + Vector3(0, 9.4, 0), 0.14, 0.05, 1.0, 6)
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 54.0, 36.0, 36.0, 0.85)

static func molino_stucky(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#A24834", 3.0))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#E9E2D2", 2.2))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#565B60", 2.4))
	lm.use("Glass", LandmarkVnKit.shadow_glass("#222A30"))
	lm.use("Algae", LandmarkVnKit.algae_plinth())
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE3A4", 2.1))

	# Ernst Wullekopf's colossal 1895 Neo-Gothic red-brick flour mill (124 x 58 m, height 38.0 m)
	lm.box("Algae", Vector3(0.0, 0.22, 0.0), Vector3(124.6, 0.6, 58.6))
	lm.box("Brick", Vector3(0.0, 13.0, 0.0), Vector3(124.0, 25.4, 58.0))
	lm.gable("Roof", Vector3(0.0, 25.7, 0.0), 58.4, 124.4, 4.8, Basis(Vector3.UP, PI * 0.5), 0.25, "Brick")
	# White-stone string courses & regular arched industrial factory window grid along Giudecca front (+Z)
	for sy in [6.0, 12.2, 18.4, 24.8]:
		lm.box("Trim", Vector3(0.0, float(sy), 29.1), Vector3(124.4, 0.42, 0.36))
	for i in 19:
		var x := -54.0 + 6.0 * float(i)
		for sy in [3.4, 9.2, 15.4, 21.4]:
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, float(sy), 29.06), Vector3(0, 0, 1), 2.1, 3.6, true, 0.16)
	# Three iconic stepped Flemish Neo-Gothic gables along the canal front (+Z)
	for gx in [-36.0, 0.0, 36.0]:
		for k in 5:
			var w := 18.0 - 3.2 * float(k)
			lm.box("Brick", Vector3(float(gx), 26.4 + 1.45 * float(k), 28.8), Vector3(w, 1.5, 1.2))
			lm.box("Trim", Vector3(float(gx), 27.15 + 1.45 * float(k), 29.1), Vector3(w + 0.5, 0.25, 0.8))
	# Towering crenellated corner Neo-Gothic brick keep at +X (top = 38.0 m)
	var tx := 48.0
	lm.box("Brick", Vector3(tx, 17.5, 18.0), Vector3(14.0, 35.0, 14.0))
	lm.box("Trim", Vector3(tx, 34.8, 18.0), Vector3(14.8, 0.65, 14.8))
	for sx in [-6.8, 6.8]:
		for sz in [-6.8, 6.8]:
			lm.spire("Brick", Vector3(tx + float(sx), 35.1, 18.0 + float(sz)), 1.05, 2.9, 0.0, 4)
	# Illuminated "MOLINO STUCKY" rooftop banner bar facing the Zattere (+Z)
	lm.box("Trim", Vector3(-6.0, 29.2, 28.9), Vector3(44.0, 2.4, 0.5))
	lm.box("Lamp", Vector3(-6.0, 29.2, 29.22), Vector3(41.0, 1.5, 0.15))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 120.0, 58.0, 38.0, 0.9)
