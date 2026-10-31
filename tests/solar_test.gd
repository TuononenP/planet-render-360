extends SceneTree

## True solar position (T6.2, offline):
## godot --headless --script tests/solar_test.gd
## Reference values are from the PyEphem ephemeris (geometric, no
## refraction), independent of the NOAA equations SolarPosition uses.

const TOL_DEG := 0.5

## [name, lat, lon, year, month, day, utc_hour, elevation, azimuth]
const CASES := [
	["Paris solstice morning", 48.8566, 2.3522, 2026, 6, 21, 10.0, 56.309, 128.830],
	["Paris winter noon", 48.8566, 2.3522, 2026, 12, 21, 12.0, 17.660, 182.731],
	["Paris late-October dusk", 48.8566, 2.3522, 2026, 10, 29, 16.0, 4.509, 243.331],
	["Interlaken equinox morning", 46.6863, 7.8632, 2026, 3, 20, 7.5, 19.006, 111.630],
	["Interlaken equinox afternoon", 46.6863, 7.8632, 2026, 9, 22, 15.25, 21.148, 246.018],
	["Reykjavik solstice midnight", 64.1466, -21.9426, 2026, 6, 21, 0.0, -0.693, 339.561],
	["Reykjavik winter noon", 64.1466, -21.9426, 2026, 12, 21, 13.5, 2.410, 180.949],
	["Reykjavik January evening", 64.1466, -21.9426, 2026, 1, 15, 18.0, -8.933, 239.440],
	["Longyearbyen midnight sun", 78.2232, 15.6267, 2026, 6, 21, 23.0, 11.658, 0.138],
	["Longyearbyen polar night", 78.2232, 15.6267, 2026, 12, 21, 11.0, -11.664, 181.045],
	["Sydney summer noon", -33.8688, 151.2093, 2026, 1, 15, 2.0, 77.239, 4.659],
]

func _init() -> void:
	var failures: Array[String] = []
	for c in CASES:
		var sp := SolarPosition.compute(float(c[1]), float(c[2]),
			{"year": c[3], "month": c[4], "day": c[5]}, float(c[6]))
		var de := absf(float(sp["elevation"]) - float(c[7]))
		var da := absf(fposmod(float(sp["azimuth"]) - float(c[8]) + 180.0, 360.0) - 180.0)
		if de > TOL_DEG or da > TOL_DEG:
			failures.append("%s: elev %.3f az %.3f, want %.3f %.3f" % [c[0],
				sp["elevation"], sp["azimuth"], c[7], c[8]])
	# A utc_hour past midnight rolls into the next day.
	var a := SolarPosition.compute(48.8566, 2.3522, {"year": 2026, "month": 6, "day": 21}, 25.0)
	var b := SolarPosition.compute(48.8566, 2.3522, {"year": 2026, "month": 6, "day": 22}, 1.0)
	if absf(float(a["elevation"]) - float(b["elevation"])) > 0.001:
		failures.append("utc_hour 25 should equal 01:00 next day")
	# Poles: defined, no NaN.
	for lat in [90.0, -90.0]:
		var p := SolarPosition.compute(lat, 0.0, {"year": 2026, "month": 6, "day": 21}, 12.0)
		if is_nan(float(p["elevation"])) or is_nan(float(p["azimuth"])):
			failures.append("pole %f gave NaN" % lat)
	var up := SolarPosition.direction(90.0, 0.0)
	var south := SolarPosition.direction(0.0, 180.0)
	var west := SolarPosition.direction(0.0, 270.0)
	if not up.is_equal_approx(Vector3.UP) or not south.is_equal_approx(Vector3(0, 0, 1)) \
			or not west.is_equal_approx(Vector3(-1, 0, 0)):
		failures.append("direction frame wrong (north is -Z, east +X): %s %s %s" % [up, south, west])
	_rig_checks(failures)
	if failures.is_empty():
		print("SOLAR OK: %d reference positions within %.1f°, poles, frame, rig edge cases" % [CASES.size(), TOL_DEG])
		quit(0)
	else:
		for f in failures:
			printerr("SOLAR FAIL: ", f)
		quit(1)

