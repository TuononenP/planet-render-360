class_name AirportPlanes
extends RefCounted

## Places parked aircraft at OSM airports worldwide (`parking_position`, `gate`,
## `apron` fallback), helicopters on ground & rooftop `aeroway=helipad` pads,
## and attaches live animated taxiing/takeoff/landing/helicopter flights via
## `AirTrafficPlan` + `AircraftDriver`.

const GATE_GAP_M := 9.0
const APRON_INSET_M := 24.0
const APRON_STEP_M := 48.0
const APRON_OCCUPIED := 0.55
const HELI_OCCUPIED := 0.65
const MAX_HELIS := 12
## Curated rooftop helipads on hand-built landmarks: [landmark_type, local_pos_m, heading_deg, emergency].
const LANDMARK_HELIPADS := [
	{"type": "tyks_majakka", "local": Vector3(-34.0, 43.92, 14.0), "heading_deg": 25.0, "emergency": true},
]
## Curated ground/waterfront helipads not tagged aeroway=helipad in OSM.
const CURATED_HELIPADS := [
	{"name": "Keilaniemi Helipad", "lat": 60.169471, "lon": 24.830453, "radius_m": 2500.0,
		"heading_deg": -35.0, "emergency": false},
]

static func build(root: Node3D, data: LocationData, ground: GroundTruth) -> int:
	if data == null or data.quality_preset < RenderSettings.Preset.BALANCED:
		return 0
	var m2u := WorldScale.metres_to_units()
	var parked := plan_parked(data, ground, m2u)
	var helis := plan_helipads(data, ground, m2u)
	var flights := AirTrafficPlan.plan(data, ground, m2u, helis)

	var total := 0
	if not parked.is_empty() or not helis.is_empty():
		var holder := Node3D.new()
		holder.name = "ParkedAircraft"
		for p: Dictionary in parked:
			var node := AircraftModel.instantiate(str(p["kind"]), p["livery"], false, true)
			node.transform = p["xform"]
			holder.add_child(node)
			total += 1
		for h: Dictionary in helis:
			if bool(h.get("active", false)):
				continue  # Active helicopter is instantiated under AirTraffic
			var node := AircraftModel.instantiate("helicopter", h["livery"], false, true)
			var yaw := float(h["heading"])
			node.transform = Transform3D(Basis(Vector3.UP, -yaw) * Basis.from_scale(Vector3.ONE * m2u), h["pos"])
			holder.add_child(node)
			total += 1
		if holder.get_child_count() > 0:
			root.add_child(holder)
		else:
			holder.free()

	if not flights.is_empty():
		var traffic := Node3D.new()
		traffic.name = "AirTraffic"
		for f: Dictionary in flights:
			var node := AircraftModel.instantiate(str(f["kind"]), f["livery"], true, true)
			node.set_meta("flight_id", int(f["id"]))
			if not is_equal_approx(m2u, 1.0):
				node.scale = Vector3.ONE * m2u
			traffic.add_child(node)
			total += 1
		var driver := AircraftDriver.new()
		driver.name = "AircraftDriver"
		driver.flights = flights
		traffic.add_child(driver)
		root.add_child(traffic)

	return total

