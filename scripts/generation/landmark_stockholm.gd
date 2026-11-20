class_name LandmarkStockholm
extends RefCounted

## Stockholm City Hall (Östberg, 1911-1923) in true metres. Origin at the
## centroid of OSM relation 29368; the registry yaw (-7.5) turns local +X
## onto the 82.5 degree long axis, so +Z is the water front to
## Riddarfjärden (south) and -Z the street side. Plan, heights and the
## tower position are measured from the relation's outline and its
## building:part ways (docs/stockholm-landmark-sources.md); the photos are
## in visual-plan/refs/landmarks/stockholm_city_hall/.
##
## Plan (x east, z south, 136 x 77 m): four ranges round the open
## Borgargården (x -4.5..44, z -24..17.7) on its north, east and south,
## the Blue Hall block (x -66.5..-4.5) closing it on the west, and the
## tower at the south-east corner. The courtyard is therefore the EAST
## half of the building, the Blue Hall the west half.
## - Walls: some eight million hand-made dark red-brown "munktegel"
##   bricks over a pale stone plinth, eaves at 25 m under a stone cornice.
## - North and east ranges: gabled roofs of red-orange tile to 32 m
##   (the orange roofs round the courtyard in the aerial photo); the
##   south range, the Golden Hall wing, carries the long verdigris copper
##   roof with its standing seams; the Blue Hall block a low grey-green
##   roof with the raised clerestory hip over the hall.
## - Water front (StoCityHallFront): 17 slender stone columns carry 16
##   round brick arches over a loggia, above it the tall windows of the
##   Golden Hall with the balcony oriel to the west, then two rows of
##   small pointed windows under the cornice. The inner (courtyard) side
##   has its own seven-bay arcade and the gilt statues on the parapet.
## - Turrets: Karintornet (NE, 50 m) and the NW turret (48 m) in brick
##   with copper onions, Måntornet (SW of the water front, 50 m) topped by
##   the gilt crescent moon, and the two fully copper-clad towers on the
##   courtyard's west side (Södra 44 m, Norra 35 m).
## - Tower (StoCityHallTower): 16.5 m square brick shaft with slit
##   windows to 67 m, the stone cornice and dark copper base, the open
##   lantern of slim copper columns with its bell, the gilded onion and
##   the three crowns of Tre Kronor on the mast, 106 m. Birger Jarl's
##   gilded cenotaph stands at its east foot.
## - Terrace and garden (StoCityHallGarden): the stone terrace and steps,
##   Stadshusträdgården with the parterre, two basins, two flagpoles,
##   bronze figures, the granite quay railing and Engelbrekt's red
##   granite column on the east corner; floodlighting for the night.
## Surfaces (15): Brick, BrickDark, Tile, Copper, Slate, Windows, Gilt,
## Stone, Granite, Bronze, HallLamp, Water, Hedge, FlagBlue, FlagYellow.

const TOP_M := 106.0
const X_W := -66.5
const X_E := 62.1
const Z_N := -37.5
const Z_S := 35.6
const EAVE := 25.0
const RISE := 7.0
const COURT_X0 := -4.5
const COURT_X1 := 44.0
const COURT_Z0 := -24.0
const COURT_Z1 := 17.7
## South wing (Golden Hall) west and east ends.
const SOUTH_X0 := -25.0
const SOUTH_X1 := 52.8
## Tower centre and side.
const TOWER_C := Vector2(61.05, 31.7)
const TOWER_W := 16.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	materials(lm)
	_masses(lm)
	_roofs(lm)
	_faces(lm)
	_turrets(lm)
	StoCityHallFront.south_front(lm)
	StoCityHallFront.courtyard(lm)
	StoCityHallTower.build(lm, TOWER_C, TOWER_W, TOP_M)
	StoCityHallGarden.build(lm)
	lm.commit(model)
	StoCityHallGarden.lights(model)

