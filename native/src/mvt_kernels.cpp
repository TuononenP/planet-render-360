#include "mvt_kernels.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <utility>
#include <vector>

namespace godot {

namespace {

constexpr int WIRE_VARINT = 0;
constexpr int WIRE_64 = 1;
constexpr int WIRE_LEN = 2;
constexpr int WIRE_32 = 5;

enum { UNKNOWN, POINT, LINE, POLYGON };

// GDScript ints wrap on overflow; a hostile length must not be UB here.
inline int64_t wadd(int64_t a, int64_t b) {
	return (int64_t)((uint64_t)a + (uint64_t)b);
}

inline int64_t zigzag(int64_t n) {
	return (n >> 1) ^ -(n & 1);
}

struct RawFeature {
	int64_t type = UNKNOWN;
	std::vector<int32_t> tags;
	std::vector<int32_t> geometry;
};

// MvtReader's cursor. Past the end varint() returns 0 and moves p past the
// end, so every `while (p < end)` loop terminates on a truncated buffer.
struct Reader {
	const uint8_t *b;
	int64_t n;
	int64_t p = 0;

	int64_t varint() {
		if (p < 0 || p >= n) {
			p = n + 1;
			return 0;
		}
		uint64_t result = 0;
		int shift = 0;
		while (p < n) {
			uint8_t byte = b[p];
			p++;
			if (shift < 64) {
				result |= (uint64_t)(byte & 0x7f) << shift;
			}
			if (byte < 0x80) {
				break;
			}
			shift += 7;
		}
		return (int64_t)result;
	}

	// A corrupt length (negative after a 10-byte varint) ends the read.
	int64_t len() {
		int64_t v = varint();
		if (v < 0) {
			p = n + 1;
			return 0;
		}
		return v;
	}

	void skip(int wire) {
		switch (wire) {
			case WIRE_VARINT:
				varint();
				break;
			case WIRE_64:
				p = wadd(p, 8);
				break;
			case WIRE_LEN: {
				// A separate statement: len() moves p, and C++ leaves the
				// order of `wadd(p, len())`'s operands open.
				int64_t length = len();
				p = wadd(p, length);
				break;
			}
			case WIRE_32:
				p = wadd(p, 4);
				break;
			default:
				p = n; // unknown wire type: stop rather than misread
		}
	}

	// `length` bytes from p as UTF-8, clamped to the buffer; p moves the
	// full length, as the script's _string does.
	String string(int64_t length) {
		int64_t end = std::min(wadd(p, length), n);
		String s;
		if (p >= 0 && p < end) {
			s = String::utf8((const char *)b + p, end - p);
		}
		p = wadd(p, length);
		return s;
	}

	RawFeature feature(int64_t end) {
		RawFeature f;
		while (p < end) {
			int64_t key = varint();
			int64_t field = key >> 3;
			int wire = (int)(key & 7);
			if (field == 3 && wire == WIRE_VARINT) {
				f.type = varint();
			} else if ((field == 2 || field == 4) && wire == WIRE_LEN) {
				int64_t packed_len = len(); // read first: it advances p
				int64_t packed_end = std::min(wadd(p, packed_len), end);
				std::vector<int32_t> arr;
				while (p < packed_end) {
					arr.push_back((int32_t)varint()); // PackedInt32Array.append truncates
				}
				if (field == 2) {
					f.tags = std::move(arr);
				} else {
					f.geometry = std::move(arr);
				}
			} else {
				skip(wire);
			}
		}
		return f;
	}

