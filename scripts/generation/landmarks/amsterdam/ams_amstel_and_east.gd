class_name AmsAmstelAndEast
extends RefCounted

## Amstel River & Jewish Cultural Quarter / East Heritage landmarks (`AMS-3.3`):
##   - Stopera / National Opera & Ballet (28.0 m)
##   - H'ART Museum / Amstelhof (20.0 m)
##   - Koninklijk Theater Carré (26.0 m)
##   - InterContinental Amstel Hotel (28.0 m)
##   - Portuguese Synagogue (24.0 m)
##   - Wereldmuseum / Tropenmuseum (48.0 m)
##   - Molen De Gooyer (26.6 m — octagonal wooden stellingmolen windmill!)

const K = preload("res://scripts/generation/landmarks/amsterdam/landmark_ams_kit.gd")

## Stopera (Stadhuis & Nationale Opera en Ballet, 1986, 28 m): curved white
## marble & glass opera drum fronting the Amstel + brick civic city-hall wing.
static func stopera_amsterdam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8D4634", "#E9E5DC", "#4B525A")
	# Curved white marble riverside opera drum (+Z / Amstel side)
	lm.frustum("White", Vector3(-16.0, 0.0, 16.0), 34.0, 34.0, 19.5, 24)
	lm.frustum("Glass", Vector3(-16.0, 3.0, 16.0), 34.4, 34.4, 11.5, 24)
	lm.box("Stone", Vector3(-16.0, 23.8, 12.0), Vector3(32.0, 8.4, 28.0))
	# Stepped brick-and-stone City Hall wing behind (-Z / Waterlooplein)
	lm.box("Brick", Vector3(24.0, 10.5, -14.0), Vector3(58.0, 21.0, 74.0))
	K.stone_band(lm, "White", 24.0, -14.0, 58.6, 74.6, 10.5, 0.7, 0.3)
	K.stone_band(lm, "White", 24.0, -14.0, 58.6, 74.6, 20.6, 0.9, 0.4)
	lm.box("Lamp", Vector3(-16.0, 15.0, 50.2), Vector3(26.0, 0.4, 0.35))
	lm.commit(model)

## H'ART Museum / Amstelhof (1681, 20 m): symmetrical classical Dutch brick
## quadrangle facing the Amstel with crisp white sashes & central pediment.
static func hart_amstelhof(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#843A2C", "#EAE4D6", "#7A3A2A")
	lm.box("Brick", Vector3(0.0, 7.2, 24.0), Vector3(96.0, 14.4, 16.0))
	lm.box("Brick", Vector3(0.0, 7.2, -24.0), Vector3(96.0, 14.4, 16.0))
	lm.box("Brick", Vector3(-40.0, 7.2, 0.0), Vector3(16.0, 14.4, 36.0))
	lm.box("Brick", Vector3(40.0, 7.2, 0.0), Vector3(16.0, 14.4, 36.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 14.4, 24.0), 96.4, 16.4, 5.4, true)
	K.pitched_roof(lm, "Roof", Vector3(0.0, 14.4, -24.0), 96.4, 16.4, 5.4, true)
	K.pitched_roof(lm, "Roof", Vector3(-40.0, 14.4, 0.0), 16.4, 36.4, 5.2, false)
	K.pitched_roof(lm, "Roof", Vector3(40.0, 14.4, 0.0), 16.4, 36.4, 5.2, false)
	K.pediment(lm, "White", "Brick", Vector3(0.0, 14.4, 32.1), Vector3.BACK, 16.0, 4.4, 1.0)
	for y0 in [2.5, 8.2]:
		K.window_row(lm, "White", Vector3(-44.0, 0.0, 32.08), Vector3(44.0, 0.0, 32.08), Vector3.BACK, y0, 21, 1.8, 3.0)
	lm.commit(model)

## Koninklijk Theater Carré (1887, 26 m): neoclassical Amstel circus-theatre.
static func theater_carre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8D4231", "#E2D8C2", "#3A424A")
	lm.box("Stone", Vector3(0.0, 9.5, 0.0), Vector3(52.0, 19.0, 56.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 19.0, 0.0), 52.4, 56.4, 4.5, false)
	K.pediment(lm, "Stone", "White", Vector3(0.0, 19.0, 28.2), Vector3.BACK, 24.0, 4.8, 1.4)
	# Iconic copper theatre drum dome (26 m)
	lm.lathe("Copper", Vector3(0.0, 21.0, 0.0), PackedVector2Array([
		Vector2(14.0, 0.0), Vector2(12.2, 2.5), Vector2(6.5, 4.4), Vector2(0.4, 5.0),
	]), 18)
	lm.box("Lamp", Vector3(0.0, 18.2, 28.4), Vector3(22.0, 0.35, 0.3))
	lm.commit(model)

## InterContinental Amstel Hotel (1867, 28 m): Second-Empire sandstone palace.
static func amstel_hotel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8A4634", "#E2D6BE", "#383F47")
	lm.box("Stone", Vector3(0.0, 10.5, 0.0), Vector3(68.0, 21.0, 36.0))
	lm.box("Roof", Vector3(0.0, 23.2, 0.0), Vector3(64.0, 4.4, 32.0))
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 29.0, 11.2, 0.0), Vector3(12.0, 22.4, 38.0))
		lm.frustum("Roof", Vector3(sx * 29.0, 22.4, 0.0), 8.2, 2.8, 5.6, 4)
	for y0 in [3.0, 8.5, 14.0]:
		K.window_row(lm, "Glass", Vector3(-30.0, 0.0, 18.08), Vector3(30.0, 0.0, 18.08), Vector3.BACK, y0, 15, 2.0, 3.2)
	lm.box("Lamp", Vector3(0.0, 20.6, 18.3), Vector3(44.0, 0.35, 0.3))
	lm.commit(model)

