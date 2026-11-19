class_name LandmarkFtHistoric
extends RefCounted

## Turku's historic and maritime landmarks in true metres (+X east, +Z
## south, turned onto the OSM footprint by registry yaw_deg):
##  - Kakola Prison (1853, granite cellblocks on Kakolanmäki)
##  - Brinkkala Mansion / Vanha Suurtori (Empire neoclassical civic square)
##  - Suomen Joutsen (1902 white 3-masted full-rigged museum ship on Aurajoki)
##  - Föri (1904 iconic orange-and-white Aurajoki cable ferry)

## Kakola (1853, Ernst Lohrmann): imposing grey-granite and rendered
## former prison complex crowning Kakolanmäki hill — long central wing,
## symmetric cross-wings, dark pitched roofs and barred regular window grid.
static func kakola_prison(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#848078", 2.5))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D6CFC0", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#ECE6D8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3A3E42", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#1E2428"))
	# Main granite wing (66 x 18 m, 4 storeys, eaves 16 m, hipped roof to 22 m).
	LandmarkFrKit.rect(lm, "Granite", -33.0, 33.0, -9.0, 9.0, 0.0, 16.0)
	LandmarkFrParts.cornice_ring(lm, "Trim", -33.0, 33.0, -9.0, 9.0, 15.4, 0.6)
	LandmarkFrKit.hip(lm, "Roof", -33.0, 33.0, -9.0, 9.0, 16.0, 6.0, 0.6)
	# Central slightly taller chapel/admin pavilion rising to 24 m.
	LandmarkFrKit.rect(lm, "Granite", -9.0, 9.0, -11.0, 11.0, 0.0, 18.0)
	LandmarkFrKit.hip(lm, "Roof", -9.0, 9.0, -11.0, 11.0, 18.0, 6.0, 0.5)
	# Twin projecting end wings.
	for sx: float in [-1.0, 1.0]:
		var x0 := sx * 26.0 - 7.0
		var x1 := sx * 26.0 + 7.0
		LandmarkFrKit.rect(lm, "Granite", x0, x1, 9.0, 22.0, 0.0, 14.5)
		LandmarkFrKit.hip(lm, "Roof", x0, x1, 9.0, 22.0, 14.5, 4.8, 0.5)
	for sz: float in [-1.0, 1.0]:
		LandmarkFrParts.facade(lm, "Granite", "Glass", Vector3(-31.0, 2.0, sz * 9.0), Vector3(31.0, 2.0, sz * 9.0),
			Vector3(0, 0, sz), 13.0, 15, 3, Vector2(1.2, 1.9), 1.0, 3.8, 0.25)
	lm.commit(model)

## Brinkkala Mansion (Brinkkalan talo, 1829 reconstruction after the Great
## Fire of Turku): iconic pale-yellow Empire neoclassical mansion on Vanha
## Suurtori with central projecting balcony (where the Declaration of
## Christmas Peace is read), rusticated ground floor and low hipped roof.
static func vanha_suurtori(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E7CE82", 3.0))
	lm.use("Base", LandmarkMaterials.pbr("render", "#D8C27C", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F4F0E6", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3B4042", 2.0))
	lm.use("Iron", LandmarkMaterials.paint("#242628", 0.45, 0.65))
	lm.use("Glass", LandmarkMaterials.glass("#222B30"))
	# Main street wing (34 x 14 m, 2.5 storeys, eaves 10.5 m, hipped roof to 14.8 m).
	LandmarkFrKit.rect(lm, "Base", -17.0, 17.0, -7.0, 7.0, 0.0, 4.2)
	LandmarkFrKit.rect(lm, "Wall", -17.0, 17.0, -7.0, 7.0, 4.2, 10.5)
	LandmarkFrParts.band(lm, "Trim", -17.0, 17.0, -7.0, 7.0, 4.1, 0.4, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", -17.0, 17.0, -7.0, 7.0, 10.0, 0.55)
	LandmarkFrKit.hip(lm, "Roof", -17.0, 17.0, -7.0, 7.0, 10.5, 4.3, 0.4)
	# Courtyard wings enclosing the Brinkkala inner yard (-Z).
	for sx: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Wall", sx * 12.5 - 4.5, sx * 12.5 + 4.5, -22.0, -7.0, 0.0, 8.8)
		LandmarkFrKit.hip(lm, "Roof", sx * 12.5 - 4.5, sx * 12.5 + 4.5, -22.0, -7.0, 8.8, 3.4, 0.35)
	# Windows along Vanha Suurtori front (+Z) + iconic Christmas Peace balcony.
	LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-15.5, 1.2, 7.0), Vector3(15.5, 1.2, 7.0),
		Vector3.BACK, 8.8, 9, 2, Vector2(1.3, 2.2), 0.7, 4.2, 0.18)
	lm.box("Trim", Vector3(0.0, 4.4, 7.9), Vector3(6.2, 0.35, 1.8))
	lm.box("Iron", Vector3(0.0, 5.1, 8.75), Vector3(6.2, 1.0, 0.08))
	for sx2: float in [-3.05, 3.05]:
		lm.box("Iron", Vector3(sx2, 5.1, 7.9), Vector3(0.08, 1.0, 1.8))
	lm.commit(model)

## Suomen Joutsen (1902, St-Nazaire): iconic white steel-hulled 3-masted
## full-rigged museum ship permanently moored at Forum Marinum on Aurajoki
## (96 m overall including bowsprit, 12.4 m beam, three tall masts to 44 m
## with horizontal yards). Built along +X, y = 0 at water level.
static func suomen_joutsen(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Hull", LandmarkMaterials.paint("#F2EFE8", 0.55, 0.08))
	lm.use("Boot", LandmarkMaterials.paint("#7E2822", 0.65, 0.05))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#9E7E58", 2.5))
	lm.use("Mast", LandmarkMaterials.paint("#E6DCC6", 0.5, 0.1))
	lm.use("Yard", LandmarkMaterials.paint("#D8CCB4", 0.55, 0.1))
	lm.use("Dark", LandmarkMaterials.paint("#2A2E32", 0.5, 0.4))
	# Red boot-top at waterline and gleaming white hull (78 m hull, 12 m beam, 5.2 m freeboard).
	lm.box("Boot", Vector3(0.0, 0.4, 0.0), Vector3(72.0, 1.2, 11.4))
	lm.box("Hull", Vector3(0.0, 2.9, 0.0), Vector3(74.0, 4.0, 12.0))
	# Tapered bow (+X) and stern (-X) sections.
	lm.box("Hull", Vector3(39.0, 3.2, 0.0), Vector3(8.0, 4.4, 8.2))
	lm.box("Hull", Vector3(44.0, 3.6, 0.0), Vector3(5.0, 4.6, 4.2))
	lm.box("Hull", Vector3(-39.0, 3.1, 0.0), Vector3(7.0, 4.2, 9.2))
	# Timber deck, forecastle (+X), poop deck (-X) and midship deckhouses.
	lm.box("Deck", Vector3(0.0, 4.95, 0.0), Vector3(72.0, 0.2, 11.2))
	lm.box("Hull", Vector3(33.0, 5.7, 0.0), Vector3(14.0, 1.4, 10.6))
	lm.box("Hull", Vector3(-31.0, 5.8, 0.0), Vector3(16.0, 1.6, 11.0))
	lm.box("Hull", Vector3(-3.0, 6.2, 0.0), Vector3(14.0, 2.4, 7.0))
	lm.box("Dark", Vector3(-3.0, 6.4, 3.55), Vector3(11.0, 0.9, 0.1))
	lm.box("Dark", Vector3(-3.0, 6.4, -3.55), Vector3(11.0, 0.9, 0.1))
	# Long raked bowsprit extending forward (+X).
	lm.box("Mast", Vector3(51.5, 6.4, 0.0), Vector3(14.0, 0.45, 0.45), Basis(Vector3.FORWARD, -0.22))
	# Three tall masts (fore +21, main 0, mizzen -21) up to 44 m with 5 yards each.
	for m_info in [[21.0, 41.0], [0.0, 44.0], [-21.0, 39.0]]:
		var mx: float = m_info[0]
		var mh: float = m_info[1]
		lm.frustum("Mast", Vector3(mx, 4.9, 0.0), 0.42, 0.16, mh - 4.9, 10)
		# Five horizontal square-rig yards per mast, tapering upward.
		var widths := [19.0, 17.0, 14.5, 11.5, 8.5]
		for k in 5:
			var yy := 14.0 + float(k) * (mh - 19.0) / 4.0
			var yw: float = widths[k]
			lm.box("Yard", Vector3(mx + 0.35, yy, 0.0), Vector3(0.28, 0.28, yw))
	lm.commit(model)

## Föri (1904): Turku's beloved orange-and-white double-ended cable ferry
## crossing Aurajoki (~18 m long, 6.5 m wide, open deck with orange hull
## and white railings/canopy). Built along +X, y = 0 at water level.
static func fori_ferry(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Orange", LandmarkMaterials.paint("#E46818", 0.45, 0.1))
	lm.use("White", LandmarkMaterials.paint("#F2F0EA", 0.5, 0.05))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#6E7275", 2.0))
	lm.use("Dark", LandmarkMaterials.paint("#2A2E32", 0.5, 0.4))
	# Double-ended orange hull (18 x 6.5 m) and deck.
	lm.box("Orange", Vector3(0.0, 0.55, 0.0), Vector3(17.5, 1.3, 6.4))
	lm.box("Deck", Vector3(0.0, 1.25, 0.0), Vector3(17.2, 0.15, 6.0))
	# White side bulwarks & handrails.
	for sz: float in [-1.0, 1.0]:
		lm.box("White", Vector3(0.0, 1.85, sz * 3.05), Vector3(16.0, 1.1, 0.18))
	# Central wheelhouse / control cabin on one side + small canopy.
	lm.box("White", Vector3(0.0, 2.8, -2.2), Vector3(4.2, 2.6, 1.5))
	lm.box("Dark", Vector3(0.0, 3.1, -1.42), Vector3(3.6, 1.1, 0.1))
	lm.box("Orange", Vector3(0.0, 4.2, -2.2), Vector3(4.5, 0.25, 1.8))
	lm.commit(model)
