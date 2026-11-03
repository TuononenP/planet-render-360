class_name StreetFront
extends RefCounted

## The street side of a facade, on exposed stretches that face a road
## (PartyWalls.faces_street) — what makes a Paris café row, a Brooklyn
## brownstone street, a Tokyo shopping lane and an Amsterdam canal front
## read as themselves rather than as the same box:
## - canvas awnings over shop bays (`awning`, in the look's
##   `awning_colours`; striped or plain per building);
## - a stone stoop up to the door (`stoop`, brownstones);
## - vertical lit signs on the upper floors (`signage`, Tokyo/Hong Kong);
## - a big poster / video screen high on a tall front (`screens`, Shibuya,
##   Hong Kong; desktop Ultra only);
## - an iron fire escape on the front (`fire_escape`, New York walk-ups);
## - a stepped, neck or bell gable rising over the roof on a narrow
##   gable-fronted house (`gable`, Amsterdam), with its hoist beam;
## - a garage door at street level with the entry stair beside it
##   (`garage`, San Francisco flats and stucco rowhouses);
## - a bracketed cornice along the top of a flat-roofed front (`cornice`,
##   Italianate and Edwardian San Francisco).
## Rolls are seeded per building and stretch; geometry goes to FacadeRelief's
## ReliefKit, so one building is still one mesh.

const SIGN_COLOURS := ["#d8262e", "#f2c230", "#f4f1e8", "#2a6fd1", "#1f9e5a", "#e2531f"]
## A screen needs a front this long (m), is at most this wide (m).
const SCREEN_MIN_LEN_M := 14.0
const SCREEN_MAX_W_M := 18.0
const DEFAULT_AWNINGS := ["#7a1f24", "#1f4a34", "#22314f", "#8a6a2a"]
const SHOP_USES: Array[String] = ["shop", "cafe", "restaurant", "bar", "pub",
	"fast_food", "bakery", "pharmacy", "bank"]

static func add(kit: ReliefKit, spans: Array, rows: Array, d: Dictionary, stone: Material) -> void:
	if rows.is_empty():
		return
	var raised := bool(d.get("raised", false))
	var look: Dictionary = d["look"]
	var relief: Dictionary = look.get("relief", {})
	var seed_v := float(d["seed"])
	var b: Dictionary = d.get("b", {})
	var shops := str(look.get("ground", "")) in ["shop", "signage"] \
		or str(look.get("pattern", "")) == "haussmann" or str(b.get("use", "")) in SHOP_USES
	var garage := has_garage(d)
	var trim := FacadeRelief.trim_for(look, stone)
	var corniced := str(d.get("shape", "")) == "flat" \
		and ArchitectureStyle._h(seed_v, 89) < float(relief.get("cornice", 0.0))
	var stooped := false
	var escaped := false
	var longest := -1
	for i in spans.size():
		if spans[i]["street"] and (longest < 0 or float(spans[i]["len_m"]) > float(spans[longest]["len_m"])):
			longest = i
	for i in spans.size():
		var sp: Dictionary = spans[i]
		if not sp["street"]:
			continue
		var salt := float(i) * 1.37
		if shops and rows[0]["ground"] and not raised:
			_awnings(kit, sp, rows[0], relief, seed_v, salt)
			# Desktop Ultra near the eye: the lit shop spills onto the pavement.
			if bool(d.get("shop_lights", false)):
				ShopLights.note(sp["a"], sp["dir"], sp["n"], float(sp["len_m"]), float(rows[0]["y0"]))
		if garage and i == longest:
			_garage(kit, sp, rows, float(d["ground_y"]), stone, trim, seed_v)
			stooped = true
		if corniced:
			_cornice(kit, sp, float(d["top"]), trim)
		if not stooped and not raised and i == longest and ArchitectureStyle._h(seed_v, 81) < float(relief.get("stoop", 0.0)):
			_stoop(kit, sp, float(d["ground_y"]), stone)
			stooped = true
		if ArchitectureStyle._h(seed_v + salt, 82) < float(relief.get("signage", 0.0)):
			_signs(kit, sp, rows, seed_v + salt)
		if bool(d.get("screens", false)) and i == longest \
				and ArchitectureStyle._h(seed_v, 84) < float(relief.get("screens", 0.0)):
			_screen(kit, sp, rows, seed_v)
		if not escaped and not raised and i == longest and rows.size() >= 4 \
				and ArchitectureStyle._h(seed_v, 83) < float(relief.get("fire_escape", 0.0)):
			_fire_escape(kit, sp, rows)
			escaped = true
		if str(relief.get("gable", "")) != "" and bool(d.get("gable_front", false)):
			_gable(kit, sp, d, str(relief["gable"]))

