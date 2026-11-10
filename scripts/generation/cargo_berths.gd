class_name CargoBerths
extends RefCounted

## Cargo ships alongside port quays. Harbour dressing, not a claim that a
## real vessel is berthed there. A straight mapped quay run is a port run
## when industrial land tagged as a port (OsmTags.harbour_use) lies just
## behind it, or when warehouses, sheds, silos and tanks make up enough of
## the building footprint within BOX_M of it (detailed extracts keep only
## plain industrial land). Ferry terminals keep their ferries and plain
## quays their liners (QuayMoorings.liners). Container ships take the
## longest runs, then bulk carriers and tankers, then general cargo; a
## seeded share ride high in ballast, red bottom paint showing.
const MAX_CARGO := 3
const SPACING_M := 300.0
const PROBE_M := 60.0
const BOX_M := 200.0
const SHARE_PORT := 0.35
const SHARE_ON_INDUSTRIAL := 0.2
const MIN_BUILDINGS := 3
const MIN_M := 80.0
const HEAVY_KINDS := ["warehouse", "industrial", "storage_tank", "silo", "manufacture", "factory",
	"hangar", "shed", "transportation"]
const HEAVY_USES := ["industrial", "storage_tank", "silo", "crane"]

## Whether the quay run a..b (world units) fronts port land.
static func port_run(data: LocationData, a: Vector2, b: Vector2, m: float) -> bool:
	var dir := (b - a).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var mid := (a + b) * 0.5
	var industrial := false
	for poly in data.land_polygons:
		var use := str(poly.get("harbour_use", "")) if poly is Dictionary else ""
		if use == "":
			continue
		var points: PackedVector2Array = poly.get("points", PackedVector2Array())
		for s in [-1.0, 1.0]:
			if Geometry2D.is_point_in_polygon(mid + normal * float(s) * PROBE_M * m, points):
				if use == "port":
					return true
				industrial = true
	var run := a.distance_to(b)
	var total := 0.0
	var heavy := 0.0
	var count := 0
	for bd in data.buildings:
		if not (bd is Dictionary) or ShipBuilder.accepts(bd):
			continue
		var p := Vector2(float(bd.get("x", 0.0)), float(bd.get("z", 0.0)))
		var along := (p - a).dot(dir)
		if along < 0.0 or along > run or absf((p - a).dot(normal)) > BOX_M * m:
			continue
		var area := float(bd.get("size_x", 10.0 * m)) * float(bd.get("size_z", 10.0 * m))
		total += area
		if str(bd.get("kind", "")) in HEAVY_KINDS or str(bd.get("use", "")) in HEAVY_USES:
			heavy += area
			count += 1
	return count >= MIN_BUILDINGS and total > 0.0 \
		and heavy / total >= (SHARE_ON_INDUSTRIAL if industrial else SHARE_PORT)

## Variant and size for a run `run_m` long, from hash `h` in [0, 1):
## [variant, length, beam, height to the mast top] in metres.
static func pick(run_m: float, h: float) -> Array:
	var room := run_m - 30.0
	if room >= 200.0 and h < 0.55:
		var l := minf(room, lerpf(180.0, 300.0, fposmod(h * 7.3, 1.0)))
		return ["container", l, l * 0.15, clampf(l * 0.17, 30.0, 55.0)]
	if room >= 150.0:
		var tanker := fposmod(h * 3.7, 1.0) > 0.7
		var l := minf(room, lerpf(150.0, 240.0 if tanker else 230.0, fposmod(h * 5.1, 1.0)))
		return ["tanker" if tanker else "bulk", l, l * (0.18 if tanker else 0.16), clampf(l * 0.16, 26.0, 48.0)]
	var l := clampf(room, MIN_M, 140.0)
	return ["general", l, l * 0.16, clampf(l * 0.22, 22.0, 36.0)]

## Cargo ships for `data`'s port quays, as LargeShips entries; `placed`
## are the liners and ferries already berthed (kept SPACING_M clear).
static func plan(data: LocationData, ground: GroundTruth, taken: Dictionary, m: float,
		mask: VegetationMask = null, placed: Array = []) -> Array:
	var out: Array = []
	if ground.shoreline == null or not ground.shoreline.ready:
		return out
	var eye := View360.spawn_xz(data)
	var runs: Array = []
	for points in QuayMoorings._quay_lines(data, m):
		runs.append_array(QuayMoorings._straight_runs(points, m))
	runs.sort_custom(func(p: Array, q: Array) -> bool:
		return ((p[0] + p[1]) * 0.5).distance_to(eye) < ((q[0] + q[1]) * 0.5).distance_to(eye))
	for run in runs:
		var a: Vector2 = run[0]
		var b: Vector2 = run[1]
		if a.x > b.x or (is_equal_approx(a.x, b.x) and a.y > b.y):
			var swap := a
			a = b
			b = swap
		var mid := (a + b) * 0.5
		if QuayMoorings._near_terminal(data, mid, m) or not port_run(data, a, b, m):
			continue
		var run_m := a.distance_to(b) / m
		var h := fposmod(sin(mid.x * 12.9898 / m + mid.y * 78.233 / m) * 43758.5453, 1.0)
		var size := pick(run_m, h)
		var length: float = size[1]
		var beam: float = size[2]
		if run_m - 30.0 < MIN_M:
			continue
		var dir := (b - a).normalized()
		for frac in [0.5, 0.25, 0.75]:
			var at := a + dir * (length * 0.5 + 15.0 + (run_m - length - 30.0) * float(frac)) * m
			var berth := QuayMoorings._liner_berth(ground, mask, at, dir, length, beam, m)
			if berth.is_empty():
				continue
			var c: Vector2 = berth["centre"]
			if c.distance_to(eye) > QuayMoorings.LINER_RADIUS_M * m \
					or QuayMoorings._near_eye(c, dir, length, beam, eye, m) \
					or not _clear(out + placed, c, m) or QuayMoorings._mapped_ship_near(data, c, length, m):
				continue
			if not MarinaBuilder._claim(taken, c - dir * length * 0.5 * m, dir, length, beam, m):
				continue
			var info := QuayMoorings.berth_info(ground, a, b, at, berth, beam, m)
			# Bulk carriers and tankers often wait in ballast, high in the water.
			if str(size[0]) != "general" and fposmod(h * 11.7, 1.0) < 0.5:
				info["lift"] = clampf(length * 0.012, 1.5, 4.0)
			out.append([Vector3(c.x, ground.water_level_at(c.x, c.y), c.y), atan2(-dir.y, dir.x),
				length, beam, size[3], h, "cargo:" + str(size[0]), info])
			break
		if out.size() >= MAX_CARGO:
			break
	return out

static func _clear(ships: Array, c: Vector2, m: float) -> bool:
	for l in ships:
		var q: Vector3 = l[0]
		if Vector2(q.x, q.z).distance_to(c) < SPACING_M * m:
			return false
	return true
