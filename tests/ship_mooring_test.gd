extends SceneTree

## Headless: a moored ship's lines run from its hull side to the quay top,
## nothing dips into the water, fenders sit between the hull and the quay,
## and the gangway reaches the quay; ballast lift moves the quay down in
## the ship's frame.
var failures: Array[String] = []

func _init() -> void:
	MaterialLibrary.hi_res = true
	for c in [["liner", 250.0, 31.0, 50.0, "", 0.0], ["cargo", 190.0, 30.0, 32.0, "bulk", 3.0]]:
		var length: float = c[1]
		var beam: float = c[2]
		var lift: float = c[5]
		var berth := {"quay_z": -(beam * 0.5 + 2.0), "quay_top": 2.5, "along": Vector2(-length, length), "lift": lift}
		var lm := LargeShips.geometry("cargo:bulk" if c[0] == "cargo" else "liner", length, beam, c[3], 0.4, true, true, berth)
		var root := Node3D.new()
		var found := {}
		for part in lm.commit(root):
			var v: PackedVector3Array = part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			found[str(part.name)] = v
		root.free()
		var water := -lift
		var quay_y := 2.5 - lift
		var rope: PackedVector3Array = found.get("Rope", PackedVector3Array())
		_check(rope.size() > 100, "%s needs mooring lines" % c[0])
		var on_quay := 0
		for p in rope:
			_check(p.y > water + 0.2, "%s lines must stay out of the water" % c[0])
			_check(p.z <= beam * 0.5 + 0.5, "%s lines must run toward the quay side" % c[0])
			if absf(p.z - (-(beam * 0.5 + 2.0) - 1.5)) < 0.6 and absf(p.y - quay_y - 0.6) < 0.6:
				on_quay += 1
		_check(on_quay > 20, "%s lines must end at quay bitts" % c[0])
		var fender: PackedVector3Array = found.get("Fender", PackedVector3Array())
		_check(not fender.is_empty(), "%s needs fenders" % c[0])
		for p in fender:
			_check(p.z < -beam * 0.5 + 0.3 and p.z > -(beam * 0.5 + 2.0) - 0.3, "%s fenders sit between hull and quay" % c[0])
		var bitts: PackedVector3Array = found.get("Bitt", PackedVector3Array())
		for p in bitts:
			_check(p.y >= quay_y - 0.01, "%s bitts stand on the quay top" % c[0])
		var low := INF
		for p in found.get("Steel", PackedVector3Array()):
			if p.z < -(beam * 0.5 + 2.5):
				low = minf(low, p.y)
		_check(absf(low - quay_y) < 0.6, "%s gangway must land on the quay (%.2f vs %.2f)" % [c[0], low, quay_y])
	if failures.is_empty():
		print("SHIP MOORING OK: lines, bitts, fenders, gangway, ballast lift")
		quit(0)
	else:
		for f in failures:
			printerr("SHIP MOORING FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)
