class_name LandmarkAircraft
extends RefCounted

## Parked aircraft for the hand-built airfields, in true metres. Each kind
## is built once in its own frame (nose +X, up +Y, right wing +Z, wheels on
## y = 0, centred on its fuselage) and merged wherever a stand needs one:
## the white fuselage with a window band, swept or straight wings, engines
## or propellers, tail surfaces carrying the tail colour, and the landing
## gear. Sizes follow the real types: narrow (Airbus A320 / Boeing 737),
## wide (Airbus A330 / Boeing 787), turboprop (Dash 8 Q400, ATR 72) and
## light (Cessna 172).

const SPECS := {
	"narrow": {"L": 37.6, "D": 3.95, "span": 34.1, "clear": 1.9, "wing_x": 1.5, "root": 6.4, "tip": 1.6,
		"sweep": 8.5, "low": true, "eng_z": [5.8], "eng_r": 1.0, "eng_l": 3.4, "fin_h": 6.4, "fin_root": 7.0,
		"fin_x": -13.0, "t_tail": false, "tp_span": 12.4, "tp_x": -15.0, "gear": 2},
	"wide": {"L": 58.8, "D": 5.64, "span": 60.3, "clear": 2.6, "wing_x": 3.5, "root": 10.5, "tip": 2.6,
		"sweep": 17.0, "low": true, "eng_z": [11.0], "eng_r": 1.55, "eng_l": 4.8, "fin_h": 9.4, "fin_root": 10.5,
		"fin_x": -20.0, "t_tail": false, "tp_span": 19.0, "tp_x": -23.0, "gear": 3},
	"turboprop": {"L": 32.8, "D": 2.7, "span": 28.4, "clear": 1.4, "wing_x": 2.0, "root": 3.2, "tip": 1.7,
		"sweep": 1.0, "low": false, "eng_z": [5.6], "eng_r": 0.55, "eng_l": 4.2, "fin_h": 5.0, "fin_root": 4.2,
		"fin_x": -11.5, "t_tail": true, "tp_span": 8.2, "tp_x": -14.0, "gear": 2, "prop": 4.1},
	"light": {"L": 8.3, "D": 1.2, "span": 11.0, "clear": 0.5, "wing_x": 1.4, "root": 1.6, "tip": 1.4,
		"sweep": 0.1, "low": false, "eng_z": [], "eng_r": 0.0, "eng_l": 0.0, "fin_h": 1.3, "fin_root": 1.3,
		"fin_x": -2.6, "t_tail": false, "tp_span": 3.4, "tp_x": -3.6, "gear": 2},
}

static var _masters: Dictionary = {}

## Registers the aircraft materials on `lm` (call once per model).
static func mats(lm: LandmarkMesh) -> void:
	lm.use("AcBody", LandmarkMaterials.paint("#ECEFEF", 0.45, 0.1))
	lm.use("Glass", LandmarkMaterials.glass("#4F6270"))
	lm.use("AcGear", LandmarkMaterials.paint("#2A2C2E", 0.8, 0.1))

## One aircraft of `kind` with its tail in `tail_hex`, at (x, z) with its
## nose along `heading` (radians in the airfield frame: 0 along +X, positive
## toward +Z).
static func place(lm: LandmarkMesh, kind: String, tail_hex: String, at: Vector2, heading: float) -> void:
	var master := _master(kind, tail_hex)
	lm.merge(master, Transform3D(Basis(Vector3.UP, -heading), Vector3(at.x, LandmarkAirfieldKit.APRON_TOP, at.y)))

## Length of a kind's fuselage, for stand placement.
static func length_m(kind: String) -> float:
	return float((SPECS[kind] as Dictionary)["L"])

static func _master(kind: String, tail_hex: String) -> LandmarkMesh:
	var key := kind + tail_hex
	if _masters.has(key):
		return _masters[key]
	var m := _build(kind, tail_hex)
	_masters[key] = m
	return m

static func _build(kind: String, tail_hex: String) -> LandmarkMesh:
	var s: Dictionary = SPECS[kind]
	var lm := LandmarkMesh.new()
	mats(lm)
	var tail_key := "AcTail" + tail_hex.trim_prefix("#")
	lm.use(tail_key, LandmarkMaterials.paint(tail_hex, 0.45, 0.1))
	var length := float(s["L"])
	var r := float(s["D"]) * 0.5
	var cy := r + float(s["clear"])
	_fuselage(lm, s, cy)
	# Window band and cockpit glass.
	for side: float in [-1.0, 1.0]:
		lm.box("Glass", Vector3(length * 0.06, cy + r * 0.28, side * (r - 0.02)), Vector3(length * 0.56, r * 0.2, 0.08), Basis(), 0.0)
	lm.box("Glass", Vector3(length * 0.5 - r * 1.35, cy + r * 0.3, 0.0), Vector3(r * 0.9, r * 0.35, r * 1.6), Basis(), 0.0)
	_wings(lm, s, cy, r)
	_tail(lm, s, tail_key, tail_hex, cy, r)
	_engines(lm, s, cy, r)
	_gear(lm, s, cy, r)
	return lm

