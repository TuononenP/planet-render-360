class_name StoOuterBerwald
extends RefCounted

## Berwaldhallen, the Radiohuset concert hall (Sven-Ivar Lind, 1979), Djurgardsslatten.
## Origin at the OSM footprint centroid (way 5174887, 76.8 x 51.7 m), long
## axis local X, front +Z. The registry yaw (-67.8) turns local +X onto
## bearing 22.2 and the front (+Z) onto bearing 112.2.
##
## Footprint in the model frame: x -37.4..39, z -27.6..24.1.
##
## From the photos (front, quarter, aerial in visual-plan/refs/landmarks/
## berwaldhallen/; the concrete is a pale warm grey, not white):
## - The hall is a tall windowless block of board-marked pale concrete,
##   12 m to its flat roof, its walls broken into a rhythm of vertical
##   concrete fins every 2.4 m whose tops rise and fall by up to 1 m,
##   so the skyline is wavy.
## - Round the foot runs a low glazed foyer, 4.7 m high under a dark flat
##   roof edge, behind a row of free-standing square concrete piers (3.6 m
##   apart) with the glass set back between them.
## - In the middle of the front a concrete canopy (10 m deep, on two piers)
##   shelters the doors; BERWALDHALLEN in big white letters on its fascia.
## - Left of the foyer a dark brown service wall with the high loading door.
## - Paved forecourt in front.
## Height 13 m is the tallest fin, scaled from the quarter photo against the
## 4.7 m foyer piers (OSM has only `building:levels=3`, derived 12 m).
## Night: a warm glow in the foyer, the front washed from the forecourt.

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")

const HALL_Y := 12.0
const FIN_RISE := 1.0
const FOYER_Y := 4.7
const FIN_STEP := 2.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BBB4A8", 3.0))
	lm.use("Fin", LandmarkMaterials.pbr("concrete", "#C6BFB3", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#7C9893"))
	lm.use("Fascia", LandmarkMaterials.paint("#38322C", 0.55, 0.3))
	lm.use("Brown", LandmarkMaterials.pbr("wood", "#3D2E26", 2.0))
	lm.use("Sign", LandmarkMaterials.paint("#ECEAE3", 0.5, 0.1))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#52504C", 3.0, 0.6, 0.4))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#9B968C", 2.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE9BE", 0.7))
	_hall(lm)
	_fins(lm)
	_foyer(lm)
	_canopy(lm)
	_service(lm)
	_forecourt(lm)
	lm.commit(model)
	# Night: the front and the sign are washed from the forecourt.
	var warm := Color(1.0, 0.88, 0.7)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-24.0, 1.5, 40.0), Vector3(-12.0, 9.0, 9.0), 40.0, 0.8, 55.0, warm],
		[Vector3(24.0, 1.5, 40.0), Vector3(12.0, 9.0, 9.0), 40.0, 0.8, 55.0, warm],
		[Vector3(1.0, 1.5, 44.0), Vector3(1.0, 5.0, 33.0), 34.0, 0.8, 40.0, warm]])

# --- The hall ----------------------------------------------------------------

static func _hall(lm: LandmarkMesh) -> void:
	K.rb(lm, "Concrete", -30.0, 39.0, 0.0, HALL_Y, -21.0, 9.0, 0.0)
	K.rb(lm, "Concrete", -30.0, 5.7, 0.0, HALL_Y, -27.6, -21.0, 0.0)
	K.rb(lm, "Roof", -30.2, 39.2, HALL_Y, HALL_Y + 0.25, -21.2, 9.2, 0.0)
	K.rb(lm, "Roof", -30.2, 5.9, HALL_Y, HALL_Y + 0.25, -27.8, -21.0, 0.0)

