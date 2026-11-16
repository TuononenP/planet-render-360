class_name LandmarkCaAtlantic
extends RefCounted

## Capital airfields on the Atlantic side in the airfield frame (+X along the
## longest runway, +Z to its right, origin at the terminal's centre):
## Lisbon, Washington National and Buenos Aires Aeroparque. Layouts from
## OpenStreetMap (CaLayout*); terminals, towers and aircraft authored here.

const K = preload("res://scripts/generation/landmarks/capital_airports/landmark_airfield_kit.gd")

## Lisbon's Humberto Delgado Airport, 7 km north-east of the Baixa: the long
## three-storey Terminal 1 with its raised departures forecourt, the newer
## Terminal 2 and the Pier Sul finger, one 3,805 m runway (02/20) and a
## 33 m control tower, with TAP and low-cost narrowbodies on the stands.
static func lisbon(model: Node3D) -> void:
	var d: Dictionary = CaLayoutLisbon.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#DAD5CA", "membrane", "#7B7F82")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {"Terminal 1": [16.0, 3, 1.5], "Terminal 2": [12.0, 2, 1.2], "Pier Sul": [10.0, 2, 0.8],
		"_big": [10.0, 2], "_small": [4.0, 1]})
	K.towers(lm, d, 33.0)
	K.park(lm, d, [["narrow", "#00844A"], ["narrow", "#FF6600"], ["narrow", "#00844A"], ["wide", "#00844A"],
		["narrow", "#073590"]], 16)
	lm.commit(model)

## Ronald Reagan Washington National, across the Potomac from the Mall: the
## 1997 Terminal 2 (Piers A, B and C under César Pelli's vaulted glass-and-
## steel roofs) and the older Terminal 1, three runways (01/19, 15/33, 04/22)
## and regional jets on the gates.
static func washington(model: Node3D) -> void:
	var d: Dictionary = CaLayoutWashington.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D7D3C8", "membrane", "#8E9498")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {"Terminal 2": [17.0, 3, 1.5], "Terminal 1": [11.0, 2, 1.0], "_big": [10.0, 2], "_small": [4.0, 1]})
	K.towers(lm, d, 36.0)
	K.park(lm, d, [["narrow", "#0B5CAB"], ["narrow", "#C8102E"], ["narrow", "#1B3A6B"], ["narrow", "#0B5CAB"],
		["narrow", "#E31837"]], 20)
	lm.commit(model)

## Aeroparque Jorge Newbery on the Río de la Plata shore: the six-level
## passenger terminal of 1947 with its cargo terminal to the south and the
## 35 m control tower, one 2,700 m runway (13/31) along the river, with
## Aerolíneas Argentinas and low-cost narrowbodies on the apron.
static func aeroparque(model: Node3D) -> void:
	var d: Dictionary = CaLayoutBuenosAires.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E4DFD3", "membrane", "#85898C")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {"Terminal de pasajeros": [21.6, 6, 1.0], "_big": [12.0, 3], "_small": [5.0, 1]})
	K.towers(lm, d, 35.0)
	K.park(lm, d, [["narrow", "#009FE3"], ["narrow", "#009FE3"], ["narrow", "#F2C500"], ["narrow", "#C8102E"],
		["narrow", "#009FE3"]], 14)
	lm.commit(model)
