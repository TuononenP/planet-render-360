#include "earcut_kernels.h"

#include <godot_cpp/core/class_db.hpp>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <deque>
#include <limits>
#include <utility>
#include <vector>

namespace godot {

namespace {

// A port of mapbox/earcut (ISC licence, Copyright (c) 2016 Mapbox): the
// polygon is a circular doubly linked list, ears are cut one by one, holes
// are bridged into the outline first.
struct Node {
	int32_t i;
	double x;
	double y;
	Node *prev = nullptr;
	Node *next = nullptr;
	int32_t z = 0;
	Node *prev_z = nullptr;
	Node *next_z = nullptr;
	bool steiner = false;
	Node(int32_t index, double px, double py) :
			i(index), x(px), y(py) {}
};

class Earcut {
public:
	std::vector<int32_t> indices;

	void run(const std::vector<double> &data, const std::vector<size_t> &hole_starts, size_t outer_len);

private:
	std::deque<Node> nodes;
	bool hashing = false;
	double min_x = 0.0;
	double min_y = 0.0;
	double inv_size = 0.0;

	template <typename... Args>
	Node *make(Args &&...args) {
		nodes.emplace_back(std::forward<Args>(args)...);
		return &nodes.back();
	}

	static double area(const Node *p, const Node *q, const Node *r) {
		return (q->y - p->y) * (r->x - q->x) - (q->x - p->x) * (r->y - q->y);
	}
	static bool equals(const Node *a, const Node *b) { return a->x == b->x && a->y == b->y; }
	static int sign(double v) { return v > 0 ? 1 : (v < 0 ? -1 : 0); }

	static bool on_segment(const Node *p, const Node *q, const Node *r) {
		return q->x <= std::max(p->x, r->x) && q->x >= std::min(p->x, r->x) &&
				q->y <= std::max(p->y, r->y) && q->y >= std::min(p->y, r->y);
	}

	static bool intersects(const Node *p1, const Node *q1, const Node *p2, const Node *q2) {
		int o1 = sign(area(p1, q1, p2));
		int o2 = sign(area(p1, q1, q2));
		int o3 = sign(area(p2, q2, p1));
		int o4 = sign(area(p2, q2, q1));
		if (o1 != o2 && o3 != o4) {
			return true;
		}
		if (o1 == 0 && on_segment(p1, p2, q1)) {
			return true;
		}
		if (o2 == 0 && on_segment(p1, q2, q1)) {
			return true;
		}
		if (o3 == 0 && on_segment(p2, p1, q2)) {
			return true;
		}
		if (o4 == 0 && on_segment(p2, q1, q2)) {
			return true;
		}
		return false;
	}

	static bool point_in_triangle(double ax, double ay, double bx, double by, double cx, double cy, double px, double py) {
		return (cx - px) * (ay - py) >= (ax - px) * (cy - py) &&
				(ax - px) * (by - py) >= (bx - px) * (ay - py) &&
				(bx - px) * (cy - py) >= (cx - px) * (by - py);
	}
	static bool point_in_triangle_except_first(double ax, double ay, double bx, double by, double cx, double cy, double px, double py) {
		return !(ax == px && ay == py) && point_in_triangle(ax, ay, bx, by, cx, cy, px, py);
	}

	static double signed_area(const std::vector<double> &data, size_t start, size_t end) {
		double sum = 0.0;
		size_t j = end - 1;
		for (size_t i = start; i < end; i++) {
			sum += (data[2 * j] - data[2 * i]) * (data[2 * i + 1] + data[2 * j + 1]);
			j = i;
		}
		return sum;
	}

	Node *insert_node(int32_t i, double x, double y, Node *last) {
		Node *p = make(i, x, y);
		if (!last) {
			p->prev = p;
			p->next = p;
		} else {
			p->next = last->next;
			p->prev = last;
			last->next->prev = p;
			last->next = p;
		}
		return p;
	}

