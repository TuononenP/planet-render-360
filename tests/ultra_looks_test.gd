extends SceneTree

## Headless: godot --headless --script tests/ultra_looks_test.gd
## Desktop Ultra's wider look palette (ArchitectureStyle.ULTRA_LOOKS via
## the build context): Paris apartments spread over more wall/roof/
## pattern combinations than the default two looks, the same building
## keeps its geometry picks either way.

func _init() -> void:
	var failures: Array[String] = []
	var region := "haussmann"
	var seen := {LOOKS_KEY: {}, "ultra": {}}
	for i in 400:
		var seed_v := fmod(float(i) * 0.61803, 1.0)
		var b := {"kind": "apartments", "levels": 6}
		var lo := ArchitectureStyle.resolve(b, region, "urban", seed_v, 400.0, {})
		var hi := ArchitectureStyle.resolve(b, region, "urban", seed_v, 400.0, {"looks": ArchitectureStyle.ULTRA_LOOKS})
		(seen[LOOKS_KEY] as Dictionary)[_sig(lo)] = true
		(seen["ultra"] as Dictionary)[_sig(hi)] = true
		if lo.get("roof_shape") != hi.get("roof_shape"):
			failures.append("look count must not change the roof shape (seed %.3f)" % seed_v)
			break
	var n_lo := (seen[LOOKS_KEY] as Dictionary).size()
	var n_hi := (seen["ultra"] as Dictionary).size()
	if n_hi <= n_lo or n_hi > n_lo * 4:
		failures.append("Ultra should widen the look palette a little: %d -> %d looks" % [n_lo, n_hi])
	if failures.is_empty():
		print("ULTRA LOOKS OK: %d -> %d Paris apartment looks, geometry picks kept" % [n_lo, n_hi])
		quit(0)
	else:
		for f in failures:
			printerr("ULTRA LOOKS FAIL: ", f)
		quit(1)

const LOOKS_KEY := "default"

func _sig(look: Dictionary) -> String:
	return "%s|%s|%s|%s|%s" % [look.get("wall_set"), look.get("wall_colour"), look.get("roof_colour"),
		look.get("shutter"), look.get("pattern")]
