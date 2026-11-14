class_name BridgeStructureMembers
extends RefCounted

## A road bridge way on a bridge structure (BridgeStructures): inside the
## outline it lays only its asphalt, a few centimetres over the slab at the
## structure's level, with the road's lane attributes and lane paint
## (RoadBridgeDecks._mark, _paint), and piers under it on land. A stretch
## past the outline (a way mapped longer than the outline, or grown to dry
## ground by BridgeLandings) is a deck of its own (RoadBridgeBuild._bridge)
## at its own profile, eased into the structure's level.

## Builds `line` (a RoadBridgeDecks.Index line) on structure `s`.
static func lay(batches: Dictionary, s: BridgeStructures.Structure, line: Dictionary,
		surf: RoadBuilder._Surface, m2u: float, li: int = -1) -> void:
	# Parsed as RoadBuilder lays a road: rank, lanes and one-way for the
	# lane attributes and paint.
	var road := RoadBuilder._parse(line.get("road", {}), m2u)
	var width := float(line["half"]) * 2.0
	# With its approach slabs (BridgeApproaches), where it has them.
	var mapped: PackedVector2Array = s.points_of(li, line)
	var dense := PackedVector2Array()
	for p in RoadBuilder._resample(mapped, surf.step * 0.34):
		if surf.inside(p):
			dense.append(p)
	if dense.size() < 2:
		return
	dense = BridgeLandings.landed(dense, dense, surf, m2u)
	var n := dense.size()
	var deck := heights(s, dense, line, surf, m2u)
	var on := PackedByteArray()
	on.resize(n)
	var grow := BridgeStructures.ON_M * m2u
	for i in n:
		on[i] = 1 if s.contains(dense[i], grow) else 0
	# The road's chain wear seed, and its kerb flag: as its approaches carry them.
	var ri := int(line.get("ri", -1))
	var seed := surf.wear_seeds[ri] if ri >= 0 and ri < surf.wear_seeds.size() else RoadBridgeDecks.DEFAULT_SEED
	var urban := RoadBridgeDecks.urban_at(dense, surf, road)
	# The slab's own height at any point of the ribbon and its paint, across
	# the width: the abutment ends carry a cross slope (BridgeStructures.
	# Structure.surface_at), which a flat strip at the centreline's height
	# buried on one side and floated on the other.
	var rise := func(k: int, p: Vector2) -> float:
		return s.surface_at(p) if on[k] != 0 else deck[k]
	# A footway or cycleway keeps its paving on the deck (asphalt there
	# read as a different road starting at the abutment).
	var finish := RoadBuilder.finish_of(line.get("road", {}), surf, m2u)
	var top := RoadBuilder._batch(batches, finish if finish in ["paving", "sett", "gravel"] else "bridge")
	var side := RoadBuilder._batch(batches, "deck")
	var lift := BridgeStructures.RIBBON_LIFT_M * m2u
	var i := 0
	while i < n:
		var j := i
		while j + 1 < n and on[j + 1] == on[i]:
			j += 1
		# One point of overlap, so the stretches meet without a gap.
		var last := mini(j + 1, n - 1)
		if last <= i:
			break
		var run := dense.slice(i, last + 1)
		var run_deck := deck.slice(i, last + 1)
		if on[i] != 0:
			top.pad()
			var k0 := top.verts.size()
			_ribbon(top, run, run_deck, width, lift, m2u, s)
			RoadBridgeDecks._mark(top, k0, width, m2u, road, seed, urban)
			for k in range(k0, top.verts.size()):
				top.uv2s[k].y = BridgeStructures.RIBBON_LAYER
			if s.layer > 0 and RoadBridgeDecks.mostly_land(run, surf):
				RoadBridgeBuild._land_piers(side, run, RoadBridgeBuild._dist_of(run), run_deck, surf, m2u)
		else:
			var deck_top := RoadBuilder._batch(batches, "bridge")
			deck_top.pad()
			var k1 := deck_top.verts.size()
			RoadBridgeBuild._bridge(batches, run, width, surf, m2u, "bridge", s.kind, s.layer,
				{"deck": run_deck, "railing": str(line["cls"]) in RoadBridgeDecks.PATH_CLASSES})
			RoadBridgeDecks._mark(deck_top, k1, width, m2u, road, seed, urban)
		i = j + 1
	RoadBridgeDecks._paint(batches, dense, deck, width, surf, m2u, road, seed, line.get("road", {}), rise)

## Deck heights along `pts`: the structure's deck top on its outline, the
## way's own profile past it, eased into the level at the ramp grade.
static func heights(s: BridgeStructures.Structure, pts: PackedVector2Array, line: Dictionary,
		surf: RoadBuilder._Surface, m2u: float) -> PackedFloat32Array:
	var n := pts.size()
	var deck := BridgeStructures._own(pts, line, surf, m2u)
	var fixed := PackedByteArray()
	fixed.resize(n)
	var grow := BridgeStructures.ON_M * m2u
	for i in n:
		if s.contains(pts[i], grow):
			deck[i] = s.surface_at(pts[i])
			fixed[i] = 1
	RoadBridgeDecks._ease(deck, pts, fixed, maxf(float(line["half"]), s.half), m2u)
	return deck

## Asphalt strip `width` wide along `pts`, `lift` over the structure's deck
## top at each edge vertex (flat across the width where the slab is), its
## UVs as RoadBridgeBuild._bridge lays a deck top.
static func _ribbon(top: RoadBuilder._Batch, pts: PackedVector2Array, deck: PackedFloat32Array,
		width: float, lift: float, m2u: float, s: BridgeStructures.Structure) -> void:
	var half := width * 0.5
	var k0 := top.verts.size()
	var along := 0.0
	for i in pts.size():
		if i > 0:
			along += pts[i].distance_to(pts[i - 1])
		var sd := RoadBuilder._side(pts, i) * half
		for e: Vector2 in [pts[i] + sd, pts[i] - sd]:
			top.verts.append(Vector3(e.x, s.surface_at(e) + lift, e.y))
			top.normals.append(Vector3.UP)
		top.uvs.append(Vector2(0.0, along / m2u / 4.0))
		top.uvs.append(Vector2(width / m2u / 4.0, along / m2u / 4.0))
	for i in pts.size() - 1:
		RoadBuilder._quad_up(top, k0 + i * 2, k0 + i * 2 + 1, k0 + i * 2 + 2, k0 + i * 2 + 3)
