#include "photo_sampler.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <algorithm>
#include <cmath>

namespace godot {

void PhotoSampler::setup(const Ref<Image> &p_image, double p_lat, double p_lon, int p_zoom, const Vector2 &origin_px,
		double mosaic_px) {
	image = p_image;
	lat = p_lat;
	lon = p_lon;
	zoom = p_zoom;
	origin = origin_px;
	mosaic = mosaic_px;
	const bool usable = image.is_valid() && !image->is_empty() && !image->is_compressed();
	width = usable ? image->get_width() : 0;
	height = usable ? image->get_height() : 0;
}

// TerrainBuilder.satellite_uv.
static Vector2 mosaic_uv(double lat, double lon, int zoom, const Vector2 &origin, double mosaic, double x, double z) {
	// WorldScale.latlon_from_xz: a Vector2, so float lat / lon.
	const double north_m = -z, east_m = x;
	const real_t lat_f = (real_t)(lat + north_m / 110540.0);
	const real_t lon_f = (real_t)(lon + east_m / (111320.0 * std::cos(lat * (Math::PI / 180.0))));
	// TileFetcher.global_pixel.
	const double n = (double)(1 << zoom) * 256.0;
	const double px = ((double)lon_f + 180.0) / 360.0 * n;
	const double clamped = (double)lat_f < -85.0 ? -85.0 : ((double)lat_f > 85.0 ? 85.0 : (double)lat_f);
	const double lat_rad = clamped * (Math::PI / 180.0);
	const double py = (1.0 - std::asinh(std::tan(lat_rad)) / Math::PI) / 2.0 * n;
	return (Vector2((real_t)px, (real_t)py) - origin) / (real_t)mosaic;
}

Color PhotoSampler::roof_sample(double x, double z, double size_x, double size_z) const {
	Color acc(0, 0, 0);
	int n = 0;
	for (double dz : { -0.25, 0.0, 0.25 }) {
		for (double dx : { -0.25, 0.0, 0.25 }) {
			const Vector2 uv = mosaic_uv(lat, lon, zoom, origin, mosaic, x + dx * size_x, z + dz * size_z);
			const int px = std::clamp((int)((double)uv.x * (double)width), 0, width - 1);
			const int py = std::clamp((int)((double)uv.y * (double)height), 0, height - 1);
			acc += image->get_pixel(px, py);
			n += 1;
		}
	}
	return acc / (real_t)(double)std::max(n, 1);
}

Color PhotoSampler::photo(double x, double z) const {
	if (width <= 0 || height <= 0) return Color(0, 0, 0, 0);
	const Vector2 uv = mosaic_uv(lat, lon, zoom, origin, mosaic, x, z);
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x >= 1.0 || uv.y >= 1.0) return Color(0, 0, 0, 0);
	const int ix = (int)((double)uv.x * (double)width), iy = (int)((double)uv.y * (double)height);
	const Color c = image->get_pixel(ix, iy).srgb_to_linear();
	return Color(c.r, c.g, c.b, 1.0);
}

int PhotoSampler::green_around(double x, double z, double r, double green_min, double lum_min) const {
	const real_t rf = (real_t)r, nf = (real_t)-r;
	const Vector2 offsets[4] = { Vector2(rf, 0), Vector2(nf, 0), Vector2(0, rf), Vector2(0, nf) };
	int green = 0;
	for (const Vector2 &o : offsets) {
		const Color c = photo(x + (double)o.x, z + (double)o.y);
		if (c.a <= 0.0) continue;
		const double r_ = c.r, g = c.g, b = c.b;
		const double sum = r_ + g + b;
		const double index = (2.0 * g - r_ - b) / (sum > 0.001 ? sum : 0.001);
		if (index >= green_min && r_ * 0.2126 + g * 0.7152 + b * 0.0722 >= lum_min) ++green;
	}
	return green;
}

void PhotoSampler::_bind_methods() {
	ClassDB::bind_method(D_METHOD("setup", "image", "lat", "lon", "zoom", "origin_px", "mosaic_px"), &PhotoSampler::setup);
	ClassDB::bind_method(D_METHOD("photo", "x", "z"), &PhotoSampler::photo);
	ClassDB::bind_method(D_METHOD("roof_sample", "x", "z", "size_x", "size_z"), &PhotoSampler::roof_sample);
	ClassDB::bind_method(D_METHOD("green_around", "x", "z", "r", "green_min", "lum_min"), &PhotoSampler::green_around);
}

} // namespace godot