## Plans parked fixed-wing aircraft for `data.aeroways`:
## Array of {kind, livery, centre (Vector2), heading (float), xform (Transform3D)}.
static func plan_parked(data: LocationData, ground: GroundTruth, m2u: float) -> Array:
	var aw: Dictionary = data.aeroways
	if OsmAeroway.is_empty(aw):
		return []
	var cap := _parked_cap(data.quality_preset)
	if cap <= 0:
		return []
	var eye := View360.spawn_xz(data)
	var region := CityStyles.region_at(data.latitude, data.longitude)
	var airport_cls := _infer_airport_class(aw, m2u)
	var cap_rects := _capital_airport_rects(data, m2u)
	var bld_rings := _building_rings(data)
	var term_rings := _terminal_rings(data)
	var rwy_segs := _runway_segments(aw)

	var cands: Array = []  # [dist2, pos, dir, source_kind]
	var stand_pts: Array[Vector2] = []
	for s: Dictionary in aw.get("stands", []):
		var p := Vector2(float(s["x"]), float(s["z"]))
		stand_pts.append(p)
		cands.append([p.distance_squared_to(eye), p, s.get("dir", Vector2.ZERO), "stand"])
	for g: Dictionary in aw.get("gates", []):
		var p := Vector2(float(g["x"]), float(g["z"]))
		var near_stand := false
		for sp in stand_pts:
			if sp.distance_to(p) < 40.0 * m2u:
				near_stand = true
				break
		if not near_stand:
			cands.append([p.distance_squared_to(eye), p, Vector2.ZERO, "gate"])
	if cands.size() < cap:
		for p in _apron_spots(aw.get("aprons", []), m2u):
			if _hash(p.x, p.y, 1.9) <= APRON_OCCUPIED:
				cands.append([p.distance_squared_to(eye), p, Vector2.ZERO, "apron"])

	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var placed: Array = []  # [{centre, clear_u}]
	var out: Array = []
	for c: Array in cands:
		if out.size() >= cap:
			break
		var p: Vector2 = c[1]
		var src := str(c[3])
		if _in_capital_airport(p, cap_rects):
			continue
		var h1 := _hash(p.x, p.y, 3.1)
		var h2 := _hash(p.x, p.y, 7.3)
		var kind := AircraftSpecs.pick_fixed_wing_kind(airport_cls, h1)
		var length := AircraftSpecs.length_m(kind) * m2u
		var clear_u := AircraftSpecs.clear_m(kind) * m2u
		var dir: Vector2 = c[2]
		var centre := p

		if dir == Vector2.ZERO:
			var wall := _nearest_wall(p, term_rings if not term_rings.is_empty() else bld_rings)
			if wall["dist"] < 90.0 * m2u and wall["dist"] > 0.1:
				var to_wall := ((wall["pt"] as Vector2) - p).normalized()
				if src == "gate" and _inside_any(p, bld_rings):
					dir = -to_wall
					centre = (wall["pt"] as Vector2) + to_wall * (GATE_GAP_M * m2u + length * 0.5)
				else:
					dir = to_wall
					if src == "stand":
						centre = p - dir * length * 0.35
			else:
				var ang := _hash(p.x, p.y, 5.7) * TAU
				dir = Vector2(cos(ang), sin(ang))
		elif src == "stand":
			centre = p - dir * length * 0.35

		if ground != null and ground.water_at(centre.x, centre.y) > 0.0:
			continue
		if _on_runway(centre, rwy_segs, 35.0 * m2u):
			continue
		if _hits_building(centre, dir, length, AircraftSpecs.span_m(kind) * m2u, bld_rings):
			continue
		var overlap := false
		for o: Dictionary in placed:
			var need := maxf(clear_u, float(o["clear_u"])) * 0.85
			if (o["centre"] as Vector2).distance_to(centre) < need:
				overlap = true
				break
		if overlap:
			continue

		var heading := atan2(dir.y, dir.x)
		var xform := _surface_xform(centre, dir, length, ground, m2u)
		var livery := AircraftSpecs.pick_livery(kind, data.country, region, h2)
		placed.append({"centre": centre, "clear_u": clear_u})
		out.append({
			"kind": kind, "livery": livery, "centre": centre,
			"heading": heading, "xform": xform,
		})
	return out

