class_name FtTyksAUHospitals
extends RefCounted

## TYKS A-sairaala (1938, Jussi Paatela & Uno Ullberg) & U-sairaala (1968,
## Martti Jaatinen) on Kiinamyllynkatu medical hill, in true metres (+X ENE
## along U-sairaala slab axis, +Z SSE toward Hämeentie, turned by registry
## yaw_deg = -19.7°):
##   1. U-sairaala (OSM way:29050045, 191.4 x 47.4 m, turku_lod2 103440010H
##      area 8,646 m², 13 storeys, H = 51.1 m — verified still present in
##      turku_detailed.osmb): monumental 13-storey white/pale-grey precast
##      concrete inpatient slab (148 x 21 m, H = 51.0 m) rising over a 3-storey
##      clinical podium (176 x 45 m, H = 12.2 m), continuous horizontal ribbon
##      windows (SkyKit), twin vertical stair/lift towers, and rooftop plant.
##   2. A-sairaala (1938 protected Functionalist landmark, SEAT_META child at
##      local (-50, 0, +24), OSM way:782380021): gleaming white rendered
##      6-storey slab (92 x 16.5 m, H = 24.2 m) with signature semicircular
##      curved end balconies on both ends, continuous horizontal ribbon windows,
##      projecting central glazed staircase, cantilevered rooftop solarium
##      terrace with pergola, and granite approach steps.
## Surfaces: 11 merged PBR parts (6 U-sairaala + 5 A-sairaala).