## A garage at street level (rolled per building on the look's `garage`
## odds): never under a shopfront or on a raised building. FacadeRelief
## then starts its bays above the garage storey.
static func has_garage(d: Dictionary) -> bool:
	var look: Dictionary = d["look"]
	var b: Dictionary = d.get("b", {})
	if bool(d.get("raised", false)) or str(look.get("ground", "")) in ["shop", "signage"] \
			or str(b.get("use", "")) in SHOP_USES:
		return false
	return ArchitectureStyle._h(float(d["seed"]), 90) < float((look.get("relief", {}) as Dictionary).get("garage", 0.0))

const GARAGE_DOORS := ["#f2efe8", "#d8d4cc", "#5a4a3a", "#7a8288", "#e8e0d0", "#3a4a5a"]
## Riser and tread of the entry stair (m).
const RISER_M := 0.19
const TREAD_M := 0.28

## Garage door under the bay (the first window bay of a narrow front, the
## second of a wider one) and the entry stair on the next bay, climbing
## along the wall to a door at the first floor: the San Francisco flat
## raised over its garage.
static func _garage(kit: ReliefKit, sp: Dictionary, rows: Array, ground_y: float,
		stone: Material, trim: Material, seed_v: float) -> void:
	var m := WorldScale.metres_to_units()
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var bays := maxi(int(sp["bays"]), 1)
	var step := float(sp["len_m"]) * m / float(bays)
	var door_bay := 0 if bays < 3 else 1
	var dw := minf(step * 0.86, 2.8 * m)
	var dh := minf(float(rows[0]["y1"]) - ground_y - 0.35 * m, 2.3 * m)
	if dh < 1.8 * m:
		return
	var dc2: Vector2 = (sp["a"] as Vector2) + dir * step * (float(door_bay) + 0.5)
	var dc := Vector3(dc2.x, ground_y, dc2.y) + az * 0.03 * m
	var door := ReliefKit.flat(str(GARAGE_DOORS[int(ArchitectureStyle._h(seed_v, 91) * GARAGE_DOORS.size())
		% GARAGE_DOORS.size()]), 0.55)
	kit.quad(door, dc - ax * dw * 0.5, dc + ax * dw * 0.5, dc + ax * dw * 0.5 + Vector3.UP * dh,
		dc - ax * dw * 0.5 + Vector3.UP * dh, az)
	# Panel grooves, then the header and jambs in the trim.
	var groove := ReliefKit.flat("#2e2e2c", 0.8)
	for k in range(1, 4):
		var gy := Vector3.UP * dh * float(k) / 4.0 + az * 0.005 * m
		kit.quad(groove, dc - ax * dw * 0.48 + gy, dc + ax * dw * 0.48 + gy,
			dc + ax * dw * 0.48 + gy + Vector3.UP * 0.03 * m, dc - ax * dw * 0.48 + gy + Vector3.UP * 0.03 * m, az)
	kit.box(trim, dc + Vector3.UP * (dh + 0.09 * m), ax, az, Vector3(dw + 0.3 * m, 0.18 * m, 0.12 * m))
	for s in [-1.0, 1.0]:
		kit.box(trim, dc + ax * s * (dw * 0.5 + 0.06 * m) + Vector3.UP * dh * 0.5, ax, az,
			Vector3(0.12 * m, dh, 0.1 * m))
	if bays < 2 or rows.size() < 2:
		return
	# Entry stair on the neighbouring bay, rising away from the garage.
	var rise := minf(float(rows[1]["y0"]) - ground_y, 3.6 * m)
	if rise < 0.6 * m:
		return
	var sb := door_bay + 1 if door_bay + 1 < bays else door_bay - 1
	var away := signf(float(sb - door_bay))
	var steps := ceili(rise / (RISER_M * m))
	var run := minf(step * 0.9, float(steps) * TREAD_M * m)
	var tread := run / float(steps)
	var depth := 1.1 * m
	var s2: Vector2 = (sp["a"] as Vector2) + dir * step * (float(sb) + 0.5)
	var start := Vector3(s2.x, ground_y, s2.y) - ax * away * run * 0.5
	for k in steps:
		var h := rise * float(k + 1) / float(steps)
		kit.box(stone, start + ax * away * tread * (float(k) + 0.5) + Vector3.UP * h * 0.5 + az * depth * 0.5,
			ax, az, Vector3(tread, h, depth))
	var top := start + ax * away * run + Vector3.UP * rise
	kit.rail(start + az * depth + Vector3.UP * RISER_M * m, top + az * depth, 0.9 * m, az)
	# The entry door at the head of the stair.
	var e := top - ax * away * 0.6 * m + az * 0.03 * m
	kit.quad(ReliefKit.flat("#4a3a2e", 0.6), e - ax * 0.5 * m, e + ax * 0.5 * m,
		e + ax * 0.5 * m + Vector3.UP * 2.1 * m, e - ax * 0.5 * m + Vector3.UP * 2.1 * m, az)