	static void remove_node(Node *p) {
		p->next->prev = p->prev;
		p->prev->next = p->next;
		if (p->prev_z) {
			p->prev_z->next_z = p->next_z;
		}
		if (p->next_z) {
			p->next_z->prev_z = p->prev_z;
		}
	}

	Node *linked_list(const std::vector<double> &data, size_t start, size_t end, bool clockwise) {
		Node *last = nullptr;
		if (clockwise == (signed_area(data, start, end) > 0)) {
			for (size_t i = start; i < end; i++) {
				last = insert_node((int32_t)i, data[2 * i], data[2 * i + 1], last);
			}
		} else {
			for (size_t i = end; i-- > start;) {
				last = insert_node((int32_t)i, data[2 * i], data[2 * i + 1], last);
			}
		}
		if (last && equals(last, last->next)) {
			remove_node(last);
			last = last->next;
		}
		return last;
	}

	// Drops collinear and duplicate points.
	Node *filter_points(Node *start, Node *end = nullptr) {
		if (!start) {
			return start;
		}
		if (!end) {
			end = start;
		}
		Node *p = start;
		bool again;
		do {
			again = false;
			if (!p->steiner && (equals(p, p->next) || area(p->prev, p, p->next) == 0)) {
				remove_node(p);
				p = end = p->prev;
				if (p == p->next) {
					break;
				}
				again = true;
			} else {
				p = p->next;
			}
		} while (again || p != end);
		return end;
	}

	int32_t z_order(double px, double py) const {
		int32_t x = (int32_t)((px - min_x) * inv_size);
		int32_t y = (int32_t)((py - min_y) * inv_size);
		x = (x | (x << 8)) & 0x00FF00FF;
		x = (x | (x << 4)) & 0x0F0F0F0F;
		x = (x | (x << 2)) & 0x33333333;
		x = (x | (x << 1)) & 0x55555555;
		y = (y | (y << 8)) & 0x00FF00FF;
		y = (y | (y << 4)) & 0x0F0F0F0F;
		y = (y | (y << 2)) & 0x33333333;
		y = (y | (y << 1)) & 0x55555555;
		return x | (y << 1);
	}

	// Simon Tatham's linked list merge sort, by z-order.
	Node *sort_linked(Node *list) {
		int in_size = 1;
		int num_merges;
		do {
			Node *p = list;
			list = nullptr;
			Node *tail = nullptr;
			num_merges = 0;
			while (p) {
				num_merges++;
				Node *q = p;
				int p_size = 0;
				for (int i = 0; i < in_size; i++) {
					p_size++;
					q = q->next_z;
					if (!q) {
						break;
					}
				}
				int q_size = in_size;
				while (p_size > 0 || (q_size > 0 && q)) {
					Node *e;
					if (p_size != 0 && (q_size == 0 || !q || p->z <= q->z)) {
						e = p;
						p = p->next_z;
						p_size--;
					} else {
						e = q;
						q = q->next_z;
						q_size--;
					}
					if (tail) {
						tail->next_z = e;
					} else {
						list = e;
					}
					e->prev_z = tail;
					tail = e;
				}
				p = q;
			}
			tail->next_z = nullptr;
			in_size *= 2;
		} while (num_merges > 1);
		return list;
	}

	void index_curve(Node *start) {
		Node *p = start;
		do {
			if (p->z == 0) {
				p->z = z_order(p->x, p->y);
			}
			p->prev_z = p->prev;
			p->next_z = p->next;
			p = p->next;
		} while (p != start);
		p->prev_z->next_z = nullptr;
		p->prev_z = nullptr;
		sort_linked(p);
	}

	bool is_ear(Node *ear) const {
		const Node *a = ear->prev;
		const Node *b = ear;
		const Node *c = ear->next;
		if (area(a, b, c) >= 0) {
			return false; // reflex, can't be an ear
		}
		double x0 = std::min({ a->x, b->x, c->x });
		double y0 = std::min({ a->y, b->y, c->y });
		double x1 = std::max({ a->x, b->x, c->x });
		double y1 = std::max({ a->y, b->y, c->y });
		const Node *p = c->next;
		while (p != a) {
			if (p->x >= x0 && p->x <= x1 && p->y >= y0 && p->y <= y1 &&
					point_in_triangle_except_first(a->x, a->y, b->x, b->y, c->x, c->y, p->x, p->y) &&
					area(p->prev, p, p->next) >= 0) {
				return false;
			}
			p = p->next;
		}
		return true;
	}

