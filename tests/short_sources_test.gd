extends SceneTree

## Headless: godot --headless --script tests/short_sources_test.gd
## The attribution pill names each source briefly, and an owner with
## several credits once: "© City of Helsinki: Elevation model 2021,
## building register, tree register", where its first credit stood.

func _init() -> void:
	var full := " · ".join(PackedStringArray([HelsinkiDem.CREDIT,
		"Imagery: Esri, Vantor, Earthstar Geographics", "© HSY, orthophoto 2023",
		"Map data: © OpenStreetMap contributors", HelsinkiRegister.CREDIT, HelsinkiTrees.CREDIT]))
	var got := HudParts.short_sources(full)
	var want := "© City of Helsinki: Elevation model 2021, building register, tree register · Esri, Vantor, Earthstar Geographics · © HSY, orthophoto 2023 · © OpenStreetMap contributors"
	var fails := 0
	if got != want:
		fails += 1
		printerr("FAIL: short_sources\n  got  %s\n  want %s" % [got, want])
	# One credit of an owner stays as it was.
	var one := HudParts.short_sources(HelsinkiRegister.CREDIT)
	if one != "© City of Helsinki, building register":
		fails += 1
		printerr("FAIL: a lone credit changed: ", one)
	if fails == 0:
		print("short_sources_test: PASS")
	quit(1 if fails > 0 else 0)