static func materials(lm: LandmarkMesh) -> void:
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#703B2C", 2.5))
	lm.use("BrickDark", LandmarkMaterials.pbr("brick", "#46231B", 2.5))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A04C2C", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#587A6A", 2.0, 0.55, 0.3))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#667068", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#22292D"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D2C4AC", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("rock", "#8E8B86", 4.0))
	lm.use("Bronze", LandmarkMaterials.paint("#4C5A4E", 0.45, 0.5))
	lm.use("HallLamp", _lamp_glass())
	lm.use("Water", LandmarkMaterials.pool_water("#4A7482"))
	lm.use("Hedge", LandmarkMaterials.pbr("lawn", "#3A5A2C", 1.5))
	lm.use("FlagBlue", LandmarkMaterials.paint("#2A62A8", 0.7, 0.0))
	lm.use("FlagYellow", LandmarkMaterials.paint("#E4B92A", 0.7, 0.0))

## Window glass that is lit amber at night (LandmarkLights.NIGHT_GLOW_META).
static func _lamp_glass() -> StandardMaterial3D:
	var m := LandmarkMaterials.glass("#2A3438").duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color("#FFC878")
	m.emission_energy_multiplier = 0.0
	m.set_meta(LandmarkLights.NIGHT_GLOW_META, 1.1)
	return m

