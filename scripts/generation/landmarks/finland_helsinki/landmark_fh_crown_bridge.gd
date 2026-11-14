class_name LandmarkFhCrownBridge
extends RefCounted

## Kruunuvuorensilta (Crown Bridge, 2026), Finland's longest and tallest
## bridge: 1191 m of curved composite deck from Korkeasaari's Palosaari
## tip to Kruunuvuorenranta carrying two tram tracks on its north half
## and the cycle path and footway on its south edge behind a wind screen,
## hung by 17 pairs of stays in two planes from one 135 m white concrete
## pylon. The pylon's diamond-shaped lower part straddles the deck on the
## artificial islet between Nimismies and Emäntä, and a single mast rises
## from where its legs meet. The 260 m main span over the channel to the
## east keeps 20 m clearance; the back span to the west rests on
## auxiliary piers, and both approaches on V piers 64 to 72 m apart.
## Built along the bridge's mapped curve (KruunuvuorensiltaLine) at yaw 0,
## y = 0 at sea level. The deck crests at 24 m over the main span, lands
## at 3.5 m on the Kruunuvuorenranta shore and 7 m on the Palosaari
## underpass, at most 5 % grade (City of Helsinki elevation model 2021
## for the landings). Span split, pier spacing and deck depth are
## estimated from photographs: no source lists them.

