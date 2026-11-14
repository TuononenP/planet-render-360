extends SceneTree

## Headless: godot --headless --script tests/modern_block_relief_test.gd
## ModernBlockRelief: which blocks qualify (modern, flat, apartment/office/
## civic, desktop Ultra only), what a synthetic Espoo slab gains (fascia,
## base course, entrance, core, balconies), the per-building triangle
## budget, determinism, Ultra-only built glass, and rooftop plant standing
## on the parapet's sunk deck instead of floating over it.

func _init() -> void:
	_run()

func _look(kind: String, era: String, extra: Dictionary = {}) -> Dictionary:
	var look := {"kind": kind, "era": era, "wall_set": "render", "pattern": "punched",
		"relief": {}, "floor_h": 3.0, "equip": 1.0, "region": "nordic", "chimney": 0.0,
		"dormer": 0.0, "tower": "", "wall_colour": Color(0.9, 0.9, 0.88)}
	look.merge(extra, true)
	return look

func _d(look: Dictionary, b: Dictionary = {}, shape: String = "flat") -> Dictionary:
	return {"ultra": true, "shape": shape, "look": look, "b": b}

## Synthetic block: an axis-aligned w x h m rectangle, all walls exposed,
## `storeys` storeys of 3 m over a 3.5 m ground storey.
func _block(w_m: float, h_m: float, storeys: int, look: Dictionary, seed_v: float) -> Dictionary:
	var m := WorldScale.metres_to_units()
	var ring := PackedVector2Array([Vector2(0, 0), Vector2(w_m, 0), Vector2(w_m, h_m), Vector2(0, h_m)])
	for i in ring.size():
		ring[i] *= m
	var cover: Array = []
	for i in ring.size():
		cover.append([[0.0, 1.0, PartyWalls.OPEN]])
	var spans := FacadeRelief.exposed_spans(ring, cover)
	for sp in spans:
		sp["street"] = false
		sp["bays"] = FacadeRelief.bay_count(float(sp["len_m"]), 3.6)
	var base := 0.0
	var g_top := 3.5 * m
	var top := g_top + float(storeys) * 3.0 * m
	var rows: Array = [{"y0": base, "y1": g_top, "storey": 0, "ground": true}]
	for k in storeys:
		rows.append({"y0": g_top + float(k) * 3.0 * m, "y1": g_top + float(k + 1) * 3.0 * m,
			"storey": k + 1, "ground": false})
	var d := {"ultra": true, "shape": "flat", "look": look, "b": {}, "seed": seed_v,
		"base": base, "ground_y": base, "g_top": g_top, "top": top, "ring": ring}
	return {"d": d, "spans": spans, "rows": rows}

func _build(blk: Dictionary) -> ReliefKit:
	var kit := ReliefKit.new()
	kit.ultra = true
	var look: Dictionary = (blk["d"] as Dictionary)["look"]
	var stone := ReliefKit.stone(str(look["wall_set"]), look["wall_colour"])
	ModernBlockRelief.add(kit, blk["spans"], blk["rows"], blk["d"], stone)
	return kit

