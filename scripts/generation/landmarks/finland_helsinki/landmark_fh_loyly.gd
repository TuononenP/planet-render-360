extends RefCounted

## Löyly (Avanto Architects, 2016), public sauna and restaurant on the
## Hernesaari shore (Hernesaarenranta 4, 60.15218, 24.93044).
##
## Surveyed & photo-verified sources:
## - City of Helsinki 3D CityGML (`VTJ_PRT 100522546S`): ~6.95 m peak on the
##   northern sauna lookout, ~5.65 m twin sea-lobe crowns, ~3.55 m southern
##   restaurant roof terrace, 46.7 x 14.2 m warm box.
## - OpenStreetMap: warm core (`way:625576876`), faceted cloak overhang
##   (`way:466092407`), outer zig-zag waterfront sun deck (`way:1307741294`),
##   two-flight roof stairs and terraces (`way:1307741299`–`1307741302`),
##   set-back roof balustrades (`way:1307741303`–`1307741305`), street entrance
##   cleft (`way:1307741306`), and NE avanto sea stairs (`way:625576877`,
##   `way:1307836802`) along coastline `way:969805474`.
## - HSY Ortoilmakuva 2023, oblique/plan drone photography & Commons refs:
##   twin polyhedral sea-facing sauna lobes framing the overhanging triangular
##   V-cleft glass lounge portal, deep NNE alcove, 3.5 m cantilevered slatted
##   restaurant visor in front of the set-back terrace glass railing, wide
##   sea-facing roof amphitheatre tiers, five black sauna stovepipes (tallest
##   8.6 m), four stepped blonde-timber sun-deck tiers on dark sea piles with
##   avanto steel ladders, 6+2 square off-white restaurant parasols, and SSW
##   twin-peaked white marquee pavilion.

const ENTRY := {"type": "loyly_helsinki", "name": "Löyly", "lat": 60.15218, "lon": 24.93044,
	"radius_m": 1500.0, "wiki_title": "Löyly", "height_m": 8.6, "clear_m": 42.0,
	"base_at_m": [-29.0, 10.0], "tree_clear_m": 44.0,
	"model_rects_m": [[13.0, -14.0, 20.0, 12.0], [6.0, 6.0, 23.0, 14.0], [-6.0, 28.0, 19.0, 14.0]],
	"kind": "Sauna", "aliases": ["löyly", "loyly sauna", "löyly helsinki"]}

## Orthonormal frame at ENTRY (0, 0):
## `u` runs SSW along the 46.7 m warm core toward the southern prow;
## `s` runs ESE toward the Baltic Sea (`s < 0` faces Hernesaarenranta street).
const AX_U := Vector2(-0.432386, 0.901689)
const AX_S := Vector2(0.901689, 0.432386)
const YAW_U := atan2(-AX_U.y, AX_U.x)

const DECK_T1 := 0.72
const DECK_T2 := 0.54
const DECK_T3 := 0.37
const DECK_T4 := 0.20
const TERRACE_LOW := 3.55
const TERRACE_HIGH := 6.95
const SLAT_PITCH := 0.19

## Watertight polyhedral cloak control vertices in `(u, s, y)` metres.
const CLOAK_V := {
	# High sauna viewpoint plateau (y = 6.95 m, layer 2)
	"T_NW_N": Vector3(-12.4, -6.75, TERRACE_HIGH),
	"T_SE_N": Vector3(-12.2, -1.75, TERRACE_HIGH),
	"T_NW_S": Vector3(1.4, -6.75, TERRACE_HIGH),
	"T_SE_S": Vector3(-0.8, -1.75, TERRACE_HIGH),
	# Twin sea-lobe crowns, V-cleft brow & arch apex, NNE alcove nose, and WNW shoulders
	"R_NNE_NW": Vector3(-19.2, -6.85, 5.15),
	"R_NNE_M": Vector3(-19.6, -0.80, 5.15),
	"P_LOBE_N": Vector3(-14.6, 5.20, 5.65),
	"V_CROWN": Vector3(-9.0, 7.60, 5.65),
	"V_APEX": Vector3(-9.0, 9.55, 4.80),
	"VC_TOP": Vector3(-8.8, 7.34, 4.80),
	"P_LOBE_S": Vector3(-2.6, 6.20, 5.82),
	"R_WNW_M": Vector3(9.4, -8.85, 4.45),
	"ENT_TOP": Vector3(9.4, -6.78, 3.05),
	"R_WNW_S": Vector3(21.8, -7.85, 3.82),
	# Mid restaurant roof terrace (y = 3.55 m) & 3.5 m cantilevered slatted visor
	"M_ST_NW": Vector3(9.2, -4.45, TERRACE_LOW),
	"M_ST_SE": Vector3(6.2, 4.20, TERRACE_LOW),
	"M_RAIL_N": Vector3(5.2, 7.40, TERRACE_LOW),
	"M_RAIL_S": Vector3(26.4, 7.40, TERRACE_LOW),
	"V_LIP_N": Vector3(5.6, 10.25, 2.96),
	"V_LIP_S": Vector3(28.2, 11.15, 2.96),
	"V_FAS_N": Vector3(5.6, 10.10, 2.52),
	"V_FAS_S": Vector3(28.2, 11.00, 2.52),
	"M_LD_SE": Vector3(26.4, -1.15, TERRACE_LOW),
	"M_LD_NW": Vector3(26.4, -4.55, TERRACE_LOW),
	# Base perimeter on street forecourt (y = 0.08) and main sun deck (y = DECK_T1 = 0.72)
	"B_NNE_NW": Vector3(-22.6, -7.70, 0.08),
	"B_ALC_W": Vector3(-25.8, -3.20, 0.20),
	"B_ALC_IN": Vector3(-20.8, 0.60, DECK_T1),
	"B_LOBE_NE": Vector3(-23.2, 6.20, DECK_T1),
	"B_STEP_NE": Vector3(-19.8, 12.40, DECK_T1),
	"B_VC_N": Vector3(-15.8, 15.40, DECK_T1),
	"B_VC_NJ": Vector3(-12.2, 7.34, DECK_T1),
	"B_VC_SJ": Vector3(-5.4, 7.34, DECK_T1),
	"B_VC_S": Vector3(-2.2, 14.55, DECK_T1),
	"B_LOBE_SM": Vector3(1.2, 13.95, DECK_T1),
	"B_NOSE_S": Vector3(4.2, 12.45, DECK_T1),
	"B_REST_N": Vector3(5.4, 7.35, 2.48),
	"B_REST_S": Vector3(26.4, 7.35, 2.48),
	"B_SSW_E": Vector3(30.8, 3.80, 2.25),
	"B_PROW_SE": Vector3(39.0, -1.60, DECK_T1),
	"B_PROW_NW": Vector3(39.0, -3.95, DECK_T1),
	"B_WNW_S": Vector3(26.4, -8.85, 0.08),
	"B_ENT_S": Vector3(12.6, -10.05, 0.08),
	"B_ENT_SJ": Vector3(12.0, -6.78, 0.08),
	"B_ENT_NJ": Vector3(6.8, -6.78, 0.08),
	"B_ENT_N": Vector3(6.2, -9.85, 0.08),
	"B_WNW_N": Vector3(-11.0, -9.20, 0.08),
}