## Bracketed cornice along the top of a flat-roofed street front: a band
## projecting 0.45 m on slim brackets every ~0.6 m, in the trim.
static func _cornice(kit: ReliefKit, sp: Dictionary, top: float, trim: Material) -> void:
	var m := WorldScale.metres_to_units()
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var len := float(sp["len_m"]) * m
	var mid2: Vector2 = (sp["a"] as Vector2) + dir * len * 0.5
	var mid := Vector3(mid2.x, top, mid2.y)
	kit.box(trim, mid - Vector3.UP * 0.16 * m + az * 0.225 * m, ax, az, Vector3(len, 0.32 * m, 0.45 * m))
	kit.box(trim, mid - Vector3.UP * 0.62 * m + az * 0.04 * m, ax, az, Vector3(len, 0.28 * m, 0.08 * m))
	var count := maxi(roundi(len / (0.6 * m)), 2)
	for k in count:
		var t := (float(k) + 0.5) / float(count) * len - len * 0.5
		kit.box(trim, mid + ax * t - Vector3.UP * 0.44 * m + az * 0.17 * m, ax, az,
			Vector3(0.07 * m, 0.24 * m, 0.32 * m))

## Awnings over the shop bays of a ground storey: one colour per building.
static func _awnings(kit: ReliefKit, sp: Dictionary, ground: Dictionary,
		relief: Dictionary, seed_v: float, salt: float) -> void:
	var share := float(relief.get("awning", 0.0))
	if share <= 0.0:
		return
	var m := WorldScale.metres_to_units()
	var colours: Array = relief.get("awning_colours", DEFAULT_AWNINGS)
	if colours.is_empty():
		colours = DEFAULT_AWNINGS
	var mat := ReliefKit.canvas(str(colours[int(ArchitectureStyle._h(seed_v, 84) * colours.size()) % colours.size()]),
		ArchitectureStyle._h(seed_v, 85) < 0.5)
	var a: Vector2 = sp["a"]
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var az := Vector3(n.x, 0.0, n.y)
	var bays := maxi(int(sp["bays"]), 1)
	var step := float(sp["len_m"]) * m / float(bays)
	var y := minf(float(ground["y1"]) - 0.3 * m, float(ground["y0"]) + 3.4 * m)
	var out := 1.3 * m
	var drop := 0.7 * m
	for j in bays:
		if ArchitectureStyle._h(seed_v + salt + float(j) * 0.71, 86) >= share:
			continue
		var c := a + dir * step * (float(j) + 0.5)
		var w := step * 0.86
		var l := Vector3(c.x, y, c.y) - Vector3(dir.x, 0.0, dir.y) * w * 0.5 + az * 0.02 * m
		var r := l + Vector3(dir.x, 0.0, dir.y) * w
		var lf := l + az * out + Vector3.DOWN * drop
		var rf := r + az * out + Vector3.DOWN * drop
		var slope_n := (az * drop + Vector3.UP * out).normalized()
		kit.quad(mat, lf, rf, r, l, slope_n, Vector2.ZERO, Vector2(w / m, 1.0))
		var val := Vector3.DOWN * 0.25 * m
		kit.quad(mat, lf + val, rf + val, rf, lf, az, Vector2.ZERO, Vector2(w / m, 0.2))
		for side in [[l, lf, -1.0], [r, rf, 1.0]]:
			var sn := Vector3(dir.x, 0.0, dir.y) * float(side[2])
			kit.quad(mat, side[0], side[1], side[1] + val, side[0] + Vector3.DOWN * 0.05 * m, sn)

