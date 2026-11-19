extends SceneTree

## Headless: godot --headless --path . --script tests/stair_builder_test.gd
## StairBuilder: a 33-step flight from 10 m down 33 risers draws 33 treads
## whose risers are 0.12-0.20 m, the top tread one riser under the top
## node and the bottom one at the foot's level; ground beside it a metre
## over the treads is walled with a cheek (and none where it is not);
## `handrail` adds rails; a flight's ribbon is left out of the roads; a
## steps area is cut into one slab per step.

const SIZE := 129
const STEP_M := 2.0
const TOP := 10.0

var _fails := 0

func _init() -> void:
	_run()
	if _fails == 0:
		print("stair_builder_test: PASS")
	quit(1 if _fails > 0 else 0)

func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("FAIL: ", what)

func _flight(count: int, handrail: bool = false) -> Dictionary:
	var m := WorldScale.metres_to_units()
	return {"road": 0, "points": PackedVector2Array([Vector2(-1, 0) * m, Vector2(9, 0) * m]),
		"y_top": TOP, "y_bot": TOP - float(count) * StepsGround.RISER_M, "n": count,
		"width": 2.0 * m, "handrail": handrail, "area": false, "ring": PackedVector2Array(), "holes": []}

## A ground that follows the flight's line a riser and the clearance under
## the treads, `side_rise` higher than it more than 1.5 m beside it.
func _ground(f: Dictionary, side_rise: float) -> GroundTruth:
	var m := WorldScale.metres_to_units()
	var g := GroundTruth.new(null)
	g._size = SIZE
	g._step_units = STEP_M * m
	g._half_units = float(SIZE) * 0.5 * STEP_M * m
	g.water_level_m = -100.0
	g._surface.resize(SIZE * SIZE)
	g._level.resize(SIZE * SIZE)
	g._level.fill(-INF)
	var drop: float = float(f["y_top"]) - float(f["y_bot"])
	for z in SIZE:
		for x in SIZE:
			var wx := (float(x) - float(SIZE) * 0.5) * STEP_M
			var wz := (float(z) - float(SIZE) * 0.5) * STEP_M
			var line := TOP - drop * clampf((wx + 1.0) / 10.0, 0.0, 1.0)
			g._surface[z * SIZE + x] = line - 0.32 + (side_rise if absf(wz) > 1.5 else 0.0)
	g.steps = [f]
	return g

func _data(f: Dictionary) -> LocationData:
	var data := LocationData.new()
	data.roads = [{"class": "steps", "points": f["points"], "width_m": 2.0, "surface": "",
		"bridge": false, "tunnel": false, "layer": 0, "step_count": int(f["n"])}]
	return data

## The "Stairs" mesh's surfaces as {material: arrays}.
func _lay(f: Dictionary, side_rise: float) -> Dictionary:
	var data := _data(f)
	var ground := _ground(f, side_rise)
	var root := Node3D.new()
	StairBuilder.lay(root, data, ground, RoadBuilder._Surface.new(data, ground), WorldScale.metres_to_units())
	var stairs := root.get_node_or_null("Stairs") as MeshInstance3D
	var out := {}
	if stairs != null:
		for s in stairs.mesh.get_surface_count():
			out[stairs.mesh.surface_get_material(s)] = MeshArrays.surface(stairs.mesh, s)
	root.free()
	return out

## Distinct heights (mm) of the upward faces of one surface, high to low.
func _tread_heights(arrays: Array) -> Array:
	var seen := {}
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in verts.size():
		if normals[i].y > 0.9:
			seen[roundi(verts[i].y * 1000.0)] = true
	var hs: Array = seen.keys()
	hs.sort()
	hs.reverse()
	return hs

func _top_of(arrays: Array) -> float:
	var top := -INF
	for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		top = maxf(top, v.y)
	return top

func _run() -> void:
	var f := _flight(33)
	var data := _data(f)
	var tread := RoadBuilder._material("paving")
	var surfaces := _lay(f, 0.0)
	_check(surfaces.has(tread), "the treads are the paving's material")
	if not surfaces.has(tread):
		return
	var heights := _tread_heights(surfaces[tread])
	_check(heights.size() == 33, "33 treads, got %d" % heights.size())
	var rise := 33.0 * StepsGround.RISER_M / 33.0
	for k in range(1, heights.size()):
		var riser: float = float(heights[k - 1] - heights[k]) / 1000.0
		_check(riser >= 0.12 and riser <= 0.20, "riser %d is %.3f m" % [k, riser])
	if not heights.is_empty():
		_near(float(heights[0]) / 1000.0, TOP - rise, 0.05, "top tread one riser under the top node")
		_near(float(heights[heights.size() - 1]) / 1000.0, float(f["y_bot"]), 0.05, "bottom tread at the foot's level")
	var riser_mat: Material = RoadBuilder._mats.get("riser_paving")
	_check(riser_mat != null and surfaces.has(riser_mat) and riser_mat != tread, "risers have a darker material of their own")
	_check(not surfaces.has(QuayBuilder.stone_material(data)), "no cheek where the ground is under the treads")
	_check(not surfaces.has(ReliefKit.iron()), "no rails without a handrail")

	# Ground a metre over the treads beside the flight is walled up to it.
	var walled := _lay(f, 6.0)
	_check(walled.has(QuayBuilder.stone_material(data)), "a cheek wall where the ground stands over the treads")
	if walled.has(QuayBuilder.stone_material(data)):
		_check(_top_of(walled[QuayBuilder.stone_material(data)]) > TOP - 2.0, "the cheek rises to the ground beside it")

	# A handrail adds rails.
	var railed := _lay(_flight(33, true), 0.0)
	_check(railed.has(ReliefKit.iron()), "handrail=yes draws rails")

	# The ribbon of a flight is left out of the roads.
	var ground := _ground(f, 0.0)
	_check(StairBuilder.skipped_roads(ground).has(0), "the flight's road is skipped")
	var roads := RoadBuilder.build_roads(data, ground)
	var ribbon := 0
	for c in roads.get_children():
		if (c as Node).name.begins_with("Road_") and c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			ribbon += (c as MeshInstance3D).mesh.get_surface_count()
	_check(roads.get_node_or_null("Stairs") != null, "build_roads adds the Stairs mesh")
	_check(ribbon == 0, "no ribbon for a flight that is drawn as stairs (%d surfaces)" % ribbon)
	roads.free()

	# A steps area: one slab per step.
	var m := WorldScale.metres_to_units()
	var area := _flight(20)
	area["area"] = true
	area["ring"] = PackedVector2Array([Vector2(-1, -3) * m, Vector2(9, -3) * m, Vector2(9, 3) * m, Vector2(-1, 3) * m])
	var slabs := _lay(area, 0.0)
	# build_roads rebuilt RoadBuilder's materials: ask again.
	tread = RoadBuilder._material("paving")
	_check(slabs.has(tread), "an area's slabs are the paving's material")
	if slabs.has(tread):
		var levels := _tread_heights(slabs[tread])
		_check(levels.size() == 20, "20 slabs for a 20-step area, got %d" % levels.size())

func _near(a: float, b: float, tol: float, what: String) -> void:
	_check(absf(a - b) <= tol, "%s: %.3f, want %.3f ± %.2f" % [what, a, b, tol])
