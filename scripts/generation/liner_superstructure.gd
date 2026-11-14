class_name LinerSuperstructure
extends RefCounted

## The accommodation stack of cruise liners and cruise ferries (metres,
## +X bow, decks from cfg["y0"] up to cfg["top"]), in the modern profile:
## - deck 0 is the lifeboat deck, set in so enclosed lifeboats and
##   tenders hang along the hull under the overhanging decks above;
## - cabin decks run the full beam with a rounded, slightly stepped front,
##   balconies (dividers, glass balustrade, handrail) on their sides;
## - the bridge deck has full-beam wings with the sidelights at their
##   tips; one or two sun decks on top are narrower and set back;
## - aft, the liner's decks terrace down (cfg["terraces"]);
## - a raked funnel with exhaust pipes, a radar mast with radomes and
##   scanners, a pool, a water slide (cfg["slide"]) and deck lamps.
## Cabin windows use ShipLights' lit glass; the bridge stays plain Glass.
## Returns the deck layout and anchor points for the caller.
const DECK_M := 2.9
const BALCONY_M := 1.6

## Deck plan: a rectangle `front`..`aft` by +-`half` with front corners
## of radius `rf` (the rounded bow face) and aft corners of radius `ra`.
static func plan(front: float, aft: float, half: float, rf: float, ra: float, steps: int = 6) -> PackedVector2Array:
	var out := PackedVector2Array()
	rf = minf(rf, minf(half, (front - aft) * 0.5) * 0.98)
	ra = minf(ra, minf(half, (front - aft) * 0.5) * 0.98)
	var corners := [[Vector2(front - rf, half - rf), rf, 0.0], [Vector2(aft + ra, half - ra), ra, 0.5 * PI],
		[Vector2(aft + ra, -half + ra), ra, PI], [Vector2(front - rf, -half + rf), rf, 1.5 * PI]]
	for c in corners:
		for i in steps + 1:
			var a: float = float(c[2]) + 0.5 * PI * float(i) / float(steps)
			out.append((c[0] as Vector2) + Vector2(cos(a), sin(a)) * float(c[1]))
	return out

