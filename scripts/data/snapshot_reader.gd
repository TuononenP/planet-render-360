class_name SnapshotReader
extends Node

## Reads bundled OSM snapshots (BundledOsm.read: inflate, UTF-8, SHA-256 and
## payload checks, ~0.1-0.2 s for a big city, several times that on a phone)
## on the worker pool, so the loading screen keeps drawing. Callers
## `await read(key)` and check their own generation afterwards, because a
## newer fetch may have started while the snapshot was loading.
##
## Several reads may run at once. Each carries a token, so a read that
## outlived its caller's interest cannot hand its text to a later one.

signal completed(token: int, text: String)

var _serial := 0
var _tasks: Dictionary = {}  # token -> WorkerThreadPool task id

## The snapshot's text, or "" when `key` is empty, unknown or unusable.
## Returns at once, without suspending, for an empty key.
func read(key: String) -> String:
	if key == "":
		return ""
	_serial += 1
	var token := _serial
	_tasks[token] = WorkerThreadPool.add_task(func() -> void:
		_deliver.call_deferred(token, BundledOsm.read(key)))
	while true:
		var got: Array = await completed
		if got[0] == token:
			return got[1]
	return ""

func _deliver(token: int, text: String) -> void:
	_join(token)
	completed.emit(token, text)

func _join(token: int) -> void:
	if _tasks.has(token):
		WorkerThreadPool.wait_for_task_completion(_tasks[token])
		_tasks.erase(token)

## Reads in flight must not outlive the node they report to.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for token in _tasks.keys():
			_join(token)
