class_name LandmarkAirfieldKit
extends RefCounted

## Shared builders of the hand-built airfields, in true metres in the
## airfield frame (+X along the longest runway, +Z to its right, Y up;
## GROUND is the seat the engine buries a landmark's base at). An airfield
## is drawn from its layout (CaLayout*, measured from OpenStreetMap by
## tools/capital_airports.py): the aprons, taxiways, runways and their
## paint come straight from it (`surfaces`), as do the hangars and sheds
## (`buildings`); the terminals, the tower, the jet bridges and the parked
## aircraft are authored per airport from what the real airport looks like.

const GROUND := 0.3
## The paved layers stand LIFT proud of the seat so the ground's small swells
## do not break through them; their skirts reach SKIRT_Y below it.
const LIFT := 0.4
const SKIRT_Y := -1.5
const APRON_TOP := GROUND + LIFT + 0.02
const TAXI_TOP := GROUND + LIFT + 0.05
const RUNWAY_TOP := GROUND + LIFT + 0.08
const LINE_LIFT := 0.03
const MIN_RING_M := 1.0
const GATE_GAP_M := 9.0

## Registers the ground, hangar and aircraft materials and the terminal
## set: Walls (`wall_set` tinted `wall`), Roof, Glass and Trim. A landmark
## keeps to 16 material surfaces, so taxiways share the runway asphalt and
## the aircraft share the glass.
static func mats(lm: LandmarkMesh, wall_set: String, wall: String, roof_set: String, roof: String,
		glass: String = "#4F6270", trim: String = "#D8D8D2") -> void:
	lm.use("Runway", LandmarkMaterials.pbr("asphalt", "#3E4043", 8.0, 0.88))
	lm.use("Apron", LandmarkMaterials.pbr("asphalt", "#85868A", 8.0, 0.9))
	lm.use("MarkW", LandmarkMaterials.paint("#F0F0EA", 0.8, 0.0))
	lm.use("MarkY", LandmarkMaterials.paint("#E6BE1E", 0.8, 0.0))
	lm.use("HangarWall", LandmarkMaterials.pbr("sheet_metal", "#B8BCBE", 4.0))
	lm.use("HangarRoof", LandmarkMaterials.pbr("sheet_metal", "#9EA3A6", 4.0))
	lm.use("Walls", LandmarkMaterials.pbr(wall_set, wall, 3.0))
	lm.use("Roof", LandmarkMaterials.pbr(roof_set, roof, 2.0))
	lm.use("Glass", LandmarkMaterials.glass(glass))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", trim, 3.0))
	LandmarkAircraft.mats(lm)

## The paved ground: aprons, taxiways (with their yellow centre lines),
## runways and their paint.
static func surfaces(lm: LandmarkMesh, data: Dictionary) -> void:
	for ring in data["aprons"]:
		slab(lm, "Apron", _poly(ring), APRON_TOP)
	for t in data["taxiways"]:
		var line := _poly(t["pts"])
		for p in Geometry2D.offset_polyline(line, float(t["w"]) * 0.5, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND):
			slab(lm, "Runway", p, TAXI_TOP)
	for t in data["taxiways"]:
		var line := _poly(t["pts"])
		for p in Geometry2D.offset_polyline(line, 0.15, Geometry2D.JOIN_ROUND, Geometry2D.END_BUTT):
			cap(lm, "MarkY", p, TAXI_TOP + LINE_LIFT)
	for r in data["runways"]:
		var a := Vector2(float(r["a"][0]), float(r["a"][1]))
		var b := Vector2(float(r["b"][0]), float(r["b"][1]))
		var d := (b - a).normalized()
		var hw := Vector2(-d.y, d.x) * float(r["w"]) * 0.5
		slab(lm, "Runway", PackedVector2Array([a - hw, b - hw, b + hw, a + hw]), RUNWAY_TOP)
		LandmarkRunwayMarks.paint(lm, r, RUNWAY_TOP)

