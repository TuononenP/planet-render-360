class_name LandmarkNaBuildings
extends RefCounted

## Four grand buildings in true metres: the US Capitol and the White
## House in Washington, Mexico City's Palacio de Bellas Artes and
## Quebec's Château Frontenac.

const CAPITOL_TOP_M := 88.0
const WHITE_HOUSE_TOP_M := 21.0
const BELLAS_ARTES_TOP_M := 52.0
const FRONTENAC_TOP_M := 78.0

## US Capitol: the long north-south block (Senate wing north, House wing
## south, the central block between, joined by lower links) with its
## colonnaded east porticos and pediments, and above the Rotunda the
## cast-iron dome: the columned peristyle, the attic drum, the ribbed
## shell, the tholos and the bronze Statue of Freedom, to 88 m. The east
## front faces +X.
static func us_capitol(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E9E6DE", 3.0))
	lm.use("Dome", LandmarkMaterials.paint("#F2F1ED", 0.5, 0.1))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7E8884", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Bronze", LandmarkMaterials.paint("#5C4B34", 0.5, 0.5))
	lm.box("Marble", Vector3(0, -0.5, 0), Vector3(118.0, 1.4, 236.0))
	# [z centre, z length, x depth, height]: Senate, link, centre, link, House.
	var blocks := [[-78.0, 70.0, 50.0, 23.0], [-37.0, 12.0, 36.0, 17.0], [0.0, 62.0, 56.0, 28.0],
		[37.0, 12.0, 36.0, 17.0], [78.0, 70.0, 50.0, 23.0]]
	for b in blocks:
		var z: float = b[0]
		var zl: float = b[1]
		var xd: float = b[2]
		var h: float = b[3]
		lm.box("Marble", Vector3(0, h * 0.5, z), Vector3(xd, h, zl))
		lm.box("Marble", Vector3(0, h + 0.6, z), Vector3(xd + 1.2, 1.2, zl + 1.2))
		if h < 20.0 or z == 0.0:
			continue
		LandmarkNaParts.hip(lm, "Roof", Vector3(0, h + 1.2, z), Basis(), xd * 0.5, zl * 0.5, 0.6, 3.5)
	for b in blocks:
		var z: float = b[0]
		var zl: float = b[1]
		var xd: float = b[2]
		var h: float = b[3]
		var cols := maxi(2, floori((zl - 8.0) / 4.2))
		var rows := maxi(2, floori(h / 6.0))
		for s in [-1.0, 1.0]:
			var r := Basis(Vector3.UP, s * PI * 0.5)
			LandmarkNaParts.windows(lm, "Windows", Vector3(s * xd * 0.5, 0, z), r, zl - 8.0, 4.0,
				h - 3.0, rows, cols, Vector2(1.4, 2.6), 0.1)
	# East porticos (centre 12 columns, each wing 8) with pediments.
	for p in [[0.0, 44.0, 15.0, 5.0], [-78.0, 28.0, 11.0, 3.4], [78.0, 28.0, 11.0, 3.4]]:
		var pz: float = p[0]
		var pw: float = p[1]
		var ph: float = p[2]
		var px := 28.0 if pz == 0.0 else 25.0
		lm.box("Marble", Vector3(px + 5.0, 0.6, pz), Vector3(10.0, 1.2, pw + 2.0))
		LandmarkNaParts.columns(lm, "Marble", Vector3(px + 8.5, 1.2, pz - pw * 0.5 + 1.0),
			Vector3(px + 8.5, 1.2, pz + pw * 0.5 - 1.0), 12 if pz == 0.0 else 8, 0.9, 0.8, ph, 10)
		lm.box("Marble", Vector3(px + 5.0, 1.2 + ph + 1.1, pz), Vector3(10.0, 2.2, pw + 1.0))
		lm.gable("Marble", Vector3(px + 5.0, 1.2 + ph + 2.2, pz), pw + 1.0, 10.0, float(p[3]),
			Basis(Vector3.UP, PI * 0.5), 0.2, "Marble")
	# Dome: drum with its 36-column peristyle, entablature, attic, shell.
	lm.frustum("Marble", Vector3(0, 28.0, 0), 17.0, 17.0, 2.0, 32)
	lm.frustum("Dome", Vector3(0, 30.0, 0), 14.6, 14.6, 12.0, 32)
	for k in 36:
		var a := TAU * float(k) / 36.0
		lm.frustum("Dome", Vector3(cos(a) * 15.4, 30.0, sin(a) * 15.4), 0.5, 0.45, 12.0, 8)
	lm.frustum("Dome", Vector3(0, 42.0, 0), 16.2, 16.2, 3.0, 32)
	lm.frustum("Dome", Vector3(0, 45.0, 0), 13.6, 13.2, 7.0, 32)
	lm.lathe("Dome", Vector3(0, 52.0, 0), PackedVector2Array([Vector2(13.2, 0.0), Vector2(12.9, 3.0),
		Vector2(12.0, 7.5), Vector2(10.2, 12.0), Vector2(7.5, 16.0), Vector2(5.0, 19.5),
		Vector2(3.7, 22.0)]), 32)
	lm.frustum("Dome", Vector3(0, 74.0, 0), 3.6, 3.3, 5.0, 16)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.frustum("Marble", Vector3(cos(a) * 3.6, 74.0, sin(a) * 3.6), 0.3, 0.3, 5.0, 6)
	lm.lathe("Dome", Vector3(0, 79.0, 0), PackedVector2Array([Vector2(4.2, 0.0), Vector2(3.0, 1.0),
		Vector2(1.6, 3.0)]), 16)
	lm.lathe("Bronze", Vector3(0, 82.0, 0), PackedVector2Array([Vector2(1.1, 0.0), Vector2(0.9, 2.4),
		Vector2(0.8, 3.8), Vector2(0.6, 4.6), Vector2(0.45, 5.3), Vector2(0.3, 5.8),
		Vector2(0.1, CAPITOL_TOP_M - 82.0)]), 10)
	lm.commit(model)

