class_name LandmarkCsAsia
extends RefCounted

## Capital stations of Asia in the station frame (+X along the main
## facade, +Z the forecourt): Tokyo Station, the old Seoul Station,
## Beijing railway station, New Delhi, the old Kuala Lumpur station,
## Bangkok's Hua Lamphong, Taipei Main Station and Tehran.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Tatsuno Kingo's Marunouchi building of Tokyo Station (1914, restored
## 2012): the 335 m red brick range banded in white stone, three storeys
## under slate roofs, the central pavilion, and the north and south
## octagonal domed halls (35 m) at either end; the tracks run behind it.
static func tokyo_station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#9B4A35", "#E3DBCB", "slate", "#3E454C")
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 55.0, 0.0, 86.0, 20.0, 0.0, 17.0, "hip", 4.5, 4.0, 5.0, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 145.0, 0.0, 44.0, 20.0, 0.0, 17.0, "hip", 4.5, 4.0, 5.0, true)
		var c := Vector3(s * 108.0, 0, 1.5)
		lm.lathe("Walls", c, PackedVector2Array([Vector2(16.0, 0.0), Vector2(16.0, 21.0)]), 8, 1.0, 1.0, PI / 8.0, false)
		lm.lathe("Trim", c + Vector3.UP * 20.0, PackedVector2Array([Vector2(16.8, 0.0), Vector2(16.8, 1.0)]), 8, 1.0,
			1.0, PI / 8.0, false)
		lm.lathe("Roof", c + Vector3.UP * 21.0, PackedVector2Array([Vector2(16.5, 0.0), Vector2(13.0, 5.0),
			Vector2(8.0, 9.0), Vector2(3.0, 11.0), Vector2(1.2, 11.6)]), 8, 1.0, 1.0, PI / 8.0, false)
		lm.frustum("Trim", c + Vector3.UP * 32.6, 0.6, 0.2, 2.4, 8)
		for k in 8:
			var a := TAU * (float(k) + 0.5) / 8.0
			var n := Vector3(sin(a), 0, cos(a))
			if n.z < -0.3:
				continue
			K.arch_window(lm, "Trim", "Glass", c + n * 14.85 + Vector3.UP * 4.0, n, 3.0, 8.0, 1)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.0, 24.0, 22.0, 0.0, 19.0, "hip", 6.0, 4.0, 5.0, true)
	for y in [6.0, 11.0]:
		LandmarkFhParts.band(lm, "Trim", Vector3(-167, 0, 10.05), Vector3(167, 0, 10.05), Vector3.BACK, y, 0.6, 0.2)
	for i in 3:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-160, 6.0, -18.0 - 14.0 * float(i)), Vector3.RIGHT, 11.0, 320.0,
			5.0, 1.2, 12.0, 0.2, 0)
	lm.commit(model)

## The old Seoul Station (Tsukamoto Yasushi, 1925), now Culture Station
## Seoul 284: red brick on a pale granite ground storey with granite
## bands, dark slate roofs, the central Byzantine dome of green copper on
## its drum between four copper-capped turrets, and the gabled end
## pavilions with their small green-domed turrets.
static func old_seoul_station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#A55A40", "#D9D2C3", "slate", "#4A4C50")
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#6E9A86", 2.0))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 82.0, 22.0, 0.0, 12.0, "hip", 3.0, 3.6, 4.8, true)
	lm.box("Trim", Vector3(0, 2.0, 0), Vector3(82.6, 4.0, 22.6))
	LandmarkFhParts.box_band(lm, "Trim", 0.0, 0.0, 82.0, 22.0, 8.0, 0.5, 0.25)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.0, 26.0, 26.0, 0.0, 15.0, "flat", 0.0, 3.5, 5.0, true)
	var c := Vector3(0, 15.0, 1.0)
	lm.lathe("Walls", c, PackedVector2Array([Vector2(7.5, 0.0), Vector2(7.5, 3.5)]), 16)
	lm.lathe("Copper", c + Vector3.UP * 3.5, LandmarkFhUtil.dome_prof(8.0, 6.0), 20)
	lm.lathe("Copper", c + Vector3.UP * 9.5, PackedVector2Array([Vector2(1.0, 0.0), Vector2(1.0, 1.5),
		Vector2(0.0, 2.5)]), 8)
	for s in [-1.0, 1.0]:
		for z in [13.0, -11.0]:
			var t := Vector3(s * 11.5, 15.0, z)
			lm.box("Walls", t + Vector3.UP * 2.0, Vector3(3.0, 4.0, 3.0))
			lm.lathe("Copper", t + Vector3.UP * 4.0, LandmarkFhUtil.dome_prof(1.8, 1.8), 10)
		# The end pavilions: gabled, a little proud, with a turret.
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 41.0, 1.5, 10.0, 25.0, 0.0, 13.0, "gable_z", 3.0, 3.4, 4.8, true)
		var e := Vector3(s * 41.0, 16.0, 12.0)
		lm.box("Walls", e + Vector3.UP * 1.5, Vector3(2.4, 3.0, 2.4))
		lm.lathe("Copper", e + Vector3.UP * 3.0, LandmarkFhUtil.dome_prof(1.5, 1.5), 10)
	K.clock(lm, "Dial", "Trim", Vector3(0, 12.0, 14.1), Vector3.BACK, 1.3)
	lm.commit(model)

