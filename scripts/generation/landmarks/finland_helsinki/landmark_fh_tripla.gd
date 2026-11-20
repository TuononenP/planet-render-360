extends RefCounted

## Mall of Tripla (Pasila, 2019), extruded from the mapped complex outline
## (LandmarkFhMallFootprints), 30 m flat roof.
##
## From the photographs (visual-plan/refs/landmarks/mall_of_tripla/): the mall
## is a white-green translucent skin of vertical glass fins in a sawtooth
## profile above a glazed shopfront storey; the white mushroom columns of
## the station plaza; a red rooftop sign. The towers around it (hotel,
## offices, apartments: 37-50 m in OSM) are separate OSM buildings and are
## not part of this model.
##
## Measured: outline; the 30 m registry height (LoD2 57 m is the tower
## block). Estimated: fin width (1.6 m) and depth (0.55 m), plaza mushroom
## count, sign length.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")

const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "mall_of_tripla", "name": "Mall of Tripla", "lat": 60.198376, "lon": 24.930295,
	"radius_m": 4000.0, "wiki_title": "Mall of Tripla", "height_m": 30.0, "clear_m": 40.0,
	"clear_offsets_m": [
		[-44.0, 0.0], [26.0, 40.0], [56.0, -30.0], [166.0, -50.0], [-29.0, 65.0], [-4.0, -30.0],
		[81.0, -15.0], [-69.0, 0.0], [196.0, -55.0], [141.0, -40.0], [46.0, 55.0], [-64.0, 30.0],
		[61.0, -50.0], [-74.0, -15.0], [6.0, 45.0], [-44.0, -10.0], [141.0, -45.0], [21.0, -25.0],
		[36.0, 10.0], [201.0, -65.0], [136.0, -50.0], [206.0, -50.0], [136.0, -35.0],
		[-79.0, -20.0]],
	"kind": "Shopping centre", "aliases": ["mall of tripla", "kauppakeskus tripla", "tripla pasila"]}

static func build(model: Node3D) -> void:
	var type := "mall_of_tripla"
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
	lm.use("Mush", LandmarkMaterials.paint("#F4F2EC", 0.35, 0.1))
	var poly := F.outline(type)
	lm.poly_prism("Wall", poly, 0.0, h - 2.5)
	# Shopfront ring under a facade of vertical glass fins in a sawtooth
	# profile (the mall's white-green translucent skin), lit from within.
	var skin := F.offset(poly, 0.06)
	lm.poly_prism("Glass", skin, 0.4, 4.0, false)
	lm.poly_prism("Trim", F.offset(poly, 0.2), 4.0, 4.5)
	for i in poly.size():
		_fins(lm, poly, i, h)
	_entrance(lm, poly, h)
	# Roof slab, then plant boxes and skylight strips that fit inside it.
	var roof := F.offset(poly, -2.0)
	lm.poly_prism("Roof", roof, h - 2.5, h - 1.3)
	var inner := F.offset(poly, -8.0)
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
	lm.commit(model)

## Entrance canopy and accent pylon at the middle of the longest edge,
## facing out of the building.
## Fin facade along outline edge `i`: a zigzag of vertical glass panes
## 1.6 m wide and 0.55 m deep from the first floor up to the roof.
static func _fins(lm: LandmarkMesh, poly: PackedVector2Array, i: int, h: float) -> void:
	var a := poly[i]
	var b := poly[(i + 1) % poly.size()]
	var l := a.distance_to(b)
	if l < 8.0:
		return
	var o := FhP.edge_out(poly, i)
	var n := maxi(int(l / 1.6), 2)
	var y0 := 4.5
	var up := Vector3(0, h - 2.5 - y0, 0)
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
	var s := mid
	lm.box("Sign", Vector3(s.x, h + 0.9, s.y), Vector3(22.0, 1.8, 0.4), basis)

