extends SceneTree

## Headless: godot --headless --script tests/shore_abutment_test.gd
## A bridge abutment is the bridge deck's concrete, wherever the build
## order puts the water stage. The water stage runs before the roads
## stage, so in a process that already built a stone-quay place (Paris)
## RoadBuilder._mats["deck"] still holds that place's limestone deck;
## the abutment must not duplicate it (a white stone slab on a granite
## quay). Stone-quay places keep their limestone abutments.

func _data(lat: float, lon: float) -> LocationData:
	var d := LocationData.new()
	d.latitude = lat
	d.longitude = lon
	return d

func _init() -> void:
	var failures: Array[String] = []
	var helsinki := _data(60.1699, 24.9384)
	var paris := _data(48.8566, 2.3522)
	if not QuayBuilder.stone_quays(paris):
		failures.append("Paris core must count as stone quays")
	if QuayBuilder.stone_quays(helsinki):
		failures.append("Helsinki must not count as stone quays")
	# A Paris roads stage's leftovers: its limestone deck cached as the
	# deck finish, no abutment memoized yet in this process.
	var stale := StandardMaterial3D.new()
	stale.albedo_color = Color.WHITE
	var stale_tex := ImageTexture.create_from_image(
		Image.create(8, 8, false, Image.FORMAT_RGB8))
	stale.albedo_texture = stale_tex
	RoadBuilder._mats["deck"] = stale
	RoadBuilder._stone_deck = stale
	ShoreBankMesh._abutment_mat = null
	var abut := ShoreBankMesh.abutment_material(helsinki) as StandardMaterial3D
	if abut == null:
		failures.append("a non-stone place must get a concrete abutment")
	else:
		var concrete := ShoreBankMesh._concrete_deck_material() as StandardMaterial3D
		if concrete == null:
			failures.append("there must be a place-independent concrete deck")
		else:
			if is_same(abut.albedo_texture, stale_tex):
				failures.append("the abutment must not duplicate the previous place's deck")
			if not is_same(abut.albedo_texture, concrete.albedo_texture):
				failures.append("the abutment must carry the concrete deck texture")
			if abut.albedo_color != concrete.albedo_color:
				failures.append("the abutment must carry the concrete deck tint, got %s" % abut.albedo_color)
		if not abut.uv1_triplanar or not abut.uv1_world_triplanar:
			failures.append("the abutment stays world-triplanar (no UVs on shore walls)")
	# Stone-quay places bypass the memo: still limestone after all this.
	var stone := ShoreBankMesh.abutment_material(paris) as StandardMaterial3D
	if stone == null or not is_same(stone, QuayBuilder.stone_material(paris)):
		failures.append("a stone-quay place must keep its limestone abutment")
	# Memoized for the process: a second call is the same abutment.
	if not is_same(ShoreBankMesh.abutment_material(helsinki), abut):
		failures.append("the abutment stays memoized within the process")
	RoadBuilder._mats.erase("deck")
	RoadBuilder._stone_deck = null
	ShoreBankMesh._abutment_mat = null
	ShoreBankMesh._deck_mat = null
	if failures.is_empty():
		print("SHORE ABUTMENT OK")
		quit(0)
	else:
		for f in failures:
			printerr("SHORE ABUTMENT FAIL: ", f)
		quit(1)
