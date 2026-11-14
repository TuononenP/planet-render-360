#pragma once

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

// The satellite photo under world XZ (GroundCover._photo_at through
// TerrainBuilder.satellite_uv), byte-identical with the script: float64
// lat/lon and mercator pixels, the UV rounded to a Vector2 as the script's.
class PhotoSampler : public RefCounted {
	GDCLASS(PhotoSampler, RefCounted)

	Ref<Image> image;
	double lat = 0.0, lon = 0.0, mosaic = 1.0;
	int zoom = 0, width = 0, height = 0;
	Vector2 origin;

protected:
	static void _bind_methods();

public:
	// The mosaic, the view's centre, the stitched zoom, the mosaic's
	// global-pixel origin and its size in pixels.
	void setup(const Ref<Image> &image, double lat, double lon, int zoom, const Vector2 &origin_px, double mosaic_px);
	// Linear photo colour at (x, z), alpha 0 off the photo.
	Color photo(double x, double z) const;
	// How many of the four photo points `r` east, west, south and north of
	// (x, z) are vegetation (GroundCover.photo_green with these thresholds).
	int green_around(double x, double z, double r, double green_min, double lum_min) const;
	// MaterialLibrary.sampled_roof_color: the raw photo's mean over a 3 x 3
	// grid a quarter of the size apart around (x, z), from Color(0, 0, 0).
	Color roof_sample(double x, double z, double size_x, double size_z) const;
};

} // namespace godot