## Beijing railway station (1959): the long warm-tan front with its
## central waiting hall, a three-bay glazed screen under a shallow curved
## roof, between the two 43 m clock towers whose clocks sit high under
## double-eaved pavilion roofs of green glazed tile with yellow trim; the
## smaller pavilion roofs on the inner wing ends and the corners.
static func beijing_station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D6B98A", "#E8D27A", "terracotta", "#4F7A5A")
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 62.0, 0.0, 80.0, 34.0, 0.0, 18.0, "flat", 0.0, 4.0, 5.0, true)
		_pavilion(lm, Vector3(s * 98.0, 18.0, 0.0), 14.0, 7.0)
		_pavilion(lm, Vector3(s * 34.0, 18.0, 8.0), 9.0, 5.0)
		var t := Vector3(s * 22.0, 0, 8.0)
		lm.box("Walls", t + Vector3.UP * 16.5, Vector3(8.0, 33.0, 8.0))
		lm.box("Trim", t + Vector3.UP * 20.5, Vector3(8.8, 0.6, 8.8))
		for i in 4:
			var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
			K.clock(lm, "Dial", "Trim", t + n * 4.0 + Vector3.UP * 29.5, n, 2.0)
		_pavilion(lm, t + Vector3.UP * 33.0, 9.0, 4.5)
		_pavilion(lm, t + Vector3.UP * 37.5, 6.0, 5.5)
	# The waiting hall: a rectangular three-bay glazed screen, its piers
	# and the shallow curved roof over it.
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 34.0, 40.0, 0.0, 22.0, "barrel", 4.0, 4.0, 5.0)
	lm.box("Glass", Vector3(0, 10.5, 20.06), Vector3(28.0, 18.0, 0.1), Basis(), 0.0)
	LandmarkFhParts.strips(lm, "Trim", Vector3(-14, 0, 20.1), Vector3(14, 0, 20.1), Vector3.BACK, 0.0, 20.0, 4, 1.4, 0.8)
	LandmarkFhParts.ribs(lm, "Trim", Vector3(-13, 0, 20.12), Vector3(13, 0, 20.12), Vector3.BACK, 1.5, 19.5, 2.2, 0.2, 0.2)
	lm.commit(model)

## A Chinese hipped pavilion roof `w` square at `base`, `h` tall with
## upturned eaves: a wide flared skirt, then the steep upper hip.
static func _pavilion(lm: LandmarkMesh, base: Vector3, w: float, h: float) -> void:
	lm.box("Trim", base + Vector3.UP * 0.4, Vector3(w, 0.8, w))
	LandmarkFhUtil.hip(lm, "Roof", base + Vector3.UP * 0.8, w * 1.45, w * 1.45, h * 0.3, 0.7)
	LandmarkFhUtil.hip(lm, "Roof", base + Vector3.UP * (0.8 + h * 0.3), w * 1.0, w * 1.0, h * 0.7 - 0.8, 0.12)

