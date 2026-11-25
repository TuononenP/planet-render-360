extends RefCounted

## Helsinki City Hall (Kaupungintalo, Engel, 1833), Pohjoisesplanadi 11-13
## facing the Market Square. Model origin at the centre of the OSM outline
## (way 24337154, 71 x 75 m), front +Z; yaw -3 follows the street grid, the
## front looks south over the harbour.
##
## From the photos (visual-plan/refs/landmarks/helsinki_city_hall/):
## - A 71 m front range of pale blue-grey stucco on a reddish granite
##   plinth (1.8 m): a rusticated grey ground floor, two storeys of
##   windows (25 bays, pitch 2.75 m, three rows) and a white dentilled
##   cornice at 13.2-14.5 m under a low pale-grey sheet-metal hip roof.
## - Fluted giant pilasters pair up at both ends. In the middle a
##   single-storey porch of six columns (planter boxes along its deck) stands
##   out 4 m; above it six pilasters carry a pediment to 16.8 m.
## - Behind the pediment a white drum with arched windows carries a green
##   copper dome and gilt finial to 25 m, with two small green domes
##   either side of it. The rear complex is filled to the OSM outline.
##
## Measured: outline and bearing (OSM). The 25 m height to the finial is
## read from a front photo scaled by the 71 m width (OSM `height=6` is
## wrong). Counted: 25 bays, three rows, six columns. Estimated: floor
## heights, rear window rhythm, roof pitch.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const E = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_empire.gd")

const ENTRY := {"type": "helsinki_city_hall", "name": "Helsinki City Hall", "lat": 60.168352, "lon": 24.952863,
	"radius_m": 1500.0, "wiki_title": "Helsinki City Hall", "height_m": 25.0, "clear_m": 32.0,
	"clear_offsets_m": [[0.0, 24.0], [0.0, -8.0], [-18.0, 24.0], [18.0, 24.0], [-18.0, -8.0], [18.0, -8.0],
		[-18.0, -30.0], [18.0, -30.0]],
	"yaw_deg": -3.0, "kind": "City hall", "aliases": ["helsinki city hall", "helsingin kaupungintalo", "helsingfors stadshus"]}

const XL := -35.6
const XR := 35.2
const ZF := 37.3
const PLINTH := 1.8
const F1 := 5.4
const EAVE := 13.2
const BAYS := 25

static func _outline() -> PackedVector2Array:
	return PackedVector2Array([Vector2(-35.1, -16.9), Vector2(-35.0, -31.1), Vector2(-14.6, -31.0), Vector2(-14.6, -34.1),
		Vector2(7.5, -34.0), Vector2(7.5, -37.4), Vector2(13.8, -37.3), Vector2(13.7, -15.1), Vector2(25.4, -15.0),
		Vector2(25.5, -18.8), Vector2(35.6, -18.7), Vector2(35.2, ZF), Vector2(-35.6, ZF)])

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#9DACBE", 3.0))
	lm.use("Rust", LandmarkMaterials.pbr("render", "#B7BEC6", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F0EFEA", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#93604B", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#AEB4B8", 3.0, 0.55, 0.35))
	lm.use("Glass", LandmarkMaterials.glass("#2B3237"))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#5F8D78", 2.0, 0.5, 0.3))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Flowers", LandmarkMaterials.paint("#B9505F", 0.8, 0.0))
	var poly := _outline()
	lm.poly_prism("Stone", _grow(poly, 0.25), 0.0, PLINTH)
	lm.poly_prism("Wall", poly, PLINTH, EAVE)
	# Rear complex: flat dark-grey roof at the eaves.
	var rear := PackedVector2Array([Vector2(-35.0, -31.0), Vector2(7.5, -34.0), Vector2(13.8, -37.3), Vector2(13.7, -15.0),
		Vector2(35.6, -18.7), Vector2(35.2, 12.0), Vector2(-35.6, 12.0)])
	lm.poly_prism("Roof", _grow(rear, -0.4), EAVE, EAVE + 0.08)
	_front(lm)
	_flanks(lm, poly)
	_porch(lm)
	_roof(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-22.0, 3.0, ZF + 26.0), Vector3(-14.0, 9.0, ZF), 40.0, 0.9, 55.0, warm],
		[Vector3(22.0, 3.0, ZF + 26.0), Vector3(14.0, 9.0, ZF), 40.0, 0.9, 55.0, warm],
		[Vector3(0.0, 3.0, ZF + 28.0), Vector3(0.0, 12.0, ZF + 3.0), 30.0, 0.8, 55.0, warm],
	])

