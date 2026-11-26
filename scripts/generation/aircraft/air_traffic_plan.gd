class_name AirTrafficPlan
extends RefCounted

## Pure build-time planner for live animated aircraft traffic (taxiing,
## takeoff, climb-out, approach, landing, and helicopter vertical flights).
## Reads `data.aeroways` and, when a hand-built capital airport landmark is
## present in `data`, also falls back to its measured layout runways/taxiways
## so capital airports get live air traffic too.

const MIN_RUNWAY_M := 380.0
const TAXI_JOIN_M := 14.0
const MAX_TAXI_STEPS := 18
const APPROACH_DIST_M := 4200.0
const CLIMB_DIST_M := 4500.0
const GLIDE_SLOPE_RAD := 0.05236  # ~3 degrees

## Returns an Array of flight dicts for `AircraftDriver`:
##   Fixed-wing: {id, mode: "departure"|"arrival", kind, livery, runway_id,
##     rwy_a, rwy_b, rwy_y, taxi_pts (PackedVector2Array), taxi_y,
##     phase_offset_s}
##   Helicopter: {id, mode: "helicopter", kind: "helicopter", livery,
##     pad_pos (Vector3), heading, out_dir (Vector2), phase_offset_s}
static func plan(data: LocationData, ground: GroundTruth, m2u: float,
		helipads: Array = []) -> Array:
	var flights: Array = []
	var max_fw := _max_fixed_wing(data.quality_preset)
	var max_heli := 2 if data.quality_preset >= RenderSettings.Preset.HIGH else 1
	var region := CityStyles.region_at(data.latitude, data.longitude)
	var next_id := 1

	var rwy_data := _collect_runways_and_taxiways(data, ground, m2u)
	var runways: Array = rwy_data["runways"]
	var taxiways: Array = rwy_data["taxiways"]
	var aprons: Array = rwy_data["aprons"]

	if not runways.is_empty() and max_fw > 0:
		var airport_cls := _airport_class(runways, data.aeroways)
		var used_rwy := runways.slice(0, mini(runways.size(), 2))
		var per_rwy := maxi(1, int(ceil(float(max_fw) / float(used_rwy.size()))))
		for r_idx in used_rwy.size():
			var rwy: Dictionary = used_rwy[r_idx]
			var a: Vector2 = rwy["a"]
			var b: Vector2 = rwy["b"]
			var rwy_y := float(rwy["y"])
			var dep_taxi := _build_taxi_path(taxiways, aprons, a, true, m2u)
			var arr_taxi := _build_taxi_path(taxiways, aprons, b, false, m2u)
			var count := mini(per_rwy, max_fw - flights.size())
			for k in count:
				var is_dep := (k % 2 == 0)
				var h1 := _hash(a.x + float(k) * 37.0, a.y + float(r_idx) * 19.0, 1.3)
				var h2 := _hash(b.x + float(k) * 53.0, b.y + float(r_idx) * 29.0, 2.7)
				var kind := AircraftSpecs.pick_fixed_wing_kind(airport_cls, h1)
				var livery := AircraftSpecs.pick_livery(kind, data.country, region, h2)
				flights.append({
					"id": next_id,
					"mode": "departure" if is_dep else "arrival",
					"kind": kind,
					"livery": livery,
					"runway_id": r_idx,
					"rwy_a": a,
					"rwy_b": b,
					"rwy_y": rwy_y,
					"taxi_pts": dep_taxi if is_dep else arr_taxi,
					"phase_offset_s": float(k) * 26.0 + float(r_idx) * 11.0,
				})
				next_id += 1

	# Active helicopter flights on up to `max_heli` helipads
	var heli_added := 0
	for pad: Dictionary in helipads:
		if heli_added >= max_heli:
			break
		if not bool(pad.get("active", false)):
			continue
		var p: Vector3 = pad["pos"]
		var ang := _hash(p.x, p.z, 5.1) * TAU
		flights.append({
			"id": next_id,
			"mode": "helicopter",
			"kind": "helicopter",
			"livery": pad["livery"],
			"pad_pos": p,
			"heading": float(pad.get("heading", ang)),
			"out_dir": Vector2(cos(ang), sin(ang)),
			"phase_offset_s": float(pad.get("phase_offset_s", float(heli_added) * 34.0 + 6.0)),
		})
		next_id += 1
		heli_added += 1

	return flights