static func build(lm: LandmarkMesh, p: Dictionary, spec: Dictionary, cfg: Dictionary) -> Dictionary:
	var length: float = spec["length"]
	var beam: float = spec["beam"]
	var h: float = p["height"]
	var detail: bool = p.get("detail", true)
	var ultra: bool = detail and bool(p.get("ultra", false))
	var y0: float = cfg["y0"]
	var top: float = cfg["top"]
	var n := clampi(int(round((top - y0) / DECK_M)), 3, 14)
	var boats: bool = cfg.get("boats", true)
	# The lifeboat deck is a deck and a third high, so the boats hang
	# clear under the overhang; the cabin decks share the rest.
	var d0 := (top - y0) / float(n) * (1.35 if boats else 1.0)
	var dh := (top - y0 - d0) / float(n - 1)
	var boat_len := clampf(length * 0.042, 7.0, 11.0)
	var boat_beam := boat_len * 0.34
	var sun := 2 if n >= 7 else 1
	var bi := maxi(n - sun - 1, 1)
	var terrace_from := int(n * 0.55) if bool(cfg.get("terraces", false)) else n
	var fronts: Array[float] = []
	var afts: Array[float] = []
	var widths: Array[float] = []
	var tops: Array[float] = []
	for i in n:
		var front: float = float(cfg["front"]) - float(i) * length * 0.004
		var aft: float = cfg["aft"]
		if i >= terrace_from:
			aft += float(i - terrace_from + 1) * length * 0.035
		var w := beam
		if i == 0:
			w = beam - 2.0 * (boat_beam + 1.0) if boats else beam * 0.94
		if i >= n - sun:
			w = beam * 0.72
			front -= length * 0.05
		fronts.append(front)
		afts.append(aft)
		widths.append(w)
		tops.append(_base(i + 1, y0, d0, dh))
	for i in n:
		_deck(lm, i, _base(i, y0, d0, dh), d0 if i == 0 else dh, fronts[i], afts[i], widths[i] * 0.5, detail, ultra,
			"Glass" if i == bi else ShipLights.cabin_key(i),
			bool(cfg.get("balconies", true)) and i >= 1 and i < n - sun and i != bi)
	var top_y: float = tops[n - 1]
	# Bridge wings across the full beam, just aft of the bridge front.
	var wing_x := fronts[bi] - 5.5
	var wing_y := _base(bi, y0, d0, dh)
	if detail:
		VesselForms.cabin(lm, wing_x, 7.0, beam * 1.06, wing_y, dh, 0.0, "White", 0.0, "Glass")
	else:
		lm.box("White", Vector3(wing_x, wing_y + dh * 0.5, 0), Vector3(7.0, dh, beam * 1.06), Basis(), 0.0)
		VesselKit.windows(lm, wing_x - 3.0, wing_x + 3.4, beam * 0.53, wing_y + dh * 0.3, wing_y + dh * 0.8, 0.0)
	if boats:
		_boats(lm, length, beam, y0, d0, widths[0], boat_len, boat_beam, detail)
	# Sun deck: glass windbreaks, a pool and loungers; a water slide aft.
	var sun_w := widths[n - 1]
	if detail:
		for s in [-1.0, 1.0]:
			lm.box("Glass", Vector3((fronts[n - 1] + afts[n - 1]) * 0.5, top_y + 0.75, float(s) * (sun_w * 0.5 - 0.1)),
				Vector3(fronts[n - 1] - afts[n - 1] - 4.0, 1.5, 0.03), Basis(), 0.0)
	if bool(cfg.get("pool", false)):
		lm.box("Pool", Vector3(-length * 0.02, top_y + 0.05, 0), Vector3(length * 0.06, 0.08, sun_w * 0.4), Basis(), 0.0)
		if ultra:
			for row in [-1.0, 1.0]:
				for k in 10:
					var x := -length * 0.05 + float(k) * 1.0
					VesselForms.slab(lm, "White", Vector3(x, top_y + 0.25, float(row) * sun_w * 0.32), Vector3(0.7, 0.12, 1.9), 0.15)
	if bool(cfg.get("slide", false)) and detail:
		_slide(lm, Vector3(afts[n - 1] + 8.0, top_y, sun_w * 0.25), minf(dh * 2.5, h - top_y - 1.0))
	# Funnel with exhaust pipes; the radar mast with radomes and scanners.
	var funnel_x: float = cfg.get("funnel_x", -length * 0.1)
	var fr := beam * 0.1
	# The funnel stands on the highest deck under its whole footprint (aft
	# terraces can end forward of it) and keeps its top above the sun deck.
	var f_top := top_y + maxf(minf(dh * 2.4, h * 0.97 - top_y), 2.0)
	var f_base := _deck_under(tops, afts, fronts, funnel_x - fr * 2.4, funnel_x + fr * 2.4, y0)
	var f_h := f_top - f_base
	VesselKit.funnel(lm, Vector3(funnel_x, f_base - 0.1, 0), f_h + 0.1, fr, 2.3, "Funnel", "Black", detail)
	if detail:
		for k in 3:
			lm.lathe("Black", Vector3(funnel_x + fr * (float(k) - 1.0) * 0.9, f_top - 0.3, 0),
				PackedVector2Array([Vector2(fr * 0.16, 0), Vector2(fr * 0.16, 1.4 + 0.3 * float(k % 2))]), 10)
	var mast_x: float = fronts[n - 1] - 3.0
	VesselKit.mast(lm, "White", Vector3(mast_x, top_y, 0), h - top_y, maxf(beam * 0.012, 0.18), detail)
	var bar_y := top_y + (h - top_y) * 0.6
	lm.box("Steel", Vector3(mast_x, bar_y, 0), Vector3(1.2, 0.2, 6.0), Basis(), 0.0)
	if detail:
		for s in [-1.0, 1.0]:
			var dome := Vector3(mast_x - 2.0, top_y + (h - top_y) * 0.42, float(s) * 2.6)
			lm.beam("Steel", Vector3(dome.x, top_y, dome.z), dome, 0.25)
			lm.lathe("White", dome, PackedVector2Array([Vector2(0.4, 0), Vector2(1.2, 0.5), Vector2(1.25, 1.2),
				Vector2(0.9, 2.0), Vector2(0.01, 2.4)]), 12)
		for k in 2:
			lm.box("Dark", Vector3(mast_x + 0.3, bar_y + 0.6 + float(k) * 2.2, 0), Vector3(0.35, 0.22, 4.2 - float(k)), Basis(), 0.0)
		var vent_x := funnel_x + fr * 3.0
		var vent_y := _deck_under(tops, afts, fronts, vent_x - 0.7, vent_x + 0.7, y0)
		VesselEquipment.vent(lm, Vector3(vent_x, vent_y, beam * 0.2), 0.6)
		VesselEquipment.vent(lm, Vector3(vent_x, vent_y, -beam * 0.2), 0.6)
		ShipLights.nav(lm, wing_x - 1.5, wing_y + dh * 0.85, beam * 0.53 + 0.25, Vector3(mast_x, h - 0.5, 0),
			Vector3(-length * 0.5 + 0.4, HullLoft.sheer(spec, -length * 0.49) + 1.0, 0),
			Vector3(funnel_x + fr * 2.0, f_top + 0.6, 0))
		ShipLights.deck_lamps(lm, -length * 0.3, length * 0.22, y0 + d0 - 0.35, widths[0] * 0.5 + 0.3, 9.0)
		ShipLights.deck_lamps(lm, afts[n - 1] + 3.0, fronts[n - 1] - 3.0, top_y + 1.6, sun_w * 0.5 - 0.15, 11.0, 0.1)
	return {"n": n, "dh": dh, "deck_tops": tops, "fronts": fronts, "afts": afts, "widths": widths,
		"bridge": bi, "top_y": top_y, "mast_x": mast_x, "funnel_x": funnel_x}

