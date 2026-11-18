class_name ClassicSteamerDetails
extends RefCounted

## Near-view dressing of PassengerVesselModel's classic coastal steamer
## (metres, +X bow, `spec` as HullLoft): a covered promenade whose boat
## deck overhangs the main deck on white stanchions, a white rubbing
## strake, open bridge wings with solid bulwarks, cowl
## ventilators round the funnel, benches on the aft deck and a
## raked jackstaff and flagstaff. `d` carries the deckhouse layout:
## house_x, tier_len, tier_w, floor_h, decks, roof_y, wh_x, wh_l, wh_w,
## funnel (base Vector3), fr (funnel radius), boat_x0 / boat_x1 (the
## lifeboat span the boat-deck rail leaves open).

static func dress(lm: LandmarkMesh, spec: Dictionary, d: Dictionary) -> void:
	var length: float = spec["length"]
	var fb: float = spec["freeboard"]
	if int(d["decks"]) >= 2:
		_promenade(lm, spec, d)
	_wings(lm, spec, d)
	_cowls(lm, d)
	_benches(lm, spec, float(d["house_x"]) - float(d["tier_len"]) * 0.5)
	# Rubbing strake just under the sheer, bow to stern. It follows the
	# lofted sections, which carry the stem's rake that side_z ignores.
	var strake: Array = []
	for i in 49:
		var pts := HullLoft.section(spec, lerpf(0.03, 0.96, float(i) / 48.0))
		var top: Vector3 = pts[0]
		var mid: Vector3 = pts[1]
		var p: Vector3 = top.lerp(mid, 0.18 / maxf(top.y - mid.y, 0.2))
		strake.append(Vector3(p.x, p.y, absf(p.z) + 0.03))
	for s in [-1.0, 1.0]:
		var path: Array = []
		for p in strake:
			path.append(Vector3((p as Vector3).x, (p as Vector3).y, (p as Vector3).z * float(s)))
		HullLoft.tube(lm, "White", path, clampf(fb * 0.035, 0.04, 0.09), 6)
	# Jackstaff at the stem and flagstaff over the counter, both raked.
	var bow := Vector3(length * 0.45, HullLoft.sheer(spec, length * 0.45), 0)
	HullLoft.tube(lm, "White", [bow, bow + Vector3(0.25, fb * 0.7 + 0.8, 0)], 0.035, 6)
	var stern_x := HullLoft.transom_x(spec, fb) + 0.35
	var stern := Vector3(stern_x, HullLoft.sheer(spec, stern_x), 0)
	HullLoft.tube(lm, "White", [stern, stern + Vector3(-0.45, fb * 0.8 + 1.0, 0)], 0.04, 6)

## The boat deck carried out to the hull sides over the main deck, aft
## past the deckhouse, on stanchions, with a rail round its edge.
static func _promenade(lm: LandmarkMesh, spec: Dictionary, d: Dictionary) -> void:
	var length: float = spec["length"]
	var fb: float = spec["freeboard"]
	var x1: float = float(d["house_x"]) + float(d["tier_len"]) * 0.5
	var x0: float = float(d["house_x"]) - float(d["tier_len"]) * 0.5 - length * 0.06
	var hw := minf(HullLoft.half(spec, x0), HullLoft.half(spec, x1)) - 0.12
	var top: float = fb + 0.02 + float(d["floor_h"]) + 0.05
	VesselForms.slab(lm, "DeckSteel", Vector3((x0 + x1) * 0.5, top - 0.06, 0), Vector3(x1 - x0, 0.12, hw * 2.0), minf(hw * 0.5, 1.6))
	var n := maxi(int((x1 - x0) / 2.6), 2)
	var b0: float = d["boat_x0"]
	var b1: float = d["boat_x1"]
	for s in [-1.0, 1.0]:
		var rails: Array = [[]]
		for i in n + 1:
			var x := lerpf(x0 + 0.35, x1 - 0.35, float(i) / float(n))
			var z := (hw - 0.14) * float(s)
			HullLoft.tube(lm, "White", [Vector3(x, HullLoft.sheer(spec, x), z), Vector3(x, top - 0.12, z)], 0.05, 6)
			if x > b0 and x < b1:
				if not (rails[rails.size() - 1] as Array).is_empty():
					rails.append([])
				continue
			var rz := (hw - 0.08) * float(s)
			HullLoft.tube(lm, "Steel", [Vector3(x, top, rz), Vector3(x, top + 1.0, rz)], 0.02, 6)
			(rails[rails.size() - 1] as Array).append(Vector3(x, top + 1.0, rz))
		for r in rails:
			HullLoft.tube(lm, "Steel", r, 0.025, 6)

