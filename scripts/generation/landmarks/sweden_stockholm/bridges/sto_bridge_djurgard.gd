class_name StoBridgeDjurgard
extends RefCounted

## Djurgardsbron (1896-97, Carl Fraenell; abutments and candelabras by Erik
## Josephson), built from its BridgeSpecs row (br_stockholm_djurgardsbron) so
## a deck fitted to low banks (BridgeSpec.fitted) still works. Along +X, y = 0
## at the water, deck top at the row's `clear`, 18 m wide, 58 m long.
## Spec from visual-plan/refs/landmarks/djurgardsbron and sv/en Wikipedia:
## - three shallow segmental plate-girder arches in pale blue-grey iron, deep
##   at the piers and slender at mid-span, open Warren web above the arch
##   band, two round granite drum piers with a flared cap
## - 3 lanes with the Djurgardslinjen tram tracks between two broad footways,
##   each fenced from the roadway by a low iron rail, pierced cast-iron
##   parapets (rail, balusters, plinth)
## - four tapering granite columns at the abutment corners, each with a ringed
##   shaft, a bronze garland collar, three lamps and a zinc Norse god on top:
##   Heimdal with the Gjallarhorn and Frigg with a staff at the north (-X)
##   end, Freyja with a falcon and Thor with Mjolnir at the south (+X) end
## - iron candelabra standards, three lamps each, along both parapets
## Surface keys: Girder, Iron, Granite, Deck, Paving, Bronze, Lamp.

const FOOTWAY_M := 4.0
const COLUMN_BASE_M := 1.0
const COLUMN_SHAFT_M := 3.9
const GOD_M := 2.1
const LAMP_STANDARD_M := 4.6
const PANELS := 6

## Plan positions (x along the bridge, z across) of the four god columns.
static func column_positions(row: Dictionary) -> Array[Vector2]:
	var h := BridgeParam.half_length(row)
	var z := float(row["width"]) * 0.5 - 1.0
	var x := h - 1.8
	return [Vector2(-x, -z), Vector2(-x, z), Vector2(x, -z), Vector2(x, z)]

static func build(model: Node3D, row: Dictionary) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm, row)
	var h := BridgeParam.half_length(row)
	var c := float(row["clear"])
	var width := float(row["width"])
	var xs := BridgeParam.supports(row)
	var d_p := minf(2.4, c * 0.5)
	var d_m := d_p * 0.45
	_deck(lm, h, c, width)
	for i in xs.size() - 1:
		_girder_span(lm, xs[i], xs[i + 1], c, width, d_p, d_m)
	for i in range(1, xs.size() - 1):
		_pier(lm, xs[i], c - d_p - 0.05, width)
	_railings(lm, h, c, width)
	_tram_tracks(lm, h, c)
	var gods := ["heimdal", "frigg", "freyja", "thor"]
	var pos := column_positions(row)
	for k in 4:
		_column(lm, Vector3(pos[k].x, c, pos[k].y), gods[k], signf(pos[k].x))
	for z in [-width * 0.5 + 0.3, width * 0.5 - 0.3]:
		for x in [-h + 9.0, xs[1], xs[2], h - 9.0]:
			_candelabrum(lm, Vector3(x, c, z))
	BridgeCamber.apply(lm, h, c, float(row.get("camber", 0.0)), float(row.get("tilt", 0.0)))
	lm.commit(model)

static func _materials(lm: LandmarkMesh, row: Dictionary) -> void:
	lm.use("Girder", LandmarkMaterials.paint(str(row.get("steel_hex", "#8F9AA3")), 0.55, 0.3))
	lm.use("Iron", LandmarkMaterials.paint("#2D3236", 0.5, 0.45))
	lm.use("Granite", LandmarkMaterials.pbr("limestone", str(row.get("concrete_hex", "#8A857C")), 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#9A958A", 3.0))
	lm.use("Bronze", LandmarkMaterials.paint("#33372F", 0.45, 0.55))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 0.9))

## Roadway slab and the two footways over it, top of the slab at `c`.
static func _deck(lm: LandmarkMesh, h: float, c: float, width: float) -> void:
	lm.box("Deck", Vector3(0, c - 0.25, 0), Vector3(2.0 * h, 0.5, width), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Paving", Vector3(0, c + 0.04, s * (width * 0.5 - FOOTWAY_M * 0.5)),
			Vector3(2.0 * h, 0.08, FOOTWAY_M), Basis(), 0.0)

## Lower flange height of the girder at x in the span x0..x1: deep over the
## piers, shallow at mid-span.
static func _soffit(x: float, x0: float, x1: float, c: float, d_p: float, d_m: float) -> float:
	var u := absf(x - (x0 + x1) * 0.5) / ((x1 - x0) * 0.5)
	return c - 0.5 - (d_m + (d_p - d_m) * u * u)

