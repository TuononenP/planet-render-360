class_name ModernBlockRelief
extends RefCounted

## Built relief for modern blocks (1945 on) on desktop Ultra, flat-roofed
## or under a plain pitch:
## the pieces that keep a post-war slab or a contemporary office from
## reading as an extruded box. FacadeRelief's own keys dress historic
## fronts (string courses, quoins, oriels); a modernist block has none of
## them, so before this it stood as flat walls under a bare parapet.
## On every exposed stretch, on the facade's own storey rows and bays:
## - fascia: a metal, aluminium or rendered band capping the parapet;
## - base course: a darker plinth band all round, not only on the street;
## - entrances: a cantilevered canopy over a dark door, or a framed portal;
## - a stair/lift core: a one-bay projection with a glazed strip, rising
##   past the parapet as the roof access head;
## - offices: vertical fins on curtain walls, floor ledges on strip glazing;
## - apartments: open balcony stacks on the sunnier faces when the style
##   row draws no balconies of its own.
## Worldwide defaults per kind (defaults); a style row's `rv["modern"]`
## dict overrides them key by key, `rv["modern"] = false` turns it off.
## Seeded per building (salts 150–179), one merged mesh with the facade's
## other relief (ReliefKit), at most MAX_TRIS triangles per building.

## Added triangles one building may carry.
const MAX_TRIS := 4000
## A box is six quads.
const BOX_TRIS := 12
## Triangles of one balcony: slab and solid parapet, or slab and rails.
const SOLID_BALCONY_TRIS := 48
const OPEN_BALCONY_TRIS := 18
const KINDS: Array[String] = ["apartments", "commercial", "civic"]
## First year counted as modern.
const MODERN_FROM := 1945
const HISTORIC_WALLS: Array[String] = ["limestone", "stone", "wood", "adobe"]
const HISTORIC_PATTERNS: Array[String] = ["ornate", "haussmann", "brownstone", "shophouse",
	"clapboard", "adobe", "balcony"]
const HISTORIC_RELIEF: Array[String] = ["string_course", "quoins", "oriel", "turret", "gable",
	"balconette", "cornice", "stoop", "altana", "chimney_cap"]
## One entrance per this much face (m), at most MAX_ENTRANCES a building.
const ENTRANCE_EVERY_M := 25.0
const MAX_ENTRANCES := 3
const MIN_ENTRANCE_FACE_M := 8.0
const MIN_CORE_FACE_M := 12.0
const CORE_DEPTH_M := 0.45
const CORE_RISE_M := 1.2
## Roofs a modern block may carry: flat, or a plain pitch (a 1950s-80s
## block under a low hipped or gabled roof). Pitched blocks get no fascia
## (their eave is BuildingTrim's cornice) and a core that stops at the eaves.
const ROOF_SHAPES: Array[String] = ["flat", "gabled", "hipped", "skillion", "half-hipped"]
const CANOPY_Y_M := 2.9

const DEFAULTS := {
	"apartments": {"base": 0.8, "entrance": 0.9, "entrance_kind": [["canopy", 1]], "core": 0.45,
		"balconies": 0.35, "fins": 0.0, "fascia": [["metal", 2], ["render", 2], ["alu", 1], ["none", 1]]},
	"commercial": {"base": 0.6, "entrance": 0.9, "entrance_kind": [["canopy", 1], ["portal", 1]],
		"core": 0.25, "balconies": 0.0, "fins": 0.6, "fascia": [["metal", 3], ["alu", 2], ["none", 1]]},
	"civic": {"base": 0.7, "entrance": 0.9, "entrance_kind": [["portal", 2], ["canopy", 1]],
		"core": 0.25, "balconies": 0.0, "fins": 0.3, "fascia": [["metal", 2], ["render", 1], ["alu", 1]]},
}

## Era key → [first year, last year] over every city and country era row.
static var _YEARS: Dictionary = _era_years()