const FOUND := -3.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var sky := SkyKit.new(lm)
	_materials(lm, sky)
	_build_u_sairaala(lm, sky)
	lm.commit(model)
	_build_a_sairaala(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh, sky: SkyKit) -> void:
	lm.use("WhiteWall", LandmarkMaterials.pbr("render", "#EFECE4", 3.2))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C8C5BC", 3.2))
	lm.use("DarkMetal", LandmarkMaterials.paint("#2F343A", 0.45, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#22323D"))
	sky.wall("WallLit", "white_panel", 3.4, 3.55)
	lm.use("Lamp", LandmarkMaterials.lit("#FFECC4", 1.5))

static func _build_u_sairaala(lm: LandmarkMesh, sky: SkyKit) -> void:
	# 3-storey clinical podium (176 x 45 m, H = 12.2 m) seated into the hill.
	LandmarkFrKit.rect(lm, "Concrete", -88.0, 88.0, -22.5, 22.5, FOUND, 1.8)
	_sky_box(lm, sky, -86.0, 86.0, -21.5, 21.5, 1.8, 12.2, 46, 12)
	LandmarkFrParts.band(lm, "Concrete", -86.0, 86.0, -21.5, 21.5, 11.6, 0.75, 0.25)
	# Monumental 13-storey precast concrete inpatient slab (148 x 21 m, y = 12.2..47.8 m).
	_sky_box(lm, sky, -74.0, 74.0, -10.5, 10.5, 12.2, 47.8, 42, 6)
	# Crisp horizontal precast concrete spandrel bands per floor.
	for lv in 10:
		var fy := 15.6 + float(lv) * 3.55
		if fy < 47.4:
			LandmarkFrParts.band(lm, "WhiteWall", -74.0, 74.0, -10.5, 10.5, fy, 0.52, 0.20)
	# Three vertical elevator/service core projections on the north (-Z) facade.
	for cx: float in [-46.0, 0.0, 46.0]:
		LandmarkFrKit.rect(lm, "Concrete", cx - 5.2, cx + 5.2, -14.2, -10.2, FOUND, 50.6)
		LandmarkFrKit.rect(lm, "Glass", cx - 2.4, cx + 2.4, -14.35, -13.9, 3.0, 48.0)
	# Rooftop mechanical penthouse & parapet reaching 51.1 m (matches LoD2 51.1 m).
	LandmarkFrKit.rect(lm, "Concrete", -56.0, 56.0, -7.2, 7.2, 47.8, 51.1)
	LandmarkFrKit.rect(lm, "DarkMetal", -55.5, 55.5, -6.8, 6.8, 50.9, 51.2)
	# Sheltered entrance canopy on south (+Z) podium front.
	LandmarkFrKit.rect(lm, "WhiteWall", -14.0, 14.0, 21.5, 27.5, 4.2, 4.75)
	for px: float in [-12.0, -4.0, 4.0, 12.0]:
		lm.frustum("DarkMetal", Vector3(px, 0.0, 26.8), 0.22, 0.22, 4.3, 8)
	lm.box("Lamp", Vector3(0.0, 4.12, 24.5), Vector3(24.0, 0.10, 0.55))

## 1938 A-sairaala (Paatela & Ullberg) — protected white Functionalist landmark
## with curved end balconies, continuous ribbon windows & rooftop solarium.
static func _build_a_sairaala(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	for k: String in ["WhiteWall", "Concrete", "DarkMetal", "Glass", "Lamp"]:
		lm.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	# Granite/concrete plinth & 6-storey gleaming white rendered main slab (92 x 16.5 m).
	LandmarkFrKit.rect(lm, "Concrete", -46.5, 46.5, -8.6, 8.6, FOUND, 1.8)
	LandmarkFrKit.rect(lm, "WhiteWall", -46.0, 46.0, -8.25, 8.25, 1.8, 21.8)
	# Continuous horizontal Functionalist ribbon windows on all 5 upper storeys (+Z & -Z).
	for lv in 5:
		var wy := 2.9 + float(lv) * 3.65
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -43.5, 43.5, sz * 8.20 - 0.14, sz * 8.20 + 0.14, wy, wy + 1.85)
			# Fine white vertical mullions along the ribbon windows.
			for k in 25:
				var mx := lerpf(-43.0, 43.0, float(k) / 24.0)
				lm.box("WhiteWall", Vector3(mx, wy + 0.92, sz * 8.32), Vector3(0.16, 1.9, 0.12))
	# Signature semicircular curved Functionalist end balconies at east (+X) & west (-X) ends!
	for sx: float in [-1.0, 1.0]:
		var ex := sx * 46.0
		for lv in 5:
			var by := 2.4 + float(lv) * 3.65
			# Curved white balcony slab & parapet wrapping each end.
			lm.frustum("WhiteWall", Vector3(ex, by, 0.0), 7.8, 7.8, 1.15, 16)
			lm.frustum("DarkMetal", Vector3(ex, by + 1.15, 0.0), 7.85, 7.85, 0.12, 16)
			# Curved recessed glass behind each balcony deck.
			lm.frustum("Glass", Vector3(ex, by + 1.15, 0.0), 5.8, 5.8, 2.35, 16)
		# Curved balcony end columns.
		lm.frustum("WhiteWall", Vector3(ex + sx * 7.1, 1.8, 0.0), 0.32, 0.32, 19.6, 10)
	# Central projecting glazed stairwell bay on north (-Z) facade.
	LandmarkFrKit.rect(lm, "WhiteWall", -5.2, 5.2, -11.4, -8.2, FOUND, 23.6)
	LandmarkFrKit.rect(lm, "Glass", -3.4, 3.4, -11.55, -11.2, 2.2, 22.4)
	lm.box("Lamp", Vector3(0.0, 12.0, -10.2), Vector3(5.6, 18.0, 1.6))
	# Cantilevered rooftop solarium terrace & white Functionalist pergola (y = 21.8..24.4 m).
	LandmarkFrKit.rect(lm, "WhiteWall", -34.0, 34.0, -5.8, 5.8, 21.8, 22.3)
	LandmarkFrKit.rect(lm, "Glass", -24.0, 24.0, -4.6, 4.6, 22.3, 24.1)
	LandmarkFrKit.rect(lm, "WhiteWall", -34.0, 34.0, -6.2, 6.2, 24.0, 24.45)
	for px: float in [-32.0, -26.0, 26.0, 32.0]:
		for pz: float in [-5.4, 5.4]:
			lm.frustum("WhiteWall", Vector3(px, 21.8, pz), 0.22, 0.22, 2.3, 8)
	# Landscaped granite approach steps & entrance canopy on south (+Z) side.
	LandmarkFrKit.rect(lm, "Concrete", -10.0, 10.0, 8.25, 13.0, FOUND, 1.2)
	LandmarkFrKit.rect(lm, "WhiteWall", -7.5, 7.5, 8.25, 12.2, 4.4, 4.85)
	lm.box("Lamp", Vector3(0.0, 4.32, 10.2), Vector3(12.0, 0.10, 0.45))
	var child := Node3D.new()
	child.name = "ASairaala"
	child.position = Vector3(-52.0, 0.0, 38.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _sky_box(lm: LandmarkMesh, sky: SkyKit, x0: float, x1: float,
		z0: float, z1: float, y0: float, y1: float, bx: int, bz: int) -> void:
	LandmarkFrKit.rect(lm, "Concrete", x0 + 0.15, x1 - 0.15, z0 + 0.15, z1 - 0.15, y1 - 0.5, y1)
	LandmarkFrKit.rect(lm, "DarkMetal", x0 + 0.4, x1 - 0.4, z0 + 0.4, z1 - 0.4, y0, y1 - 0.4)
	sky.face("WallLit", Vector2(x0, z1), Vector2(x1, z1), y0, y1 - 0.35, Vector3.BACK, bx)
	sky.face("WallLit", Vector2(x1, z0), Vector2(x0, z0), y0, y1 - 0.35, Vector3.FORWARD, bx)
	sky.face("WallLit", Vector2(x1, z1), Vector2(x1, z0), y0, y1 - 0.35, Vector3.RIGHT, bz)
	sky.face("WallLit", Vector2(x0, z0), Vector2(x0, z1), y0, y1 - 0.35, Vector3.LEFT, bz)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-52.0, 2.0, 56.0), Vector3(-52.0, 14.0, 40.0), 64.0, 0.90, 48.0, Color(1.0, 0.90, 0.72)],
		[Vector3(0.0, 3.0, 36.0), Vector3(0.0, 28.0, 12.0), 66.0, 0.70, 58.0, Color(0.94, 0.96, 1.0)],
		[Vector3(-42.0, 3.0, 32.0), Vector3(-42.0, 28.0, 12.0), 60.0, 0.65, 52.0, Color(0.94, 0.96, 1.0)],
	])