const CLOAK_FACETS := [
	# NNE bluff & deep shaded NNE sauna-exit alcove
	["T_NW_N", "T_SE_N", "R_NNE_M"],
	["T_NW_N", "R_NNE_M", "R_NNE_NW"],
	["R_NNE_NW", "R_NNE_M", "B_ALC_W"],
	["R_NNE_NW", "B_ALC_W", "B_NNE_NW"],
	["B_ALC_W", "R_NNE_M", "B_ALC_IN"],
	["R_NNE_M", "B_LOBE_NE", "B_ALC_IN"],
	# Northern sea lobe (`Lobe N` stepped wedge & sea facets)
	["T_SE_N", "P_LOBE_N", "R_NNE_M"],
	["R_NNE_M", "P_LOBE_N", "B_LOBE_NE"],
	["P_LOBE_N", "B_STEP_NE", "B_LOBE_NE"],
	["P_LOBE_N", "B_VC_N", "B_STEP_NE"],
	# Central upper roof slopes & overhanging ESE V-cleft arch (open to glass portal!)
	["T_SE_N", "V_CROWN", "P_LOBE_N"],
	["T_SE_N", "T_SE_S", "P_LOBE_S"],
	["T_SE_N", "P_LOBE_S", "V_CROWN"],
	["P_LOBE_N", "V_CROWN", "V_APEX"],
	["P_LOBE_N", "V_APEX", "B_VC_N"],
	["V_CROWN", "P_LOBE_S", "V_APEX"],
	["V_APEX", "P_LOBE_S", "B_VC_S"],
	["B_VC_N", "V_APEX", "B_VC_NJ"],
	["V_APEX", "VC_TOP", "B_VC_NJ"],
	["B_VC_S", "B_VC_SJ", "V_APEX"],
	["V_APEX", "B_VC_SJ", "VC_TOP"],
	# Southern sea lobe (`Lobe S` 5-ray star facets) & sub-amphitheatre closure
	["P_LOBE_S", "B_LOBE_SM", "B_VC_S"],
	["P_LOBE_S", "B_NOSE_S", "B_LOBE_SM"],
	["P_LOBE_S", "V_LIP_N", "B_NOSE_S"],
	["B_NOSE_S", "V_LIP_N", "V_FAS_N"],
	["B_NOSE_S", "V_FAS_N", "B_REST_N"],
	["P_LOBE_S", "M_RAIL_N", "V_LIP_N"],
	["P_LOBE_S", "M_ST_SE", "M_RAIL_N"],
	["T_SE_S", "M_ST_SE", "P_LOBE_S"],
	["T_SE_S", "M_ST_NW", "M_ST_SE"],
	["T_NW_S", "M_ST_NW", "T_SE_S"],
	# 3.5 m cantilevered horizontal-slatted restaurant visor (top slope + thick lip fascia)
	["M_RAIL_N", "M_RAIL_S", "V_LIP_S"],
	["M_RAIL_N", "V_LIP_S", "V_LIP_N"],
	["V_LIP_N", "V_LIP_S", "V_FAS_S"],
	["V_LIP_N", "V_FAS_S", "V_FAS_N"],
	# SSW restaurant roof wedge & grand-stair SE prow cheek
	["M_LD_SE", "M_RAIL_S", "B_SSW_E"],
	["M_RAIL_S", "V_LIP_S", "B_SSW_E"],
	["B_SSW_E", "V_LIP_S", "V_FAS_S"],
	["M_LD_SE", "B_SSW_E", "B_PROW_SE"],
	# WNW street wall, open covered entrance cleft, and SSW NW prow cheek
	["T_NW_N", "R_NNE_NW", "B_NNE_NW"],
	["T_NW_N", "B_NNE_NW", "B_WNW_N"],
	["T_NW_N", "B_WNW_N", "T_NW_S"],
	["T_NW_S", "B_WNW_N", "B_ENT_N"],
	["T_NW_S", "B_ENT_N", "R_WNW_M"],
	["B_ENT_N", "B_ENT_NJ", "R_WNW_M"],
	["R_WNW_M", "B_ENT_NJ", "ENT_TOP"],
	["B_ENT_S", "R_WNW_M", "B_ENT_SJ"],
	["R_WNW_M", "ENT_TOP", "B_ENT_SJ"],
	["T_NW_S", "R_WNW_M", "M_ST_NW"],
	["R_WNW_M", "B_ENT_S", "R_WNW_S"],
	["R_WNW_M", "R_WNW_S", "M_LD_NW"],
	["R_WNW_M", "M_LD_NW", "M_ST_NW"],
	["R_WNW_S", "B_ENT_S", "B_WNW_S"],
	["R_WNW_S", "B_WNW_S", "B_PROW_NW"],
	["R_WNW_S", "B_PROW_NW", "M_LD_NW"],
]

static func _p(u: float, s: float) -> Vector2:
	return AX_U * u + AX_S * s

static func _v(u: float, s: float, y: float) -> Vector3:
	var p := _p(u, s)
	return Vector3(p.x, y, p.y)

static func _cv(key: String) -> Vector3:
	var raw: Vector3 = CLOAK_V[key]
	return _v(raw.x, raw.y, raw.z)

