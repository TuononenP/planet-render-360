#include "ground_kernels.h"

#include "parallel.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

#include <algorithm>
#include <cmath>
#include <vector>

namespace godot {

namespace {

struct Fill {
	uint8_t byte = 0;
	std::vector<PackedVector2Array> rings;
	int j0 = 0, j1 = -1;
};

} // namespace

PackedByteArray GroundKernels::fill_rings(int n, double extent, const Array &fills_in) {
	PackedByteArray out;
	out.resize((int64_t)n * n);
	out.fill(0);
	const double half = extent * 0.5;
	const double ts = extent / (double)n;
	std::vector<Fill> fills;
	fills.reserve(fills_in.size());
	for (int64_t k = 0; k < fills_in.size(); k++) {
		Array f = fills_in[k];
		Fill fl;
		fl.byte = (uint8_t)(int)f[0];
		Array rings = f[1];
		double zmin = INFINITY;
		double zmax = -INFINITY;
		for (int64_t r = 0; r < rings.size(); r++) {
			PackedVector2Array ring = rings[r];
			for (int64_t q = 0; q < ring.size(); q++) {
				zmin = Math::min(zmin, (double)ring[q].y);
				zmax = Math::max(zmax, (double)ring[q].y);
			}
			fl.rings.push_back(ring);
		}
		if (zmin == INFINITY) {
			continue;
		}
		// GroundMaterial._fill_rings' row range.
		fl.j0 = Math::max((int)std::ceil((zmin + half) / ts - 0.5), 0);
		fl.j1 = Math::min((int)std::floor((zmax + half) / ts - 0.5), n - 1);
		fills.push_back(std::move(fl));
	}
	uint8_t *px = out.ptrw();
	// Rows are independent; each paints its fills in order (later on top).
	parallel_for(n, [&](int j) {
		std::vector<double> xs;
		const double wz = ((double)j + 0.5) * ts - half;
		uint8_t *row = px + (int64_t)j * n;
		for (const Fill &fl : fills) {
			if (j < fl.j0 || j > fl.j1) {
				continue;
			}
			xs.clear();
			for (const PackedVector2Array &ring : fl.rings) {
				const Vector2 *rp = ring.ptr();
				int64_t cnt = ring.size();
				for (int64_t q = 0; q < cnt; q++) {
					const double ax = rp[q].x, ay = rp[q].y;
					const double bx = rp[(q + 1) % cnt].x, by = rp[(q + 1) % cnt].y;
					if ((ay <= wz && by > wz) || (by <= wz && ay > wz)) {
						xs.push_back(ax + (wz - ay) / (by - ay) * (bx - ax));
					}
				}
			}
			if (xs.size() < 2) {
				continue;
			}
			std::sort(xs.begin(), xs.end());
			for (size_t k = 0; k + 1 < xs.size(); k += 2) {
				int i0 = Math::max((int)std::ceil((xs[k] + half) / ts - 0.5), 0);
				int i1 = Math::min((int)std::floor((xs[k + 1] + half) / ts - 0.5), n - 1);
				if (i1 >= i0) {
					std::fill(row + i0, row + i1 + 1, fl.byte);
				}
			}
		}
	});
	return out;
}

void GroundKernels::_bind_methods() {
	ClassDB::bind_static_method("GroundKernels", D_METHOD("fill_rings", "n", "extent", "fills"),
			&GroundKernels::fill_rings);
}

} // namespace godot
