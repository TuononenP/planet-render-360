class_name BridgeParam
extends RefCounted

## Builds a capital bridge from its BridgeSpec row, in true metres along +X
## centred on the origin, y = 0 at the water (like the hand-built bridges of
## LandmarkSetBridges). This is the dispatcher and the parts every family
## shares: materials, the deck slab, edge railings, supports and abutments.
## The structure itself lives in BridgeParamCable (suspension, cable-stayed),
## BridgeParamArch, BridgeParamBeam (girder, truss) and BridgeParamMasonry.
## Six surface keys at most, so a bridge stays within the model part budget:
## Steel (the structure: steel, iron or painted concrete), Deck, Concrete,
## Stone, and the road's Paving (footways) and Line (centre dashes).

## Triangle budget of one bridge; the railings are thinned to stay inside it.
const MAX_TRIS := 6000
## Deck slab thickness, metres.
const SLAB_M := 0.5

static func build(model: Node3D, row: Dictionary) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm, row)
	match str(row["st"]):
		"masonry": BridgeParamMasonry.build(lm, row)
		"arch_deck": BridgeParamArch.deck(lm, row)
		"arch_through", "arch_tied": BridgeParamArch.through(lm, row)
		"girder": BridgeParamBeam.girder(lm, row)
		"truss": BridgeParamBeam.truss(lm, row)
		"susp": BridgeParamCable.suspension(lm, row)
		"stayed": BridgeParamCable.stayed(lm, row)
		"bascule": BridgeParamBeam.bascule(lm, row)
		"haunched": BridgeParamBeam.haunched(lm, row)
		"extradosed": BridgeParamCable.extradosed(lm, row)
		"lateral": BridgeParamCable.lateral(lm, row)
		"swing": BridgeParamMovable.swing(lm, row)
		"lift": BridgeParamMovable.lift(lm, row)
		"pontoon": BridgeParamMovable.pontoon(lm, row)
		_: BridgeParamBeam.girder(lm, row)
	lm.commit(model)

static func _materials(lm: LandmarkMesh, row: Dictionary) -> void:
	var steel := "#6E777B"
	match str(row.get("material", "steel")):
		"iron": steel = "#44504A"
		"concrete": steel = "#BDB8AE"
		"stone": steel = "#A79E8C"
	lm.use("Steel", LandmarkMaterials.paint(steel, 0.58, 0.35))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B9B3A8", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B9B09C", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#9A958A", 3.0))
	lm.use("Line", LandmarkMaterials.paint("#E8E6DE", 0.8, 0.0))

## Support positions along x (the two ends and every pier / tower between):
## cumulative span lengths about the centre.
static func supports(row: Dictionary) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var x := -BridgeSpec.length_m(row) * 0.5
	out.append(x)
	for s in row["spans"]:
		x += float(s)
		out.append(x)
	return out

static func half_length(row: Dictionary) -> float:
	return BridgeSpec.length_m(row) * 0.5

## Railing step for a deck of this length, wide enough to hold MAX_TRIS.
static func rail_step(length: float) -> float:
	return clampf(length / 70.0, 3.0, 16.0)

## Road slab from x0 to x1 with its top at y, `width` wide.
static func slab(lm: LandmarkMesh, x0: float, x1: float, y: float, width: float) -> void:
	lm.box("Deck", Vector3((x0 + x1) * 0.5, y - SLAB_M * 0.5, 0), Vector3(x1 - x0, SLAB_M, width), Basis(), 0.0)

## Footways along both edges of a road at least 12 m wide and a dashed centre
## line on one at least 7 m wide, on a deck whose top is at y. The dashes thin
## out on a long deck so the triangle budget holds.
static func markings(lm: LandmarkMesh, x0: float, x1: float, y: float, width: float) -> void:
	var length := x1 - x0
	if width >= 12.0:
		var f := minf(3.0, width * 0.14)
		for z in [-1.0, 1.0]:
			lm.box("Paving", Vector3((x0 + x1) * 0.5, y + 0.03, z * (width * 0.5 - 0.6 - f * 0.5)),
				Vector3(length, 0.06, f), Basis(), 0.0)
	if width >= 7.0:
		var step := maxf(9.0, length / 80.0)
		var dash := minf(3.0, step * 0.4)
		var x := x0 + step * 0.5
		while x < x1 - dash:
			lm.box("Line", Vector3(x + dash * 0.5, y + 0.06, 0), Vector3(dash, 0.04, 0.16), Basis(), 0.0)
			x += step

## Railings along both deck edges (top at y + PARAPET_M).
static func rails(lm: LandmarkMesh, key: String, x0: float, x1: float, y: float, width: float) -> void:
	var step := rail_step(x1 - x0)
	for z in [-width * 0.5 + 0.1, width * 0.5 - 0.1]:
		LandmarkBrKit.railing(lm, key, Vector3(x0, y, z), Vector3(x1, y, z), BridgeSpec.PARAPET_M - 0.07, step)

## A solid parapet wall along both deck edges, top at y + PARAPET_M.
static func parapets(lm: LandmarkMesh, key: String, x0: float, x1: float, y: float, width: float) -> void:
	for z in [-width * 0.5 + 0.3, width * 0.5 - 0.3]:
		lm.box(key, Vector3((x0 + x1) * 0.5, y + BridgeSpec.PARAPET_M * 0.5, z),
			Vector3(x1 - x0, BridgeSpec.PARAPET_M, 0.6), Basis(), 0.0)

## Closed box girder under the road: `depth` deep including the slab.
static func box_girder(lm: LandmarkMesh, key: String, x0: float, x1: float, y: float, width: float,
		depth: float) -> void:
	slab(lm, x0, x1, y, width)
	markings(lm, x0, x1, y, width)
	lm.box(key, Vector3((x0 + x1) * 0.5, y - SLAB_M - (depth - SLAB_M) * 0.5, 0),
		Vector3(x1 - x0, depth - SLAB_M, width * 0.82), Basis(), 0.0)

## Concrete abutment block under each end of the deck, from the water up to
## the girder soffit, 6 m deep along the bridge.
static func abutments(lm: LandmarkMesh, row: Dictionary, soffit: float) -> void:
	var h := half_length(row)
	var width := float(row["width"])
	if soffit < 0.8:
		return
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(s * (h - 3.0), soffit * 0.5, 0), Vector3(6.0, soffit, width * 0.9), Basis(), 0.0)

## Pier under an interior support at x: a tapering shaft from the water to
## the soffit, `across` wide.
static func pier(lm: LandmarkMesh, key: String, x: float, soffit: float, along: float, across: float) -> void:
	if soffit < 0.8:
		return
	LandmarkBrKit.tapered_box(lm, key, Vector3(x, 0, 0), along, across, along * 0.75, across * 0.85, soffit)