static func _poly(pts_us: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q: Array in pts_us:
		out.append(_p(float(q[0]), float(q[1])))
	return out

static func _basis_u(extra_yaw: float = 0.0) -> Basis:
	return Basis(Vector3.UP, YAW_U + extra_yaw)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Slat", LandmarkMaterials.pbr("wood", "#8D7356", 1.3))
	lm.use("Core", LandmarkMaterials.pbr("wood", "#211C18", 1.6))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#968065", 1.8))
	lm.use("Dark", LandmarkMaterials.pbr("wood", "#202326", 1.5))
	lm.use("Steel", LandmarkMaterials.paint("#B8C0C6", 0.36, 0.65))
	lm.use("Flue", LandmarkMaterials.paint("#1B1D1F", 0.46, 0.55))
	lm.use("Stone", LandmarkMaterials.pbr("rock", "#686560", 2.2))
	lm.use("WinGlass", LandmarkMaterials.glass("#24333C"))
	lm.use("RailGlass", LandmarkMaterials.clear_glass("#CFE7EF", 0.20))
	lm.use("Canvas", LandmarkMaterials.pbr("render", "#CBC4B6", 2.0, 0.78))
	lm.use("Lamp", LandmarkMaterials.lit("#FFC068", 1.15))

	_build_decks_and_avanto(lm)
	_build_warm_core(lm)
	_build_slatted_cloak(lm)
	_build_roof_terraces_and_stairs(lm)
	_build_flues(lm)
	_build_terrace_furnishings(lm)

	var parts := lm.commit(model)
	var rail_sh := LandmarkMaterials.clear_glass_shader("#D8EEF5", 0.14)
	for mi in parts:
		if mi.name == "RailGlass":
			mi.set_surface_override_material(0, rail_sh)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var warm := Color(1.0, 0.88, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[_v(-8.0, 22.0, 1.0), _v(-8.0, 6.0, 4.4), 58.0, 0.85, 42.0, warm],
		[_v(16.0, 22.0, 1.0), _v(16.0, 7.0, 3.0), 58.0, 0.80, 40.0, warm],
		[_v(-28.0, 4.0, 1.0), _v(-16.0, 0.0, 4.6), 54.0, 0.75, 36.0, warm],
		[_v(42.0, -2.0, 1.0), _v(24.0, -2.0, 3.4), 54.0, 0.75, 36.0, warm],
		[_v(2.0, -18.0, 1.0), _v(2.0, -6.5, 4.4), 58.0, 0.70, 36.0, warm],
	])

