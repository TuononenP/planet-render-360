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

const GLSL := """
global uniform float street_lamp_glow;
global uniform vec3 street_lamp_tint;
global uniform vec2 street_lamp_near;

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
""" % [NEAR_SHARE, StreetProps.LAMP_SPACING_M, StreetProps.LAMP_SPACING_M, POOL_M * POOL_M,
	POOL_MEAN, FLOOR, FLOOR, GAIN, FLOOR, FLOOR, POOL_MEAN, GAIN]

## Last night share sent (the dummy renderer can't read globals back).
static var night := 0.0

## Night share `amount` (CityLights.amount_for) of the pools.
static func set_night(amount: float) -> void:
	night = clampf(amount, 0.0, 1.0)
	RenderingServer.global_shader_parameter_set("street_lamp_glow", night)

## The place's lamp colour and, where real lamp lights burn, their fade
## (world units: begin, length; zero length for none).
static func set_place(tint: Color, near_begin: float = 0.0, near_length: float = 0.0) -> void:
	RenderingServer.global_shader_parameter_set("street_lamp_tint", Vector3(tint.r, tint.g, tint.b))
	RenderingServer.global_shader_parameter_set("street_lamp_near", Vector2(near_begin, near_length))