func _rig_checks(failures: Array[String]) -> void:
	var rig := AtmosphereRig.new()
	# Paris: the light comes from the real azimuth, not a fixed 65°.
	rig.set_place(48.8566, 2.3522)
	rig.set_utc_offset(1.0)
	rig.set_time(13.0, 48.8566, {"year": 2026, "month": 12, "day": 21})  # 12:00 UTC
	var light_from := Basis.from_euler(rig.sun.rotation).z
	var want := SolarPosition.direction(17.660, 182.731)
	if Vector2(light_from.x, light_from.z).normalized().dot(Vector2(want.x, want.z).normalized()) < 0.999:
		failures.append("Paris winter noon light should come from the south, got %s" % light_from)
	if absf(-rig.sun.rotation_degrees.x - 17.66) > TOL_DEG:
		failures.append("Paris winter noon light pitch %.2f, want 17.66" % -rig.sun.rotation_degrees.x)
	# Midnight sun and polar night: finite light/sky, never black.
	rig.set_place(78.2232, 15.6267)
	for state in [[{"year": 2026, "month": 6, "day": 21}, 0.0], [{"year": 2026, "month": 12, "day": 21}, 12.0]]:
		for h in [0.0, 6.0, 12.0, 18.0]:
			rig.set_time(h, 78.2232, state[0])
			var rot := rig.sun.rotation_degrees
			var sky := rig.sky_top_color
			if is_nan(rot.x) or is_nan(rot.y) or is_nan(sky.r) or is_nan(rig.night_amount):
				failures.append("Longyearbyen %s %02d:00 produced NaN" % [state[0], h])
			if rig.sun.light_energy <= 0.0 or sky.get_luminance() <= 0.005:
				failures.append("Longyearbyen %s %02d:00 renders black" % [state[0], h])
	rig.set_time(0.0, 78.2232, {"year": 2026, "month": 6, "day": 21})
	if rig.night_amount > 0.0:
		failures.append("midnight sun must not show the night sky")
	rig.set_time(12.0, 78.2232, {"year": 2026, "month": 12, "day": 21})
	if rig.night_amount <= 0.0:
		failures.append("polar-night noon should be dark sky")
	# Golden hour exists everywhere (closest afternoon hour when the sun
	# never crosses the reference elevation).
	var g := rig.golden_hour()
	if is_nan(g) or g < 12.0 or g > 24.0:
		failures.append("polar golden hour out of range: %f" % g)
	_moon_checks(rig, failures)
	rig.free()

## The real moon: phase from the date, light from where it stands.
func _moon_checks(rig: AtmosphereRig, failures: Array[String]) -> void:
	var full := SolarPosition.moon(48.8566, 2.3522, {"year": 2026, "month": 1, "day": 3}, 10.0)
	var new := SolarPosition.moon(48.8566, 2.3522, {"year": 2026, "month": 1, "day": 18}, 19.9)
	if float(full["illum"]) < 0.97 or float(new["illum"]) > 0.03:
		failures.append("moon phase: full %f, new %f" % [full["illum"], new["illum"]])
	rig.set_place(48.8566, 2.3522)
	rig.set_utc_offset(1.0)
	# Paris, local midnight: the full moon rides high in the south, the
	# new moon is down with the sun.
	rig.set_time(0.0, 48.8566, {"year": 2026, "month": 1, "day": 4})
	var full_e := rig.sun.light_energy
	var mf := rig.moon_state
	var light_from := Basis.from_euler(rig.sun.rotation).z
	var want := SolarPosition.direction(float(mf["elevation"]), float(mf["azimuth"]))
	if rig.moon_up < 1.0 or Vector2(light_from.x, light_from.z).normalized().dot(Vector2(want.x, want.z).normalized()) < 0.999:
		failures.append("full-moon light should come from the moon (%s)" % mf)
	rig.set_time(0.0, 48.8566, {"year": 2026, "month": 1, "day": 19})
	if rig.moon_up > 0.0 or float(rig.sky_material.get_shader_parameter("moon")) > 0.0:
		failures.append("new moon at midnight should be below the horizon")
	if not (full_e > rig.sun.light_energy * 4.0 and rig.sun.light_energy > 0.0):
		failures.append("full moon should outshine a moonless night: %f vs %f" % [full_e, rig.sun.light_energy])