## The measured hangars and sheds, extruded to their tagged or typical
## height under a flat roof; `data["buildings"]` indices in `skip` are left
## to the caller (the terminals). `heights` sets a building's height by its
## name where OpenStreetMap gives none.
static func buildings(lm: LandmarkMesh, data: Dictionary, skip: Array = [], heights: Dictionary = {}) -> void:
	var i := -1
	for b in data["buildings"]:
		i += 1
		if i in skip or str(b["kind"]) == "terminal":
			continue
		var ring := _poly(b["ring"])
		if ring.size() < 3:
			continue
		var big := absf(_area(ring)) > 1500.0
		var h := float(heights.get(str(b["name"]), b["h"]))
		if h <= 0.0:
			h = 11.0 if str(b["kind"]) == "hangar" else (9.0 if big else 6.0)
		lm.poly_prism("HangarWall", ring, 0.0, h, false)
		cap(lm, "HangarRoof", ring, h)

## Indices of the layout's terminal buildings.
static func terminals(data: Dictionary) -> Array:
	var out: Array = []
	var i := -1
	for b in data["buildings"]:
		i += 1
		if str(b["kind"]) == "terminal":
			out.append(i)
	return out

## A terminal block on the measured outline `ring`: walls to `h`, a glazing
## band on each of `storeys` storeys (`glaze_lo` / `glaze_hi` metres within a
## storey), a flat roof with an `overhang`-metre fascia when set and, when
## `sky_w` is set, glazed skylight strips that wide every `sky_pitch` metres
## along the long axis.
static func terminal(lm: LandmarkMesh, ring_pts: Array, h: float, storeys: int, glaze_lo: float = 1.0,
		glaze_hi: float = 2.5, overhang: float = 0.0, sky_w: float = 0.0, sky_pitch: float = 0.0) -> void:
	var ring := _poly(ring_pts)
	if ring.size() < 3:
		return
	lm.poly_prism("Walls", ring, 0.0, h, false)
	var pitch := h / float(maxi(storeys, 1))
	for k in storeys:
		band(lm, "Glass", ring, pitch * float(k) + glaze_lo, pitch * float(k) + minf(glaze_hi, pitch - 0.3))
	var top := h
	if overhang > 0.0:
		for p in Geometry2D.offset_polygon(ring, overhang, Geometry2D.JOIN_MITER):
			lm.poly_prism("Trim", p, h - 0.1, h + 0.45, true)
		top = h + 0.45
	else:
		cap(lm, "Roof", ring, h)
	if sky_w > 0.0:
		skylights(lm, ring, top + 0.05, sky_w, sky_pitch)

## Glazed strips `w` wide every `pitch` metres across `ring`, running along
## its longest edge, flat at height `y`.
static func skylights(lm: LandmarkMesh, ring: PackedVector2Array, y: float, w: float, pitch: float) -> void:
	var best := 0.0
	var ax := Vector2.RIGHT
	for i in ring.size():
		var e := ring[(i + 1) % ring.size()] - ring[i]
		if e.length() > best:
			best = e.length()
			ax = e.normalized()
	var cr := Vector2(-ax.y, ax.x)
	var a0 := INF
	var a1 := -INF
	var c0 := INF
	var c1 := -INF
	for v in ring:
		a0 = minf(a0, v.dot(ax))
		a1 = maxf(a1, v.dot(ax))
		c0 = minf(c0, v.dot(cr))
		c1 = maxf(c1, v.dot(cr))
	var c := c0 + pitch * 0.5
	while c < c1:
		var rect := PackedVector2Array([ax * a0 + cr * (c - w * 0.5), ax * a1 + cr * (c - w * 0.5),
			ax * a1 + cr * (c + w * 0.5), ax * a0 + cr * (c + w * 0.5)])
		for piece in Geometry2D.intersect_polygons(rect, ring):
			cap(lm, "Glass", piece, y)
		c += pitch