## Four-tier zig-zag overwater wooden sun deck (all four tiers standing above y = 0.0),
## 0.52 m blonde-wood rim fascia, dark sea piles, NNE concrete abutment, and avanto stairs.
static func _build_decks_and_avanto(lm: LandmarkMesh) -> void:
	# Tightly fitted foundation plinth tucked strictly inside the WNW/NNE cloak base.
	var land_pad := _poly([
		[-22.4, -7.6], [-11.0, -9.1], [6.2, -9.7], [12.6, -9.9],
		[26.4, -8.7], [38.8, -3.9], [38.8, 6.6], [-23.0, 6.6], [-25.5, -3.1],
	])
	lm.poly_prism("Core", land_pad, -0.50, 0.08)

	# Concrete sea-wall abutment under the northern deck bay (93c71528.jpg).
	var abutment := _poly([
		[-27.2, 9.0], [-26.2, 14.8], [-23.6, 19.2], [-15.8, 17.8], [-15.8, 10.0],
	])
	lm.poly_prism("Steel", abutment, -1.45, -0.32)

	# Tier 4: outer overwater boardwalk (y = +0.20 m, 0.52 m blonde-wood fascia down to -0.32 m, way:1307741294).
	var tier4 := _poly([
		[-27.5, 2.5], [-27.0, 9.6], [-26.4, 15.0], [-27.0, 19.05], [-23.9, 19.49],
		[-20.0, 20.17], [-16.2, 18.26], [-7.0, 27.39], [6.07, 26.46], [9.24, 22.22],
		[25.29, 25.16], [45.57, 18.71], [45.70, 14.48], [44.20, 3.21], [44.12, -7.64],
		[37.0, -6.9], [37.0, 6.5], [-23.0, 6.5],
	])
	lm.poly_prism("Dark", tier4, -0.48, -0.32, false)
	lm.poly_prism("Deck", tier4, -0.32, DECK_T4)

	# Tier 3: lower zig-zag amphitheatre step (y = +0.37 m).
	var tier3 := _poly([
		[-25.8, 5.2], [-24.6, 15.8], [-19.8, 17.5], [-15.8, 16.6], [-7.2, 24.4],
		[5.2, 23.6], [8.8, 20.2], [24.6, 22.6], [43.2, 16.8], [43.2, 3.0],
		[42.5, -6.2], [36.0, -5.8], [36.0, 6.8], [-22.5, 6.8],
	])
	lm.poly_prism("Deck", tier3, DECK_T4 - 0.02, DECK_T3)

	# Tier 2: middle zig-zag amphitheatre step (y = +0.54 m).
	var tier2 := _poly([
		[-24.8, 6.0], [-22.6, 13.8], [-16.4, 16.2], [-7.4, 21.4], [4.4, 20.8],
		[8.4, 18.2], [24.0, 20.1], [41.0, 14.8], [41.2, -5.2], [33.0, -5.0],
		[33.0, 7.0], [-22.0, 7.0],
	])
	lm.poly_prism("Deck", tier2, DECK_T3 - 0.02, DECK_T2)

	# Tier 1: main restaurant & sauna threshold deck + SSW forecourt (y = +0.72 m).
	var tier1 := _poly([
		[-24.2, 6.2], [-20.5, 11.8], [-15.8, 15.8], [-8.4, 18.2], [3.8, 18.0],
		[7.8, 16.2], [23.4, 17.6], [39.6, 12.6], [40.2, -4.6], [26.0, -5.2],
		[26.0, 7.1], [-21.5, 7.1],
	])
	lm.poly_prism("Deck", tier1, DECK_T2 - 0.02, DECK_T1)

	# Three forecourt approach steps rising from street walk (0.08 m) onto Tier 1 (0.72 m) at the SSW prow.
	for st in 3:
		var u_s := 40.2 + float(st) * 0.55
		var y_s := lerpf(DECK_T1 - 0.15, 0.22, float(st) / 2.0)
		lm.poly_prism("Deck", _poly([[40.0, -4.6], [u_s, -4.6], [u_s, 1.0], [40.0, 1.0]]), 0.06, y_s)

	# Warm recessed LED strip glow under the zig-zag amphitheatre step risers.
	for strip: Array in [
		[[-15.5, 16.0, DECK_T1 - 0.08], [-8.2, 18.25, DECK_T1 - 0.08], [3.8, 18.05, DECK_T1 - 0.08], [7.8, 16.25, DECK_T1 - 0.08], [23.4, 17.65, DECK_T1 - 0.08]],
		[[-16.0, 16.3, DECK_T2 - 0.08], [-7.4, 21.45, DECK_T2 - 0.08], [4.4, 20.85, DECK_T2 - 0.08], [8.4, 18.25, DECK_T2 - 0.08], [24.0, 20.15, DECK_T2 - 0.08]],
		[[-15.6, 16.7, DECK_T3 - 0.08], [-7.2, 24.45, DECK_T3 - 0.08], [5.2, 23.65, DECK_T3 - 0.08], [8.8, 20.25, DECK_T3 - 0.08], [24.6, 22.65, DECK_T3 - 0.08]],
	]:
		for i in strip.size() - 1:
			var q0: Array = strip[i]
			var q1: Array = strip[i + 1]
			lm.beam("Lamp", _v(q0[0], q0[1], q0[2]), _v(q1[0], q1[1], q1[2]), 0.05, 0.05, Vector3.UP)

	# Dark cylindrical piles carrying the overwater deck into the Baltic Sea (down to y = -2.65 m).
	var pile_pts := [
		[-20.2, 19.4], [-15.8, 17.8], [-11.2, 22.4], [-6.8, 26.5],
		[-0.4, 26.2], [5.6, 25.6], [9.2, 21.5], [16.8, 23.0], [24.8, 24.2],
		[33.5, 21.4], [42.0, 18.2], [44.8, 15.0], [-5.0, 20.5], [14.0, 18.5], [29.0, 18.5],
	]
	for pp: Array in pile_pts:
		var pv := _p(float(pp[0]), float(pp[1]))
		lm.frustum("Dark", Vector3(pv.x, -2.65, pv.y), 0.22, 0.22, 2.35, 10)

	# Perimeter glass windbreak balustrade standing on Tier 4 (y = +0.20 m), leaving the avanto stairs open.
	_glass_rail_us(lm, [
		Vector3(-27.4, 2.8, DECK_T4), Vector3(-27.0, 9.6, DECK_T4),
		Vector3(-26.4, 15.0, DECK_T4), Vector3(-26.9, 18.5, DECK_T4),
	], 1.05)
	_glass_rail_us(lm, [
		Vector3(-23.6, 19.5, DECK_T4), Vector3(-20.0, 20.17, DECK_T4), Vector3(-16.2, 18.26, DECK_T4),
		Vector3(-7.0, 27.39, DECK_T4), Vector3(6.07, 26.46, DECK_T4), Vector3(9.24, 22.22, DECK_T4),
		Vector3(25.29, 25.16, DECK_T4), Vector3(45.57, 18.71, DECK_T4), Vector3(45.70, 14.48, DECK_T4),
		Vector3(44.20, 3.21, DECK_T4), Vector3(44.12, -7.40, DECK_T4),
	], 1.05)

	# NE Avanto sea-swimming stairs descending from Tier 4 (+0.20 m) down to the sea (-1.85 m)
	# with warm pine stringer cheeks and twin stainless-steel pool ladders.
	var av_u := -25.25
	var av_w := 2.85
	for k in 12:
		var t := float(k) / 11.0
		var s := lerpf(18.6, 23.6, t)
		var y := lerpf(DECK_T4 - 0.06, -1.85, t)
		lm.box("Deck", _v(av_u, s, y), Vector3(av_w, 0.09, 0.42), _basis_u(), 0.0)
	var foot_pad := _poly([[-26.8, 23.3], [-23.7, 23.3], [-23.7, 24.5], [-26.8, 24.5]])
	lm.poly_prism("Deck", foot_pad, -2.02, -1.82)
	var side_dir := Vector3(AX_U.x, 0.0, AX_U.y)
	for side in [-1.42, 1.42]:
		var u_r := av_u + float(side)
		lm.beam("Deck", _v(u_r, 18.4, DECK_T4 - 0.10), _v(u_r, 24.2, -1.94), 0.14, 0.34, side_dir)
		lm.beam("Deck", _v(u_r, 18.4, DECK_T4 + 0.96), _v(u_r, 23.8, -0.92), 0.09, 0.07, Vector3.UP)
		for sp_s in [18.5, 21.2, 23.8]:
			var ft := (float(sp_s) - 18.4) / 5.4
			var y_b := lerpf(DECK_T4 - 0.05, -1.88, ft)
			lm.beam("Deck", _v(u_r, float(sp_s), y_b), _v(u_r, float(sp_s), y_b + 0.98), 0.07, 0.07)
		var pv := _p(u_r, 23.9)
		lm.frustum("Dark", Vector3(pv.x, -2.85, pv.y), 0.15, 0.15, 1.2, 8)
	for l_u in [-25.95, -24.55]:
		for rail_off in [-0.24, 0.24]:
			var u_st := float(l_u) + float(rail_off)
			lm.beam("Steel", _v(u_st, 24.45, -2.75), _v(u_st, 24.45, -1.05), 0.04, 0.04)
			lm.beam("Steel", _v(u_st, 24.45, -1.05), _v(u_st, 23.95, -1.05), 0.04, 0.04, Vector3.UP)
			lm.beam("Steel", _v(u_st, 23.95, -1.05), _v(u_st, 23.95, -1.82), 0.04, 0.04)

	# Coastal granite riprap boulders flanking the NE and SSW shore embankments.
	for b_spec: Array in [
		[-28.6, 12.2, -0.9, 1.4], [-29.6, 15.0, -1.2, 1.7], [-28.8, 18.2, -1.5, 1.6],
		[-30.5, 20.5, -1.7, 1.8], [-27.8, 21.4, -1.8, 1.4], [46.2, 10.5, -0.7, 1.5],
		[46.8, 13.8, -1.0, 1.6], [46.4, 17.2, -1.3, 1.5],
	]:
		var bp := _v(float(b_spec[0]), float(b_spec[1]), float(b_spec[2]))
		var r := float(b_spec[3])
		lm.lathe("Stone", bp, PackedVector2Array([
			Vector2(r * 1.05, 0.0), Vector2(r * 0.92, r * 0.48), Vector2(r * 0.42, r * 0.82), Vector2(0.0, r * 0.92),
		]), 7, 1.15, 0.9, float(b_spec[0]), false)

