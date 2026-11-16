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
