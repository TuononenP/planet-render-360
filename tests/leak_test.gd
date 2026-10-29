extends SceneTree

## Orphan-node regression test: godot --headless --script tests/leak_test.gd
## The picker's layout-only containers must stay inside the tree in
## every layout, including when that layout is the first one applied
## (a full-screen window makes the picker Expanded at _ready). Left
## parentless, _side/_right_col (compact/medium) and
## _sheet/_top_col/_stack_gap (expanded) were orphan nodes, leaked as
## CanvasItem RIDs and ObjectDB instances on quit.

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	for width in [390.0, 800.0, 1280.0]:
		# Pre-sized parent: the picker is already at its final width
		# when _ready applies the first layout.
		var parent := Control.new()
		parent.set_anchors_preset(Control.PRESET_TOP_LEFT)
		parent.size = Vector2(width, 844)
		root.add_child(parent)
		await process_frame
		var picker := MapPicker.new()
		picker.set_anchors_preset(Control.PRESET_FULL_RECT)
		parent.add_child(picker)
		await process_frame
		await process_frame
		for pair in [["side", picker._side], ["side_col", picker._side_col],
				["right_col", picker._right_col], ["brand_pill", picker._brand_pill],
				["sheet", picker._sheet], ["top_col", picker._top_col],
				["stack_gap", picker._stack_gap]]:
			if not (pair[1] as Node).is_inside_tree():
				failures.append("picker at %dpt: _%s should be inside the tree" % [int(width), pair[0]])
		var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		if orphans != 0:
			failures.append("picker at %dpt: %d orphan node(s) should be 0" % [int(width), orphans])
		# Layout transitions (window resize / rotation relayouts live):
		# reparenting through every layout must keep the same
		# containers in the tree, with no orphans left behind.
		for tw in [1280.0, 390.0, 800.0, width]:
			parent.size = Vector2(tw, 844)
			await process_frame
			await process_frame
			for pair in [["side", picker._side], ["right_col", picker._right_col],
					["sheet", picker._sheet], ["top_col", picker._top_col],
					["stack_gap", picker._stack_gap]]:
				if not (pair[1] as Node).is_inside_tree():
					failures.append("picker %dpt -> %dpt: _%s should be inside the tree" % [int(width), int(tw), pair[0]])
			var orphans_after := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
			if orphans_after != 0:
				failures.append("picker %dpt -> %dpt: %d orphan node(s) should be 0" % [int(width), int(tw), orphans_after])
		parent.queue_free()
		await process_frame
		await process_frame

	if failures.is_empty():
		print("LEAK OK: picker containers stay in tree at compact/medium/expanded")
		quit(0)
	else:
		for f in failures:
			printerr("LEAK FAIL: ", f)
		quit(1)