## New Delhi railway station (Paharganj side): the long red concourse
## whose front is a two-storey colonnade of white square pillars with
## recessed panels between them under a white cornice, the taller entrance
## block, and the platform canopies behind.
static func new_delhi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#B8443C", "#EDE9E1", "roof_concrete", "#8A857C")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 180.0, 22.0, 0.0, 14.0, "flat", 0.0, 4.5, 5.0)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.0, 36.0, 24.0, 0.0, 20.0, "flat", 0.0, 4.0, 5.0)
	LandmarkFhParts.strips(lm, "Trim", Vector3(-89, 0, 11.0), Vector3(89, 0, 11.0), Vector3.BACK, 0.0, 13.0, 31, 1.2, 1.4)
	LandmarkFhParts.strips(lm, "Trim", Vector3(-17, 0, 13.0), Vector3(17, 0, 13.0), Vector3.BACK, 0.0, 19.0, 7, 1.4, 1.4)
	lm.box("Trim", Vector3(0, 13.6, 12.0), Vector3(182.0, 0.8, 1.8))
	lm.box("Trim", Vector3(0, 19.6, 13.6), Vector3(38.0, 0.8, 1.8))
	K.clock(lm, "Dial", "Trim", Vector3(0, 16.5, 14.5), Vector3.BACK, 1.5)
	LandmarkFhUtil.columns(lm, "Trim", Vector3(-12, 0, 19.0), Vector3(12, 0, 19.0), 6, 8.0, 0.6)
	lm.box("Trim", Vector3(0, 8.5, 16.5), Vector3(27.0, 1.0, 6.0))
	for i in 6:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-150, 0, -20.0 - 13.0 * float(i)), Vector3.RIGHT, 10.0, 300.0, 5.0,
			1.0, 12.0, 0.2, 0)
	lm.commit(model)

