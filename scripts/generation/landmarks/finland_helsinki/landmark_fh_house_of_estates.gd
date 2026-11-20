extends RefCounted

## The House of the Estates (Säätytalo, Gustaf Nyström, 1891), Snellmaninkatu
## 9-11. Origin at the OSM outline's bounding-box centre, front +Z on the
## portico (registry yaw 87 turns +Z west onto the street).
##
## Measured: the outline (way 22296373, simplified to 1 m: a 38 x 40 m block
## with the 19.4 m wide, 4 m deep portico on +Z and two rear wings) and its
## three levels. The registry point lay 57 m from the building. Estimated from
## visual-plan/refs/house_of_estates/ (no LoD2 row in reach): cream sandstone on
## a rusticated granite base, the portico of four fluted white columns between
## two square piers with gilt Corinthian capitals, the gilt frieze with the
## provincial arms, the pediment with its green-bronze relief and the gilt
## crest, rusticated and pink-frieze wings with framed windows, the broad
## granite stair with lamp standards. Column spacing, storey heights and the
## 21 m top are read from the photo scale.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "house_of_estates", "name": "House of the Estates", "lat": 60.171233, "lon": 24.954206,
	"radius_m": 1500.0, "wiki_title": "House of the Estates", "height_m": 21.0, "clear_m": 34.0,
	"yaw_deg": 87.0, "kind": "Hall", "aliases": ["house of the estates", "säätytalo", "ständerhuset"]}

## The main block and the rear wings; the portico stands on the +Z face.
const BLOCK := [-19.2, 22.3, 19.2, 22.3, 19.2, -18.0, 18.7, -18.0, 18.7, -26.3, 8.1, -26.2, 8.2, -20.0, -8.8, -20.0, -8.9, -26.0, -19.2, -25.9]
const EAVE := 15.2
const PLINTH := 3.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#E0CE9E", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F1EBDA", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9B9690", 3.0))
	lm.use("Column", LandmarkMaterials.pbr("limestone", "#F4F0E4", 1.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkMaterials.pbr("copper", "#4E6E5E", 2.0, 0.5, 0.5))
	lm.use("Pink", LandmarkMaterials.pbr("render", "#C98F7C", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2B3236"))
	lm.use("Roof", LandmarkMaterials.paint("#4C5154", 0.6, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#F6E8BC", 0.4))
	var p := D.poly(BLOCK)
	D.block(lm, p, {"eave": EAVE, "plinth": PLINTH, "stone": "Stone", "cornice": 1.1, "cornice_out": 0.6, "course_y": PLINTH + 0.1,
		"bay": 4.6, "win": Vector2(1.5, 3.0), "sill": 1.0, "y0": PLINTH + 1.2, "storey": 5.2, "rows": 2,
		"depth": 0.3, "min_len": 5.0})
	U.blk(lm, "Roof", 0.0, EAVE, -2.0, 36.0, 0.8, 38.0)
	# Pink relief frieze across the wings under the cornice.
	P.band(lm, "Pink", Vector3(-19.2, 0, 22.3), Vector3(-10.0, 0, 22.3), Vector3(0, 0, 1), 11.6, 1.6, 0.15)
	P.band(lm, "Pink", Vector3(10.0, 0, 22.3), Vector3(19.2, 0, 22.3), Vector3(0, 0, 1), 11.6, 1.6, 0.15)
	# The portico: stylobate, four fluted columns between two gilt-capped piers,
	# gilt frieze, pediment with a bronze relief, crest and acroteria.
	var z0 := 22.3
	var w := 19.4
	var h := 10.2
	var base := PLINTH + 0.2
	U.blk(lm, "Stone", 0.0, 0.0, z0 + 2.4, w + 1.2, base, 5.2)
	for k in 6:
		var x := -w * 0.5 + 0.9 + (w - 1.8) * float(k) / 5.0
		if k == 0 or k == 5:
			U.blk(lm, "Wall", x, base, z0 + 3.6, 1.8, h, 1.8)
			U.blk(lm, "Gold", x, base + h, z0 + 3.6, 2.2, 0.8, 2.2)
		else:
			lm.frustum("Column", Vector3(x, base, z0 + 3.6), 0.62, 0.52, h, 16)
			lm.frustum("Gold", Vector3(x, base + h, z0 + 3.6), 0.75, 0.9, 0.9, 12)
	var ent := base + h + 0.9
	U.blk(lm, "Trim", 0.0, ent, z0 + 2.4, w + 1.0, 0.9, 5.4)
	U.blk(lm, "Gold", 0.0, ent + 0.9, z0 + 4.95, w, 0.9, 0.3)
	U.ridge_z(lm, "Trim", "Bronze", Vector3(0, ent + 1.8, z0 + 2.4), w + 1.0, 5.4, 3.3, 0.2)
	U.blk(lm, "Gold", 0.0, ent + 5.0, z0 + 2.4, 1.8, 1.4, 0.8)
	# Three doors under a window storey behind the colonnade.
	P.win_row(lm, "Trim", "Glass", Vector3(-6.5, 0, z0 + 0.1), Vector3(6.5, 0, z0 + 0.1), Vector3(0, 0, 1), base + 0.4, 3, 2.2, 4.6, false, 0.3)
	P.win_row(lm, "Trim", "Glass", Vector3(-6.5, 0, z0 + 0.1), Vector3(6.5, 0, z0 + 0.1), Vector3(0, 0, 1), base + 6.4, 3, 2.2, 3.6, false, 0.3)
	# The broad granite stair with lamp standards at its head.
	U.steps(lm, "Stone", Vector3(0, 0, z0 + 5.2), Vector3(0, 0, 1), 22.0, 0.55, 0.19, 18)
	for s in [-1.0, 1.0]:
		lm.frustum("Column", Vector3(s * 8.4, base, z0 + 6.4), 0.18, 0.12, 3.2, 8)
		lm.lathe("Lamp", Vector3(s * 8.4, base + 3.2, z0 + 6.4), U.ball(0.35), 8)
	lm.commit(model)
	D.flood(model, [
		[Vector3(-14.0, 0.5, 44.0), Vector3(-2.0, 10.0, 24.0), 50.0, 0.9, 45.0, Color(1.0, 0.9, 0.74)],
		[Vector3(14.0, 0.5, 44.0), Vector3(2.0, 10.0, 24.0), 50.0, 0.9, 45.0, Color(1.0, 0.9, 0.74)]])
