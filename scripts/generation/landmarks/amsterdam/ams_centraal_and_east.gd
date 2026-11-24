class_name AmsCentraalAndEast
extends RefCounted

## Amsterdam Centraal (full rebuild) + Damrak & East Waterfront historic icons:
##   - Amsterdam Centraal (45.0 m — Cuypers' full 306 m island terminus, 3 sheds)
##   - Beurs van Berlage (40.0 m — Berlage's rationalist brick exchange)
##   - Sint-Nicolaasbasiliek (58.0 m — neo-Baroque green-copper dome basilica)
##   - Schreierstoren (20.0 m — 1487 round brick tower)
##   - Montelbaanstoren (48.0 m — 1516 bastion + 1606 clock spire)
##   - Scheepvaarthuis / Grand Hotel Amrâth (35.0 m — Amsterdam School ship prow)

const K = preload("res://scripts/generation/landmarks/amsterdam/landmark_ams_kit.gd")
const SK = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Full Cuypers' Amsterdam Centraal (1889): 306 m red-brick & Bentheimer
## sandstone neo-Renaissance range, central triumphal stepped gable, 45 m west
## clock tower & east gilded wind-vane tower, East Royal Pavilion, 1889 & 1922
## iron-and-glass arched train sheds, and 2015 curving glass IJ-side canopy.
static func amsterdam_centraal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	SK.mats(lm, "brick", "#8E3B2B", "#E2D7BF", "slate", "#3B434B")
	lm.use("Lamp", LandmarkMaterials.lit("#FFD588", 2.8))
	# Three train / transit sheds behind (-Z toward the IJ):
	# 1) 1889 main south arched train shed (Middenkap)
	SK.shed(lm, "Roof", "Steel", "Glass", Vector3(-135.0, 0.0, -34.0), Vector3.RIGHT, 42.0, 270.0, 9.5, 14.5, 9.0, 0.52, 3)
	# 2) 1922 north arched train shed
	SK.shed(lm, "Roof", "Steel", "Glass", Vector3(-118.0, 0.0, -76.0), Vector3.RIGHT, 34.0, 236.0, 8.5, 11.0, 9.0, 0.50, 3)
	# 3) 2015 Benthem Crouwel curved glass-and-steel IJ-side bus station & ferry canopy
	SK.shed(lm, "Glass", "Steel", "Glass", Vector3(-112.0, 0.0, -108.0), Vector3.RIGHT, 24.0, 224.0, 9.0, 4.5, 10.0, 0.82, 2)
	# Symmetrical neo-Renaissance brick-and-sandstone front ranges
	for s in [-1.0, 1.0]:
		SK.block(lm, "Walls", "Trim", "Glass", "Roof", s * 48.0, 0.0, 60.0, 24.0, 0.0, 16.5, "hip", 7.2, 4.2, 5.0, true)
		SK.block(lm, "Walls", "Trim", "Glass", "Roof", s * 86.0, 0.0, 16.0, 28.0, 0.0, 19.5, "hip", 8.5, 3.5, 5.5, true)
		SK.block(lm, "Walls", "Trim", "Glass", "Roof", s * 109.0, 0.0, 30.0, 24.0, 0.0, 15.5, "hip", 6.8, 4.2, 5.0, true)
		SK.block(lm, "Walls", "Trim", "Glass", "Roof", s * 129.0, 0.0, 12.0, 27.0, 0.0, 17.5, "hip", 7.5, 3.5, 5.5, true)
		# Dormer gables along the intermediate wings
		for dx in [34.0, 48.0, 62.0]:
			K.step_gable(lm, "Walls", "Trim", Vector3(s * dx, 16.5, 12.1), Vector3.BACK, 5.2, 4.6, 3, 0.6)
		# Twin 45 m central towers: west clock dial, east gilded wind-vane dial
		var t := Vector3(s * 14.0, 0.0, 6.0)
		SK.clock_tower(lm, "Walls", "Trim", "Roof", "Dial" if s < 0.0 else "Gilt", "Glass", t, 9.4, 27.5, "flat", 0.65)
		lm.box("Walls", t + Vector3.UP * 30.8, Vector3(6.8, 6.2, 6.8))
		lm.frustum("Lamp", t + Vector3.UP * 29.0, 2.2, 2.0, 3.6, 8)
		lm.spire("Roof", t + Vector3.UP * 33.9, 3.7, 11.1)
	# East Royal Pavilion (Koninklijke Wachtkamer) projecting on the east wing
	SK.block(lm, "Walls", "Trim", "Glass", "Roof", 142.0, 4.0, 16.0, 22.0, 0.0, 15.0, "hip", 8.0, 3.8, 4.8, true)
	lm.frustum("Gilt", Vector3(142.0, 23.0, 4.0), 0.3, 0.06, 2.4, 6)
	# Central triumphal stepped gable entrance pavilion
	SK.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.5, 18.0, 28.0, 0.0, 24.5, "gable_z", 9.5, 4.0, 5.5, false)
	K.step_gable(lm, "Walls", "Trim", Vector3(0.0, 24.5, 15.5), Vector3.BACK, 18.0, 9.5, 5, 0.9)
	SK.arch_row(lm, "Trim", "Glass", Vector3(-7.5, 0.0, 15.6), Vector3(7.5, 0.0, 15.6), Vector3.BACK, 0.6, 3, 4.2, 8.8, 2)
	SK.arch_window(lm, "Trim", "Glass", Vector3(0.0, 11.2, 15.6), Vector3.BACK, 9.6, 10.2, 3)
	for y in [5.2, 10.8, 16.2]:
		K.stone_band(lm, "Trim", 0.0, 0.0, 272.0, 24.5, y, 0.55, 0.25)
	lm.box("Lamp", Vector3(0.0, 9.8, 15.7), Vector3(16.0, 0.35, 0.25))
	lm.commit(model)

