extends SceneTree

## Headless: godot --headless --script tests/neighbour_evidence_test.gd
## Untagged buildings borrow the finish of a tagged neighbour of the same
## kind (NeighbourEvidence): often when close, sometimes when near, never
## beyond a block; never over a building's own tags, never for named,
## protected, religious or civic buildings; deterministic.

var _m2u := 1.0

func _init() -> void:
	_m2u = WorldScale.metres_to_units()
	var failures: Array[String] = []
	_rate_checks(failures)
	_protection_checks(failures)
	_no_evidence_checks(failures)
	if failures.is_empty():
		print("NEIGHBOUR EVIDENCE OK")
		quit(0)
	else:
		for f in failures:
			printerr("NEIGHBOUR EVIDENCE FAIL: ", f)
		quit(1)

## A 14 x 10 m two-storey house at x/z metres (kind "house").
func _house(x_m: float, z_m: float, extra: Dictionary = {}) -> Dictionary:
	var b := {"x": x_m * _m2u, "z": z_m * _m2u, "size_x": 14.0 * _m2u, "size_z": 10.0 * _m2u,
		"kind": "house", "levels": 2, "colour": "", "material": "", "roof_shape": "",
		"roof_colour": "", "roof_material": "", "start_year": 0, "name": "", "religion": "",
		"heritage": false, "monument": "", "architecture": ""}
	b.merge(extra, true)
	return b

func _evidence() -> Dictionary:
	return _house(0.0, 0.0, {"colour": "#d8b040", "material": "plaster",
		"roof_shape": "gabled", "roof_colour": "#803020", "start_year": 1890})

## Untagged houses on a ring of `r` metres around the evidence building: the
## share that borrowed, and how many borrowed a date.
func _ring(r: float, n: int) -> Dictionary:
	var ev := _evidence()
	var peers := NeighbourEvidence.build([ev], "mid", _m2u)
	var ctx := {"peers": peers, "density": "mid"}
	var borrowed := 0
	var dated := 0
	for i in n:
		var a := float(i) * 2.399963
		var rr := r + float(i % 5) * 0.7
		var b := _house(cos(a) * rr, sin(a) * rr)
		var out := NeighbourEvidence.with_peers(b, ctx)
		if str(out["colour"]) == "#d8b040":
			borrowed += 1
			if not bool(out.get("inferred", false)):
				return {"error": "a borrowed finish must be marked inferred"}
		if int(out["start_year"]) == 1890:
			dated += 1
	return {"rate": float(borrowed) / float(n), "dated": dated}

func _rate_checks(failures: Array[String]) -> void:
	var near := _ring(10.0, 300)
	if near.has("error"):
		failures.append(str(near["error"]))
		return
	if float(near["rate"]) < 0.55 or float(near["rate"]) > 0.92:
		failures.append("within 20 m about %d%% should borrow, got %.0f%%" % [NeighbourEvidence.NEAR_P * 100.0, float(near["rate"]) * 100.0])
	if int(near["dated"]) == 0:
		failures.append("a neighbour within 25 m should sometimes borrow the year too")
	var mid := _ring(30.0, 300)
	if float(mid["rate"]) < 0.25 or float(mid["rate"]) > 0.65:
		failures.append("at 30 m about %d%% should borrow, got %.0f%%" % [NeighbourEvidence.FAR_P * 100.0, float(mid["rate"]) * 100.0])
	if int(mid["dated"]) > 0:
		failures.append("a year is not borrowed from beyond %d m (%d did)" % [NeighbourEvidence.YEAR_M, int(mid["dated"])])
	var far := _ring(62.0, 200)
	if float(far["rate"]) > 0.0:
		failures.append("nothing borrows beyond a block (%.0f%% at 62 m)" % [float(far["rate"]) * 100.0])
	# Deterministic.
	var again := _ring(10.0, 300)
	if again["rate"] != near["rate"]:
		failures.append("the same map resolved differently twice")

func _protection_checks(failures: Array[String]) -> void:
	var peers := NeighbourEvidence.build([_evidence()], "mid", _m2u)
	var ctx := {"peers": peers, "density": "mid"}
	# Own look: never touched, whatever the roll.
	var protected := {
		"named": {"name": "Villa Rosa"}, "protected": {"heritage": true},
		"religious": {"religion": "christian"}, "landmark": {"mapped_landmark": true},
		"civic": {"kind": "school"}, "monument": {"monument": "memorial"}}
	for label in protected:
		for i in 40:
			var b := _house(8.0 + float(i) * 0.31, 3.0 + float(i) * 0.17, protected[label] as Dictionary)
			if not is_same(NeighbourEvidence.with_peers(b, ctx), b):
				failures.append("a %s building borrowed a neighbour's finish" % label)
				break
	# Own tags win; the rest is borrowed.
	var kept := 0
	var filled := 0
	for i in 200:
		var b := _house(6.0 + float(i) * 0.09, 4.0 + float(i) * 0.05, {"colour": "#112233"})
		var out := NeighbourEvidence.with_peers(b, ctx)
		if str(out["colour"]) != "#112233":
			failures.append("a building's own colour was overwritten")
			return
		kept += 1
		if str(out["material"]) == "plaster":
			filled += 1
	if kept == 0 or filled == 0:
		failures.append("a building with its own colour should still borrow what it lacks")
	# Another kind is not borrowed from.
	var tower := {"kind": "apartments", "levels": 6, "size_x": 30.0 * _m2u, "size_z": 20.0 * _m2u}
	for i in 40:
		var b := _house(8.0 + float(i) * 0.3, 2.0, tower)
		if not is_same(NeighbourEvidence.with_peers(b, ctx), b):
			failures.append("an apartment block borrowed a house's finish")
			break
	# A roof is not borrowed across a very different footprint.
	var big := {"size_x": 60.0 * _m2u, "size_z": 40.0 * _m2u}
	for i in 60:
		var out := NeighbourEvidence.with_peers(_house(7.0 + float(i) * 0.2, 5.0, big), ctx)
		if str(out["roof_shape"]) != "":
			failures.append("a roof was borrowed across a 17x footprint area")
			break

func _no_evidence_checks(failures: Array[String]) -> void:
	var plain := [_house(0.0, 0.0), _house(12.0, 3.0), _house(25.0, -4.0)]
	var peers := NeighbourEvidence.build(plain, "mid", _m2u)
	if not peers.is_empty():
		failures.append("untagged buildings are not evidence")
	var b := _house(5.0, 5.0)
	if not is_same(NeighbourEvidence.with_peers(b, {"peers": peers, "density": "mid"}), b):
		failures.append("without evidence a building must come back unchanged")
	if not is_same(NeighbourEvidence.with_peers(b, {}), b):
		failures.append("a context without peers must leave a building unchanged")
	# The evidence building itself is never changed (its own tags are complete or kept).
	var ev := _evidence()
	var ctx := {"peers": NeighbourEvidence.build([ev], "mid", _m2u), "density": "mid"}
	if not is_same(NeighbourEvidence.with_peers(ev, ctx), ev):
		failures.append("the evidence building was altered by itself")
