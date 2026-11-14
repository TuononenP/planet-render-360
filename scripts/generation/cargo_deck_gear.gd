class_name CargoDeckGear
extends RefCounted

## Cargo deck equipment (metres, +X bow, `spec` as HullLoft):
## - container stacks bay by bay, one corrugated box per container in
##   eight colours ("Box0".."Box7"), on hatch covers, with lashing bridges
##   and a breakwater forward; far ships get one block per bay;
## - hatch coamings and covers for bulk carriers and general cargo;
## - deck cranes (pedestal, cab, stowed jib, hook);
## - a tanker's pipe runs, midship manifold and catwalk.
## Floodlights use ShipLights' "Lamp".
const BOX_COLOURS := ["#2b5d8a", "#9c2b22", "#2f6e3e", "#c8792a", "#7a7f84", "#1f2a36", "#b8b3a5", "#5a3a6e"]
const BAY_M := 12.9
const ROW_M := 2.5
const TIER_M := 2.6

## Registers the container colours on `lm`.
static func register(lm: LandmarkMesh, maps: bool) -> void:
	for k in BOX_COLOURS.size():
		lm.use("Box%d" % k, ShipPaint.corrugated(Color(BOX_COLOURS[k]), maps))

## Container bays from x0 (aft) to x1 (forward) on the deck at `deck_y`.
static func containers(lm: LandmarkMesh, spec: Dictionary, x0: float, x1: float, deck_y: float,
		seed_value: float, detail: bool, max_tiers: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(int(seed_value * 100000.0))
	var bays := int((x1 - x0) / BAY_M)
	for i in bays:
		var x := x0 + (float(i) + 0.5) * BAY_M
		var half := HullLoft.half(spec, x + BAY_M * 0.5) - 0.8
		var rows := maxi(int(half * 2.0 / ROW_M), 2)
		var width := float(rows) * ROW_M
		# Hatch cover under the bay.
		lm.box("DeckSteel", Vector3(x, deck_y + 0.75, 0), Vector3(BAY_M - 0.6, 1.5, width + 0.4), Basis(), 0.0)
		var base := deck_y + 1.5
		var forward := float(i) / float(maxi(bays - 1, 1))
		var cap := maxi(1, int(round(float(max_tiers) * (1.0 - 0.45 * pow(forward, 3.0)))))
		if not detail:
			var tiers := maxi(cap - 1, 1)
			lm.box("Box%d" % (i % BOX_COLOURS.size()), Vector3(x, base + float(tiers) * TIER_M * 0.5, 0),
				Vector3(BAY_M - 0.7, float(tiers) * TIER_M, width), Basis(), 0.0)
			continue
		for r in rows:
			var z := -width * 0.5 + (float(r) + 0.5) * ROW_M
			var tiers := cap - (rng.randi_range(1, 2) if rng.randf() < 0.18 else 0)
			for t in tiers:
				lm.box("Box%d" % rng.randi_range(0, BOX_COLOURS.size() - 1),
					Vector3(x, base + (float(t) + 0.5) * TIER_M, z), Vector3(12.2, TIER_M - 0.06, 2.42), Basis(), 0.0)
		# Lashing bridge aft of the bay.
		if i > 0:
			lm.box("Steel", Vector3(x - BAY_M * 0.5, deck_y + 1.5 + TIER_M, 0), Vector3(0.5, TIER_M * 2.0, width + 0.6), Basis(), 0.0)
			ShipLights.bulb(lm, "Lamp", Vector3(x - BAY_M * 0.5, deck_y + 1.6 + TIER_M * 2.0, width * 0.5), 0.15)
	# Breakwater ahead of the first bay forward.
	var bx := x0 + float(bays) * BAY_M + 1.5
	var bh := HullLoft.half(spec, bx) - 0.3
	for s in [-1.0, 1.0]:
		lm.beam("DeckSteel", Vector3(bx, deck_y + 1.8, 0), Vector3(bx - 3.0, deck_y + 1.8, float(s) * bh), 3.6, 0.3)

## Hatch coamings with side-rolling covers, `holds` from x0 to x1.
static func hatches(lm: LandmarkMesh, spec: Dictionary, x0: float, x1: float, deck_y: float, holds: int) -> void:
	var step := (x1 - x0) / float(holds)
	for i in holds:
		var x := x0 + (float(i) + 0.5) * step
		var w := (HullLoft.half(spec, x) - 2.5) * 2.0
		lm.box("DeckSteel", Vector3(x, deck_y + 0.8, 0), Vector3(step * 0.72, 1.6, w), Basis(), 0.0)
		for s in [-1.0, 1.0]:
			lm.box("Hatch", Vector3(x, deck_y + 1.85, float(s) * w * 0.25), Vector3(step * 0.74, 0.5, w * 0.5 - 0.05), Basis(), 0.0)
			for k in 4:
				lm.box("Hatch", Vector3(x + (float(k) - 1.5) * step * 0.18, deck_y + 2.15, float(s) * w * 0.25),
					Vector3(0.3, 0.12, w * 0.5 - 0.3), Basis(), 0.0)

## A deck crane at `at` with its jib stowed toward `toward` (+1 bow).
static func crane(lm: LandmarkMesh, at: Vector3, reach: float, toward: float, detail: bool) -> void:
	var r := reach * 0.05
	lm.lathe("Hatch", at, PackedVector2Array([Vector2(r, 0), Vector2(r, reach * 0.28), Vector2(r * 0.8, reach * 0.3)]), 12 if detail else 6)
	var cab := at + Vector3(0, reach * 0.3 + 1.2, 0)
	lm.box("Hatch", cab, Vector3(r * 2.4, 2.4, r * 2.0), Basis(), 0.1)
	var tip := cab + Vector3(toward * reach * 0.92, reach * 0.32, 0)
	var foot := cab + Vector3(toward * r, -0.6, 0)
	lm.beam("Hatch", foot, tip, 0.8, 0.9)
	if detail:
		lm.box("Glass", cab + Vector3(toward * r * 1.2, 0.3, 0), Vector3(0.05, 1.0, r * 1.4), Basis(), 0.0)
		HullLoft.tube(lm, "Dark", [tip, tip - Vector3(0, reach * 0.4, 0)], 0.05, 4)
		lm.box("Dark", tip - Vector3(0, reach * 0.4 + 0.4, 0), Vector3(0.6, 0.8, 0.5), Basis(), 0.0)
		ShipLights.bulb(lm, "Lamp", cab + Vector3(0, 1.4, 0), 0.18)

## Tanker deck: pipe runs along the deck, the manifold amidships with its
## hose crane, and the raised catwalk on the centreline.
static func tanker(lm: LandmarkMesh, spec: Dictionary, x0: float, x1: float, deck_y: float, beam: float, detail: bool) -> void:
	var zs := [-0.18, -0.1, -0.04, 0.04]
	for z in zs:
		HullLoft.tube(lm, "Steel", [Vector3(x0, deck_y + 0.9, beam * float(z)), Vector3(x1, deck_y + 0.9, beam * float(z))],
			0.25 if detail else 0.3, 8 if detail else 4)
	lm.box("White", Vector3((x0 + x1) * 0.5, deck_y + 2.4, beam * 0.12), Vector3(x1 - x0, 0.15, 1.0), Basis(), 0.0)
	var mx := (x0 + x1) * 0.5 + (x1 - x0) * 0.05
	for k in 4:
		var x := mx + (float(k) - 1.5) * 2.2
		HullLoft.tube(lm, "Steel", [Vector3(x, deck_y + 0.9, -beam * 0.45), Vector3(x, deck_y + 0.9, beam * 0.45)], 0.3, 8 if detail else 4)
	if not detail:
		return
	var n := int((x1 - x0) / 6.0)
	for i in n + 1:
		var x := lerpf(x0, x1, float(i) / float(maxi(n, 1)))
		lm.box("White", Vector3(x, deck_y + 1.2, beam * 0.12), Vector3(0.2, 2.4, 0.2), Basis(), 0.0)
	HullLoft.tube(lm, "Steel", [Vector3(x0, deck_y + 3.4, beam * 0.12 + 0.5), Vector3(x1, deck_y + 3.4, beam * 0.12 + 0.5)], 0.04, 6)
	crane(lm, Vector3(mx, deck_y, -beam * 0.3), 14.0, 1.0, detail)
	for i in 6:
		var x := lerpf(x0 + 5.0, x1 - 5.0, float(i) / 5.0)
		VesselEquipment.vent(lm, Vector3(x, deck_y, -beam * 0.3), 0.5)
