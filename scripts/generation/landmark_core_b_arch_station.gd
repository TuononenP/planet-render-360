class_name LandmarkCoreBArchStation
extends RefCounted

## The `station` archetype: a railway station building drawn on its real
## outline (model frame: +X the long axis, +Z the forecourt side away from
## the tracks), `h` metres to its highest point. The body stands on the
## outline to the eaves with its storeys of windows, round-headed ground
## floor openings on the forecourt and a cornice; over its middle the
## booking hall rises with a glazed lunette and clock in its front and a
## barrel roof, or, with `tower`, a clock tower takes the full height
## beside a lower hall. A canopy shelters the entrance. The parts come from
## LandmarkStationKit; materials are the archetype's Walls, Roof, Trim,
## Windows plus Dial (lit clock face) and Steel.

const STOREY_M := 4.5

static func build(lm: LandmarkMesh, h: float, poly: PackedVector2Array, tower: bool) -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	var length := hi.x - lo.x
	var width := hi.y - lo.y
	# The hall: centred on the outline's middle, shrunk until it stands
	# inside the outline; none when the middle is open (a courtyard).
	var hall := _hall(poly, Vector2((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5),
		clampf(length * 0.32, 12.0, 46.0), width * 0.82)
	var has_hall := hall.size.x >= 10.0 and h >= 12.0
	var eave := h
	var hall_eave := h
	var tw := clampf(minf(length, width) * 0.22, 6.0, 12.0)
	var with_tower := tower and h >= 20.0 and has_hall
	if with_tower:
		eave = clampf(h * 0.4, 7.0, 24.0)
		hall_eave = clampf(h * 0.55, eave + 2.0, h - 4.0)
	elif has_hall:
		eave = clampf(h * 0.62, 6.0, h - 3.0)
		hall_eave = eave + (h - eave) * 0.4
	_body(lm, poly, eave)
	if not has_hall:
		return
	var hc := Vector3(hall.get_center().x, 0.0, hall.get_center().y)
	var hl := hall.size.x
	var hd := hall.size.y
	var rise := h - hall_eave if not with_tower else minf(hd * 0.3, (h - hall_eave) * 0.5)
	lm.box("Walls", hc + Vector3.UP * hall_eave * 0.5, Vector3(hl, hall_eave, hd))
	lm.box("Trim", hc + Vector3.UP * (hall_eave - 0.35), Vector3(hl + 0.8, 0.7, hd + 0.8))
	LandmarkFhHelsinkiCity._barrel(lm, "Roof", hc + Vector3(0, hall_eave, -hd * 0.5),
		hc + Vector3(0, hall_eave, hd * 0.5), hl * 0.5 + 0.3, rise)
	# The hall front: a great glazed lunette over the doors, the clock in
	# the arch head, and pilasters to the cornice.
	var front := hc + Vector3(0, 0, hd * 0.5)
	var aw := hl * 0.62
	var ah := minf(hall_eave * 0.82, aw * 1.15)
	LandmarkStationKit.arch_window(lm, "Trim", "Windows", front + Vector3(0, 0.6, 0.02), Vector3.BACK, aw, ah,
		maxi(int(aw / 2.5), 3), 0.7)
	LandmarkStationKit.lunette(lm, "Trim", "Windows", front + Vector3(0, hall_eave, 0.05), Vector3.BACK,
		hl, rise * 0.96, 12, 5)
	var clock_r := clampf(hl * 0.09, 1.0, 2.6)
	var clock_y := minf(0.6 + ah + clock_r * 1.6, hall_eave + rise * 0.45)
	LandmarkStationKit.clock(lm, "Dial", "Trim", front + Vector3(0, clock_y, 0.35), Vector3.BACK, clock_r)
	LandmarkFhParts.strips(lm, "Trim", front + Vector3(-hl * 0.5 + 0.6, 0, 0), front + Vector3(hl * 0.5 - 0.6, 0, 0),
		Vector3.BACK, 0.0, hall_eave, 2, 1.2, 0.5)
	LandmarkStationKit.lunette(lm, "Trim", "Windows", hc + Vector3(0, hall_eave, -hd * 0.5 - 0.05), Vector3.FORWARD,
		hl, rise * 0.96, 12, 5)
	LandmarkStationKit.canopy(lm, "Steel", "Steel", front + Vector3(-hl * 0.5, 0, 0.2), front + Vector3(hl * 0.5, 0, 0.2),
		Vector3.BACK, 4.0, minf(4.6, eave - 0.5), 4)
	if with_tower:
		var tx := hc.x + hl * 0.5 + tw * 0.5 + 0.5
		var tz := clampf(hc.z + hd * 0.5 - tw * 0.5, lo.y + tw * 0.5, hi.y - tw * 0.5)
		var cap_h := clampf(h * 0.18, 3.0, 14.0)
		LandmarkStationKit.clock_tower(lm, "Walls", "Trim", "Roof", "Dial", "Windows", Vector3(tx, 0, tz), tw,
			h - cap_h, "pavilion", cap_h)

## The outline as a walled block to `eave`: walls with their storeys of
## windows, round-headed openings on the forecourt's ground floor, the
## cornice, a parapet and the flat roof.
static func _body(lm: LandmarkMesh, poly: PackedVector2Array, eave: float) -> void:
	lm.poly_prism("Walls", poly, 0.0, eave)
	var rings := Geometry2D.offset_polygon(poly, 0.45)
	if not rings.is_empty():
		lm.poly_prism("Trim", rings[0] as PackedVector2Array, eave - 0.9, eave - 0.2)
		lm.poly_prism("Trim", rings[0] as PackedVector2Array, 0.0, 0.8)
	var inner := Geometry2D.offset_polygon(poly, -0.5)
	if not inner.is_empty():
		lm.poly_prism("Roof", inner[0] as PackedVector2Array, eave - 0.2, eave + 0.05)
	var rows := maxi(int((eave - 1.5) / STOREY_M), 1)
	# Outward normals from the winding, so a concave (L- or U-shaped)
	# outline keeps its windows on every wall.
	var wind := 1.0 if RingGeometry.signed_area(poly) > 0.0 else -1.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var run := a.distance_to(b)
		if run < 5.0:
			continue
		var d := (b - a) / run
		var out := Vector3(d.y, 0, -d.x) * wind
		var p0 := Vector3(a.x, 0, a.y) + out * 0.02
		var p1 := Vector3(b.x, 0, b.y) + out * 0.02
		var n := maxi(int(run / 4.2), 1)
		var forecourt := out.z > 0.7
		if forecourt and eave >= 7.0:
			LandmarkStationKit.arch_row(lm, "Trim", "Windows", p0, p1, out, 0.8, n, 2.4, minf(4.6, eave * 0.45), 1)
			LandmarkFhUtil.window_grid(lm, "Windows", p0, p1, out, 6.2, maxi(rows - 1, 0), STOREY_M, n, 1.6, 2.4)
		else:
			LandmarkFhUtil.window_grid(lm, "Windows", p0, p1, out, 1.4, rows, STOREY_M, n, 1.6, 2.4)

## The largest rectangle round `c` (up to `l` by `d`) whose corners and
## edge midpoints stand inside `poly`, shrinking by tenths; empty when none.
static func _hall(poly: PackedVector2Array, c: Vector2, l: float, d: float) -> Rect2:
	var k := 1.0
	while k > 0.35:
		var hl := l * k * 0.5
		var hd := d * k * 0.5
		var ok := true
		for p in [Vector2(-hl, -hd), Vector2(hl, -hd), Vector2(hl, hd), Vector2(-hl, hd), Vector2(0, -hd),
				Vector2(0, hd), Vector2(-hl, 0), Vector2(hl, 0)]:
			if not Geometry2D.is_point_in_polygon(c + (p as Vector2) * 0.97, poly):
				ok = false
				break
		if ok:
			return Rect2(c - Vector2(hl, hd), Vector2(hl, hd) * 2.0)
		k -= 0.1
	return Rect2()
