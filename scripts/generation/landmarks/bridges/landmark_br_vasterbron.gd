extends RefCounted

## Riddarfjärdsbron, the main part of Västerbron: two deck-supported
## steel arches, southern 204 m and northern 168 m span,
## 602 m overall and 26 m wide. Opened 1935. The bridge is built
## along +X from south to north, with y=0 at the water. Dimensions:
## https://www.diva-portal.org/smash/get/diva2:827161/FULLTEXT01.pdf
## Axis and centre estimated from OpenStreetMap way 386452685.
## Form checked against the reference photos: both arches spring from the
## squat mid-river pier close to the water (rib crown meets the deck
## girder, rise about 34 m at 1:6), their outer feet land on the shore
## rock a little higher; slim spandrel columns carry the deck; the steel
## approach girders run on a row of slender concrete bents; tall double
## arm lamp standards line both kerbs (the lit necklace at night).
const DECK_Y := 43.0
const HALF_WIDTH := 13.0
const END := 301.0
## Approach deck height at the shore ends, and the girder depth.
const END_Y := 35.0
const GIRDER := 2.4
## Rib springing heights: [x, y] at the south foot, the mid-river pier and
## the north foot.
const FOOT_S := Vector2(-186.0, 9.0)
const FOOT_M := Vector2(18.0, 5.5)
const FOOT_N := Vector2(186.0, 7.0)
const LAMP_STEP := 31.0
const LAMP_H := 7.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#788184", "#aaa79c")
	lm.use("Lamp", LandmarkMaterials.lit("#FFE6B4", 0.9))
	# Each arch is a pair of plate ribs with vertical spandrel columns.
	_arch(lm, FOOT_S, FOOT_M)
	_arch(lm, FOOT_M, FOOT_N)
	LandmarkBrKit.deck_girder(lm, -186.0, 186.0, DECK_Y, HALF_WIDTH, GIRDER)
	# Steel girder approaches on slender concrete bents.
	for side: float in [-1.0, 1.0]:
		var inner: float = side * 186.0
		var outer: float = side * END
		var a := Vector3(inner, DECK_Y - 0.5, 0)
		var b := Vector3(outer, END_Y, 0)
		lm.beam("Steel", a, b, HALF_WIDTH * 2.0 - 2.0, 2.0, Vector3(0, 0, 1))
		lm.beam("Deck", a + Vector3.UP * 0.75, b + Vector3.UP * 0.75,
			HALF_WIDTH * 2.0, 0.5, Vector3(0, 0, 1))
		for k in range(1, 6):
			_bent(lm, side * (186.0 + 23.0 * float(k)), 2.2)
	_piers(lm)
	for z in [-HALF_WIDTH + 0.2, HALF_WIDTH - 0.2]:
		LandmarkBrKit.railing(lm, "Steel", Vector3(-186, DECK_Y, z), Vector3(186, DECK_Y, z), 1.2, 4.0)
		for side: float in [-1.0, 1.0]:
			LandmarkBrKit.railing(lm, "Steel", Vector3(side * 186, DECK_Y, z),
				Vector3(side * END, END_Y + 0.5, z), 1.2, 4.0)
	_lamps(lm)
	lm.commit(model)

## Deck level (road top) at x: level over the arches, falling to the ends.
static func _deck_y(x: float) -> float:
	var d := absf(x)
	return DECK_Y if d <= 186.0 else lerpf(DECK_Y, END_Y + 0.5, clampf((d - 186.0) / (END - 186.0), 0.0, 1.0))

## Rib centre-line height at parameter t of the arch from foot `a` to foot
## `b`: a parabola whose crown reaches up under the deck girder.
static func _rib_y(a: Vector2, b: Vector2, t: float) -> float:
	var crown := DECK_Y - GIRDER - 1.0
	var k := crown - (a.y + b.y) * 0.5
	return lerpf(a.y, b.y, t) + k * 4.0 * t * (1.0 - t)

