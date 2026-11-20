class_name FtVartiovuoriObservatory
extends RefCounted

## Vartiovuori Observatory (Vartiovuoren tähtitorni, Carl Ludvig Engel, 1819)
## crowning Vartiovuorenmäki hill overlooking Turku Cathedral and Aurajoki.
## Origin at OSM way 17037200 centroid (60.448699 N, 22.276653 E), yaw_deg 0.5:
##   +X bears 90.5° (East, east Empire wing)
##   -X bears 270.5° (West, west Empire wing)
##   -Z bears 0.5° (North, 4-column portico overlooking Turku Cathedral & city)
##   +Z bears 180.5° (South, symmetrical Vartiovuori park facade)
##
## Architectural & facade spec (counted from Wikimedia Commons / Finna refs
## and OSM way 17037200 / rotunda way 317221112: 29.3 x 33.5 m, rotunda
## 14.1 m dia, wings ~7.5-9 m, 12° hipped roof, registry height_m = 18.0):
## - Rusticated grey-granite hilltop plinth (foundation dropped to y = -3.8 m
##   for Vartiovuorenmäki bedrock crest, top at y = 1.8 m).
## - Symmetric two-storey Empire main block (33.6 x 15.6 m, eaves 9.0 m) in
##   pale cream-yellow render with white string course, corner pilasters,
##   moulded dentil cornice, two tiers of tall framed casements, low 12° dark
##   sheet-metal hipped roof (to 11.1 m), and 4 symmetrical chimney stacks.
## - 4-column classical Ionic north portico (-Z, facing Cathedral & city):
##   5 broad granite steps, 4 fluted white columns (h = 6.6 m), entablature
##   with dentil cornice, triangular pediment with cream-yellow tympanum,
##   and arched Empire double timber entrance portal with fanlight.
## - Shallow central pilastered south park projection (+Z) with low pediment
##   and stone garden steps.
## - Central cylindrical observation rotunda (r = 5.4 m drum on r = 6.5 m base,
##   y = 9.0..18.0 m): wrought-iron belvedere railing around the observation
##   deck, 12 tall arched/framed casement windows between 12 white pilasters
##   with warm night interior glow, moulded cornice, and conical dark-metal
##   observatory dome with standing seams and finial peaking at 18.0 m.
## - Night illumination: warm upward floodlights (LandmarkLights.FLOOD_META)
##   on the north portico, central rotunda and south front + rotunda glow.

const FOUND := -3.8
const PLINTH_Y := 1.8
const EAVE_Y := 9.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EFE6CC", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F7F4EC", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8B8780", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#383D40", 2.5, 0.52, 0.40))
	lm.use("Iron", LandmarkMaterials.paint("#25282B", 0.45, 0.65))
	lm.use("Glass", LandmarkMaterials.glass("#202930"))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#4B3828", 1.5))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE2A8", 0.90))

	_build_wings(lm)
	_build_north_portico(lm)
	_build_south_projection(lm)
	_build_rotunda(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.93, 0.80)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-6.5, 1.0, -17.5), Vector3(0.0, 7.5, -9.5), 32.0, 1.05, 55.0, warm],
		[Vector3(6.5, 1.0, -17.5), Vector3(0.0, 7.5, -9.5), 32.0, 1.05, 55.0, warm],
		[Vector3(-12.0, 1.0, -13.0), Vector3(0.0, 14.5, 0.0), 26.0, 0.95, 60.0, warm],
		[Vector3(12.0, 1.0, 14.0), Vector3(0.0, 14.5, 0.0), 28.0, 0.85, 60.0, warm],
		[Vector3(0.0, 1.0, 16.5), Vector3(0.0, 6.5, 8.5), 34.0, 0.80, 50.0, warm],
	])

