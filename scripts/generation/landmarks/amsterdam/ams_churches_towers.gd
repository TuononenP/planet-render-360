class_name AmsChurchesTowers
extends RefCounted

## Historic Amsterdam canal-ring churches & clock towers:
##   - Westerkerk & 86 m Westertoren (Imperial Crown of Maximilian I)
##   - Oude Kerk (67 m Baroque spire)
##   - Zuiderkerk (61.2 m Groenburgwal vista spire)
##   - Munttoren (40 m)
##   - De Waag (28 m Nieuwmarkt medieval gatehouse)
##   - Koepelkerk / Ronde Lutherse Kerk (36 m green copper dome)
##   - Noorderkerk (34 m)
##   - De Krijtberg (53 m twin neo-Gothic spires)

const K = preload("res://scripts/generation/landmarks/amsterdam/landmark_ams_kit.gd")

## Hendrick de Keyser's Westerkerk (1631) & 86 m Westertoren on Prinsengracht:
## double-transept Dutch Renaissance brick-and-sandstone hall church and the
## tallest church spire in Amsterdam, crowned by the royal-blue & gilded
## Imperial Crown of Maximilian I.
static func westerkerk(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#843A2C", "#DDD2BA", "#3B4249")
	lm.use("Blue", LandmarkMaterials.paint("#1E4F9A", 0.35, 0.15))
	# Main nave (54 x 26 m) + two projecting transept pairs
	lm.box("Brick", Vector3(6.0, 10.5, 0.0), Vector3(48.0, 21.0, 22.0))
	lm.box("Brick", Vector3(-6.0, 10.5, 0.0), Vector3(14.0, 21.0, 32.0))
	lm.box("Brick", Vector3(18.0, 10.5, 0.0), Vector3(14.0, 21.0, 32.0))
	K.pitched_roof(lm, "Roof", Vector3(6.0, 21.0, 0.0), 48.5, 22.5, 11.0, true)
	K.pitched_roof(lm, "Roof", Vector3(-6.0, 21.0, 0.0), 14.5, 32.5, 9.5, false)
	K.pitched_roof(lm, "Roof", Vector3(18.0, 21.0, 0.0), 14.5, 32.5, 9.5, false)
	for tx in [-6.0, 18.0]:
		for sz in [-1.0, 1.0]:
			K.step_gable(lm, "Brick", "Stone", Vector3(tx, 21.0, sz * 16.0), Vector3(0.0, 0.0, sz), 14.0, 9.5, 5, 0.9)
			K.window_row(lm, "Glass", Vector3(tx - 4.5, 0.0, sz * 16.08), Vector3(tx + 4.5, 0.0, sz * 16.08),
				Vector3(0.0, 0.0, sz), 5.0, 3, 2.0, 12.5)
	K.step_gable(lm, "Brick", "Stone", Vector3(30.0, 21.0, 0.0), Vector3.RIGHT, 22.0, 11.0, 6, 1.0)
	K.stone_band(lm, "Stone", 6.0, 0.0, 48.4, 22.4, 20.6, 0.7, 0.35)
	# Iconic 86 m Westertoren at the west end (-X, facing Prinsengracht)
	var t := Vector3(-23.0, 0.0, 0.0)
	# Heavy square brick shaft to 36 m
	lm.box("Brick", t + Vector3.UP * 18.0, Vector3(11.4, 36.0, 11.4))
	for y in [12.0, 24.0, 35.6]:
		K.stone_band(lm, "Stone", t.x, t.z, 11.6, 11.6, y, 0.8, 0.4)
	# Four black-and-gold clock dials at 30 m
	for n in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		K.clock_dial(lm, "Dial", "Gold", t + Vector3.UP * 30.0 + n * 5.8, n, 2.1)
	# Three stepped white Bentheimer sandstone & open carillon lantern stages (36 -> 86 m)
	lm.box("Stone", t + Vector3.UP * 42.5, Vector3(9.4, 13.0, 9.4))
	K.stone_band(lm, "Stone", t.x, t.z, 10.2, 10.2, 49.0, 0.9, 0.45)
	K.dutch_spire(lm, "Stone", "Roof", "White", "Lamp", t + Vector3.UP * 49.5, 4.4, 36.5, true)
	lm.commit(model)

## Oude Kerk (1306 — Amsterdam's oldest building, De Wallen): broad Gothic
## red-brick hall church with 67 m multi-tiered open-lantern Baroque spire.
static func oude_kerk_amsterdam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7A3629", "#CFC4AC", "#383F47")
	lm.box("Brick", Vector3(6.0, 9.5, 0.0), Vector3(58.0, 19.0, 42.0))
	lm.box("Brick", Vector3(8.0, 12.5, 0.0), Vector3(52.0, 25.0, 18.0))
	K.pitched_roof(lm, "Roof", Vector3(8.0, 25.0, 0.0), 52.5, 18.5, 9.0, true)
	K.pitched_roof(lm, "Roof", Vector3(6.0, 19.0, -15.0), 58.0, 12.5, 5.5, true)
	K.pitched_roof(lm, "Roof", Vector3(6.0, 19.0, 15.0), 58.0, 12.5, 5.5, true)
	for sz in [-1.0, 1.0]:
		K.window_row(lm, "Glass", Vector3(-18.0, 0.0, sz * 21.08), Vector3(28.0, 0.0, sz * 21.08),
			Vector3(0.0, 0.0, sz), 5.0, 8, 2.8, 10.5)
	# 67 m west tower (brick shaft to 34 m + Hendrick de Keyser Baroque spire)
	var t := Vector3(-26.0, 0.0, 0.0)
	lm.box("Brick", t + Vector3.UP * 17.0, Vector3(10.8, 34.0, 10.8))
	K.stone_band(lm, "Stone", t.x, t.z, 11.4, 11.4, 33.8, 0.85, 0.4)
	for n in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		K.clock_dial(lm, "Dial", "Gold", t + Vector3.UP * 28.5 + n * 5.5, n, 1.8)
	K.dutch_spire(lm, "White", "Roof", "Stone", "Lamp", t + Vector3.UP * 34.2, 4.4, 32.8, false)
	lm.commit(model)

## Zuiderkerk (1611, 61.2 m): brick Renaissance hall church & iconic white
## sandstone square-to-octagonal tower framing the Groenburgwal canal vista.
static func zuiderkerk(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#843A2C", "#E0D7C2", "#3A4148")
	lm.box("Brick", Vector3(4.0, 9.0, 0.0), Vector3(36.0, 18.0, 26.0))
	K.pitched_roof(lm, "Roof", Vector3(4.0, 18.0, 0.0), 36.4, 26.4, 8.8, true)
	for sz in [-1.0, 1.0]:
		K.window_row(lm, "Glass", Vector3(-10.0, 0.0, sz * 13.08), Vector3(18.0, 0.0, sz * 13.08),
			Vector3(0.0, 0.0, sz), 4.2, 5, 2.4, 10.5)
	var t := Vector3(-16.0, 0.0, 0.0)
	lm.box("Brick", t + Vector3.UP * 13.0, Vector3(9.0, 26.0, 9.0))
	K.stone_band(lm, "Stone", t.x, t.z, 9.6, 9.6, 26.0, 0.8, 0.4)
	lm.box("Stone", t + Vector3.UP * 31.5, Vector3(7.6, 10.5, 7.6))
	for n in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		K.clock_dial(lm, "Dial", "Gold", t + Vector3.UP * 32.0 + n * 3.9, n, 1.5)
	K.dutch_spire(lm, "Stone", "Roof", "White", "Lamp", t + Vector3.UP * 36.8, 3.6, 24.4, false)
	lm.commit(model)

## Munttoren (1620, 40 m at Muntplein): medieval polygonal brick base,
## stepped-gable guardhouse, and Hendrick de Keyser's open octagonal lantern.
static func munttoren(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#82382B", "#DED4BE", "#3A424A")
	# Adjacent 19th-century Dutch neo-Renaissance guardhouse
	lm.box("Brick", Vector3(5.2, 5.2, 0.0), Vector3(8.0, 10.4, 9.2))
	K.pitched_roof(lm, "Roof", Vector3(5.2, 10.4, 0.0), 8.2, 9.4, 4.2, true)
	K.step_gable(lm, "Brick", "Stone", Vector3(9.2, 10.4, 0.0), Vector3.RIGHT, 9.2, 4.2, 4, 0.7)
	# Polygonal brick tower base to 17 m
	lm.frustum("Brick", Vector3(-1.8, 0.0, 0.0), 4.4, 4.2, 17.0, 8)
	lm.frustum("Stone", Vector3(-1.8, 17.0, 0.0), 4.8, 4.6, 0.7, 8)
	for n in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		K.clock_dial(lm, "Dial", "Gold", Vector3(-1.8, 14.2, 0.0) + n * 4.1, n, 1.25)
	K.dutch_spire(lm, "White", "Roof", "Stone", "Lamp", Vector3(-1.8, 17.7, 0.0), 3.6, 22.3, false)
	lm.commit(model)

## De Waag on Nieuwmarkt (1488 Sint Antoniespoort): medieval red-brick city
## gatehouse with five cylindrical turrets capped by steep dark-slate cones.
static func waag_amsterdam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D362A", "#D6CAB2", "#343B43")
	lm.box("Brick", Vector3(0.0, 6.5, 0.0), Vector3(20.0, 13.0, 22.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 13.0, 0.0), 20.2, 22.2, 5.5, false)
	# Four corner round defensive turrets
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tp := Vector3(sx * 9.8, 0.0, sz * 10.6)
			lm.frustum("Brick", tp, 3.8, 3.6, 15.2, 12)
			lm.frustum("Stone", tp + Vector3.UP * 15.2, 4.0, 3.9, 0.5, 12)
			lm.frustum("Roof", tp + Vector3.UP * 15.7, 3.9, 0.12, 7.6, 12)
	# Taller central octagonal Theatrum Anatomicum cupola turret (28 m)
	lm.frustum("Brick", Vector3(0.0, 16.5, 0.0), 4.2, 4.0, 4.5, 8)
	lm.frustum("Lamp", Vector3(0.0, 17.5, 0.0), 4.1, 4.0, 1.8, 8)
	lm.frustum("Roof", Vector3(0.0, 21.0, 0.0), 4.3, 0.12, 7.0, 8)
	lm.commit(model)

## Koepelkerk / Ronde Lutherse Kerk (1671 on Singel): circular brick drum
## crowned by its monumental ribbed green-copper rotunda dome & lantern (36 m).
static func koepelkerk_amsterdam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7D3729", "#D6CAB2", "#3B4249")
	lm.frustum("Brick", Vector3.ZERO, 18.5, 18.2, 16.5, 24)
	lm.frustum("Stone", Vector3(0.0, 16.5, 0.0), 19.2, 19.0, 0.9, 24)
	# Arched windows around circular drum
	for k in 12:
		var ang := float(k) * TAU / 12.0
		var n := Vector3(cos(ang), 0.0, sin(ang))
		lm.box("Glass", n * 18.4 + Vector3.UP * 10.0, Vector3(2.2, 6.2, 0.3),
			Basis(Vector3.UP, atan2(n.x, n.z)))
	# Monumental green patinated copper dome + lantern (17.4 -> 36 m)
	lm.lathe("Copper", Vector3(0.0, 17.4, 0.0), PackedVector2Array([
		Vector2(18.2, 0.0), Vector2(17.4, 3.5), Vector2(14.5, 7.4),
		Vector2(9.2, 10.8), Vector2(3.6, 12.6), Vector2(2.6, 13.0),
	]), 24)
	lm.frustum("Lamp", Vector3(0.0, 30.4, 0.0), 2.2, 2.0, 2.6, 12)
	lm.frustum("Copper", Vector3(0.0, 33.0, 0.0), 2.5, 0.1, 3.0, 12)
	lm.commit(model)

## Noorderkerk (1623, Noordermarkt): Greek-cross brick church with four equal
## gables, dark slate roofs, and central bell lantern (34 m).
static func noorderkerk(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7B362A", "#D6CBB4", "#383F47")
	lm.box("Brick", Vector3(0.0, 8.0, 0.0), Vector3(38.0, 16.0, 16.0))
	lm.box("Brick", Vector3(0.0, 8.0, 0.0), Vector3(16.0, 16.0, 38.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 16.0, 0.0), 38.4, 16.4, 7.5, true)
	K.pitched_roof(lm, "Roof", Vector3(0.0, 16.0, 0.0), 16.4, 38.4, 7.5, false)
	for d in [[Vector3(19.0, 16.0, 0.0), Vector3.RIGHT], [Vector3(-19.0, 16.0, 0.0), Vector3.LEFT],
			[Vector3(0.0, 16.0, 19.0), Vector3.BACK], [Vector3(0.0, 16.0, -19.0), Vector3.FORWARD]]:
		K.step_gable(lm, "Brick", "Stone", d[0], d[1], 16.0, 7.5, 4, 0.8)
	K.dutch_spire(lm, "White", "Roof", "Stone", "Lamp", Vector3(0.0, 22.8, 0.0), 2.2, 11.2, false)
	lm.commit(model)

## De Krijtberg (1883 on Singel): slender neo-Gothic red-brick canal church
## with twin pointed slate spires soaring to 53 m.
static func de_krijtberg(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#843628", "#D9CEB8", "#353C44")
	lm.box("Brick", Vector3(0.0, 10.5, -6.0), Vector3(16.0, 21.0, 34.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 21.0, -6.0), 16.4, 34.4, 8.5, false)
	K.step_gable(lm, "Brick", "Stone", Vector3(0.0, 21.0, 11.0), Vector3.BACK, 16.0, 8.5, 5, 0.9)
	# Twin slender neo-Gothic front spires flanking the canal front (+Z)
	for sx in [-1.0, 1.0]:
		var tp := Vector3(sx * 6.4, 0.0, 10.2)
		lm.box("Brick", tp + Vector3.UP * 15.5, Vector3(4.6, 31.0, 4.6))
		lm.box("Stone", tp + Vector3.UP * 31.2, Vector3(5.0, 0.6, 5.0))
		lm.frustum("Lamp", tp + Vector3.UP * 31.5, 1.7, 1.6, 2.2, 8)
		lm.frustum("Roof", tp + Vector3.UP * 33.7, 2.3, 0.08, 19.3, 8)
	lm.commit(model)