## A. B. Hubback's Kuala Lumpur railway station (1910): white plaster in
## the Indo-Saracenic manner, three storeys (18 m) of deep verandah
## arcades of horseshoe-headed arches stacked on both long fronts, the
## projecting pavilions every 30 m crowned by chhatris, the central
## pavilion with its tall open chhatri and onion dome (35 m), and the
## slender minarets along the roofline.
static func kuala_lumpur_station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#EDE7DA", "#F7F4EC", "render", "#F1EDE4")
	lm.box("Walls", Vector3(0, 9.0, 0), Vector3(190.0, 18.0, 20.0))
	lm.box("Trim", Vector3(0, 17.7, 0), Vector3(191.0, 0.6, 21.0))
	for s in [-1.0, 1.0]:
		var z: float = s * 10.05
		for y in [0.6, 6.6, 12.6]:
			K.arch_row(lm, "Trim", "Glass", Vector3(-94, 0, z), Vector3(94, 0, z), Vector3(0, 0, s), y, 40, 3.2, 5.0, 0)
		for y in [6.0, 12.0]:
			LandmarkFhParts.band(lm, "Trim", Vector3(-95, 0, z), Vector3(95, 0, z), Vector3(0, 0, s), y, 0.4, 0.6)
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-95, 18.0, 10.0), Vector3(95, 18.0, 10.0), 1.4, 0.7, 0.8, 0.4)
	for x in [-90.0, -60.0, -30.0, 30.0, 60.0, 90.0]:
		var c := Vector3(x, 0, 1.5)
		lm.box("Walls", c + Vector3.UP * 11.0, Vector3(10.0, 22.0, 23.0))
		K.arch_row(lm, "Trim", "Glass", c + Vector3(-4.5, 0, 11.55), c + Vector3(4.5, 0, 11.55), Vector3.BACK, 0.6, 2, 3.2,
			8.0, 0)
		_chhatri(lm, c + Vector3.UP * 22.0, 3.2, 8.0)
		for sx in [-1.0, 1.0]:
			_minaret(lm, c + Vector3(sx * 5.0, 22.0, 11.5), 6.0)
	# The central pavilion and its great chhatri.
	var m := Vector3(0, 0, 2.0)
	lm.box("Walls", m + Vector3.UP * 12.0, Vector3(16.0, 24.0, 24.0))
	K.arch_window(lm, "Trim", "Glass", m + Vector3(0, 0.6, 12.05), Vector3.BACK, 7.0, 13.0, 2)
	_chhatri(lm, m + Vector3.UP * 24.0, 5.5, 11.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_minaret(lm, m + Vector3(sx * 7.5, 24.0, sz * 11.5), 7.0)
	K.canopy(lm, "Roof", "Steel", Vector3(-80, 0, -10.5), Vector3(80, 0, -10.5), Vector3.FORWARD, 10.0, 5.0, 12)
	lm.commit(model)

## An open chhatri on `base`: eight columns on a ring of radius `r`, a
## drum, and an onion dome with its finial, `h` tall overall.
static func _chhatri(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.frustum("Walls", base + Vector3(cos(a) * r, 0, sin(a) * r), 0.3, 0.25, h * 0.38, 6)
	lm.lathe("Walls", base + Vector3.UP * h * 0.38, PackedVector2Array([Vector2(r * 1.12, 0.0), Vector2(r * 1.12, h * 0.07),
		Vector2(r * 0.85, h * 0.12)]), 16)
	LandmarkFhUtil.onion(lm, "Roof", base + Vector3.UP * h * 0.5, r * 0.95, h * 0.42, 16)
	lm.frustum("Gilt", base + Vector3.UP * h * 0.92, 0.15, 0.04, h * 0.08, 6)

## A slender white minaret `h` tall on `base` with its little onion cap.
static func _minaret(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.frustum("Walls", base, 0.6, 0.45, h * 0.7, 8)
	lm.lathe("Walls", base + Vector3.UP * h * 0.7, PackedVector2Array([Vector2(0.75, 0.0), Vector2(0.75, h * 0.05)]), 8)
	LandmarkFhUtil.onion(lm, "Roof", base + Vector3.UP * h * 0.75, 0.6, h * 0.25, 8)

## Bangkok's Hua Lamphong (Mario Tamagno, 1916): the yellow Italian
## neo-Renaissance front, its great arched hall end under the ochre-gold
## barrel roof with the clock in the lunette and a colonnade at its foot,
## and the low wings along the front ending in two-storey pavilions with
## balustrades.
static func hua_lamphong(model: Node3D) -> void:
	LandmarkBkHuaLamphong.build(model)

## Taipei Main Station (1989): the pale grey palace-style block with
## banded glazing between its columns, the broad lower eave band of
## orange-brown glazed tile, the raised upper block over the middle half
## with its own hipped roof and upswept eaves, and the square portals of
## the entrances.
static func taipei_main(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D8D8D0", "#E6E6DF", "terracotta", "#C46A35")
	lm.box("Walls", Vector3(0, 11.0, 0), Vector3(190.0, 22.0, 140.0))
	for y in [5.0, 9.5, 14.0, 18.5]:
		lm.box("Glass", Vector3(0, y, 0), Vector3(190.2, 2.2, 140.2), Basis(), 0.0)
	for face in LandmarkFhParts.faces(0.0, 0.0, 190.0, 140.0):
		var a: Vector3 = face[0]
		var b: Vector3 = face[1]
		var o: Vector3 = face[2]
		LandmarkFhParts.strips(lm, "Trim", a, b, o, 0.0, 22.0, int(a.distance_to(b) / 8.0) + 1, 1.0, 0.5)
		var m := (a + b) * 0.5 + o * 0.6
		var along_x := absf(o.z) > 0.5
		lm.box("Glass", m + Vector3.UP * 5.0, Vector3(14.0, 10.0, 1.2) if along_x else Vector3(1.2, 10.0, 14.0),
			Basis(), 0.0)
		lm.box("Trim", m + Vector3.UP * 10.6, Vector3(17.0, 1.2, 2.0) if along_x else Vector3(2.0, 1.2, 17.0))
	LandmarkFhUtil.hip(lm, "Roof", Vector3(0, 22.0, 0), 200.0, 150.0, 4.0, 0.62)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 96.0, 70.0, 26.0, 6.0, "flat", 0.0, 4.0, 3.0)
	LandmarkFhUtil.hip(lm, "Roof", Vector3(0, 32.0, 0), 106.0, 80.0, 5.0, 0.25)
	lm.commit(model)

## Tehran railway station (1939): the long symmetrical stone front on Rah
## Ahan Square with its tall central hall of three great arched windows,
## the clock and flagpole over it, and the wings either side.
static func tehran_station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#CBBE9F", "#DED3BC", "roof_concrete", "#8A847A")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 40.0, 30.0, 0.0, 22.0, "flat", 0.0, 4.0, 5.0)
	K.arch_row(lm, "Trim", "Glass", Vector3(-15, 0, 15.05), Vector3(15, 0, 15.05), Vector3.BACK, 2.0, 3, 6.5, 15.0, 2)
	K.clock(lm, "Dial", "Trim", Vector3(0, 19.6, 15.2), Vector3.BACK, 1.4)
	lm.box("Trim", Vector3(0, 23.0, 14.0), Vector3(10.0, 2.0, 2.0))
	lm.box("Steel", Vector3(0, 26.0, 14.0), Vector3(0.2, 4.0, 0.2), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 55.0, -2.0, 70.0, 24.0, 0.0, 13.0, "flat", 0.0, 4.0, 4.5, true)
	lm.commit(model)
