extends SceneTree

## Headless: godot --headless --script tests/postpass_gate_test.gd
## PostpassGate keeps one Postpass request on the wire for the whole app
## (Postpass usage policy: no parallel requests): later callers wait their
## turn, the detailed layer goes to the front, a cancelled caller leaves the
## line, and after a refusal (429/503) callers are told to skip. No network.

var _fails := 0
var _log: Array = []

class Owner extends RefCounted:
	var name := ""
	func _init(n: String) -> void:
		name = n

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	await _serial()
	await _urgent_and_cancel()
	await _refused()
	await _low_priority()
	await _reentry_and_wait()
	await _requests()
	PostpassGate.reset()
	if _fails == 0:
		print("postpass_gate_test: PASS")
	quit(1 if _fails > 0 else 0)

func _enter(owner: Owner, urgent: bool = false) -> void:
	PostpassGate.enter(owner, func() -> void: _log.append(owner.name),
		func(why: String) -> void: _log.append("skip " + owner.name + ": " + why), urgent)

func _serial() -> void:
	PostpassGate.reset()
	_log.clear()
	var a := Owner.new("a")
	var b := Owner.new("b")
	var c := Owner.new("c")
	_enter(a)
	_enter(b)
	_enter(c)
	_check(_log == ["a"] and PostpassGate.holds(a) and PostpassGate.waiting() == 2,
		"only the first request is sent while it is in flight: %s" % [_log])
	PostpassGate.leave(b)  # a waiter that leaves is not sent
	PostpassGate.leave(a)
	await process_frame
	_check(_log == ["a", "c"] and PostpassGate.holds(c), "the next in line goes when the slot frees: %s" % [_log])
	PostpassGate.leave(c)
	await process_frame
	_check(PostpassGate.waiting() == 0 and not PostpassGate.holds(c), "the gate empties")

func _urgent_and_cancel() -> void:
	PostpassGate.reset()
	_log.clear()
	var ring := Owner.new("ring")
	var far := Owner.new("far")
	var detailed := Owner.new("detailed")
	_enter(ring)
	_enter(far)
	_enter(detailed, true)
	PostpassGate.leave(ring)
	await process_frame
	_check(_log == ["ring", "detailed"], "the detailed layer goes ahead of the ones waiting: %s" % [_log])
	# Entering again replaces the owner's place instead of doubling it.
	_enter(far)
	_check(PostpassGate.waiting() == 1, "an owner waits once")
	# A newcomer while the slot is freeing waits behind the line.
	PostpassGate.leave(detailed)
	var late := Owner.new("late")
	_enter(late)
	await process_frame
	_check(_log == ["ring", "detailed", "far"], "those already waiting go before a newcomer: %s" % [_log])
	PostpassGate.leave(far)
	await process_frame
	_check(_log.back() == "late", "then the newcomer: %s" % [_log])
	PostpassGate.leave(late)

## A fetch-ahead's requests (a node under one marked LOW_META) go behind
## every live one, urgent or not, and keep their own order.
func _low_priority() -> void:
	PostpassGate.reset()
	_log.clear()
	var warm := Node.new()
	warm.set_meta(PostpassGate.LOW_META, true)
	var nodes: Dictionary = {}
	for n: String in ["first", "w1", "w2", "live", "live2", "urgent"]:
		var node := Node.new()
		node.name = n
		nodes[n] = node
		if n.begins_with("w"):
			warm.add_child(node)
	var enter := func(n: String, urgent := false) -> void:
		PostpassGate.enter(nodes[n], func() -> void: _log.append(n),
			func(why: String) -> void: _log.append("skip " + n + ": " + why), urgent)
	for n: String in ["first", "w1", "w2", "live", "live2"]:
		enter.call(n)
	enter.call("urgent", true)
	for n: String in ["first", "urgent", "live", "live2", "w1", "w2"]:
		PostpassGate.leave(nodes[n])
		await process_frame
	_check(_log == ["first", "urgent", "live", "live2", "w1", "w2"],
		"live requests go ahead of a fetch-ahead's, in order: %s" % [_log])
	# A fetch-ahead's detailed layer (urgent) goes ahead of the fetch-ahead's
	# other layers, in its own order, and never ahead of a live request:
	# the next stretch's map before any stretch's far city.
	PostpassGate.reset()
	_log.clear()
	for n: String in ["wd1", "wd2"]:
		var node := Node.new()
		node.name = n
		nodes[n] = node
		warm.add_child(node)
	for n: String in ["first", "w1", "w2"]:
		enter.call(n)
	enter.call("wd1", true)
	enter.call("live")
	enter.call("wd2", true)
	enter.call("urgent", true)
	for n: String in ["first", "urgent", "live", "wd1", "wd2", "w1", "w2"]:
		PostpassGate.leave(nodes[n])
		await process_frame
	_check(_log == ["first", "urgent", "live", "wd1", "wd2", "w1", "w2"],
		"a fetch-ahead's detailed layer leads its other layers, behind the live ones: %s" % [_log])
	# In a free slot it still gives way to a live request already waiting.
	PostpassGate.reset()
	_log.clear()
	enter.call("first")
	enter.call("live")
	PostpassGate.leave(nodes["first"])  # the slot frees; "live" is sent next frame
	enter.call("wd1", true)
	await process_frame
	_check(_log == ["first", "live"], "a live request waiting takes the freed slot first: %s" % [_log])
	PostpassGate.leave(nodes["live"])
	await process_frame
	_check(_log == ["first", "live", "wd1"], "then the fetch-ahead's detailed layer: %s" % [_log])
	# While a live build holds them back, a fetch-ahead's request does not start
	# even in a free slot; it goes once the live layers are in.
	PostpassGate.reset()
	_log.clear()
	PostpassGate.hold_low()
	enter.call("w1")
	await process_frame
	_check(_log.is_empty() and not PostpassGate.holds(nodes["w1"]) and PostpassGate.waiting() == 1,
		"a fetch-ahead waits for the live layers: %s" % [_log])
	enter.call("live")
	await process_frame
	_check(_log == ["live"], "a live request goes at once: %s" % [_log])
	PostpassGate.leave(nodes["live"])
	PostpassGate.release_low()
	await process_frame
	await process_frame
	_check(_log == ["live", "w1"], "the fetch-ahead goes once released: %s" % [_log])
	PostpassGate.reset()
	warm.free()
	for n: String in ["first", "live", "live2", "urgent"]:
		(nodes[n] as Node).free()

