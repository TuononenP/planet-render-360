extends SceneTree

## WorldScale unit test (T1.2): godot --headless --script tests/world_scale_test.gd
## Guards contract §1: true-metre lat/lon conversion at the 5 golden
## locations (independent hardcoded expectations, 0.5 m tolerance),
## the latlon inverse round-trip, render-origin rebasing, and the
## metre cutover (T7.0: identity units, 2400 m extent, no legacy flag).

# Golden centres (plan T0.1): lat, lon, expected x for +0.008° lon.
# Expected values computed independently (python, full precision):
# x = 0.008 * 111320 * cos(rad(clat)); z = -0.005 * 110540 = -552.7.
const GOLDEN := [
	["paris", 48.8566, 2.3522, 585.9403],
	["interlaken", 46.6863, 7.8632, 610.9173],
	["banff", 51.1789, -115.5708, 558.2838],
	["bigsur", 36.2704, -121.8081, 717.9998],
	["turku", 60.4518, 22.2666, 439.1846],
]
const EXPECT_Z := -552.7

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []

	if WorldScale.DETAILED_EXTENT_M != 2400.0:
		failures.append("DETAILED_EXTENT_M should be 2400, got %s" % WorldScale.DETAILED_EXTENT_M)

	# T7.0 metre cutover: the v1 equivalence flag is gone; 1 unit = 1 m
	# and the detailed extent is 2400 units.
	if "legacy_880m_equivalence" in WorldScale.new():
		failures.append("legacy_880m_equivalence must be deleted at the cutover")
	if WorldScale.metres_to_units() != 1.0:
		failures.append("metres_to_units should be identity, got %s" % WorldScale.metres_to_units())
	if WorldScale.detailed_extent_units() != 2400.0:
		failures.append("extent should be 2400 units, got %s" % WorldScale.detailed_extent_units())
	var script_consts: Dictionary = (WorldScale as Script).get_script_constant_map()
	for k in script_consts:
		if str(k).begins_with("LEGACY_"):
			failures.append("legacy constant %s must be deleted" % k)

	# Known lat/lon offsets -> metre XZ within 0.5 m at golden locations.
	for g in GOLDEN:
		var c_lat: float = g[1]
		var c_lon: float = g[2]
		var xz := WorldScale.xz_from_latlon(c_lat + 0.005, c_lon + 0.008, c_lat, c_lon)
		# Axes: +X = east, +Z = south (north offset -> -Z).
		if xz.distance_to(Vector2(g[3], EXPECT_Z)) > 0.5:
			failures.append("%s offset should be ~(%.1f, %.1f) m, got %s"
				% [g[0], g[3], EXPECT_Z, str(xz)])
		# Inverse round-trips to the original offset. Looser than the
		# 0.5 m forward check: degrees stored in a Vector2 (float32)
		# quantise to ~0.1–0.3 m at these latitudes by representation.
		var ll := WorldScale.latlon_from_xz(xz.x, xz.y, c_lat, c_lon)
		var back := WorldScale.xz_from_latlon(ll.x, ll.y, c_lat, c_lon)
		if back.distance_to(xz) > 1.0:
			failures.append("%s latlon round-trip drifted: %s -> %s" % [g[0], str(xz), str(back)])

	# Centre maps to origin exactly.
	var zero := WorldScale.xz_from_latlon(48.8566, 2.3522, 48.8566, 2.3522)
	if zero.length() > 0.000001:
		failures.append("centre should map to origin, got %s" % str(zero))

	# Render origin: pipeline datum shifts Y only (contract §1.3).
	var ws := WorldScale.new()
	ws.set_origin(48.8566, 2.3522, 35.0)
	var rp := ws.to_render(Vector3(100.0, 80.0, -50.0))
	if rp.distance_to(Vector3(100.0, 45.0, -50.0)) > 0.0001:
		failures.append("to_render should subtract elevation on Y only, got %s" % str(rp))

	# v1 shim: OsmFetcher.local_xz is now true metres.
	var shim := OsmFetcher.local_xz(48.8566 + 0.005, 2.3522 + 0.008, 48.8566, 2.3522)
	if shim.distance_to(Vector2(585.9403, EXPECT_Z)) > 0.5:
		failures.append("local_xz should give true metres, got %s" % str(shim))
	# Deprecated v1 aliases are gone (contract §7 V4–V7).
	for pair in [[TerrainBuilder, "WORLD_SIZE"], [TerrainBuilder, "METRES_TO_WORLD"],
			[OsmFetcher, "WORLD_SCALE"]]:
		if (pair[0] as Script).get_script_constant_map().has(pair[1]):
			failures.append("deprecated alias %s must be deleted" % pair[1])

	# CameraRig records the render origin without moving (T1.2 seam).
	var rig := CameraRig.new()
	rig.set_render_origin(Vector3(100.0, 35.0, -50.0))
	if rig.render_origin != Vector3(100.0, 35.0, -50.0):
		failures.append("rig should record the render origin")
	if rig.position != Vector3.ZERO:
		failures.append("recording the origin must not move the rig, got %s" % str(rig.position))
	rig.free()

	if failures.is_empty():
		print("WORLDSCALE OK: metre conversions, round-trip, origin, metre cutover (no legacy aliases)")
		quit(0)
	else:
		for f in failures:
			printerr("WORLDSCALE FAIL: ", f)
		quit(1)
