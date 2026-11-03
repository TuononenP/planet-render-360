extends RefCounted

## Riddarfjärdsbron, the main part of Västerbron: two deck-supported
## steel arches, southern 204 m / 24 m rise and northern 168 m / 20 m
## rise, 602 m overall and 26 m wide. Opened 1935. The bridge is built
## along +X from south to north, with y=0 at the water. Dimensions:
## https://www.diva-portal.org/smash/get/diva2:827161/FULLTEXT01.pdf
## Axis and centre estimated from OpenStreetMap way 386452685.
const DECK_Y := 50.0
const HALF_WIDTH := 13.0
const END := 301.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#788184", "#aaa79c")
	# Each arch is a pair of plate ribs with vertical spandrel columns.
	_arch(lm, -186.0, 18.0, 24.0)
	_arch(lm, 18.0, 186.0, 20.0)
	LandmarkBrKit.deck_girder(lm, -186.0, 186.0, DECK_Y, HALF_WIDTH, 2.4)
	# Steel girder approaches and their concrete supports.
	for side: float in [-1.0, 1.0]:
		var inner: float = side * 186.0
		var outer: float = side * END
		var a := Vector3(inner, DECK_Y - 0.5, 0)
		var b := Vector3(outer, 40.0, 0)
		lm.beam("Steel", a, b, HALF_WIDTH * 2.0 - 2.0, 2.0, Vector3(0, 0, 1))
		lm.beam("Deck", a + Vector3.UP * 0.75, b + Vector3.UP * 0.75,
			HALF_WIDTH * 2.0, 0.5, Vector3(0, 0, 1))
		var x: float = side * 245.0
		lm.box("Concrete", Vector3(x, 18.5, 0), Vector3(4.0, 37.0, 22.0))
	for x in [-186.0, 18.0, 186.0]:
		lm.box("Concrete", Vector3(x, 12.5, 0), Vector3(6.0, 25.0, 22.0))
	for z in [-HALF_WIDTH + 0.2, HALF_WIDTH - 0.2]:
		LandmarkBrKit.railing(lm, "Steel", Vector3(-186, DECK_Y, z), Vector3(186, DECK_Y, z), 1.2, 4.0)
		for side: float in [-1.0, 1.0]:
			LandmarkBrKit.railing(lm, "Steel", Vector3(side * 186, DECK_Y, z),
				Vector3(side * END, 40.5, z), 1.2, 4.0)
	lm.commit(model)

static func _arch(lm: LandmarkMesh, a: float, b: float, rise: float) -> void:
	var spring := 48.0 - rise
	var segments := 32
	for z in [-10.0, 10.0]:
		var previous := Vector3(a, spring, z)
		for i in range(1, segments + 1):
			var t := float(i) / float(segments)
			var x := lerpf(a, b, t)
			var y := spring + rise * 4.0 * t * (1.0 - t)
			var next := Vector3(x, y, z)
			lm.beam("Steel", previous, next, 1.5, 2.2, Vector3(0, 0, 1))
			if i < segments and i % 2 == 0:
				lm.beam("Steel", next, Vector3(x, DECK_Y - 1.0, z), 0.7, 0.7)
			previous = next
	# Lateral bracing links the two ribs beneath the deck.
	for i in range(1, 8):
		var t := float(i) / 8.0
		var x := lerpf(a, b, t)
		var y := spring + rise * 4.0 * t * (1.0 - t)
		lm.beam("Steel", Vector3(x, y, -10.0), Vector3(x, y, 10.0), 0.6, 0.6)
