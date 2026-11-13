class_name DemRelief
extends RefCounted

## Fine ground relief from the City of Helsinki's 1 m elevation model,
## as lighting only: the ground mesh stands on 9.4 m posts (GroundTruth,
## the same on every preset, AC-12), so kerbs of granite outcrop, ditches,
## embankments and mounds between posts are lost. A ±640 m window of the
## model at 2.5 m (HelsinkiDemFetcher variant "relief") minus a ~10 m
## bilinear copy of itself (the mesh's own relief) leaves what the posts
## miss; its slopes bend the ground shader's normal near the eye. Nothing
## moves. High / Ultra in the model's coverage (CityDetail).

const HALF_M := 640.0
const CELLS := 512
## The mesh's relief scale: CELLS → COARSE → CELLS bilinear ≈ 10 m posts.
const COARSE := 128
## Slopes past this (45°) clamp; RG8 encodes ±MAX_SLOPE.
const MAX_SLOPE := 1.0
const VARIANT := "relief"
## A harbour window is largely sea (no data): accept up to this share.
const MAX_MISSING := 0.6
const SOURCE := "helsinki_2021_1m_relief"

## RG8 residual slopes (dh/dx east, dh/dz south) of a decoded relief
## window, CELLS a side; null when the raster is unusable.
static func bake(raster: Dictionary) -> Image:
	if raster.is_empty() or Vector2i(raster.get("size", Vector2i.ZERO)) != Vector2i(CELLS, CELLS):
		return null
	var src: PackedFloat32Array = raster["values"]
	var cell: Vector2 = raster["cell"]
	# Missing cells are mostly sea: N2000 0 there (the shore meets it),
	# and texels touching one stay flat.
	var have := 0
	var hv := src.duplicate()
	var valid := PackedByteArray()
	valid.resize(hv.size())
	for i in hv.size():
		if hv[i] > HelsinkiDem.NODATA + 1.0:
			valid[i] = 1
			have += 1
		else:
			hv[i] = 0.0
	if float(have) < float(hv.size()) * (1.0 - MAX_MISSING):
		return null
	var fine := Image.create_from_data(CELLS, CELLS, false, Image.FORMAT_RF, hv.to_byte_array())
	var coarse := fine.duplicate() as Image
	coarse.resize(COARSE, COARSE, Image.INTERPOLATE_BILINEAR)
	coarse.resize(CELLS, CELLS, Image.INTERPOLATE_BILINEAR)
	var cv := coarse.get_data().to_float32_array()
	var out := PackedByteArray()
	out.resize(CELLS * CELLS * 2)
	var kx := 1.0 / (2.0 * maxf(cell.x, 0.01))
	var kz := 1.0 / (2.0 * maxf(cell.y, 0.01))
	for j in CELLS:
		var jm := maxi(j - 1, 0) * CELLS
		var jp := mini(j + 1, CELLS - 1) * CELLS
		var row := j * CELLS
		for i in CELLS:
			var im := maxi(i - 1, 0)
			var ip := mini(i + 1, CELLS - 1)
			if valid[row + im] == 0 or valid[row + ip] == 0 or valid[jm + i] == 0 or valid[jp + i] == 0:
				out[(row + i) * 2] = 128
				out[(row + i) * 2 + 1] = 128
				continue
			var dx := ((hv[row + ip] - cv[row + ip]) - (hv[row + im] - cv[row + im])) * kx
			var dz := ((hv[jp + i] - cv[jp + i]) - (hv[jm + i] - cv[jm + i])) * kz
			out[(row + i) * 2] = int(clampf(dx / MAX_SLOPE * 0.5 + 0.5, 0.0, 1.0) * 255.0 + 0.5)
			out[(row + i) * 2 + 1] = int(clampf(dz / MAX_SLOPE * 0.5 + 0.5, 0.0, 1.0) * 255.0 + 0.5)
	return Image.create_from_data(CELLS, CELLS, false, Image.FORMAT_RG8, out)

## The window in the ground shader's frame: (centre x, centre z, half x,
## half z) in world units. The request is centred on whole GK25 metres
## (HelsinkiDem.window_centre), not on the viewpoint, and GK25 metres
## differ slightly from the local frame's.
static func rect(lat: float, lon: float) -> Vector4:
	var c := HelsinkiDem.window_centre(lat, lon)
	var m2u := WorldScale.metres_to_units()
	var at := Gk25.to_xz(float(c.x), float(c.y), lat, lon)
	var ex := Gk25.to_xz(float(c.x) + 100.0, float(c.y), lat, lon)
	var nz := Gk25.to_xz(float(c.x), float(c.y) - 100.0, lat, lon)
	var sx := at.distance_to(ex) / 100.0
	var sz := at.distance_to(nz) / 100.0
	return Vector4(at.x * m2u, at.y * m2u, HALF_M * sx * m2u, HALF_M * sz * m2u)

## Binds the relief map onto the ground material, when one landed.
static func bind(m: ShaderMaterial, data: LocationData) -> void:
	if data.ground_detail.is_empty():
		return
	var img := bake(data.ground_detail)
	if img == null:
		return
	m.set_shader_parameter("dem_relief", ImageTexture.create_from_image(img))
	m.set_shader_parameter("relief_rect", rect(data.latitude, data.longitude))