## Stoop: five stone steps rising 1.5 m to the door, 2.4 m out, iron rails.
static func _stoop(kit: ReliefKit, sp: Dictionary, ground_y: float, stone: Material) -> void:
	var m := WorldScale.metres_to_units()
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var bays := maxi(int(sp["bays"]), 1)
	var step := float(sp["len_m"]) * m / float(bays)
	var c2: Vector2 = (sp["a"] as Vector2) + dir * step * (float(bays / 2) + 0.5)
	var c := Vector3(c2.x, ground_y, c2.y)
	var w := 1.7 * m
	for k in 5:
		var h := 0.3 * m * float(k + 1)
		var depth := 2.4 * m * (1.0 - float(k) / 5.0)
		kit.box(stone, c + Vector3.UP * h * 0.5 + az * depth * 0.5, ax, az, Vector3(w, h, depth))
	for s in [-1.0, 1.0]:
		var foot: Vector3 = c + ax * s * w * 0.5 + az * 2.4 * m + Vector3.UP * 0.3 * m
		var head: Vector3 = c + ax * s * w * 0.5 + Vector3.UP * 1.5 * m
		kit.rail(head, foot, 0.9 * m, ax * s)

## Vertical signs at both ends of the stretch from the first floor up.
static func _signs(kit: ReliefKit, sp: Dictionary, rows: Array, seed_v: float) -> void:
	var m := WorldScale.metres_to_units()
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var y0 := float(rows[0]["y1"]) + 0.4 * m
	var y1 := minf(float(rows[-1]["y1"]) - 0.5 * m, y0 + (3.0 + ArchitectureStyle._h(seed_v, 87) * 4.0) * m)
	if y1 - y0 < 1.5 * m:
		return
	var len := float(sp["len_m"]) * m
	for k in (2 if len > 8.0 * m else 1):
		var t := 0.9 * m if k == 0 else len - 0.9 * m
		var p: Vector2 = (sp["a"] as Vector2) + dir * t
		var hex := str(SIGN_COLOURS[int(ArchitectureStyle._h(seed_v, 88 + k) * SIGN_COLOURS.size()) % SIGN_COLOURS.size()])
		kit.box(ReliefKit.sign(hex), Vector3(p.x, (y0 + y1) * 0.5, p.y) + az * 0.45 * m, ax, az,
			Vector3(0.16 * m, y1 - y0, 0.8 * m))

## A big poster or video screen on the stretch: a wide panel above the third
## storey (Shibuya's QFRONT wall, Hong Kong's shopfront towers), one of the
## poster atlas's eight tiles, lit like a sign.
static func _screen(kit: ReliefKit, sp: Dictionary, rows: Array, seed_v: float) -> void:
	var m := WorldScale.metres_to_units()
	var len := float(sp["len_m"]) * m
	if rows.size() < 6 or len < SCREEN_MIN_LEN_M * m:
		return
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var y0 := float(rows[2]["y1"]) + 0.6 * m
	var top := float(rows[-1]["y1"]) - 1.0 * m
	var w := minf(len * 0.7, SCREEN_MAX_W_M * m)
	var h := minf(w * (0.4 + 0.2 * ArchitectureStyle._h(seed_v, 85)), top - y0)
	if h < 4.0 * m:
		return
	w = minf(w, h * 2.4)
	var t := (len - w) * (0.2 + 0.6 * ArchitectureStyle._h(seed_v, 86)) + w * 0.5
	var c: Vector2 = (sp["a"] as Vector2) + dir * t + n * 0.14 * m
	var ax := Vector3(dir.x, 0.0, dir.y) * w * 0.5
	var ctr := Vector3(c.x, y0 + h * 0.5, c.y)
	var up := Vector3.UP * h * 0.5
	var tile := int(ArchitectureStyle._h(seed_v, 87) * float(ReliefKit.SCREEN_TILES)) % ReliefKit.SCREEN_TILES
	var u0 := float(tile % 2) * 0.5
	var v_top := float(tile / 2) * 0.25
	kit.quad(ReliefKit.screen(), ctr - ax - up, ctr + ax - up, ctr + ax + up, ctr - ax + up,
		Vector3(n.x, 0.0, n.y), Vector2(u0, v_top + 0.25), Vector2(u0 + 0.5, v_top))

