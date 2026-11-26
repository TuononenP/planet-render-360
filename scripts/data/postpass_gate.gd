class_name PostpassGate
extends RefCounted

## One Postpass request in flight for the whole app, as the Postpass usage
## policy asks of automated clients (no parallel requests, don't overload
## the server). Every caller (PostpassRequest, OsmFetcher's detailed layer)
## enters here and leaves when its answer lands or it is cancelled; the next
## one in line is sent then. After the server refuses (HTTP 429 or 503)
## Postpass rests for REFUSED_PAUSE_S: a caller entering then, and every
## caller still waiting, is told to skip (its next source) instead. A caller
## that has waited MAX_WAIT_S in line is told to skip too, so time spent
## waiting stays bounded (OsmFetcher.retry_budget_seconds counts it).

## Seconds Postpass is left alone after a 429 or 503.
const REFUSED_PAUSE_S := 60.0
## A holder that never left (a node freed mid-request) frees the slot after
## this long: longer than any Postpass timeout.
const STALE_HOLD_S := 120.0
## Seconds a caller may wait in line before it is told to skip.
const MAX_WAIT_S := 30.0
const PAUSED_REASON := "resting after the server refused a request"

static var _busy: Object = null
static var _busy_since_msec := 0
## Waiting callers in order: {"id": int, "owner": Object, "start": Callable,
## "skip": Callable}.
static var _queue: Array = []
static var _last_id := 0
static var _paused_until_msec := 0
## What the gate did since take_stats(): requests sent, ms the slot was
## held, and the longest ms a request waited in line (stream.log).
static var _sent := 0
static var _held_msec := 0
static var _max_wait_msec := 0

## "n requests, slot held X s, longest wait Y s" since the last call.
static func take_stats() -> String:
	var line := "%d requests, slot held %.1f s, longest wait %.1f s" % [_sent,
		_held_msec / 1000.0, _max_wait_msec / 1000.0]
	_sent = 0
	_held_msec = 0
	_max_wait_msec = 0
	return line

## Runs `start` now if no Postpass request is in flight, else when the ones
## ahead have left. `urgent` (the detailed layer) goes to the front of the
## line, a fetch-ahead's (a node under one marked LOW_META) goes to the back,
## behind every live one; its own `urgent` request goes ahead of the other
## fetch-ahead requests (the next stretch's map before any stretch's far
## city, ring or POIs). While Postpass rests after a refusal, or once it has waited
## `max_wait_s` in line, `skip(reason)` is called (never synchronously)
## instead. An owner already holding or waiting is replaced, not doubled.
static func enter(owner: Object, start: Callable, skip: Callable, urgent: bool = false,
		max_wait_s: float = MAX_WAIT_S) -> void:
	# Its earlier request is over; the slot it held goes to the next one.
	leave(owner)
	if paused():
		_skip.call_deferred(owner, skip, PAUSED_REASON)
		return
	_free_stale()
	var low := _is_low(owner)
	# A slot freed this frame goes to the ones already waiting first.
	if _busy == null and ((urgent and not low) or not _eligible_waiting()) and not (low and low_held()):
		_take(owner, start)
		return
	_last_id += 1
	var id := _last_id
	var entry := {"id": id, "owner": owner, "start": start, "skip": skip,
		"queued": Time.get_ticks_msec(), "low": low, "urgent": urgent}
	if urgent and not low:
		_queue.push_front(entry)
	elif low and not urgent:
		_queue.append(entry)
	else:
		# Behind the live ones; a live one ahead of every fetch-ahead's, a
		# fetch-ahead's detailed layer ahead of its other layers only.
		var at := _queue.size()
		for i in _queue.size():
			if _queue[i]["low"] and not (low and _queue[i]["urgent"]):
				at = i
				break
		_queue.insert(at, entry)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and max_wait_s > 0.0:
		tree.create_timer(max_wait_s).timeout.connect(func() -> void: _expire(id, max_wait_s))

## The owner's request is done or cancelled: frees its slot (or its place in
## line) and sends the next waiting request.
static func leave(owner: Object) -> void:
	_drop(owner)
	if _busy != owner:
		return
	_held_msec += Time.get_ticks_msec() - _busy_since_msec
	_busy = null
	_next.call_deferred()