## Plans parked & active helicopters on mapped `aeroway=helipad` pads.
## Handles both ground helipads and rooftop helipads (elevated onto the
## enclosing building's roof).
static func plan_helipads(data: LocationData, ground: GroundTruth, m2u: float) -> Array:
	var pads: Array = data.aeroways.get("helipads", [])
	var eye := View360.spawn_xz(data)
	var region := CityStyles.region_at(data.latitude, data.longitude)
	var cap_rects := _capital_airport_rects(data, m2u)
	var out: Array = []
	var active_quota := 2 if data.quality_preset >= RenderSettings.Preset.HIGH else 1
	var active_count := 0
	var lm_pts: Array[Vector2] = []
	# Curated rooftop helipads on hand-built landmarks (e.g. TYKS Majakkasairaala).
	for lh: Dictionary in LANDMARK_HELIPADS:
		var entry := LocationData.entry_for_type(str(lh["type"]))
		if entry.is_empty():
			continue
		if LocationData.distance_m(data.latitude, data.longitude,
				float(entry["lat"]), float(entry["lon"])) > float(entry.get("radius_m", 3000.0)):
			continue
		var at := WorldScale.xz_from_latlon(float(entry["lat"]), float(entry["lon"]),
			data.latitude, data.longitude) * m2u
		var half := minf(LandmarkSites.clear_m(entry) * 0.5, 45.0) if entry.has("clear_m") else 20.0
		var hero_y := TerrainBuilder._hero_y(data, ground, at.x, at.y, entry, half) if ground != null else 0.0
		var yaw_rad := deg_to_rad(float(entry.get("yaw_deg", 0.0)))
		var loc := (lh["local"] as Vector3) * m2u
		var rot := Basis(Vector3.UP, -yaw_rad) * loc
		var wpos := Vector3(at.x + rot.x, hero_y + rot.y, at.y + rot.z)
		var em := bool(lh.get("emergency", false))
		var make_active := active_count < active_quota
		if make_active:
			active_count += 1
		lm_pts.append(Vector2(wpos.x, wpos.z))
		out.append({
			"pos": wpos,
			"heading": deg_to_rad(float(lh.get("heading_deg", 0.0))) + yaw_rad,
			"rooftop": true,
			"emergency": em,
			"active": make_active,
			"phase_offset_s": 0.0,  # starts seated on the helipad before spooling up
			"livery": AircraftSpecs.pick_livery("helicopter", data.country, region, 0.1, em),
		})
	# Curated ground/waterfront helipads (e.g. Keilaniemi circular helipad, Espoo).
	for ch: Dictionary in CURATED_HELIPADS:
		if LocationData.distance_m(data.latitude, data.longitude,
				float(ch["lat"]), float(ch["lon"])) > float(ch.get("radius_m", 2500.0)):
			continue
		var at := WorldScale.xz_from_latlon(float(ch["lat"]), float(ch["lon"]),
			data.latitude, data.longitude) * m2u
		var gy := ground.height_at_world(at.x, at.y) if ground != null else 0.0
		var em := bool(ch.get("emergency", false))
		var make_active := active_count < active_quota
		if make_active:
			active_count += 1
		lm_pts.append(at)
		out.append({
			"pos": Vector3(at.x, gy + 0.05 * m2u, at.y),
			"heading": deg_to_rad(float(ch.get("heading_deg", 0.0))),
			"rooftop": false,
			"emergency": em,
			"active": make_active,
			"phase_offset_s": 0.0,
			"livery": AircraftSpecs.pick_livery("helicopter", data.country, region, 0.15, em),
		})
	if pads.is_empty():
		return out
	var sorted := pads.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return Vector2(float(a["x"]), float(a["z"])).distance_squared_to(eye) \
			< Vector2(float(b["x"]), float(b["z"])).distance_squared_to(eye))
	var guarantee := sorted.size() <= 2
	for pad: Dictionary in sorted:
		if out.size() >= MAX_HELIS:
			break
		var p := Vector2(float(pad["x"]), float(pad["z"]))
		var dup_lm := false
		for lp in lm_pts:
			if lp.distance_to(p) < 80.0 * m2u:
				dup_lm = true
				break
		if dup_lm:
			continue
		if not guarantee and _hash(p.x, p.y, 4.1) > HELI_OCCUPIED:
			continue
		var roof_info := _enclosing_building(p, data)
		var is_rooftop := bool(pad.get("rooftop", false)) or not roof_info.is_empty()
		var y := ground.height_at_world(p.x, p.y) if ground != null else 0.0
		if is_rooftop and not roof_info.is_empty():
			y += float(roof_info["height"]) * m2u + 0.05 * m2u
		elif ground != null and ground.water_at(p.x, p.y) > 0.0:
			continue
		var emergency := bool(pad.get("emergency", false)) or bool(roof_info.get("hospital", false))
		var h_liv := _hash(p.x, p.y, 8.3)
		var heading := _hash(p.x, p.y, 6.7) * TAU
		var make_active := active_count < active_quota
		if make_active:
			active_count += 1
		out.append({
			"pos": Vector3(p.x, y, p.y),
			"heading": heading,
			"rooftop": is_rooftop,
			"emergency": emergency,
			"active": make_active,
			"livery": AircraftSpecs.pick_livery("helicopter", data.country, region, h_liv, emergency),
		})
	return out

