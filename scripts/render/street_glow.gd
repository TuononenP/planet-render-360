class_name StreetGlow
extends RefCounted

## Lamp pools painted on the street surface at night (RoadSurface), on
## every tier and at any range: the real lamp lights (StreetLights, desktop
## Ultra) stop at the nearest few hundred lamps and fade out past ~200 m,
## and no other tier has them, so the streets went black under lit lamp
## glass. Pools sit where StreetProps stands its lampposts (every
## LAMP_SPACING_M, half a step in, alternating sides) on urban carriageways
## only, warm or cool as the place's lamps. Where real lights burn
## (street_lamp_near: their fade, in world units) the pools keep only a
## faint base, so the near street is not lit twice.

## Pool emission at full night, × the lit surface (lamp_albedo).
const GAIN := 0.6
## Share of the pool kept between lamps, so a lit street reads lit.
const FLOOR := 0.3
## Pool kept inside the real lights' reach (desktop Ultra).
const NEAR_SHARE := 0.5
const POOL_M := 5.5
## Mean of one pool along its LAMP_SPACING_M: sqrt(TAU) * POOL_M / 25.
const POOL_MEAN := 0.5515
## The far city's carpet of street lights (FarSurface), at full night on
## a fully built SettlementMap cell: an absolute glow, the far drape's
## albedo says nothing about the lamps.
const FAR_GAIN := 0.12
## The detailed ground takes the far glow only past this (m), in full
## 500 m on (GroundShader, inlined there): nearer, the drawn streets
## carry their own pools.
const GROUND_NEAR_M := 700.0
## Meta on a "StreetGlowMap" node (settle_node, BuildingBuilder): the
## SettlementMap as an L8 Image, kept in the cached world so a restored
## city glows too. A node of its own: TerrainBuilder adopts the buildings
## subtree's children flat and drops its root (and any meta on it).
const SETTLE_META := "street_glow_settle"

const GLSL := """
global uniform float street_lamp_glow;
global uniform vec3 street_lamp_tint;
global uniform vec2 street_lamp_near;
global uniform sampler2D street_lamp_settle : filter_linear, repeat_disable;
// (centre x, centre z, half extent, on) in world units.
global uniform vec4 street_lamp_settle_rect;

// The far city's light: the place's lamps pulled toward amber, as a
// distant city's mixed sodium, LED and window light reads.
vec3 far_lamp_tint() {
	return mix(street_lamp_tint, vec3(1.0, 0.62, 0.30), 0.65);
}

// How lit the far city is at world xz `p` (SettlementMap), 0 by day,
// in open country, parks and on water.
float lamp_settle(vec2 p) {
	if (street_lamp_glow <= 0.001 || street_lamp_settle_rect.w <= 0.0) {
		return 0.0;
	}
	vec2 uv = (p - street_lamp_settle_rect.xy) / (2.0 * street_lamp_settle_rect.z) + 0.5;
	if (uv.x <= 0.0 || uv.y <= 0.0 || uv.x >= 1.0 || uv.y >= 1.0) {
		return 0.0;
	}
	return smoothstep(0.15, 0.6, texture(street_lamp_settle, uv).r) * street_lamp_glow * %.3f;
}

// What a pool lights: the surface's colour, lifted so dark asphalt still
// reads lit under a lamp and pale paving does not flare.
vec3 lamp_albedo(vec3 a) {
	return a * 0.5 + vec3(0.07);
}

// Share of the pools left `d` world units out: a faint base inside the
// real lamp lights' reach (desktop Ultra), all of it past their fade.
float lamp_near(float d) {
	return street_lamp_near.y > 0.0
		? mix(%.2f, 1.0, smoothstep(street_lamp_near.x, street_lamp_near.x + street_lamp_near.y, d)) : 1.0;
}

// Lamp light on a ribbon at metres `m` (across from one edge, along) of a
// `w` m wide way, seen from `d` world units away, `fw` = fwidth(m.y); 0
// by day.
float lamp_pool(vec2 m, float w, float d, float fw) {
	if (street_lamp_glow <= 0.001 || w < 2.0) {
		return 0.0;
	}
	float k = floor(m.y / %.1f);
	float along = m.y - (k + 0.5) * %.1f;
	float edge = mod(k, 2.0) < 0.5 ? 0.0 : w;
	float across = m.x - edge;
	float reach = max(w * 0.7, 3.5);
	float a = exp(-along * along / (2.0 * %.2f));
	float c = exp(-across * across / (2.0 * reach * reach));
	// Far off, the pools settle to their mean instead of flickering.
	float mean = %.4f * exp(-0.5 * (w * 0.5) * (w * 0.5) / (reach * reach));
	a = mix(a * c, mean, smoothstep(1.5, 6.0, fw));
	return (%.2f + (1.0 - %.2f) * a) * lamp_near(d) * street_lamp_glow * %.2f;
}

// The pools' average, for paint laid over the street (RoadPaint), which
// has no lamp positions of its own.
float lamp_mean(float d) {
	return (%.2f + (1.0 - %.2f) * %.4f * 0.8) * lamp_near(d) * street_lamp_glow * %.2f;
}
""" % [FAR_GAIN, NEAR_SHARE, StreetProps.LAMP_SPACING_M, StreetProps.LAMP_SPACING_M, POOL_M * POOL_M,
	POOL_MEAN, FLOOR, FLOOR, GAIN, FLOOR, FLOOR, POOL_MEAN, GAIN]

