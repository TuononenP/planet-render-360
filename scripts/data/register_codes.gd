class_name RegisterCodes
extends RefCounted

## Finnish building-register code lists (VTJ / the former RHR, as served
## by the City of Helsinki's open building register) mapped onto the
## building vocabulary the generators already read: OSM `building=*`
## kinds (ArchitectureData.KIND_TAGS keys) and wall materials
## (MaterialLibrary.MATERIAL_TAGS keys). "" = the code says nothing a
## generator can use; the building keeps its map / era picks.

## Facade material (julkisivumateriaali, `c_julkisivu`). 7 ("muu") is
## mostly render over brick in the inner city: left to the era rules.
const FACADE := {
	"1": "concrete",   # betoni
	"2": "brick",      # tiili
	"3": "metal",      # metallilevy
	"4": "stone",      # kivi
	"5": "wood",       # puu
	"6": "glass",      # lasi
}

## Load-bearing material (rakennusaine, `c_rakeaine`): 1 betoni, 2 tiili,
## 3 teräs, 4 puu, 5 muu. Only timber is a safe facade hint (a wooden
## frame is clad in boards); brick and concrete frames are often rendered.
const STRUCTURE_WOOD := "4"

## Use class, 1994 classification (käyttötarkoitus, `c_kayttark`), three
## digits → kind. Codes absent here (parking garages 163, telecoms 164,
## 999 "other") say nothing usable.
const USE_1994 := {
	"011": "house", "012": "semidetached_house", "013": "house",
	"021": "terrace", "022": "terrace",
	"032": "apartments", "039": "apartments",
	"041": "cabin",
	"111": "retail", "112": "retail", "119": "retail",
	"121": "hotel", "123": "hotel", "124": "cabin", "129": "hotel",
	"131": "dormitory", "139": "dormitory",
	"141": "commercial",
	"151": "office",
	"161": "train_station", "162": "depot",
	"211": "hospital", "213": "hospital", "214": "hospital", "215": "hospital", "219": "hospital",
	"221": "civic", "222": "civic", "223": "civic", "229": "civic",
	"231": "kindergarten", "239": "civic", "241": "civic",
	"311": "civic", "312": "civic",
	"322": "library", "323": "museum", "324": "museum",
	"331": "civic",
	"341": "church", "342": "religious", "349": "religious",
	"351": "sports_hall", "352": "sports_hall", "353": "sports_hall", "354": "sports_hall",
	"359": "sports_hall",
	"369": "civic",
	"511": "school", "521": "college", "531": "university", "532": "university",
	"541": "school", "549": "school",
	"611": "industrial", "613": "industrial",
	"691": "industrial", "692": "industrial", "699": "industrial",
	"711": "warehouse", "712": "warehouse", "719": "warehouse",
	"721": "fire_station", "722": "civic", "729": "civic",
	"811": "barn", "819": "barn", "891": "silo", "892": "greenhouse", "893": "farm", "899": "farm",
	"931": "shed", "941": "shed",
}

## Building class, RL2018 (rakennusluokitus 2018, `c_rakennusluokka`),
## four digits → kind: the fallback when the 1994 use class is empty
## (newer entries). Exact codes first, then the two-digit main class.
const RL2018 := {
	"0110": "house", "0111": "semidetached_house", "0112": "terrace",
	"0120": "apartments", "0121": "apartments",
	"0130": "dormitory", "0140": "cabin",
	"0310": "retail", "0311": "retail", "0319": "retail",
	"0320": "hotel", "0330": "hotel", "0340": "commercial",
	"0400": "office",
	"0810": "kindergarten", "0820": "school", "0830": "college",
	"0840": "university", "0841": "university", "0890": "school",
	"1310": "fire_station",
	"1910": "shed", "1911": "shed",
}
const RL2018_MAIN := {
	"01": "apartments", "03": "commercial", "04": "office",
	"06": "civic", "07": "civic", "08": "school",
	"09": "industrial", "10": "industrial", "11": "industrial",
	"12": "warehouse", "13": "civic", "14": "farm",
}
## Health-care buildings (RL2018 061x) are hospitals, not generic civic.
const RL2018_HOSPITAL := "061"

## Building kind for a register row, "" when the codes say nothing.
static func kind_for(use_1994: String, rl2018: String) -> String:
	var u := use_1994.strip_edges()
	if USE_1994.has(u):
		return USE_1994[u]
	if u != "" and u != "999":
		return ""
	var r := rl2018.strip_edges()
	if RL2018.has(r):
		return RL2018[r]
	if r.begins_with(RL2018_HOSPITAL):
		return "hospital"
	if r.length() >= 2:
		return RL2018_MAIN.get(r.substr(0, 2), "")
	return ""

## Wall material for a register row, "" to leave the era's choice.
## Brick on a pre-1940 block of three or more floors is the frame of a
## rendered Jugend / classicist facade far more often than exposed
## brick, so it is left to the era rules too.
static func facade_for(facade: String, structure: String, year: int, floors: int) -> String:
	var f := facade.strip_edges()
	if FACADE.has(f):
		var m: String = FACADE[f]
		if m == "brick" and year > 0 and year < 1940 and floors >= 3:
			return ""
		return m
	if f == "" and structure.strip_edges() == STRUCTURE_WOOD and floors <= 3:
		return "wood"
	return ""