static func _parked_cap(preset: int) -> int:
	if preset >= RenderSettings.Preset.ULTRA:
		return 48
	if preset >= RenderSettings.Preset.HIGH:
		return 24
	if preset >= RenderSettings.Preset.BALANCED:
		return 12
	return 0

static func _infer_airport_class(aw: Dictionary, m2u: float) -> String:
	var longest := 0.0
	for r: Dictionary in aw.get("runways", []):
		var pts: PackedVector2Array = r.get("points", PackedVector2Array())
		if pts.size() >= 2:
			longest = maxf(longest, pts[0].distance_to(pts[pts.size() - 1]) / maxf(m2u, 0.001))
	var stands := (aw.get("stands", []) as Array).size() + (aw.get("gates", []) as Array).size()
	var ad := str(aw.get("aerodrome", ""))
	if longest >= 2500.0 or stands >= 15 or ad.contains("international"):
		return "hub"
	if longest >= 1200.0 or stands >= 3 or not (aw.get("aprons", []) as Array).is_empty():
		return "regional"
	return "ga"

static func _surface_xform(centre: Vector2, dir: Vector2, length_u: float,
		ground: GroundTruth, m2u: float) -> Transform3D:
	var heading := atan2(dir.y, dir.x)
	if ground == null:
		return Transform3D(Basis(Vector3.UP, -heading) * Basis.from_scale(Vector3.ONE * m2u),
			Vector3(centre.x, 0.0, centre.y))
	var nose := centre + dir * length_u * 0.35
	var tail := centre - dir * length_u * 0.35
	var yn := ground.height_at_world(nose.x, nose.y)
	var yt := ground.height_at_world(tail.x, tail.y)
	var fwd := Vector3(dir.x * length_u * 0.7, yn - yt, dir.y * length_u * 0.7).normalized()
	var right_2d := Vector2(-dir.y, dir.x) * maxf(length_u * 0.25, 2.0 * m2u)
	var yr := ground.height_at_world(centre.x + right_2d.x, centre.y + right_2d.y)
	var yl := ground.height_at_world(centre.x - right_2d.x, centre.y - right_2d.y)
	var side := Vector3(right_2d.x * 2.0, yr - yl, right_2d.y * 2.0).normalized()
	var up := side.cross(fwd).normalized()
	if up.y < 0.0:
		up = -up
	var right := fwd.cross(up).normalized()
	var basis := Basis(fwd, up, right) * Basis.from_scale(Vector3.ONE * m2u)
	return Transform3D(basis, Vector3(centre.x, (yn + yt) * 0.5, centre.y))

