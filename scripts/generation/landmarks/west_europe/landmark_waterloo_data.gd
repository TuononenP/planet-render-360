class_name LandmarkWaterlooData
extends RefCounted

## Plan of London Waterloo in model metres: +X east, +Z south, origin at
## 51.5031 N, 0.1132 W (the registry point), traced from OpenStreetMap
## (way 4245075 and the platform ways 1-24, November 2026) through
## WorldScale's projection.

## Rail level: the city lays the station's viaduct tracks about 5 m up;
## the model's track bed sits under their decks and the platforms stand
## a platform height over the rail.
const TRACK_Y := 3.9
const PLAT_Y := 6.0

const _OUTLINE := [Vector2(-62.4, 130.4), Vector2(-68.1, 125.9), Vector2(-79.3, 152.7),
	Vector2(-86.4, 176.2), Vector2(-92.2, 175.3), Vector2(-87.1, 152.1), Vector2(-75.5, 121.2),
	Vector2(-81.3, 117.9), Vector2(-90.6, 139.5), Vector2(-98.2, 169.9), Vector2(-102.4, 169.3),
	Vector2(-94.9, 135.0), Vector2(-87.2, 114.5), Vector2(-107.6, 102.9), Vector2(-119.4, 143.3),
	Vector2(-122.9, 187.9), Vector2(-128.0, 338.9), Vector2(-162.6, 338.5), Vector2(-162.2, 283.2),
	Vector2(-159.0, 207.8), Vector2(-162.5, 132.9), Vector2(-160.4, 108.5), Vector2(-156.2, 88.5),
	Vector2(-150.4, 67.6), Vector2(-140.3, 42.1), Vector2(-130.2, 22.2), Vector2(-80.3, -45.3),
	Vector2(-78.8, -44.2), Vector2(-71.9, -53.4), Vector2(-70.0, -51.8), Vector2(-60.7, -62.9),
	Vector2(-72.5, -71.9), Vector2(-64.9, -85.1), Vector2(-54.9, -76.7), Vector2(-35.4, -74.8),
	Vector2(-31.5, -78.6), Vector2(-21.6, -75.5), Vector2(-21.9, -74.1), Vector2(20.1, -61.4),
	Vector2(65.2, -49.9), Vector2(78.4, -40.8), Vector2(77.5, -39.6), Vector2(94.8, -24.4), Vector2(95.9, -25.5),
	Vector2(100.8, -20.0), Vector2(98.4, -18.1), Vector2(145.7, 42.8), Vector2(144.7, 46.1), Vector2(8.8, 192.1),
	Vector2(-39.6, 149.1), Vector2(-67.0, 196.9), Vector2(-70.5, 195.3), Vector2(-45.1, 144.2),
	Vector2(-50.4, 139.4), Vector2(-75.0, 188.1), Vector2(-81.5, 185.5), Vector2(-75.3, 162.9)]

## The Edwardian office range's street front on Mepham Street and
## Waterloo Road, west to east, and its inner face 16 m in.
const _FRONT := [Vector2(-54.9, -76.7), Vector2(-35.4, -74.8), Vector2(-21.9, -74.1),
	Vector2(20.1, -61.4), Vector2(65.2, -49.9), Vector2(78.4, -40.8), Vector2(98.4, -18.1), Vector2(145.7, 42.8)]
const _INNER := [Vector2(-56.5, -60.8), Vector2(-36.6, -58.8), Vector2(-24.7, -58.2),
	Vector2(15.8, -46.0), Vector2(58.5, -35.1), Vector2(67.7, -28.7), Vector2(86.1, -7.9), Vector2(133.1, 52.6)]

## The Victory Arch's butterfly plan at the north-west corner: the
## canted south-west wing, the arch front facing the corner of York
## Road and Mepham Street, the north-east wing.
const _ARCH := [Vector2(-60.7, -62.9), Vector2(-72.5, -71.9), Vector2(-64.9, -85.1),
	Vector2(-54.9, -76.7)]

## The 1922 roof over platforms 1-19: its west edge follows the island
## of platforms 19 and 20 (as it bends towards Vauxhall), its east edge
## the wall on Station Approach; both run from the concourse to the
## roof's end over the platforms.
const _MAIN_LEFT := [Vector2(-12.0, -50.0), Vector2(-30.6, -20.1), Vector2(-45.5, 0.0),
	Vector2(-64.0, 25.0), Vector2(-83.6, 50.0), Vector2(-97.0, 75.0), Vector2(-107.0, 100.0)]
