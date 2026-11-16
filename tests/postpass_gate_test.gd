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