## Every terminal of the layout as a block: `rules` maps a building's name to
## [height, storeys] (or [height, storeys, overhang] or
## [height, storeys, overhang, skylight width, skylight pitch]); the others take their
## tagged height, else `_small` ([h, storeys]) under 400 m2, else `_big`.
static func terminal_set(lm: LandmarkMesh, data: Dictionary, rules: Dictionary) -> void:
	for i in terminals(data):
		var b: Dictionary = data["buildings"][i]
		var rule: Array = rules.get(str(b["name"]), [])
		if rule.is_empty():
			if float(b["h"]) > 0.0:
				rule = [float(b["h"]), maxi(int(float(b["h"]) / 4.5), 1)]
			elif absf(_area(_poly(b["ring"]))) < 400.0:
				rule = rules.get("_small", [4.0, 1])
			else:
				rule = rules.get("_big", [12.0, 3])
		terminal(lm, b["ring"], float(rule[0]), int(rule[1]), 1.0, 2.5, float(rule[2]) if rule.size() > 2 else 0.0,
			float(rule[3]) if rule.size() > 4 else 0.0, float(rule[4]) if rule.size() > 4 else 0.0)

## The layout's control towers (one per place), `default_h` high to the mast
## tip where OpenStreetMap gives no height: a tapering shaft, glazed cab and mast.
static func towers(lm: LandmarkMesh, data: Dictionary, default_h: float = 28.0, shaft_r: float = 3.2,
		cab_r: float = 4.6, cab_h: float = 3.4, mast_h: float = 5.0) -> void:
	var done: Array[Vector2] = []
	for t in data["towers"]:
		var p := Vector2(float(t["p"][0]), float(t["p"][1]))
		var dup := false
		for q: Vector2 in done:
			if q.distance_to(p) < 12.0:
				dup = true
		if dup:
			continue
		done.append(p)
		var h := float(t["h"]) if float(t["h"]) > 8.0 else default_h
		tower(lm, p, h - cab_h - mast_h, shaft_r, cab_r, cab_h, mast_h)

## A vertical band of `key` on every face of `ring`, `y0` to `y1`, standing
## a hair proud of the wall.
static func band(lm: LandmarkMesh, key: String, ring: PackedVector2Array, y0: float, y1: float) -> void:
	var wind := 1.0 if _area(ring) > 0.0 else -1.0
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		if p.distance_to(q) < 2.5:
			continue
		var e := q - p
		var n := Vector3(e.y, 0.0, -e.x).normalized() * wind
		var o := n * 0.05
		lm.quad(key, Vector3(p.x, y0, p.y) + o, Vector3(q.x, y0, q.y) + o, Vector3(q.x, y1, q.y) + o,
			Vector3(p.x, y1, p.y) + o, n)

## A control tower: a tapering concrete shaft, a flared glazed cab with a
## flat roof and an antenna mast. `h` is the top of the mast.
static func tower(lm: LandmarkMesh, at: Vector2, shaft_h: float, shaft_r: float, cab_r: float, cab_h: float,
		mast_h: float = 5.0) -> void:
	var base := Vector3(at.x, 0.0, at.y)
	lm.lathe("Trim", base, PackedVector2Array([Vector2(shaft_r * 1.35, 0.0), Vector2(shaft_r, shaft_h * 0.35),
		Vector2(shaft_r * 0.9, shaft_h)]), 12)
	var cab := base + Vector3.UP * shaft_h
	lm.lathe("Glass", cab, PackedVector2Array([Vector2(shaft_r * 0.9, 0.0), Vector2(cab_r, cab_h * 0.25),
		Vector2(cab_r, cab_h)]), 12)
	lm.lathe("Trim", cab + Vector3.UP * cab_h, PackedVector2Array([Vector2(cab_r * 1.15, 0.0), Vector2(cab_r * 1.15, 0.35),
		Vector2(cab_r * 0.4, 0.5), Vector2(0.15, mast_h)]), 12)

