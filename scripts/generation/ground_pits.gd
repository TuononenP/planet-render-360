class_name GroundPits
extends RefCounted

## Holes cut in the ground surface for sunken openings (subway entrance
## stairwells, SubwayEntrances.pits). The terrain mesh is far coarser than
## a 1.9 m stair well, so the ground shader discards fragments inside each
## oriented rectangle and the builder fills the opening with real geometry
## below. Two small textures carry the pits to the shader:
## * map  (R8, GroundMaterial.CLASS_TEXELS square over the detailed
##   extent, nearest): 1-based id of the pit whose bounding box covers
##   the texel, 0 = none. Overlapping boxes keep the later pit.
## * data (RGBAF, one column per pit, two rows): row 0 = centre x, z and
##   unit forward x, z; row 1 = half width (across), half length (along).
## A pit is {c: Vector2 centre, f: Vector2 unit forward, hw, hl} in units.

const MAX_PITS := 255

## {map, data, count} for the data's pits; count 0 with 1x1 stand-ins
## when there are none (the shader's pit_count gate skips the lookup).
static func textures(pits: Array, n: int) -> Dictionary:
	var count := mini(pits.size(), MAX_PITS)
	var map := Image.create(n, n, false, Image.FORMAT_R8)
	var info := Image.create(maxi(count, 1), 2, false, Image.FORMAT_RGBAF)
	var extent := WorldScale.detailed_extent_units()
	for i in count:
		var p: Dictionary = pits[i]
		var c: Vector2 = p["c"]
		var f: Vector2 = p["f"]
		var hw := float(p["hw"])
		var hl := float(p["hl"])
		info.set_pixel(i, 0, Color(c.x, c.y, f.x, f.y))
		info.set_pixel(i, 1, Color(hw, hl, 0.0, 0.0))
		var r := Vector2(-f.y, f.x)
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var q: Vector2 = c + r * hw * sx + f * hl * sy
				lo = lo.min(q)
				hi = hi.max(q)
		var t0 := _texel(lo, extent, n) - Vector2i(1, 1)
		var t1 := _texel(hi, extent, n) + Vector2i(1, 1)
		for tz in range(maxi(t0.y, 0), mini(t1.y, n - 1) + 1):
			for tx in range(maxi(t0.x, 0), mini(t1.x, n - 1) + 1):
				map.set_pixel(tx, tz, Color(float(i + 1) / 255.0, 0.0, 0.0, 1.0))
	return {"map": ImageTexture.create_from_image(map),
		"data": ImageTexture.create_from_image(info), "count": count}

static func _texel(p: Vector2, extent: float, n: int) -> Vector2i:
	return Vector2i(floori((p.x / extent + 0.5) * float(n)),
		floori((p.y / extent + 0.5) * float(n)))

## GLSL lines for the fragment() prologue: discards inside any pit.
const GLSL := """
uniform sampler2D pit_map : filter_nearest, repeat_disable;
uniform sampler2D pit_data : filter_nearest, repeat_disable;
uniform int pit_count = 0;
bool in_pit(vec2 w, float extent, float n) {
	ivec2 t = clamp(ivec2(floor((w / extent + 0.5) * n)), ivec2(0), ivec2(int(n) - 1));
	int id = int(texelFetch(pit_map, t, 0).r * 255.0 + 0.5);
	if (id <= 0) {
		return false;
	}
	vec4 a = texelFetch(pit_data, ivec2(id - 1, 0), 0);
	vec4 b = texelFetch(pit_data, ivec2(id - 1, 1), 0);
	vec2 d = w - a.xy;
	return abs(dot(d, vec2(-a.w, a.z))) < b.x && abs(dot(d, a.zw)) < b.y;
}
"""
