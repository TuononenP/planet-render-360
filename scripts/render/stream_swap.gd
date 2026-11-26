class_name StreamSwap
extends RefCounted

## Endless walk & fly: seats the view on a streamed world just swapped in
## (WorldStreamer.apply_swap): the camera over the same ground at the
## same height, and everything that reads the place or caches the old
## ground told of the new one. v._data and v._ground are the new world's
## already.

## `new_xz`: the camera in the new centre's frame; `agl`: its height over
## the old ground.
static func seat(v: View360, data: LocationData, new_xz: Vector2, agl: float) -> void:
	var y := v._ground.height_at_world(new_xz.x, new_xz.y) + agl
	if not v._drone.on:
		# Keep the walker's height when the new centre's floor agrees
		# with it (ViewWalk lerps the small rest while moving); snap
		# when it does not — a set-down from flight, an authored
		# island or quay floor — so the eye is right even standing
		# still, where no lerp runs.
		var foot := ViewWalk.foot_y(data, v._ground, new_xz)
		if absf(foot - y) > 0.5:
			y = foot
	v._rig.position = Vector3(new_xz.x, y, new_xz.y)
	v._atmos.ground_at = func(x: float, z: float) -> float: return v._ground.height_at_world(x, z)
	v._atmos.set_place(data.latitude, data.longitude)
	v._atmos.set_coast(v._ground.render_y(0.0), data.waterways.any(func(w: Variant) -> bool:
		return w is Dictionary and str((w as Dictionary).get("class", "")) == "coastline"))
	v._atmos.set_probe_origin(v._rig.position)
	# Defer non-camera-critical UI/horizon updates off the swap frame.
	var ground := v._ground
	_defer_post_swap.call_deferred(v, data, ground)
	v._walk._spans_for = null
	v._walk._near_at = Vector2.INF
	v._walk._near.clear()
	v._drone._obstacles.invalidate()
	if v._drone.on:
		# Momentum is frame-relative and survives the recentre: only
		# the height-over-ground and floor caches are re-derived. A
		# resync left pending by a glide the swap just killed must
		# not eat the first frame's momentum either.
		v._drone._resync = false
		v._drone._agl = clampf(agl, ViewDrone.AGL_MIN_M, ViewDrone.AGL_MAX_M)
	else:
		v._drone._resync = true

static func _defer_post_swap(v: View360, data: LocationData, ground: GroundTruth) -> void:
	if not is_instance_valid(v) or v._data != data:
		return
	if v._horizon != null:
		v._horizon.set_place(data, ground)
	if v._minimap != null:
		v._minimap.set_place(data)
	ViewChrome.show_place(v, data)
