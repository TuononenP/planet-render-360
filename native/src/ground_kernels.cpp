#include "ground_kernels.h"

#include "parallel.h"
#include "segments.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

#include <algorithm>
#include <cmath>
#include <cstring>
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

namespace {

struct Box {
	double x0, z0, x1, z1;
};

Box box_of(const PackedVector2Array &pts) {
	Box b{ INFINITY, INFINITY, -INFINITY, -INFINITY };
	for (int64_t i = 0; i < pts.size(); i++) {
		b.x0 = Math::min(b.x0, (double)pts[i].x);
		b.z0 = Math::min(b.z0, (double)pts[i].y);
		b.x1 = Math::max(b.x1, (double)pts[i].x);
		b.z1 = Math::max(b.z1, (double)pts[i].y);
	}
	return b;
}

} // namespace

Array GroundKernels::underpass_hits(const Array &bridges, const Array &ways,
		const PackedInt32Array &b_layers, const PackedInt32Array &w_layers) {
	const int nb = (int)bridges.size();
	const int nw = (int)ways.size();
	std::vector<PackedVector2Array> bp((size_t)nb), wp((size_t)nw);
	std::vector<Box> bb((size_t)nb), wb((size_t)nw);
	for (int i = 0; i < nb; i++) {
		bp[i] = bridges[i];
		bb[i] = box_of(bp[i]);
	}
	for (int k = 0; k < nw; k++) {
		wp[k] = ways[k];
		wb[k] = box_of(wp[k]);
	}
	std::vector<std::vector<double>> hits((size_t)nb);
	parallel_for(nb, [&](int b) {
		const PackedVector2Array &bpts = bp[b];
		// A margin well past the intersection test's tolerance, so a box
		// miss is never a hit.
		const Box &q = bb[b];
		double b_arc = 0.0;
		std::vector<double> arc((size_t)bpts.size());
		for (int64_t i = 0; i + 1 < bpts.size(); i++) {
			arc[i] = b_arc;
			b_arc += (double)bpts[i].distance_to(bpts[i + 1]);
		}
		for (int k = 0; k < nw; k++) {
			if (w_layers[k] >= b_layers[b]) {
				continue;
			}
			const Box &w = wb[k];
			if (q.x1 + 1.0 < w.x0 || w.x1 + 1.0 < q.x0 || q.z1 + 1.0 < w.z0 || w.z1 + 1.0 < q.z0) {
				continue;
			}
			const PackedVector2Array &wpts = wp[k];
			for (int64_t i = 0; i + 1 < bpts.size(); i++) {
				double w_arc = 0.0;
				for (int64_t j = 0; j + 1 < wpts.size(); j++) {
					Vector2 p;
					if (segments_cross(bpts[i], bpts[i + 1], wpts[j], wpts[j + 1], p)) {
						std::vector<double> &h = hits[b];
						h.push_back((double)k);
						h.push_back(arc[i] + (double)bpts[i].distance_to(p));
						h.push_back(w_arc + (double)wpts[j].distance_to(p));
						h.push_back((double)p.x);
						h.push_back((double)p.y);
					}
					w_arc += (double)wpts[j].distance_to(wpts[j + 1]);
				}
			}
		}
	});
	Array out;
	out.resize(nb);
	for (int b = 0; b < nb; b++) {
		PackedFloat64Array a;
		a.resize((int64_t)hits[b].size());
		if (!hits[b].empty()) {
			std::memcpy(a.ptrw(), hits[b].data(), hits[b].size() * sizeof(double));
		}
		out[b] = a;
	}
	return out;
}

void GroundKernels::_bind_methods() {
	ClassDB::bind_static_method("GroundKernels", D_METHOD("fill_rings", "n", "extent", "fills"),
			&GroundKernels::fill_rings);
	ClassDB::bind_static_method("GroundKernels",
			D_METHOD("underpass_hits", "bridges", "ways", "b_layers", "w_layers"),
			&GroundKernels::underpass_hits);
}

} // namespace godot