	bool inside_ear(const Node *a, const Node *b, const Node *c, const Node *p,
			double x0, double y0, double x1, double y1) const {
		return p->x >= x0 && p->x <= x1 && p->y >= y0 && p->y <= y1 && p != a && p != c &&
				point_in_triangle_except_first(a->x, a->y, b->x, b->y, c->x, c->y, p->x, p->y) &&
				area(p->prev, p, p->next) >= 0;
	}

	bool is_ear_hashed(Node *ear) const {
		const Node *a = ear->prev;
		const Node *b = ear;
		const Node *c = ear->next;
		if (area(a, b, c) >= 0) {
			return false; // reflex
		}
		double x0 = std::min({ a->x, b->x, c->x });
		double y0 = std::min({ a->y, b->y, c->y });
		double x1 = std::max({ a->x, b->x, c->x });
		double y1 = std::max({ a->y, b->y, c->y });
		int32_t min_z = z_order(x0, y0);
		int32_t max_z = z_order(x1, y1);
		const Node *p = ear->prev_z;
		const Node *n = ear->next_z;
		while (p && p->z >= min_z && n && n->z <= max_z) {
			if (inside_ear(a, b, c, p, x0, y0, x1, y1)) {
				return false;
			}
			p = p->prev_z;
			if (inside_ear(a, b, c, n, x0, y0, x1, y1)) {
				return false;
			}
			n = n->next_z;
		}
		while (p && p->z >= min_z) {
			if (inside_ear(a, b, c, p, x0, y0, x1, y1)) {
				return false;
			}
			p = p->prev_z;
		}
		while (n && n->z <= max_z) {
			if (inside_ear(a, b, c, n, x0, y0, x1, y1)) {
				return false;
			}
			n = n->next_z;
		}
		return true;
	}

	static bool locally_inside(const Node *a, const Node *b) {
		return area(a->prev, a, a->next) < 0 ?
				area(a, b, a->next) >= 0 && area(a, a->prev, b) >= 0 :
				area(a, b, a->prev) < 0 || area(a, a->next, b) < 0;
	}

	static bool middle_inside(const Node *a, const Node *b) {
		const Node *p = a;
		bool inside = false;
		double px = (a->x + b->x) / 2;
		double py = (a->y + b->y) / 2;
		do {
			if (((p->y > py) != (p->next->y > py)) && p->next->y != p->y &&
					(px < (p->next->x - p->x) * (py - p->y) / (p->next->y - p->y) + p->x)) {
				inside = !inside;
			}
			p = p->next;
		} while (p != a);
		return inside;
	}

	static bool intersects_polygon(const Node *a, const Node *b) {
		const Node *p = a;
		do {
			if (p->i != a->i && p->next->i != a->i && p->i != b->i && p->next->i != b->i && intersects(p, p->next, a, b)) {
				return true;
			}
			p = p->next;
		} while (p != a);
		return false;
	}

	static bool is_valid_diagonal(const Node *a, const Node *b) {
		return a->next->i != b->i && a->prev->i != b->i && !intersects_polygon(a, b) &&
				((locally_inside(a, b) && locally_inside(b, a) && middle_inside(a, b) &&
						 (area(a->prev, a, b->prev) != 0 || area(a, b->prev, b) != 0)) ||
						(equals(a, b) && area(a->prev, a, a->next) > 0 && area(b->prev, b, b->next) > 0));
	}

	// Links two vertices with a bridge: one ring splits in two, or an outer
	// ring and a hole merge into one.
	Node *split_polygon(Node *a, Node *b) {
		Node *a2 = make(a->i, a->x, a->y);
		Node *b2 = make(b->i, b->x, b->y);
		Node *an = a->next;
		Node *bp = b->prev;
		a->next = b;
		b->prev = a;
		a2->next = an;
		an->prev = a2;
		b2->next = a2;
		a2->prev = b2;
		bp->next = b2;
		b2->prev = bp;
		return b2;
	}

