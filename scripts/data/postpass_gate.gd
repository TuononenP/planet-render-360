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

## Runs `start` now if no Postpass request is in flight, else when the ones
## ahead have left. `urgent` (the detailed layer) goes to the front of the
## line. While Postpass rests after a refusal, or once it has waited
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
	# A slot freed this frame goes to the ones already waiting first.
	if _busy == null and (urgent or _queue.is_empty()):
		_take(owner, start)
		return
	_last_id += 1
	var id := _last_id
	var entry := {"id": id, "owner": owner, "start": start, "skip": skip}
	if urgent:
		_queue.push_front(entry)
	else:
		_queue.append(entry)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and max_wait_s > 0.0:
		tree.create_timer(max_wait_s).timeout.connect(func() -> void: _expire(id, max_wait_s))

## The owner's request is done or cancelled: frees its slot (or its place in
## line) and sends the next waiting request.
static func leave(owner: Object) -> void:
	_drop(owner)
	if _busy != owner:
		return
	_busy = null
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
	_busy = null
	_queue.clear()
	_paused_until_msec = 0

static func _take(owner: Object, start: Callable) -> void:
	_busy = owner
	_busy_since_msec = Time.get_ticks_msec()
	start.call()

static func _next() -> void:
	_free_stale()
	while _busy == null and not _queue.is_empty():
		var entry: Dictionary = _queue.pop_front()
		if not is_instance_valid(entry["owner"]):
			continue
		if paused():
			_skip(entry["owner"], entry["skip"], PAUSED_REASON)
		elif (entry["start"] as Callable).is_valid():
			_take(entry["owner"], entry["start"])

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