func _refused() -> void:
	PostpassGate.reset()
	_log.clear()
	var a := Owner.new("a")
	var b := Owner.new("b")
	_enter(a)
	_enter(b)
	PostpassGate.note_refused()
	_check(PostpassGate.paused(), "a refusal rests Postpass")
	PostpassGate.leave(a)
	await process_frame
	_check(_log.size() == 2 and str(_log[1]).begins_with("skip b"),
		"a waiter is told to skip while Postpass rests: %s" % [_log])
	var c := Owner.new("c")
	_enter(c)
	await process_frame
	_check(_log.size() == 3 and str(_log[2]).begins_with("skip c") and not PostpassGate.holds(c),
		"a newcomer is told to skip too: %s" % [_log])
	_check(PostpassFallback.refused(429) and PostpassFallback.refused(503) and not PostpassFallback.refused(504),
		"429 and 503 count as refusals")
	PostpassGate.reset()

## An owner that enters again while holding the slot does not stall the
## line; a waiter past its max wait is told to skip; a freed owner's skip
## never runs.
func _reentry_and_wait() -> void:
	PostpassGate.reset()
	_log.clear()
	var a := Owner.new("a")
	var b := Owner.new("b")
	_enter(a)
	_enter(b)
	_enter(a)  # again, without leaving first: behind b now
	await process_frame
	_check(_log == ["a", "b"] and PostpassGate.holds(b) and PostpassGate.waiting() == 1,
		"re-entering hands the slot on instead of stalling: %s" % [_log])
	PostpassGate.leave(b)
	await process_frame
	_check(_log.back() == "a", "and the re-entered owner follows: %s" % [_log])
	PostpassGate.leave(a)
	await process_frame
	# A short max wait: the waiter skips once it passes.
	_log.clear()
	var holder := Owner.new("holder")
	var slow := Owner.new("slow")
	_enter(holder)
	PostpassGate.enter(slow, func() -> void: _log.append("slow"),
		func(why: String) -> void: _log.append("skip slow: " + why), false, 0.05)
	await create_timer(0.2).timeout
	_check(_log.size() == 2 and str(_log[1]).begins_with("skip slow: waited")
		and PostpassGate.waiting() == 0, "a waiter past its max wait skips: %s" % [_log])
	PostpassGate.leave(holder)
	await process_frame
	_check(_log.size() == 2, "an expired waiter is not sent later: %s" % [_log])
	# A freed owner is told nothing.
	_log.clear()
	PostpassGate.note_refused()
	var node := Node.new()
	PostpassGate.enter(node, func() -> void: _log.append("node"),
		func(why: String) -> void: _log.append("skip node: " + why))
	node.free()
	await process_frame
	_check(_log.is_empty(), "a freed owner's skip does not run: %s" % [_log])
	PostpassGate.reset()

## Two PostpassRequests: the second waits, and reports the skip as a failure
## while Postpass rests.
func _requests() -> void:
	PostpassGate.reset()
	var first := PostpassRequest.new()
	var second := PostpassRequest.new()
	root.add_child(first)
	root.add_child(second)
	var fails := []
	second.failed.connect(func(why: String) -> void: fails.append(why))
	var holder := Owner.new("holder")
	_enter(holder)
	first.run("data=x")
	second.run("data=y")
	_check(PostpassGate.waiting() == 2 and not PostpassGate.holds(first), "requests wait behind the holder")
	first.cancel()
	_check(PostpassGate.waiting() == 1, "a cancelled request leaves the line")
	PostpassGate.note_refused()
	PostpassGate.leave(holder)
	for i in 5:
		await process_frame
	_check(fails.size() == 1 and str(fails[0]).begins_with("Postpass resting"),
		"a request skipped while Postpass rests fails over: %s" % [fails])
	PostpassGate.reset()
	first.free()
	second.free()

func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("FAIL: ", what)