## Portuguese Synagogue / Esnoga (1675, 24 m): austere monumental brick cube.
static func portugese_synagoge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#DDD2BA", "#3B4249")
	lm.box("Brick", Vector3(0.0, 10.5, 0.0), Vector3(32.0, 21.0, 38.0))
	K.stone_band(lm, "Stone", 0.0, 0.0, 32.6, 38.6, 20.8, 0.9, 0.45)
	lm.box("Roof", Vector3(0.0, 22.6, 0.0), Vector3(30.0, 2.8, 36.0))
	for sx in [-1.0, 1.0]:
		K.window_row(lm, "Glass", Vector3(sx * 16.08, 0.0, -14.0), Vector3(sx * 16.08, 0.0, 14.0),
			Vector3(sx, 0.0, 0.0), 4.5, 5, 2.6, 12.0)
	lm.commit(model)

## Wereldmuseum / Tropenmuseum (1926, 48 m): grand neo-Renaissance red-brick
## palace with dominant 48 m octagonal corner tower & copper lantern.
static func tropenmuseum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8A3C2C", "#DCD0B8", "#3B4249")
	lm.box("Brick", Vector3(0.0, 11.5, 0.0), Vector3(96.0, 23.0, 64.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 23.0, 0.0), 96.4, 64.4, 6.2, true)
	K.stone_band(lm, "Stone", 0.0, 0.0, 96.4, 64.4, 11.5, 0.65, 0.28)
	var t := Vector3(-42.0, 0.0, 26.0)
	lm.frustum("Brick", t, 7.6, 7.2, 31.0, 8)
	lm.frustum("Stone", t + Vector3.UP * 31.0, 8.0, 7.8, 0.9, 8)
	lm.frustum("Lamp", t + Vector3.UP * 31.9, 5.2, 4.8, 3.6, 8)
	lm.frustum("Copper", t + Vector3.UP * 35.5, 7.2, 0.15, 12.5, 8)
	lm.commit(model)

## Molen De Gooyer (1814, 26.6 m on Funenkade): Amsterdam's iconic octagonal
## wooden & thatched stellingmolen windmill with elevated gallery & 4 sails.
static func molen_de_gooyer(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#C4B494", "#3E362E")
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#3A3128", 2.0))
	lm.use("Thatch", LandmarkMaterials.pbr("render", "#5E5242", 2.5, 0.92, 0.02))
	lm.use("Sail", LandmarkMaterials.pbr("wood", "#D6CEBE", 2.0))
	# Octagonal brick lower base (0..8 m)
	lm.frustum("Brick", Vector3.ZERO, 6.4, 5.6, 8.0, 8)
	# Elevated wooden miller's gallery (stelling) at 8 m with struts & railing
	lm.frustum("Timber", Vector3(0.0, 7.8, 0.0), 8.8, 8.8, 0.5, 12)
	for k in 8:
		var ang := float(k) * TAU / 8.0
		lm.beam("Timber", Vector3(cos(ang) * 5.6, 4.8, sin(ang) * 5.6),
			Vector3(cos(ang) * 8.4, 7.8, sin(ang) * 8.4), 0.25, 0.25)
	# Tapered octagonal thatched smock body (8..21.5 m)
	lm.frustum("Thatch", Vector3(0.0, 8.0, 0.0), 5.5, 3.4, 13.5, 8)
	# Rotating thatched cap (21.5..26.6 m) + tailpole (-Z)
	lm.lathe("Thatch", Vector3(0.0, 21.5, 0.0), PackedVector2Array([
		Vector2(3.6, 0.0), Vector2(3.7, 1.8), Vector2(2.6, 3.8), Vector2(0.2, 5.1),
	]), 12)
	lm.beam("Timber", Vector3(0.0, 23.0, -3.2), Vector3(0.0, 8.5, -8.5), 0.3, 0.3)
	# Four 13.5 m latticed Dutch windmill sails facing +Z
	var hub := Vector3(0.0, 22.8, 3.9)
	lm.frustum("Timber", hub - Vector3(0.0, 0.0, 0.8), 0.55, 0.45, 1.4, 8)
	for k in 4:
		var a := deg_to_rad(32.0 + 90.0 * float(k))
		var dir := Vector3(cos(a), sin(a), 0.0)
		var perp := Vector3(-sin(a), cos(a), 0.0)
		lm.beam("Timber", hub, hub + dir * 13.0, 0.24, 0.24)
		# Sail lattice board
		var s_mid := hub + dir * 7.6 + perp * 0.72
		lm.box("Sail", s_mid, Vector3(10.2, 1.25, 0.14), Basis(Vector3.BACK, a))
	lm.commit(model)
