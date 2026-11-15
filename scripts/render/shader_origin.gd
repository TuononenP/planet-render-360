class_name ShaderOrigin
extends RefCounted

## Where the live world's origin lies (m) on one continuous map that the
## streamer's swaps never reset (an opened place starts it at zero).
## Shaders that hash world position (facade weathering, lite-facade lit
## windows, roof snow) add it as the global world_origin_m, and the far
## city builds its grid and hashes on it (LocationData.origin_m), so all
## of them stay put on the ground through a swap instead of reshuffling.
## Wrapped every WRAP_M (a whole number of the far city's 600 m district
## patches) to keep float precision in the shaders, under 4 mm there: no
## wrap is a period of every pattern, so they reshuffle once per WRAP_M
## of travel, not at every swap.

const WRAP_M := 64800.0
const META := "origin_m"
static var _origin := Vector2.ZERO

## An opened place starts the map over.
static func reset() -> void:
	_origin = Vector2.ZERO
	RenderingServer.global_shader_parameter_set("world_origin_m", _origin)

static func wrapped(o: Vector2) -> Vector2:
	return Vector2(fposmod(o.x, WRAP_M), fposmod(o.y, WRAP_M))

## `world`'s origin (the last one set when it has none of its own).
static func of(world: Node3D) -> Vector2:
	return world.get_meta(META, _origin) as Vector2 if world != null and is_instance_valid(world) else _origin

## The origin of a world centred `step` (the live world's frame) from the
## live world `live`: what its build stands on (LocationData.origin_m).
static func ahead(live: Node3D, step: Vector2) -> Vector2:
	return wrapped(of(live) + step)

## Makes `world` the live one: its own origin when its build set one,
## else `old`'s moved by the swap (the old centre lies at `old_centre`
## in the new frame). Returns the origin now set.
static func carry(old: Node3D, world: Node3D, old_centre: Vector2) -> Vector2:
	var o := wrapped(of(old) - old_centre)
	if world != null and world.has_meta(META):
		o = world.get_meta(META) as Vector2
	elif world != null:
		world.set_meta(META, o)
	_origin = o
	RenderingServer.global_shader_parameter_set("world_origin_m", o)
	return o
