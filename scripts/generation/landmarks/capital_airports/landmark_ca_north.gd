class_name LandmarkCaNorth
extends RefCounted

## Capital airfields of northern Europe in the airfield frame (+X along the
## longest runway, +Z to its right, origin at the terminal's centre): the
## layouts are measured from OpenStreetMap (CaLayout*), the terminals, tower
## and parked aircraft are authored here.

const K = preload("res://scripts/generation/landmarks/capital_airports/landmark_airfield_kit.gd")

## Reykjavik Airport (Vatnsmýri, 1.5 km from the centre): two crossing
## asphalt runways (01/19 and 13/31), a domestic terminal and the airport
## building in white-rendered low blocks, the old control tower ("Gamli
## Flugturninn") and a long row of numbered hangars on the east side, where
## the Icelandic Coast Guard and the general-aviation operators stand.
static func reykjavik(model: Node3D) -> void:
	var d: Dictionary = CaLayoutReykjavik.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E6E4DC", "membrane", "#6A6F73")
	K.surfaces(lm, d)
	K.buildings(lm, d, [], {"Gamli Flugturninn": 12.0})
	K.terminal_set(lm, d, {"_big": [7.5, 2, 0.8], "_small": [5.0, 1]})
	K.park(lm, d, [["turboprop", "#0B3560"], ["turboprop", "#0B3560"], ["light", "#B3262C"]], 4)
	lm.commit(model)

## Tallinn's Lennart Meri Airport: one 3,070 m runway (08/26) beside a single
## three-storey, 21 m terminal under a flat white roof, its long glazed front
## facing the apron, with Baltic narrowbodies and turboprops on the stands.
static func tallinn(model: Node3D) -> void:
	var d: Dictionary = CaLayoutTallinn.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E9EBEC", "membrane", "#8A9096")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {"Lennart Meri Tallinna lennujaam": [21.0, 3, 1.2], "_big": [12.0, 2], "_small": [5.0, 1]})
	K.towers(lm, d, 30.0)
	K.park(lm, d, [["narrow", "#1E4D9B"], ["narrow", "#1E4D9B"], ["turboprop", "#C8102E"], ["narrow", "#073590"]], 10)
	lm.commit(model)

## Stockholm Bromma, Paul Hedqvist's 1936 functionalist airport: the pale
## rendered terminal of three storeys with its ribbon windows and the white
## control tower beside it, one 1,668 m runway (12/30) on the western shore
## of Lake Mälaren, and regional jets and turboprops on the apron.
static func stockholm(model: Node3D) -> void:
	var d: Dictionary = CaLayoutStockholm.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E9E3D3", "membrane", "#7C8084")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {"Bromma flygplats": [14.0, 3, 0.9], "_big": [10.0, 2], "_small": [5.0, 1]})
	K.towers(lm, d, 26.0, 2.6, 4.0, 3.0)
	K.park(lm, d, [["narrow", "#0B2D6B"], ["turboprop", "#C8102E"], ["narrow", "#0B2D6B"], ["turboprop", "#1B6FB8"]], 10)
	lm.commit(model)

## Vilnius Airport: the 1980 terminal's long glazed concourse and the
## departures block, one 2,500 m runway (02/20) running past it, with
## Baltic and low-cost narrowbodies parked on the apron.
static func vilnius(model: Node3D) -> void:
	var d: Dictionary = CaLayoutVilnius.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#DAD7CE", "membrane", "#767B80")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {"VNO išvykimo terminalas": [12.0, 3, 1.0], "_big": [13.0, 3, 1.0], "_small": [5.0, 1]})
	K.towers(lm, d, 36.0)
	K.park(lm, d, [["narrow", "#073590"], ["narrow", "#C6007E"], ["narrow", "#1E4D9B"], ["turboprop", "#C8102E"]], 8)
	lm.commit(model)