## Beurs van Berlage (H.P. Berlage, 1903 on Damrak): unplastered deep red-orange
## brick halls, pale sandstone lintels, three pitched glass-and-iron hall roofs,
## and signature 40 m corner clock tower with green patinated copper cap.
static func beurs_van_berlage(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#94422D", "#DDD2B8", "#3D444C")
	# Exact OSM footprint (54 m wide x 136 m long along Damrak)
	lm.box("Brick", Vector3(0.0, 9.5, 0.0), Vector3(54.0, 19.0, 136.0))
	for rx in [-15.0, 0.0, 15.0]:
		K.pitched_roof(lm, "Glass", Vector3(rx, 19.0, 0.0), 13.5, 122.0, 6.2, false)
	for y in [5.4, 11.2, 18.6]:
		K.stone_band(lm, "Stone", 0.0, 0.0, 54.4, 136.4, y, 0.55, 0.22)
	for sx in [-1.0, 1.0]:
		for y0 in [1.0, 6.4, 12.2]:
			K.window_row(lm, "Glass", Vector3(sx * 27.08, 0.0, -62.0), Vector3(sx * 27.08, 0.0, 62.0),
				Vector3(sx, 0.0, 0.0), y0, 24, 2.2, 3.6)
	for sz in [-1.0, 1.0]:
		for y0 in [1.0, 6.4, 12.2]:
			K.window_row(lm, "Glass", Vector3(-22.0, 0.0, sz * 68.08), Vector3(22.0, 0.0, sz * 68.08),
				Vector3(0.0, 0.0, sz), y0, 10, 2.2, 3.6)
	var t := Vector3(-22.5, 0.0, 63.5)
	lm.box("Brick", t + Vector3.UP * 16.5, Vector3(9.0, 33.0, 9.0))
	K.stone_band(lm, "Stone", t.x, t.z, 9.4, 9.4, 32.8, 0.75, 0.3)
	for n in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		K.clock_dial(lm, "Dial", "Gold", t + Vector3.UP * 27.5 + n * 4.6, n, 1.8)
	lm.frustum("Lamp", t + Vector3.UP * 33.2, 2.6, 2.4, 2.2, 8)
	lm.frustum("Copper", t + Vector3.UP * 33.5, 5.0, 0.12, 6.5, 4)
	lm.commit(model)

## Sint-Nicolaasbasiliek (1887, facing Amsterdam Centraal): neo-Baroque
## sandstone & brick twin-towered basilica with 58 m green copper crossing dome.
static func sint_nicolaasbasiliek(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#8A4634", "#D8CCB4", "#3B4249")
	# Exact OSM footprint (24 m wide x 48 m long)
	lm.box("Brick", Vector3(0.0, 11.0, 0.0), Vector3(24.0, 22.0, 48.0))
	K.pitched_roof(lm, "Roof", Vector3(0.0, 22.0, 0.0), 24.4, 48.4, 6.8, false)
	lm.box("Stone", Vector3(0.0, 11.5, -24.5), Vector3(16.0, 23.0, 2.4))
	K.pediment(lm, "Stone", "Brick", Vector3(0.0, 23.0, -24.8), Vector3.FORWARD, 15.0, 5.2, 1.4)
	lm.frustum("Glass", Vector3(0.0, 14.5, -25.8), 2.8, 2.8, 0.4, 16)
	for sx in [-1.0, 1.0]:
		var tp := Vector3(sx * 10.2, 0.0, -20.5)
		lm.box("Stone", tp + Vector3.UP * 14.5, Vector3(6.2, 29.0, 6.2))
		lm.lathe("Copper", tp + Vector3.UP * 29.0, PackedVector2Array([
			Vector2(3.0, 0.0), Vector2(3.2, 3.2), Vector2(1.9, 6.4), Vector2(0.15, 10.0),
		]), 12)
	var d := Vector3(0.0, 23.0, 4.0)
	lm.frustum("Stone", d, 9.6, 9.2, 11.0, 8)
	lm.lathe("Copper", d + Vector3.UP * 11.0, PackedVector2Array([
		Vector2(9.2, 0.0), Vector2(8.8, 4.8), Vector2(6.6, 10.2), Vector2(3.0, 13.8), Vector2(2.2, 14.6),
	]), 16)
	lm.frustum("Lamp", d + Vector3.UP * 25.6, 1.9, 1.7, 3.8, 8)
	lm.frustum("Copper", d + Vector3.UP * 29.4, 2.2, 0.1, 5.6, 8)
	lm.commit(model)

## Schreierstoren (1487 on Geldersekade/Oosterdok): stout semicircular red-brick
## medieval defence tower with conical slate roof (20 m).
static func schreierstoren(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7C372B", "#D6CBB4", "#373E46")
	lm.frustum("Brick", Vector3.ZERO, 6.8, 6.5, 12.2, 16)
	lm.box("Brick", Vector3(-3.8, 6.1, 0.0), Vector3(7.6, 12.2, 13.0))
	lm.frustum("Stone", Vector3(0.0, 12.2, 0.0), 7.1, 7.0, 0.55, 16)
	lm.frustum("Roof", Vector3(0.0, 12.75, 0.0), 7.0, 0.15, 7.25, 16)
	lm.commit(model)

## Montelbaanstoren (1516 bastion + Hendrick de Keyser 1606 spire, 48 m):
static func montelbaanstoren(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7A372B", "#DCD1BA", "#383F47")
	lm.frustum("Brick", Vector3.ZERO, 6.2, 5.9, 21.0, 14)
	lm.frustum("Stone", Vector3(0.0, 21.0, 0.0), 6.6, 6.4, 0.8, 14)
	for n in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		K.clock_dial(lm, "Dial", "Gold", Vector3(0.0, 18.2, 0.0) + n * 6.0, n, 1.4)
	K.dutch_spire(lm, "White", "Roof", "Stone", "Lamp", Vector3(0.0, 21.8, 0.0), 4.6, 26.2, false)
	lm.commit(model)

## Scheepvaarthuis / Grand Hotel Amrâth (1916 — birth of the Amsterdam School):
## acute ship-prow sculpted brick & granite block with steep tiled roof (35 m).
static func scheepvaarthuis(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "#7B3A29", "#A89E90", "#6B382A")
	# Tapered ship-prow massing (+Z narrow prow, -Z wider stern)
	lm.box("Stone", Vector3(0.0, 2.4, 0.0), Vector3(54.0, 4.8, 76.0))
	lm.box("Brick", Vector3(0.0, 13.5, -10.0), Vector3(52.0, 18.0, 52.0))
	lm.box("Brick", Vector3(0.0, 13.5, 22.0), Vector3(32.0, 18.0, 24.0))
	lm.frustum("Brick", Vector3(0.0, 4.5, 36.0), 10.5, 9.8, 18.0, 6)
	K.pitched_roof(lm, "Roof", Vector3(0.0, 22.5, -10.0), 52.4, 52.4, 7.5, false)
	K.pitched_roof(lm, "Roof", Vector3(0.0, 22.5, 22.0), 32.4, 24.4, 7.0, false)
	# Maritime prow turret rising to 35 m
	lm.frustum("Roof", Vector3(0.0, 22.5, 36.0), 9.6, 1.2, 9.5, 6)
	lm.frustum("Copper", Vector3(0.0, 32.0, 36.0), 1.4, 0.1, 3.0, 6)
	for sx in [-1.0, 1.0]:
		for y0 in [6.5, 11.5, 16.5]:
			K.window_row(lm, "Glass", Vector3(sx * 26.08, 0.0, -32.0), Vector3(sx * 26.08, 0.0, 12.0),
				Vector3(sx, 0.0, 0.0), y0, 11, 2.2, 3.2)
	lm.commit(model)
