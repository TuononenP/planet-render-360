class_name LandmarkArchBridges
extends RefCounted

## Arch bridges in true metres, built along +X.

## Sydney Harbour Bridge (y = 0 at the harbour, `base: water`): the
## 503 m two-hinged steel arch, its two trussed ribs rising to 134 m,
## hangers down to the 49 m deck where it hangs, posts up to it where it
## rides above the arch, the four granite pylons (89 m) at the arch ends
## and the approach spans on concrete piers, 1149 m end to end.
const SH_SPAN := 503.0
const SH_TOP_M := 134.0
const SH_DECK_M := 49.0
const SH_LENGTH := 1149.0
const SH_HALF_W := 24.5
const SH_RIB_Z := 15.0
const SH_HINGE_M := 5.0

static func harbour(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#7D8287", 0.55, 0.45))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B9AE9B", 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B9B3A8", 4.0))
	var half := SH_SPAN * 0.5
	var n := 28
	for rz in [-SH_RIB_Z, SH_RIB_Z]:
		var z: float = rz
		var prev_b := Vector3.ZERO
		var prev_t := Vector3.ZERO
		for k in n + 1:
			var x := -half + SH_SPAN * k / n
			var b := Vector3(x, _sh_bottom(x), z)
			var t := Vector3(x, _sh_top(x), z)
			lm.beam("Steel", b, t, 1.4, 1.4)
			if k > 0:
				lm.beam("Steel", prev_b, b, 2.6, 2.2)
				lm.beam("Steel", prev_t, t, 2.4, 2.0)
				lm.beam("Steel", prev_b if k % 2 == 0 else prev_t, t if k % 2 == 0 else b, 1.0, 1.0)
			prev_b = b
			prev_t = t
	# Bracing between the ribs along the top chord.
	for k in range(0, n + 1, 2):
		var x := -half + SH_SPAN * k / n
		lm.beam("Steel", Vector3(x, _sh_top(x), -SH_RIB_Z), Vector3(x, _sh_top(x), SH_RIB_Z), 1.2, 1.2)
	# Hangers (deck below the arch) and posts (deck above the arch).
	for k in range(1, n):
		var x := -half + SH_SPAN * k / n
		var yb := _sh_bottom(x)
		for z in [-SH_RIB_Z, SH_RIB_Z]:
			if yb > SH_DECK_M + 1.0:
				lm.beam("Steel", Vector3(x, SH_DECK_M, z), Vector3(x, yb, z), 0.8, 0.8)
			else:
				lm.beam("Steel", Vector3(x, yb, z), Vector3(x, SH_DECK_M - 2.0, z), 1.4, 1.4)
	# Deck with its girders, over the whole length.
	lm.box("Deck", Vector3(0, SH_DECK_M + 0.2, 0), Vector3(SH_LENGTH, 0.4, SH_HALF_W * 2.0))
	lm.box("Steel", Vector3(0, SH_DECK_M - 1.6, 0), Vector3(SH_LENGTH, 3.2, SH_HALF_W * 2.0 - 2.0))
	# Pylons at each arch end, either side of the deck.
	for s in [-1.0, 1.0]:
		var px: float = s * (half + 12.0)
		for side in [-1.0, 1.0]:
			var pz: float = side * (SH_HALF_W + 7.0)
			lm.box("Granite", Vector3(px, 44.5, pz), Vector3(22.0, 89.0, 14.0))
			lm.box("Granite", Vector3(px, 88.0, pz), Vector3(23.0, 2.0, 15.0))
		lm.box("Granite", Vector3(px, SH_DECK_M * 0.5 - 2.0, 0), Vector3(22.0, SH_DECK_M - 4.0, SH_HALF_W * 2.0))
		lm.box("Granite", Vector3(s * half, SH_HINGE_M * 0.5, 0), Vector3(12.0, SH_HINGE_M + 1.0, SH_RIB_Z * 2.0 + 6.0))
		# Approach spans on paired concrete piers.
		var x := half + 40.0
		while x < SH_LENGTH * 0.5:
			for side in [-1.0, 1.0]:
				lm.box("Concrete", Vector3(s * x, (SH_DECK_M - 3.2) * 0.5, side * 14.0),
					Vector3(4.0, SH_DECK_M - 3.2, 4.0))
			x += 40.0
	lm.commit(model)

## Bottom chord of the arch: hinge at ±half rising to the crown, 18 m
## under the 134 m top.
static func _sh_bottom(x: float) -> float:
	var u := x / (SH_SPAN * 0.5)
	return SH_HINGE_M + (SH_TOP_M - 18.0 - SH_HINGE_M) * (1.0 - u * u)

## Top chord: 18 m over the bottom at the crown, 57 m at the ends where
## it meets the pylons.
static func _sh_top(x: float) -> float:
	var u := x / (SH_SPAN * 0.5)
	return _sh_bottom(x) + 18.0 + 39.0 * u * u

## Bixby Creek Bridge (y = 0 at the creek bed, `base: ground`): the
## reinforced-concrete open-spandrel arch of 98 m, its twin ribs, the
## spandrel columns and the tall paired piers carrying the 7.3 m deck
## 79 m above the creek, 218 m end to end.
const BX_SPAN := 98.0
const BX_DECK_M := 78.0
const BX_TOP_M := 79.0
const BX_LENGTH := 218.0
const BX_HALF_W := 3.65

static func bixby(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#CFC9BC", 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	var half := BX_SPAN * 0.5
	var spring := 12.0
	var crown := BX_DECK_M - 3.0
	# Twin arch ribs.
	for rz in [-2.8, 2.8]:
		var z: float = rz
		var prev := Vector3(-half, spring, z)
		for k in range(1, 21):
			var x := -half + BX_SPAN * k / 20.0
			var u := x / half
			var p := Vector3(x, spring + (crown - spring) * (1.0 - u * u), z)
			lm.beam("Concrete", prev, p, 2.2, 3.0)
			prev = p
	# Spandrel columns from the ribs to the deck, cross-braced.
	var x := -half + 7.0
	while x < half:
		var u := x / half
		var yb := spring + (crown - spring) * (1.0 - u * u)
		if BX_DECK_M - yb > 2.0:
			for z in [-2.8, 2.8]:
				lm.box("Concrete", Vector3(x, (yb + BX_DECK_M) * 0.5, z), Vector3(1.2, BX_DECK_M - yb, 1.2))
			lm.box("Concrete", Vector3(x, (yb + BX_DECK_M) * 0.5, 0), Vector3(0.8, 0.8, 5.6))
		x += 7.0
	# Tall paired piers beyond the arch, from below the bank to the deck.
	for s in [-1.0, 1.0]:
		for px in [half, half + 15.0, half + 30.0, half + 45.0]:
			var pxs: float = s * float(px)
			var base := -10.0 if px == half else -10.0 + (float(px) - half) * 0.9
			for z in [-2.8, 2.8]:
				lm.box("Concrete", Vector3(pxs, (base + BX_DECK_M) * 0.5, z),
					Vector3(3.0 if px == half else 1.8, BX_DECK_M - base, 2.2))
			var y := base + 12.0
			while y < BX_DECK_M - 4.0:
				lm.box("Concrete", Vector3(pxs, y, 0), Vector3(1.4, 1.2, 5.6))
				y += 12.0
	# Deck, fascia beams and the railings.
	lm.box("Deck", Vector3(0, BX_DECK_M + 0.15, 0), Vector3(BX_LENGTH, 0.3, BX_HALF_W * 2.0))
	lm.box("Concrete", Vector3(0, BX_DECK_M - 0.8, 0), Vector3(BX_LENGTH, 1.6, BX_HALF_W * 2.0 + 0.4))
	for z in [-BX_HALF_W, BX_HALF_W]:
		lm.box("Concrete", Vector3(0, BX_TOP_M - 0.1, z), Vector3(BX_LENGTH, 0.2, 0.3))
		var rx := -BX_LENGTH * 0.5
		while rx <= BX_LENGTH * 0.5:
			lm.box("Concrete", Vector3(rx, (BX_DECK_M + BX_TOP_M) * 0.5, z), Vector3(0.3, BX_TOP_M - BX_DECK_M, 0.3))
			rx += 3.0
	lm.commit(model)