## Floor height of deck `i`: deck 0 is `d0` high, the others `dh`.
static func _base(i: int, y0: float, d0: float, dh: float) -> float:
	return y0 if i == 0 else y0 + d0 + dh * float(i - 1)

## Top of the highest deck spanning x0..x1 (`y0`, the main deck, if none).
static func _deck_under(tops: Array, afts: Array, fronts: Array, x0: float, x1: float, y0: float) -> float:
	for i in range(tops.size() - 1, -1, -1):
		if float(afts[i]) <= x0 and float(fronts[i]) >= x1:
			return float(tops[i])
	return y0

## One deck: walls with a window band, the deck plate above (it carries
## the overhang and the balcony floors) and, on balcony decks, the
## dividers, glass balustrade and handrail.
static func _deck(lm: LandmarkMesh, i: int, yb: float, dh: float, front: float, aft: float,
		half: float, detail: bool, ultra: bool, glass: String, balcony: bool) -> void:
	var rf := minf(half * 0.6, (front - aft) * 0.2)
	if not detail:
		var cx := (front + aft) * 0.5
		lm.box("White", Vector3(cx, yb + dh * 0.5, 0), Vector3(front - aft, dh, half * 2.0), Basis(), 0.0)
		VesselKit.windows(lm, aft + 1.5, front - rf * 0.5, half, yb + dh * 0.3, yb + dh * 0.78, 0.0, glass)
		lm.box("White", Vector3(cx, yb + dh - 0.05, 0), Vector3(front - aft + 0.3, 0.1, half * 2.0 + 0.3), Basis(), 0.0)
		return
	var inset := BALCONY_M if balcony else 0.0
	var wall := plan(front - inset, aft, half - inset, maxf(rf - inset, 1.0), 1.0)
	var bands := [0.0, 0.3, 0.8, 1.0]
	if balcony:
		bands = [0.0, 0.05, 0.86, 1.0]
	elif i <= 1:
		bands = [0.0, 0.16, 0.88, 1.0]
	var rows: Array = []
	for f in bands:
		var ring := PackedVector3Array()
		for q in wall:
			ring.append(Vector3(q.x, yb + dh * float(f), q.y))
		ring.append(ring[0])
		rows.append(ring)
	var centre := Vector3((front + aft) * 0.5, yb + dh * 0.5, 0)
	for b in 3:
		lm.grid(glass if b == 1 else "White", [rows[b], rows[b + 1]], centre, true)
	_plate(lm, "White", plan(front + 0.15, aft - 0.15, half + 0.15, rf + 0.15, 1.15), yb + dh - 0.16, yb + dh)
	if not balcony:
		return
	var x0 := aft + 2.0
	var x1 := front - rf
	var pitch := 3.0 if ultra else 4.5
	var count := maxi(int((x1 - x0) / pitch), 1)
	for s in [-1.0, 1.0]:
		var z := float(s) * (half - inset * 0.5)
		for k in count + 1:
			var x := lerpf(x0, x1, float(k) / float(count))
			lm.box("White", Vector3(x, yb + dh * 0.45, z), Vector3(0.08, dh * 0.86, inset), Basis(), 0.0)
		var edge := float(s) * (half - 0.06)
		lm.box("Glass", Vector3((x0 + x1) * 0.5, yb + 0.55, edge), Vector3(x1 - x0, 1.0, 0.03), Basis(), 0.0)
		HullLoft.tube(lm, "Steel", [Vector3(x0, yb + 1.08, edge), Vector3(x1, yb + 1.08, edge)], 0.035, 6)