## A passenger boarding bridge from the terminal face `a` to the aircraft
## door `b` (both at the same height above the ground).
static func jet_bridge(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	lm.beam("Trim", a, b, 2.5, 2.5, Vector3.UP)
	lm.frustum("Trim", Vector3(b.x, 0.0, b.z), 0.5, 0.35, b.y - 1.3, 8)
	lm.box("Trim", Vector3(b.x, 0.45, b.z), Vector3(2.2, 0.9, 0.9), Basis(), 0.0)
	lm.lathe("Trim", a - Vector3.UP * 1.3, PackedVector2Array([Vector2(1.7, 0.0), Vector2(1.7, 2.6)]), 10)

## Parked aircraft on the layout's stand positions nearest `near` (grid spots
## inside the aprons when it has too few): `fleet` is [kind, tail hex] cycled
## over at most `limit` aircraft within `reach_m`. A mapped stand marks where
## the nose wheel stops, so an aircraft at a stand within 70 m of a terminal
## wall stands nose-in to it with its nose wheel on the stand, and one at a
## gate node inside a terminal stands outside the nearest wall; an aircraft
## never overlaps a building or another aircraft. With `bridges`, a boarding
## bridge joins the wall to its door.
static func park(lm: LandmarkMesh, data: Dictionary, fleet: Array, limit: int, near: Vector2 = Vector2.ZERO,
		reach_m: float = 500.0, bridges: bool = false) -> void:
	var rings: Array[PackedVector2Array] = []
	for i in terminals(data):
		rings.append(_poly(data["buildings"][i]["ring"]))
	var blocks: Array[PackedVector2Array] = []
	for b in data["buildings"]:
		var ring := _poly(b["ring"])
		if ring.size() >= 3:
			for g in Geometry2D.offset_polygon(ring, 3.0, Geometry2D.JOIN_MITER):
				blocks.append(g)
	var cands: Array = []
	for s in data["stands"]:
		var p := Vector2(float(s[0]), float(s[1]))
		if p.distance_to(near) <= reach_m:
			cands.append([p, true])
	if cands.size() < limit:
		for p in _apron_spots(data, near, reach_m, 46.0):
			cands.append([p, false])
	cands.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).distance_to(near) < (b[0] as Vector2).distance_to(near))
	var placed: Array[Vector2] = []
	var n := 0
	for c in cands:
		if n >= limit or fleet.is_empty():
			break
		var p: Vector2 = c[0]
		var spec: Array = fleet[n % fleet.size()]
		var kind := str(spec[0])
		var length := LandmarkAircraft.length_m(kind)
		var best := INF
		var wall := p + Vector2.RIGHT
		for ring in rings:
			for i in ring.size():
				var q := Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])
				if p.distance_to(q) < best:
					best = p.distance_to(q)
					wall = q
		var dir := (wall - p).normalized() if best < INF and best > 0.01 else Vector2.RIGHT
		var centre := p - dir * length * 0.35 if bool(c[1]) and best < 70.0 else p
		var at_gate := false
		for ring in rings:
			if Geometry2D.is_point_in_polygon(p, ring):
				at_gate = true
		if at_gate:
			# A gate node inside a terminal: the aircraft stands outside the
			# nearest wall, nose-in, its nose GATE_GAP_M from the wall.
			if best < 0.01:
				continue
			var out := (wall - p).normalized()
			dir = -out
			centre = wall + out * (GATE_GAP_M + length * 0.5)
		var clear := true
		for k in [-0.45, 0.0, 0.45]:
			var at := centre + dir * length * float(k)
			for g in blocks:
				if Geometry2D.is_point_in_polygon(at, g):
					clear = false
					break
		for o in placed:
			if o.distance_to(centre) < 36.0:
				clear = false
		if not clear:
			continue
		placed.append(centre)
		LandmarkAircraft.place(lm, kind, str(spec[1]), centre, atan2(dir.y, dir.x))
		if bridges:
			_bridge(lm, rings, kind, centre, dir)
		n += 1