static func _era_years() -> Dictionary:
	var out := {}
	for table in [BuildingEra.ERAS, ArchitectureCountryEras.ERAS]:
		for key in table:
			for e in (table[key] as Array):
				var row := e as Array
				var k := str(row[0])
				var span: Array = out.get(k, [int(row[2]), int(row[3])])
				out[k] = [mini(int(span[0]), int(row[2])), maxi(int(span[1]), int(row[3]))]
	return out

## This building's settings: the kind's defaults under the row's own.
static func settings(look: Dictionary) -> Dictionary:
	var out: Dictionary = (DEFAULTS.get(str(look.get("kind", "")), DEFAULTS["apartments"]) as Dictionary).duplicate()
	var own = (look.get("relief", {}) as Dictionary).get("modern", {})
	if own is Dictionary:
		out.merge(own, true)
	return out

## Whether the block gets modern relief: desktop Ultra, a flat-roofed or
## plainly pitched (ROOF_SHAPES) apartment, office or civic block on a tiled facade, not a landmark or
## a tower (TowerMassing/TowerTop dress those), and modern by its tags,
## its era's years, or failing both by its finishes.
static func qualifies(d: Dictionary, tiled: bool = true) -> bool:
	if not bool(d.get("ultra", false)) or not tiled or not str(d.get("shape", "")) in ROOF_SHAPES:
		return false
	var look: Dictionary = d["look"]
	var b: Dictionary = d.get("b", {})
	if not str(look.get("kind", "")) in KINDS or look.has("tower_look") \
			or bool(b.get("mapped_landmark", false)):
		return false
	var relief: Dictionary = look.get("relief", {})
	if relief.get("modern", {}) is bool:
		return bool(relief["modern"])
	if relief.has("modern"):
		return true
	return is_modern(look, b)

static func is_modern(look: Dictionary, b: Dictionary) -> bool:
	var arch := str(b.get("architecture", "")).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	if arch != "" and (arch in BuildingEra.MODERN or arch in ArchitectureCountryEras.POSTWAR_TAGS
			or arch in ArchitectureCountryEras.NEW_TAGS):
		return true
	var year := int(b.get("start_year", 0))
	if year > 0:
		return year >= MODERN_FROM
	if bool(b.get("heritage", false)):
		return false
	var span: Array = _YEARS.get(str(look.get("era", "")), [])
	if not span.is_empty():
		if int(span[0]) >= MODERN_FROM:
			return true
		if int(span[1]) < MODERN_FROM:
			return false
	if str(look.get("wall_set", "")) in HISTORIC_WALLS or str(look.get("pattern", "")) in HISTORIC_PATTERNS:
		return false
	var relief: Dictionary = look.get("relief", {})
	for k in HISTORIC_RELIEF:
		if relief.has(k) and relief[k] != null and relief[k] != false and str(relief[k]) not in ["", "0", "0.0"]:
			return false
	return true

## Seeded weighted pick from [[value, weight], ...].
static func _pick(options: Array, h: float) -> String:
	var total := 0.0
	for o in options:
		total += float((o as Array)[1])
	var t := h * total
	for o in options:
		t -= float((o as Array)[1])
		if t < 0.0:
			return str((o as Array)[0])
	return str((options[-1] as Array)[0]) if not options.is_empty() else ""

class Budget:
	var left := MAX_TRIS
	func take(tris: int) -> bool:
		if left < tris:
			return false
		left -= tris
		return true