## Fire escape on the middle bays: an iron platform at every upper floor
## with railings, and a stair flight between each pair.
static func _fire_escape(kit: ReliefKit, sp: Dictionary, rows: Array) -> void:
	var m := WorldScale.metres_to_units()
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var len := float(sp["len_m"]) * m
	var w := minf(len * 0.5, 5.5 * m)
	var c2: Vector2 = (sp["a"] as Vector2) + dir * len * 0.5
	var iron := ReliefKit.flat("#1d1f22", 0.6, 0.5)
	var depth := 1.2 * m
	var prev := Vector3.ZERO
	for row in rows:
		if int(row["storey"]) < 1:
			continue
		var y := float(row["y0"])
		var base := Vector3(c2.x, y, c2.y)
		kit.box(iron, base + az * depth * 0.5, ax, az, Vector3(w, 0.06 * m, depth))
		var f0 := base + az * depth - ax * w * 0.5
		kit.rail(f0, f0 + ax * w, 0.95 * m, az)
		kit.rail(base - ax * w * 0.5, f0, 0.95 * m, -ax)
		kit.rail(f0 + ax * w, base + ax * w * 0.5, 0.95 * m, ax)
		var landing := base + az * depth * 0.5 + ax * (w * 0.5 - 0.4 * m)
		if prev != Vector3.ZERO:
			var flight := (landing - prev)
			kit.box(iron, (landing + prev) * 0.5, flight.normalized() if absf(flight.normalized().y) < 0.99 else ax,
				az, Vector3(flight.length(), 0.05 * m, 0.6 * m))
		prev = base + az * depth * 0.5 - ax * (w * 0.5 - 0.4 * m)

