extends SceneTree

## Headless: godot --headless --script tests/shop_lights_test.gd
## Shopfront spill light (ShopLights, desktop Ultra): StreetFront notes a
## point every few metres along a flagged shop storey, a metre out from the
## glass; the nearest MAX_LIGHTS become shadowless omnis that CityLights
## turns on at night, and unflagged fronts note nothing.

func _init() -> void:
	_run()

func _front(flag: bool) -> void:
	var m := WorldScale.metres_to_units()
	var sp := {"a": Vector2(0, -10) * m, "b": Vector2(30, -10) * m, "n": Vector2(0, -1),
		"dir": Vector2(1, 0), "len_m": 30.0, "street": true, "bays": 6}
	var rows := [{"y0": 0.0, "y1": 4.0 * m, "storey": 0, "ground": true}]
	var look := {"ground": "shop", "relief": {}, "pattern": "punched"}
	StreetFront.add(ReliefKit.new(), [sp], rows,
		{"look": look, "seed": 0.3, "b": {}, "ground_y": 0.0, "shop_lights": flag}, null)

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var m := WorldScale.metres_to_units()
	ShopLights.begin_build()
	_front(false)
	var root := Node3D.new()
	if ShopLights.add(root) != 0:
		failures.append("an unflagged shop front should note no lights")
	ShopLights.begin_build()
	_front(true)
	var n := ShopLights.add(root)
	if n != 5:
		failures.append("30 m of shop front should give 5 spill lights, got %d" % n)
	var holder := root.get_node_or_null("ShopLights")
	if holder != null:
		var o := holder.get_child(0) as OmniLight3D
		if o.shadow_enabled or not o.distance_fade_enabled or not o.has_meta(StreetLights.META):
			failures.append("spill lights should be shadowless, faded and CityLights-driven")
		if absf(o.position.z - (-11.0 * m)) > 0.01 * m or absf(o.position.y - ShopLights.HEIGHT_M * m) > 0.01 * m:
			failures.append("spill light should sit 1 m out at fascia height, got %s" % str(o.position / m))
		StreetLights.apply(o, 0.0)
		if o.visible:
			failures.append("spill lights should be off by day")
		StreetLights.apply(o, 1.0)
		if not o.visible or o.light_energy <= 0.0:
			failures.append("spill lights should be on at night")
	# Nearest first, capped.
	ShopLights.begin_build()
	for i in ShopLights.MAX_LIGHTS + 40:
		ShopLights.note(Vector2(float(i) * 7.0, 0.0) * m, Vector2(1, 0), Vector2(0, 1), 1.0, 0.0)
	var far_root := Node3D.new()
	if ShopLights.add(far_root) != ShopLights.MAX_LIGHTS:
		failures.append("spill lights should cap at MAX_LIGHTS")
	var lights := far_root.get_node("ShopLights").get_children()
	var max_x := 0.0
	for l in lights:
		max_x = maxf(max_x, (l as Node3D).position.x / m)
	if max_x > float(ShopLights.MAX_LIGHTS) * 7.0 + 1.0:
		failures.append("the cap should keep the nearest lights")
	# ...nearest the eye, not the world origin.
	ShopLights.begin_build()
	for i in ShopLights.MAX_LIGHTS + 40:
		ShopLights.note(Vector2(float(i) * 7.0, 0.0) * m, Vector2(1, 0), Vector2(0, 1), 1.0, 0.0)
	var eye_root := Node3D.new()
	ShopLights.add(eye_root, Vector2(float(ShopLights.MAX_LIGHTS + 40) * 7.0, 0.0) * m)
	var min_x := INF
	for l in eye_root.get_node("ShopLights").get_children():
		min_x = minf(min_x, (l as Node3D).position.x / m)
	if min_x < 40.0 * 7.0 - 1.0:
		failures.append("the cap should keep the lights nearest the eye")
	eye_root.free()
	root.free()
	far_root.free()
	# A cancelled build's points go with it.
	ShopLights.begin_build()
	_front(true)
	ShopLights.discard()
	if ShopLights.add(Node3D.new()) != 0:
		failures.append("a discarded build should leave no spill points behind")
	failures.erase(failures[0])
	if failures.is_empty():
		print("SHOP LIGHTS OK: flagged fronts only, spaced spill points, shadowless and night-driven, nearest capped")
		quit(0)
	else:
		for f in failures:
			printerr("SHOP LIGHTS FAIL: ", f)
		quit(1)