## Copenhagen Airport on Amager, the largest airfield of the batch: two
## parallel 3,300-3,500 m runways (04L/22R, 04R/22L) crossed by 12/30, the
## 1939 Vilhelm Lauritzen Terminal (white, functionalist) beside Terminal 2
## (1960) and Terminal 3 (glass and steel under a broad roof carried on tall
## columns, with rows of skylights), Fingers A, B, C and E and CPH Go reaching
## onto the apron with boarding bridges, and the slender 70 m concrete control
## tower of 2008 with its flared glass cab south-east of the runways.
static func copenhagen(model: Node3D) -> void:
	var d: Dictionary = CaLayoutCopenhagen.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E4E4E0", "membrane", "#8B9094")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {
		"Terminal 3 Københavns Lufthavn": [14.0, 3, 2.5, 5.0, 14.0],
		"Terminal 2 Københavns Lufthavn": [12.0, 3, 1.5],
		"Vilhelm Lauritzen Terminalen": [8.5, 2, 0.8],
		"Finger A": [7.5, 2, 1.0], "Finger B": [10.8, 3, 1.0], "Finger C": [8.0, 2, 1.0],
		"Finger E": [14.0, 3, 1.2, 4.0, 12.0], "CPH Go": [14.4, 4, 1.2, 4.0, 12.0],
		"_big": [10.0, 2, 1.0], "_small": [4.5, 1]})
	for t in d["towers"]:
		var p := Vector2(float(t["p"][0]), float(t["p"][1]))
		if float(t["h"]) >= 60.0:
			K.tower(lm, p, float(t["h"]) - 5.5 - 10.0, 3.6, 8.0, 5.5, 10.0)
		else:
			K.tower(lm, p, 24.0, 2.4, 3.8, 3.0, 5.0)
	K.park(lm, d, [["narrow", "#0B2D6B"], ["narrow", "#D81939"], ["narrow", "#0B2D6B"], ["wide", "#0B2D6B"],
		["narrow", "#FF6600"], ["narrow", "#D81939"], ["narrow", "#073590"], ["narrow", "#0B2D6B"]], 48,
		Vector2.ZERO, 2500.0, true)
	lm.commit(model)

## Helsinki-Vantaa (EFHK), 16 km north of the centre in Vantaa: three
## runways (04L/22R, 04R/22L, 15/33), the merged Terminal complex under one
## long block, hotels and hangars at their mapped heights, and the blue-glass
## Avia Pilot office tower (50 m, mapped; glazed with the kit glass to stay in
## the batch's parts budget) as the field's tallest. OpenStreetMap
## maps no control tower, so the white flared-cab tower stands by the
## terminal's north front where the photos put it (estimated position and
## 26 m height, from the jet-bridge scale). Finnair narrowbodies and a
## widebody with a Norra turboprop in Finnair tail blue on the stands.
static func vantaa(model: Node3D) -> void:
	var d: Dictionary = CaLayoutVantaa.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D9D6D0", "membrane", "#7E8387")
	K.surfaces(lm, d)
	var sheds_skip := _named_index(d, "Avia Pilot") + _named_index(d, "Hilton Helsinki Airport") \
		+ _named_index(d, "Clarion Hotel Helsinki Airport") + _named_index(d, "Comfort Hotel Helsinki Airport") \
		+ _named_index(d, "Forenom Hostel Vantaa Airport") + _named_index(d, "Avia College") \
		+ _named_index(d, "P1/P2") + _named_index(d, "P3A") + _named_index(d, "P3B") + _named_index(d, "P5")
	K.buildings(lm, d, sheds_skip)
	K.terminal_set(lm, d, {"Terminaali": [15.0, 3, 1.0], "FinnHems": [7.2, 2],
		"_big": [10.0, 2], "_small": [5.0, 1]})
	_avia_pilot(lm, d)
	# Landside hotels and offices read glazed, not as flat sheds: mapped heights.
	for hotel in ["Hilton Helsinki Airport", "Clarion Hotel Helsinki Airport",
			"Comfort Hotel Helsinki Airport", "Forenom Hostel Vantaa Airport", "Avia College"]:
		_glazed_block(lm, d, hotel)
	# The multi-storey car parks are open decks, not solid blocks.
	for garage in ["P1/P2", "P3A", "P3B", "P5"]:
		_garage(lm, d, garage)
	K.tower(lm, Vector2(-150.0, -230.0), 17.6, 3.0, 5.2, 3.4, 5.0)
	lm.box("Walls", Vector3(-150.0, 4.0, -222.0), Vector3(14.0, 8.0, 10.0))
	K.park(lm, d, [["narrow", "#0B2D6B"], ["narrow", "#0B2D6B"], ["narrow", "#0B2D6B"],
		["wide", "#0B2D6B"], ["turboprop", "#0B2D6B"], ["narrow", "#0B2D6B"],
		["narrow", "#0B2D6B"]], 10)
	lm.commit(model)