## A boarding bridge from the nearest terminal face to the left-hand door of
## the aircraft of `kind` parked at `p` with its nose along `dir`, when the
## door stands 6 to 40 m from a terminal wall.
static func _bridge(lm: LandmarkMesh, rings: Array[PackedVector2Array], kind: String, p: Vector2, dir: Vector2) -> void:
	var spec: Dictionary = LandmarkAircraft.SPECS[kind]
	var length := float(spec["L"])
	var r := float(spec["D"]) * 0.5
	if length < 25.0:
		return
	var left := Vector2(dir.y, -dir.x)
	var door := p + dir * (length * 0.5 - length * 0.16) + left * r
	var best := INF
	var at := Vector2.ZERO
	for ring in rings:
		for i in ring.size():
			var q := Geometry2D.get_closest_point_to_segment(door, ring[i], ring[(i + 1) % ring.size()])
			if door.distance_to(q) < best:
				best = door.distance_to(q)
				at = q
	if best < 6.0 or best > 40.0:
		return
	var y := APRON_TOP + r + float(spec["clear"]) - 0.4
	jet_bridge(lm, Vector3(at.x, y, at.y), Vector3(door.x, y, door.y))

## Grid points `step` metres apart inside the aprons (22 m clear of their
## edges), within `reach_m` of `near`: parking where the layout has no stands.
static func _apron_spots(data: Dictionary, near: Vector2, reach_m: float, step: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for ring in data["aprons"]:
		var poly := _poly(ring)
		if poly.size() < 3:
			continue
		for inner in Geometry2D.offset_polygon(poly, -22.0, Geometry2D.JOIN_MITER):
			var lo := Vector2(INF, INF)
			var hi := Vector2(-INF, -INF)
			for v in inner:
				lo = lo.min(v)
				hi = hi.max(v)
			var x := lo.x
			while x <= hi.x:
				var z := lo.y
				while z <= hi.y:
					var p := Vector2(x, z)
					if p.distance_to(near) <= reach_m and Geometry2D.is_point_in_polygon(p, inner):
						out.append(p)
					z += step
				x += step
	return out

## An aircraft at an authored spot (heading in degrees: 0 along +X, positive toward +Z).
static func aircraft(lm: LandmarkMesh, kind: String, tail_hex: String, x: float, z: float, heading_deg: float) -> void:
	LandmarkAircraft.place(lm, kind, tail_hex, Vector2(x, z), deg_to_rad(heading_deg))

## A paved slab: its top at `top`, its sides down to SKIRT_Y.
static func slab(lm: LandmarkMesh, key: String, ring: PackedVector2Array, top: float) -> void:
	if ring.size() >= 3:
		lm.poly_prism(key, ring, SKIRT_Y, top, true)

## Only the top face of `ring` at height `y` (paint, roofs).
static func cap(lm: LandmarkMesh, key: String, ring: PackedVector2Array, y: float) -> void:
	var idx := Geometry2D.triangulate_polygon(ring)
	for t in range(0, idx.size(), 3):
		var a := ring[idx[t]]
		var b := ring[idx[t + 1]]
		var c := ring[idx[t + 2]]
		lm.tri(key, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y),
			Vector3.UP, Vector3.UP, Vector3.UP, a, b, c)

## A layout outline as a polygon without repeated points.
static func _poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		var v := Vector2(float(p[0]), float(p[1]))
		if out.is_empty() or out[out.size() - 1].distance_to(v) >= 0.05:
			out.append(v)
	if out.size() > 1 and out[0].distance_to(out[out.size() - 1]) < 0.05:
		out.remove_at(out.size() - 1)
	return out

static func _area(ring: PackedVector2Array) -> float:
	var a := 0.0
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5