## Wall masses: the north, east and Blue Hall ranges (the south range is
## StoCityHallFront's), each on its stone skirt under a stone cornice.
static func _masses(lm: LandmarkMesh) -> void:
	_wing(lm, SOUTH_X0, X_E, Z_N, COURT_Z0, EAVE)
	_wing(lm, COURT_X1, X_E, COURT_Z0, 23.5, EAVE)
	_wing(lm, X_W, COURT_X0, -34.0, 34.0, EAVE)
	# The raised hall over the Blue Hall: a clerestory storey under its own hip.
	lm.box("Brick", Vector3(-40.0, 26.5, 1.0), Vector3(30.0, 3.0, 50.0))
	for k in 9:
		var x := -55.0 + 30.0 * (float(k) + 0.5) / 9.0
		for sz in [-1.0, 1.0]:
			lm.box("Windows", Vector3(x, 26.9, 1.0 + sz * 25.05), Vector3(1.8, 1.9, 0.08), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		for k in 6:
			lm.box("Windows", Vector3(-40.0 + sx * 15.05, 26.9, -19.0 + 8.0 * float(k)), Vector3(0.08, 1.9, 1.8), Basis(), 0.0)

static func _wing(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, h: float) -> void:
	var c := Vector3((x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5)
	var s := Vector3(x1 - x0, h, z1 - z0)
	lm.box("Brick", c + Vector3(0, h * 0.5, 0), s)
	lm.box("Stone", c + Vector3(0, 0.6, 0), Vector3(s.x + 0.5, 1.2, s.z + 0.5))
	lm.box("Stone", c + Vector3(0, h - 0.35, 0), Vector3(s.x + 0.7, 0.7, s.z + 0.7))

## Roofs: tile over the north and east ranges, copper over the south
## range, the Blue Hall's slate hips.
static func _roofs(lm: LandmarkMesh) -> void:
	roof(lm, "Tile", SOUTH_X0, X_E, Z_N, COURT_Z0, EAVE, RISE, true, "Brick", false)
	roof(lm, "Tile", COURT_X1, X_E, Z_N, 26.65, EAVE, RISE, false, "Brick", false)
	roof(lm, "Copper", SOUTH_X0, SOUTH_X1, COURT_Z1, Z_S, EAVE, RISE, true, "Brick", true)
	hip(lm, "Slate", X_W, COURT_X0, -34.0, 34.0, EAVE, 3.2)
	hip(lm, "Slate", -55.0, -25.0, -24.0, 26.0, 28.0, 4.2)

## Gabled roof over the eave rectangle x0..x1, z0..z1 at height `y`, ridge
## along X (`ridge_x`) or Z; `seams` lays the standing seams of a copper
## roof down both slopes.
static func roof(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float, y: float,
		rise: float, ridge_x: bool, gable_key: String, seams: bool) -> void:
	var c := Vector3((x0 + x1) * 0.5, y, (z0 + z1) * 0.5)
	var run := (x1 - x0) if ridge_x else (z1 - z0)
	var across := (z1 - z0) if ridge_x else (x1 - x0)
	var rb := Basis(Vector3.UP, PI * 0.5) if ridge_x else Basis()
	lm.gable(key, c, across, run, rise, rb, 0.5, gable_key)
	lm.box(key, c + Vector3(0, rise + 0.15, 0), Vector3(0.4, 0.4, run + 0.5), rb, 0.0)
	if not seams:
		return
	var half := across * 0.5 + 0.5
	var n := int(run / 2.0)
	for k in n + 1:
		var u := -run * 0.5 + run * float(k) / float(n)
		for s in [-1.0, 1.0]:
			lm.beam(key, c + rb * Vector3(s * half, 0.08, u), c + rb * Vector3(0, rise + 0.08, u), 0.08, 0.1)

## Hipped roof over the eave rectangle, ridge along its longer side.
static func hip(lm: LandmarkMesh, key: String, x0: float, x1: float, z0: float, z1: float, y: float,
		rise: float, over: float = 0.5) -> void:
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var wx := (x1 - x0) * 0.5 + over
	var wz := (z1 - z0) * 0.5 + over
	var ux := wx >= wz
	var hu := wx if ux else wz
	var hv := wz if ux else wx
	var e := hu - hv
	var P := func(u: float, v: float, h: float) -> Vector3:
		return Vector3(cx + u, y + h, cz + v) if ux else Vector3(cx + v, y + h, cz + u)
	var N := func(nu: float, nv: float, ny: float) -> Vector3:
		return (Vector3(nu, ny, nv) if ux else Vector3(nv, ny, nu)).normalized()
	lm.quad(key, P.call(-hu, -hv, 0.0), P.call(hu, -hv, 0.0), P.call(e, 0.0, rise), P.call(-e, 0.0, rise),
		N.call(0.0, -rise, hv))
	lm.quad(key, P.call(hu, hv, 0.0), P.call(-hu, hv, 0.0), P.call(-e, 0.0, rise), P.call(e, 0.0, rise),
		N.call(0.0, rise, hv))
	var nl: Vector3 = N.call(-rise, 0.0, hv)
	var nr: Vector3 = N.call(rise, 0.0, hv)
	lm.tri(key, P.call(-hu, hv, 0.0), P.call(-hu, -hv, 0.0), P.call(-e, 0.0, rise), nl, nl, nl,
		Vector2(0, 0), Vector2(hv * 2.0, 0), Vector2(hv, -rise))
	lm.tri(key, P.call(hu, -hv, 0.0), P.call(hu, hv, 0.0), P.call(e, 0.0, rise), nr, nr, nr,
		Vector2(0, 0), Vector2(hv * 2.0, 0), Vector2(hv, -rise))

## Windows in rows set deep in the brick of the street-side and flank
## walls (real reveals), the grand doors under stone arches on the north.
static func _faces(lm: LandmarkMesh) -> void:
	var n := Vector3(0, 0, -1)
	LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(X_E, 1.2, Z_N), Vector3(-1, 0, 0), n,
		X_E - SOUTH_X0, EAVE - 2.0, 24, 3, Vector2(1.4, 3.0), 4.6, 6.5, 0.45)
	LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(SOUTH_X0, 1.2, -34.0), Vector3(-1, 0, 0), n,
		SOUTH_X0 - X_W, EAVE - 2.0, 10, 3, Vector2(1.4, 3.0), 4.6, 6.5, 0.45)
	for k in 24:
		var x := X_E - (X_E - SOUTH_X0) * (float(k) + 0.5) / 24.0
		for row in 3:
			lm.box("Stone", Vector3(x, 1.2 + 4.6 + 6.5 * row - 0.12, Z_N - 0.55), Vector3(1.8, 0.24, 0.3), Basis(), 0.0)
	for x in [6.0, 34.0]:
		lm.box("BrickDark", Vector3(float(x), 2.6, Z_N - 0.47), Vector3(3.0, 3.6, 0.1))
		LandmarkDetail.arch(lm, "Stone", Vector3(float(x), 4.4, Z_N - 0.5), n, 3.0, 0.5, 0.4)
	# West flank, Blue Hall block south face, east flank.
	LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(X_W, 1.2, -34.0), Vector3(0, 0, 1), Vector3(-1, 0, 0),
		68.0, EAVE - 2.0, 16, 3, Vector2(1.3, 2.8), 4.0, 6.5, 0.4)
	LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(X_W, 1.2, 34.0), Vector3(1, 0, 0), Vector3(0, 0, 1),
		SOUTH_X0 - X_W - 5.0, EAVE - 2.0, 11, 4, Vector2(1.3, 2.6), 3.2, 5.0, 0.4)
	LandmarkDetail.pierced_face(lm, "Brick", "Windows", Vector3(X_E, 1.2, 23.5), Vector3(0, 0, -1), Vector3(1, 0, 0),
		23.5 - Z_N - 8.0, EAVE - 2.0, 11, 3, Vector2(1.3, 2.8), 4.0, 6.5, 0.4)