## `d` as FacadeRelief.add; `spans` carry FacadeRelief's street, bays and
## glazed `stacks`; `stone` is the relief stone in the wall's finish.
static func add(kit: ReliefKit, spans: Array, rows: Array, d: Dictionary, stone: Material) -> void:
	if spans.is_empty() or rows.is_empty():
		return
	var look: Dictionary = d["look"]
	var s := settings(look)
	var seed_v := float(d["seed"])
	var budget := Budget.new()
	var kind := str(look.get("kind", ""))
	var fascia := _pick(s.get("fascia", []) as Array, ArchitectureStyle._h(seed_v, 150))
	var metal := _fascia_mat(fascia, stone)
	if fascia != "none" and str(d.get("shape", "")) == "flat" and float(d["top"]) > float(d["base"]):
		for sp in spans:
			_fascia(kit, sp, float(d["top"]), metal, budget)
	if ArchitectureStyle._h(seed_v, 151) < float(s.get("base", 0.0)):
		var dark := ReliefKit.flat("#5d5f60", 0.85)
		for sp in spans:
			if _shopfront(sp, d):
				continue
			_base_course(kit, sp, d, dark, ArchitectureStyle._h(seed_v, 152), budget)
	var doors: Array = []
	if ArchitectureStyle._h(seed_v, 153) < float(s.get("entrance", 0.0)):
		doors = _entrances(spans, seed_v)
	var core: Array = []
	if rows.size() >= 3 and ArchitectureStyle._h(seed_v, 154) < float(s.get("core", 0.0)):
		core = _core_at(spans, doors, seed_v)
	if not core.is_empty():
		_core(kit, core[0], int(core[1]), d, FacadeRelief.oriel_paint(d.get("b", {}), look, stone),
			kit.pane(), budget)
	var portal := _pick(s.get("entrance_kind", [["canopy", 1]]) as Array, ArchitectureStyle._h(seed_v, 155)) == "portal"
	for door in doors:
		var on_core: bool = not core.is_empty() and core[0] == door[0] and int(core[1]) == int(door[1])
		_entrance(kit, door[0], int(door[1]), d, CORE_DEPTH_M if on_core else 0.0, portal,
			metal if fascia in ["metal", "alu"] else ReliefKit.flat("#8c8f8f", 0.8), stone, budget)
	var relief: Dictionary = look.get("relief", {})
	if kind != "apartments" and not bool(relief.get("mullion", false)) \
			and ArchitectureStyle._h(seed_v, 156) < float(s.get("fins", 0.0)):
		for sp in spans:
			_fins(kit, sp, rows, d, metal if fascia in ["metal", "alu"] else ReliefKit.flat("#3b4045", 0.45, 0.6), budget)
	if kind == "apartments" and not relief.has("glazed_balcony") and not relief.has("deep_balcony") \
			and not relief.has("balcony_rows"):
		var share := float(s.get("balconies", 0.0))
		if share > 0.0:
			var solid := str(look.get("wall_set", "")) == "concrete" or str(look.get("pattern", "")) in ["panel", "strip"]
			var cost := SOLID_BALCONY_TRIS if solid else OPEN_BALCONY_TRIS
			# Thin the share so whole stacks fit the budget, spread over every face.
			var bays := 0
			for sp in spans:
				if _balcony_face(sp):
					bays += _inner_bays(sp).size()
			var stack := cost * maxi(rows.size() - 1, 1)
			if bays > 0:
				share = minf(share, float(budget.left / stack) / float(bays))
			for sp in spans:
				_balconies(kit, sp, rows, seed_v, share, doors, core, stone, solid, cost, budget)

static func _fascia_mat(kind: String, stone: Material) -> Material:
	match kind:
		"metal":
			return ReliefKit.flat("#3b4045", 0.45, 0.6)
		"alu":
			return ReliefKit.flat("#b9bcbd", 0.35, 0.7)
	return stone

## A stretch that carries a mapped shop's or a style's shopfront.
static func _shopfront(sp: Dictionary, d: Dictionary) -> bool:
	if (d.get("shop_edges", {}) as Dictionary).has(int(sp["edge"])):
		return true
	var look: Dictionary = d["look"]
	if not bool(sp.get("street", false)):
		return false
	return str(look.get("ground", "")) in ["shop", "signage"] \
		or bool((look.get("relief", {}) as Dictionary).get("granite_plinth", false))

