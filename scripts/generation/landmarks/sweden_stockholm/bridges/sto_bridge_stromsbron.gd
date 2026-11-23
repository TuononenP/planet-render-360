class_name StoBridgeStromsbron
extends RefCounted

## Strömbron (1946, Gustav Adolfs torg to Helgeandsholmen): the parametric
## eleven-span girder deck of its BridgeSpecs row (BridgeParam) plus what the
## table cannot carry, from visual-plan/refs/landmarks/stromsbron:
## - pale concrete fascia beams along both deck edges and a granite kerb
##   between each footway and the carriageway, solid edge lines on the road
## - a galvanised steel balustrade both sides: bar infill between a flat top
##   rail and a mid rail, 1.2 m high
## - white lamp standards 8.5 m tall on alternate sides, each with one arm
##   reaching over the carriageway and a white dome luminaire
## - four granite parapet piers (square posts with a cap) where the balustrade
##   meets the quays, joined to it by a short granite parapet
## - a pale waterline band round the foot of every pyramidal pier plinth
## No tram rails: the bridge carries buses and cars only.
## Surface keys of the extras: Rail, Pole, Lamp, Fascia, Granite, Edge, Band.

const LAMP_PITCH_M := 27.0
## Pole height when the row has no `orn`; with it the dome tops out at `orn`.
const LAMP_H := 8.5
## The waterline band: height and how far it stands proud of the plinth, metres.
const BAND_H := 0.6
const BAND_PROUD := 0.05
const ARM_M := 1.9
const BAR_PITCH_M := 2.2
## Carriageway edge, metres from the axis: inside the 2.8 m footway.
const ROAD_EDGE_M := 6.55

