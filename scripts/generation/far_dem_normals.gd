class_name FarDemNormals
extends RefCounted

## Normal maps for the far terrain, baked from the DEM rings. The ring meshes
## space vertices 94-312 m apart, but the rings hold heights every 25-100 m:
## real ridges and gullies that the mesh loses, and that noise relief only
## imitated. High and Ultra; each map covers one ring, addressed through the
## drape UVs the far surface already carries.

static var _mutex := Mutex.new()

## Binds the two coarsest rings' maps to `mat`, addressed through the drapes
## showing `fine` and `coarse`. A band with no such drape keeps noise relief.
static func bind(mat: ShaderMaterial, data: LocationData, fine: Texture2D, coarse: Texture2D) -> void:
	if data == null or data.quality_preset < RenderSettings.Preset.HIGH or data.dem_rings.size() < 2:
		return
	var n := data.dem_rings.size()
	_bind_one(mat, data, "fine", data.dem_rings[n - 2], fine)
	_bind_one(mat, data, "coarse", data.dem_rings[n - 1], coarse)

static func _bind_one(mat: ShaderMaterial, data: LocationData, slot: String, ring: Dictionary,
		drape_tex: Texture2D) -> void:
	if drape_tex == null:
		return
	for drape: Dictionary in data.far_drapes:
		if drape.get("texture") == drape_tex:
			mat.set_shader_parameter("dem_%s" % slot, _texture(ring, data.latitude))
			mat.set_shader_parameter("dem_%s_map" % slot, uv_map(drape, ring))
			mat.set_shader_parameter("has_dem_%s" % slot, 1.0)
			return

## Scale (xy) and offset (zw) taking the drape's UV to the ring's.
static func uv_map(drape: Dictionary, ring: Dictionary) -> Vector4:
	var k := pow(2.0, float(int(ring["zoom"]) - int(drape["zoom"])))
	var size := Vector2(float(ring["width"]), float(ring["height"]))
	var d_size := Vector2(drape["size_px"]) * k
	var offset := (Vector2(drape["origin_px"]) * k - Vector2(ring["origin_px"])) / size
	return Vector4(d_size.x / size.x, d_size.y / size.y, offset.x, offset.y)

## The ring's map, baked once however many bands share it.
static func _texture(ring: Dictionary, lat: float) -> Texture2D:
	_mutex.lock()
	if not ring.has("normal_tex"):
		var img := bake(ring, DemFetcher.metres_per_px(lat, int(ring["zoom"])))
		img.generate_mipmaps()
		ring["normal_tex"] = ImageTexture.create_from_image(img)
	var tex: Texture2D = ring["normal_tex"]
	_mutex.unlock()
	return tex

## World normal of each ring pixel, x in R and z in G (x east, z south), from
## central differences of its heights `mpp` metres apart.
static func bake(ring: Dictionary, mpp: float) -> Image:
	var w := int(ring["width"])
	var h := int(ring["height"])
	var heights: PackedFloat32Array = ring["heights"]
	var bytes := PackedByteArray()
	bytes.resize(w * h * 2)
	var span := 2.0 * mpp
	for y in h:
		var up := maxi(y - 1, 0) * w
		var down := mini(y + 1, h - 1) * w
		for x in w:
			var left := y * w + maxi(x - 1, 0)
			var right := y * w + mini(x + 1, w - 1)
			var dx := (heights[right] - heights[left]) / span
			var dz := (heights[down + x] - heights[up + x]) / span
			var k := 1.0 / sqrt(dx * dx + dz * dz + 1.0)
			bytes[(y * w + x) * 2] = int(clampf((-dx * k) * 127.5 + 127.5, 0.0, 255.0))
			bytes[(y * w + x) * 2 + 1] = int(clampf((-dz * k) * 127.5 + 127.5, 0.0, 255.0))
	return Image.create_from_data(w, h, false, Image.FORMAT_RG8, bytes)