static func _girder_span(lm: LandmarkMesh, x0: float, x1: float, c: float, width: float, d_p: float,
		d_m: float) -> void:
	var top := c - 0.5
	var segs := 8
	for z in [-width * 0.5 + 0.35, width * 0.5 - 0.35]:
		# Top chord and the deeper arched lower band.
		lm.beam("Girder", Vector3(x0, top - 0.1, z), Vector3(x1, top - 0.1, z), 0.45, 0.5)
		var prev := Vector3(x0, _soffit(x0, x0, x1, c, d_p, d_m), z)
		for k in range(1, segs + 1):
			var x := lerpf(x0, x1, float(k) / segs)
			var p := Vector3(x, _soffit(x, x0, x1, c, d_p, d_m), z)
			lm.beam("Girder", prev, p, 0.5, 0.55)
			prev = p
		# Web: a post at every panel point, a diagonal in every panel.
		for k in range(0, PANELS + 1):
			var x := lerpf(x0, x1, float(k) / PANELS)
			lm.beam("Girder", Vector3(x, _soffit(x, x0, x1, c, d_p, d_m), z), Vector3(x, top, z), 0.3, 0.3)
			if k < PANELS:
				var xn := lerpf(x0, x1, float(k + 1) / PANELS)
				var a := Vector3(x, top, z)
				var b := Vector3(xn, _soffit(xn, x0, x1, c, d_p, d_m), z)
				if k >= PANELS / 2:
					a = Vector3(x, _soffit(x, x0, x1, c, d_p, d_m), z)
					b = Vector3(xn, top, z)
				lm.beam("Girder", a, b, 0.22, 0.22)
	# The belly plate carrying the roadway between the fascias.
	for k in segs:
		var xa := lerpf(x0, x1, float(k) / segs)
		var xb := lerpf(x0, x1, float(k + 1) / segs)
		var y := _soffit((xa + xb) * 0.5, x0, x1, c, d_p, d_m)
		lm.box("Girder", Vector3((xa + xb) * 0.5, y + 0.2, 0), Vector3(xb - xa, 0.4, width - 1.4), Basis(), 0.0)

## Round granite drum pier under a support at x, flared at the cap.
static func _pier(lm: LandmarkMesh, x: float, top: float, width: float) -> void:
	if top < 0.6:
		return
	var r := width * 0.24
	var prof := PackedVector2Array([Vector2(r, 0.0), Vector2(r * 0.96, top - 0.9), Vector2(r * 1.06, top - 0.6),
		Vector2(r * 1.06, top - 0.25), Vector2(r * 0.9, top)])
	lm.lathe("Granite", Vector3(x, 0, 0), prof, 16, 0.55, 1.0)

static func _railings(lm: LandmarkMesh, h: float, c: float, width: float) -> void:
	var step := 2.4
	var n := int(round(2.0 * h / step))
	for z in [-width * 0.5 + 0.12, width * 0.5 - 0.12]:
		lm.beam("Iron", Vector3(-h, c + 1.13, z), Vector3(h, c + 1.13, z), 0.16, 0.12)
		lm.beam("Iron", Vector3(-h, c + 0.95, z), Vector3(h, c + 0.95, z), 0.07, 0.06)
		lm.beam("Iron", Vector3(-h, c + 0.35, z), Vector3(h, c + 0.35, z), 0.1, 0.1)
		lm.beam("Iron", Vector3(-h, c + 0.2, z), Vector3(h, c + 0.2, z), 0.2, 0.18)
		for k in n + 1:
			var x := -h + 2.0 * h * float(k) / n
			lm.beam("Iron", Vector3(x, c + 0.2, z), Vector3(x, c + 1.13, z), 0.1, 0.08)
	# Low rails between each footway and the roadway.
	for z in [-width * 0.5 + FOOTWAY_M, width * 0.5 - FOOTWAY_M]:
		lm.beam("Iron", Vector3(-h, c + 1.0, z), Vector3(h, c + 1.0, z), 0.07, 0.07)
		var m := int(round(2.0 * h / 5.0))
		for k in m + 1:
			var x := -h + 2.0 * h * float(k) / m
			lm.beam("Iron", Vector3(x, c, z), Vector3(x, c + 1.0, z), 0.07, 0.07)

## The two Djurgardslinjen tram tracks (standard gauge) in the roadway.
static func _tram_tracks(lm: LandmarkMesh, h: float, c: float) -> void:
	for t in [-1.9, 1.9]:
		for g in [-0.7175, 0.7175]:
			lm.box("Iron", Vector3(0, c + 0.04, t + g), Vector3(2.0 * h, 0.08, 0.07), Basis(), 0.0)