static func _axes(sp: Dictionary) -> Array:
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	return [Vector3(dir.x, 0.0, dir.y), Vector3(n.x, 0.0, n.y)]

## A box along a whole stretch, `out` proud of the wall, wrapping the
## stretch's ring corners.
static func _band(kit: ReliefKit, sp: Dictionary, y0: float, y1: float, out: float,
		mat: Material, budget: Budget) -> void:
	if y1 <= y0 or not budget.take(BOX_TRIS):
		return
	var m := WorldScale.metres_to_units()
	var ax_az := _axes(sp)
	var len := float(sp["len_m"]) * m
	var lo := -out if sp["first"] else 0.0
	var hi := len + (out if sp["last"] else 0.0)
	var a: Vector2 = sp["a"]
	var mid := a + (sp["dir"] as Vector2) * (lo + hi) * 0.5
	kit.box(mat, Vector3(mid.x, (y0 + y1) * 0.5, mid.y) + (ax_az[1] as Vector3) * out * 0.5,
		ax_az[0], ax_az[1], Vector3(hi - lo, y1 - y0, out + 0.02 * m))

static func _fascia(kit: ReliefKit, sp: Dictionary, top: float, mat: Material, budget: Budget) -> void:
	var m := WorldScale.metres_to_units()
	var h := 0.45 * m
	_band(kit, sp, top - h, top + 0.02 * m, 0.08 * m, mat, budget)

static func _base_course(kit: ReliefKit, sp: Dictionary, d: Dictionary, mat: Material,
		hv: float, budget: Budget) -> void:
	var m := WorldScale.metres_to_units()
	var ground := float(d.get("ground_y", d["base"]))
	_band(kit, sp, float(d["base"]), ground + lerpf(0.5, 0.8, hv) * m, 0.05 * m, mat, budget)

## Usable bays of a stretch: not its end bays, not a glazed stack's.
static func _inner_bays(sp: Dictionary) -> Array:
	var bays := int(sp["bays"])
	var stacks: PackedByteArray = sp.get("stacks", PackedByteArray())
	var out: Array = []
	for j in range(1, bays - 1):
		if j < stacks.size() and stacks[j] != 0:
			continue
		out.append(j)
	return out

## [[span, bay], ...]: street stretches first, else the longest, one door
## per ENTRANCE_EVERY_M of face, spread over its usable bays.
static func _entrances(spans: Array, seed_v: float) -> Array:
	var faces := spans.filter(func(sp: Dictionary) -> bool:
		return float(sp["len_m"]) >= MIN_ENTRANCE_FACE_M and not _inner_bays(sp).is_empty())
	if faces.is_empty():
		return []
	var street := faces.filter(func(sp: Dictionary) -> bool: return bool(sp.get("street", false)))
	if street.is_empty():
		var longest: Dictionary = faces[0]
		for sp in faces:
			if float(sp["len_m"]) > float(longest["len_m"]):
				longest = sp
		street = [longest]
	var out: Array = []
	for sp in street:
		var bays := _inner_bays(sp)
		var n := clampi(int(float(sp["len_m"]) / ENTRANCE_EVERY_M), 1, mini(bays.size(), MAX_ENTRANCES - out.size()))
		var shift := ArchitectureStyle._h(seed_v + float(sp["edge"]) * 0.71, 157)
		for k in n:
			var at := int((float(k) + 0.25 + shift * 0.5) / float(n) * float(bays.size()))
			out.append([sp, bays[clampi(at, 0, bays.size() - 1)]])
		if out.size() >= MAX_ENTRANCES:
			break
	return out

