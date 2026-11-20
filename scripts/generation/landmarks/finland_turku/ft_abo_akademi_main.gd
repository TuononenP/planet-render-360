class_name FtAboAkademiMain
extends RefCounted

## Old Academy Building & Åbo Akademi Cathedral Quarter (Vanha Akatemiatalo,
## 1815, C.C. Gjörwell & Charles Bassi): Finland's premier Gustavian
## neoclassical ceremonial palace on Rothoviuksenkatu / Tuomiokirkontori
## (+X ENE, -Z NNW facing Tuomiokirkontori & Cathedral, yaw_deg = -23.2°,
## height_m = 19.0):
##   - Monumental 3-storey pale-yellow Empire / Gustavian neoclassical block
##     (58 x 24 m main wing + flanking rear courtyard wings, eaves 13.8 m,
##     hipped dark-metal roof to 18.9 m).
##   - Rusticated granite-and-plaster ground storey, central 6-column/pilaster
##     giant Ionic ceremonial order with broad triangular pediment facing
##     Tuomiokirkontori (-Z), rhythmic arched Solennitetssalen ballroom
##     windows on the piano nobile, and warm ceremonial hall night glow.
## Surfaces: 7 merged PBR parts (Wall, Base, Trim, Stone, Roof, Glass, Lamp).

const FOUND := -2.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E9D9A4", 3.0))
	lm.use("Base", LandmarkMaterials.pbr("render", "#D5C694", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F6F3EA", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#86827A", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#373C41", 2.2))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BA", 1.35))

	# Main 58 x 22 m Old Academy Building (Vanha Akatemiatalo, eaves 13.8 m, hipped roof 18.9 m).
	LandmarkFrKit.rect(lm, "Stone", -29.4, 29.4, -11.4, 11.4, FOUND, 1.4)
	LandmarkFrKit.rect(lm, "Base", -29.2, 29.2, -11.2, 11.2, 1.4, 5.2)
	LandmarkFrKit.rect(lm, "Wall", -29.0, 29.0, -11.0, 11.0, 5.2, 13.8)
	LandmarkFrParts.band(lm, "Trim", -29.0, 29.0, -11.0, 11.0, 5.15, 0.45, 0.16)
	LandmarkFrParts.cornice_ring(lm, "Trim", -29.0, 29.0, -11.0, 11.0, 13.1, 0.72)
	LandmarkFrKit.hip(lm, "Roof", -29.0, 29.0, -11.0, 11.0, 13.8, 5.1, 0.55)
	# Twin rear academy wings enclosing the southern honour courtyard (+Z = +11..+30).
	for sx: float in [-1.0, 1.0]:
		var x0 := sx * 21.5 - 7.5
		var x1 := sx * 21.5 + 7.5
		LandmarkFrKit.rect(lm, "Base", x0 - 0.15, x1 + 0.15, 11.0, 30.2, FOUND, 4.8)
		LandmarkFrKit.rect(lm, "Wall", x0, x1, 11.0, 30.0, 4.8, 12.6)
		LandmarkFrParts.cornice_ring(lm, "Trim", x0, x1, 11.0, 30.0, 12.05, 0.55)
		LandmarkFrKit.hip(lm, "Roof", x0, x1, 11.0, 30.0, 12.6, 4.2, 0.45)
	# Central projecting 7-bay Gustavian neoclassical avant-corps (-Z facing Cathedral square).
	LandmarkFrKit.rect(lm, "Wall", -10.5, 10.5, -12.1, -10.8, 5.2, 14.0)
	LandmarkFrKit.rect(lm, "Base", -10.7, 10.7, -12.3, -10.8, FOUND, 5.2)
	for k in 6:
		var px := lerpf(-9.2, 9.2, float(k) / 5.0)
		lm.frustum("Trim", Vector3(px, 5.2, -12.22), 0.42, 0.36, 8.2, 12)
		lm.box("Trim", Vector3(px, 13.45, -12.22), Vector3(0.95, 0.35, 0.95))
	LandmarkFrParts.gable_wall(lm, "Trim", Vector3(0.0, 14.0, -12.25), Vector3.RIGHT, Vector3.FORWARD, 21.4, 3.6, 0.70)
	# Grand entrance steps & three arched ground portals (-Z).
	LandmarkFrKit.rect(lm, "Stone", -7.2, 7.2, -14.2, -12.3, FOUND, 0.9)
	for ax: float in [-3.8, 0.0, 3.8]:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(ax, 0.9, -12.3), Vector3.FORWARD, 2.2, 3.6,
			LandmarkFrParts.HEAD_ROUND, 0.24, 0.16, 1)
	# Tall arched Solennitetssalen ceremonial hall windows & flanking 13-bay Empire windows.
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-7.4, 6.2, -12.1), Vector3(7.4, 6.2, -12.1),
		Vector3.FORWARD, 5, 1.75, 4.6, LandmarkFrParts.HEAD_ROUND, 0.22, 0.16, 1)
	LandmarkFrKit.rect(lm, "Lamp", -7.8, 7.8, -11.4, -11.0, 6.6, 10.2)
	for sx: float in [-1.0, 1.0]:
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 13.0, 2.0, -11.2), Vector3(sx * 26.8, 2.0, -11.2),
			Vector3.FORWARD, 4, 1.4, 2.4, LandmarkFrParts.HEAD_FLAT, 0.16, 0.12, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 13.0, 6.1, -11.0), Vector3(sx * 26.8, 6.1, -11.0),
			Vector3.FORWARD, 4, 1.45, 2.8, LandmarkFrParts.HEAD_FLAT, 0.18, 0.14, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 13.0, 9.8, -11.0), Vector3(sx * 26.8, 9.8, -11.0),
			Vector3.FORWARD, 4, 1.4, 2.3, LandmarkFrParts.HEAD_FLAT, 0.16, 0.12, 1)

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.5, -22.0), Vector3(0.0, 10.0, -12.0), 58.0, 0.90, 44.0, Color(1.0, 0.88, 0.66)],
		[Vector3(-18.0, 1.5, -20.0), Vector3(-18.0, 8.5, -11.0), 56.0, 0.75, 38.0, Color(1.0, 0.88, 0.66)],
		[Vector3(18.0, 1.5, -20.0), Vector3(18.0, 8.5, -11.0), 56.0, 0.75, 38.0, Color(1.0, 0.88, 0.66)],
	])