	Node *cure_local_intersections(Node *start) {
		Node *p = start;
		do {
			Node *a = p->prev;
			Node *b = p->next->next;
			if (!equals(a, b) && intersects(a, p, p->next, b) && locally_inside(a, b) && locally_inside(b, a)) {
				indices.push_back(a->i);
				indices.push_back(p->i);
				indices.push_back(b->i);
				remove_node(p);
				remove_node(p->next);
				p = start = b;
			}
			p = p->next;
		} while (p != start);
		return filter_points(p);
	}

	void split_earcut(Node *start) {
		Node *a = start;
		do {
			Node *b = a->next->next;
			while (b != a->prev) {
				if (a->i != b->i && is_valid_diagonal(a, b)) {
					Node *c = split_polygon(a, b);
					a = filter_points(a, a->next);
					c = filter_points(c, c->next);
					earcut_linked(a, 0);
					earcut_linked(c, 0);
					return;
				}
				b = b->next;
			}
			a = a->next;
		} while (a != start);
	}

	void earcut_linked(Node *ear, int pass) {
		if (!ear) {
			return;
		}
		if (!pass && hashing) {
			index_curve(ear);
		}
		Node *stop = ear;
		while (ear->prev != ear->next) {
			Node *prev = ear->prev;
			Node *next = ear->next;
			if (hashing ? is_ear_hashed(ear) : is_ear(ear)) {
				indices.push_back(prev->i);
				indices.push_back(ear->i);
				indices.push_back(next->i);
				remove_node(ear);
				// Skipping the next vertex leaves fewer sliver triangles.
				ear = next->next;
				stop = next->next;
				continue;
			}
			ear = next;
			if (ear == stop) {
				if (!pass) {
					earcut_linked(filter_points(ear), 1);
				} else if (pass == 1) {
					ear = cure_local_intersections(filter_points(ear));
					earcut_linked(ear, 2);
				} else if (pass == 2) {
					split_earcut(ear);
				}
				break;
			}
		}
	}

	static Node *leftmost(Node *start) {
		Node *p = start;
		Node *best = start;
		do {
			if (p->x < best->x || (p->x == best->x && p->y < best->y)) {
				best = p;
			}
			p = p->next;
		} while (p != start);
		return best;
	}

	static bool sector_contains_sector(const Node *m, const Node *p) {
		return area(m->prev, m, p->prev) < 0 && area(p->next, m, m->next) < 0;
	}

	// David Eberly's algorithm for a bridge between a hole and the outline.
	Node *find_hole_bridge(Node *hole, Node *outer) {
		Node *p = outer;
		double hx = hole->x;
		double hy = hole->y;
		double qx = -std::numeric_limits<double>::infinity();
		Node *m = nullptr;
		do {
			if (hy <= p->y && hy >= p->next->y && p->next->y != p->y) {
				double x = p->x + (hy - p->y) * (p->next->x - p->x) / (p->next->y - p->y);
				if (x <= hx && x > qx) {
					qx = x;
					m = p->x < p->next->x ? p : p->next;
					if (x == hx) {
						return m; // the hole touches an outline segment
					}
				}
			}
			p = p->next;
		} while (p != outer);
		if (!m) {
			return nullptr;
		}
		const Node *stop = m;
		double mx = m->x;
		double my = m->y;
		double tan_min = std::numeric_limits<double>::infinity();
		p = m;
		do {
			if (hx >= p->x && p->x >= mx && hx != p->x &&
					point_in_triangle(hy < my ? hx : qx, hy, mx, my, hy < my ? qx : hx, hy, p->x, p->y)) {
				double t = std::fabs(hy - p->y) / (hx - p->x);
				if (locally_inside(p, hole) &&
						(t < tan_min || (t == tan_min && (p->x > m->x || (p->x == m->x && sector_contains_sector(m, p)))))) {
					m = p;
					tan_min = t;
				}
			}
			p = p->next;
		} while (p != stop);
		return m;
	}