## [span, bay] of the stair core: the first entrance on a long enough
## face, else the middle usable bay of the longest face.
static func _core_at(spans: Array, doors: Array, seed_v: float) -> Array:
	for door in doors:
		if float((door[0] as Dictionary)["len_m"]) >= MIN_CORE_FACE_M:
			return door
	var best: Dictionary = {}
	for sp in spans:
		if float(sp["len_m"]) >= MIN_CORE_FACE_M and not _inner_bays(sp).is_empty() \
				and (best.is_empty() or float(sp["len_m"]) > float(best["len_m"])):
			best = sp
	if best.is_empty():
		return []
	var bays := _inner_bays(best)
	return [best, bays[int(ArchitectureStyle._h(seed_v, 158) * float(bays.size())) % bays.size()]]

static func _bay_centre(sp: Dictionary, j: int) -> Vector2:
	var m := WorldScale.metres_to_units()
	var step := float(sp["len_m"]) * m / float(maxi(int(sp["bays"]), 1))
	return (sp["a"] as Vector2) + (sp["dir"] as Vector2) * step * (float(j) + 0.5)

static func _step(sp: Dictionary) -> float:
	return float(sp["len_m"]) * WorldScale.metres_to_units() / float(maxi(int(sp["bays"]), 1))

## Stair/lift core: a one-bay mass `CORE_DEPTH_M` proud of the wall from the
## ground to CORE_RISE_M past the parapet, a glazed strip up its front over
## the ground storey, and a cap slab.
static func _core(kit: ReliefKit, sp: Dictionary, j: int, d: Dictionary, paint: Material,
		glass: Material, budget: Budget) -> void:
	if not budget.take(BOX_TRIS * 3):
		return
	var m := WorldScale.metres_to_units()
	var ax_az := _axes(sp)
	var ax: Vector3 = ax_az[0]
	var az: Vector3 = ax_az[1]
	var c := _bay_centre(sp, j)
	var w := minf(_step(sp), 4.0 * m)
	var depth := CORE_DEPTH_M * m
	var y0 := float(d["base"])
	var y1 := float(d["top"]) + (CORE_RISE_M * m if str(d.get("shape", "")) == "flat" else 0.0)
	var p := Vector3(c.x, 0.0, c.y)
	kit.box(paint, p + Vector3.UP * (y0 + y1) * 0.5 + az * depth * 0.5, ax, az, Vector3(w, y1 - y0, depth))
	var g0 := float(d.get("g_top", y0)) + 0.4 * m
	var g1 := float(d["top"]) - 0.3 * m
	if g1 > g0:
		kit.box(glass, p + Vector3.UP * (g0 + g1) * 0.5 + az * (depth + 0.01 * m), ax, az,
			Vector3(minf(0.9 * m, w * 0.4), g1 - g0, 0.03 * m))
	if str(d.get("shape", "")) == "flat":  # a pitched block's eave caps it
		kit.box(paint, p + Vector3.UP * (y1 + 0.075 * m) + az * depth * 0.5, ax, az,
			Vector3(w + 0.1 * m, 0.15 * m, depth + 0.1 * m))

## Entrance in bay j: a dark door, under a cantilevered canopy or framed
## by a portal; `proud` (m) stands it on the front of a stair core.
static func _entrance(kit: ReliefKit, sp: Dictionary, j: int, d: Dictionary, proud: float,
		portal: bool, canopy_mat: Material, stone: Material, budget: Budget) -> void:
	if not budget.take(BOX_TRIS * (4 if portal else 2)):
		return
	var m := WorldScale.metres_to_units()
	var ax_az := _axes(sp)
	var ax: Vector3 = ax_az[0]
	var az: Vector3 = ax_az[1]
	var c := _bay_centre(sp, j)
	var step := _step(sp)
	var ground := float(d.get("ground_y", d["base"]))
	var g_top := float(d.get("g_top", ground))
	var storey := g_top - ground if g_top > ground + 2.0 * m else float((d["look"] as Dictionary).get("floor_h", 3.0)) * m
	var head := ground + minf(CANOPY_Y_M * m, storey - 0.3 * m)
	var p := Vector3(c.x, 0.0, c.y) + az * proud * m
	var door_w := minf(1.8 * m, step * 0.6)
	kit.box(ReliefKit.flat("#2a2f33", 0.5, 0.2), p + Vector3.UP * (ground + head) * 0.5 + az * 0.02 * m,
		ax, az, Vector3(door_w, head - ground, 0.04 * m))
	if portal:
		var depth := 0.6 * m
		for s in [-1.0, 1.0]:
			kit.box(stone, p + Vector3.UP * (ground + head + 0.25 * m) * 0.5 + az * depth * 0.5
				+ ax * s * (door_w * 0.5 + 0.2 * m), ax, az, Vector3(0.25 * m, head + 0.25 * m - ground, depth))
		kit.box(stone, p + Vector3.UP * (head + 0.125 * m) + az * depth * 0.5, ax, az,
			Vector3(door_w + 0.65 * m, 0.25 * m, depth))
	else:
		var depth := 1.6 * m
		kit.box(canopy_mat, p + Vector3.UP * (head + 0.09 * m) + az * depth * 0.5, ax, az,
			Vector3(minf(step + 0.8 * m, door_w + 2.0 * m), 0.18 * m, depth))

