class_name BridgeTramDeck
extends RefCounted

## Trams over a registry bridge model that lays its own tracks
## (Kruunuvuorensilta): RailBuilder leaves the mapped track there to the
## model (LandmarkSites.outside_spans), so a tram on the mapped line would
## stand at sea level beside the model's rails. Over the deck the route
## is resampled onto the model's nearest track at its rail-head height
## (TramRoute.heights); everywhere else it stays as mapped.

## Resample step over the deck (m): the deck crests 17 m over 500 m and
## curves, so the tram follows both.
const STEP_M := 4.0

## Registry bridge types whose model lays tram track, and the lookup that
## answers a model-local point for them.
const MODELS := ["kruunuvuorensilta"]

## Rewrites `route` over every registry bridge standing in `data` that
## carries tram track: points on a bridge way over the deck move onto the
## model's track with their rail-head heights; the rest keep NaN.
static func apply(route: TramRoute, data: LocationData, m2u: float) -> void:
	if data == null or route.points.size() < 2:
		return
	var decks: Array = []
	for sp: Array in LandmarkSites.bridge_spans(data):
		var entry := sp[1] as Dictionary
		if str(entry.get("type", "")) in MODELS:
			decks.append(sp)
	if decks.is_empty() or route._ground == null:
		return
	var sea_y := route._ground.render_y(0.0)
	var pts := PackedVector2Array()
	var ways: Array = []
	var ys := PackedFloat32Array()
	var any := false
	for i in route.points.size() - 1:
		var a := route.points[i]
		var b := route.points[i + 1]
		var rail: Dictionary = route.ways[i]
		var bridge := bool(rail.get("bridge", false))
		var n := maxi(1, ceili(a.distance_to(b) / (STEP_M * m2u))) if bridge else 1
		for k in n:
			var p := a.lerp(b, float(k) / float(n))
			var on := _on_deck(p, decks, m2u) if bridge else Vector4(0, 0, 0, -1)
			if on.w > 0.0:
				p = Vector2(on.x, on.z)
				any = true
			if not pts.is_empty():
				ways.append(route.ways[i] if k > 0 else route.ways[i - 1])
			pts.append(p)
			ys.append(sea_y + on.y * m2u if on.w > 0.0 else NAN)
	var last := route.points[route.points.size() - 1]
	var tail := route.ways[route.ways.size() - 1] as Dictionary
	var end := _on_deck(last, decks, m2u) if bool(tail.get("bridge", false)) else Vector4(0, 0, 0, -1)
	ways.append(tail)
	pts.append(Vector2(end.x, end.z) if end.w > 0.0 else last)
	ys.append(sea_y + end.y * m2u if end.w > 0.0 else NAN)
	if not any:
		return
	route.points = pts
	route.ways = ways
	route.heights = ys
	route.cum = PackedFloat32Array([0.0])
	for k in range(1, pts.size()):
		route.cum.append(route.cum[k - 1] + pts[k].distance_to(pts[k - 1]))
	route.length_m = route.cum[route.cum.size() - 1] / m2u

## World point `p` on a deck in `decks`: (x, rail height over sea level in
## metres, z, 1) on the model's nearest track, or w = -1 off every deck.
static func _on_deck(p: Vector2, decks: Array, m2u: float) -> Vector4:
	for sp: Array in decks:
		var site := sp[0] as Vector2
		var entry := sp[1] as Dictionary
		var axis := LandmarkSites.axis(entry)
		var cross := Vector2(-axis.y, axis.x)
		var d := (p - site) / m2u
		var local := Vector2(d.dot(axis), d.dot(cross))
		var hit := _crown(local)
		if hit.w > 0.0:
			var w := site + (axis * hit.x + cross * hit.z) * m2u
			return Vector4(w.x, hit.y, w.y, 1.0)
	return Vector4(0, 0, 0, -1)

## Kruunuvuorensilta: model-local `local` (metres) onto its nearest track,
## (x, rail y, z, 1), or w = -1 off the deck or past its ends.
static func _crown(local: Vector2) -> Vector4:
	var c := KruunuvuorensiltaLine.CENTRE
	var best := INF
	var best_s := 0.0
	var run := 0.0
	for i in c.size() - 1:
		var a := Vector2(c[i].x, c[i].y)
		var b := Vector2(c[i + 1].x, c[i + 1].y)
		var q := Geometry2D.get_closest_point_to_segment(local, a, b)
		var dist := q.distance_to(local)
		if dist < best:
			best = dist
			best_s = run + a.distance_to(q)
		run += a.distance_to(b)
	if best_s <= 0.5 or best_s >= run - 0.5:
		return Vector4(0, 0, 0, -1)
	var centre := LandmarkFhCrownBridge.at(best_s)
	if best > centre.z:
		return Vector4(0, 0, 0, -1)
	var t := LandmarkFhCrownBridge.heading(best_s)
	var off := (local - Vector2(centre.x, centre.y)).dot(Vector2(-t.y, t.x))
	var track: float = LandmarkFhCrownBridge.TRACKS[0]
	for o: float in LandmarkFhCrownBridge.TRACKS:
		if absf(o - off) < absf(track - off):
			track = o
	var r := LandmarkFhCrownBridge.rail_point(best_s, track)
	return Vector4(r.x, r.y, r.z, 1.0)
