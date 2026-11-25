class_name LandmarkSgChinatownTemples
extends RefCounted

## Historic Chinatown & Telok Ayer temples (SG-3.11–3.13):
## - `sri_mariamman` (18 m, way 300380459): 6-tier polychrome sculpted Dravidian gopuram
##   with coloured figure relief bands, golden kalasams, mandapam hall, and Nandi-topped wall.
## - `buddha_tooth_relic` (34 m, way 47298635): Crimson-and-white Tang-dynasty palace hall
##   with sweeping dark-grey upturned tiered ceramic roofs & golden ridge ornaments.
## - `thian_hock_keng` (14 m, way 172272611): 1840 Hokkien courtyard temple with sweeping
##   swallowtail ceramic roofs & carved porcelain dragon ridges.

static func sri_mariamman(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F4EFE6", 3.0))
	lm.use("Saffron", LandmarkMaterials.pbr("concrete", "#E28A28", 2.0))
	lm.use("Crimson", LandmarkMaterials.pbr("concrete", "#C43238", 2.0))
	lm.use("Teal", LandmarkMaterials.pbr("concrete", "#2A8482", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFD988", 1.8))

	# Compound boundary wall with seated white Nandi bull figures along South Bridge Rd (+X).
	lm.box("White", Vector3(0.0, 2.2, 0.0), Vector3(44.0, 4.4, 26.0))
	for i in 9:
		var wx := -20.0 + float(i) * 5.0
		lm.box("White", Vector3(wx, 4.9, 13.0), Vector3(1.1, 1.0, 0.9))
		lm.box("White", Vector3(wx, 4.9, -13.0), Vector3(1.1, 1.0, 0.9))
	# Inner mandapam prayer hall & vimana dome.
	lm.box("White", Vector3(-6.0, 5.0, 0.0), Vector3(24.0, 6.0, 18.0))
	LandmarkAsiaSouthUtil.dome(lm, "Gold", Vector3(-12.0, 8.0, 0.0), 4.2, 4.6, 12, 6)

	# 6-tier polychrome sculpted Dravidian Gopuram entrance tower on South Bridge Rd (+X end, 18.0 m).
	var gx := 20.0
	var tier_mats := ["Saffron", "Crimson", "Teal", "Saffron", "Crimson", "Teal"]
	lm.box("White", Vector3(gx, 2.5, 0.0), Vector3(6.8, 5.0, 10.2))
	var y := 5.0
	for t in 6:
		var k := 1.0 - float(t) * 0.12
		var th := 1.85
		lm.box(str(tier_mats[t]), Vector3(gx, y + th * 0.5, 0.0), Vector3(6.2 * k, th, 9.6 * k))
		lm.box("White", Vector3(gx, y + th, 0.0), Vector3(6.5 * k, 0.25, 9.9 * k))
		y += th
	# Barrel-vaulted sala crown & 5 golden kalasam finials reaching 18.0 m.
	lm.box("Saffron", Vector3(gx, y + 0.7, 0.0), Vector3(2.4, 1.4, 4.8))
	for k in 5:
		lm.spire("Gold", Vector3(gx, y + 1.4, -1.8 + float(k) * 0.9), 0.24, 0.95, 0.04, 6)
	lm.box("WarmLamp", Vector3(gx + 3.6, 5.2, 0.0), Vector3(0.4, 0.4, 8.0))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(gx + 10.0, 2.0, 0.0), Vector3(gx, 11.0, 0.0), 58.0, 1.5],
	])

static func buddha_tooth_relic(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Crimson", LandmarkMaterials.pbr("concrete", "#9E2422", 2.0))
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F0ECE2", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#383C42", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFCE78", 1.8))

	# Monumental 5-storey Tang-dynasty palace-temple hall (72 x 32 m, 34 m total height).
	lm.box("White", Vector3(0.0, 2.0, 0.0), Vector3(74.0, 4.0, 34.0))
	# Three stacked Tang tiers with sweeping dark-grey upturned hip roofs.
	var tiers := [
		[4.0, 12.0, 70.0, 30.0, 76.0, 36.0],
		[12.0, 20.5, 60.0, 25.0, 66.0, 31.0],
		[20.5, 28.0, 48.0, 20.0, 56.0, 26.0],
	]
	for tr in tiers:
		var y0 := float(tr[0]); var y1 := float(tr[1])
		lm.box("Crimson", Vector3(0.0, 0.5 * (y0 + y1), 0.0), Vector3(float(tr[2]), y1 - y0, float(tr[3])))
		# Upturned eaves overhang & golden roof ridge.
		lm.box("Roof", Vector3(0.0, y1 + 0.9, 0.0), Vector3(float(tr[4]), 1.8, float(tr[5])))
		lm.box("Gold", Vector3(0.0, y1 + 1.9, 0.0), Vector3(float(tr[4]) - 2.0, 0.4, 0.9))
	# Crowning Tang hip-and-gable roof & golden finials reaching 34.0 m.
	lm.box("Roof", Vector3(0.0, 30.8, 0.0), Vector3(44.0, 3.8, 18.0))
	lm.box("Gold", Vector3(0.0, 33.4, 0.0), Vector3(38.0, 1.2, 1.4))
	lm.box("WarmLamp", Vector3(0.0, 11.8, 16.2), Vector3(64.0, 0.45, 0.45))
	lm.box("WarmLamp", Vector3(0.0, 20.3, 13.6), Vector3(54.0, 0.45, 0.45))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.5, 28.0), Vector3(0.0, 18.0, 12.0), 66.0, 1.4],
	])

static func thian_hock_keng(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B8B2A6", 3.0))
	lm.use("Crimson", LandmarkMaterials.pbr("concrete", "#A42824", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#9E3E2A", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFD282", 1.7))

	# Walled Hokkien courtyard complex (way 172272611): entrance hall, courtyard, main Mazu hall.
	lm.box("Granite", Vector3(0.0, 1.8, 0.0), Vector3(56.0, 3.6, 54.0))
	# Front entrance hall (+Z) and main inner hall (-Z) with sweeping swallowtail roof ridges.
	for hz: float in [18.0, -14.0]:
		var hh := 7.2 if hz < 0.0 else 5.8
		var hw := 38.0 if hz < 0.0 else 32.0
		lm.box("Crimson", Vector3(0.0, 3.6 + hh * 0.5, hz), Vector3(hw, hh, 14.0))
		lm.box("Roof", Vector3(0.0, 3.6 + hh + 1.4, hz), Vector3(hw + 5.0, 2.8, 17.5))
		# Upturned swallowtail dragon ridge tips reaching 14.0 m on main hall.
		lm.box("Gold", Vector3(0.0, 3.6 + hh + 3.0, hz), Vector3(hw + 2.0, 0.55, 0.8))
		lm.spire("Gold", Vector3(-hw * 0.5 - 1.5, 3.6 + hh + 2.8, hz), 0.7, 1.8, 0.1, 4)
		lm.spire("Gold", Vector3(hw * 0.5 + 1.5, 3.6 + hh + 2.8, hz), 0.7, 1.8, 0.1, 4)
	lm.box("WarmLamp", Vector3(0.0, 8.8, 25.5), Vector3(28.0, 0.4, 0.4))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 34.0), Vector3(0.0, 8.0, 18.0), 62.0, 1.2],
	])