## One granite column at `base` (deck level): square plinth, ringed tapering
## shaft, bronze garland collar, three lamps, capital and the zinc god.
## `dir` is the sign of x toward the bridge's far end (the god looks along it).
static func _column(lm: LandmarkMesh, base: Vector3, god: String, dir: float) -> void:
	var inward := -dir
	lm.box("Granite", base + Vector3(0, COLUMN_BASE_M * 0.5, 0), Vector3(2.3, COLUMN_BASE_M, 2.3), Basis(), 0.0)
	var y0 := COLUMN_BASE_M
	var shaft := PackedVector2Array([Vector2(0.98, y0), Vector2(0.98, y0 + 0.25), Vector2(0.78, y0 + 0.4),
		Vector2(0.7, y0 + COLUMN_SHAFT_M - 0.3), Vector2(0.92, y0 + COLUMN_SHAFT_M - 0.15),
		Vector2(0.92, y0 + COLUMN_SHAFT_M)])
	lm.lathe("Granite", base, shaft, 12)
	# Bronze garland collar, then the lamp brackets.
	lm.lathe("Bronze", base + Vector3(0, y0 + COLUMN_SHAFT_M * 0.62, 0),
		PackedVector2Array([Vector2(0.8, 0.0), Vector2(0.92, 0.12), Vector2(0.92, 0.38), Vector2(0.78, 0.5)]), 12)
	var lamp_y := y0 + COLUMN_SHAFT_M * 0.62 + 0.5
	for a in [-1.0, 0.0, 1.0]:
		var arm := base + Vector3(inward * 0.45 * absf(a), lamp_y + 0.1, a * 1.1)
		lm.beam("Iron", base + Vector3(0, lamp_y - 0.1, a * 0.7), arm, 0.07, 0.07)
		lm.box("Lamp", arm + Vector3(0, 0.3, 0), Vector3(0.32, 0.42, 0.32), Basis(), 0.0)
		lm.spire("Iron", arm + Vector3(0, 0.51, 0), 0.2, 0.2, 0.03)
	_god(lm, base + Vector3(0, y0 + COLUMN_SHAFT_M, 0), god, dir)

## Zinc god standing on a column top, about GOD_M tall.
static func _god(lm: LandmarkMesh, at: Vector3, god: String, dir: float) -> void:
	LandmarkBrKit.figure(lm, "Bronze", at, GOD_M)
	var f := Vector3(dir, 0, 0)
	var head := at + Vector3(0, GOD_M * 0.92, 0)
	match god:
		"heimdal":
			# Gjallarhorn raised to the lips.
			lm.beam("Bronze", head + Vector3(0, -0.1, 0), head + f * 0.5 + Vector3(0, 0.5, 0), 0.14, 0.14)
		"frigg":
			lm.beam("Bronze", at + Vector3(0, 0, 0.4), at + Vector3(0, GOD_M * 1.12, 0.4), 0.07, 0.07)
		"freyja":
			lm.box("Bronze", head + Vector3(0, 0.1, 0.45), Vector3(0.28, 0.16, 0.12), Basis(), 0.0)
			lm.beam("Bronze", head + Vector3(0, -0.4, 0.1), head + Vector3(0, 0.05, 0.42), 0.12, 0.12)
		"thor":
			# Mjolnir resting on the shoulder.
			lm.box("Bronze", head + Vector3(0, -0.15, 0.3), Vector3(0.5, 0.26, 0.2), Basis(), 0.0)
			lm.beam("Bronze", head + Vector3(-0.25, -0.5, 0.25), head + Vector3(0.0, -0.15, 0.3), 0.07, 0.07)

## Iron candelabrum with three lamps at the parapet.
static func _candelabrum(lm: LandmarkMesh, base: Vector3) -> void:
	var y := LAMP_STANDARD_M
	lm.lathe("Iron", base, PackedVector2Array([Vector2(0.2, 0.0), Vector2(0.15, 0.5), Vector2(0.1, 1.8),
		Vector2(0.08, y * 0.82), Vector2(0.14, y * 0.86)]), 6)
	for a in [-1.0, 0.0, 1.0]:
		var tip := base + Vector3(a * 0.55, y * 0.84 + (0.3 if a == 0.0 else 0.0), 0)
		lm.beam("Iron", base + Vector3(0, y * 0.8, 0), tip, 0.06, 0.06)
		lm.box("Lamp", tip + Vector3(0, 0.22, 0), Vector3(0.28, 0.36, 0.28), Basis(), 0.0)
		lm.spire("Iron", tip + Vector3(0, 0.4, 0), 0.17, 0.16, 0.03)
