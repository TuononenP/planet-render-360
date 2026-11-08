class_name NeighbourEvidence
extends RefCounted

## Terraces look alike. Most buildings carry no colour, material, roof or
## date tag, but a few on the same street usually do, and a block is mostly
## built, painted and roofed together. An untagged building near a tagged
## one of the same kind borrows the tagged one's finish, with a probability
## that falls off with distance, so a mapped yellow house colours its
## neighbours instead of one in two hundred. Only buildings with their own
## tags are evidence (a borrowed finish never spreads further), and a
## building's own tags, landmarks, named, protected and religious buildings
## and civic, industrial and farm kinds are never touched. Seeded by position:
## the same map always resolves the same way.

## Evidence grid cell (m); a lookup scans the 3x3 cells around a building.
const CELL_M := 40.0
## Within NEAR_M a neighbour is borrowed from with NEAR_P, out to CELL_M with FAR_P.
const NEAR_M := 20.0
const NEAR_P := 0.75
const FAR_P := 0.45
## A date is borrowed only from this close (a year is much more local than a paint).
const YEAR_M := 25.0
## Roof finish is borrowed only between footprints of this area ratio.
const ROOF_RATIO := Vector2(0.5, 2.0)
## Kinds that keep their own look.
const OWN_LOOK := ["religious", "civic", "industrial", "farm"]
## Fields borrowed as a block, and the roof ones (need a similar footprint).
const FINISH := ["colour", "material"]
const ROOF := ["roof_shape", "roof_colour", "roof_material"]

## Evidence index over `buildings` for build context "peers": {grid, m2u},
## or {} when no building carries evidence (the lookup is then free).
static func build(buildings: Array, density: String, m2u: float) -> Dictionary:
	var grid := {}
	var cell := CELL_M * m2u
	for b in buildings:
		if not (b is Dictionary):
			continue
		var bd := b as Dictionary
		if not _has_evidence(bd) or _own_look(bd, density):
			continue
		var p := Vector2(float(bd.get("x", 0.0)), float(bd.get("z", 0.0)))
		var key := Vector2i(floori(p.x / cell), floori(p.y / cell))
		if not grid.has(key):
			grid[key] = []
		(grid[key] as Array).append({"p": p, "b": bd, "kind": _kind(bd, density),
			"area": _area(bd)})
	if grid.is_empty():
		return {}
	return {"grid": grid, "m2u": m2u}

## `b` with the missing finish of its nearest evidence neighbour filled in
## (a copy marked "inferred"), or `b` itself when there is nothing to borrow.
static func with_peers(b: Dictionary, ctx: Dictionary) -> Dictionary:
	var peers: Dictionary = ctx.get("peers", {})
	if peers.is_empty() or _own_look(b, str(ctx.get("density", ""))) or not _missing(b):
		return b
	var m2u := float(peers["m2u"])
	var grid: Dictionary = peers["grid"]
	var p := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	var cell := CELL_M * m2u
	var cx := floori(p.x / cell)
	var cz := floori(p.y / cell)
	var kind := _kind(b, str(ctx.get("density", "")))
	var best: Dictionary = {}
	var best_d := INF
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var entries: Array = grid.get(Vector2i(cx + dx, cz + dz), [])
			for e in entries:
				var ed := e as Dictionary
				if str(ed["kind"]) != kind:
					continue
				var d := p.distance_to(ed["p"] as Vector2) / m2u
				if d > 0.01 and d < best_d:
					best_d = d
					best = ed
	if best.is_empty() or best_d > CELL_M:
		return b
	var roll := ArchitectureStyle._h(TerrainBuilder._hash(p.x, p.y), 61)
	if roll >= (NEAR_P if best_d <= NEAR_M else FAR_P):
		return b
	var peer: Dictionary = best["b"]
	var out := b.duplicate()
	var changed := false
	for k in FINISH:
		if _blank(b, k) and not _blank(peer, k):
			out[k] = peer[k]
			changed = true
	var ratio := _area(b) / maxf(float(best["area"]), 1.0)
	if ratio >= ROOF_RATIO.x and ratio <= ROOF_RATIO.y:
		for k in ROOF:
			if _blank(b, k) and not _blank(peer, k):
				out[k] = peer[k]
				changed = true
	if int(b.get("start_year", 0)) == 0 and int(peer.get("start_year", 0)) > 0 and best_d <= YEAR_M:
		out["start_year"] = peer["start_year"]
		changed = true
	if not changed:
		return b
	out["inferred"] = true
	return out

## True when `b` carries a finish, roof or date tag of its own.
static func _has_evidence(b: Dictionary) -> bool:
	for k in FINISH:
		if not _blank(b, k):
			return true
	for k in ROOF:
		if not _blank(b, k):
			return true
	return int(b.get("start_year", 0)) > 0

## True when `b` lacks at least one field a neighbour could supply.
static func _missing(b: Dictionary) -> bool:
	for k in FINISH:
		if _blank(b, k):
			return true
	for k in ROOF:
		if _blank(b, k):
			return true
	return int(b.get("start_year", 0)) == 0

## Buildings that keep their own look: named, protected, landmark and
## monument buildings, places of worship, and the kinds in OWN_LOOK.
static func _own_look(b: Dictionary, density: String) -> bool:
	if str(b.get("name", "")) != "" or bool(b.get("heritage", false)) \
			or bool(b.get("mapped_landmark", false)) or str(b.get("monument", "")) != "" \
			or str(b.get("religion", "")) != "" or str(b.get("architecture", "")) != "":
		return true
	return _kind(b, density) in OWN_LOOK

static func _blank(b: Dictionary, key: String) -> bool:
	return str(b.get(key, "")).strip_edges() == ""

static func _kind(b: Dictionary, density: String) -> String:
	return ArchitectureStyle.kind_for(b, density, _area(b))

## Footprint area (m²).
static func _area(b: Dictionary) -> float:
	return BuildingHeights._area_m2(b)
