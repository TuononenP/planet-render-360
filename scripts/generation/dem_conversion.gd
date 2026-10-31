class_name DemConversion
extends RefCounted

## Vertical DEM conversion for GenerationPipeline (split out to keep
## the pipeline under the class-size budget). Callers keep using
## GenerationPipeline.convert_dem_heights, which forwards here.

## The v1 adaptive factor (relief remapped to ~30 units). True-metre
## mode still uses it to un-squash the water plane (see below); the
## squash path itself is deleted in T3.1 (contract §7 V1).
static func legacy_vscale_for(relief_m: float) -> float:
	return clampf(30.0 / maxf(relief_m, 1.0), 0.02, 0.35)

## Pure vertical conversion (T1.3): raw DEM metres ASL → render heights.
## Identity by default (heights ARE source metres); legacy_squash=true
## restores the v1 adaptive remap for A/B captures. Returns {heights,
## centre_elevation_m, relief_metres, water_level, legacy_vscale}.
## The true-metre water plane is the un-squashed v1 plane
## (centre − 6/vscale: the raw value v1 mapped to −3.0), so flood
## extent is unchanged by the unit cutover.
static func convert_dem_heights(raw_metres: PackedFloat32Array, grid: int,
		use_legacy_squash: bool) -> Dictionary:
	var centre_m := raw_metres[(grid / 2) * grid + grid / 2]
	var mn := raw_metres[0]
	var mx := raw_metres[0]
	for h in raw_metres:
		mn = minf(mn, h)
		mx = maxf(mx, h)
	var vscale := legacy_vscale_for(mx - mn)
	var out := {
		"centre_elevation_m": centre_m,
		"relief_metres": mx - mn,
		"legacy_vscale": vscale,
	}
	if use_legacy_squash:
		var squashed := PackedFloat32Array()
		squashed.resize(raw_metres.size())
		for idx in raw_metres.size():
			squashed[idx] = (raw_metres[idx] - centre_m) * vscale + 3.0
		out["heights"] = squashed
		out["water_level"] = -3.0
	else:
		out["heights"] = raw_metres.duplicate()
		out["water_level"] = centre_m - 6.0 / vscale
	return out
