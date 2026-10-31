extends SceneTree

## Auto accent (offline):
## godot --headless --script tests/accent_sun_test.gd

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	# Thresholds from the design system: below -6 Aurora, rising to +10
	# Dawn, daylight Glacier, setting down to +6 Dusk.
	var cases := [
		[-10.0, true, AccentSun.AURORA], [-10.0, false, AccentSun.AURORA],
		[-3.0, true, AccentSun.DAWN], [9.0, true, AccentSun.DAWN],
		[11.0, true, AccentSun.GLACIER], [40.0, false, AccentSun.GLACIER],
		[7.0, false, AccentSun.GLACIER], [5.0, false, AccentSun.DUSK],
		[-5.0, false, AccentSun.DUSK],
	]
	for c in cases:
		var got := AccentSun.index_for(c[0], c[1])
		if got != c[2]:
			failures.append("index_for(%s, rising=%s) = %d, want %d" % [c[0], c[1], got, c[2]])

	# Off by default: following the sun does nothing until Auto is chosen.
	UiTheme.apply_palette(AccentSun.GLACIER)
	var paris := {"year": 2026, "month": 6, "day": 21}
	AccentSun.follow(48.8566, 2.3522, paris, 0.0)
	if UiTheme.theme_index != AccentSun.GLACIER:
		failures.append("follow() changed the accent with Auto off")

	UiTheme.auto_mode = true
	# Paris midsummer: deep night, sunrise, noon, evening.
	var places := [[0.0, AccentSun.AURORA], [4.5, AccentSun.DAWN],
		[12.0, AccentSun.GLACIER], [19.5, AccentSun.DUSK]]
	for p in places:
		AccentSun.follow(48.8566, 2.3522, paris, p[0])
		if UiTheme.theme_index != p[1]:
			failures.append("Paris 21 Jun %.1f UTC: accent %d, want %d" % [p[0], UiTheme.theme_index, p[1]])
	# The colour glides to the target, then holds.
	await create_timer(AccentSun.FADE_SECONDS + 0.4).timeout
	if UiTheme.TEAL != UiTheme.ACCENTS[UiTheme.theme_index]:
		failures.append("accent colour should settle on ACCENTS[%d], got %s" % [UiTheme.theme_index, UiTheme.TEAL])
	if HudStyle.ACCENT != UiTheme.TEAL:
		failures.append("HudStyle.ACCENT should follow the accent")

	# A manual pick turns Auto off and ends any fade.
	AccentSun.follow(48.8566, 2.3522, paris, 0.0)
	UiTheme.apply_palette(AccentSun.GLACIER)
	await create_timer(AccentSun.FADE_SECONDS + 0.4).timeout
	if UiTheme.auto_mode or UiTheme.TEAL != UiTheme.ACCENTS[AccentSun.GLACIER]:
		failures.append("a manual pick should stop Auto and hold its colour")

	if failures.is_empty():
		print("ACCENT SUN OK: thresholds, sun-driven accent, fade, manual override")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: " + f)
		quit(1)