static func _fuselage(lm: LandmarkMesh, s: Dictionary, cy: float) -> void:
	var length := float(s["L"])
	var r := float(s["D"]) * 0.5
	var nose := length * 0.16
	var tail := length * 0.3
	# Tail (y = 0) to nose (y = length): the lathe axis becomes +X below.
	var prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(r * 0.16, tail * 0.04), Vector2(r * 0.5, tail * 0.35),
		Vector2(r * 0.8, tail * 0.65), Vector2(r, tail), Vector2(r, length - nose),
		Vector2(r * 0.93, length - nose * 0.62), Vector2(r * 0.72, length - nose * 0.3),
		Vector2(r * 0.4, length - nose * 0.08), Vector2(0.0, length)])
	var part := LandmarkMesh.new()
	part.use("AcBody", LandmarkMaterials.paint("#ECEFEF", 0.45, 0.1))
	part.lathe("AcBody", Vector3.ZERO, prof, 14)
	lm.merge(part, Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3(-length * 0.5, cy, 0.0)))

static func _wings(lm: LandmarkMesh, s: Dictionary, cy: float, r: float) -> void:
	var half := float(s["span"]) * 0.5
	var x0 := float(s["wing_x"])
	var root := float(s["root"])
	var tip := float(s["tip"])
	var sweep := float(s["sweep"])
	var y := cy - r * 0.45 if bool(s["low"]) else cy + r * 0.72
	for side: float in [-1.0, 1.0]:
		var poly := PackedVector2Array([Vector2(x0, side * r * 0.8), Vector2(x0 - sweep, side * half),
			Vector2(x0 - sweep - tip, side * half), Vector2(x0 - root, side * r * 0.8)])
		_prism(lm, "AcBody", poly, y - 0.2, y + 0.2)
	var tp_half := float(s["tp_span"]) * 0.5
	var tx := float(s["tp_x"])
	var ty := cy + float(s["fin_h"]) + r * 0.3 if bool(s["t_tail"]) else cy + r * 0.2
	for side: float in [-1.0, 1.0]:
		var poly := PackedVector2Array([Vector2(tx, side * 0.5), Vector2(tx - tp_half * 0.35, side * tp_half),
			Vector2(tx - tp_half * 0.35 - tp_half * 0.12, side * tp_half), Vector2(tx - float(s["fin_root"]) * 0.55, side * 0.5)])
		_prism(lm, "AcBody", poly, ty - 0.1, ty + 0.1)

static func _tail(lm: LandmarkMesh, s: Dictionary, tail_key: String, tail_hex: String, cy: float, r: float) -> void:
	var fx := float(s["fin_x"])
	var h := float(s["fin_h"])
	var root := float(s["fin_root"])
	var poly := PackedVector2Array([Vector2(fx, 0.0), Vector2(fx - root, 0.0), Vector2(fx - root * 0.95, h),
		Vector2(fx - root * 0.55, h)])
	var part := LandmarkMesh.new()
	part.use(tail_key, LandmarkMaterials.paint(tail_hex, 0.45, 0.1))
	part.poly_prism(tail_key, poly, -0.2, 0.2)
	# Stand the (x, height) outline up from the XZ plane.
	lm.merge(part, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0.0, cy + r * 0.55, 0.0)))

static func _engines(lm: LandmarkMesh, s: Dictionary, cy: float, r: float) -> void:
	var er := float(s["eng_r"])
	if er <= 0.0:
		return
	var el := float(s["eng_l"])
	var x := float(s["wing_x"]) - 0.6
	var y := (cy - r * 0.45 - er * 1.25) if bool(s["low"]) else (cy + r * 0.72 - er * 0.9)
	for z0: float in s["eng_z"]:
		for side: float in [-1.0, 1.0]:
			var part := LandmarkMesh.new()
			part.use("AcBody", LandmarkMaterials.paint("#ECEFEF", 0.45, 0.1))
			part.lathe("AcBody", Vector3.ZERO, PackedVector2Array([Vector2(er * 0.9, 0.0), Vector2(er, el * 0.12),
				Vector2(er, el * 0.8), Vector2(er * 0.7, el)]), 10)
			lm.merge(part, Transform3D(Basis(Vector3.BACK, -PI * 0.5),
				Vector3(x - el * 0.35 + 0.0, y, side * float(z0))))
			if s.has("prop"):
				var pr := float(s["prop"]) * 0.5
				lm.box("AcGear", Vector3(x + el * 0.65 + 0.15, y, side * float(z0)), Vector3(0.12, pr * 2.0, 0.22), Basis(), 0.0)

static func _gear(lm: LandmarkMesh, s: Dictionary, cy: float, r: float) -> void:
	var length := float(s["L"])
	var h := cy - r + 0.2
	var mx := -length * 0.04
	var track := r * 1.1 if int(s["gear"]) == 2 else r * 1.3
	lm.box("AcGear", Vector3(length * 0.5 - length * 0.15, h * 0.5, 0.0), Vector3(0.18, h, 0.18), Basis(), 0.0)
	lm.box("AcGear", Vector3(length * 0.5 - length * 0.15, 0.4, 0.0), Vector3(0.9, 0.8, 0.45), Basis(), 0.0)
	for side: float in [-1.0, 1.0]:
		lm.box("AcGear", Vector3(mx, h * 0.5, side * track), Vector3(0.22, h, 0.22), Basis(), 0.0)
		lm.box("AcGear", Vector3(mx, 0.45, side * track), Vector3(1.1, 0.9, 0.6), Basis(), 0.0)

## A prism over an XZ outline with both faces closed (a wing is seen from
## below as well as above).
static func _prism(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y0: float, y1: float) -> void:
	lm.poly_prism(key, poly, y0, y1)
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri(key, Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(c.x, y0, c.y),
			Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, a, b, c)
