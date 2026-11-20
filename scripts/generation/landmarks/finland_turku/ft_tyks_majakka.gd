class_name FtTyksMajakka
extends RefCounted

## TYKS Majakkasairaala (Lighthouse Hospital, 2022, Schauman Arkkitehdit)
## — landmark university hospital spanning directly over Highway 1
## (Helsinginkatu) and the Helsinki–Turku railway at Savitehtaankatu,
## in true metres (+X ENE along deck span, +Z SSE along motorway/rail
## corridor, turned by registry yaw_deg = -34.0°; `skyline: true`):
##   - Structural concrete bridge deck: 112 x 82 m spanning the sunken
##     Helsinginkatu motorway & railway corridor (clear soffit y = 6.2 m,
##     deck slab y = 6.2..8.6 m, supported by 4 rows of flared reinforced
##     concrete bridge piers and east/west retaining abutments down to
##     FOUND = -3.6 m).
##   - Main hospital superstructure (y = 8.6..41.0 m, 8 clinical storeys,
##     turku_lod2 1036173151 area 10,037 m², H = 46.4 m): twin sculpted
##     white/light-metal courtyard wings flanking a glazed central atrium,
##     continuous horizontal ribbon-window bands (SkyKit), and signature
##     warm amber/coral/teal coloured glass accent fins.
##   - Glowing vertical "Lighthouse" (Majakka) corner beacon prow on the SW
##     Savitehtaankatu elevation (y = 8.6..44.4 m) with illuminated vertical
##     glass ribs and crown beacon.
##   - Rooftop H-marked octagonal helipad (dia 18 m, deck y = 43.4 m) on
##     steel trusses with white/yellow aiming ring, crisp "H" marking,
##     safety netting frame, green perimeter lights, and red aviation beacon
##     reaching 46.4 m.
##   - Elevated glazed pedestrian skybridge (yhdyskäytävä) extending -X
##     across Savitehtaankatu (x = -54..-82 m, y = 13.8..17.6 m) on steel
##     V-piers toward TYKS T-sairaala.
## Surfaces: 14 merged PBR parts (Concrete, WhiteMetal, DarkMetal, Glass,
## WallLit, AccentAmber, AccentTeal, HelipadDeck, HeliMark, Lamp, BeaconRed,
## BeaconGreen).

const FOUND := -3.6
const DECK_BOT := 6.2
const DECK_TOP := 8.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var sky := SkyKit.new(lm)
	_materials(lm, sky)
	_build_bridge_deck(lm)
	_build_hospital_wings(lm, sky)
	_build_lighthouse_beacon(lm)
	_build_helipad(lm)
	_build_skybridge(lm)
	lm.commit(model)
	_set_night_lights(model)

