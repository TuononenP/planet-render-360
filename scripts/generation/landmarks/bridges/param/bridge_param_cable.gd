class_name BridgeParamCable
extends RefCounted

## Cable bridges from a spec row. The towers stand on the interior supports
## (cumulative spans), `tower` metres over the water. A suspension bridge
## (spans side, main, side) hangs a deck from two main cables over the
## towers (LandmarkBrKit.suspension); a cable-stayed bridge fans stays from
## each tower to the deck both ways. `pylon: "single"` is one mast on the
## road's centre line, otherwise two legs outside the roadway; `lean` tilts
## a single pylon (its top displaced that many metres along +X). An
## extradosed bridge is the same with a low pylon and a deep box girder and
## fewer, flatter stays; a lateral-suspension footbridge keeps its cables
## level with the deck between low pier arms.

## Tower on the centre line (`pylon: "single"`) or two legs either side. A
## low tower (an extradosed pylon) has one cross beam at its top, a leaning
## single pylon is one inclined member.
static func _tower(lm: LandmarkMesh, row: Dictionary, x: float, leg_z: float) -> void:
	var top := float(row["tower"])
	var clear := float(row["clear"])
	var main := BridgeSpec.widest_span(row)
	var leg := clampf(main * 0.008 + 1.0, 1.4, 4.5)
	if str(row.get("pylon", "portal")) == "single":
		var lean := float(row.get("lean", 0.0))
		if absf(lean) > 0.5:
			# The foot starts above the water so its slanted end face stays out of it.
			lm.beam("Steel", Vector3(x, leg * 1.2, 0), Vector3(x + lean, top - 0.3, 0), leg * 2.4, leg * 1.8,
				Vector3(0, 0, 1))
			return
		LandmarkBrKit.tapered_box(lm, "Steel", Vector3(x, 0, 0), leg * 1.3, leg, leg * 0.75, leg * 0.6, top)
		return
	var beams: Array = [clear + (top - clear) * 0.45, top - 3.0]
	if top - clear < 12.0:
		beams = [top - 1.0]
	LandmarkBrKit.portal_tower(lm, "Steel", x, 0.0, top, leg_z, Vector2(leg, leg * 0.9),
		Vector2(leg * 0.7, leg * 0.65), beams, 2.0 if top - clear < 12.0 else 2.4, false)

static func suspension(lm: LandmarkMesh, row: Dictionary) -> void:
	var xs := BridgeParam.supports(row)
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var top := float(row["tower"])
	var main := BridgeSpec.widest_span(row)
	var depth := minf(clampf(main / 60.0, 1.6, 4.5), clear - 0.3)
	BridgeParam.box_girder(lm, "Steel", -h, h, clear, width, depth)
	BridgeParam.rails(lm, "Steel", -h, h, clear, width)
	var leg_z := width * 0.5 + 1.2
	var tx0 := xs[1]
	var tx1 := xs[xs.size() - 2]
	for x in [tx0, tx1]:
		_tower(lm, row, x, leg_z)
	var w := clampf(main * 0.0009, 0.35, 1.1)
	LandmarkBrKit.suspension(lm, "Steel", {
		"tx0": tx0, "tx1": tx1, "e0": -h, "e1": h, "top": top - 0.6 - w * 0.5, "low": clear + 2.2,
		"end0": clear + 1.0, "end1": clear + 1.0, "sag0": 0.0, "sag1": 0.0, "z": leg_z - 0.4,
		"dz": width * 0.5, "deck_y": clear, "w": w, "step": clampf(main / 28.0, 5.0, 18.0),
		"hw": 0.25, "side": true})
	BridgeParamBeam.piers(lm, row, clear - depth)

static func stayed(lm: LandmarkMesh, row: Dictionary) -> void:
	_stayed(lm, row, false)

## Extradosed: a low pylon (`tower` only a few metres to a few spans' tenths
## over the deck), a deep box girder and a few shallow stays.
static func extradosed(lm: LandmarkMesh, row: Dictionary) -> void:
	_stayed(lm, row, true)

## One stay from the pylon at height y (its axis leans `lean` m over the full
## height `top`) to the deck, `reach` m along dir from the pylon foot.
static func _stay(lm: LandmarkMesh, x: float, y: float, top: float, lean: float, dir: float,
		reach: float, deck_y: float, z_top: float, z_deck: float, w: float) -> void:
	var tx := x + lean * y / top
	lm.beam("Steel", Vector3(tx, y, z_top), Vector3(x + dir * reach, deck_y, z_deck), w, w)