## White House: the 52 m sandstone block of three storeys on a raised
## basement under its balustrade and low hipped roof with chimneys, the
## north portico with six columns and pediment (−Z), the curved south
## portico (+Z), and the West and East Wings joined by colonnades.
static func white_house(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#EDEBE4", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6C7074", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.box("Wall", Vector3(0, 7.7, 0), Vector3(51.8, 15.4, 25.9))
	lm.box("Wall", Vector3(0, 16.0, 0), Vector3(52.6, 1.2, 26.7))
	LandmarkNaParts.hip(lm, "Roof", Vector3(0, 16.6, 0), Basis(), 24.5, 11.5, 0.78, 2.6)
	for cx in [-20.0, -10.0, 10.0, 20.0]:
		for cz in [-5.0, 5.0]:
			lm.box("Wall", Vector3(cx, 20.0, cz), Vector3(1.4, 2.0, 1.4))
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var span: float = 44.0 if q % 2 == 0 else 20.0
		var face: float = 12.95 if q % 2 == 0 else 25.9
		LandmarkNaParts.windows(lm, "Windows", r * Vector3(0, 0, face), r, span, 2.2, 14.6, 4,
			11 if q % 2 == 0 else 5, Vector2(1.3, 2.0), 0.1)
	# North portico: six columns under a pediment.
	lm.box("Wall", Vector3(0, 0.3, -18.5), Vector3(17.0, 0.6, 11.0))
	LandmarkNaParts.columns(lm, "Wall", Vector3(-7.0, 0.6, -22.5), Vector3(7.0, 0.6, -22.5), 6,
		0.7, 0.6, 11.4)
	lm.box("Wall", Vector3(0, 12.8, -18.5), Vector3(17.6, 1.6, 10.8))
	lm.gable("Wall", Vector3(0, 13.6, -18.5), 17.6, 10.8, 3.4, Basis(), 0.2, "Wall")
	# South portico: the rounded bow with its half ring of columns.
	lm.frustum("Wall", Vector3(0, 0, 12.95), 7.8, 7.8, 14.0, 24)
	for k in 7:
		var a := PI * float(k) / 6.0
		lm.frustum("Wall", Vector3(cos(a) * 9.2, 0.6, 12.95 + sin(a) * 9.2), 0.5, 0.45, 12.0, 8)
	lm.frustum("Wall", Vector3(0, 12.6, 12.95), 9.9, 9.9, 1.2, 24)
	# Wings and their colonnades.
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(s * 31.9, 2.6, 0), Vector3(12.0, 5.2, 5.0))
		var c := Vector3(s * 51.9, 0, 0)
		lm.box("Wall", c + Vector3(0, 4.75, 0), Vector3(26.0, 9.5, 22.0))
		LandmarkNaParts.hip(lm, "Roof", c + Vector3(0, 9.5, 0), Basis(), 13.5, 11.5, 0.75, 1.8)
		for fz in [-1.0, 1.0]:
			LandmarkNaParts.windows(lm, "Windows", c + Vector3(0, 0, fz * 11.0),
				Basis(Vector3.UP, 0.0 if fz > 0.0 else PI), 22.0, 1.8, 8.4, 2, 6, Vector2(1.3, 2.0), 0.1)
	lm.commit(model)