static func _materials(lm: LandmarkMesh, sky: SkyKit) -> void:
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B4B2AC", 3.2))
	lm.use("WhiteMetal", LandmarkMaterials.pbr("sheet_metal", "#ECEEEB", 2.8, 0.38, 0.25))
	lm.use("DarkMetal", LandmarkMaterials.paint("#2F353C", 0.42, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#263A48"))
	sky.wall("WallLit", "white_panel", 3.6, 3.9)
	lm.use("AccentAmber", LandmarkMaterials.paint("#D9822B", 0.26, 0.15))
	lm.use("AccentTeal", LandmarkMaterials.paint("#2F888E", 0.28, 0.15))
	lm.use("HelipadDeck", LandmarkMaterials.pbr("asphalt", "#343940", 3.0))
	lm.use("HeliMark", LandmarkMaterials.paint("#F0C838", 0.55, 0.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF0CE", 1.7))
	lm.use("BeaconRed", LandmarkMaterials.lit("#FF2418", 2.6))
	lm.use("BeaconGreen", LandmarkMaterials.lit("#38E874", 2.0))

static func _build_bridge_deck(lm: LandmarkMesh) -> void:
	# Massive concrete bridge-deck spanning over Highway 1 & Helsinki-Turku rail.
	LandmarkFrKit.rect(lm, "Concrete", -56.0, 56.0, -41.0, 41.0, DECK_BOT, DECK_TOP)
	# Edge fascia beams & safety parapet along motorway/rail overpasses.
	for sz: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "WhiteMetal", -56.4, 56.4, sz * 40.6 - 0.5, sz * 40.6 + 0.5,
			DECK_BOT - 0.3, DECK_TOP + 1.1)
	# Heavy concrete end abutments on east (+X) and west (-X) banks.
	LandmarkFrKit.rect(lm, "Concrete", -56.0, -47.0, -41.0, 41.0, FOUND, DECK_BOT)
	LandmarkFrKit.rect(lm, "Concrete", 47.0, 56.0, -41.0, 41.0, FOUND, DECK_BOT)
	# Three central pier lines separating Highway 1 eastbound, westbound & dual rail tracks.
	for px: float in [-23.0, 0.0, 23.0]:
		for i in 5:
			var pz := lerpf(-32.0, 32.0, float(i) / 4.0)
			LandmarkFrKit.rect(lm, "Concrete", px - 1.35, px + 1.35, pz - 2.6, pz + 2.6, FOUND, DECK_BOT - 0.8)
			# Flared concrete pier hammerhead cap.
			LandmarkFrKit.rect(lm, "Concrete", px - 2.2, px + 2.2, pz - 3.6, pz + 3.6, DECK_BOT - 0.8, DECK_BOT)
		# Continuous concrete crash barrier wall along each pier line.
		LandmarkFrKit.rect(lm, "Concrete", px - 0.55, px + 0.55, -38.0, 38.0, FOUND, 1.35)
	# Under-deck motorway/railway soffit downlight strips.
	for lx: float in [-35.0, -11.5, 11.5, 35.0]:
		for lz: float in [-22.0, 0.0, 22.0]:
			lm.box("Lamp", Vector3(lx, DECK_BOT - 0.08, lz), Vector3(0.45, 0.10, 2.8))

static func _build_hospital_wings(lm: LandmarkMesh, sky: SkyKit) -> void:
	# 2-storey clinical podium over bridge deck (y = 8.6..16.8 m).
	_clad_block(lm, sky, -51.0, 51.0, -36.0, 36.0, DECK_TOP, 16.8, 28, 20)
	# Sculpted white/light-metal upper clinical wings (levels 3..8, y = 16.8..41.0 m)
	# arranged around two landscaped daylight courtyards.
	var wings := [
		[-50.0, -18.0, -34.0, 34.0, 41.0], # West clinical wing (Savitehtaankatu)
		[18.0, 50.0, -34.0, 34.0, 40.2],   # East clinical wing
		[-20.0, 20.0, -34.0, -14.0, 38.6], # North spine wing
		[-20.0, 20.0, 14.0, 34.0, 39.2],   # South spine wing
		[-18.0, 18.0, -6.5, 6.5, 35.0],    # Central glazed clinical bridge
	]
	for w: Array in wings:
		var x0: float = w[0]
		var x1: float = w[1]
		var z0: float = w[2]
		var z1: float = w[3]
		var top: float = w[4]
		_clad_block(lm, sky, x0, x1, z0, z1, 16.8, top,
			maxi(4, int((x1 - x0) / 3.8)), maxi(4, int((z1 - z0) / 3.8)))
		# Crisp white-metal parapet coping band at roof edge.
		LandmarkFrParts.band(lm, "WhiteMetal", x0, x1, z0, z1, top - 0.85, 0.95, 0.28)
		# Horizontal white-metal floor spandrel fins.
		var fy := 20.6
		while fy < top - 1.5:
			LandmarkFrParts.band(lm, "WhiteMetal", x0, x1, z0, z1, fy, 0.42, 0.22)
			fy += 3.9
	# Signature coloured glass/metal vertical accent fins on west (-X) & south (+Z) facades.
	for i in 12:
		var fz := lerpf(-30.0, 30.0, float(i) / 11.0)
		var key := "AccentAmber" if i % 3 == 0 else ("AccentTeal" if i % 3 == 1 else "WhiteMetal")
		lm.box(key, Vector3(-50.35, 28.8, fz), Vector3(0.55, 22.8, 0.42))
		lm.box(key, Vector3(50.35, 28.4, fz), Vector3(0.55, 22.0, 0.42))
	for i in 10:
		var fx := lerpf(-44.0, 44.0, float(i) / 9.0)
		var key := "AccentTeal" if i % 2 == 0 else "AccentAmber"
		lm.box(key, Vector3(fx, 28.0, 34.35), Vector3(0.45, 21.0, 0.55))
		lm.box(key, Vector3(fx, 27.6, -34.35), Vector3(0.45, 20.2, 0.55))
	# Rooftop mechanical penthouses & louvered HVAC enclosures.
	LandmarkFrKit.rect(lm, "WhiteMetal", -44.0, -24.0, -26.0, -6.0, 41.0, 44.2)
	LandmarkFrKit.rect(lm, "DarkMetal", -43.5, -24.5, -25.5, -6.5, 44.0, 44.5)
	LandmarkFrKit.rect(lm, "WhiteMetal", 24.0, 44.0, -22.0, 14.0, 40.2, 43.2)

static func _clad_block(lm: LandmarkMesh, sky: SkyKit, x0: float, x1: float,
		z0: float, z1: float, y0: float, y1: float, bx: int, bz: int) -> void:
	# Core & roof slab + SkyKit lit glazed walls on all four faces.
	LandmarkFrKit.rect(lm, "WhiteMetal", x0 + 0.15, x1 - 0.15, z0 + 0.15, z1 - 0.15, y1 - 0.6, y1)
	LandmarkFrKit.rect(lm, "DarkMetal", x0 + 0.4, x1 - 0.4, z0 + 0.4, z1 - 0.4, y0, y1 - 0.5)
	sky.face("WallLit", Vector2(x0, z1), Vector2(x1, z1), y0, y1 - 0.4, Vector3.BACK, bx)
	sky.face("WallLit", Vector2(x1, z0), Vector2(x0, z0), y0, y1 - 0.4, Vector3.FORWARD, bx)
	sky.face("WallLit", Vector2(x1, z1), Vector2(x1, z0), y0, y1 - 0.4, Vector3.RIGHT, bz)
	sky.face("WallLit", Vector2(x0, z0), Vector2(x0, z1), y0, y1 - 0.4, Vector3.LEFT, bz)

static func _build_lighthouse_beacon(lm: LandmarkMesh) -> void:
	# Signature SW glowing vertical "Lighthouse" (Majakka) glass atrium & beacon prow.
	var cx := -49.5
	var cz := 32.5
	lm.frustum("Glass", Vector3(cx, DECK_TOP, cz), 6.2, 5.8, 35.4, 12)
	# Sculpted white vertical fins framing the beacon glass cylinder.
	for i in 8:
		var a := PI * 0.35 + PI * 1.15 * float(i) / 7.0
		var fx := cx + cos(a) * 6.05
		var fz := cz + sin(a) * 6.05
		lm.box("WhiteMetal", Vector3(fx, 26.5, fz), Vector3(0.45, 35.6, 0.75), Basis(Vector3.UP, -a))
	# Glowing vertical lighthouse beacon core & crown lantern (y = 8.6..44.8 m).
	lm.frustum("Lamp", Vector3(cx, 12.0, cz), 4.6, 4.4, 31.8, 12)
	lm.frustum("WhiteMetal", Vector3(cx, 43.8, cz), 6.4, 6.2, 0.9, 12)
	lm.frustum("Lamp", Vector3(cx, 44.7, cz), 3.2, 2.8, 1.1, 12)
	lm.frustum("WhiteMetal", Vector3(cx, 45.8, cz), 3.4, 3.0, 0.4, 12)

static func _build_helipad(lm: LandmarkMesh) -> void:
	# Elevated rooftop octagonal helipad on steel trusses over the SW/central-west roof.
	var hx := -34.0
	var hz := 14.0
	var hy := 43.6
	# Structural steel support legs & truss frame (y = 41.0..43.6 m).
	for sx: float in [-5.8, 0.0, 5.8]:
		for sz: float in [-5.8, 0.0, 5.8]:
			if absf(sx) + absf(sz) > 0.1:
				lm.frustum("DarkMetal", Vector3(hx + sx, 41.0, hz + sz), 0.28, 0.28, 2.6, 8)
	lm.frustum("DarkMetal", Vector3(hx, hy - 0.55, hz), 9.2, 9.5, 0.55, 8, PI / 8.0)
	lm.frustum("HelipadDeck", Vector3(hx, hy, hz), 9.4, 9.4, 0.22, 8, PI / 8.0)
	# Yellow/white aiming circle & crisp "H" marking on helipad deck.
	var my := hy + 0.26
	for i in 16:
		var a0 := TAU * float(i) / 16.0
		var a1 := TAU * float(i + 1) / 16.0
		lm.beam("HeliMark", Vector3(hx + cos(a0) * 5.8, my, hz + sin(a0) * 5.8),
			Vector3(hx + cos(a1) * 5.8, my, hz + sin(a1) * 5.8), 0.10, 0.48, Vector3.UP)
	lm.box("HeliMark", Vector3(hx - 2.1, my, hz), Vector3(0.75, 0.10, 5.6))
	lm.box("HeliMark", Vector3(hx + 2.1, my, hz), Vector3(0.75, 0.10, 5.6))
	lm.box("HeliMark", Vector3(hx, my, hz), Vector3(4.2, 0.10, 0.75))
	# Cantilevered safety netting frame & green perimeter approach lights.
	for i in 8:
		var a := PI / 8.0 + TAU * float(i) / 8.0
		var px := hx + cos(a) * 9.8
		var pz := hz + sin(a) * 9.8
		lm.box("DarkMetal", Vector3(px, hy + 0.15, pz), Vector3(1.1, 0.12, 1.1), Basis(Vector3.UP, -a))
		lm.box("BeaconGreen", Vector3(hx + cos(a) * 9.1, hy + 0.36, hz + sin(a) * 9.1),
			Vector3(0.26, 0.24, 0.26))
	# Red aviation obstruction mast reaching 46.4 m (matches LoD2 46.4 m).
	lm.frustum("DarkMetal", Vector3(hx - 8.2, hy + 0.2, hz - 5.2), 0.08, 0.08, 2.4, 6)
	lm.box("BeaconRed", Vector3(hx - 8.2, 46.25, hz - 5.2), Vector3(0.32, 0.32, 0.32))

static func _build_skybridge(lm: LandmarkMesh) -> void:
	# Glazed pedestrian skybridge (yhdyskäytävä) linking across Savitehtaankatu to T-sairaala.
	LandmarkFrKit.rect(lm, "DarkMetal", -82.0, -50.0, 2.0, 7.6, 13.8, 14.35)
	LandmarkFrKit.rect(lm, "WhiteMetal", -82.0, -50.0, 1.9, 7.7, 17.35, 17.95)
	LandmarkFrKit.rect(lm, "Glass", -81.5, -50.0, 2.15, 7.45, 14.35, 17.35)
	# Warm interior lit strip along skybridge floor/ceiling.
	lm.box("Lamp", Vector3(-66.0, 15.8, 4.8), Vector3(30.0, 1.2, 3.6))
	# Rhythmic vertical steel portal frames & twin V-shaped street piers.
	for i in 8:
		var mx := lerpf(-80.0, -52.0, float(i) / 7.0)
		lm.box("DarkMetal", Vector3(mx, 15.85, 2.08), Vector3(0.22, 3.2, 0.22))
		lm.box("DarkMetal", Vector3(mx, 15.85, 7.52), Vector3(0.22, 3.2, 0.22))
	for px: float in [-71.0, -61.0]:
		lm.beam("Concrete", Vector3(px, FOUND, 4.8), Vector3(px - 1.6, 14.0, 2.5), 0.55, 0.55)
		lm.beam("Concrete", Vector3(px, FOUND, 4.8), Vector3(px + 1.6, 14.0, 7.1), 0.55, 0.55)

static func _set_night_lights(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-64.0, 10.0, 44.0), Vector3(-49.5, 32.0, 32.5), 55.0, 1.0, 56.0, Color(1.0, 0.92, 0.78)],
		[Vector3(-62.0, 9.0, 0.0), Vector3(-50.0, 24.0, 0.0), 62.0, 0.75, 48.0, Color(0.92, 0.96, 1.0)],
		[Vector3(0.0, 10.0, 50.0), Vector3(0.0, 26.0, 34.0), 66.0, 0.70, 52.0, Color(0.92, 0.96, 1.0)],
		[Vector3(0.0, 10.0, -50.0), Vector3(0.0, 26.0, -34.0), 66.0, 0.65, 52.0, Color(0.92, 0.96, 1.0)],
	])
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(-49.5, 45.2, 32.5), 5.5, Color(1.0, 0.92, 0.72)],
		[Vector3(-42.2, 46.25, 8.8), 2.4, Color(1.0, 0.12, 0.08)],
		[Vector3(-34.0, 44.0, 23.1), 1.6, Color(0.22, 0.95, 0.45)],
		[Vector3(-24.9, 44.0, 14.0), 1.6, Color(0.22, 0.95, 0.45)],
	])