const STEP_M := 6.0
const DEPTH_M := 2.6
const TOP_M := 24.0
const WEST_Y := 7.0
const EAST_Y := 3.5
const ROUND_M := 3.0
const CREST_BACK_M := 30.0
const CREST_MAIN_M := 300.0
const MAIN_SPAN_M := 260.0
const PIER_STEP_M := 66.0
const BACK_PIERS: Array[float] = [72.0, 144.0, 216.0]
const JOIN_M := 62.0
const MAST_TOP_M := 131.5
const PYLON_TOP_M := 135.0
## Stays per direction (17 pairs in all) and their deck reach, metres
## from the pylon; the farthest is anchored highest on the mast.
const STAYS_EAST := 9
const STAYS_WEST := 8
const REACH_EAST := Vector2(44.0, 236.0)
const REACH_WEST := Vector2(40.0, 214.0)
const MAST_ANCHORS := Vector2(84.0, 128.0)
## Cross-section, metres from the centre line (positive south): the
## tramway's north edge, metre-gauge tracks, the kerbed separator, the
## cycle path and footway.
const TRAM_EDGE := -7.5
const TRACKS: Array[float] = [-5.4, -1.8]
const GAUGE_HALF := 0.5
const SEPARATOR := Vector2(0.3, 0.9)
const CYCLE_EDGE := 4.0
## Catenary and lighting poles every this many deck samples.
const POLE_EVERY := 6
const POLE_FIRST := 3

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#E3E1DA", 4.0))
	lm.use("Footing", LandmarkMaterials.pbr("concrete", "#8E8B84", 3.0))
	lm.use("Girder", LandmarkMaterials.paint("#DADDDE", 0.5, 0.3))
	lm.use("Track", LandmarkMaterials.pbr("concrete", "#7E7C77", 3.0))
	lm.use("Cycle", LandmarkMaterials.pbr("asphalt", "#7C4236", 4.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B0ACA3", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#B9BEC2", 0.45, 0.55))
	lm.use("Stay", LandmarkMaterials.paint("#F1F2F0", 0.4, 0.2))
	lm.use("Rail", LandmarkMaterials.paint("#4F5254", 0.35, 0.8))
	lm.use("Glass", LandmarkMaterials.glass("#9DB3BE"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF1D6", 0.9))
	lm.use("BeaconLamp", LandmarkMaterials.lit("#FF2A1A", 1.4))
	var plan := _plan()
	_deck(lm, plan)
	_rails(lm, plan)
	_railings(lm, plan)
	_poles(lm, plan)
	_piers(lm)
	_pylon(lm)
	_stays(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, flood_spots())

## Length of the deck centre line, metres.
static func length_m() -> float:
	var cum := _cumulative()
	return cum[cum.size() - 1]

## Arc length of the pylon along the centre line.
static func pylon_s() -> float:
	var cum := _cumulative()
	var c := KruunuvuorensiltaLine.CENTRE
	var best := INF
	var found := 0.0
	for i in c.size() - 1:
		var a := Vector2(c[i].x, c[i].y)
		var b := Vector2(c[i + 1].x, c[i + 1].y)
		var q := Geometry2D.get_closest_point_to_segment(KruunuvuorensiltaLine.PYLON_XZ, a, b)
		var d := q.distance_to(KruunuvuorensiltaLine.PYLON_XZ)
		if d < best:
			best = d
			found = cum[i] + a.distance_to(q)
	return found

## Deck top over the sea at arc length s: ramps from both landings that
## meet the crest over the main span, rounded into vertical curves.
static func deck_y(s: float) -> float:
	var sp := pylon_s()
	var total := length_m()
	var west := WEST_Y + (TOP_M - WEST_Y) * s / (sp - CREST_BACK_M)
	var east := EAST_Y + (TOP_M - EAST_Y) * (total - s) / (total - sp - CREST_MAIN_M)
	return _smin(_smin(west, east), TOP_M)

## Centre (x, z) and half-width at arc length s.
static func at(s: float) -> Vector3:
	var cum := _cumulative()
	var c := KruunuvuorensiltaLine.CENTRE
	s = clampf(s, 0.0, cum[cum.size() - 1])
	for i in c.size() - 1:
		if s <= cum[i + 1] or i == c.size() - 2:
			var f := (s - cum[i]) / maxf(cum[i + 1] - cum[i], 0.001)
			return c[i].lerp(c[i + 1], clampf(f, 0.0, 1.0))
	return c[c.size() - 1]

## Unit heading (x, z) at arc length s.
static func heading(s: float) -> Vector2:
	var a := at(s - 1.0)
	var b := at(s + 1.0)
	return Vector2(b.x - a.x, b.y - a.y).normalized()

## Arc length at each centre point.
static func _cumulative() -> PackedFloat32Array:
	var c := KruunuvuorensiltaLine.CENTRE
	var cum := PackedFloat32Array([0.0])
	for i in range(1, c.size()):
		cum.append(cum[i - 1] + Vector2(c[i].x, c[i].y).distance_to(Vector2(c[i - 1].x, c[i - 1].y)))
	return cum

static func _smin(a: float, b: float) -> float:
	return 0.5 * (a + b - sqrt((a - b) * (a - b) + ROUND_M * ROUND_M))

## Deck samples every STEP_M: arc length, centre (x, z), half-width,
## deck top and the lateral unit vector (pointing south of the heading).
static func _plan() -> Dictionary:
	var total := length_m()
	var n := ceili(total / STEP_M)
	var s := PackedFloat32Array()
	var p := PackedVector3Array()
	var lat := PackedVector3Array()
	for k in n + 1:
		var sk := total * float(k) / n
		var c := at(sk)
		var t := heading(sk)
		s.append(sk)
		p.append(Vector3(c.x, deck_y(sk), c.y))
		lat.append(Vector3(-t.y, 0.0, t.x))
	var h := PackedFloat32Array()
	for k in n + 1:
		h.append(at(s[k]).z)
	return {"s": s, "p": p, "lat": lat, "h": h}

## Point of sample i at lateral offset `o` (base + edge * half-width)
## and dy over the deck top.
static func _sp(plan: Dictionary, i: int, o: Vector2, dy: float) -> Vector3:
	var h: float = plan["h"][i]
	var off := o.x + o.y * h
	return (plan["p"][i] as Vector3) + (plan["lat"][i] as Vector3) * off + Vector3.UP * dy

## Ribbon along the whole deck between section points (a, ya) and (b, yb)
## facing `out` (lateral, up).
static func _strip(lm: LandmarkMesh, plan: Dictionary, key: String, a: Vector2, ya: float, b: Vector2,
		yb: float, out: Vector2) -> void:
	var s: PackedFloat32Array = plan["s"]
	for i in s.size() - 1:
		var nrm := ((plan["lat"][i] as Vector3) * out.x + Vector3.UP * out.y).normalized()
		lm.quad(key, _sp(plan, i, a, ya), _sp(plan, i, b, yb), _sp(plan, i + 1, b, yb), _sp(plan, i + 1, a, ya),
			nrm, Vector2(0.0, -s[i]))

## Deck box (steel edge girders under the concrete slab, a sloped soffit)
## and the surfaces on it.
static func _deck(lm: LandmarkMesh, plan: Dictionary) -> void:
	var e := Vector2(0.0, 1.0)
	var w := Vector2(0.0, -1.0)
	var lip := 0.25
	# Fascias, soffit chamfers and soffit.
	_strip(lm, plan, "Girder", w, lip, w, -1.0, Vector2(-1, 0))
	_strip(lm, plan, "Girder", w, -1.0, Vector2(1.8, -1.0), -DEPTH_M, Vector2(-1, -1.1))
	_strip(lm, plan, "Girder", Vector2(1.8, -1.0), -DEPTH_M, Vector2(-1.8, 1.0), -DEPTH_M, Vector2(0, -1))
	_strip(lm, plan, "Girder", Vector2(-1.8, 1.0), -DEPTH_M, e, -1.0, Vector2(1, -1.1))
	_strip(lm, plan, "Girder", e, -1.0, e, lip, Vector2(1, 0))
	# Edge beams.
	_strip(lm, plan, "Concrete", w, lip, Vector2(0.3, -1.0), lip, Vector2(0, 1))
	_strip(lm, plan, "Concrete", Vector2(0.3, -1.0), lip, Vector2(0.3, -1.0), 0.15, Vector2(1, 0))
	_strip(lm, plan, "Concrete", Vector2(-0.3, 1.0), lip, e, lip, Vector2(0, 1))
	_strip(lm, plan, "Concrete", Vector2(-0.3, 1.0), 0.15, Vector2(-0.3, 1.0), lip, Vector2(-1, 0))
	# North service strip, tramway, separator, cycle path and footway.
	_strip(lm, plan, "Paving", Vector2(0.3, -1.0), 0.15, Vector2(TRAM_EDGE, 0.0), 0.15, Vector2(0, 1))
	_strip(lm, plan, "Paving", Vector2(TRAM_EDGE, 0.0), 0.15, Vector2(TRAM_EDGE, 0.0), 0.0, Vector2(1, 0))
	_strip(lm, plan, "Track", Vector2(TRAM_EDGE, 0.0), 0.0, Vector2(SEPARATOR.x, 0.0), 0.0, Vector2(0, 1))
	_strip(lm, plan, "Concrete", Vector2(SEPARATOR.x, 0.0), 0.0, Vector2(SEPARATOR.x, 0.0), 0.2, Vector2(-1, 0))
	_strip(lm, plan, "Concrete", Vector2(SEPARATOR.x, 0.0), 0.2, Vector2(SEPARATOR.y, 0.0), 0.2, Vector2(0, 1))
	_strip(lm, plan, "Concrete", Vector2(SEPARATOR.y, 0.0), 0.2, Vector2(SEPARATOR.y, 0.0), 0.05, Vector2(1, 0))
	_strip(lm, plan, "Cycle", Vector2(SEPARATOR.y, 0.0), 0.05, Vector2(CYCLE_EDGE, 0.0), 0.05, Vector2(0, 1))
	_strip(lm, plan, "Paving", Vector2(CYCLE_EDGE, 0.0), 0.05, Vector2(CYCLE_EDGE, 0.0), 0.15, Vector2(-1, 0))
	_strip(lm, plan, "Paving", Vector2(CYCLE_EDGE, 0.0), 0.15, Vector2(-0.3, 1.0), 0.15, Vector2(0, 1))
	# Abutments under both ends and the Palosaari underpass wall.
	var total := length_m()
	for s: float in [0.0, 18.3, total]:
		var c := at(s)
		var t := heading(s)
		var y := deck_y(s) - DEPTH_M
		var basis := Basis(Vector3(t.x, 0, t.y), Vector3.UP, Vector3(-t.y, 0, t.x))
		var along := 2.0 if s > 1.0 and s < total - 1.0 else 6.0
		lm.box("Concrete", Vector3(c.x, (y - 1.0) * 0.5, c.y), Vector3(along, y + 1.0, c.z * 2.0 + 0.6), basis)

## Metre-gauge rails on both tracks: a raised head with its two sides.
static func _rails(lm: LandmarkMesh, plan: Dictionary) -> void:
	for track in TRACKS:
		for side: float in [-1.0, 1.0]:
			var o: float = track + side * GAUGE_HALF
			_strip(lm, plan, "Rail", Vector2(o - 0.04, 0.0), 0.12, Vector2(o + 0.04, 0.0), 0.12, Vector2(0, 1))
			_strip(lm, plan, "Rail", Vector2(o - 0.04, 0.0), 0.0, Vector2(o - 0.04, 0.0), 0.12, Vector2(-1, 0))
			_strip(lm, plan, "Rail", Vector2(o + 0.04, 0.0), 0.12, Vector2(o + 0.04, 0.0), 0.0, Vector2(1, 0))

## North railing (posts, top and middle rails) and the south wind screen
## (glass panels between posts under a handrail).
static func _railings(lm: LandmarkMesh, plan: Dictionary) -> void:
	var north := Vector2(0.15, -1.0)
	var south := Vector2(-0.15, 1.0)
	var count: int = (plan["s"] as PackedFloat32Array).size()
	for i in count:
		for o: Vector2 in [north, south]:
			var tall := 1.7 if o == south else 1.2
			var foot := _sp(plan, i, o, 0.25)
			lm.beam("Steel", foot, foot + Vector3.UP * tall, 0.12, 0.12)
		if i == count - 1:
			continue
		for y: float in [0.6, 1.2]:
			lm.beam("Steel", _sp(plan, i, north, 0.25 + y), _sp(plan, i + 1, north, 0.25 + y), 0.08, 0.08)
		lm.beam("Steel", _sp(plan, i, south, 1.95), _sp(plan, i + 1, south, 1.95), 0.1, 0.1)
	for side: float in [-1.0, 1.0]:
		_strip(lm, plan, "Glass", south, 0.35, south, 1.9, Vector2(side, 0))
	# LED strips under both handrails: they wash the paths and read from
	# afar as two glowing lines along the curve.
	for rail: Array in [[1.0, 1.88], [-1.0, 1.4]]:
		var edge: float = rail[0]
		var y: float = rail[1]
		var inner := Vector2(-0.21 * edge, edge)
		var outer := Vector2(-0.09 * edge, edge)
		_strip(lm, plan, "Lamp", inner, y, outer, y, Vector2(0, -1))
		_strip(lm, plan, "Lamp", inner, y, inner, y + 0.07, Vector2(-edge, 0))
		_strip(lm, plan, "Lamp", outer, y, outer, y + 0.07, Vector2(edge, 0))

## Combined catenary and lighting poles on the separator: an arm over
## both tracks carrying the contact wires, a luminaire over the paths.
static func _poles(lm: LandmarkMesh, plan: Dictionary) -> void:
	var sp := pylon_s()
	var s: PackedFloat32Array = plan["s"]
	var mid := Vector2((SEPARATOR.x + SEPARATOR.y) * 0.5, 0.0)
	var last := -1
	for i in range(POLE_FIRST, s.size() - 1, POLE_EVERY):
		if absf(s[i] - sp) < 15.0:
			continue
		var foot := _sp(plan, i, mid, 0.2)
		lm.beam("Steel", foot, foot + Vector3.UP * 8.0, 0.26, 0.26)
		lm.beam("Steel", _sp(plan, i, mid, 7.4), _sp(plan, i, Vector2(TRACKS[0] - 1.0, 0.0), 7.4), 0.14, 0.14)
		lm.beam("Steel", _sp(plan, i, mid, 7.9), _sp(plan, i, Vector2(CYCLE_EDGE - 0.5, 0.0), 7.9), 0.12, 0.12)
		lm.box("Steel", _sp(plan, i, Vector2(CYCLE_EDGE - 0.5, 0.0), 7.75), Vector3(0.7, 0.18, 0.7), Basis(), 0.0)
		lm.box("Lamp", _sp(plan, i, Vector2(CYCLE_EDGE - 0.5, 0.0), 7.64), Vector3(0.55, 0.04, 0.55), Basis(), 0.0)
		if last >= 0:
			for track in TRACKS:
				lm.beam("Rail", _sp(plan, last, Vector2(track, 0.0), 5.9), _sp(plan, i, Vector2(track, 0.0), 5.9),
					0.05, 0.05)
		last = i

## Pier positions along the deck: auxiliary piers under the back span,
## the anchor pier closing the main span, then the approach piers.
static func pier_s() -> PackedFloat32Array:
	var sp := pylon_s()
	var total := length_m()
	var out := PackedFloat32Array()
	for d in BACK_PIERS:
		out.append(sp - d)
	var s := sp - BACK_PIERS[BACK_PIERS.size() - 1] - PIER_STEP_M
	while s > 40.0:
		out.append(s)
		s -= PIER_STEP_M
	s = sp + MAIN_SPAN_M
	while s < total - 25.0:
		out.append(s)
		s += 64.0
	return out

## V piers: a footing at the waterline and two splayed blade columns
## to the soffit; the main span's anchor pier is heavier.
static func _piers(lm: LandmarkMesh) -> void:
	var anchor := pylon_s() + MAIN_SPAN_M
	for s in pier_s():
		var c := at(s)
		var t := heading(s)
		var t3 := Vector3(t.x, 0, t.y)
		var n3 := Vector3(-t.y, 0, t.x)
		var base := Vector3(c.x, 0.0, c.y)
		var soffit := deck_y(s) - DEPTH_M
		var heavy := absf(s - anchor) < 1.0
		var basis := Basis(t3, Vector3.UP, n3)
		lm.box("Footing", base + Vector3.UP * 0.2, Vector3(7.0 if heavy else 5.0, 2.4, c.z * 1.3 + 4.0), basis)
		for side: float in [-1.0, 1.0]:
			lm.beam("Concrete", base + n3 * side * 1.6 + Vector3.UP * 1.4,
				base + n3 * side * c.z * 0.55 + Vector3.UP * soffit, 3.2 if heavy else 2.0, 1.1, t3)

## The pylon: a plinth on the islet, the diamond's two legs splaying out
## past the deck edges and closing on the mast at JOIN_M, a cross beam
## under the deck, the tapering mast, the service balcony, red aviation
## lights and the lightning rod at 135 m.
static func _pylon(lm: LandmarkMesh) -> void:
	var sp := pylon_s()
	var c := at(sp)
	var t := heading(sp)
	var t3 := Vector3(t.x, 0, t.y)
	var n3 := Vector3(-t.y, 0, t.x)
	var basis := Basis(t3, Vector3.UP, n3)
	var base := Vector3(c.x, 0.0, c.y)
	var yd := deck_y(sp)
	var knee := c.z + 2.6
	lm.box("Footing", base + Vector3.UP * 1.5, Vector3(14.0, 5.0, knee * 2.0 + 8.0), basis)
	for side: float in [-1.0, 1.0]:
		var foot := base + n3 * side * 3.0 + Vector3.UP * 4.0
		var k := base + n3 * side * knee + Vector3.UP * (yd - 2.0)
		var top := base + n3 * side * 1.6 + Vector3.UP * (JOIN_M + 2.0)
		lm.beam("Concrete", foot, k, 4.2, 2.8, t3)
		lm.beam("Concrete", k, top, 3.8, 2.4, t3)
		lm.box("Concrete", k, Vector3(4.2, 3.0, 3.0), basis)
	lm.box("Concrete", base + Vector3.UP * (yd - DEPTH_M - 0.9), Vector3(3.5, 1.8, knee * 2.0), basis)
	_taper(lm, "Concrete", base + Vector3.UP * (JOIN_M - 4.0), t3, n3, Vector2(3.4, 2.6), Vector2(2.2, 1.6),
		MAST_TOP_M - JOIN_M + 4.0)
	lm.box("Steel", base + Vector3.UP * 128.5, Vector3(5.4, 0.35, 4.6), basis)
	lm.box("Steel", base + Vector3.UP * (MAST_TOP_M + 0.4), Vector3(1.4, 0.8, 1.4), basis)
	lm.beam("Steel", base + Vector3.UP * (MAST_TOP_M + 0.8), base + Vector3.UP * PYLON_TOP_M, 0.2, 0.2)
	# Red aviation obstacle lights: on the top and on both faces of the mast.
	lm.box("BeaconLamp", base + Vector3.UP * (MAST_TOP_M + 1.1), Vector3(1.0, 0.6, 1.0), basis, 0.0)
	for y: float in [72.0, 102.0]:
		for side: float in [-1.0, 1.0]:
			lm.box("BeaconLamp", base + n3 * side * (_mast_half(y) + 0.2) + Vector3.UP * y, Vector3(0.9, 0.8, 0.5),
				basis, 0.0)

## Night floodlights of the white pylon (LandmarkLights.FLOOD_META,
## model metres): four on the deck beside the legs washing the mast up
## to its top, two on the islet plinth lighting the diamond's legs.
static func flood_spots() -> Array:
	var sp := pylon_s()
	var c := at(sp)
	var t := heading(sp)
	var t3 := Vector3(t.x, 0, t.y)
	var n3 := Vector3(-t.y, 0, t.x)
	var base := Vector3(c.x, 0.0, c.y)
	var yd := deck_y(sp)
	var out: Array = []
	for along: float in [-1.0, 1.0]:
		for side: float in [-1.0, 1.0]:
			out.append([base + t3 * along * 10.0 + n3 * side * (c.z + 6.0) + Vector3.UP * (yd + 1.0),
				base + Vector3.UP * 100.0, 22.0, 1.4])
		out.append([base + t3 * along * 14.0 + Vector3.UP * 4.5, base + Vector3.UP * (JOIN_M * 0.6), 40.0, 0.9])
	return out

## Mast half-width across the deck at height y (for the stay anchors).
static func _mast_half(y: float) -> float:
	var f := clampf((y - JOIN_M + 4.0) / (MAST_TOP_M - JOIN_M + 4.0), 0.0, 1.0)
	return lerpf(2.6, 1.6, f)

## Stays in two planes, from both faces of the mast to anchors on the
## outside of each edge girder, fanning both ways along the curve.
static func _stays(lm: LandmarkMesh) -> void:
	var sp := pylon_s()
	var c := at(sp)
	var t := heading(sp)
	var n3 := Vector3(-t.y, 0, t.x)
	var base := Vector3(c.x, 0.0, c.y)
	for dir: float in [1.0, -1.0]:
		var count := STAYS_EAST if dir > 0.0 else STAYS_WEST
		var reach := REACH_EAST if dir > 0.0 else REACH_WEST
		for k in count:
			var f := float(k) / (count - 1)
			var s: float = sp + dir * lerpf(reach.x, reach.y, f)
			var ym := lerpf(MAST_ANCHORS.x, MAST_ANCHORS.y, f)
			var d := at(s)
			var dt := heading(s)
			var dn := Vector3(-dt.y, 0, dt.x)
			var yd := deck_y(s)
			for side: float in [-1.0, 1.0]:
				var top := base + n3 * side * _mast_half(ym) * 0.7 + Vector3.UP * ym
				var low := Vector3(d.x, yd - 0.4, d.y) + dn * side * (d.z + 0.35)
				lm.beam("Stay", top, low, 0.22, 0.22)
				lm.box("Girder", low, Vector3(0.9, 0.7, 0.7), Basis(Vector3(dt.x, 0, dt.y), Vector3.UP, dn), 0.0)

## Four-sided prism from a rectangle at `base` (half-sizes h0 along t
## and n) up `h` metres to one of half-sizes h1, with a top cap.
static func _taper(lm: LandmarkMesh, key: String, base: Vector3, t: Vector3, n: Vector3, h0: Vector2,
		h1: Vector2, h: float) -> void:
	var st: Array[float] = [-1.0, 1.0, 1.0, -1.0]
	var sn: Array[float] = [-1.0, -1.0, 1.0, 1.0]
	var top := base + Vector3.UP * h
	for i in 4:
		var j := (i + 1) % 4
		var a := base + t * st[i] * h0.x + n * sn[i] * h0.y
		var b := base + t * st[j] * h0.x + n * sn[j] * h0.y
		var c := top + t * st[j] * h1.x + n * sn[j] * h1.y
		var d := top + t * st[i] * h1.x + n * sn[i] * h1.y
		lm.quad(key, a, b, c, d, (t * (st[i] + st[j]) + n * (sn[i] + sn[j])).normalized())
	lm.quad(key, top + t * -h1.x + n * -h1.y, top + t * h1.x + n * -h1.y, top + t * h1.x + n * h1.y,
		top + t * -h1.x + n * h1.y, Vector3.UP)