## A plate with both faces (decks seen from above and their overhangs
## from below).
static func _plate(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y0: float, y1: float) -> void:
	lm.poly_prism(key, poly, y0, y1)
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri(key, Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(c.x, y0, c.y),
			Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, a, b, c)

## Enclosed lifeboats and tenders along the recessed deck 0, under the
## overhang, each on a pair of davit arms.
static func _boats(lm: LandmarkMesh, length: float, beam: float, y0: float, dh: float, w0: float,
		boat_len: float, boat_beam: float, detail: bool) -> void:
	var count := clampi(int(length * 0.032), 3, 10)
	for s in [-1.0, 1.0]:
		var z := float(s) * (beam * 0.5 - boat_beam * 0.5 - 0.25)
		for k in count:
			var x := lerpf(-length * 0.22, length * 0.18, float(k) / float(maxi(count - 1, 1)))
			var at := Vector3(x, y0 + 0.25, z)
			if detail:
				VesselKit.enclosed_lifeboat(lm, at, boat_len)
				for off in [-0.3, 0.3]:
					var ax := x + boat_len * float(off)
					lm.beam("Steel", Vector3(ax, y0 + dh * 0.95, float(s) * w0 * 0.5),
						Vector3(ax, y0 + dh * 0.95, z), 0.22)
					lm.beam("Steel", Vector3(ax, y0 + dh * 0.95, z), Vector3(ax, at.y + boat_len * 0.25, z), 0.08)
			else:
				lm.box("Orange", at + Vector3(0, boat_len * 0.14, 0), Vector3(boat_len, boat_len * 0.28, boat_beam), Basis(), 0.0)

## A helical water slide around a tower from `base`, `rise` m high.
static func _slide(lm: LandmarkMesh, base: Vector3, rise: float) -> void:
	if rise < 2.0:
		return
	var path: Array = []
	var turns := 2.5
	for i in 41:
		var t := float(i) / 40.0
		var a := TAU * turns * t
		path.append(base + Vector3(cos(a) * 3.2, rise * (1.0 - t) + 0.4, sin(a) * 3.2))
	HullLoft.tube(lm, "Slide", path, 0.55, 10)
	lm.beam("Steel", base, base + Vector3(0, rise + 0.6, 0), 0.6)