static func _max_fixed_wing(preset: int) -> int:
	if preset >= RenderSettings.Preset.ULTRA:
		return 6
	if preset >= RenderSettings.Preset.HIGH:
		return 4
	if preset >= RenderSettings.Preset.BALANCED:
		return 2
	return 0

static func _airport_class(runways: Array, aw: Dictionary) -> String:
	var longest := 0.0
	for r: Dictionary in runways:
		longest = maxf(longest, float(r["len_m"]))
	var stands := (aw.get("stands", []) as Array).size() + (aw.get("gates", []) as Array).size()
	var ad := str(aw.get("aerodrome", ""))
	if longest >= 2500.0 or stands >= 15 or ad.contains("international"):
		return "hub"
	if longest >= 1200.0 or stands >= 3:
		return "regional"
	return "ga"

static func _collect_runways_and_taxiways(data: LocationData, ground: GroundTruth,
		m2u: float) -> Dictionary:
	var runways: Array = []
	var taxiways: Array = []
	var aprons: Array = []
	var aw: Dictionary = data.aeroways
	for r in aw.get("runways", []):
		var pts: PackedVector2Array = (r as Dictionary).get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var a := pts[0]
		var b := pts[pts.size() - 1]
		var len_m := a.distance_to(b) / maxf(m2u, 0.001)
		if len_m < MIN_RUNWAY_M:
			continue
		# Consistent operating direction: prefer +X / -Z so all traffic flows one way
		if (b - a).x < 0.0 or (is_equal_approx((b - a).x, 0.0) and (b - a).y > 0.0):
			var tmp := a; a = b; b = tmp
		var mid := (a + b) * 0.5
		var y := ground.height_at_world(mid.x, mid.y) if ground != null else 0.0
		runways.append({"a": a, "b": b, "len_m": len_m, "y": y})
	for tw in aw.get("taxiways", []):
		var pts: PackedVector2Array = (tw as Dictionary).get("points", PackedVector2Array())
		if pts.size() >= 2:
			taxiways.append(pts)
	for ap in aw.get("aprons", []):
		var pts: PackedVector2Array = (ap as Dictionary).get("points", PackedVector2Array())
		if pts.size() >= 3:
			aprons.append(pts)

	# If OSM aeroways had no runways, check if a hand-built capital airport is active
	if runways.is_empty():
		var cap := _capital_airport_runways(data, ground, m2u)
		runways = cap["runways"]
		taxiways = cap["taxiways"]

	runways.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		return float(x["len_m"]) > float(y["len_m"]))
	return {"runways": runways, "taxiways": taxiways, "aprons": aprons}

static func _capital_airport_runways(data: LocationData, ground: GroundTruth,
		m2u: float) -> Dictionary:
	var out_r: Array = []
	var out_t: Array = []
	for entry in LandmarkRegistryCapitalAirports.entries():
		var dist := LocationData.distance_m(data.latitude, data.longitude,
			float(entry["lat"]), float(entry["lon"]))
		if dist > 2600.0:
			continue
		var layout := _layout_for_capital(str(entry["type"]))
		if layout.is_empty():
			continue
		var origin := WorldScale.xz_from_latlon(float(entry["lat"]), float(entry["lon"]),
			data.latitude, data.longitude) * m2u
		var yaw := deg_to_rad(float(entry.get("yaw_deg", 0.0)))
		var ca := cos(yaw)
		var sa := sin(yaw)
		for r in layout.get("runways", []):
			var la := Vector2(float(r["a"][0]), float(r["a"][1])) * m2u
			var lb := Vector2(float(r["b"][0]), float(r["b"][1])) * m2u
			var wa := origin + Vector2(la.x * ca - la.y * sa, la.x * sa + la.y * ca)
			var wb := origin + Vector2(lb.x * ca - lb.y * sa, lb.x * sa + lb.y * ca)
			var len_m := wa.distance_to(wb) / maxf(m2u, 0.001)
			if len_m >= MIN_RUNWAY_M:
				var mid := (wa + wb) * 0.5
				var ry := (ground.height_at_world(mid.x, mid.y) if ground != null else 0.0) \
					+ (LandmarkAirfieldKit.RUNWAY_TOP - LandmarkAirfieldKit.GROUND) * m2u
				out_r.append({"a": wa, "b": wb, "len_m": len_m, "y": ry})
		for t in layout.get("taxiways", []):
			var pts := PackedVector2Array()
			for p in t["pts"]:
				var lp := Vector2(float(p[0]), float(p[1])) * m2u
				pts.append(origin + Vector2(lp.x * ca - lp.y * sa, lp.x * sa + lp.y * ca))
			if pts.size() >= 2:
				out_t.append(pts)
		break
	return {"runways": out_r, "taxiways": out_t}

