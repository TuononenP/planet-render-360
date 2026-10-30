class_name PostGrade
extends RefCounted

## Tonemap, grade, glow, ambient and haze defaults of the 360 view's
## Environment, applied once by AtmosphereRig. Every tier shares them
## (AC-12): ACES, one grade, the same glow, ambient and fog model.
##
## - Glow only from true highlights (HDR threshold 1.0, no bloom): sun
##   glints on water and glass, the sun disc, lit windows at night. A
##   bloom term spreads every pixel over the frame and reads as milk.
## - Ambient light is the sky itself, so shade turns blue under a blue
##   sky, grey under overcast and dark at night; no fixed fill colour.
## - Contrast and a touch of saturation over ACES, which rolls off
##   highlights and greys the mid-tones on its own.

## ACES with a white point of 6: highlights (sun-lit stone, sky near the
## sun, glints) roll off like film instead of clipping at 1.0, which
## washed the frame toward white; exposure lifts the mid-tones back.
const EXPOSURE := 1.45
const WHITE := 6.0
const CONTRAST := 1.1
const SATURATION := 1.1
const AMBIENT_ENERGY := 0.55
const GLOW_THRESHOLD := 1.0
const GLOW_INTENSITY := 0.32

## Exposure and contrast per tier: the same curve, hue and saturation
## everywhere (AC-12), but tiers without shadows (Fast) or without SSAO
## (the Mobile renderer, Balanced) have no dark contact and shade terms,
## and at the shadowed tiers' exposure they read pale and milky.
static func apply_tier(env: Environment, preset: int, forward_plus: bool) -> void:
	var p := RenderSettings.clamp_preset(preset)
	var lean := not forward_plus or p == RenderSettings.Preset.FAST
	var mid := forward_plus and p == RenderSettings.Preset.BALANCED
	env.tonemap_exposure = EXPOSURE * (0.86 if lean else (0.93 if mid else 1.0))
	env.adjustment_contrast = CONTRAST + (0.05 if lean else (0.02 if mid else 0.0))

static func apply(env: Environment) -> void:
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.73, 0.80, 0.85)  # #B9CBD8, unused at full sky
	env.ambient_light_energy = AMBIENT_ENERGY
	env.ambient_light_sky_contribution = 1.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = EXPOSURE
	env.tonemap_white = WHITE
	env.adjustment_enabled = true
	env.adjustment_contrast = CONTRAST
	env.adjustment_saturation = SATURATION
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_energy = 1.0
	env.fog_sun_scatter = 0.25
	# The sky shader draws its own horizon haze; fog stays off it so
	# the cloud deck is not double-hazed.
	env.fog_sky_affect = 0.0
	# Far geometry picks up the sky's directional colour: warm toward
	# the sun, blue-grey away from it.
	env.fog_aerial_perspective = 0.55
	env.glow_enabled = true
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = GLOW_THRESHOLD
	env.glow_hdr_scale = 2.0
	env.glow_intensity = GLOW_INTENSITY
	env.glow_strength = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	# Wide, soft levels: a halo around glints, not a sharp ring.
	for i in 7:
		env.set_glow_level(i, 1.0 if i >= 2 and i <= 5 else 0.0)