static func _build_wings(lm: LandmarkMesh) -> void:
	# Rusticated grey-granite plinth dropped below y = 0 for hilltop seating.
	LandmarkFrKit.rect(lm, "Stone", -17.3, 17.3, -8.3, 8.3, FOUND, PLINTH_Y)
	LandmarkFrParts.band(lm, "Trim", -17.1, 17.1, -8.1, 8.1, PLINTH_Y - 0.25, 0.28, 0.14)
	# Symmetric two-storey Empire wings (-16.8..16.8 x -7.8..7.8, eaves 9.0 m).
	LandmarkFrKit.rect(lm, "Wall", -16.8, 16.8, -7.8, 7.8, PLINTH_Y, EAVE_Y)
	LandmarkFrParts.corner_strips(lm, "Trim", -16.8, 16.8, -7.8, 7.8, PLINTH_Y, EAVE_Y, 0.65, 0.14)
	LandmarkFrParts.band(lm, "Trim", -16.8, 16.8, -7.8, 7.8, 5.15, 0.30, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", -16.8, 16.8, -7.8, 7.8, EAVE_Y - 0.55, 0.55)
	# Low-pitched 12° dark sheet-metal hipped roof (y = 9.0..11.1 m).
	LandmarkFrKit.hip(lm, "Roof", -16.8, 16.8, -7.8, 7.8, EAVE_Y, 2.1, 0.55)
	# 4 symmetric dark-metal chimney stacks on the wing roofs.
	for cx: float in [-12.5, -8.5, 8.5, 12.5]:
		LandmarkFrParts.chimney(lm, "Roof", Vector3(cx, 9.8, -2.0 if absf(cx) > 10.0 else 2.0), 12.4, 1.0, 0.9)
	# Two tiers of framed Empire casement windows on both long fronts (flanking central porticos).
	for sz: float in [-1.0, 1.0]:
		var n := Vector3(0.0, 0.0, sz)
		for side: Array in [[-15.2, -6.4], [6.4, 15.2]]:
			var xa: float = side[0]
			var xb: float = side[1]
			LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(xa, 2.55, sz * 7.8), Vector3(xb, 2.55, sz * 7.8),
				n, 3, 1.25, 2.15, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 1)
			LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(xa, 5.95, sz * 7.8), Vector3(xb, 5.95, sz * 7.8),
				n, 3, 1.25, 2.25, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 1)
	# End facades (-X and +X): 3 bays x 2 storeys with central arched piano nobile window.
	for sx: float in [-1.0, 1.0]:
		var n := Vector3(sx, 0.0, 0.0)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 16.8, 2.55, -5.8), Vector3(sx * 16.8, 2.55, 5.8),
			n, 3, 1.25, 2.15, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(sx * 16.8, 5.95, -5.8), Vector3(sx * 16.8, 5.95, 5.8),
			n, 3, 1.25, 2.25, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 1)

static func _build_north_portico(lm: LandmarkMesh) -> void:
	# 4-column classical north portico (-Z) overlooking Turku Cathedral & city.
	LandmarkFrKit.rect(lm, "Stone", -5.2, 5.2, -11.0, -7.8, FOUND, PLINTH_Y)
	# 5 broad granite entrance steps descending north (-Z, z = -13.0..-11.0).
	for s in 5:
		var sy := lerpf(0.32, PLINTH_Y, float(s + 1) / 5.0)
		var z0 := -13.0 + float(s) * 0.40
		LandmarkFrKit.rect(lm, "Stone", -4.8, 4.8, z0, -10.8, FOUND, sy)
	for sx: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Stone", sx * 5.1 - 0.35, sx * 5.1 + 0.35, -13.1, -10.8, FOUND, 2.1)
	# Four fluted white Ionic columns across the north front (z = -10.45, h = 6.55 m).
	for cx: float in [-3.9, -1.3, 1.3, 3.9]:
		LandmarkDetail.column(lm, "Trim", Vector3(cx, PLINTH_Y, -10.45), 0.34, 6.55, "ionic", 16, 12)
	# Portico entablature (y = 8.35..9.25 m) and dentil cornice.
	LandmarkFrKit.rect(lm, "Trim", -4.95, 4.95, -10.95, -7.6, 8.35, 9.05)
	LandmarkDetail.cornice(lm, "Trim", Vector3(5.05, 8.95, -10.95), Vector3(-5.05, 8.95, -10.95),
		Vector3.FORWARD, 0.42, true)
	# Classical triangular pediment (y = 9.25..11.15 m) + dark sheet-metal portico roof.
	LandmarkFrKit.gable(lm, "Roof", -5.0, 5.0, -11.0, -7.5, 9.20, 1.95, 0.25, "Wall", 0)
	lm.beam("Trim", Vector3(-5.2, 9.18, -11.12), Vector3(0.0, 11.20, -11.12), 0.28, 0.28, Vector3.FORWARD)
	lm.beam("Trim", Vector3(5.2, 9.18, -11.12), Vector3(0.0, 11.20, -11.12), 0.28, 0.28, Vector3.FORWARD)
	lm.box("Trim", Vector3(0.0, 9.22, -11.12), Vector3(10.4, 0.18, 0.24), Basis(), 0.0)
	# Grand arched north entrance doorway & upper centre window behind columns.
	LandmarkFrParts.opening(lm, "Trim", "Door", Vector3(0.0, PLINTH_Y, -7.82), Vector3.FORWARD,
		2.2, 3.8, LandmarkFrParts.HEAD_ROUND, 0.26, 0.16, 0)
	lm.box("WarmGlow", Vector3(0.0, PLINTH_Y + 3.15, -7.88), Vector3(1.4, 0.72, 0.05), Basis(), 0.0)
	for wx: float in [-2.75, 2.75]:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 2.55, -7.82), Vector3.FORWARD,
			1.2, 2.15, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 1)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 5.95, -7.82), Vector3.FORWARD,
			1.2, 2.25, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 1)