static func _grow(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var c := LandmarkFhParts.centre(poly)
	var out := PackedVector2Array()
	for p in poly:
		out.append(p + (p - c).normalized() * d)
	return out

static func _front(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	var a := Vector3(XL + 1.2, 0, ZF)
	var b := Vector3(XR - 1.2, 0, ZF)
	# Rusticated ground floor skin and its joints.
	U.blk(lm, "Rust", (XL + XR) * 0.5, PLINTH, ZF + 0.08, XR - XL, F1 - PLINTH, 0.16)
	for k in 5:
		E.course(lm, "Stone", Vector2(XL, ZF), Vector2(XR, ZF), Vector2(0, 1), PLINTH + 0.6 + 0.65 * float(k), 0.06, 0.2)
	E.row(lm, "Trim", "Glass", a, b, out, 2.4, BAYS, 1.4, 2.6, "plain")
	E.row(lm, "Trim", "Glass", a, b, out, 6.2, BAYS, 1.3, 2.5, "rect")
	E.row(lm, "Trim", "Glass", a, b, out, 10.1, BAYS, 1.3, 2.3, "rect")
	var a2 := Vector2(XL, ZF)
	var b2 := Vector2(XR, ZF)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), F1 - 0.2, 0.4, 0.22)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), PLINTH - 0.05, 0.3, 0.3)
	LandmarkDetail.cornice(lm, "Trim", Vector3(XL, EAVE - 1.1, ZF), Vector3(XR, EAVE - 1.1, ZF), out, 1.4, true)
	# Giant fluted pilasters, paired at both ends.
	for x in [XL + 0.7, XL + 2.4, XR - 0.7, XR - 2.4]:
		E.pilaster(lm, "Trim", Vector3(x, 0, ZF), out, F1, EAVE - 1.1 - F1, 0.9, 0.3)
	var pitch := (b.x - a.x) / float(BAYS)
	for k in range(10, 16):
		E.pilaster(lm, "Trim", Vector3(a.x + float(k) * pitch, 0, ZF), out, F1, EAVE - 1.1 - F1, 0.7, 0.3)

static func _flanks(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	var rows := [[2.4, 1.3, 2.4, "plain"], [6.2, 1.3, 2.5, "plain"], [10.1, 1.3, 2.3, "plain"]]
	E.poly_walls(lm, "Trim", "Glass", poly, 3.0, rows, 1.2, 5.0, Vector2(0, 1), 0.9)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a.distance_to(b) < 5.0:
			continue
		var o3 := LandmarkFhParts.edge_out(poly, i)
		if o3.z > 0.9:
			continue
		E.course(lm, "Trim", a, b, Vector2(o3.x, o3.z), EAVE - 1.0, 1.0, 0.4)

## The single-storey porch of six columns, its planter deck and pediment.
static func _porch(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	var pitch := (XR - XL - 2.4) / float(BAYS)
	var x0 := XL + 1.2 + 10.0 * pitch
	var x1 := XL + 1.2 + 15.0 * pitch
	var cx := (x0 + x1) * 0.5
	var depth := 4.0
	U.blk(lm, "Stone", cx, 0.0, ZF + depth * 0.5, x1 - x0 + 3.4, 1.2, depth)
	for i in 6:
		var x := x0 + (x1 - x0) * float(i) / 5.0
		LandmarkDetail.column(lm, "Trim", Vector3(x, 1.2, ZF + depth - 0.7), 0.5, F1 - 1.2 - 0.6, "tuscan", 0, 14)
	# Deck slab, planter boxes and the dark doorways behind the columns.
	U.blk(lm, "Trim", cx, F1 - 0.6, ZF + depth * 0.5, x1 - x0 + 3.0, 0.6, depth + 0.3)
	U.blk(lm, "Flowers", cx, F1, ZF + depth - 0.1, x1 - x0 + 2.4, 0.5, 0.5)
	for k in 3:
		var x := cx + (float(k) - 1.0) * 3.0
		E.win(lm, "Trim", "Glass", Vector3(x, 1.4, ZF), out, 2.0, 3.4, "arch")
	# Pediment over the six pilasters.
	lm.gable("Trim", Vector3(cx, EAVE, ZF - 0.5), x1 - x0 + 3.4, 1.4, 2.4, Basis(), 0.0, "Wall")
	lm.disc("Gilt", Vector3(cx, EAVE + 1.2, ZF + 0.25), out, 0.5, 14)
	U.steps(lm, "Stone", Vector3(cx, 0, ZF + depth + 0.2), out, x1 - x0 + 1.0, 0.4, 0.2, 6)

static func _roof(lm: LandmarkMesh) -> void:
	var cx := (XL + XR) * 0.5
	U.hip(lm, "Roof", Vector3(cx, EAVE, (12.0 + ZF) * 0.5), XR - XL + 0.8, ZF - 12.0 + 0.8, 1.6, 0.92)
	var dc := Vector3(-0.2, EAVE + 1.5, 24.0)
	var drum_y0 := EAVE + 0.6
	lm.frustum("Trim", Vector3(dc.x, drum_y0, dc.z), 3.4, 3.4, (dc.y + 3.8) - drum_y0, 24)
	for k in 8:
		var an := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(an), 0, sin(an))
		LandmarkDetail.window(lm, "Trim", "Glass", dc + d * 3.4 + Vector3(0, 1.9, 0), d, 1.0, 2.0, true, 0.15)
	lm.frustum("Trim", dc + Vector3(0, 3.8, 0), 3.7, 3.7, 0.45, 24)
	lm.lathe("Dome", dc + Vector3(0, 4.25, 0), U.dome_prof(3.6, 3.2), 24)
	lm.frustum("Trim", dc + Vector3(0, 7.4, 0), 0.7, 0.7, 1.1, 8)
	lm.lathe("Gilt", dc + Vector3(0, 8.5, 0), U.ball(0.3), 8)
	lm.box("Gilt", dc + Vector3(0, 9.7, 0), Vector3(0.1, 1.4, 0.1))
	for s in [-1.0, 1.0]:
		var sc := Vector3(s * 12.5, EAVE + 1.45, 24.0)
		lm.frustum("Trim", Vector3(sc.x, drum_y0, sc.z), 1.1, 1.1, (sc.y + 1.4) - drum_y0, 12)
		lm.lathe("Dome", sc + Vector3(0, 1.4, 0), U.dome_prof(1.15, 1.0), 12)
