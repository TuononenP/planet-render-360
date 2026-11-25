class_name LodSpread
extends RefCounted

## Spreads a full-world LodRing.apply() walk over frames (16 top-level
## children per frame, mirroring AltitudeReach's RANGE_SLICES) so a preset
## switch does not freeze the main thread on a 2.7k-node walk. Pure
## cursor/count logic plus LodRing.apply_child; the world is read-only.
const SLICES := 16

var _world: Node
var _preset := 0
var _cursor := 0

## Begins (or restarts) a spread re-range of `world` for `preset`.
func begin(world: Node, preset: int) -> void:
	_world = world
	_preset = preset
	_cursor = 0

## One slice's worth of children; clears itself when the walk is done or
## the world goes away.
func tick() -> void:
	if _world == null or not is_instance_valid(_world):
		_world = null
		return
	var stop := mini(_world.get_child_count(), _cursor + SLICES)
	while _cursor < stop:
		LodRing.apply_child(_world, _cursor, _preset)
		_cursor += 1
	if _cursor >= _world.get_child_count():
		_world = null

func cancel() -> void:
	_world = null