## Dark warm core chamfered cleanly inside the sloped NNE/NE cloak facets,
## panoramic restaurant curtain wall, and tall V-cleft sauna lounge portal.
static func _build_warm_core(lm: LandmarkMesh) -> void:
	var core_low := _poly([
		[-18.8, -6.50], [26.25, -6.50], [26.25, 7.28],
		[-13.8, 7.28], [-20.2, 1.40], [-20.2, -2.60],
	])
	lm.poly_prism("Core", core_low, 0.05, 3.25)
	var core_high := _poly([
		[-15.5, -6.30], [0.8, -6.30], [0.8, 2.20], [-14.2, 2.20],
	])
	lm.poly_prism("Core", core_high, 3.25, 4.95)

	var sea_nrm := Vector3(AX_S.x, 0.0, AX_S.y)
	var ssw_nrm := Vector3(AX_U.x, 0.0, AX_U.y)
	var nne_nrm := -ssw_nrm
	var wnw_nrm := -sea_nrm

	# Panoramic ESE restaurant curtain wall under the 3.5 m cantilevered visor.
	lm.quad("WinGlass", _v(26.2, 7.33, DECK_T1 + 0.02), _v(5.4, 7.33, DECK_T1 + 0.02),
		_v(5.4, 7.33, 2.52), _v(26.2, 7.33, 2.52), sea_nrm)
	lm.quad("Lamp", _v(25.4, 7.18, 1.85), _v(6.2, 7.18, 1.85),
		_v(6.2, 7.18, 2.42), _v(25.4, 7.18, 2.42), sea_nrm)
	for k in 13:
		var u := lerpf(5.4, 26.2, float(k) / 12.0)
		lm.box("Dark", _v(u, 7.37, (DECK_T1 + 2.52) * 0.5), Vector3(0.11, 2.52 - DECK_T1, 0.14), _basis_u(), 0.0)
	lm.beam("Dark", _v(5.4, 7.37, DECK_T1 + 0.04), _v(26.2, 7.37, DECK_T1 + 0.04), 0.12, 0.14, Vector3.UP)
	lm.beam("Dark", _v(5.4, 7.37, 2.50), _v(26.2, 7.37, 2.50), 0.14, 0.16, Vector3.UP)
	lm.quad("Slat", _v(5.4, 7.32, 2.48), _v(26.4, 7.32, 2.48),
		_v(28.2, 11.00, 2.52), _v(5.6, 10.10, 2.52), Vector3.DOWN)
	lm.tri("Slat", _v(26.4, 7.32, 2.48), _v(30.8, 3.80, 2.25), _v(28.2, 11.00, 2.52),
		Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector2.ZERO, Vector2(4.0, 0.0), Vector2(2.0, -3.5))

	# SSW corner return glazing of the restaurant.
	lm.quad("WinGlass", _v(26.29, 0.5, DECK_T1 + 0.02), _v(26.29, 7.32, DECK_T1 + 0.02),
		_v(26.29, 7.32, 2.52), _v(26.29, 0.5, 2.52), ssw_nrm)
	for k in 4:
		var s := lerpf(0.5, 7.32, float(k) / 3.0)
		lm.box("Dark", _v(26.32, s, (DECK_T1 + 2.52) * 0.5), Vector3(0.14, 2.52 - DECK_T1, 0.11), _basis_u(), 0.0)

	# Iconic ESE triangular V-cleft glazed sauna fireplace lounge portal (completely unobstructed!).
	var vc_n := _v(-12.2, 7.34, DECK_T1)
	var vc_s := _v(-5.4, 7.34, DECK_T1)
	var vc_top := _v(-8.8, 7.34, 4.80)
	lm.tri("WinGlass", vc_s, vc_n, vc_top, sea_nrm, sea_nrm, sea_nrm,
		Vector2(0.0, 0.0), Vector2(6.8, 0.0), Vector2(3.4, -4.08))
	lm.quad("Lamp", _v(-6.6, 7.20, DECK_T1 + 0.20), _v(-11.0, 7.20, DECK_T1 + 0.20),
		_v(-9.6, 7.20, 3.45), _v(-8.0, 7.20, 3.45), sea_nrm)
	for u_m in [-10.5, -8.8, -7.1]:
		var h_m := 4.78 - absf(float(u_m) + 8.8) * 1.15
		lm.beam("Dark", _v(float(u_m), 7.38, DECK_T1), _v(float(u_m), 7.38, h_m), 0.10, 0.12, sea_nrm)
	lm.beam("Dark", _v(-11.1, 7.38, 2.45), _v(-6.5, 7.38, 2.45), 0.10, 0.12, Vector3.UP)

	# Deep NNE sauna exit alcove glazing (`B_ALC_IN`, 93c71528.jpg right).
	lm.quad("WinGlass", _v(-20.25, -2.2, DECK_T1), _v(-20.25, 1.4, DECK_T1),
		_v(-20.25, 1.4, 2.95), _v(-20.25, -2.2, 2.95), nne_nrm)

	# WNW covered street-side main entrance portal.
	lm.quad("WinGlass", _v(6.8, -6.77, 0.10), _v(12.0, -6.77, 0.10),
		_v(12.0, -6.77, 3.02), _v(6.8, -6.77, 3.02), wnw_nrm)
	lm.quad("Lamp", _v(7.4, -6.65, 0.35), _v(11.4, -6.65, 0.35),
		_v(11.4, -6.65, 2.65), _v(7.4, -6.65, 2.65), wnw_nrm)
	for k in 4:
		var u := lerpf(6.8, 12.0, float(k) / 3.0)
		lm.box("Dark", _v(u, -6.81, 1.55), Vector3(0.11, 2.90, 0.13), _basis_u(), 0.0)

## Polyhedral heat-treated pine cloak: exact manifold dark `"Core"` shell + proud
## CNC-mitred 3D horizontal pine lamellas (`"Slat"`) revealing genuine shadow grooves.
static func _build_slatted_cloak(lm: LandmarkMesh) -> void:
	for f: Array in CLOAK_FACETS:
		var k0 := str(f[0])
		var k1 := str(f[1])
		var k2 := str(f[2])
		var a := _cv(k0)
		var b := _cv(k1)
		var c := _cv(k2)
		var u_mid := ((CLOAK_V[k0] as Vector3).x + (CLOAK_V[k1] as Vector3).x + (CLOAK_V[k2] as Vector3).x) / 3.0
		var spine := _v(u_mid, -2.2, 1.5)
		var nrm := (b - a).cross(c - a).normalized()
		if nrm.dot((a + b + c) / 3.0 - spine) < 0.0:
			nrm = -nrm
		if k2 == "B_VC_NJ" or k1 == "B_VC_SJ" or k1 == "VC_TOP" or k2 == "VC_TOP":
			var cleft_mid := _v(-8.8, 13.5, 1.8)
			if nrm.dot(cleft_mid - (a + b + c) / 3.0) < 0.0:
				nrm = -nrm
		elif k2 == "B_ALC_IN":
			var alc_mid := _v(-24.5, 2.2, 1.6)
			if nrm.dot(alc_mid - (a + b + c) / 3.0) < 0.0:
				nrm = -nrm
		elif k1 == "B_ENT_NJ" or k2 == "B_ENT_SJ" or k1 == "ENT_TOP" or k2 == "ENT_TOP":
			var ent_mid := _v(9.4, -12.5, 1.5)
			if nrm.dot(ent_mid - (a + b + c) / 3.0) < 0.0:
				nrm = -nrm

		lm.tri("Core", a, b, c, nrm, nrm, nrm,
			Vector2(0.0, 0.0), Vector2(a.distance_to(b), 0.0), Vector2(0.0, -a.distance_to(c)))
		_slice_facet_slats(lm, a, b, c, nrm)