func _tris(root: Node3D) -> int:
	var n := 0
	for c in root.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var mesh := (c as MeshInstance3D).mesh
			for s in mesh.get_surface_count():
				n += (MeshArrays.surface(mesh, s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return n

func _arrays_sig(root: Node3D) -> String:
	var parts: Array[String] = []
	for c in root.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var mesh := (c as MeshInstance3D).mesh
			for s in mesh.get_surface_count():
				parts.append(str(hash(MeshArrays.surface(mesh, s)[Mesh.ARRAY_VERTEX])))
	return ",".join(parts)

func _highest_y(root: Node3D) -> float:
	var hi := -INF
	for c in root.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var mi := c as MeshInstance3D
			for s in mi.mesh.get_surface_count():
				for v in (MeshArrays.surface(mi.mesh, s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
					hi = maxf(hi, (mi.transform * v).y)
	return hi

func _lowest_y(root: Node3D) -> float:
	var lo := INF
	for c in root.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var mi := c as MeshInstance3D
			for s in mi.mesh.get_surface_count():
				for v in (MeshArrays.surface(mi.mesh, s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
					lo = minf(lo, (mi.transform * v).y)
	return lo

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var m := WorldScale.metres_to_units()
	# Who qualifies.
	var yes := {
		"tapiola apartments": _d(_look("apartments", "tapiola")),
		"espoo_modern apartments": _d(_look("apartments", "espoo_modern")),
		"helsinki_element commercial": _d(_look("commercial", "helsinki_element", {"pattern": "panel"})),
		"untagged concrete strip office": _d(_look("commercial", "no_such_era", {"wall_set": "concrete", "pattern": "strip"})),
		"1972 start date": _d(_look("apartments", "helsinki"), {"start_year": 1972}),
		"brutalist tag": _d(_look("civic", "helsinki"), {"architecture": "brutalist"}),
		"hipped tapiola block": _d(_look("apartments", "tapiola"), {}, "hipped"),
	}
	for k in yes:
		if not ModernBlockRelief.qualifies(yes[k]):
			failures.append("%s should qualify" % k)
	var off := _d(_look("apartments", "tapiola"))
	off["ultra"] = false
	var no := {
		"High": off,
		"haussmann": _d(_look("apartments", "haussmann", {"wall_set": "limestone", "pattern": "haussmann"})),
		"jugend helsinki": _d(_look("apartments", "helsinki", {"pattern": "ornate"})),
		"house": _d(_look("house", "tapiola")),
		"onion roof": _d(_look("apartments", "tapiola"), {}, "onion"),
		"1900 start date": _d(_look("apartments", "tapiola"), {"start_year": 1900}),
		"string course, no era": _d(_look("apartments", "no_such_era", {"relief": {"string_course": true}})),
		"rv.modern false": _d(_look("apartments", "tapiola", {"relief": {"modern": false}})),
		"tower look": _d(_look("commercial", "espoo_modern", {"tower_look": {}})),
		"mapped landmark": _d(_look("commercial", "espoo_modern"), {"mapped_landmark": true}),
	}
	for k in no:
		if ModernBlockRelief.qualifies(no[k]):
			failures.append("%s should not qualify" % k)
	if not ModernBlockRelief.qualifies(_d(_look("apartments", "tapiola")), true) \
			or ModernBlockRelief.qualifies(_d(_look("apartments", "tapiola")), false):
		failures.append("only tiled facades (not the Paris composer) qualify")
	# Settings: the row's own dict over the kind's defaults.
	var s := ModernBlockRelief.settings(_look("apartments", "tapiola", {"relief": {"modern": {"core": 0.9}}}))
	if float(s["core"]) != 0.9 or float(s["base"]) != float(ModernBlockRelief.DEFAULTS["apartments"]["base"]):
		failures.append("settings should merge the row's modern dict over the defaults: %s" % s)
	# A 60 x 14 m, five-storey Espoo slab with everything forced on.
	var all_on := {"base": 1.0, "entrance": 1.0, "core": 1.0, "balconies": 1.0,
		"fascia": [["metal", 1]], "entrance_kind": [["canopy", 1]]}
	var slab := _look("apartments", "tapiola", {"relief": {"modern": all_on}})
	var kit := _build(_block(60.0, 14.0, 5, slab, 0.37))
	var mats := kit.surfaces.keys()
	if not ReliefKit.flat("#3b4045", 0.45, 0.6) in mats:
		failures.append("the slab should carry a metal fascia")
	if not ReliefKit.flat("#5d5f60", 0.85) in mats:
		failures.append("the slab should carry a base course")
	if not ReliefKit.flat("#2a2f33", 0.5, 0.2) in mats:
		failures.append("the slab should carry an entrance door")
	if not ReliefKit.glass_ultra() in mats:
		failures.append("the stair core's glazed strip should use the Ultra pane")
	if not ReliefKit.iron() in mats:
		failures.append("open balcony stacks should carry railings")
	var root := Node3D.new()
	kit.flush(root, "Relief")
	var tris := _tris(root)
	if tris <= 0:
		failures.append("the slab should gain relief")
	# Determinism: the same seed builds the same arrays.
	var again := Node3D.new()
	_build(_block(60.0, 14.0, 5, slab, 0.37)).flush(again, "Relief")
	if _arrays_sig(root) != _arrays_sig(again):
		failures.append("the same building should build the same relief")
	root.free()
	again.free()
	# Budget: a 150 m, eight-storey slab with balconies everywhere.
	var long_root := Node3D.new()
	_build(_block(150.0, 16.0, 8, slab, 0.61)).flush(long_root, "Relief")
	var long_tris := _tris(long_root)
	if long_tris > ModernBlockRelief.MAX_TRIS:
		failures.append("a 150 m slab added %d triangles, over MAX_TRIS %d" % [long_tris, ModernBlockRelief.MAX_TRIS])
	long_root.free()
	# A hipped block: base, door and core, but no fascia (its eave is the cornice).
	var hip := _block(40.0, 12.0, 4, slab, 0.37)
	(hip["d"] as Dictionary)["shape"] = "hipped"
	var hkit := _build(hip)
	var hmats := hkit.surfaces.keys()
	if not ReliefKit.flat("#5d5f60", 0.85) in hmats or not ReliefKit.flat("#2a2f33", 0.5, 0.2) in hmats:
		failures.append("a pitched block should still get a base course and an entrance")
	var hroot := Node3D.new()
	hkit.flush(hroot, "Relief")
	var eaves := float((hip["d"] as Dictionary)["top"])
	if _highest_y(hroot) > eaves + 0.01 * m:
		failures.append("a pitched block's relief should stop at the eaves %.2f (no fascia, no core head), got %.2f"
			% [eaves, _highest_y(hroot)])
	hroot.free()
	# Offices: fins on a curtain wall, no balconies.
	var office := _look("commercial", "espoo_modern", {"pattern": "curtain", "wall_set": "glass",
		"relief": {"modern": {"fins": 1.0, "fascia": [["alu", 1]]}}})
	var okit := _build(_block(40.0, 20.0, 8, office, 0.52))
	if not ReliefKit.flat("#b9bcbd", 0.35, 0.7) in okit.surfaces.keys():
		failures.append("an office with fins on should carry aluminium fins and fascia")
	if ReliefKit.iron() in okit.surfaces.keys():
		failures.append("an office should not get apartment balconies")
	# Built glass: the High kit keeps the old pane.
	var high := ReliefKit.new()
	if high.pane() != ReliefKit.glass():
		failures.append("High's built glass should stay ReliefKit.glass()")
	# Rooftop plant stands on the sunk parapet deck.
	var ring := PackedVector2Array([Vector2(0, 0), Vector2(30, 0), Vector2(30, 20), Vector2(0, 20)])
	for i in ring.size():
		ring[i] *= m
	var top := 15.0 * m
	var plant := _look("apartments", "tapiola", {"equip": 1.0})
	var lows := {}
	for deck in [top, BuildingTrim.deck(top, BuildingTrim.PARAPET)]:
		var detail := Node3D.new()
		BuildingDetail.add(detail, ring, top, top, "flat", 0.0, plant, null, null, 0.11, true,
			PackedByteArray(), false, true, "FI", false, deck)
		lows[deck] = _lowest_y(detail)
		detail.free()
	var sunk := BuildingTrim.deck(top, BuildingTrim.PARAPET)
	if is_inf(float(lows[sunk])) or absf(float(lows[sunk]) - sunk) > 0.05 * m:
		failures.append("plant on a parapet roof should stand on the deck at %.2f, lowest %.2f" % [sunk, lows[sunk]])
	if absf(float(lows[top]) - top) > 0.05 * m:
		failures.append("plant without a deck should stand on the wall top %.2f, lowest %.2f" % [top, lows[top]])
	failures.erase(failures[0])
	if failures.is_empty():
		print("MODERN BLOCK RELIEF OK: qualification, settings, slab relief (%d tris), budget (%d tris), offices, Ultra pane, plant on the deck"
			% [tris, long_tris])
		quit(0)
	else:
		for f in failures:
			printerr("MODERN BLOCK RELIEF FAIL: ", f)
		quit(1)