static func _stayed(lm: LandmarkMesh, row: Dictionary, low: bool) -> void:
	var xs := BridgeParam.supports(row)
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var top := float(row["tower"])
	var main := BridgeSpec.widest_span(row)
	var depth := clampf(main / 70.0, 1.6, 4.0)
	if low:
		depth = clampf(main / 30.0, 2.5, 7.0)
	depth = minf(depth, clear - 0.3)
	BridgeParam.box_girder(lm, "Steel", -h, h, clear, width, depth)
	BridgeParam.rails(lm, "Steel", -h, h, clear, width)
	var single := str(row.get("pylon", "portal")) == "single"
	var lean := float(row.get("lean", 0.0)) if single else 0.0
	var leg_z := width * 0.5 + 1.2
	var w := clampf(main * 0.0005, 0.18, 0.45)
	if low:
		w = clampf(main * 0.0012, 0.25, 0.6)
	var towers := tower_supports(row)
	for t in towers.size():
		var x := xs[towers[t]]
		_tower(lm, row, x, leg_z)
		var y1 := top - (1.0 if low else 3.0)
		var y0 := clear + (top - clear) * (0.5 if low else 0.45)
		for dir in [-1.0, 1.0]:
			# Stays run to the deck end, or halfway to the next tower.
			var next := t + int(dir)
			var between := next >= 0 and next < towers.size()
			var other := xs[towers[next]] if between else (h if dir > 0.0 else -h)
			var reach := absf(other - x) * (0.5 if between else 1.0)
			reach = minf(reach, main * 0.5) * 0.94
			var n := clampi(int(reach / (22.0 if low else 14.0)), 3 if low else 5, 8 if low else 14)
			var d0 := reach * (0.2 if low else 0.12)
			var dd := (reach - d0) / maxf(n - 1, 1)
			for s in [-1.0, 1.0]:
				for i in n:
					var f := float(i) / maxf(n - 1, 1)
					_stay(lm, x, lerpf(y0, y1, f), top, lean, dir, d0 + dd * i, clear,
						0.0 if single else s * leg_z, s * (width * 0.5 - 0.5), w)
	BridgeParamBeam.piers(lm, row, clear - depth)

## Lateral-suspension footbridge (Millennium Bridge): the pier arms at the
## supports rise `tower` over the water, the two cables run from arm to arm
## sagging to the deck's level beside it, and outriggers carry the deck.
static func lateral(lm: LandmarkMesh, row: Dictionary) -> void:
	var xs := BridgeParam.supports(row)
	var h := BridgeParam.half_length(row)
	var width := float(row["width"])
	var clear := float(row["clear"])
	var top := float(row["tower"])
	var main := BridgeSpec.widest_span(row)
	var depth := minf(clampf(main / 60.0, 0.7, 1.6), clear - 0.3)
	BridgeParam.box_girder(lm, "Steel", -h, h, clear, width, depth)
	BridgeParam.rails(lm, "Steel", -h, h, clear, width)
	var zc := width * 0.5 + 0.9
	var arm_x := xs[1]
	var arm_x1 := xs[xs.size() - 2]
	for x in [arm_x, arm_x1]:
		BridgeParam.pier(lm, "Concrete", x, clear - depth, 1.6, width * 0.3)
		for s in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(x, clear - depth, s * width * 0.3), Vector3(x, top - 0.2, s * zc), 0.9, 0.9)
	var p := {"tx0": arm_x, "tx1": arm_x1, "e0": -h, "e1": h, "top": top - 0.45, "low": clear + 0.25,
		"end0": clear + 0.3, "end1": clear + 0.3, "sag0": 0.0, "sag1": 0.0, "z": zc, "dz": width * 0.5,
		"deck_y": clear, "w": 0.45, "step": 1.0e6}
	LandmarkBrKit.suspension(lm, "Steel", p)
	# Outriggers from the deck edge to the cable every 8 m.
	var n := maxi(int(2.0 * h / 8.0), 2)
	for k in range(1, n):
		var x := lerpf(-h, h, float(k) / n)
		for s in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(x, clear - 0.35, s * width * 0.5), Vector3(x, LandmarkBrKit.cable_y(p, x) - 0.1, s * zc), 0.3, 0.3)
	BridgeParam.abutments(lm, row, clear - depth)

## Indices into BridgeParam.supports of the supports that carry a tower: the
## row's `towers`, else every interior support.
static func tower_supports(row: Dictionary) -> Array[int]:
	var out: Array[int] = []
	if row.has("towers"):
		for i in row["towers"]:
			out.append(int(i))
	else:
		for i in range(1, (row["spans"] as Array).size()):
			out.append(i)
	return out
