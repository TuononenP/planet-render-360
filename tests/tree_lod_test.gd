extends SceneTree

## TreeLod / TreeLodWindow: LOD rings follow the camera without a rebuild.
func _init() -> void:
	var failures: Array[String] = []
	# A line of trees every 10 m along +X, 0..990 m.
	var plan := {"pos": [], "sp": [], "scale": [], "real": []}
	for i in 100:
		plan["pos"].append(Vector3(float(i) * 10.0, 0, 5.0))
		plan["sp"].append("lime" if i % 2 == 0 else "birch")
		plan["scale"].append(Vector2.ONE)
		plan["real"].append(true)
	var ctx := {"m2u": 1.0, "full_r": 100.0, "mid_r": 200.0, "budget": 30,
		"eye": Vector2.ZERO, "season": LocationData.Season.SUMMER,
		"snow": 0.0, "sway": 0.0, "biome": "temperate"}
	var st := TreeLod.state(plan, ctx)
	# Rows carry the instance transform: origin = trunk base, y scale > 0.
	var rows: PackedFloat32Array = st["rows"]
	var o := 7 * TreeLod.ROW
	if not Vector3(rows[o + 3], rows[o + 7], rows[o + 11]).is_equal_approx(Vector3(70, 0, 5)) or rows[o + 5] <= 0.0:
		failures.append("row 7 does not hold tree 7's transform")
	# Around the origin: 10 trees inside the 100 m ring, 10 more to 200 m.
	var a := TreeLod.assign(st, Vector2.ZERO)
	var lod: Array = a["lod"]
	if lod != [10, 10, 80]:
		failures.append("eye at origin: LODs %s, want [10, 10, 80]" % str(lod))
	# The mesh budget demotes the farther mesh-ring trees to impostors.
	ctx["budget"] = 15
	var demoted: Array = TreeLod.assign(TreeLod.state(plan, ctx), Vector2.ZERO)["lod"]
	if demoted != [10, 5, 85]:
		failures.append("budget 15: LODs %s, want [10, 5, 85]" % str(demoted))
	# The impostor cap drops the farthest trees, never the nearest.
	ctx["budget"] = 5
	var capped := TreeLod.assign(TreeLod.state(plan, ctx), Vector2(500, 5))
	if int(capped["dropped"]) != 100 - 5 - 5 * VegetationBuilder.IMPOSTOR_FACTOR:
		failures.append("cap dropped %d" % int(capped["dropped"]))
	ctx["budget"] = 30
	# Emit + window: moving the eye 500 m re-centres the LOD-0 ring.
	var root := Node3D.new()
	VegetationBuilder._emit(root, plan, ctx)
	var w := TreeLodWindow.attach(root)
	if w == null:
		failures.append("no TreeLodWindow on an emitted tree set")
	else:
		if w.needs_refresh(Vector2(10, 0)):
			failures.append("a 10 m step must not re-centre (refresh at 20 m)")
		var eye := Vector2(500, 5)
		w.tick(eye, 2)
		for i in 200:
			if not w.busy():
				break
			OS.delay_msec(5)
			w.tick(eye, 2)
		if w.centre() != eye:
			failures.append("window did not re-centre on the moved eye")
		var near := 0
		for n in root.find_children("VegTrees_*_lod0_*", "MultiMeshInstance3D", true, false):
			for p: Vector3 in (n.get_meta("origins") as PackedVector3Array):
				if Vector2(p.x, p.z).distance_to(eye) > 100.0:
					failures.append("LOD 0 tree at %s outside the moved ring" % str(p))
				near += 1
		if near != 21:
			failures.append("moved eye: %d LOD 0 trees, want 21" % near)
		w.stop()
	root.free()
	if failures.is_empty():
		print("TREE LOD OK: rows, rings, cap, camera-following window")
		quit(0)
	else:
		for f in failures:
			printerr("TREE LOD FAIL: ", f)
		quit(1)
