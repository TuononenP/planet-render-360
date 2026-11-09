extends SceneTree

## Headless: godot --headless --script tests/roof_clutter_test.gd
## Rooftop clutter (RoofClutter, desktop Ultra flat roofs): each city or
## region gets its own mix (New York water towers, East Asian condensers,
## Gulf tanks, Greek solar heaters, skylights elsewhere), the same roof
## always gets the same pieces, and lower tiers get none.

## A 10-storey pre-war New York roof, the kind that carries a water tower.
const WALL_M := 32.0
const NEW_YORK := {"city": "new_york", "region": "north_america", "era": "nyc_prewar"}

func _init() -> void:
	_run()

func _ring(half: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half)])

## Materials RoofClutter put in a batch, for `look` on a 24 m square roof.
func _mats_for(look: Dictionary, seed_v: float, country: String = "") -> Dictionary:
	var batch := BuildingDetail.Batch.new()
	var ring := _ring(12.0)
	var basis := Basis()
	RoofClutter.add(batch, ring, Vector2.ZERO, Vector2.RIGHT, Vector2(0, 1), 12.0, 12.0,
		30.0, basis, look, seed_v, 576.0, country, WALL_M)
	var out := {}
	for k in RoofClutter._mats:
		if batch.surfaces.has(RoofClutter._mats[k]):
			out[k] = true
	return out

## Whether every vertex RoofClutter adds on a narrow 25 × 6 m roof stays
## over it (a hair of slack for tilted dishes and collectors).
func _stays_on_roof(look: Dictionary, seed_v: float, country: String = "") -> bool:
	var batch := BuildingDetail.Batch.new()
	var ring := PackedVector2Array([Vector2(-12.5, -3), Vector2(12.5, -3), Vector2(12.5, 3), Vector2(-12.5, 3)])
	RoofClutter.add(batch, ring, Vector2.ZERO, Vector2.RIGHT, Vector2(0, 1), 12.5, 3.0,
		30.0, Basis(), look, seed_v, 300.0, country, WALL_M)
	for mat in batch.surfaces:
		for p in (batch.surfaces[mat][0] as PackedVector3Array):
			if absf(p.x) > 12.5 + 0.3 or absf(p.z) > 3.0 + 0.3:
				return false
	return true

func _any(seeds: int, look: Dictionary, key: String, country: String = "") -> bool:
	for i in seeds:
		if _mats_for(look, float(i) * 0.137 + 0.01, country).has(key):
			return true
	return false

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	if not _any(20, NEW_YORK, "cedar"):
		failures.append("New York roofs should carry wooden water towers")
	if not _any(5, {"city": "tokyo", "region": "japan"}, "ac"):
		failures.append("Tokyo roofs should carry AC condensers")
	if not _any(10, {"city": "dubai", "region": "middle_east"}, "tank_white") \
			and not _any(10, {"city": "dubai", "region": "middle_east"}, "tank_black"):
		failures.append("Gulf roofs should carry water tanks")
	if not _any(5, {"city": "", "region": "mediterranean"}, "solar", "GR"):
		failures.append("Greek roofs should carry solar water heaters")
	if not _any(10, {"city": "", "region": "central_europe"}, "skylight"):
		failures.append("other flat roofs should get skylights")
	if not _any(5, {"city": "", "region": "central_europe"}, "core"):
		failures.append("big flat roofs should carry a stair/lift overrun")
	if not _any(5, {"city": "", "region": "middle_east"}, "solar", "IL") \
			or _any(20, {"city": "", "region": "middle_east"}, "dish", "IL"):
		failures.append("Israeli roofs should carry solar water heaters, not the region's tanks")
	for look: Dictionary in [NEW_YORK, {"city": "tokyo", "region": "japan"},
			{"city": "dubai", "region": "middle_east"}, {"city": "", "region": "central_europe"}]:
		for i in 40:
			if not _stays_on_roof(look, float(i) * 0.113 + 0.02, "GR" if i % 2 == 0 else ""):
				failures.append("a %s piece hangs over a narrow roof's edge (seed %d)" % [look["city"], i])
				break
	if _any(20, {"city": "", "region": "central_europe"}, "cedar"):
		failures.append("water towers belong to New York")
	var a := _mats_for({"city": "tokyo", "region": "japan"}, 0.42)
	var b := _mats_for({"city": "tokyo", "region": "japan"}, 0.42)
	if a != b:
		failures.append("the same roof should always get the same clutter")
	# Off the Ultra flag, BuildingDetail adds none of it.
	var root := Node3D.new()
	var look := ArchitectureStyle.resolve({"kind": "commercial", "levels": 6, "x": 0.0, "z": 0.0},
		"tokyo", "dense", 0.3, 576.0)
	BuildingDetail.add(root, _ring(12.0), 30.0, 30.0, "flat", 0.0, look, null, null, 0.3, true)
	for c in root.get_children():
		var mesh := (c as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			if RoofClutter._mats.values().has(mesh.surface_get_material(s)):
				failures.append("lower tiers should get no rooftop clutter")
				break
	root.free()
	failures.erase(failures[0])
	if failures.is_empty():
		print("ROOF CLUTTER OK: regional mixes (NYC towers, Asian condensers, Gulf tanks, Greek heaters, skylights, overruns), stable, Ultra only")
		quit(0)
	else:
		for f in failures:
			printerr("ROOF CLUTTER FAIL: ", f)
		quit(1)
