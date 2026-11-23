extends SceneTree

## Miami and regional glazing palettes in TowerLooks + Miami white balcony-band
## facade finish (MI-3C).

var failures: Array[String] = []

func _init() -> void:
	_check(TowerLooks._family("miami", "miami") == "miami", "miami region resolves to miami family")
	_check(TowerLooks._family("mi_condo_tower", "miami") == "miami", "miami city resolves to miami family")
	_check(TowerLooks.glazing({"region": "miami", "city": "miami"}, 2005, 0.20) == "lowe_blue",
		"miami 0.20 share -> lowe_blue")
	_check(TowerLooks.glazing({"region": "miami", "city": "miami"}, 2005, 0.45) == "green_glass",
		"miami 0.45 share -> green_glass")
	_check(TowerLooks.glazing({"region": "miami", "city": "miami"}, 2005, 0.65) == "silver_reflective",
		"miami 0.65 share -> silver_reflective")
	_check(TowerLooks.glazing({"region": "miami", "city": "miami"}, 2005, 0.82) == "clear_fin",
		"miami 0.82 share -> clear_fin")
	_check(TowerLooks.glazing({"region": "miami", "city": "miami"}, 1984, 0.95) == "intl_bronze",
		"miami 0.95 share -> intl_bronze")
	_check(TowerLooks.glazing({"region": "miami", "city": "miami"}, 2022, 0.20) == "clear_fin",
		"post-2013 miami tower takes clear_fin at low h")

	var look := {"city": "miami", "region": "miami", "kind": "apartments", "wall_set": "glass",
		"pattern": "curtain", "storeys": 40, "floor_h": 3.4, "bay_m": 3.2}
	var applied := TowerLooks.apply({"levels": 40, "start_year": 2008}, look, 0.42)
	_check(applied.has("tower_look") and str(applied.get("curtain", "")) in ["lowe_blue", "green_glass", "silver_reflective", "clear_fin", "intl_bronze"],
		"TowerLooks.apply assigns Miami glazing to 40-storey Miami glass tower")

	_check(FacadeComposer.is_tiled("balcony_band"), "balcony_band is registered in FacadeComposer.TILED")
	_check(FacadePatterns.has("balcony_band"), "balcony_band is registered in FacadePatterns.NAMES")
	_check(FacadeComposer.smooth_plaster("render", {"city": "miami"}), "miami uses smooth plaster")

	var mat := SkyKit.material("balcony_white", 3.2, 3.4)
	_check(mat != null and str(mat.get_meta("facade_pattern", "")) == "balcony_band",
		"SkyKit balcony_white builds a balcony_band facade material")
	var alb_tex := mat.albedo_texture
	_check(alb_tex != null and alb_tex.get_width() == FacadeComposer.CELL * FacadeComposer.BAYS,
		"balcony_white composes a 4-bay tile texture")

	if failures.is_empty():
		print("tower_looks_test: PASS")
		quit(0)
	else:
		for f in failures:
			printerr("TOWER LOOKS FAIL: ", f)
		quit(1)

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
