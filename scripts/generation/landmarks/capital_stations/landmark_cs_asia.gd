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
## Seoul 284: red brick with granite dressings, the central Byzantine
## dome of green copper on its drum between the turrets.
static func old_seoul_station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#A55A40", "#D8CDB8", "copper", "#5E8C7A")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 82.0, 22.0, 0.0, 12.0, "hip", 3.0, 3.6, 4.8, true)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.0, 26.0, 26.0, 0.0, 15.0, "flat", 0.0, 3.5, 5.0, true)
	var c := Vector3(0, 15.0, 1.0)
	lm.lathe("Walls", c, PackedVector2Array([Vector2(7.5, 0.0), Vector2(7.5, 3.5)]), 16)
	lm.lathe("Roof", c + Vector3.UP * 3.5, LandmarkFhUtil.dome_prof(8.0, 6.0), 20)
	lm.lathe("Roof", c + Vector3.UP * 9.5, PackedVector2Array([Vector2(1.0, 0.0), Vector2(1.0, 1.5),
		Vector2(0.0, 2.5)]), 8)
	for s in [-1.0, 1.0]:
		var t := Vector3(s * 11.5, 15.0, 13.0)
		lm.box("Walls", t + Vector3.UP * 2.0, Vector3(3.0, 4.0, 3.0))
		lm.lathe("Roof", t + Vector3.UP * 4.0, LandmarkFhUtil.dome_prof(1.8, 1.8), 10)
	K.clock(lm, "Dial", "Trim", Vector3(0, 12.0, 14.1), Vector3.BACK, 1.3)
	lm.commit(model)

## Beijing railway station (1959): the long hall front with its central
## glazed arch-roofed waiting hall and the two 43 m clock towers under
## double-eaved pavilion roofs of glazed green tile, the corner pavilions.
static func beijing_station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D7C8A6", "#E5DCC8", "terracotta", "#4F7A5A")
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 62.0, 0.0, 80.0, 34.0, 0.0, 18.0, "flat", 0.0, 4.0, 5.0, true)
		_pavilion(lm, Vector3(s * 98.0, 18.0, 0.0), 14.0, 7.0)
		var t := Vector3(s * 22.0, 0, 8.0)
		lm.box("Walls", t + Vector3.UP * 15.5, Vector3(10.0, 31.0, 10.0))
		for i in 4:
			var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
			K.clock(lm, "Dial", "Trim", t + n * 5.0 + Vector3.UP * 27.0, n, 2.2)
		_pavilion(lm, t + Vector3.UP * 31.0, 11.0, 6.0)
		_pavilion(lm, t + Vector3.UP * 37.0, 7.0, 6.0)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 34.0, 40.0, 0.0, 22.0, "barrel", 8.0, 4.0, 5.0)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 1.0, 20.05), Vector3.BACK, 24.0, 20.0, 6, 1.2)
	lm.commit(model)

## A Chinese hipped pavilion roof `w` square at `base`, `h` tall with
## upturned eaves: a wide flared skirt, then the steep upper hip.
static func _pavilion(lm: LandmarkMesh, base: Vector3, w: float, h: float) -> void:
	lm.box("Trim", base + Vector3.UP * 0.4, Vector3(w, 0.8, w))
	LandmarkFhUtil.hip(lm, "Roof", base + Vector3.UP * 0.8, w * 1.45, w * 1.45, h * 0.3, 0.7)
	LandmarkFhUtil.hip(lm, "Roof", base + Vector3.UP * (0.8 + h * 0.3), w * 1.0, w * 1.0, h * 0.7 - 0.8, 0.12)

## New Delhi railway station (Paharganj side): the long red sandstone-clad
## concourse with its arcade of round-headed openings and the taller
## entrance block, the platform canopies behind.
static func new_delhi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#A8543A", "#D8C7A8", "roof_concrete", "#8A857C")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 180.0, 22.0, 0.0, 14.0, "flat", 0.0, 4.5, 5.0, true)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.0, 36.0, 24.0, 0.0, 20.0, "flat", 0.0, 4.0, 5.0, true)
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-18, 20.0, 13.0), Vector3(18, 20.0, 13.0), 2.4, 1.2, 1.2, 0.5)
	K.clock(lm, "Dial", "Trim", Vector3(0, 16.5, 13.3), Vector3.BACK, 1.5)
	for i in 6:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-150, 0, -20.0 - 13.0 * float(i)), Vector3.RIGHT, 10.0, 300.0, 5.0,
			1.0, 12.0, 0.2, 0)
	lm.commit(model)