static func _layout_for_capital(t: String) -> Dictionary:
	match t:
		"reykjavik_airport": return CaLayoutReykjavik.DATA
		"tallinn_airport": return CaLayoutTallinn.DATA
		"stockholm_bromma_airport": return CaLayoutStockholm.DATA
		"vilnius_airport": return CaLayoutVilnius.DATA
		"copenhagen_airport": return CaLayoutCopenhagen.DATA
		"lisbon_airport": return CaLayoutLisbon.DATA
		"washington_national_airport": return CaLayoutWashington.DATA
		"aeroparque_jorge_newbery": return CaLayoutBuenosAires.DATA
		"taipei_songshan_airport": return CaLayoutTaipei.DATA
		"wellington_airport": return CaLayoutWellington.DATA
		"kathmandu_airport": return CaLayoutKathmandu.DATA
		"wattay_airport": return CaLayoutVientiane.DATA
		"maputo_airport": return CaLayoutMaputo.DATA
		"helsinki_vantaa_airport": return CaLayoutVantaa.DATA
	return {}

## Walks a connected taxiway chain of 150-550 m ending near `anchor` (for
## departure: apron -> threshold; for arrival: exit -> apron). Returns an
## empty array if no taxiway lies near `anchor` (driver uses runway-only cycle).
static func _build_taxi_path(taxiways: Array, _aprons: Array, anchor: Vector2,
		towards_anchor: bool, m2u: float) -> PackedVector2Array:
	if taxiways.is_empty():
		return PackedVector2Array()
	var join := TAXI_JOIN_M * m2u
	var max_reach := 220.0 * m2u
	var best_idx := -1
	var best_end := false
	var best_d := max_reach
	for i in taxiways.size():
		var pts: PackedVector2Array = taxiways[i]
		for at_end: bool in [false, true]:
			var ep := pts[pts.size() - 1] if at_end else pts[0]
			var d := ep.distance_to(anchor)
			if d < best_d:
				best_d = d
				best_idx = i
				best_end = at_end
	if best_idx < 0:
		return PackedVector2Array()

	# Walk away from anchor across connected taxiways up to ~450 m
	var chain: Array[Vector2] = []
	var used := {best_idx: true}
	var cur_pts: PackedVector2Array = taxiways[best_idx]
	var cur_list := _ordered(cur_pts, best_end)  # starts at endpoint nearest anchor
	chain.append_array(cur_list)
	var total_len := _poly_len(chain)
	var steps := 0
	while total_len < 420.0 * m2u and steps < MAX_TAXI_STEPS:
		steps += 1
		var tip := chain[chain.size() - 1]
		var next_i := -1
		var next_end := false
		var best_j := join
		for i in taxiways.size():
			if used.has(i):
				continue
			var pts: PackedVector2Array = taxiways[i]
			for at_end: bool in [false, true]:
				var ep := pts[pts.size() - 1] if at_end else pts[0]
				var d := ep.distance_to(tip)
				if d < best_j:
					best_j = d
					next_i = i
					next_end = at_end
		if next_i < 0:
			break
		used[next_i] = true
		var seg := _ordered(taxiways[next_i], next_end)
		for k in range(1, seg.size()):
			chain.append(seg[k])
		total_len = _poly_len(chain)

	if chain.size() < 2 or total_len < 40.0 * m2u:
		return PackedVector2Array()
	if towards_anchor:
		chain.reverse()
	return PackedVector2Array(chain)

static func _ordered(pts: PackedVector2Array, start_at_end: bool) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if start_at_end:
		for i in range(pts.size() - 1, -1, -1):
			out.append(pts[i])
	else:
		for p in pts:
			out.append(p)
	return out

static func _poly_len(pts: Array[Vector2]) -> float:
	var s := 0.0
	for i in range(1, pts.size()):
		s += pts[i].distance_to(pts[i - 1])
	return s

static func _hash(x: float, z: float, salt: float) -> float:
	return fposmod(sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453, 1.0)
