class_name TerrainTextures
extends RefCounted

## The terrain's photographic detail sets as two Texture2DArrays shared by
## the near ground (GroundShader) and the far rings (FarSurface): one
## array of albedos (linear data, read raw) and one of normal maps with
## the set's roughness packed into alpha, so a layer costs one albedo
## and one normal fetch. Layer order is LAYERS; GroundMaterial's palette
## weights index it.
##
## Phones (Fast/Balanced) get 512 px layers (≈11 MB per array instead of
## ≈44 MB); desktop tiers the bundled 1024 px.

const LAYERS := ["pavement", "lawn", "rock", "asphalt", "cliff", "forest", "gravel", "sand", "snow"]
## Metres one texture repeat spans on the ground, per layer.
const TILE_M := [3.0, 2.6, 4.0, 4.0, 9.0, 3.2, 2.4, 4.0, 5.0]
const SNOW := 8

static var _arrays: Dictionary = {}

static func size_for(preset: int) -> int:
	return 512 if RenderSettings.clamp_preset(preset) <= RenderSettings.Preset.BALANCED else 1024

## Packed arrays persist under user:// (built once per install): built
## worlds then reference them as external resources instead of
## embedding ~100 MB of layers in every WorldCache scene.
const DIR := "user://terrain"
const VERSION := 1

## {"albedo": Texture2DArray, "normal": Texture2DArray} at `size` px.
static func arrays(size: int = 1024) -> Dictionary:
	if _arrays.has(size):
		return _arrays[size]
	var key := "%s/layers_%d_v%d_%d" % [DIR, size, VERSION, hash(",".join(LAYERS))]
	var paths: Array[String] = [key + "_albedo.res", key + "_normal.res"]
	if FileAccess.file_exists(paths[0]) and FileAccess.file_exists(paths[1]):
		var la := ResourceLoader.load(paths[0]) as Texture2DArray
		var ln := ResourceLoader.load(paths[1]) as Texture2DArray
		if la != null and ln != null and la.get_layers() == LAYERS.size() \
				and la.get_width() == size and ln.get_width() == size:
			_arrays[size] = {"albedo": la, "normal": ln}
			return _arrays[size]
	var built := _build(size)
	# The headless dummy renderer keeps no texture data: never persist
	# an empty array. Saved via a temp name so a reader never sees half.
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(DIR)
		for i in 2:
			var res: Texture2DArray = built["albedo" if i == 0 else "normal"]
			var tmp: String = paths[i] + ".tmp.res"
			if ResourceSaver.save(res, tmp) == OK \
					and DirAccess.rename_absolute(tmp, paths[i]) == OK:
				res.take_over_path(paths[i])
	_arrays[size] = built
	return built

static func _build(size: int) -> Dictionary:
	var alb: Array[Image] = []
	var nor: Array[Image] = []
	for s in LAYERS:
		alb.append(_layer(s, "diff", size))
		var n := _layer(s, "nor", size)
		var r := _layer(s, "rough", size)
		# Roughness into the normal map's alpha (one fetch per layer).
		n.clear_mipmaps()
		r.clear_mipmaps()
		var nd := n.get_data()
		var rd := r.get_data()
		for i in range(0, nd.size(), 4):
			nd[i + 3] = rd[i]
		n = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, nd)
		n.generate_mipmaps(true)
		nor.append(n)
	var a := Texture2DArray.new()
	a.create_from_images(alb)
	var b := Texture2DArray.new()
	b.create_from_images(nor)
	return {"albedo": a, "normal": b}

## Per-layer mean albedo (linear), for normalising detail to structure.
static func means() -> PackedVector3Array:
	var out := PackedVector3Array()
	for s in LAYERS:
		var m: Color = (MaterialLibrary.PBR_SETS[s] as Dictionary)["mean"]
		out.append(Vector3(m.r, m.g, m.b))
	return out

static func tiles() -> PackedFloat32Array:
	return PackedFloat32Array(TILE_M)

static func _layer(set_name: String, map_name: String, size: int) -> Image:
	var img := (MaterialLibrary._set_image(set_name, map_name) as Image).duplicate() as Image
	img.clear_mipmaps()
	img.convert(Image.FORMAT_RGBA8)
	if img.get_width() != size or img.get_height() != size:
		img.resize(size, size, Image.INTERPOLATE_CUBIC)
	img.generate_mipmaps(map_name == "nor")
	return img