## One arch from foot `a` to foot `b` (x, spring y): two plate ribs,
## deepest at the feet and slimmest at the crown, with spandrel columns
## up to the deck girder and lateral bracing between the ribs.
static func _arch(lm: LandmarkMesh, a: Vector2, b: Vector2) -> void:
	var segments := 32
	for z in [-10.0, 10.0]:
		var previous := Vector3(a.x, a.y, z)
		for i in range(1, segments + 1):
			var t := float(i) / float(segments)
			var x := lerpf(a.x, b.x, t)
			var next := Vector3(x, _rib_y(a, b, t), z)
			var tm := (float(i) - 0.5) / float(segments)
			var depth := 1.6 + 1.8 * pow(absf(2.0 * tm - 1.0), 2.0)
			lm.beam("Steel", previous, next, 2.0, depth, Vector3(0, 0, 1))
			if i < segments and i % 2 == 0:
				var top := DECK_Y - GIRDER
				if top - next.y > 1.8:
					lm.beam("Steel", next, Vector3(x, top, z), 0.9, 0.9)
			previous = next
	# Lateral bracing links the two ribs beneath the deck.
	for i in range(1, 8):
		var t := float(i) / 8.0
		var x := lerpf(a.x, b.x, t)
		var y := _rib_y(a, b, t)
		lm.beam("Steel", Vector3(x, y, -10.0), Vector3(x, y, 10.0), 0.6, 0.6)
		if i < 7:
			var t1 := float(i + 1) / 8.0
			var x1 := lerpf(a.x, b.x, t1)
			var y1 := _rib_y(a, b, t1)
			lm.beam("Steel", Vector3(x, y, -10.0), Vector3(x1, y1, 10.0), 0.4, 0.4)
			lm.beam("Steel", Vector3(x, y, 10.0), Vector3(x1, y1, -10.0), 0.4, 0.4)

## The three piers: the shore-end columns carrying the arch feet and the
## squat mid-river block the two arches spring from.
static func _piers(lm: LandmarkMesh) -> void:
	for x in [-186.0, 186.0]:
		for z in [-10.0, 10.0]:
			lm.box("Concrete", Vector3(x, (DECK_Y - GIRDER) * 0.5, z), Vector3(4.0, DECK_Y - GIRDER, 3.4))
	lm.box("Concrete", Vector3(FOOT_M.x, 4.5, 0), Vector3(9.0, 9.0, 25.0))
	# Mid pier columns up to the deck between the two arch crowns.
	for z in [-10.0, 10.0]:
		lm.box("Concrete", Vector3(FOOT_M.x, (DECK_Y - GIRDER) * 0.5, z), Vector3(3.0, DECK_Y - GIRDER, 2.4))

## A slender approach bent at x: two columns under the girder and a cap.
static func _bent(lm: LandmarkMesh, x: float, w: float) -> void:
	var top := _deck_y(x) - 2.5
	for z in [-8.0, 8.0]:
		lm.box("Concrete", Vector3(x, top * 0.5, z), Vector3(w, top, w))
	lm.box("Concrete", Vector3(x, top - 0.5, 0), Vector3(2.4, 1.0, 20.0))

## Tall double-arm lamp standards along both kerbs, the arms reaching
## over the carriageway, a lit head on each.
static func _lamps(lm: LandmarkMesh) -> void:
	var x := -END + 8.0
	while x < END - 4.0:
		var y := _deck_y(x)
		for s: float in [-1.0, 1.0]:
			var z := s * (HALF_WIDTH - 0.6)
			lm.frustum("Steel", Vector3(x, y, z), 0.16, 0.1, LAMP_H, 6)
			var top := Vector3(x, y + LAMP_H, z)
			lm.beam("Steel", top, top + Vector3(0, 0.5, -s * 2.4), 0.1, 0.1)
			lm.box("Lamp", top + Vector3(0, 0.45, -s * 2.5), Vector3(1.5, 0.3, 0.6))
			lm.beam("Steel", top, top + Vector3(0, 0.3, s * 1.4), 0.08, 0.08)
			lm.box("Lamp", top + Vector3(0, 0.25, s * 1.5), Vector3(1.2, 0.26, 0.5))
		x += LAMP_STEP