static func _slice_facet_slats(lm: LandmarkMesh, a: Vector3, b: Vector3, c: Vector3, nrm: Vector3) -> void:
	var y_lo := minf(a.y, minf(b.y, c.y))
	var y_hi := maxf(a.y, maxf(b.y, c.y))
	var h_out := Vector3(nrm.x, 0.0, nrm.z)
	var h_len := h_out.length()
	if h_len < 0.05 or y_hi - y_lo < 0.08:
		return
	h_out /= h_len
	var edges := [[a, b], [b, c], [c, a]]
	var k_start := maxi(1, int(ceil((y_lo + 0.04) / SLAT_PITCH)))
	var k_end := int(floor((y_hi - 0.04) / SLAT_PITCH))
	var hh := SLAT_PITCH * 0.28
	var proj := 0.095
	var slope_tan := maxf(nrm.y, 0.0) / maxf(h_len, 0.16)
	var face_n := (h_out + Vector3.UP * 0.18).normalized()
	for k in range(k_start, k_end + 1):
		var yk := float(k) * SLAT_PITCH
		var hits: Array[Vector3] = []
		for e: Array in edges:
			var p0: Vector3 = e[0]
			var p1: Vector3 = e[1]
			if (p0.y <= yk and p1.y > yk) or (p1.y <= yk and p0.y > yk):
				var t := (yk - p0.y) / (p1.y - p0.y)
				hits.append(p0.lerp(p1, t))
		if hits.size() < 2:
			continue
		var q0: Vector3 = hits[0]
		var q1: Vector3 = hits[1]
		if q0.distance_to(q1) < 0.04:
			continue
		if (q1 - q0).cross(Vector3.UP).dot(h_out) < 0.0:
			var tmp := q0
			q0 = q1
			q1 = tmp
		var ib0 := q0 - Vector3(0.0, hh, 0.0) + h_out * (hh * slope_tan)
		var ib1 := q1 - Vector3(0.0, hh, 0.0) + h_out * (hh * slope_tan)
		var it0 := q0 + Vector3(0.0, hh, 0.0) - h_out * (hh * slope_tan)
		var it1 := q1 + Vector3(0.0, hh, 0.0) - h_out * (hh * slope_tan)
		var ob0 := ib0 + h_out * proj
		var ob1 := ib1 + h_out * proj
		var ot0 := it0 + h_out * proj
		var ot1 := it1 + h_out * proj
		lm.quad("Slat", ob0, ob1, ot1, ot0, face_n)
		lm.quad("Slat", it0, it1, ot1, ot0, Vector3.UP)
		lm.quad("Slat", ob0, ob1, ib1, ib0, Vector3.DOWN)

## Walkable upper/lower timber roof decks, grand stairs, sea-facing roof amphitheatre, and glass railings.
static func _build_roof_terraces_and_stairs(lm: LandmarkMesh) -> void:
	var high_deck := _poly([
		[-12.4, -6.75], [1.4, -6.75], [-0.8, -1.75], [-12.2, -1.75],
	])
	lm.poly_prism("Deck", high_deck, TERRACE_HIGH - 0.14, TERRACE_HIGH)

	var mid_deck := _poly([
		[9.2, -4.45], [26.4, -4.55], [26.4, 7.40], [5.2, 7.40], [6.2, 4.20], [9.2, -1.60],
	])
	lm.poly_prism("Deck", mid_deck, TERRACE_LOW - 0.14, TERRACE_LOW)

	# 1. SSW Lower Grand Stair (u = 39.0 -> 26.4, y = DECK_T1 (0.72) -> 3.55 m, 18 wide treads).
	_stair_flight(lm, 39.0, -3.90, -1.65, DECK_T1, 26.4, -4.50, -1.20, TERRACE_LOW, 18, true, true)

	# 2. Upper Viewpoint Stair on WNW-centre (u = 9.2 -> -0.8, y = 3.55 -> 6.95 m, 19 treads).
	_stair_flight(lm, 9.2, -4.40, -1.65, TERRACE_LOW, -0.8, -5.25, -1.80, TERRACE_HIGH, 19, true, true)

	# 3. Wide sea-facing rooftop amphitheatre seating tiers (8 broad benches between 3.55 m and 6.95 m).
	for b_i in 8:
		var t0 := float(b_i) / 8.0
		var t1 := float(b_i + 1) / 8.0
		var y_b := lerpf(TERRACE_LOW, TERRACE_HIGH - 0.02, t0) - 0.06
		var y_t := lerpf(TERRACE_LOW, TERRACE_HIGH - 0.02, t1)
		var ua := lerpf(7.8, -0.8, t0)
		var ub := lerpf(7.8, -0.8, t1)
		var sa_l := lerpf(-1.60, -1.78, t0)
		var sb_l := lerpf(-1.60, -1.78, t1)
		var sa_r := lerpf(4.15, 0.20, t0)
		var sb_r := lerpf(4.15, 0.20, t1)
		lm.poly_prism("Deck", _poly([[ua, sa_l], [ua, sa_r], [ub, sb_r], [ub, sb_l]]), y_b, y_t)

	_glass_rail_us(lm, [
		Vector3(-0.8, -5.30, TERRACE_HIGH), Vector3(1.4, -6.75, TERRACE_HIGH),
		Vector3(-12.4, -6.75, TERRACE_HIGH), Vector3(-12.2, -1.75, TERRACE_HIGH),
		Vector3(-0.8, -1.75, TERRACE_HIGH),
	], 1.10)
	_glass_rail_us(lm, [
		Vector3(26.4, -1.15, TERRACE_LOW), Vector3(26.4, 7.38, TERRACE_LOW),
		Vector3(5.2, 7.38, TERRACE_LOW), Vector3(6.2, 4.20, TERRACE_LOW),
	], 1.10)
	_glass_rail_us(lm, [
		Vector3(26.4, -4.55, TERRACE_LOW), Vector3(9.2, -4.45, TERRACE_LOW),
	], 1.10)

	lm.box("Dark", _v(13.8, 1.8, TERRACE_LOW + 0.26), Vector3(1.75, 0.52, 1.65), _basis_u(0.18), 0.0)
	lm.quad("WinGlass", _v(13.1, 1.15, TERRACE_LOW + 0.53), _v(14.5, 1.15, TERRACE_LOW + 0.53),
		_v(14.5, 2.45, TERRACE_LOW + 0.53), _v(13.1, 2.45, TERRACE_LOW + 0.53), Vector3.UP)