## The five turrets of the plan, from the OSM building parts.
static func _turrets(lm: LandmarkMesh) -> void:
	turret(lm, Vector2(63.3, -32.2), 6.4, 32.0, 18.0, "Brick", false)
	turret(lm, Vector2(-27.65, -34.35), 6.4, 26.0, 22.0, "Brick", false)
	turret(lm, Vector2(-27.55, 35.85), 5.4, 26.5, 23.5, "Brick", true)
	turret(lm, Vector2(-0.75, 14.8), 5.9, 25.0, 19.0, "Copper", false)
	turret(lm, Vector2(-1.4, -16.1), 6.2, 23.0, 12.0, "Copper", false)

## A square turret: shaft with a stone belt and slit windows under an
## eight-sided copper onion with its gilt ball and needle; `moon` crowns
## the mast with the gilt crescent (Måntornet).
static func turret(lm: LandmarkMesh, c: Vector2, w: float, shaft: float, onion_h: float, key: String,
		moon: bool) -> void:
	var base := Vector3(c.x, 0.0, c.y)
	lm.box(key, base + Vector3(0, shaft * 0.5, 0), Vector3(w, shaft, w))
	if key == "Brick":
		lm.box("Stone", base + Vector3(0, 0.6, 0), Vector3(w + 0.5, 1.2, w + 0.5))
		lm.box("Stone", base + Vector3(0, shaft - 0.3, 0), Vector3(w + 0.7, 0.6, w + 0.7))
		lm.box("Stone", base + Vector3(0, shaft - 4.0, 0), Vector3(w + 0.3, 0.3, w + 0.3), Basis(), 0.0)
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		for k in 2:
			lm.box("Windows", base + r * Vector3((float(k) - 0.5) * w * 0.4, shaft - 2.4, w * 0.5 + 0.03),
				Vector3(0.6, 1.8, 0.06), r, 0.0)
	var r0 := w * 0.62
	var h := onion_h
	var prof := PackedVector2Array()
	for p in [Vector2(1.0, 0.0), Vector2(1.12, 0.05), Vector2(1.0, 0.12), Vector2(0.62, 0.2), Vector2(0.78, 0.27),
			Vector2(0.84, 0.33), Vector2(0.6, 0.42), Vector2(0.3, 0.52), Vector2(0.16, 0.58), Vector2(0.07, 0.76),
			Vector2(0.0, 1.0)]:
		prof.append(Vector2(p.x * r0, p.y * h))
	lm.lathe("Copper", base + Vector3(0, shaft, 0), prof, 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gilt", base + Vector3(0, shaft + h * 0.5, 0), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.4, 0.1),
		Vector2(0.45, 0.45), Vector2(0.4, 0.8), Vector2(0.0, 0.9)]), 10)
	if moon:
		_crescent(lm, base + Vector3(0, shaft + h * 0.88, 0), 1.5)

## The gilt crescent moon, open to the sky, standing in the XY plane.
static func _crescent(lm: LandmarkMesh, c: Vector3, r: float) -> void:
	var prev := c + Vector3(cos(deg_to_rad(40.0)), sin(deg_to_rad(40.0)), 0.0) * r
	for i in 12:
		var a := deg_to_rad(40.0 + 280.0 * float(i + 1) / 12.0)
		var p := c + Vector3(cos(a), sin(a), 0.0) * r
		lm.beam("Gilt", prev, p, 0.34, 0.2, Vector3.BACK)
		prev = p

## Riddarholmen Church is its own class now.
static func riddarholmen(model: Node3D) -> void:
	StoIslandRiddarholmen.build(model)
