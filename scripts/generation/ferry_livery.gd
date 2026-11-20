class_name FerryLivery
extends RefCounted

## A shipping line's livery on a procedural cruise ferry (CruiseFerryModel):
## the hull band (a sweep rising to the bow or a stripe along the boot top),
## a second thin stripe, the funnel's colours and band, an emblem disc on
## the funnel and the line's name on the hull, from a
## HarbourVesselData.CRUISE_LIVERIES row. The ferry berthed beside a row's
## terminal wears it (`line_at`); other ferries keep the seeded colours.

## The row of CRUISE_LIVERIES whose terminal `at` (world XZ, units) stands
## within its radius, the nearest first; {} when none.
static func line_at(data: LocationData, at: Vector2, m: float) -> Dictionary:
	var best := {}
	var best_d := INF
	for row: Dictionary in HarbourVesselData.CRUISE_LIVERIES:
		var t: Array = row["terminal"]
		var p := WorldScale.xz_from_latlon(float(t[0]), float(t[1]), data.latitude, data.longitude) * m
		var d := p.distance_to(at)
		if d <= float(row["radius_m"]) * m and d < best_d:
			best = row
			best_d = d
	return best

static func row(id: String) -> Dictionary:
	return HarbourVesselData.row(HarbourVesselData.CRUISE_LIVERIES, id)

## Registers the livery's surface keys on `lm` (before the hull is lofted).
static func register(lm: LandmarkMesh, line: Dictionary, maps: bool) -> void:
	lm.use("Livery", ShipPaint.enamel(Color(str(line["band"])), maps))
	lm.use("Funnel", ShipPaint.enamel(Color(str(line["funnel"])), maps))
	lm.use("FunnelTop", ShipPaint.enamel(Color(str(line.get("funnel_band", line["funnel"]))), maps))
	if str(line.get("trim", "")) != "":
		lm.use("Trim", ShipPaint.enamel(Color(str(line["trim"])), maps))
	if str(line.get("mark", "")) != "":
		lm.use("Mark", ShipPaint.enamel(Color(str(line["mark"])), maps))
	if str(line.get("lettering", "")) != "":
		lm.use("Letters", ShipPaint.enamel(Color(str(line.get("letters", line["band"]))), maps))

## Paints the hull band, trim and name, and the funnel emblem. `top` is
## LinerSuperstructure.build's result (funnel dimensions).
static func dress(lm: LandmarkMesh, s: Dictionary, line: Dictionary, top: Dictionary, detail: bool) -> void:
	var length: float = s["length"]
	var fb: float = s["freeboard"]
	var sweep := str(line.get("band_style", "waterline")) == "sweep"
	if sweep:
		ShipHullKit.livery(lm, s, "Livery", -length * 0.48, length * 0.44, fb * 0.3, fb * 0.78,
			clampf(fb * 0.2, 1.2, 3.0))
	else:
		_stripe(lm, s, "Livery", 1.9, 1.3)
	if str(line.get("trim", "")) != "":
		_stripe(lm, s, "Trim", fb * 0.1 if sweep else 3.0, 0.35)
	if not detail:
		return
	var text := str(line.get("lettering", ""))
	if text != "":
		var h := clampf(fb * 0.17, 1.4, 2.4)
		var w := HullLettering.width(text, h)
		if w > length * 0.4:
			h *= length * 0.4 / w
		HullLettering.on_hull(lm, "Letters", s, text, -length * 0.18 if sweep else length * 0.12, fb * 0.64, h)
	if str(line.get("mark", "")) != "":
		var r := float(top["funnel_r"])
		var y := lerpf(float(top["funnel_base"]), float(top["funnel_top"]), 0.55)
		var d := r * 1.5
		for side in [-1.0, 1.0]:
			var z := float(side) * (r * 0.94 + 0.05)
			for k in 4:
				lm.box("Mark", Vector3(float(top["funnel_x"]), y, z), Vector3(d, d * 0.41, 0.06),
					Basis(Vector3.BACK, PI * 0.25 * float(k)), 0.0)

## A painted stripe `w` m tall centred at `y` along the hull, both sides.
static func _stripe(lm: LandmarkMesh, s: Dictionary, key: String, y: float, w: float) -> void:
	var length: float = s["length"]
	for side in [-1.0, 1.0]:
		var lo := PackedVector3Array()
		var hi := PackedVector3Array()
		for i in 41:
			var x := lerpf(-length * 0.47, length * 0.44, float(i) / 40.0)
			lo.append(Vector3(x, y - w * 0.5, (HullLoft.side_z(s, x, y - w * 0.5) + 0.1) * float(side)))
			hi.append(Vector3(x, y + w * 0.5, (HullLoft.side_z(s, x, y + w * 0.5) + 0.1) * float(side)))
		lm.grid(key, [lo, hi], Vector3(0, 0, float(side)))