## Indices of the layout's buildings called `wanted` (for K.buildings skip).
static func _named_index(d: Dictionary, wanted: String) -> Array:
	var out: Array = []
	var i := -1
	for b in d["buildings"]:
		i += 1
		if str(b["name"]) == wanted:
			out.append(i)
	return out

## Avia Pilot: the mapped blue-glass office tower on its measured ring,
## white slab edges each storey, roof at exactly the mapped 50.0 m.
static func _avia_pilot(lm: LandmarkMesh, d: Dictionary) -> void:
	var ring := PackedVector2Array()
	for b in d["buildings"]:
		if str(b["name"]) == "Avia Pilot":
			for p in b["ring"]:
				ring.append(Vector2(float(p[0]), float(p[1])))
	if ring.size() < 3:
		return
	lm.poly_prism("Glass", ring, 0.0, 49.0, false)
	var storey := 1
	while 3.6 * float(storey) < 49.0:
		K.band(lm, "Trim", ring, 3.6 * float(storey), 3.6 * float(storey) + 0.5)
		storey += 1
	lm.poly_prism("Trim", ring, 49.0, 50.0, false)
	K.cap(lm, "Roof", ring, 50.0)

## A landside hotel or office on its measured ring, glazed like the terminal
## at its mapped height (9 m where OSM maps none).
static func _glazed_block(lm: LandmarkMesh, d: Dictionary, wanted: String) -> void:
	for b in d["buildings"]:
		if str(b["name"]) != wanted:
			continue
		var ring := PackedVector2Array()
		for p in b["ring"]:
			ring.append(Vector2(float(p[0]), float(p[1])))
		if ring.size() < 3:
			continue
		var h := maxf(float(b["h"]), 9.0)
		K.terminal(lm, b["ring"], h, maxi(2, roundi(h / 3.5)), 1.0, 2.5, 1.0)

## An open-deck car park on its measured ring: a slab and a parapet per
## deck on columns, roofed at the top. Shared materials only.
static func _garage(lm: LandmarkMesh, d: Dictionary, wanted: String) -> void:
	for b in d["buildings"]:
		if str(b["name"]) != wanted:
			continue
		var ring := PackedVector2Array()
		for p in b["ring"]:
			ring.append(Vector2(float(p[0]), float(p[1])))
		if ring.size() < 3:
			continue
		var dh := 3.2
		var n := maxi(2, roundi(maxf(float(b["h"]), 9.0) / dh))
		for k in range(1, n + 1):
			var y := float(k) * dh
			K.cap(lm, "Trim", ring, y)
			K.band(lm, "Trim", ring, y, y + 1.1)
		var top := float(n) * dh
		K.cap(lm, "Roof", ring, top + 0.3)
		K.band(lm, "Trim", ring, top + 0.3, top + 1.4)
		var last := ring[ring.size() - 1]
		for p in ring:
			if p.distance_to(last) >= 8.0:
				lm.beam("Trim", Vector3(p.x, 0.0, p.y), Vector3(p.x, top, p.y), 0.5, 0.5)
				last = p
