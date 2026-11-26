#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

namespace godot {

// Far-terrain hot loops in native code, across every core. Each kernel
// repeats its GDScript twin's arithmetic in the same order and rounds
// through float32 where the script goes through Vector2/Vector3, so the
// world is byte-identical with or without the library
// (tools/build_bench.gd checks it).
class FarKernels : public Object {
	GDCLASS(FarKernels, Object)

protected:
	static void _bind_methods();

public:
	// FarTerrainBuilder._ring_bands' vertex positions: loops of
	// 4 * segs vertices around the square rings at `radii`.
	static PackedVector3Array ring_positions(const PackedFloat64Array &radii, int segs,
			const Dictionary &params, const Array &dem_rings);
	// Its normals and colours over those positions: [normals, colors].
	// `water` holds the PolygonIndex objects of the OSM water.
	static Array ring_colors(const PackedVector3Array &pos, int loops, int per,
			const Dictionary &params, const Array &water);
	// FarTerrainBuilder._band_mesh's triangle indices (with optional outer skirt).
	static PackedInt32Array band_indices(int loops, int per, bool has_skirt);
	// FarTerrainBuilder._band_mesh's drape UV / UV2 arrays: [uvs, uv2s].
	static Array band_drape_uvs(const PackedVector3Array &verts, const Dictionary &params,
			const Dictionary &fine, const Dictionary &coarse);
	// TerrainBuilder._terrain_mesh's satellite-draped vertex grid + indices:
	// [verts, normals, colors, tangents, uvs, water_levels, indices].
	static Array terrain_grid_sat(int size, double step, const PackedFloat32Array &post_heights,
			const Dictionary &params, const Array &drapes, Object *shore_domains);
	// LandmarkImpostor.bake's 4 orthographic cardinal RGBA8 views (N, E, S, W).
	static Array rasterize_impostor_views(const Array &batches, const Vector3 &center,
			double y_top, double span_y, double wx, double wz, const Vector3 &key_dir, int size);
};

} // namespace godot