## Vertical fins along every wall run of the hall; their tops rise and fall in waves.
static func _fins(lm: LandmarkMesh) -> void:
	var runs := [
		[Vector2(-30.0, 9.0), Vector2(39.0, 9.0), Vector2(0, 1)],
		[Vector2(39.0, 9.0), Vector2(39.0, -21.0), Vector2(1, 0)],
		[Vector2(39.0, -21.0), Vector2(5.7, -21.0), Vector2(0, -1)],
		[Vector2(5.7, -21.0), Vector2(5.7, -27.6), Vector2(1, 0)],
		[Vector2(5.7, -27.6), Vector2(-30.0, -27.6), Vector2(0, -1)],
		[Vector2(-30.0, -27.6), Vector2(-30.0, 9.0), Vector2(-1, 0)]]
	var k := 0
	for r in runs:
		var a: Vector2 = r[0]
		var b: Vector2 = r[1]
		var out: Vector2 = r[2]
		var run_len := a.distance_to(b)
		var n := maxi(int(run_len / FIN_STEP), 1)
		var basis := Basis(Vector3.UP, atan2(b.x - a.x, b.y - a.y))
		for i in n + 1:
			var p := a.lerp(b, float(i) / float(n)) + out * 0.4
			var h := HALL_Y + FIN_RISE * 0.5 * (1.0 + sin(float(k) * 0.55))
			lm.box("Fin", Vector3(p.x, h * 0.5, p.y), Vector3(0.9, h, 0.9), basis, 0.0)
			k += 1

# --- Foyer, canopy, service wall ---------------------------------------------

static func _foyer(lm: LandmarkMesh) -> void:
	K.rb(lm, "Fascia", -37.4, 39.4, FOYER_Y, FOYER_Y + 0.5, 9.0, 24.6, 0.0)
	K.rb(lm, "Glass", -32.0, 38.4, 0.0, FOYER_Y, 9.0, 22.8, 0.0)
	# Free-standing piers round the front and the east end.
	var x := -34.2
	while x < 39.0:
		K.rb(lm, "Concrete", x - 0.3, x + 0.3, 0.0, FOYER_Y, 23.1, 24.0, 0.0)
		x += 3.6
	var z := 12.0
	while z < 23.0:
		K.rb(lm, "Concrete", 38.4, 39.3, 0.0, FOYER_Y, z - 0.3, z + 0.3, 0.0)
		z += 3.6
	# Interior lights behind the glass (dark by day).
	K.rb(lm, "Lamp", -30.0, 36.0, FOYER_Y - 0.5, FOYER_Y - 0.4, 12.0, 13.0, 0.0)
	K.rb(lm, "Lamp", -30.0, 36.0, FOYER_Y - 0.5, FOYER_Y - 0.4, 19.0, 20.0, 0.0)

static func _canopy(lm: LandmarkMesh) -> void:
	K.rb(lm, "Concrete", -9.0, 11.0, 4.0, 5.5, 24.0, 34.0, 0.0)
	K.rb(lm, "Concrete", -9.0, 11.0, 5.5, 6.0, 33.4, 34.0, 0.0)
	for p in [Vector2(-8.4, 33.3), Vector2(10.4, 33.3), Vector2(1.0, 33.3)]:
		K.rb(lm, "Concrete", p.x - 0.5, p.x + 0.5, 0.0, 4.0, p.y - 0.5, p.y + 0.5, 0.0)
	# The sign: white block letters along the fascia.
	for i in 14:
		var cx := -8.0 + 1.35 * float(i)
		K.rb(lm, "Sign", cx - 0.4, cx + 0.4, 4.45, 5.4, 34.0, 34.15, 0.0)

static func _service(lm: LandmarkMesh) -> void:
	K.rb(lm, "Brown", -37.4, -32.0, 0.0, 5.6, 9.0, 24.1, 0.0)
	# The tall loading door.
	K.rb(lm, "Fascia", -36.0, -33.6, 0.0, 3.9, 24.1, 24.25, 0.0)

static func _forecourt(lm: LandmarkMesh) -> void:
	K.rb(lm, "Pave", -44.0, 44.0, 0.0, 0.06, 24.1, 46.0, 0.0)
