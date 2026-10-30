class_name RenderQuality
extends RefCounted

## The photoreal layer of each tier. RenderSettings holds what a tier
## costs (mesh density, counts, render scale); this holds what the
## renderer does with the frame. Desktop runs Forward+, where Ultra
## turns on the full light-transport set:
## - SDFGI bounce light: sunlit facades fill the street, grass greens
##   the walls above it.
## - SSIL: colour bleed at small scale.
## - SSAO: contact shadow where walls meet ground.
## - SSR: water, glass and wet streets mirror the scene itself, not
##   only the probe's cubemap.
## - Volumetric fog lit and shadowed by the sun: light shafts through
##   gaps in the skyline and trees at low sun.
## - TAA.
## High gets SSAO and SSR. Phones run the Mobile renderer, which has none
## of those effects, so there each tier sharpens what Mobile can do:
## MSAA, anisotropy, shadow-map size and softness, reflection detail.
##
## AC-12: every tier keeps ACES, the same sky, sun, haze and exponential
## fog. The effects add occlusion, bounce light and reflections in the
## scene's own colours; the volumetric medium takes the haze colour, so
## no tier brings a new grade.

## Sun's angular diameter (deg): physical penumbrae (PCSS) on Ultra.
const SUN_ANGLE_DEG := 0.53
## Ultra volumetric haze: extinction per metre and froxel reach (m).
## Thin enough that the exponential haze still sets visibility; dense
## enough that sun-side shafts read at golden hour.
const VOLUME_PER_M := 0.0012
const VOLUME_FOG_PER_M := 0.006
const VOLUME_LENGTH_M := 500.0

static func is_forward_plus() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"

## Feature set of `preset` on Forward+ (`forward_plus`) or Mobile.
static func features_for(preset: int, forward_plus: bool) -> Dictionary:
	var p := RenderSettings.clamp_preset(preset)
	var ultra := p == RenderSettings.Preset.ULTRA
	var high := p >= RenderSettings.Preset.HIGH
	return {
		"ssao": forward_plus and high,
		"ssil": forward_plus and ultra,
		"ssr": forward_plus and high,
		"ssr_steps": 64 if ultra else 32,
		"sdfgi": forward_plus and ultra,
		"volumetric_fog": forward_plus and ultra,
		"taa": forward_plus and ultra,
		"msaa": [Viewport.MSAA_DISABLED, Viewport.MSAA_DISABLED, Viewport.MSAA_2X,
			Viewport.MSAA_2X if forward_plus else Viewport.MSAA_4X][p],
		"screen_aa": Viewport.SCREEN_SPACE_AA_SMAA if p == RenderSettings.Preset.BALANCED
			else Viewport.SCREEN_SPACE_AA_DISABLED,
		"anisotropy": [Viewport.ANISOTROPY_4X, Viewport.ANISOTROPY_4X, Viewport.ANISOTROPY_8X,
			Viewport.ANISOTROPY_16X][p],
		"debanding": high,
		# Phones keep the 4096 default: an 8192 map is 128 MB.
		"shadow_atlas": 8192 if ultra and forward_plus else 4096,
		"soft_shadows": [RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_LOW,
			RenderingServer.SHADOW_QUALITY_SOFT_LOW,
			RenderingServer.SHADOW_QUALITY_SOFT_HIGH if forward_plus else RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM][p],
		"sun_angle": SUN_ANGLE_DEG if ultra else 0.0,
		"sky_radiance": Sky.RADIANCE_SIZE_256 if ultra else Sky.RADIANCE_SIZE_128,
	}