static func _apron_spots(aprons: Array, m2u: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var step := APRON_STEP_M * m2u
	var inset := APRON_INSET_M * m2u
	for ap: Dictionary in aprons:
		var poly: PackedVector2Array = ap.get("points", PackedVector2Array())
		if poly.size() < 3:
			continue
		for inner in Geometry2D.offset_polygon(poly, -inset, Geometry2D.JOIN_MITER):
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
					if Geometry2D.is_point_in_polygon(p, inner):
						out.append(p)
					z += step
				x += step
	return out

static func _capital_airport_rects(data: LocationData, m2u: float) -> Array:
	var out: Array = []
	for entry in LandmarkRegistryCapitalAirports.entries():
		if LocationData.distance_m(data.latitude, data.longitude,
				float(entry["lat"]), float(entry["lon"])) <= float(entry["radius_m"]):
			var at := WorldScale.xz_from_latlon(float(entry["lat"]), float(entry["lon"]),
				data.latitude, data.longitude) * m2u
			out.append({"at": at, "entry": entry})
	return out

static func _in_capital_airport(p: Vector2, rects: Array) -> bool:
	for r: Dictionary in rects:
		if LandmarkSites.rect_dist(p, r["at"], r["entry"]) <= 0.0:
			return true
	return false

static func _building_rings(data: LocationData) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for b in data.buildings:
		if b is Dictionary:
			var ring: PackedVector2Array = (b as Dictionary).get("footprint", PackedVector2Array())
			if ring.size() >= 3:
				out.append(ring)
	return out

static func _terminal_rings(data: LocationData) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var d: Dictionary = b
		var kind := str(d.get("building", d.get("kind", ""))).to_lower()
		var name := str(d.get("name", "")).to_lower()
		if kind in ["terminal", "transportation", "hangar"] or name.contains("terminal"):
			var ring: PackedVector2Array = d.get("footprint", PackedVector2Array())
			if ring.size() >= 3:
				out.append(ring)
	return out

static func _enclosing_building(p: Vector2, data: LocationData) -> Dictionary:
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var d: Dictionary = b
		var ring: PackedVector2Array = d.get("footprint", PackedVector2Array())
		if ring.size() >= 3 and Geometry2D.is_point_in_polygon(p, ring):
			var name := str(d.get("name", "")).to_lower()
			var btype := str(d.get("building", d.get("amenity", ""))).to_lower()
			var hosp := btype == "hospital" or name.contains("hospital") or name.contains("medical") \
				or name.contains("sairaala") or name.contains("sjukhus") or name.contains("clinic")
			return {"height": maxf(float(d.get("height", 12.0)), 4.0), "hospital": hosp}
	return {}

static func _nearest_wall(p: Vector2, rings: Array[PackedVector2Array]) -> Dictionary:
	var best := INF
	var pt := p
	for ring in rings:
		for i in ring.size():
			var q := Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])
			var d := p.distance_to(q)
			if d < best:
				best = d
				pt = q
	return {"dist": best, "pt": pt}

static func _inside_any(p: Vector2, rings: Array[PackedVector2Array]) -> bool:
	for ring in rings:
		if Geometry2D.is_point_in_polygon(p, ring):
			return true
	return false

static func _hits_building(centre: Vector2, dir: Vector2, length_u: float, span_u: float,
		rings: Array[PackedVector2Array]) -> bool:
	var side := Vector2(-dir.y, dir.x)
	var probes := [
		centre,
		centre + dir * length_u * 0.45,
		centre - dir * length_u * 0.45,
		centre + side * span_u * 0.42,
		centre - side * span_u * 0.42,
	]
	for q: Vector2 in probes:
		for ring in rings:
			if Geometry2D.is_point_in_polygon(q, ring):
				return true
	return false

static func _runway_segments(aw: Dictionary) -> Array:
	var out: Array = []
	for r: Dictionary in aw.get("runways", []):
		var pts: PackedVector2Array = r.get("points", PackedVector2Array())
		for i in pts.size() - 1:
			out.append([pts[i], pts[i + 1]])
	return out

static func _on_runway(p: Vector2, segs: Array, margin: float) -> bool:
	for s: Array in segs:
		var q := Geometry2D.get_closest_point_to_segment(p, s[0], s[1])
		if p.distance_to(q) < margin:
			return true
	return false

static func _hash(x: float, z: float, salt: float) -> float:
	return fposmod(sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453, 1.0)