const _MAIN_RIGHT := [Vector2(133.1, 52.6), Vector2(8.0, 190.0)]

## The former Waterloo International shed (Grimshaw, 1993) over
## platforms 20-24: its glazed west side on York Road and its east edge
## on the 19/20 island, from the concourse to its south end.
const _INTL_LEFT := [Vector2(-78.8, -44.2), Vector2(-130.2, 22.2), Vector2(-140.3, 42.1),
	Vector2(-150.4, 67.6), Vector2(-156.2, 88.5), Vector2(-160.4, 108.5), Vector2(-162.5, 132.9),
	Vector2(-159.0, 207.8), Vector2(-162.2, 283.2), Vector2(-162.4, 338.5)]
const _INTL_RIGHT := [Vector2(-30.6, -20.1), Vector2(-45.5, 0.0), Vector2(-64.0, 25.0),
	Vector2(-83.6, 50.0), Vector2(-97.0, 75.0), Vector2(-107.0, 100.0), Vector2(-119.4, 143.3),
	Vector2(-122.9, 187.9), Vector2(-128.0, 338.9)]

## The concourse behind the office range, between it and both sheds.
const _CONCOURSE := [Vector2(-78.8, -44.2), Vector2(-71.9, -53.4), Vector2(-60.7, -62.9),
	Vector2(-56.5, -60.8), Vector2(-36.6, -58.8), Vector2(-24.7, -58.2), Vector2(15.8, -46.0),
	Vector2(58.5, -35.1), Vector2(67.7, -28.7), Vector2(86.1, -7.9), Vector2(133.1, 52.6),
	Vector2(-12.0, -50.0), Vector2(-30.6, -20.1)]

## Past the main roof's end: the platform canopies running on south.
const _SOUTH := [Vector2(-106.0, 101.0), Vector2(40.0, 215.0), Vector2(40.0, 400.0),
	Vector2(-106.0, 400.0)]

static var OUTLINE := PackedVector2Array(_OUTLINE)
static var FRONT := PackedVector2Array(_FRONT)
static var INNER := PackedVector2Array(_INNER)
static var ARCH := PackedVector2Array(_ARCH)
static var MAIN_LEFT := PackedVector2Array(_MAIN_LEFT)
static var MAIN_RIGHT := PackedVector2Array(_MAIN_RIGHT)
static var INTL_LEFT := PackedVector2Array(_INTL_LEFT)
static var INTL_RIGHT := PackedVector2Array(_INTL_RIGHT)
static var CONCOURSE := PackedVector2Array(_CONCOURSE)
static var SOUTH := PackedVector2Array(_SOUTH)
## Every platform, packed.
static var PLATFORMS := _packed(_PLATFORMS)

static func _packed(raw: Array) -> Array:
	var out: Array = []
	for r in raw:
		out.append(PackedVector2Array(r))
	return out

## Unit normal of the edge a-b in the plane, pointing out of `poly`.
static func outward(a: Vector2, b: Vector2, poly: PackedVector2Array) -> Vector2:
	var e := (b - a).normalized()
	var n := Vector2(e.y, -e.x)
	if Geometry2D.is_point_in_polygon((a + b) * 0.5 + n * 0.5, poly):
		n = -n
	return n

static func v3(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)

