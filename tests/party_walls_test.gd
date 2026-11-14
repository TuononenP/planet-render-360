extends SceneTree

## Headless: godot --headless --script tests/party_walls_test.gd
## Two masses drawing the same wall facing the same way (overlapping OSM
## building:parts, one outline mapped as a way and a relation) must not
## both draw it: the taller, else the first registered, keeps the wall and
## the other's stretch is covered, so no coplanar facades z-fight. Party
## walls (opposite facing) keep their old answer. Runs the script index
## and, when the native library is loaded, PartyIndex, and checks they
## agree.

var _fails := 0

func _init() -> void:
	_run(false)
	if ClassDB.class_exists("PartyIndex"):
		_run(true)
	else:
		print("party_walls_test: native PartyIndex not loaded, script path only")
	if _fails == 0:
		print("party_walls_test: PASS")
	quit(1 if _fails > 0 else 0)

func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("FAIL: ", what)

func _rect(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])

func _index(native: bool) -> PartyWalls:
	var pw := PartyWalls.new()
	if native:
		pw._idx = ClassDB.instantiate("PartyIndex")
	return pw

## Share (0..1) of edge i of `ring` some neighbour covers.
func _covered(cover: Array, i: int) -> float:
	var s := 0.0
	for p in cover[i]:
		if not is_inf(float(p[2])):
			s += float(p[1]) - float(p[0])
	return s

func _run(native: bool) -> void:
	var tag := "native" if native else "script"
	# Same outline twice, equal tops: only the second is covered.
	var sq := _rect(0, 0, 10, 10)
	var pw := _index(native)
	pw._add_ring(sq, "a", 12.0, false)
	pw._add_ring(sq, "b", 12.0, false)
	var ca := pw.ring_cover(sq, "a")
	var cb := pw.ring_cover(sq, "b")
	for i in 4:
		_check(_covered(ca, i) < 0.01, "%s: first copy keeps edge %d" % [tag, i])
		_check(_covered(cb, i) > 0.99, "%s: second copy hides edge %d" % [tag, i])

	# A low part spanning a taller part's south wall (shared edge z = 0,
	# same facing): the low part hides it, the tall part keeps it.
	pw = _index(native)
	var tall := _rect(0, 0, 10, 6)
	var low := _rect(0, 0, 10, 10)
	pw._add_ring(low, "low", 3.2, false)
	pw._add_ring(tall, "tall", 9.6, false)
	_check(_covered(pw.ring_cover(low, "low"), 0) > 0.99, "%s: low part hides shared wall" % tag)
	_check(_covered(pw.ring_cover(tall, "tall"), 0) < 0.01, "%s: tall part keeps shared wall" % tag)
	_check(_covered(pw.ring_cover(low, "low"), 2) < 0.01, "%s: low part keeps its own far wall" % tag)
	# Registered first does not change who is taller.
	pw = _index(native)
	pw._add_ring(tall, "tall", 9.6, false)
	pw._add_ring(low, "low", 3.2, false)
	_check(_covered(pw.ring_cover(low, "low"), 0) > 0.99, "%s: order-free low hide" % tag)
	_check(_covered(pw.ring_cover(tall, "tall"), 0) < 0.01, "%s: order-free tall keep" % tag)

	# Same facing but 0.5 m apart: two walls, both drawn.
	pw = _index(native)
	var near := _rect(0, 0.5, 10, 10)
	pw._add_ring(sq, "a", 12.0, false)
	pw._add_ring(near, "b", 6.0, false)
	_check(_covered(pw.ring_cover(near, "b"), 0) < 0.01, "%s: offset wall stays open" % tag)

	# Party wall (opposite facing): covered on both sides, as before.
	pw = _index(native)
	var left := _rect(0, 0, 10, 10)
	var right := _rect(10, 0, 20, 10)
	pw._add_ring(left, "l", 12.0, false)
	pw._add_ring(right, "r", 6.0, false)
	_check(_covered(pw.ring_cover(left, "l"), 1) > 0.99, "%s: party wall covered (left)" % tag)
	_check(_covered(pw.ring_cover(right, "r"), 3) > 0.99, "%s: party wall covered (right)" % tag)
	var piece: Array = pw.ring_cover(left, "l")[1][0]
	_check(is_equal_approx(float(piece[2]), 6.0), "%s: party wall top is the neighbour's" % tag)

	# An unregistered mass (raised part) keeps every wall.
	pw = _index(native)
	pw._add_ring(sq, "a", 12.0, false)
	var cr := pw.ring_cover(sq, "raised")
	for i in 4:
		_check(_covered(cr, i) < 0.01, "%s: unregistered mass keeps edge %d" % [tag, i])