	Variant value(int64_t end) {
		Variant v;
		while (p < end) {
			int64_t key = varint();
			int64_t field = key >> 3;
			int wire = (int)(key & 7);
			switch (field) {
				case 1:
					v = string(len());
					break;
				case 2:
					if (p >= 0 && p + 4 <= n) {
						float f;
						std::memcpy(&f, b + p, 4);
						v = (double)f;
					}
					p += 4;
					break;
				case 3:
					if (p >= 0 && p + 8 <= n) {
						double d;
						std::memcpy(&d, b + p, 8);
						v = d;
					}
					p += 8;
					break;
				case 4:
				case 5:
					v = varint();
					break;
				case 6:
					v = zigzag(varint());
					break;
				case 7:
					v = varint() != 0;
					break;
				default:
					skip(wire);
			}
		}
		return v;
	}
};

// Surveyor's formula as the MVT spec defines it (tile space, y down), in
// double from the float32 points, as the script computes it.
double ring_area(const PackedVector2Array &ring) {
	double a = 0.0;
	const int64_t count = ring.size();
	for (int64_t k = 0; k < count; k++) {
		Vector2 p = ring[k];
		Vector2 q = ring[(k + 1) % count];
		a += (double)p.x * (double)q.y - (double)q.x * (double)p.y;
	}
	return a / 2.0;
}

// MvtReader.decode_geometry: the command stream as geometry (POINT: one
// PackedVector2Array; LINE: one per line; POLYGON: [outer, hole...] per
// polygon).
Array decode_geometry(int64_t type, const std::vector<int32_t> &cmds) {
	std::vector<PackedVector2Array> parts;
	PackedVector2Array current;
	int64_t cx = 0;
	int64_t cy = 0;
	size_t i = 0;
	const size_t count_cmds = cmds.size();
	while (i < count_cmds) {
		int64_t cmd = cmds[i] & 7;
		int64_t count = (int64_t)(cmds[i] >> 3);
		i++;
		if (cmd == 7) { // ClosePath
			if (current.size() >= 3) {
				parts.push_back(current);
			}
			current = PackedVector2Array();
			continue;
		}
		for (int64_t k = 0; k < count; k++) {
			if (i + 1 >= count_cmds) {
				break;
			}
			cx += zigzag(cmds[i]);
			cy += zigzag(cmds[i + 1]);
			i += 2;
			if (cmd == 1 && type != POINT && current.size() > 0) {
				if (type == LINE && current.size() >= 2) {
					parts.push_back(current);
				}
				current = PackedVector2Array();
			}
			current.push_back(Vector2((real_t)cx, (real_t)cy));
		}
	}
	Array out;
	if (type == POINT) {
		if (current.size() > 0) {
			out.push_back(current);
		}
		return out;
	}
	if (type == LINE) {
		if (current.size() >= 2) {
			parts.push_back(current);
		}
		for (const PackedVector2Array &line : parts) {
			out.push_back(line);
		}
		return out;
	}
	if (type != POLYGON) {
		return out;
	}
	// Exterior rings have a positive area; negative rings are holes of the
	// polygon before them.
	std::vector<Array> polygons;
	for (const PackedVector2Array &ring : parts) {
		double area = ring_area(ring);
		if (area > 0.0 || polygons.empty()) {
			Array poly;
			poly.push_back(ring);
			polygons.push_back(poly);
		} else if (area < 0.0) {
			polygons.back().push_back(ring);
		}
	}
	for (const Array &poly : polygons) {
		out.push_back(poly);
	}
	return out;
}

// A layer, or an empty Dictionary when it is not wanted.
Dictionary read_layer(Reader &r, int64_t end, const Dictionary &wanted) {
	String name;
	int64_t extent = 4096;
	std::vector<String> keys;
	std::vector<std::pair<int64_t, int64_t>> values; // byte ranges, decoded on first use
	std::vector<RawFeature> raw;
	const int64_t start = r.p;
	// Pass 1: the name decides whether the rest is worth decoding.
	while (r.p < end) {
		int64_t key = r.varint();
		if ((key >> 3) == 1 && (key & 7) == WIRE_LEN) {
			name = r.string(r.len());
			break;
		}
		r.skip((int)(key & 7));
	}
	if (!wanted.has(name)) {
		return Dictionary();
	}
	r.p = start;
	while (r.p < end) {
		int64_t key = r.varint();
		int64_t field = key >> 3;
		int wire = (int)(key & 7);
		if (wire != WIRE_LEN) {
			if (field == 5 && wire == WIRE_VARINT) {
				extent = r.varint();
			} else {
				r.skip(wire);
			}
			continue;
		}
		int64_t length = r.len();
		int64_t sub_end = std::min(wadd(r.p, length), end);
		switch (field) {
			case 2:
				raw.push_back(r.feature(sub_end));
				break;
			case 3:
				keys.push_back(r.string(length));
				break;
			case 4:
				values.emplace_back((int32_t)r.p, (int32_t)sub_end); // Vector2i in the script
				break;
			default:
				break;
		}
		r.p = sub_end;
	}
	const Array keep = wanted[name];
	// Only keys the style reads; their values decode once, on first use.
	std::vector<bool> kept_key;
	kept_key.reserve(keys.size());
	for (const String &k : keys) {
		kept_key.push_back(keep.has(k));
	}
	std::vector<Variant> decoded(values.size());
	std::vector<bool> is_decoded(values.size(), false);
	Array features;
	for (const RawFeature &f : raw) {
		Dictionary tags;
		const std::vector<int32_t> &t = f.tags;
		for (size_t i = 0; i + 1 < t.size(); i += 2) {
			int64_t ki = t[i];
			int64_t vi = t[i + 1];
			if (ki < 0 || ki >= (int64_t)keys.size() || vi < 0 || vi >= (int64_t)values.size() || !kept_key[ki]) {
				continue;
			}
			if (!is_decoded[vi]) {
				r.p = values[vi].first;
				decoded[vi] = r.value(values[vi].second);
				is_decoded[vi] = true;
			}
			tags[keys[ki]] = decoded[vi];
		}
		Array geom = decode_geometry(f.type, f.geometry);
		if (geom.is_empty()) {
			continue;
		}
		Dictionary feature;
		feature["type"] = f.type;
		feature["tags"] = tags;
		feature["geom"] = geom;
		features.push_back(feature);
	}
	Dictionary layer;
	layer["name"] = name;
	layer["extent"] = extent;
	layer["features"] = features;
	return layer;
}

} // namespace

Dictionary MvtKernels::read(const PackedByteArray &bytes, const Dictionary &wanted) {
	Reader r{ bytes.ptr(), bytes.size() };
	Dictionary out;
	while (r.p < r.n) {
		int64_t key = r.varint();
		int64_t field = key >> 3;
		int wire = (int)(key & 7);
		if (field == 3 && wire == WIRE_LEN) {
			int64_t length = r.len();
			int64_t end = std::min(wadd(r.p, length), r.n);
			Dictionary layer = read_layer(r, end, wanted);
			r.p = end;
			if (!layer.is_empty()) {
				out[layer["name"]] = layer;
			}
		} else {
			r.skip(wire);
		}
	}
	return out;
}

void MvtKernels::_bind_methods() {
	ClassDB::bind_static_method("MvtKernels", D_METHOD("read", "bytes", "wanted"), &MvtKernels::read);
}

} // namespace godot