## Palacio de Bellas Artes: the white Carrara-marble body on its
## stylobate with the arched front colonnade (+Z), the cornice, the two
## smaller domes and the great tiled central dome with its lantern,
## to 52 m.
static func bellas_artes(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E7E4DD", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("brick", "#C77035", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#3A8C98", 2.5))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Marble", Vector3(0, 0.75, 0), Vector3(102.0, 1.5, 76.0))
	lm.box("Marble", Vector3(0, 13.0, 0), Vector3(96.0, 23.0, 70.0))
	lm.box("Marble", Vector3(0, 24.0, 0), Vector3(98.0, 2.0, 72.0))
	for sx in [-1.0, 1.0]:
		lm.box("Marble", Vector3(sx * 38.0, 28.0, 0), Vector3(20.0, 6.0, 60.0))
	# Front: arched openings between paired columns, windows elsewhere.
	for x in [-18.0, 0.0, 18.0]:
		lm.box("Windows", Vector3(x, 10.0, 35.1), Vector3(7.0, 14.0, 0.3))
	LandmarkNaParts.columns(lm, "Marble", Vector3(-27.0, 1.5, 36.5), Vector3(27.0, 1.5, 36.5), 8,
		0.8, 0.7, 20.0)
	LandmarkNaParts.windows(lm, "Windows", Vector3(0, 0, 35.0), Basis(), 90.0, 4.0, 20.0, 2, 14,
		Vector2(1.6, 3.4), 0.1)
	for q in [1, 2, 3]:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var span: float = 64.0 if q % 2 == 1 else 90.0
		var face: float = 48.0 if q % 2 == 1 else 35.0
		LandmarkNaParts.windows(lm, "Windows", r * Vector3(0, 0, face), r, span, 4.0, 20.0, 2,
			12 if q % 2 == 1 else 14, Vector2(1.6, 3.4), 0.1)
	# Side domes (teal tile) and the central dome (orange tile).
	for sx in [-1.0, 1.0]:
		lm.frustum("Marble", Vector3(sx * 38.0, 31.0, 0), 8.5, 8.5, 4.0, 20)
		lm.lathe("Tile", Vector3(sx * 38.0, 35.0, 0), _dome(8.8, 8.0), 20)
		lm.frustum("Gold", Vector3(sx * 38.0, 43.0, 0), 0.5, 0.2, 2.0, 8)
	lm.frustum("Marble", Vector3(0, 25.0, 0), 15.5, 15.5, 8.0, 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.frustum("Marble", Vector3(cos(a) * 15.8, 25.0, sin(a) * 15.8), 0.45, 0.45, 8.0, 8)
	lm.lathe("Dome", Vector3(0, 33.0, 0), _dome(15.2, 14.0), 32)
	lm.frustum("Marble", Vector3(0, 47.0, 0), 2.2, 1.9, 3.5, 12)
	lm.lathe("Gold", Vector3(0, 50.5, 0), PackedVector2Array([Vector2(1.6, 0.0), Vector2(1.0, 0.8),
		Vector2(0.15, BELLAS_ARTES_TOP_M - 50.5)]), 8)
	lm.commit(model)

static func _dome(r: float, h: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 9:
		var a := PI * 0.5 * float(i) / 8.0
		p.append(Vector2(r * cos(a), h * sin(a)))
	return p

## Château Frontenac: the baronial hotel above the St Lawrence — the long
## river wing (+Z) with its steep green copper roofs, dormers and round
## corner turrets, the two rear wings swept back from it, and the great
## central tower under its pyramidal roof (78 m).
static func chateau_frontenac(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B09A74", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#CFC6B2", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5F8B78", 2.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	_wing(lm, Vector3(0, 0, 4.0), Vector2(94.0, 22.0), 38.0, 18.0)
	_wing(lm, Vector3(-42.0, 0, -32.0), Vector2(20.0, 56.0), 34.0, 15.0)
	_wing(lm, Vector3(42.0, 0, -32.0), Vector2(20.0, 56.0), 34.0, 15.0)
	_wing(lm, Vector3(0, 0, -58.0), Vector2(104.0, 16.0), 30.0, 12.0)
	# Central tower and its pyramidal roof.
	lm.box("Brick", Vector3(0, 26.0, 8.0), Vector3(24.0, 52.0, 22.0))
	lm.box("Trim", Vector3(0, 52.4, 8.0), Vector3(25.4, 1.0, 23.4))
	LandmarkNaParts.hip(lm, "Roof", Vector3(0, 52.9, 8.0), Basis(), 13.2, 12.2, 0.16, FRONTENAC_TOP_M - 52.9)
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var face: float = 11.0 if q % 2 == 0 else 12.0
		LandmarkNaParts.windows(lm, "Windows", Vector3(0, 0, 8.0) + r * Vector3(0, 0, face), r,
			18.0, 20.0, 50.0, 8, 4, Vector2(1.3, 2.0), 0.1)
	# Corner turrets with conical copper caps.
	for p in [Vector3(-47.0, 0, 15.0), Vector3(47.0, 0, 15.0), Vector3(-52.0, 0, -86.0 + 20.0),
			Vector3(52.0, 0, -86.0 + 20.0), Vector3(-12.0, 0, 15.0), Vector3(12.0, 0, 15.0)]:
		lm.lathe("Brick", p, PackedVector2Array([Vector2(4.2, 0.0), Vector2(4.2, 44.0)]), 14)
		lm.frustum("Trim", p + Vector3(0, 44.0, 0), 4.6, 4.6, 0.6, 14)
		lm.lathe("Roof", p + Vector3(0, 44.6, 0), PackedVector2Array([Vector2(5.0, 0.0),
			Vector2(2.2, 8.0), Vector2(0.0, 15.0)]), 14)
	lm.commit(model)

## One storeyed block at `c` (size X x Z) with a steep hipped copper
## roof `rise` high, a window row per storey and dormers on the long
## slopes.
static func _wing(lm: LandmarkMesh, c: Vector3, size: Vector2, walls: float, rise: float) -> void:
	lm.box("Brick", c + Vector3(0, walls * 0.5, 0), Vector3(size.x, walls, size.y))
	lm.box("Trim", c + Vector3(0, walls - 0.4, 0), Vector3(size.x + 0.6, 0.8, size.y + 0.6))
	LandmarkNaParts.hip(lm, "Roof", c + Vector3(0, walls, 0), Basis(), size.x * 0.5 + 0.8,
		size.y * 0.5 + 0.8, 0.3, rise)
	var storeys := floori(walls / 3.6)
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var span: float = size.x if q % 2 == 0 else size.y
		var face: float = size.y * 0.5 if q % 2 == 0 else size.x * 0.5
		LandmarkNaParts.windows(lm, "Windows", c + r * Vector3(0, 0, face), r, span - 4.0, 2.0,
			walls - 2.0, storeys, maxi(3, floori(span / 4.2)), Vector2(1.2, 1.9), 0.1)
	if size.y > size.x:
		return
	var n := maxi(2, floori(size.x / 9.0))
	for k in n:
		var x := -size.x * 0.38 + size.x * 0.76 * (float(k) + 0.5) / float(n)
		for s in [-1.0, 1.0]:
			var dc := c + Vector3(x, walls + rise * 0.3, s * (size.y * 0.5 + 0.8) * 0.72)
			lm.box("Brick", dc + Vector3(0, 1.2, 0), Vector3(2.4, 2.4, 2.0))
			lm.gable("Roof", dc + Vector3(0, 2.4, 0), 2.4, 2.0, 1.4, Basis(), 0.2, "Brick")
