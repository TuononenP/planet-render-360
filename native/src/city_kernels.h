#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

// FarCityBuilder's street-block fabric in native code, rows of the
// settlement map across every core. Same masses, batches and float32
// rounding as the script, merged in its order.
class CityKernels : public Object {
	GDCLASS(CityKernels, Object)

protected:
	static void _bind_methods();

public:
	// FarCityBuilder._fabric: {groups: [[key, mat, v, n, uv, c, i], ...]
	// in first-add order, blocks, tris}. `mat` indexes the script's
	// distant facades then roofs.
	static Dictionary fabric(const Dictionary &city, const Dictionary &far, const Array &dem_rings);
	static Dictionary settlement_features(const Array &infos, int n, int half);
	static Dictionary settlement_finish(const Dictionary &features, const Dictionary &l0,
			const Dictionary &g0, int n);
};

} // namespace godot
