class_name ShaderOrigin
extends RefCounted

## Where the live world's origin lies (m) on one continuous map that the
## streamer's swaps never reset. Shaders that hash world position
## (facade weathering, lite-facade lit windows, roof snow) add it as the
## global world_origin_m, so their patterns stay put on the ground
## through a swap instead of reshuffling across the whole city. Wrapped
## every WRAP_M to keep float precision in the shaders (under 4 mm at
## the wrap, finer than any pattern hashed on it): no wrap is a period of
## those patterns, so they reshuffle once per WRAP_M of travel, not at
## every swap.

const WRAP_M := 65536.0
static var _origin := Vector2.ZERO

## `world` takes the origin of `old` (the live world, else the last one
## set) moved by the swap: the old centre lies at `old_centre` in the new
## frame. Returns the origin now set.
static func carry(old: Node3D, world: Node3D, old_centre: Vector2) -> Vector2:
	var from: Vector2 = old.get_meta("origin_m", _origin) \
		if old != null and is_instance_valid(old) else _origin
	var o := from - old_centre
	o = Vector2(fposmod(o.x, WRAP_M), fposmod(o.y, WRAP_M))
	if world != null:
		world.set_meta("origin_m", o)
	_origin = o
	RenderingServer.global_shader_parameter_set("world_origin_m", o)
	return o
