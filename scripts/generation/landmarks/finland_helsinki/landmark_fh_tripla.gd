extends RefCounted

## Mall of Tripla & Pasila railway station (Pasilan rautatieasema, 2019),
## extruded from the mapped complex outline (LandmarkFhMallFootprints), 30 m
## flat roof.
##
## The complex has two structural halves:
## - West Mall of Tripla podium (x < ~110 m): grounded from y = 0..27.5 m with
##   the white-green translucent sawtooth glass fin skin above a glazed
##   shopfront storey, white mushroom columns on the south Pasilansilta plaza,
##   and the red rooftop sign.
## - East Pasila station concourse bridge (Pasilan rautatieasema, OSM way
##   621975602, x ≈ 105..231 m, z ≈ -111..10 m): elevated over all 11 railway
##   tracks (open 7.5 m track portal underneath with concrete piers aligned on
##   the 6 platform islands, warm recessed portal ceiling strips, and 6 glazed
##   escalator/stair pavilions along the north edge for tracks 1-2..11).
##
## The towers around it (Original Sokos Hotel Tripla, Tripla Workery West,
## apartments: 37-50 m in OSM) are separate OSM buildings.
##
## Measured: outline, station bridge polygon, track-island pier alignments and
## pavilion centres from OSM; 30 m registry height. Estimated: 7.5 m portal
## clearance, fin width (1.6 m) and depth (0.55 m), mushroom count, sign length.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")

const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const PORTAL_H := 7.5
## East station concourse bridge polygon (OSM way 621975602, Pasilan rautatieasema).
const STATION_OUTLINE := [
	105.3, -86.4, 115.3, -45.0, 121.2, -18.9, 128.1, 10.3, 145.0, 6.4, 140.1, -14.1,
	209.5, -30.3, 214.5, -10.1, 231.3, -13.9, 208.4, -110.6, 191.4, -106.6, 196.3, -85.6,
	127.2, -69.5, 122.3, -90.4]
## West Mall of Tripla podium polygon (grounded to y = 0, west of the railway corridor).
const MALL_OUTLINE := [
	101.6, -41.8, 91.7, -83.3, -119.5, -33.7, -110.2, 5.5, -93.3, 1.6, -88.9, 20.4,
	-105.7, 24.5, -96.6, 63.3, -60.8, 54.9, -48.9, 107.9, 6.2, 94.6, 5.1, 90.4,
	82.2, 71.9, 86.2, 66.2, 76.0, 22.7, 114.8, 13.6, 108.1, -14.2]
## Glazed north-edge escalator/stair access pavilions (OSM ways 1245442056..1134546156:
## platforms 1-2, 3-4, 5-6, 7-8, 9-10, 11) and platform-island pier lines running SSE
## along track direction (0.233, 0.972).
const PAVILIONS := [
	Vector2(194.1, -104.0), Vector2(176.9, -99.3), Vector2(158.1, -94.4),
	Vector2(138.5, -89.9), Vector2(115.8, -107.9), Vector2(103.5, -104.8)]
const TRACK_DIR := Vector2(0.233, 0.972)

const ENTRY := {"type": "mall_of_tripla", "name": "Mall of Tripla", "lat": 60.198376, "lon": 24.930295,
	"radius_m": 4000.0, "wiki_title": "Mall of Tripla", "height_m": 30.0, "clear_m": 40.0,
	"no_roof_deck": true,
	"clear_offsets_m": [
		[-44.0, 0.0], [26.0, 40.0], [56.0, -30.0], [166.0, -50.0], [-29.0, 65.0], [-4.0, -30.0],
		[81.0, -15.0], [-69.0, 0.0], [196.0, -55.0], [141.0, -40.0], [46.0, 55.0], [-64.0, 30.0],
		[61.0, -50.0], [-74.0, -15.0], [6.0, 45.0], [-44.0, -10.0], [141.0, -45.0], [21.0, -25.0],
		[36.0, 10.0], [201.0, -65.0], [136.0, -50.0], [206.0, -50.0], [136.0, -35.0],
		[-79.0, -20.0], [104.0, -105.0], [116.0, -108.0], [139.0, -90.0], [158.0, -94.0],
		[177.0, -99.0], [194.0, -104.0]],
	"kind": "Shopping centre", "aliases": ["mall of tripla", "kauppakeskus tripla", "tripla pasila",
		"pasila station", "pasilan rautatieasema", "böle station"]}

