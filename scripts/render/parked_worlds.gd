class_name ParkedWorlds
extends RefCounted

## Built worlds not shown, kept hidden in the tree for a turn back
## (WorldStreamer): {world, data, ground, ll}, oldest first. A ready world
## given up for a new heading, and the world each swap leaves, park here;
## a centre started towards one swaps it in again with no build at all.
## How many stay is the device's memory tier (MemoryBudget.PARK_MAX), and
## none while MemoryGuard is short of memory: each holds a whole world,
## its satellite mosaic and its ground.

var _parked: Array[Dictionary] = []
## Frees a world over the frames to come (WorldHandoff.retire).
var _retire: Callable

func _init(retire: Callable) -> void:
	_retire = retire

## How many may stay now.
static func cap() -> int:
	return 0 if MemoryGuard.level >= MemoryGuard.Level.TIGHT \
		else MemoryBudget.PARK_MAX[MemoryBudget.tier()]

func size() -> int:
	return _parked.size()

## Parks `world` (built for `ll`, lat/lon) hidden; the oldest leave past
## cap(), and a world missing its data or ground leaves at once.
func park(world: Node3D, data: LocationData, ground: GroundTruth, ll: Vector2) -> void:
	if data == null or ground == null:
		_retire.call(world)
		return
	world.visible = false
	_parked.append({"world": world, "data": data, "ground": ground, "ll": ll})
	trim()

## Frees the oldest past cap() (all of them while memory is short).
func trim() -> void:
	while _parked.size() > cap():
		_retire.call(_parked.pop_front()["world"])

## Frees those farther than `max_m` from the centre (lat, lon).
func prune(lat: float, lon: float, max_m: float) -> void:
	for i in range(_parked.size() - 1, -1, -1):
		var ll: Vector2 = _parked[i]["ll"]
		if WorldScale.xz_from_latlon(ll.x, ll.y, lat, lon).length() > max_m:
			_retire.call(_parked[i]["world"])
			_parked.remove_at(i)

func free_all() -> void:
	for p in _parked:
		_retire.call(p["world"])
	_parked.clear()

## Forgets them (the world root frees in-tree ones; detached ones are freed here).
func forget() -> void:
	for p in _parked:
		var w: Variant = p.get("world")
		if is_instance_valid(w) and not (w as Node).is_inside_tree():
			(w as Node).free()
	_parked.clear()

## Removes and returns the newest entry `fits(entry)` accepts ({} none).
## Entries whose world was freed meanwhile are skipped.
func take(fits: Callable) -> Dictionary:
	for i in range(_parked.size() - 1, -1, -1):
		var p: Dictionary = _parked[i]
		if is_instance_valid(p["world"]) and fits.call(p):
			_parked.remove_at(i)
			return p
	return {}