## Stepped / neck / bell gable over a narrow gable-fronted stretch: the
## silhouette rises above the roof's own gable from the wall top, in the
## wall's finish, with a hoist beam under the apex.
static func _gable(kit: ReliefKit, sp: Dictionary, d: Dictionary, kind: String) -> void:
	var m := WorldScale.metres_to_units()
	var rh := float(d.get("roof_h", 0.0))
	var L := float(sp["len_m"]) * m
	if rh < 1.5 * m or L > 12.0 * m or not sp["first"] or not sp["last"]:
		return
	var ring: PackedVector2Array = d["ring"]
	if not str(d.get("shape", "")) in ["gabled", "saltbox", "gambrel"] or not RoofForms.boxy(ring) \
			or int(d.get("storeys", 0)) > 6:
		return
	# The gable end of a gable-fronted roof: an edge across the ridge
	# (RoofForms.ridged's axis), never one along a roof slope.
	var c := RingGeometry.interior_point(ring)
	var dir: Vector2 = sp["dir"]
	if RingGeometry.half_extent(ring, c, Vector2(-dir.y, dir.x)) < L * 0.6 \
			or absf(dir.dot(RoofForms.ridge_axis(ring, d.get("party_flags", PackedByteArray()), true))) > 0.3:
		return
	var pts := _silhouette(kind, L, rh + 0.6 * m)
	var look: Dictionary = d["look"]
	var mat := ReliefKit.stone(str(look.get("wall_set", "brick")), look.get("wall_colour", Color(0, 0, 0, 0)))
	if str(look.get("wall_set", "")) == "brick":
		mat = MaterialLibrary.pbr_material("brick", MaterialLibrary._calib_tint(
			(MaterialLibrary.PBR_SETS["brick"] as Dictionary)["mean"], MaterialLibrary.PRD_BRICK), 0.5)
	var n: Vector2 = sp["n"]
	var a: Vector2 = sp["a"]
	var top := float(d["top"])
	var az := Vector3(n.x, 0.0, n.y)
	var ax := Vector3(dir.x, 0.0, dir.y)
	var front := az * 0.02 * m
	var back := -az * 0.3 * m
	var w3 := func(p: Vector2, off: Vector3) -> Vector3:
		return Vector3(a.x, top, a.y) + ax * p.x + Vector3.UP * p.y + off
	var idx := Geometry2D.triangulate_polygon(pts)
	for k in range(0, idx.size() - 2, 3):
		kit.tri(mat, w3.call(pts[idx[k]], front), w3.call(pts[idx[k + 1]], front),
			w3.call(pts[idx[k + 2]], front), az)
		kit.tri(mat, w3.call(pts[idx[k]], back), w3.call(pts[idx[k + 1]], back),
			w3.call(pts[idx[k + 2]], back), -az)
	for i in pts.size():
		var p0 := pts[i]
		var p1 := pts[(i + 1) % pts.size()]
		if p0.y < 0.01 and p1.y < 0.01:
			continue
		var e := p1 - p0
		var en := (ax * e.y - Vector3.UP * e.x).normalized()
		if en.dot(ax * (p0.x - L * 0.5) + Vector3.UP * p0.y) < 0.0:
			en = -en
		kit.quad(mat, w3.call(p0, back), w3.call(p1, back), w3.call(p1, front), w3.call(p0, front), en)
	var beam: Vector3 = w3.call(Vector2(L * 0.5, rh * 0.82), front)
	kit.box(ReliefKit.flat("#2a2420", 0.8), beam + az * 0.5 * m, az, -ax, Vector3(1.0 * m, 0.2 * m, 0.2 * m))

## Gable outline (s along the wall 0..L, y up from the wall top), counter-
## clockwise from the left foot; always above the roof line y = h·(1 − |2s/L − 1|).
static func _silhouette(kind: String, L: float, h: float) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(L, 0)])
	var m := WorldScale.metres_to_units()
	match kind:
		"step":
			var steps := 4
			var cap := 0.9 * m
			var w := (L - cap) * 0.5 / float(steps)
			var right := PackedVector2Array()
			for k in steps:
				var yk := h * (float(k + 1) * w) / (L * 0.5) + 0.35 * m
				right.append(Vector2(L - float(k) * w, yk))
				right.append(Vector2(L - float(k + 1) * w, yk))
			right.append(Vector2(L * 0.5 + cap * 0.5, h + 0.4 * m))
			right.append(Vector2(L * 0.5 - cap * 0.5, h + 0.4 * m))
			pts.append_array(right)
			for k in range(steps - 1, -1, -1):
				var yk := h * (float(k + 1) * w) / (L * 0.5) + 0.35 * m
				pts.append(Vector2(float(k + 1) * w, yk))
				pts.append(Vector2(float(k) * w, yk))
		_:
			# Neck (straight shoulders) or bell (curved): a narrow raised
			# neck over sloping shoulders, topped by a pediment or an arc.
			var neck := L * 0.36
			var sh := h * 0.62 + 0.3 * m
			var curve := kind == "bell"
			var right := PackedVector2Array()
			for k in 5:
				var t := float(k + 1) / 5.0
				var s := lerpf(L, L * 0.5 + neck * 0.5, t)
				var y := sh * (sin(t * PI * 0.5) if curve else t) + 0.2 * m
				right.append(Vector2(s, y))
			right.append(Vector2(L * 0.5 + neck * 0.5, h + 0.3 * m))
			pts.append_array(right)
			pts.append(Vector2(L * 0.5, h + (0.9 if not curve else 0.6) * m))
			pts.append(Vector2(L * 0.5 - neck * 0.5, h + 0.3 * m))
			for k in range(4, -1, -1):
				var q: Vector2 = right[k]
				pts.append(Vector2(L - q.x, q.y))
	return pts
