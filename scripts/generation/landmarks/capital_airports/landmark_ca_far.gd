class_name LandmarkCaFar
extends RefCounted

## Capital airfields of Asia, Africa and Oceania in the airfield frame (+X
## along the longest runway, +Z to its right, origin at the terminal's
## centre): Taipei Songshan, Wellington, Kathmandu, Vientiane and Maputo.
## Layouts from OpenStreetMap (CaLayout*); terminals, towers and aircraft
## authored here.

const K = preload("res://scripts/generation/landmarks/capital_airports/landmark_airfield_kit.gd")

## Taipei Songshan, in the middle of the Neihu-Songshan district: the
## international Terminal 1 and the domestic Terminal 2, a single 2,605 m
## runway (10/28) with dense apron stands, and the observation deck.
static func songshan(model: Node3D) -> void:
	var d: Dictionary = CaLayoutTaipei.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D6D2C8", "membrane", "#80868A")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {"第一航廈（國際線）": [20.0, 4, 1.5], "第二航廈（國內線）": [16.0, 3, 1.2],
		"松山機場觀景台": [9.0, 2], "_big": [10.0, 2], "_small": [4.0, 1]})
	K.towers(lm, d, 40.0)
	K.park(lm, d, [["narrow", "#D6336C"], ["narrow", "#00A053"], ["wide", "#D6336C"], ["narrow", "#00A053"],
		["turboprop", "#6B2A7A"]], 12)
	lm.commit(model)

## Wellington Airport on the Rongotai isthmus: the faceted international
## terminal and the main and domestic terminals along the apron, one 1,945 m
## runway (16/34) between Cook Strait and Evans Bay, the 32 m leaning
## control tower, and Air New Zealand's black-tailed ATRs and Airbuses.
static func wellington(model: Node3D) -> void:
	var d: Dictionary = CaLayoutWellington.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#CFCBC4", "membrane", "#7A8084")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {"Main Terminal": [14.0, 3, 1.5], "International Terminal": [14.0, 2, 1.5],
		"Domestic Terminal": [9.0, 2, 1.0], "Regional Terminal": [7.0, 1, 0.8], "_big": [10.0, 2], "_small": [4.0, 1]})
	K.towers(lm, d, 32.0, 3.0, 4.2, 3.2)
	K.park(lm, d, [["turboprop", "#101010"], ["narrow", "#101010"], ["narrow", "#101010"], ["narrow", "#FF5800"],
		["turboprop", "#101010"]], 14)
	lm.commit(model)

## Kathmandu's Tribhuvan International: the brown low International Terminal
## and the Domestic Terminal on the south side of the single 3,050 m runway
## (02/20) in the valley, with Nepal Airlines' widebody and the small
## turboprops of the domestic carriers on the apron.
static func kathmandu(model: Node3D) -> void:
	var d: Dictionary = CaLayoutKathmandu.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#C9B8A0", "roof_concrete", "#8B5A3C")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {"International Terminal": [8.0, 2, 1.2], "Domestic Terminal": [8.0, 2, 1.0],
		"Arrivals": [4.0, 1], "_big": [8.0, 2], "_small": [4.0, 1]})
	K.towers(lm, d, 30.0)
	K.park(lm, d, [["turboprop", "#F6C500"], ["wide", "#D0021B"], ["turboprop", "#1B3A6B"], ["narrow", "#D0021B"],
		["light", "#FFFFFF"]], 12)
	lm.commit(model)

## Vientiane's Wattay International Airport: the white international
## terminal opened in 2012 with its glazed front and the older domestic
## terminal, one 3,000 m runway (13/31), with Lao Airlines ATRs and Airbuses.
static func wattay(model: Node3D) -> void:
	var d: Dictionary = CaLayoutVientiane.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E5E3DC", "membrane", "#82878A")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {"ອາຄານຜູ້ໂດຍສານສາກົນ": [14.0, 3, 1.5], "ອາຄານຜູ້ໂດຍສານພາຍໃນປະເທດ": [8.0, 2, 1.0],
		"_big": [8.0, 2], "_small": [4.0, 1]})
	K.towers(lm, d, 34.0)
	K.park(lm, d, [["turboprop", "#C8102E"], ["narrow", "#C8102E"], ["turboprop", "#C8102E"], ["narrow", "#1B3A6B"]], 8)
	lm.commit(model)

## Maputo International Airport: the two-storey International and Domestic
## terminals side by side, the main 3,660 m runway (05/23) crossed by the
## shorter 10/28, and LAM's regional jets and turboprops on the apron.
static func maputo(model: Node3D) -> void:
	var d: Dictionary = CaLayoutMaputo.DATA
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E7DDC9", "membrane", "#8A8C8E")
	K.surfaces(lm, d)
	K.buildings(lm, d)
	K.terminal_set(lm, d, {"Terminal Internacional": [12.0, 2, 1.2], "Terminal Domésticos": [10.0, 2, 1.0],
		"_big": [8.0, 2], "_small": [4.0, 1]})
	K.towers(lm, d, 30.0)
	K.park(lm, d, [["narrow", "#00A0DF"], ["turboprop", "#00A0DF"], ["narrow", "#00A0DF"], ["turboprop", "#0B3560"]], 8)
	lm.commit(model)