static func build(model: Node3D) -> void:
	var h := 30.0
	var wall := "#A8A29A"
	var accent := "#38505A"
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", wall, 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#40555F"))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", accent, 2.0))
	lm.use("Roof", LandmarkMaterials.paint("#5A5E60", 0.7))
	lm.use("Fin", LandmarkMaterials.lit("#BCD9D1", 0.3))
	lm.use("Sign", LandmarkMaterials.lit("#FF3B2A", 1.8))
	lm.use("SignWhite", LandmarkMaterials.lit("#F5F7FA", 1.5))
	lm.use("Mush", LandmarkMaterials.paint("#F4F2EC", 0.35, 0.1))
	lm.use("Pier", LandmarkMaterials.pbr("concrete", "#8C8A84", 2.5))
	lm.use("PortalLamp", LandmarkMaterials.lit("#FFE8C2", 1.4))

	var mall_poly := _poly(MALL_OUTLINE)
	var station_poly := _poly(STATION_OUTLINE)
	# West mall podium grounded to y = 0.
	lm.poly_prism("Wall", mall_poly, 0.0, h - 2.5)
	lm.poly_prism("Glass", F.offset(mall_poly, 0.06), 0.4, 4.0, false)
	lm.poly_prism("Trim", F.offset(mall_poly, 0.2), 4.0, 4.5)
	for i in mall_poly.size():
		_fins(lm, mall_poly, i, 4.5, h - 2.5)
	_roof_details(lm, mall_poly, h)

	# East Pasila station concourse bridge elevated above the 11 railway tracks (y = PORTAL_H..h-2.5).
	lm.poly_prism("Wall", station_poly, PORTAL_H, h - 2.5)
	lm.poly_prism("Trim", F.offset(station_poly, 0.2), PORTAL_H - 0.35, PORTAL_H + 0.45)
	lm.poly_prism("Glass", F.offset(station_poly, 0.06), PORTAL_H + 0.45, PORTAL_H + 4.2, false)
	for i in station_poly.size():
		_fins(lm, station_poly, i, PORTAL_H + 4.2, h - 2.5)
	_roof_details(lm, station_poly, h)
	_station_portal_and_pavilions(lm, station_poly)

	# Skybridge neck linking mall and station concourse above the westernmost track.
	var neck_basis := Basis(Vector3.UP, atan2(-0.233, 0.972))
	lm.box("Wall", Vector3(111.5, (PORTAL_H + h - 2.5) * 0.5, -28.0), Vector3(14.0, h - 2.5 - PORTAL_H, 28.0), neck_basis)
	lm.box("Trim", Vector3(111.5, PORTAL_H + 0.1, -28.0), Vector3(14.6, 0.8, 28.4), neck_basis)

	_entrance(lm, mall_poly, h)
	_station_signage(lm, h)
	lm.commit(model)
	var warm := Color(1.0, 0.90, 0.76)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(20.0, 1.5, 118.0), Vector3(15.0, 16.0, 85.0), 56.0, 0.95, 90.0, warm],
		[Vector3(-70.0, 1.5, 95.0), Vector3(-60.0, 16.0, 65.0), 56.0, 0.9, 85.0, warm],
		[Vector3(-10.0, 1.5, -85.0), Vector3(-10.0, 16.0, -55.0), 56.0, 0.85, 85.0, warm],
		[Vector3(160.0, 1.5, -125.0), Vector3(160.0, 16.0, -95.0), 56.0, 0.85, 85.0, warm],
		[Vector3(-135.0, 1.5, 15.0), Vector3(-105.0, 16.0, 15.0), 54.0, 0.85, 80.0, warm],
		[Vector3(245.0, 1.5, -55.0), Vector3(220.0, 16.0, -55.0), 54.0, 0.85, 80.0, warm],
	])