static func _stair_flight(lm: LandmarkMesh, u0: float, s0_l: float, s0_r: float, y0: float,
		u1: float, s1_l: float, s1_r: float, y1: float, steps: int, rail_l: bool, rail_r: bool) -> void:
	var bl := _v(u0, s0_l + 0.08, y0 - 0.05)
	var br := _v(u0, s0_r - 0.08, y0 - 0.05)
	var tl := _v(u1, s1_l + 0.08, y1 - 0.16)
	var tr := _v(u1, s1_r - 0.08, y1 - 0.16)
	lm.quad("Core", bl, br, tr, tl, Vector3.UP)
	for k in steps:
		var t0 := float(k) / float(steps)
		var t1 := float(k + 1) / float(steps)
		var tm := (t0 + t1) * 0.5
		var y_top := lerpf(y0, y1, t1)
		var y_bot := lerpf(y0, y1, t0) - 0.04
		var ua := lerpf(u0, u1, t0)
		var ub := lerpf(u0, u1, t1)
		var sl_a := lerpf(s0_l, s1_l, t0)
		var sr_a := lerpf(s0_r, s1_r, t0)
		var sl_b := lerpf(s0_l, s1_l, t1)
		var sr_b := lerpf(s0_r, s1_r, t1)
		lm.poly_prism("Deck", _poly([[ua, sl_a], [ua, sr_a], [ub, sr_b], [ub, sl_b]]), y_bot, y_top)
		if k % 4 == 1:
			var uc := lerpf(u0, u1, tm)
			lm.beam("Lamp", _v(uc, lerpf(s0_l, s1_l, tm) + 0.22, y_top - 0.03),
				_v(uc, lerpf(s0_r, s1_r, tm) - 0.22, y_top - 0.03), 0.04, 0.04, Vector3.UP)
	var side_vec := Vector3(AX_S.x, 0.0, AX_S.y)
	if rail_l:
		lm.beam("Steel", _v(u0, s0_l, y0 + 0.04), _v(u1, s1_l, y1 + 0.04), 0.07, 0.18, side_vec)
		_glass_rail_us(lm, [Vector3(u0, s0_l, y0 + 0.06), Vector3(u1, s1_l, y1 + 0.06)], 1.06)
	if rail_r:
		lm.beam("Steel", _v(u0, s0_r, y0 + 0.04), _v(u1, s1_r, y1 + 0.04), 0.07, 0.18, side_vec)
		_glass_rail_us(lm, [Vector3(u0, s0_r, y0 + 0.06), Vector3(u1, s1_r, y1 + 0.06)], 1.06)

static func _glass_rail_us(lm: LandmarkMesh, pts: Array, h: float) -> void:
	for i in pts.size() - 1:
		var q0: Vector3 = pts[i]
		var q1: Vector3 = pts[i + 1]
		var a := _v(q0.x, q0.y, q0.z)
		var b := _v(q1.x, q1.y, q1.z)
		var seg_len := a.distance_to(b)
		if seg_len < 0.15:
			continue
		var dir := (b - a) / seg_len
		var nrm := Vector3(-dir.z, 0.0, dir.x).normalized()
		lm.beam("Steel", a + Vector3(0.0, 0.04, 0.0), b + Vector3(0.0, 0.04, 0.0), 0.06, 0.08, Vector3.UP)
		var g_lo := 0.08
		var g_hi := h - 0.05
		lm.quad("RailGlass", a + Vector3(0.0, g_lo, 0.0), b + Vector3(0.0, g_lo, 0.0),
			b + Vector3(0.0, g_hi, 0.0), a + Vector3(0.0, g_hi, 0.0), nrm)
		lm.beam("Deck", a + Vector3(0.0, h - 0.02, 0.0), b + Vector3(0.0, h - 0.02, 0.0), 0.075, 0.055, Vector3.UP)
		var posts := maxi(int(round(seg_len / 1.8)), 1)
		for p_i in posts + 1:
			var p := a.lerp(b, float(p_i) / float(posts))
			lm.beam("Steel", p, p + Vector3(0.0, 0.24, 0.0), 0.045, 0.045)

static func _build_flues(lm: LandmarkMesh) -> void:
	var flues := [
		[-8.2, -0.4, 6.25, 8.60, 0.19],   # Tallest central smoke-sauna chimney (8.60 m)
		[-3.5, 2.4, 5.90, 7.98, 0.17],    # Southern sea-lobe stove flue
		[-13.2, 1.2, 5.80, 7.42, 0.20],   # Northern sea-lobe medium-thick flue
		[-16.8, -3.8, 5.25, 7.70, 0.18],  # NNE upper-slope sauna chimney
		[-20.5, -6.2, 3.70, 6.55, 0.19],  # NNE street-side steep bluff chimney
	]
	for f: Array in flues:
		var p := _p(float(f[0]), float(f[1]))
		var y0 := float(f[2])
		var y1 := float(f[3])
		var r := float(f[4])
		var cowl_y := y1 - 0.16
		var shaft_top := y1 - 0.25
		lm.frustum("Flue", Vector3(p.x, y0, p.y), r * 1.38, r * 1.25, 0.12, 12)
		lm.frustum("Flue", Vector3(p.x, y0, p.y), r, r * 0.96, shaft_top - y0, 12)
		lm.frustum("Flue", Vector3(p.x, shaft_top - 0.10, p.y), r * 1.12, r * 1.12, 0.06, 12)
		for st in 3:
			var ang := TAU * float(st) / 3.0
			var d := Vector3(cos(ang), 0.0, sin(ang)) * r * 0.80
			lm.beam("Flue", Vector3(p.x, shaft_top - 0.04, p.y) + d, Vector3(p.x, cowl_y + 0.02, p.y) + d, 0.024, 0.024)
		lm.lathe("Flue", Vector3(p.x, cowl_y, p.y), PackedVector2Array([
			Vector2(r * 1.46, 0.0), Vector2(r * 1.50, 0.03), Vector2(0.0, 0.16),
		]), 12)