## Office fins: a full-height fin at each inner bay line of a curtain wall,
## a floor ledge per storey on strip glazing.
static func _fins(kit: ReliefKit, sp: Dictionary, rows: Array, d: Dictionary, mat: Material,
		budget: Budget) -> void:
	var m := WorldScale.metres_to_units()
	var ax_az := _axes(sp)
	var ax: Vector3 = ax_az[0]
	var az: Vector3 = ax_az[1]
	var pattern := str((d["look"] as Dictionary).get("pattern", ""))
	var a: Vector2 = sp["a"]
	var dir: Vector2 = sp["dir"]
	if pattern == "curtain":
		var y0 := float(d.get("g_top", d["base"]))
		var y1 := float(d["top"])
		if y1 <= y0:
			return
		var step := _step(sp)
		for j in range(1, int(sp["bays"])):
			if not budget.take(BOX_TRIS):
				return
			var e := a + dir * step * float(j)
			kit.box(mat, Vector3(e.x, (y0 + y1) * 0.5, e.y) + az * 0.225 * m, ax, az,
				Vector3(0.12 * m, y1 - y0, 0.45 * m))
	elif pattern == "strip":
		var len := float(sp["len_m"]) * m
		var mid := a + dir * len * 0.5
		for row in rows:
			if row["ground"] or not budget.take(BOX_TRIS):
				continue
			kit.box(mat, Vector3(mid.x, float(row["y1"]) - 0.075 * m, mid.y) + az * 0.25 * m, ax, az,
				Vector3(len, 0.15 * m, 0.5 * m))

## Open balcony stacks in a seeded share of a stretch's inner bays, on
## faces that do not look north (+z is south), clear of doors and the core.
static func _balcony_face(sp: Dictionary) -> bool:
	return (sp["n"] as Vector2).y >= -0.2 and int(sp["bays"]) >= 3

static func _balconies(kit: ReliefKit, sp: Dictionary, rows: Array, seed_v: float, share: float,
		doors: Array, core: Array, stone: Material, solid: bool, cost: int, budget: Budget) -> void:
	if not _balcony_face(sp):
		return
	var ax_az := _axes(sp)
	var step := _step(sp)
	for j in _inner_bays(sp):
		var taken := false
		for door in doors + ([core] if not core.is_empty() else []):
			if door[0] == sp and absi(int(door[1]) - j) <= 0:
				taken = true
		var pick := ArchitectureStyle._h(seed_v + float(j) * 1.13 + float(sp["edge"]) * 0.29, 159)
		if taken or pick >= share:
			continue
		var c := _bay_centre(sp, j)
		for row in rows:
			if row["ground"]:
				continue
			if not budget.take(cost):
				return
			FacadeRelief._deep_balcony(kit, c, ax_az[0], ax_az[1], step * 0.86, float(row["y0"]),
				stone, solid, false)
