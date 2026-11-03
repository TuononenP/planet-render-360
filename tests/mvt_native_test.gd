extends SceneTree

## Native MVT decoder: godot --headless --path . --script tests/mvt_native_test.gd
## MvtKernels (native/, tools/build_native.sh) must decode exactly as the
## script does: every bundled tile of the picker map, then truncated and
## bit-flipped copies of real tiles (corrupt input is where two decoders
## drift apart). Skips, passing, when the library is not built.

const FLIPS_PER_TILE := 8

var _failures: Array[String] = []

func _init() -> void:
	_run()

func _run() -> void:
	if not ClassDB.class_exists("MvtKernels"):
		print("MVT_NATIVE SKIP: MvtKernels is not loaded (tools/build_native.sh)")
		quit(0)
		return
	var pack := MapPack.shared(MapPack.OMT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var tiles := 0
	var features := 0
	var samples: Array[PackedByteArray] = []
	for z in 7:
		var wanted := MapStyle.wanted(float(z))
		for x in 1 << z:
			for y in 1 << z:
				var body := VectorTileFetcher.inflate(pack.get_tile(z, x, y))
				tiles += 1
				features += _same("tile %d/%d/%d" % [z, x, y], body, wanted)
				if not body.is_empty() and rng.randi() % 40 == 0:
					samples.append(body)
	# Truncated and bit-flipped copies of real tiles, with every layer wanted.
	var all := {}
	for layer in MapStyle.wanted(6.0):
		all[layer] = MapStyle.wanted(6.0)[layer]
	var corrupt := 0
	for body in samples:
		for cut in [1, 2, 3, 7, body.size() / 3, body.size() / 2, body.size() - 1]:
			_same("tile cut to %d" % cut, body.slice(0, cut), all)
			corrupt += 1
		for _f in FLIPS_PER_TILE:
			var bad := body.duplicate()
			bad[rng.randi() % bad.size()] = rng.randi() % 256
			_same("tile with a flipped byte", bad, all)
			corrupt += 1
	_same("empty", PackedByteArray(), all)
	_same("garbage", PackedByteArray([0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f, 26, 0xff]), all)
	if _failures.is_empty():
		print("MVT_NATIVE OK: %d tiles (%d features) and %d corrupt copies decode as the script does" % [tiles, features, corrupt])
		quit(0)
	else:
		for f in _failures.slice(0, 20):
			printerr("MVT_NATIVE FAIL: ", f)
		quit(1)

## Decodes `body` both ways and records a failure when they differ,
## including the order of a feature's tags. Returns the feature count.
func _same(label: String, body: PackedByteArray, wanted: Dictionary) -> int:
	var script := MvtReader.read_script(body, wanted)
	var native: Dictionary = ClassDB.class_call_static("MvtKernels", "read", body, wanted)
	if script != native:
		_failures.append("%s: native result differs from the script's" % label)
		return 0
	var count := 0
	for name in script:
		var s: Array = script[name]["features"]
		var n: Array = native[name]["features"]
		count += s.size()
		for i in s.size():
			if (s[i]["tags"] as Dictionary).keys() != (n[i]["tags"] as Dictionary).keys():
				_failures.append("%s: %s feature %d tag order differs" % [label, name, i])
				return count
	if script.keys() != native.keys():
		_failures.append("%s: layer order differs" % label)
	return count