## A. B. Hubback's Kuala Lumpur railway station (1910): white plaster in
## the Indo-Saracenic manner, the long arcaded range with its chhatris,
## horseshoe arches and the onion-domed corner and centre towers.
static func kuala_lumpur_station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#EDE7DA", "#F4F0E6", "render", "#EFEBE2")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 190.0, 18.0, 0.0, 12.0, "flat", 0.0, 4.2, 5.5, true)
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-95, 12.0, 9.0), Vector3(95, 12.0, 9.0), 1.6, 0.8, 0.9, 0.4)
	for x in [-90.0, -60.0, -30.0, 0.0, 30.0, 60.0, 90.0]:
		var big: bool = absf(x) < 1.0 or absf(x) > 89.0
		var w := 7.0 if big else 4.0
		var top := 12.0 if not big else 18.0
		var c := Vector3(x, 0, 7.0)
		if big:
			lm.box("Walls", c + Vector3.UP * top * 0.5, Vector3(w, top, w))
		lm.lathe("Walls", c + Vector3.UP * top, PackedVector2Array([Vector2(w * 0.45, 0.0), Vector2(w * 0.45, 2.5)]), 8)
		LandmarkFhUtil.onion(lm, "Roof", c + Vector3.UP * (top + 2.5), w * 0.55, w * 1.2, 12)
		lm.frustum("Gilt", c + Vector3.UP * (top + 2.5 + w * 1.2), 0.15, 0.05, 1.2, 6)
	K.canopy(lm, "Roof", "Steel", Vector3(-80, 0, -9.0), Vector3(80, 0, -9.0), Vector3.FORWARD, 10.0, 5.0, 12)
	lm.commit(model)

## Bangkok's Hua Lamphong (Mario Tamagno, 1916): the Italian neo-
## Renaissance front with its arched glazed hall end and the clock in the
## lunette, the two-storey wings with their terraces, the hall roof behind.
static func hua_lamphong(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#DCCDAA", "#EAE0CB", "sheet_metal", "#8D9294")
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 0, 0), Vector3.FORWARD, 44.0, 120.0, 12.0, 14.0, 10.0, 0.2, 1)
	lm.box("Walls", Vector3(0, 6.0, 1.0), Vector3(46.0, 12.0, 4.0))
	K.lunette(lm, "Trim", "Glass", Vector3(0, 12.0, 1.1), Vector3.BACK, 44.0, 14.0, 12, 9)
	K.clock(lm, "Dial", "Trim", Vector3(0, 19.0, 1.6), Vector3.BACK, 2.0)
	K.arch_row(lm, "Trim", "Glass", Vector3(-18, 0, 3.05), Vector3(18, 0, 3.05), Vector3.BACK, 0.6, 5, 4.0, 9.0, 1)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 48.0, -3.0, 50.0, 18.0, 0.0, 12.0, "flat", 0.0, 4.2, 5.5, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 26.0, -50.0, 8.0, 100.0, 0.0, 10.0, "flat", 0.0, 4.2, 5.0, true)
	lm.commit(model)

## Taipei Main Station (1989): the six-storey palace-style block of pale
## stone and the hipped roof of glazed tile, and the four great arched
## gateways under it.
static func taipei_main(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#CFC6B4", "#E0D9CB", "terracotta", "#B06F3C")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 190.0, 140.0, 0.0, 25.0, "flat", 0.0, 5.0, 4.5)
	LandmarkFhUtil.hip(lm, "Roof", Vector3(0, 25.0, 0), 198.0, 148.0, 8.0, 0.75)
	for face in LandmarkFhParts.faces(0.0, 0.0, 190.0, 140.0):
		var a: Vector3 = face[0]
		var b: Vector3 = face[1]
		K.arch_window(lm, "Trim", "Glass", (a + b) * 0.5 + (face[2] as Vector3) * 0.05 + Vector3.UP * 0.5,
			face[2], 16.0, 18.0, 4, 1.2)
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