static func build(model: Node3D, row: Dictionary) -> void:
	BridgeParam.build(model, row)
	var lm := LandmarkMesh.new()
	lm.use("Rail", LandmarkMaterials.paint("#9EA6A8", 0.45, 0.6))
	lm.use("Pole", LandmarkMaterials.paint("#ECEFF0", 0.4, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF0D0", 0.9))
	lm.use("Fascia", LandmarkMaterials.pbr("concrete", "#B7B3A9", 4.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8C8780", 3.0))
	lm.use("Edge", LandmarkMaterials.paint("#EDEBE3", 0.8, 0.0))
	lm.use("Band", LandmarkMaterials.pbr("concrete", "#D9D7CF", 4.0))
	var c := float(row["clear"])
	var width := float(row["width"])
	var h := BridgeParam.half_length(row)
	var segs := 9
	for s in [-1.0, 1.0]:
		var z: float = float(s) * (width * 0.5 - 0.2)
		# Fascia beam, kerb and edge line (segmented so BridgeCamber stays within budget).
		for k in segs:
			var xa := lerpf(-h, h, float(k) / float(segs))
			var xb := lerpf(-h, h, float(k + 1) / float(segs))
			var xm := (xa + xb) * 0.5
			var seg_l := xb - xa
			lm.box("Fascia", Vector3(xm, c - 0.55, float(s) * (width * 0.5 - 0.3)), Vector3(seg_l, 1.1, 0.6), Basis(), 0.0)
			lm.box("Granite", Vector3(xm, c + 0.07, float(s) * (ROAD_EDGE_M + 0.1)), Vector3(seg_l, 0.14, 0.24), Basis(), 0.0)
			lm.box("Edge", Vector3(xm, c + 0.03, float(s) * (ROAD_EDGE_M - 0.35)), Vector3(seg_l, 0.04, 0.14), Basis(), 0.0)
		_balustrade(lm, -h + 1.0, h - 1.0, c, z)
		for e in [-1.0, 1.0]:
			_parapet_pier(lm, float(e) * (h - 0.6), c, z)
			var x0: float = float(e) * (h - 0.6)
			lm.box("Granite", Vector3(x0 - float(e) * 2.6, c + 0.55, z), Vector3(5.0, 1.1, 0.4), Basis(), 0.0)
	var n := int(floor((h * 2.0 - 24.0) / LAMP_PITCH_M)) + 1
	for i in n:
		var x := -float(n - 1) * 0.5 * LAMP_PITCH_M + float(i) * LAMP_PITCH_M
		var side := 1.0 if i % 2 == 0 else -1.0
		_lamp(lm, Vector3(x, c, side * (width * 0.5 - 0.7)), -side, float(row.get("orn", LAMP_H + 0.15)) - 0.15)
	_bands(lm, row, c - BridgeParamBeam.girder_depth(row))
	BridgeCamber.apply(lm, h, c, float(row.get("camber", 0.0)), float(row.get("tilt", 0.0)))
	lm.commit(model)

## Bar balustrade from x0 to x1 along z: flat top rail, mid rail, bars.
static func _balustrade(lm: LandmarkMesh, x0: float, x1: float, y: float, z: float) -> void:
	var segs := 9
	for k in segs:
		var xa := lerpf(x0, x1, float(k) / float(segs))
		var xb := lerpf(x0, x1, float(k + 1) / float(segs))
		var xm := (xa + xb) * 0.5
		var seg_l := xb - xa
		lm.box("Rail", Vector3(xm, y + 1.17, z), Vector3(seg_l, 0.06, 0.16), Basis(), 0.0)
		lm.box("Rail", Vector3(xm, y + 0.62, z), Vector3(seg_l, 0.05, 0.05), Basis(), 0.0)
		lm.box("Rail", Vector3(xm, y + 0.14, z), Vector3(seg_l, 0.05, 0.05), Basis(), 0.0)
	var centres := PackedVector3Array()
	var sizes := PackedVector3Array()
	var n := int((x1 - x0) / BAR_PITCH_M)
	for i in n + 1:
		var post := i % 3 == 0
		centres.append(Vector3(x0 + (x1 - x0) * float(i) / float(n), y + 0.58, z))
		sizes.append(Vector3(0.1, 1.16, 0.1) if post else Vector3(0.03, 1.1, 0.03))
	lm.boxes("Rail", centres, sizes, Basis(), 0.0)

## Square granite post with a cap, 1.6 m over the deck.
static func _parapet_pier(lm: LandmarkMesh, x: float, y: float, z: float) -> void:
	lm.box("Granite", Vector3(x, y + 0.8, z), Vector3(0.9, 1.6, 0.9), Basis(), 0.0)
	lm.box("Granite", Vector3(x, y + 1.68, z), Vector3(1.1, 0.16, 1.1), Basis(), 0.0)
	lm.spire("Granite", Vector3(x, y + 1.76, z), 0.4, 0.22, 0.0)

## White standard at `base` with its arm reaching toward `inward` (+-Z) and a
## dome luminaire at the end.
static func _lamp(lm: LandmarkMesh, base: Vector3, inward: float, pole_h: float) -> void:
	lm.lathe("Pole", base, PackedVector2Array([Vector2(0.16, 0.0), Vector2(0.12, 0.5), Vector2(0.08, pole_h)]), 8)
	lm.box("Pole", base + Vector3(0, 0.5, 0), Vector3(0.34, 1.0, 0.34), Basis(), 0.0)
	var top := base + Vector3(0, pole_h - 0.1, 0)
	var tip := top + Vector3(0, 0.25, inward * ARM_M)
	lm.beam("Pole", top, tip, 0.07, 0.07)
	lm.lathe("Pole", tip - Vector3(0, 0.3, 0), PackedVector2Array([Vector2(0.34, 0.0),
		Vector2(0.3, 0.1), Vector2(0.14, 0.26), Vector2(0.0, 0.3)]), 8)
	lm.disc("Lamp", tip - Vector3(0, 0.31, 0), Vector3.DOWN, 0.27, 8)

## The pale band at the waterline of each pier plinth, following BridgeParam's
## taper (half-width 1.4 + span/100 along the bridge, 0.3 of the width across,
## to 0.75 and 0.85 of that at the soffit `soffit` m up).
static func _bands(lm: LandmarkMesh, row: Dictionary, soffit: float) -> void:
	if soffit < 0.8:
		return
	var along := 1.4 + BridgeSpec.widest_span(row) * 0.01
	var across := float(row["width"]) * 0.3
	var t := minf(BAND_H / soffit, 1.0)
	var xs := BridgeParam.supports(row)
	for i in range(1, xs.size() - 1):
		LandmarkBrKit.tapered_box(lm, "Band", Vector3(xs[i], 0.0, 0), along + BAND_PROUD, across + BAND_PROUD,
			along * lerpf(1.0, 0.75, t) + BAND_PROUD, across * lerpf(1.0, 0.85, t) + BAND_PROUD, BAND_H)