## Platforms 1-24, each face of an island its own polygon.
const _PLATFORMS := [
	# 1 (636 m2)
	[Vector2(-36.4, 219.3), Vector2(1.2, 184.2), Vector2(103.4, 78.3),
		Vector2(106.5, 81.0), Vector2(3.4, 186.1), Vector2(-35.0, 220.6)],
	# 2 (616 m2)
	[Vector2(103.4, 78.3), Vector2(1.2, 184.2), Vector2(-36.4, 219.3),
		Vector2(-37.4, 217.7), Vector2(-0.7, 182.3), Vector2(100.3, 75.6)],
	# 3 (752 m2)
	[Vector2(-43.1, 211.8), Vector2(-9.9, 175.4), Vector2(91.1, 67.7),
		Vector2(94.0, 70.3), Vector2(-6.9, 178.8), Vector2(-25.4, 195.8), Vector2(-42.0, 212.7)],
	# 4 (706 m2)
	[Vector2(91.1, 67.7), Vector2(-9.9, 175.4), Vector2(-43.1, 211.8),
		Vector2(-43.9, 210.7), Vector2(-31.0, 193.1), Vector2(-13.4, 171.3), Vector2(4.0, 156.5), Vector2(87.9, 64.9)],
	# 5 (660 m2)
	[Vector2(-49.1, 203.9), Vector2(-47.5, 204.9), Vector2(-39.8, 193.9),
		Vector2(-17.9, 166.3), Vector2(-1.7, 151.7), Vector2(79.2, 57.5), Vector2(76.6, 55.2), Vector2(22.1, 118.8),
		Vector2(-20.2, 164.0)],
	# 6 (649 m2)
	[Vector2(74.0, 53.0), Vector2(18.6, 117.3), Vector2(-22.8, 161.4),
		Vector2(-36.6, 181.5), Vector2(-50.3, 203.1), Vector2(-49.1, 203.9), Vector2(-20.2, 164.0),
		Vector2(22.1, 118.8), Vector2(76.6, 55.2)],
	# 7 (882 m2)
	[Vector2(64.4, 44.7), Vector2(68.2, 48.0), Vector2(-28.4, 157.7),
		Vector2(-53.9, 196.1), Vector2(-68.2, 222.7), Vector2(-70.6, 229.2), Vector2(-71.6, 228.8),
		Vector2(-69.4, 221.9), Vector2(-62.2, 205.7), Vector2(-32.2, 156.6), Vector2(34.1, 78.9)],
	# 8 (892 m2)
	[Vector2(60.0, 41.0), Vector2(64.4, 44.7), Vector2(34.1, 78.9),
		Vector2(-32.2, 156.6), Vector2(-62.2, 205.7), Vector2(-69.4, 221.9), Vector2(-71.6, 228.8),
		Vector2(-72.6, 228.4), Vector2(-63.8, 205.3), Vector2(-49.7, 178.9), Vector2(-35.3, 154.9),
		Vector2(-18.9, 134.3)],
	# 9 (937 m2)
	[Vector2(-62.9, 183.8), Vector2(-73.1, 205.7), Vector2(-80.5, 227.7),
		Vector2(-79.8, 227.9), Vector2(-71.7, 206.3), Vector2(-61.6, 186.5), Vector2(-38.6, 147.5),
		Vector2(-18.8, 119.2), Vector2(53.8, 35.6), Vector2(50.0, 32.4), Vector2(-6.3, 96.3), Vector2(-24.7, 119.1),
		Vector2(-41.4, 145.4)],
	# 10 (925 m2)
	[Vector2(50.0, 32.4), Vector2(45.9, 28.8), Vector2(-10.4, 92.7),
		Vector2(-31.6, 123.5), Vector2(-44.5, 143.0), Vector2(-58.4, 168.8), Vector2(-70.8, 196.1),
		Vector2(-77.6, 214.3), Vector2(-81.6, 227.3), Vector2(-80.5, 227.7), Vector2(-73.1, 205.7),
		Vector2(-62.9, 183.8), Vector2(-41.4, 145.4), Vector2(-24.7, 119.1), Vector2(-6.3, 96.3)],
	# 11 (1495 m2)
	[Vector2(-86.4, 215.5), Vector2(-85.3, 215.7), Vector2(-80.1, 199.6),
		Vector2(-69.1, 175.3), Vector2(-59.9, 156.8), Vector2(-50.4, 139.4), Vector2(-37.7, 118.1),
		Vector2(-17.3, 89.0), Vector2(40.3, 24.0), Vector2(34.0, 18.5), Vector2(-24.0, 86.1), Vector2(-55.9, 132.6),
		Vector2(-68.9, 161.6), Vector2(-78.8, 186.9)],
	# 12 (1436 m2)
	[Vector2(34.0, 18.5), Vector2(27.7, 13.1), Vector2(-31.3, 84.7),
		Vector2(-60.0, 126.2), Vector2(-68.8, 144.7), Vector2(-75.3, 162.9), Vector2(-82.1, 187.9),
		Vector2(-87.4, 215.3), Vector2(-86.4, 215.5), Vector2(-78.8, 186.9), Vector2(-68.9, 161.6),
		Vector2(-56.0, 132.8), Vector2(-24.0, 86.1)],
	# 13 (997 m2)
	[Vector2(19.1, 5.7), Vector2(22.6, 8.8), Vector2(-37.6, 79.4),
		Vector2(-66.9, 123.5), Vector2(-74.9, 140.5), Vector2(-83.2, 164.8), Vector2(-88.8, 186.9),
		Vector2(-92.7, 208.5), Vector2(-94.0, 208.5), Vector2(-89.7, 177.4), Vector2(-83.4, 151.7),
		Vector2(-75.6, 131.1), Vector2(-71.4, 121.7), Vector2(-40.4, 75.9), Vector2(-15.6, 45.5)],
	# 14 (859 m2)
	[Vector2(-95.2, 208.5), Vector2(-94.0, 208.5), Vector2(-89.7, 177.3),
		Vector2(-83.4, 151.7), Vector2(-75.6, 131.1), Vector2(-71.4, 121.7), Vector2(-40.4, 75.9),
		Vector2(-15.6, 45.5), Vector2(19.1, 5.7), Vector2(15.3, 2.5), Vector2(-43.3, 73.7), Vector2(-74.6, 119.3),
		Vector2(-79.8, 130.7), Vector2(-83.8, 141.7), Vector2(-87.1, 152.1), Vector2(-89.9, 163.5),
		Vector2(-93.4, 184.9)],
	# 15 (873 m2)
	[Vector2(-103.2, 208.3), Vector2(-101.6, 208.4), Vector2(-99.3, 178.1),
		Vector2(-96.0, 158.9), Vector2(-90.6, 139.5), Vector2(-83.7, 122.5), Vector2(-80.2, 116.0),
		Vector2(-49.2, 70.4), Vector2(9.0, -3.0), Vector2(6.0, -5.5), Vector2(-53.0, 67.8), Vector2(-83.8, 114.3),
		Vector2(-93.7, 139.2), Vector2(-99.7, 164.9), Vector2(-101.5, 179.1)],
	# 16 (796 m2)
	[Vector2(6.0, -5.5), Vector2(2.6, -8.4), Vector2(-56.5, 66.2),
		Vector2(-86.5, 112.7), Vector2(-94.9, 135.0), Vector2(-100.6, 157.9), Vector2(-103.3, 177.2),
		Vector2(-104.8, 208.2), Vector2(-103.2, 208.3), Vector2(-101.5, 179.1), Vector2(-99.7, 164.9),
		Vector2(-93.7, 139.2), Vector2(-83.8, 114.3), Vector2(-53.0, 67.8)],
	# 17 (775 m2)
	[Vector2(-113.0, 215.7), Vector2(-111.5, 215.7), Vector2(-110.1, 177.1),
		Vector2(-107.8, 159.5), Vector2(-103.5, 140.1), Vector2(-98.2, 123.5), Vector2(-92.8, 110.0),
		Vector2(-74.3, 79.8), Vector2(-62.8, 62.2), Vector2(-43.4, 35.3), Vector2(-17.4, 2.9), Vector2(-4.6, -14.7),
		Vector2(-7.5, -17.1), Vector2(-65.1, 58.2), Vector2(-75.5, 74.0), Vector2(-94.9, 107.6),
		Vector2(-105.7, 140.3), Vector2(-107.9, 150.2), Vector2(-111.6, 176.2)],
	# 18 (758 m2)
	[Vector2(-10.4, -19.7), Vector2(-31.8, 9.2), Vector2(-51.4, 33.1),
		Vector2(-68.7, 56.6), Vector2(-78.5, 72.2), Vector2(-88.2, 90.8), Vector2(-98.0, 106.6),
		Vector2(-104.5, 128.3), Vector2(-109.5, 150.0), Vector2(-110.9, 158.7), Vector2(-113.9, 186.0),
		Vector2(-114.4, 215.7), Vector2(-113.0, 215.7), Vector2(-111.6, 176.2), Vector2(-107.9, 150.2),
		Vector2(-105.7, 140.3), Vector2(-94.9, 107.6), Vector2(-75.5, 74.0), Vector2(-65.1, 58.2),
		Vector2(-7.5, -17.1)],
	# 19 (1451 m2)
	[Vector2(-128.3, 373.0), Vector2(-126.4, 372.5), Vector2(-127.0, 328.6),
		Vector2(-123.0, 289.3), Vector2(-120.0, 179.7), Vector2(-118.2, 162.2), Vector2(-112.3, 132.1),
		Vector2(-102.5, 101.4), Vector2(-96.3, 85.4), Vector2(-80.9, 53.2), Vector2(-52.0, 15.9),
		Vector2(-29.3, -14.7), Vector2(-32.7, -17.3), Vector2(-85.7, 52.6), Vector2(-99.9, 78.8),
		Vector2(-112.5, 115.3), Vector2(-121.5, 159.3), Vector2(-123.0, 217.2), Vector2(-125.9, 289.7),
		Vector2(-129.6, 328.7), Vector2(-129.6, 346.1)],
	# 20 (1392 m2)
	[Vector2(-35.7, -19.6), Vector2(-90.3, 51.9), Vector2(-105.8, 77.3),
		Vector2(-117.1, 118.1), Vector2(-124.2, 158.8), Vector2(-124.8, 217.3), Vector2(-132.1, 329.7),
		Vector2(-132.2, 347.5), Vector2(-130.5, 373.4), Vector2(-128.3, 373.0), Vector2(-129.6, 346.1),
		Vector2(-129.6, 328.7), Vector2(-125.9, 289.7), Vector2(-123.0, 217.2), Vector2(-121.5, 159.3),
		Vector2(-112.5, 115.5), Vector2(-100.0, 79.0), Vector2(-85.7, 52.6), Vector2(-32.7, -17.3)],
	# 21 (1276 m2)
	[Vector2(-141.3, 360.8), Vector2(-142.5, 343.1), Vector2(-138.8, 195.9),
		Vector2(-138.3, 126.3), Vector2(-135.2, 98.7), Vector2(-126.8, 72.1), Vector2(-123.5, 63.9),
		Vector2(-114.8, 47.6), Vector2(-105.7, 34.3), Vector2(-49.5, -31.7), Vector2(-46.6, -29.2),
		Vector2(-83.6, 16.5), Vector2(-109.8, 47.8), Vector2(-123.5, 72.7), Vector2(-131.7, 102.4),
		Vector2(-134.7, 127.2), Vector2(-136.2, 153.0), Vector2(-140.5, 342.9), Vector2(-140.0, 358.4),
		Vector2(-140.1, 360.8)],
	# 22 (1265 m2)
	[Vector2(-49.5, -31.7), Vector2(-105.7, 34.3), Vector2(-114.8, 47.6),
		Vector2(-123.5, 63.9), Vector2(-126.8, 72.2), Vector2(-135.2, 98.7), Vector2(-138.3, 126.3),
		Vector2(-138.8, 195.9), Vector2(-142.5, 343.1), Vector2(-141.3, 360.8), Vector2(-142.7, 360.9),
		Vector2(-144.3, 343.6), Vector2(-141.0, 195.7), Vector2(-141.9, 126.4), Vector2(-138.7, 97.1),
		Vector2(-127.4, 62.8), Vector2(-109.1, 32.0), Vector2(-91.8, 10.8), Vector2(-52.3, -34.2)],
	# 23 (1234 m2)
	[Vector2(-63.5, -44.1), Vector2(-122.9, 27.6), Vector2(-137.4, 56.6),
		Vector2(-144.2, 75.0), Vector2(-149.8, 97.1), Vector2(-153.8, 123.0), Vector2(-153.9, 149.9),
		Vector2(-151.3, 188.8), Vector2(-153.6, 317.9), Vector2(-150.7, 318.0), Vector2(-148.1, 188.2),
		Vector2(-150.5, 152.7), Vector2(-150.5, 135.0), Vector2(-149.4, 114.5), Vector2(-146.7, 96.5),
		Vector2(-140.9, 75.5), Vector2(-126.9, 40.8), Vector2(-119.0, 27.9), Vector2(-61.0, -41.9)],
	# 24 (1234 m2)
	[Vector2(-63.5, -44.1), Vector2(-65.8, -46.1), Vector2(-116.7, 14.5),
		Vector2(-126.8, 27.6), Vector2(-140.9, 58.1), Vector2(-147.2, 75.1), Vector2(-152.4, 97.0),
		Vector2(-157.1, 123.9), Vector2(-156.8, 153.6), Vector2(-154.5, 188.3), Vector2(-154.3, 208.1),
		Vector2(-155.9, 240.6), Vector2(-156.9, 317.8), Vector2(-153.6, 317.9), Vector2(-152.4, 235.6),
		Vector2(-151.3, 208.4), Vector2(-151.3, 189.3), Vector2(-153.9, 149.9), Vector2(-153.8, 123.5),
		Vector2(-149.8, 97.4), Vector2(-144.2, 75.0), Vector2(-137.4, 56.6), Vector2(-122.9, 27.6)],
]