## Open bridge wings either side of the wheelhouse front: a deck plate out
## to the boat-deck edge with a solid white bulwark and a handrail.
static func _wings(lm: LandmarkMesh, spec: Dictionary, d: Dictionary) -> void:
	var wh_w: float = d["wh_w"]
	if wh_w <= 0.0:
		return
	var x: float = float(d["wh_x"]) + float(d["wh_l"]) * 0.3
	var y: float = d["roof_y"]
	var reach := HullLoft.half(spec, x) - 0.2
	var depth := clampf(float(d["wh_l"]) * 0.45, 0.8, 1.6)
	var inner := wh_w * 0.5 - 0.05
	if reach - inner < 0.4:
		return
	for s in [-1.0, 1.0]:
		var cz := (inner + reach) * 0.5 * float(s)
		lm.box("DeckSteel", Vector3(x, y - 0.07, cz), Vector3(depth, 0.1, reach - inner), Basis(), 0.0)
		lm.box("White", Vector3(x + depth * 0.5 - 0.03, y + 0.5, cz), Vector3(0.06, 1.0, reach - inner), Basis(), 0.0)
		lm.box("White", Vector3(x, y + 0.5, reach * float(s)), Vector3(depth, 1.0, 0.06), Basis(), 0.0)
		HullLoft.tube(lm, "Dark", [Vector3(x + depth * 0.5 - 0.03, y + 1.03, inner * float(s)),
			Vector3(x + depth * 0.5 - 0.03, y + 1.03, reach * float(s)), Vector3(x - depth * 0.5, y + 1.03, reach * float(s))], 0.035, 6)
		# Brackets under the wing.
		for k in [-0.35, 0.35]:
			HullLoft.tube(lm, "White", [Vector3(x + depth * float(k), y - 0.1, inner * float(s)),
				Vector3(x + depth * float(k), y - 0.1, reach * 0.8 * float(s))], 0.03, 4)

## Bell-mouthed cowl ventilators ahead of and abaft the funnel.
static func _cowls(lm: LandmarkMesh, d: Dictionary) -> void:
	var base: Vector3 = d["funnel"]
	var fr: float = d["fr"]
	var r := clampf(fr * 0.32, 0.12, 0.35)
	var spread := minf(float(d["tier_w"]) * 0.28, fr * 2.4)
	for k in [[fr * 2.3, 1.0], [-fr * 2.2, -1.0]]:
		for s in [-1.0, 1.0]:
			var at := base + Vector3(float(k[0]), 0, float(s) * spread)
			var h := r * (5.0 if float(k[1]) > 0.0 else 3.6)
			var face := Vector3(float(k[1]), 0, 0)
			var bend := at + Vector3(0, h, 0)
			var mouth := bend + Vector3(0, r * 0.9, 0) + face * r * 0.9
			HullLoft.tube(lm, "White", [at, bend, bend + Vector3(0, r * 0.55, 0) + face * r * 0.25, mouth], r * 0.55, 10)
			VesselEquipment.ring(lm, "White", mouth, face, r, r * 0.12)
			lm.disc("Dark", mouth - face * 0.04, face, r * 0.9, 12)

## Two pairs of back-to-back painted benches under the promenade overhang,
## clear of the aft door at `x_front`.
static func _benches(lm: LandmarkMesh, spec: Dictionary, x_front: float) -> void:
	var bench := clampf(float(spec["length"]) * 0.03, 1.2, 1.8)
	for k in 2:
		var x := x_front - 1.4 - bench * 0.5 - float(k) * (bench + 0.6)
		var y := HullLoft.sheer(spec, x) + minf(float(spec["beam"]) * 0.012, 0.15)
		for s in [-1.0, 1.0]:
			var z := float(s) * 0.38
			lm.box("White", Vector3(x, y + 0.45, z), Vector3(bench, 0.06, 0.42), Basis(), 0.0)
			lm.box("White", Vector3(x, y + 0.75, z - float(s) * 0.2), Vector3(bench, 0.36, 0.05), Basis(), 0.0)
			for e in [-0.42, 0.42]:
				HullLoft.tube(lm, "Steel", [Vector3(x + bench * float(e), y, z), Vector3(x + bench * float(e), y + 0.42, z)], 0.025, 6)
