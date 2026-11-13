#include "snapshot_kernels.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/char_string.hpp>

#include <cstdint>
#include <cstdio>
#include <string>
#include <unordered_set>
#include <vector>

namespace godot {

namespace {

constexpr int VERSION = 1;
constexpr int64_t F_TAGS = 1, F_GEOM = 2, F_LATLON = 4, F_MEMBERS = 8, F_CENTER = 16;
constexpr int64_t M_GEOM = 1, M_LATLON = 2;

struct Decoder {
	const uint8_t *b;
	int64_t n;
	int64_t p = 0;
	bool bad = false;
	int64_t lat = 0;
	int64_t lon = 0;
	std::vector<std::string> strings;
	std::string out;

	int64_t varint() {
		uint64_t result = 0;
		int shift = 0;
		while (true) {
			if (p >= n || shift > 63) {
				bad = true;
				return 0;
			}
			uint8_t byte = b[p++];
			result |= (uint64_t)(byte & 0x7f) << shift;
			if (byte < 0x80) {
				return (int64_t)result;
			}
			shift += 7;
		}
	}

	int64_t svarint() {
		int64_t v = varint();
		return (int64_t)((uint64_t)v >> 1) ^ -(v & 1);
	}

	bool take(int64_t len, const uint8_t *&start) {
		if (len < 0 || p + len > n) {
			bad = true;
			return false;
		}
		start = b + p;
		p += len;
		return true;
	}

	void string() {
		int64_t i = varint();
		if (i < 0 || i >= (int64_t)strings.size()) {
			bad = true;
			out += "\"\"";
			return;
		}
		out += strings[i];
	}

	static void micro(std::string &s, int64_t v) {
		char buf[32];
		uint64_t a = v < 0 ? (uint64_t)0 - (uint64_t)v : (uint64_t)v;
		snprintf(buf, sizeof(buf), "%s%llu.%06llu", v < 0 ? "-" : "", (unsigned long long)(a / 1000000),
				(unsigned long long)(a % 1000000));
		s += buf;
	}

	void coord() {
		lat += svarint();
		lon += svarint();
		out += "\"lat\":";
		micro(out, lat);
		out += ",\"lon\":";
		micro(out, lon);
	}

	void points() {
		int64_t count = varint();
		int64_t nn = varint();
		if (bad || count > n || nn > count) {
			bad = true;
			return;
		}
		std::unordered_set<int64_t> nulls;
		for (int64_t i = 0; i < nn; i++) {
			nulls.insert(varint());
		}
		out += "[";
		for (int64_t i = 0; i < count && !bad; i++) {
			if (i > 0) {
				out += ",";
			}
			if (nulls.count(i)) {
				out += "null";
			} else {
				out += "{";
				coord();
				out += "}";
			}
		}
		out += "]";
	}

	void tags() {
		int64_t count = varint();
		if (bad || count > n) {
			bad = true;
			return;
		}
		out += ",\"tags\":{";
		for (int64_t i = 0; i < count && !bad; i++) {
			if (i > 0) {
				out += ",";
			}
			string();
			out += ":";
			string();
		}
		out += "}";
	}

	void members() {
		int64_t count = varint();
		if (bad || count > n) {
			bad = true;
			return;
		}
		out += ",\"members\":[";
		int64_t ref = 0;
		for (int64_t i = 0; i < count && !bad; i++) {
			out += i == 0 ? "{\"type\":" : ",{\"type\":";
			string();
			ref += svarint();
			out += ",\"ref\":" + std::to_string(ref) + ",\"role\":";
			string();
			int64_t flags = varint();
			if (flags & M_LATLON) {
				out += ",";
				coord();
			}
			if (flags & M_GEOM) {
				out += ",\"geometry\":";
				points();
			}
			out += "}";
		}
		out += "]";
	}
};

} // namespace

String SnapshotKernels::decode_osmb(const PackedByteArray &payload) {
	Decoder d;
	d.b = payload.ptr();
	d.n = payload.size();
	if (d.n < 5 || d.b[0] != 'P' || d.b[1] != 'R' || d.b[2] != 'O' || d.b[3] != 'B') {
		return String();
	}
	d.p = 4;
	if (d.varint() != VERSION) {
		return String();
	}
	const uint8_t *start = nullptr;
	int64_t len = d.varint();
	if (!d.take(len, start)) {
		return String();
	}
	// Same trimming and escaping as the script, through Godot's own String.
	String header = String::utf8((const char *)start, len).strip_edges();
	int64_t count = d.varint();
	if (d.bad || count < 0 || count > d.n) {
		return String();
	}
	d.strings.reserve(count);
	for (int64_t i = 0; i < count; i++) {
		len = d.varint();
		if (!d.take(len, start)) {
			return String();
		}
		String escaped = "\"" + String::utf8((const char *)start, len).json_escape() + "\"";
		CharString utf8 = escaped.utf8();
		d.strings.emplace_back(utf8.get_data(), utf8.length());
	}
	if (header.length() < 2 || !header.begins_with("{")) {
		return String();
	}
	d.out.reserve((size_t)d.n * 6);
	if (header == "{}") {
		d.out += "{\"elements\":[";
	} else {
		CharString h = header.substr(0, header.length() - 1).utf8();
		d.out.append(h.get_data(), h.length());
		d.out += ",\"elements\":[";
	}
	int64_t elements = d.varint();
	if (d.bad || elements > d.n) {
		return String();
	}
	int64_t id = 0;
	for (int64_t i = 0; i < elements; i++) {
		if (d.bad) {
			return String();
		}
		d.out += i == 0 ? "{\"type\":" : ",{\"type\":";
		d.string();
		id += d.svarint();
		d.out += ",\"id\":" + std::to_string(id);
		int64_t flags = d.varint();
		if (flags & F_TAGS) {
			d.tags();
		}
		if (flags & F_LATLON) {
			d.out += ",";
			d.coord();
		}
		if (flags & F_CENTER) {
			d.out += ",\"center\":{";
			d.coord();
			d.out += "}";
		}
		if (flags & F_GEOM) {
			d.out += ",\"geometry\":";
			d.points();
		}
		if (flags & F_MEMBERS) {
			d.members();
		}
		d.out += "}";
	}
	d.out += "]}";
	if (d.bad || d.p != d.n) {
		return String();
	}
	return String::utf8(d.out.data(), (int)d.out.size());
}

void SnapshotKernels::_bind_methods() {
	ClassDB::bind_static_method("SnapshotKernels", D_METHOD("decode_osmb", "payload"), &SnapshotKernels::decode_osmb);
}

} // namespace godot