## Environment effects. Unsupported ones are simply ignored by the
## Mobile renderer, but they are switched off there anyway so the
## state reads true.
static func apply_environment(env: Environment, preset: int, forward_plus: bool = is_forward_plus()) -> void:
	var f := features_for(preset, forward_plus)
	var ultra := RenderSettings.clamp_preset(preset) == RenderSettings.Preset.ULTRA
	env.ssao_enabled = f["ssao"]
	# Metre world, eye at 30 m: a radius that reads at kerb and cornice
	# scale. AO only darkens indirect light (light_affect 0) — direct
	# sun keeps its full strength, as in reality.
	env.ssao_radius = 2.5
	env.ssao_intensity = 1.6
	env.ssao_power = 1.4
	env.ssao_detail = 0.6
	env.ssao_light_affect = 0.0
	env.ssil_enabled = f["ssil"]
	env.ssil_radius = 6.0
	env.ssil_intensity = 0.7
	env.ssil_normal_rejection = 1.0
	env.ssr_enabled = f["ssr"]
	env.ssr_max_steps = int(f["ssr_steps"])
	env.ssr_fade_in = 0.12
	env.ssr_fade_out = 2.5
	env.ssr_depth_tolerance = 0.6
	env.sdfgi_enabled = f["sdfgi"]
	# Six cascades from 0.8 m cells: cascade 0 covers the near streets
	# (~50 m), the last reaches ~1.6 km across the detailed extent.
	env.sdfgi_cascades = 6
	env.sdfgi_min_cell_size = 0.8
	env.sdfgi_use_occlusion = true
	env.sdfgi_read_sky_light = true
	env.sdfgi_bounce_feedback = 0.45
	env.sdfgi_energy = 1.0
	env.volumetric_fog_enabled = f["volumetric_fog"]
	env.volumetric_fog_length = VOLUME_LENGTH_M
	# Froxels crowd toward the eye, where shafts are seen.
	env.volumetric_fog_detail_spread = 2.0
	# Forward scattering: shafts glow looking toward the sun.
	env.volumetric_fog_anisotropy = 0.6
	env.volumetric_fog_gi_inject = 0.6
	env.volumetric_fog_ambient_inject = 0.35
	env.volumetric_fog_sky_affect = 0.0
	env.volumetric_fog_temporal_reprojection_enabled = true
	if env.sky != null:
		env.sky.radiance_size = f["sky_radiance"]
	# Server-wide quality knobs (one 3D view, so global is per view).
	RenderingServer.environment_set_ssao_quality(
		RenderingServer.ENV_SSAO_QUALITY_HIGH if ultra else RenderingServer.ENV_SSAO_QUALITY_MEDIUM,
		not ultra, 0.5, 2, 150.0, 1200.0)
	RenderingServer.environment_set_ssil_quality(RenderingServer.ENV_SSIL_QUALITY_MEDIUM, true, 0.5, 4, 80.0, 600.0)
	RenderingServer.environment_set_volumetric_fog_volume_size(128 if ultra else 64, 128 if ultra else 64)

## Sun shadow map size, filter and penumbra.
static func apply_light(sun: DirectionalLight3D, preset: int, forward_plus: bool = is_forward_plus()) -> void:
	var f := features_for(preset, forward_plus)
	RenderingServer.directional_shadow_atlas_set_size(int(f["shadow_atlas"]), true)
	RenderingServer.directional_soft_shadow_filter_set_quality(int(f["soft_shadows"]))
	sun.light_angular_distance = float(f["sun_angle"])
	# Fog shafts need the sun's shadow inside the volume.
	sun.light_volumetric_fog_energy = 1.0
	sun.shadow_opacity = 1.0

## Anti-aliasing, anisotropy and debanding of the 3D view.
static func apply_viewport(vp: Viewport, preset: int, forward_plus: bool = is_forward_plus()) -> void:
	var f := features_for(preset, forward_plus)
	vp.msaa_3d = f["msaa"]
	vp.screen_space_aa = f["screen_aa"]
	vp.use_taa = f["taa"]
	vp.anisotropic_filtering_level = f["anisotropy"]
	vp.use_debanding = f["debanding"]

## Volumetric medium in the haze colour, per light state: denser in fog
## and drizzle; the albedo follows the haze so it adds shafts, not tint.
static func update_volume(env: Environment, haze: Color, foggy: bool, units_per_metre: float) -> void:
	env.volumetric_fog_albedo = haze
	env.volumetric_fog_density = (VOLUME_FOG_PER_M if foggy else VOLUME_PER_M) / maxf(units_per_metre, 1e-4)