## Releases any slot or queued request owned by `root` or its descendants
## (called when a GenerationPipeline is cancelled so the slot frees at once).
static func leave_subtree(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return
	for i in range(_queue.size() - 1, -1, -1):
		var o: Variant = _queue[i]["owner"]
		if o is Node and (o == root or root.is_ancestor_of(o as Node)):
			_queue.remove_at(i)
	if _busy is Node and (_busy == root or root.is_ancestor_of(_busy as Node)):
		_held_msec += Time.get_ticks_msec() - _busy_since_msec
		_busy = null
		_next.call_deferred()

## Elevates any queued Postpass requests under `root` from fetch-ahead (low)
## to live priority when StreamScout's warm pipeline is adopted by WorldStreamer.
static func promote_subtree(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return
	var moved: Array = []
	for i in range(_queue.size() - 1, -1, -1):
		var o: Variant = _queue[i]["owner"]
		if o is Node and (o == root or root.is_ancestor_of(o as Node)):
			var entry: Dictionary = _queue[i]
			entry["low"] = false
			_queue.remove_at(i)
			moved.push_front(entry)
	for entry: Dictionary in moved:
		if bool(entry.get("urgent", false)):
			_queue.push_front(entry)
		else:
			var at := _queue.size()
			for i in _queue.size():
				if _queue[i]["low"]:
					at = i
					break
			_queue.insert(at, entry)
	if _busy == null and not _queue.is_empty():
		_next.call_deferred()

## The server refused (429/503): no Postpass request for REFUSED_PAUSE_S.
static func note_refused() -> void:
	_paused_until_msec = Time.get_ticks_msec() + int(REFUSED_PAUSE_S * 1000.0)

static func paused() -> bool:
	return Time.get_ticks_msec() < _paused_until_msec

## Whether `owner` holds the slot (its request is on the wire).
static func holds(owner: Object) -> bool:
	return _busy == owner

static func waiting() -> int:
	return _queue.size()

## Forgets every holder, waiter and pause (tests).
static func reset() -> void:
	_live_until_msec = 0
	_busy = null
	_queue.clear()
	_paused_until_msec = 0

static func _take(owner: Object, start: Callable, queued := -1) -> void:
	_busy = owner
	_busy_since_msec = Time.get_ticks_msec()
	_sent += 1
	if queued >= 0:
		_max_wait_msec = maxi(_max_wait_msec, _busy_since_msec - queued)
	start.call()

static func _next() -> void:
	_free_stale()
	while _busy == null and not _queue.is_empty():
		var first := 0  # a fetch-ahead's request waits while a live build holds them back
		while first < _queue.size() and _queue[first]["low"] and low_held():
			first += 1
		if first >= _queue.size():
			return
		var entry: Dictionary = _queue.pop_at(first)
		if not is_instance_valid(entry["owner"]):
			continue
		if paused():
			_skip(entry["owner"], entry["skip"], PAUSED_REASON)
		elif (entry["start"] as Callable).is_valid():
			_take(entry["owner"], entry["start"], int(entry.get("queued", -1)))

## Tells a caller to skip, unless it was freed meanwhile (its callback
## would run against a freed node).
static func _skip(owner: Variant, skip: Callable, why: String) -> void:
	if is_instance_valid(owner) and skip.is_valid():
		skip.call(why)

## A waiter still in line after its max wait goes to its next source.
static func _expire(id: int, waited_s: float) -> void:
	for i in _queue.size():
		if int(_queue[i]["id"]) == id:
			var entry: Dictionary = _queue[i]
			_queue.remove_at(i)
			_skip(entry["owner"], entry["skip"], "waited %d s for a free slot" % int(waited_s))
			return

## A live build asks Postpass for its layers first: a fetch-ahead's requests
## do not start (a big far-city download on the wire would hold the build's
## own up for seconds) until it says they are in (release_low), or LIVE_HOLD_S
## passes.
const LIVE_HOLD_S := 40.0
static var _live_until_msec := 0

static func hold_low() -> void:
	_live_until_msec = Time.get_ticks_msec() + int(LIVE_HOLD_S * 1000.0)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.create_timer(LIVE_HOLD_S).timeout.connect(_next)

static func release_low() -> void:
	if low_held():
		_live_until_msec = 0
		_next.call_deferred()

## Whether a request that may start now is already waiting for the slot.
static func _eligible_waiting() -> bool:
	for entry: Dictionary in _queue:
		if not (entry["low"] and low_held()):
			return true
	return false

static func low_held() -> bool:
	return Time.get_ticks_msec() < _live_until_msec

## Meta set on a GenerationPipeline that only warms caches (the streamer's
## fetch ahead): everything it asks of Postpass waits behind live requests.
const LOW_META := "postpass_low"

static func _is_low(owner: Object) -> bool:
	var n := owner as Node
	while n != null:
		if n.has_meta(LOW_META):
			return bool(n.get_meta(LOW_META))
		n = n.get_parent()
	return false

static func _drop(owner: Object) -> void:
	for i in range(_queue.size() - 1, -1, -1):
		if _queue[i]["owner"] == owner:
			_queue.remove_at(i)

static func _free_stale() -> void:
	if _busy == null:
		return
	if not is_instance_valid(_busy) \
			or Time.get_ticks_msec() - _busy_since_msec > int(STALE_HOLD_S * 1000.0):
		_busy = null