## Last night share sent (the dummy renderer can't read globals back).
static var night := 0.0
## The published light map: the global holds only its RID, so it is kept
## alive here (freed, the far city sampled black).
static var _settle_tex: ImageTexture

## Night share `amount` (CityLights.amount_for) of the pools.
static func set_night(amount: float) -> void:
	night = clampf(amount, 0.0, 1.0)
	RenderingServer.global_shader_parameter_set("street_lamp_glow", night)

## The place's lamp colour and, where real lamp lights burn, their fade
## (world units: begin, length; zero length for none).
static func set_place(tint: Color, near_begin: float = 0.0, near_length: float = 0.0) -> void:
	RenderingServer.global_shader_parameter_set("street_lamp_tint", Vector3(tint.r, tint.g, tint.b))
	RenderingServer.global_shader_parameter_set("street_lamp_near", Vector2(near_begin, near_length))

## The place's lamp colour and near fade from `data` alone, so a world
## restored from the cache (no StreetProps build) is lit as a fresh one.
static func set_place_for(data: LocationData) -> void:
	var m2u := WorldScale.metres_to_units()
	var region := ArchitectureStyle.country_region_for(data.latitude, data.longitude, data.country)
	var family := StreetProps.lamp_family(region, data.country, CityStyles.region_at(data.latitude, data.longitude))
	var real := RenderQuality.ultra_desktop(data.quality_preset)
	set_place(StreetLights.colour_for(StreetProps.lamp_style(family, region, "residential"), region),
		StreetLights.FADE_BEGIN_M * m2u if real else 0.0, StreetLights.FADE_LENGTH_M * m2u if real else 0.0)

## `smap`'s built score as an L8 image, parks and water cleared.
static func settle_image(smap: SettlementMap) -> Image:
	if smap == null or smap.is_empty() or smap.n <= 0:
		return null
	var bytes := PackedByteArray()
	bytes.resize(smap.n * smap.n)
	for k in bytes.size():
		bytes[k] = 0 if smap.blocked[k] != 0 else clampi(roundi(smap.score[k] * 255.0), 0, 255)
	return Image.create_from_data(smap.n, smap.n, false, Image.FORMAT_L8, bytes)

## The node carrying `smap`'s light map (SETTLE_META), or null.
static func settle_node(smap: SettlementMap) -> Node3D:
	var img := settle_image(smap)
	if img == null:
		return null
	var n := Node3D.new()
	n.name = "StreetGlowMap"
	n.set_meta(SETTLE_META, img)
	return n

## Publishes `img` (settle_image) as the far city's light map, or clears it.
static func set_settlement(img: Image) -> void:
	if img == null:
		RenderingServer.global_shader_parameter_set("street_lamp_settle_rect", Vector4.ZERO)
		return
	var half_u := float(img.get_width()) * 0.5 * SettlementMap.CELL_M * WorldScale.metres_to_units()
	_settle_tex = ImageTexture.create_from_image(img)
	RenderingServer.global_shader_parameter_set("street_lamp_settle", _settle_tex)
	RenderingServer.global_shader_parameter_set("street_lamp_settle_rect", Vector4(0.0, 0.0, half_u, 1.0))

## Everything a shown world needs (ViewConditions.dress): the place's lamps
## (`top`, the world itself) and the light map its build left on a node
## (SETTLE_META). A world handed over piece by piece brings the map with
## a later piece, so only a whole world without one clears it.
static func apply_world(world: Node, data: LocationData, top: bool = true) -> void:
	if top and data != null:
		set_place_for(data)
	var img: Image = null
	for n in [world] + (world.get_children() if world != null else []):
		if n != null and (n as Node).has_meta(SETTLE_META):
			img = (n as Node).get_meta(SETTLE_META) as Image
			break
	if img != null or top:
		set_settlement(img)