static func _poly(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		out.append(Vector2(float(flat[i]), float(flat[i + 1])))
	return out

static func _roof_details(lm: LandmarkMesh, poly: PackedVector2Array, h: float) -> void:
	var roof := F.offset(poly, -2.0)
	if roof.size() < 3:
		return
	lm.poly_prism("Roof", roof, h - 2.5, h - 1.3)
	var inner := F.offset(poly, -8.0)
	if inner.size() < 3:
		return
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in inner:
		lo = lo.min(p)
		hi = hi.max(p)
	for gx in range(int(lo.x / 40.0) - 1, int(hi.x / 40.0) + 2):
		for gz in range(int(lo.y / 40.0) - 1, int(hi.y / 40.0) + 2):
			var c := Vector2(float(gx) * 40.0, float(gz) * 40.0)
			if not F.rect_inside(inner, c, Vector2(22.0, 11.0)):
				continue
			if posmod(gx + gz, 2) == 0:
				U.blk(lm, "Roof", c.x, h - 1.3, c.y, 16.0, 1.3, 9.0)
			else:
				U.blk(lm, "Glass", c.x, h - 1.25, c.y, 22.0, 0.5, 5.0)

## Structural piers on the 6 platform islands under the elevated concourse
## bridge, recessed portal ceiling light strips, and the 6 glazed north-edge
## escalator/stair access pavilions (platforms 1-2 .. 11).
static func _station_portal_and_pavilions(lm: LandmarkMesh, station_poly: PackedVector2Array) -> void:
	var track_yaw := atan2(-TRACK_DIR.x, TRACK_DIR.y)
	var track_basis := Basis(Vector3.UP, track_yaw)
	for pav: Vector2 in PAVILIONS:
		# Glazed escalator/stair access pavilion descending from concourse deck to platform.
		lm.box("Glass", Vector3(pav.x, 4.1, pav.y), Vector3(5.6, 7.2, 9.2), track_basis)
		lm.box("Trim", Vector3(pav.x, 7.85, pav.y), Vector3(6.0, 0.5, 9.6), track_basis)
		lm.box("PortalLamp", Vector3(pav.x, 4.0, pav.y), Vector3(3.8, 5.2, 7.4), track_basis)
		# Concrete piers along this platform island's centreline underneath the bridge deck.
		for d: float in [24.0, 44.0, 64.0, 82.0]:
			var p := pav + TRACK_DIR * d
			if Geometry2D.is_point_in_polygon(p, station_poly):
				lm.box("Pier", Vector3(p.x, PORTAL_H * 0.5, p.y), Vector3(1.1, PORTAL_H + 0.1, 1.8), track_basis)
		# Warm linear soffit light strip under the portal along each platform island.
		var l_start := pav + TRACK_DIR * 18.0
		var l_end := pav + TRACK_DIR * 78.0
		var l_mid := (l_start + l_end) * 0.5
		if Geometry2D.is_point_in_polygon(l_mid, station_poly):
			lm.box("PortalLamp", Vector3(l_mid.x, PORTAL_H - 0.38, l_mid.y), Vector3(0.45, 0.14, 54.0), track_basis)

## Backlit "Pasila | Böle" fascia sign on the south Pasilansilta station front.
static func _station_signage(lm: LandmarkMesh, h: float) -> void:
	var front_a := Vector2(140.1, -14.1)
	var front_b := Vector2(209.5, -30.3)
	var along := (front_b - front_a).normalized()
	var out := Vector2(along.y, -along.x)
	if out.y < 0.0:
		out = -out
	var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
	var s := front_a.lerp(front_b, 0.35) + out * 0.65
	lm.box("SignWhite", Vector3(s.x, h - 3.6, s.y), Vector3(14.0, 1.4, 0.35), basis)

## Fin facade along outline edge `i`: a zigzag of vertical glass panes
## 1.6 m wide and 0.55 m deep from `y0` up to `y1`.
static func _fins(lm: LandmarkMesh, poly: PackedVector2Array, i: int, y0: float, y1: float) -> void:
	var a := poly[i]
	var b := poly[(i + 1) % poly.size()]
	var l := a.distance_to(b)
	if l < 8.0:
		return
	var o := FhP.edge_out(poly, i)
	var n := maxi(int(l / 1.6), 2)
	var up := Vector3(0, y1 - y0, 0)
	for k in n:
		var p0 := a.lerp(b, float(k) / float(n))
		var p1 := a.lerp(b, float(k + 1) / float(n))
		var d0 := 0.0 if k % 2 == 0 else 0.55
		var d1 := 0.55 if k % 2 == 0 else 0.0
		var q0 := Vector3(p0.x, y0, p0.y) + o * d0
		var q1 := Vector3(p1.x, y0, p1.y) + o * d1
		var nrm := (q1 - q0).cross(Vector3.UP).normalized()
		if nrm.dot(o) < 0.0:
			nrm = -nrm
		lm.quad("Fin", q0, q1, q1 + up, q0 + up, nrm)

static func _entrance(lm: LandmarkMesh, poly: PackedVector2Array, h: float) -> void:
	var best := 0
	for i in poly.size():
		if poly[i].distance_to(poly[(i + 1) % poly.size()]) > poly[best].distance_to(poly[(best + 1) % poly.size()]):
			best = i
	var a := poly[best]
	var b := poly[(best + 1) % poly.size()]
	var along := (b - a).normalized()
	var out := Vector2(along.y, -along.x)
	var mid := (a + b) * 0.5
	if Geometry2D.is_point_in_polygon(mid + out, poly):
		out = -out
	var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
	var c := mid + out * 2.5
	lm.box("Trim", Vector3(c.x, 4.05, c.y), Vector3(18.0, 0.5, 5.0), basis)
	var p := c + along * 10.5
	lm.box("Trim", Vector3(p.x, (h - 2.5) * 0.5, p.y), Vector3(0.8, h - 2.5, 0.8), basis)
	# Station-side plaza: white mushroom columns with broad flaring caps.
	for k in 5:
		var m := c + along * (-8.0 + 4.0 * float(k)) + out * 4.0
		lm.lathe("Mush", Vector3(m.x, 0.0, m.y), PackedVector2Array([Vector2(0.45, 0.0), Vector2(0.45, 3.6), Vector2(0.9, 4.6),
			Vector2(2.6, 5.4), Vector2(3.4, 5.7), Vector2(3.4, 5.9), Vector2(0.0, 5.9)]), 16)
	# Red rooftop sign above the entrance.
	var s := mid - out * 0.6
	for sx: float in [-7.5, 0.0, 7.5]:
		lm.box("Trim", Vector3(s.x, h - 1.2, s.y) + basis.x * sx, Vector3(0.28, 3.0, 0.28), basis)
	lm.box("Sign", Vector3(s.x, h + 0.9, s.y), Vector3(22.0, 1.8, 0.4), basis)