static func _build_terrace_furnishings(lm: LandmarkMesh) -> void:
	var parasols := [
		[8.2, 12.6, 0.12], [12.4, 13.0, -0.05], [16.6, 13.2, 0.08],
		[20.8, 13.5, 0.04], [25.0, 14.0, -0.08], [29.2, 14.2, 0.14],
		[27.8, 8.8, 0.0], [31.6, 9.6, 0.28],
	]
	for ps: Array in parasols:
		var u_p := float(ps[0])
		var s_p := float(ps[1])
		var rot := float(ps[2])
		var base := _v(u_p, s_p, DECK_T1)
		lm.frustum("Dark", base, 0.30, 0.28, 0.06, 8)
		lm.frustum("Dark", base, 0.055, 0.05, 2.18, 8)
		var hw := 1.62
		var y_eave := DECK_T1 + 1.94
		var apex := _v(u_p, s_p, DECK_T1 + 2.34)
		var b_rot := _basis_u(rot)
		var corners := [
			base + Vector3(0.0, y_eave - DECK_T1, 0.0) + b_rot * Vector3(-hw, 0.0, -hw),
			base + Vector3(0.0, y_eave - DECK_T1, 0.0) + b_rot * Vector3(hw, 0.0, -hw),
			base + Vector3(0.0, y_eave - DECK_T1, 0.0) + b_rot * Vector3(hw, 0.0, hw),
			base + Vector3(0.0, y_eave - DECK_T1, 0.0) + b_rot * Vector3(-hw, 0.0, hw),
		]
		for i in 4:
			var c0: Vector3 = corners[i]
			var c1: Vector3 = corners[(i + 1) % 4]
			var fn := ((c1 - c0).cross(apex - c0)).normalized()
			if fn.y < 0.0:
				fn = -fn
			lm.tri("Canvas", c0, c1, apex, fn, fn, fn,
				Vector2(0.0, 0.0), Vector2(3.2, 0.0), Vector2(1.6, -1.7))
		lm.box("Dark", _v(u_p, s_p, DECK_T1 + 0.37), Vector3(0.12, 0.72, 0.12), b_rot, 0.0)
		lm.box("Deck", _v(u_p, s_p, DECK_T1 + 0.74), Vector3(1.15, 0.05, 1.15), b_rot, 0.0)

	# Twin-peaked white pagoda marquee pavilion at the SSW end of the sun deck.
	for s_tent in [4.2, 8.2]:
		var u_t := 37.8
		var s_t := float(s_tent)
		var hw_t := 1.95
		var y_e := DECK_T1 + 2.25
		var ap := _v(u_t, s_t, DECK_T1 + 3.30)
		for du in [-hw_t, hw_t]:
			for ds in [-hw_t, hw_t]:
				lm.beam("Steel", _v(u_t + float(du), s_t + float(ds), DECK_T1),
					_v(u_t + float(du), s_t + float(ds), y_e), 0.05, 0.05)
		var tc := [
			_v(u_t - hw_t, s_t - hw_t, y_e), _v(u_t + hw_t, s_t - hw_t, y_e),
			_v(u_t + hw_t, s_t + hw_t, y_e), _v(u_t - hw_t, s_t + hw_t, y_e),
		]
		for i in 4:
			var c0: Vector3 = tc[i]
			var c1: Vector3 = tc[(i + 1) % 4]
			var fn := ((c1 - c0).cross(ap - c0)).normalized()
			if fn.y < 0.0:
				fn = -fn
			lm.tri("Canvas", c0, c1, ap, fn, fn, fn,
				Vector2(0.0, 0.0), Vector2(3.9, 0.0), Vector2(1.95, -2.2))
			lm.beam("Canvas", c0 - Vector3(0.0, 0.12, 0.0), c1 - Vector3(0.0, 0.12, 0.0), 0.04, 0.24, Vector3.UP)

	lm.box("Slat", _v(34.8, 6.2, DECK_T1 + 0.54), Vector3(1.1, 1.08, 3.6), _basis_u(), 0.0)
	lm.box("Deck", _v(34.8, 6.2, DECK_T1 + 1.10), Vector3(1.25, 0.07, 3.75), _basis_u(), 0.0)

	for s_tbl in [0.4, 3.3]:
		lm.box("Canvas", _v(20.6, float(s_tbl), TERRACE_LOW + 0.75), Vector3(0.95, 0.05, 3.8), _basis_u(), 0.0)
		for du in [-1.4, 1.4]:
			lm.box("Steel", _v(20.6 + float(du), float(s_tbl), TERRACE_LOW + 0.37), Vector3(0.8, 0.72, 0.08), _basis_u(), 0.0)
	lm.beam("Canvas", _v(7.2, 6.95, TERRACE_LOW + 0.92), _v(25.2, 6.95, TERRACE_LOW + 0.92), 0.42, 0.05, Vector3.UP)
	for u_hi in [-9.2, -5.0]:
		lm.box("Canvas", _v(float(u_hi), -4.2, TERRACE_HIGH + 0.74), Vector3(0.9, 0.05, 1.6), _basis_u(), 0.0)

	# Sleek dark sea-facing deck loungers inset cleanly inside the zig-zag Tier 4 boardwalk.
	var lounger_rows := [
		[-6.2, 4.8, 7, 25.0, DECK_T4],
		[11.5, 24.5, 7, 21.8, DECK_T4],
		[28.5, 42.5, 7, 17.2, DECK_T4],
	]
	for row: Array in lounger_rows:
		var n_ch := int(row[2])
		for i in n_ch:
			var u_c := lerpf(float(row[0]), float(row[1]), float(i) / float(maxi(n_ch - 1, 1)))
			var s_c := float(row[3])
			var y_c := float(row[4])
			lm.box("Dark", _v(u_c, s_c, y_c + 0.22), Vector3(0.60, 0.06, 1.10), _basis_u(), 0.0)
			lm.beam("Dark", _v(u_c, s_c - 0.42, y_c + 0.24), _v(u_c, s_c - 0.80, y_c + 0.70),
				0.56, 0.05, Vector3(AX_U.x, 0.0, AX_U.y))

	for pl: Array in [[-15.6, 16.4, DECK_T1], [-6.8, 24.0, DECK_T3], [4.8, 23.2, DECK_T3],
			[8.8, 19.8, DECK_T3], [24.2, 22.0, DECK_T3], [16.0, 17.2, DECK_T1]]:
		var pp := _p(float(pl[0]), float(pl[1]))
		lm.frustum("Dark", Vector3(pp.x, float(pl[2]), pp.y), 0.28, 0.34, 0.62, 10)