static func _build_south_projection(lm: LandmarkMesh) -> void:
	# Shallow central Empire risalit on the south park side (+Z, z = 7.8..9.6).
	LandmarkFrKit.rect(lm, "Stone", -5.8, 5.8, 7.6, 9.8, FOUND, PLINTH_Y)
	LandmarkFrKit.rect(lm, "Wall", -5.5, 5.5, 7.6, 9.5, PLINTH_Y, EAVE_Y)
	for px: float in [-4.9, -1.75, 1.75, 4.9]:
		lm.box("Trim", Vector3(px, 5.4, 9.58), Vector3(0.55, 6.8, 0.18), Basis(), 0.0)
	LandmarkFrKit.gable(lm, "Roof", -5.6, 5.6, 7.4, 9.6, EAVE_Y, 1.85, 0.25, "Wall", 0)
	lm.beam("Trim", Vector3(-5.75, EAVE_Y, 9.72), Vector3(0.0, EAVE_Y + 1.9, 9.72), 0.26, 0.26, Vector3.BACK)
	lm.beam("Trim", Vector3(5.75, EAVE_Y, 9.72), Vector3(0.0, EAVE_Y + 1.9, 9.72), 0.26, 0.26, Vector3.BACK)
	# Garden steps and arched south doorway + upper windows.
	for s in 4:
		var sy := lerpf(0.4, PLINTH_Y, float(s + 1) / 4.0)
		LandmarkFrKit.rect(lm, "Stone", -3.2, 3.2, 9.6, 11.4 - float(s) * 0.42, FOUND, sy)
	LandmarkFrParts.opening(lm, "Trim", "Door", Vector3(0.0, PLINTH_Y, 9.52), Vector3.BACK,
		2.0, 3.5, LandmarkFrParts.HEAD_ROUND, 0.24, 0.14, 0)
	for wx: float in [-3.35, 3.35]:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 2.55, 9.52), Vector3.BACK,
			1.15, 2.15, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 1)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 5.95, 9.52), Vector3.BACK,
			1.15, 2.25, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 1)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(0.0, 5.95, 9.52), Vector3.BACK,
		1.35, 2.35, LandmarkFrParts.HEAD_ROUND, 0.20, 0.12, 1)

static func _build_rotunda(lm: LandmarkMesh) -> void:
	# Circular base drum rising through the hipped roof (r = 6.5 m, y = 8.6..10.4 m).
	lm.frustum("Wall", Vector3(0.0, 8.6, 0.0), 6.55, 6.50, 1.85, 28)
	lm.frustum("Trim", Vector3(0.0, 10.22, 0.0), 6.68, 6.72, 0.28, 28)
	# Wrought-iron belvedere observation railing encircling the rotunda deck (y = 10.5..11.65 m).
	LandmarkFrParts.ring_railing(lm, "Iron", Vector3(0.0, 10.5, 0.0), 6.45, 1.15, 32, 0.065)
	# Cylindrical observation rotunda shaft (r = 5.4 m, y = 10.4..15.2 m).
	lm.frustum("Wall", Vector3(0.0, 10.4, 0.0), 5.45, 5.40, 4.8, 28)
	# 12 slender white pilasters & 12 tall Empire casement windows with warm night glow.
	for i in 12:
		var a := TAU * float(i) / 12.0
		var out := Vector3(cos(a), 0.0, sin(a))
		var b := Basis(Vector3.UP, atan2(out.x, out.z))
		lm.box("Trim", out * 5.46 + Vector3(0.0, 12.8, 0.0), Vector3(0.36, 4.2, 0.14), b, 0.0)
		var wa := a + PI / 12.0
		var wn := Vector3(cos(wa), 0.0, sin(wa))
		LandmarkFrParts.opening(lm, "Trim", "Glass", wn * 5.42 + Vector3(0.0, 11.45, 0.0), wn,
			1.05, 2.55, LandmarkFrParts.HEAD_FLAT, 0.16, 0.09, 1)
		lm.box("WarmGlow", wn * 5.40 + Vector3(0.0, 12.7, 0.0), Vector3(0.68, 1.85, 0.04),
			Basis(Vector3.UP, atan2(wn.x, wn.z)), 0.0)
	# Moulded rotunda entablature & cornice (y = 14.8..15.35 m).
	lm.frustum("Trim", Vector3(0.0, 14.82, 0.0), 5.58, 5.68, 0.28, 28)
	lm.frustum("Trim", Vector3(0.0, 15.10, 0.0), 5.72, 5.82, 0.28, 28)
	# Conical dark-metal observatory dome (y = 15.35..17.45 m) with standing-seam ribs.
	lm.lathe("Roof", Vector3(0.0, 15.35, 0.0), PackedVector2Array([
		Vector2(5.90, 0.0), Vector2(4.20, 0.65), Vector2(2.15, 1.45), Vector2(0.28, 2.10),
	]), 28, 1.0, 1.0, 0.0, false)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var p0 := Vector3(cos(a) * 5.92, 15.36, sin(a) * 5.92)
		var p1 := Vector3(cos(a) * 0.30, 17.45, sin(a) * 0.30)
		lm.beam("Iron", p0, p1, 0.07, 0.07)
	# Apex ventilator cap & slender weathervane finial peaking at 18.0 m.
	lm.frustum("Roof", Vector3(0.0, 17.35, 0.0), 0.38, 0.22, 0.30, 12)
	lm.beam("Iron", Vector3(0.0, 17.60, 0.0), Vector3(0.0, 18.0, 0.0), 0.06, 0.06)