	Node *eliminate_hole(Node *hole, Node *outer) {
		Node *bridge = find_hole_bridge(hole, outer);
		if (!bridge) {
			return outer;
		}
		Node *bridge_reverse = split_polygon(bridge, hole);
		filter_points(bridge_reverse, bridge_reverse->next);
		return filter_points(bridge, bridge->next);
	}

	Node *eliminate_holes(const std::vector<double> &data, const std::vector<size_t> &hole_starts, Node *outer) {
		std::vector<Node *> queue;
		for (size_t k = 0; k < hole_starts.size(); k++) {
			size_t start = hole_starts[k];
			size_t end = k + 1 < hole_starts.size() ? hole_starts[k + 1] : data.size() / 2;
			if (end - start < 1) {
				continue;
			}
			Node *list = linked_list(data, start, end, false);
			if (!list) {
				continue;
			}
			if (list == list->next) {
				list->steiner = true;
			}
			queue.push_back(leftmost(list));
		}
		std::stable_sort(queue.begin(), queue.end(), [](const Node *a, const Node *b) { return a->x < b->x; });
		for (Node *hole : queue) {
			outer = eliminate_hole(hole, outer);
		}
		return outer;
	}
};

void Earcut::run(const std::vector<double> &data, const std::vector<size_t> &hole_starts, size_t outer_len) {
	Node *outer = linked_list(data, 0, outer_len, true);
	if (!outer || outer->next == outer->prev) {
		return;
	}
	if (!hole_starts.empty()) {
		outer = eliminate_holes(data, hole_starts, outer);
	}
	// A shape that is not tiny gets z-order hashing, which needs the bounds.
	if (data.size() > 80 * 2) {
		min_x = data[0];
		min_y = data[1];
		double max_x = min_x;
		double max_y = min_y;
		for (size_t i = 1; i < outer_len; i++) {
			double x = data[2 * i];
			double y = data[2 * i + 1];
			min_x = std::min(min_x, x);
			min_y = std::min(min_y, y);
			max_x = std::max(max_x, x);
			max_y = std::max(max_y, y);
		}
		double size = std::max(max_x - min_x, max_y - min_y);
		inv_size = size != 0.0 ? 32767.0 / size : 0.0;
		hashing = inv_size != 0.0;
	}
	earcut_linked(outer, 0);
}

} // namespace

PackedInt32Array EarcutKernels::triangulate(const PackedVector2Array &outer, const Array &holes) {
	std::vector<double> data;
	std::vector<size_t> hole_starts;
	size_t total = (size_t)outer.size();
	for (int64_t h = 0; h < holes.size(); h++) {
		total += (size_t)PackedVector2Array(holes[h]).size();
	}
	data.reserve(total * 2);
	for (int64_t i = 0; i < outer.size(); i++) {
		data.push_back((double)outer[i].x);
		data.push_back((double)outer[i].y);
	}
	size_t count = (size_t)outer.size();
	for (int64_t h = 0; h < holes.size(); h++) {
		PackedVector2Array ring = holes[h];
		hole_starts.push_back(count);
		for (int64_t i = 0; i < ring.size(); i++) {
			data.push_back((double)ring[i].x);
			data.push_back((double)ring[i].y);
		}
		count += (size_t)ring.size();
	}
	PackedInt32Array out;
	if (outer.size() < 3) {
		return out;
	}
	Earcut earcut;
	earcut.run(data, hole_starts, (size_t)outer.size());
	out.resize((int64_t)earcut.indices.size());
	for (size_t i = 0; i < earcut.indices.size(); i++) {
		out[(int64_t)i] = earcut.indices[i];
	}
	return out;
}

void EarcutKernels::_bind_methods() {
	ClassDB::bind_static_method("EarcutKernels", D_METHOD("triangulate", "outer", "holes"), &EarcutKernels::triangulate);
}

} // namespace godot
