extends "res://tools/capture_presets.gd"

## Runs the standard city capture, then inspects actual built vessels.
## Use the same arguments as capture_presets.gd, with desktop Ultra.
func _capture(main: Node, view: View360, place: Dictionary, times: PackedStringArray,
		audit: bool, settle_s: float = SETTLE_S) -> void:
	await super._capture(main, view, place, times, audit, settle_s)
	if main._generating or not view.visible:
		return
	ViewConditions.set_time_minutes(view, 12.0 * 60.0)
	var candidates: Array = []
	for part in view._world_root.find_children("*", "MeshInstance3D", true, false):
		if part.name in ["MappedShip_Hull", "HarbourFerry_Orange", "Liner_Hull"]:
			candidates.append([part.global_transform * part.mesh.get_aabb(), str(part.name)])
	var inventory := {}
	for fleet in view._world_root.find_children("Boats_*", "MultiMeshInstance3D", true, false):
		inventory[str(fleet.name)] = fleet.multimesh.instance_count
		for i in mini(fleet.multimesh.instance_count, 3):
			var transform: Transform3D = fleet.global_transform * fleet.multimesh.get_instance_transform(i)
			candidates.append([transform * fleet.multimesh.mesh.get_aabb(), str(fleet.name)])
	candidates.sort_custom(func(a: Array, b: Array) -> bool:
		var a_cat := str(a[1]).begins_with("Boats_catamaran")
		var b_cat := str(b[1]).begins_with("Boats_catamaran")
		if a_cat and b_cat and str(a[1]).ends_with("_far") != str(b[1]).ends_with("_far"):
			return not str(a[1]).ends_with("_far")
		return a_cat if a_cat != b_cat else (a[0] as AABB).size.length() > (b[0] as AABB).size.length())
	_stats[str(place["id"]) + "_vessel_candidates"] = candidates.size()
	_stats[str(place["id"]) + "_vessel_inventory"] = inventory
	for i in mini(candidates.size(), 3):
		var box: AABB = candidates[i][0]
		var target := box.get_center()
		var distance := maxf(box.size.length() * 1.25, 12.0)
		var dir := Vector3(0.5, 0.4, 1).normalized()
		view._rig.position = target + dir * distance
		view._rig.set_zoom(1.0)
		view._rig.set_look(atan2(dir.x, dir.z), -asin(dir.y))
		await _settle(1.0, 20)
		await _snap(view, str(place["id"]), "vessel_%d" % i)
		_stats["%s_vessel_%d" % [place["id"], i]]["vessel_source"] = candidates[i][1]
		if str(candidates[i][1]).begins_with("Boats_catamaran"):
			var span := maxf(box.size.x, box.size.z)
			var deck_target := box.get_center()
			deck_target.y = box.position.y + span * 0.2
			var deck_dir := Vector3(0.4, 0.85, 1).normalized()
			view._rig.position = deck_target + deck_dir * span * 1.3
			view._rig.set_look(atan2(deck_dir.x, deck_dir.z), -asin(deck_dir.y))
			await _settle(1.0, 20)
			await _snap(view, str(place["id"]), "catamaran_deck_%d" % i)
