class_name LandmarkIbArches
extends RefCounted

## The Roman aqueduct of Segovia in true metres. The other two arch
## landmarks of the batch are LandmarkIbCordoba (the Mezquita) and
## LandmarkIbSeville (the Real Alcazar).

# --- Aqueduct of Segovia ---

const SEG_TOP := 28.5
const SEG_X0 := -75.0
const SEG_LEN := 728.0

## Ground height at x, metres over the Azoguejo valley floor (y = 0):
## steep out of the plaza, then a long gentle climb to the south-east.
static func _seg_ground(x: float) -> float:
	if x >= 0.0:
		return 22.0 * pow(x / (SEG_X0 + SEG_LEN), 0.39)
	return 15.0 * pow(-x / -SEG_X0, 0.8)

## The aqueduct arcade, +X along its run (north-west to south-east), the
## origin at the Plaza del Azoguejo where the arches stand tallest. 728 m
## of unmortared granite arches under a continuous attic that carries
## the U-shaped water channel: 28.5 m of two tiers in the hollow (44
## double arches, the upper ones of 5.1 m span, 7.2 m to a bay) thinning
## to single arches of 3.6 m span (5.2 m to a bay) as the ground rises to
## the south-east, 167 arches in all. The tall piers (2.4 x 3 m at the
## foot, 1.8 x 2.5 m at the top) step back at moulded ledges and carry
## projecting imposts at each springing; over the tallest arches the
## attic carries the panel of the lost bronze dedication and a niche on
## each face, the Virgin's on one side. The valley floor is y = 0 and
## the rising ground buries the piers' feet further on.
static func segovia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B3A68F", 3.0))
	lm.use("Cap", LandmarkMaterials.pbr("stone", "#C4B9A3", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3833", 3.0))
	var crown := SEG_TOP - 1.9
	var top := SEG_TOP - 1.2
	var end := SEG_X0 + SEG_LEN
	var x := SEG_X0
	while x < end - 0.5:
		var tall := _seg_ground(x + 3.6) < 15.0
		var xr := minf(x + (7.2 if tall else 5.2), end)
		if end - xr < 2.6:
			xr = end
		var pw := 1.9 if tall else 1.6
		var r := (xr - x - pw) * 0.5
		var spring_u := crown - r
		if tall:
			var y_mid := spring_u - 3.2
			var spring_l := y_mid - 0.9 - r
			_bay(lm, "Granite", x, xr, 0.0, spring_l, r, y_mid, pw, 1.4)
			_bay(lm, "Granite", x, xr, y_mid, spring_u, r, top, pw, 1.25)
			lm.box("Cap", Vector3((x + xr) * 0.5, y_mid, 0), Vector3(xr - x + 0.02, 0.4, 3.0))
			for px in ([x, xr] if xr >= end else [x]):
				_tall_pier(lm, px, pw, spring_l, spring_u)
		else:
			_bay(lm, "Granite", x, xr, 0.0, spring_u, r, top, pw, 1.3)
			for px in ([x, xr] if xr >= end else [x]):
				lm.box("Granite", Vector3(px, 0.5, 0), Vector3(pw + 0.4, 1.0, 2.9))
				lm.box("Cap", Vector3(px, spring_u - 0.15, 0), Vector3(pw + 0.3, 0.3, 2.85))
				lm.box("Cap", Vector3(px, top - 0.2, 0), Vector3(0.5, 0.4, 2.7))
		x = xr
	# Attic: coping either side of the open channel, the channel floor.
	for z in [-0.85, 0.85]:
		lm.box("Cap", Vector3(SEG_X0 + SEG_LEN * 0.5, SEG_TOP - 0.6, z), Vector3(SEG_LEN, 1.2, 0.9))
	lm.box("Shadow", Vector3(SEG_X0 + SEG_LEN * 0.5, SEG_TOP - 0.95, 0), Vector3(SEG_LEN, 0.5, 0.8), Basis(), 0.0)
	lm.box("Cap", Vector3(SEG_X0 + SEG_LEN * 0.5, top + 0.1, 0), Vector3(SEG_LEN, 0.25, 2.9))
	# The dedication panel and the niches over the tallest arches.
	lm.box("Cap", Vector3(0.6, top - 1.6, 0), Vector3(21.6, 3.0, 2.9))
	for s in [-1.0, 1.0]:
		var zf: float = s * 1.45
		lm.box("Shadow", Vector3(-4.0, top - 1.6, zf), Vector3(9.0, 1.8, 0.1), Basis(), 0.0)
		LandmarkIbParts.portal(lm, "Cap", "Shadow", Vector3(5.6, top - 3.0, zf), Vector3(s, 0, 0),
			Vector3(0, 0, s), 1.2, 2.6, 1, 0.3)
		if s > 0.0:
			LandmarkKits.statue_figure(lm, "Cap", Vector3(5.6, top - 3.0, zf + 0.2), 1.7)
	for ex in [SEG_X0 - 2.0, SEG_X0 + SEG_LEN + 2.0]:
		lm.box("Granite", Vector3(ex, top * 0.5, 0), Vector3(4.0, top, 2.8))
	lm.commit(model)

## Ledges, plinth and imposts of one tall two-tier pier at x.
static func _tall_pier(lm: LandmarkMesh, x: float, pw: float, spring_l: float, spring_u: float) -> void:
	var h1 := spring_l * 0.5
	lm.box("Granite", Vector3(x, 0.6, 0), Vector3(pw + 0.6, 1.2, 3.4))
	lm.box("Granite", Vector3(x, h1 * 0.5, 0), Vector3(pw + 0.35, h1, 3.15))
	lm.box("Cap", Vector3(x, h1, 0), Vector3(pw + 0.6, 0.35, 3.4))
	lm.box("Cap", Vector3(x, spring_l - 0.18, 0), Vector3(pw + 0.4, 0.35, 3.1))
	lm.box("Cap", Vector3(x, spring_u - 0.15, 0), Vector3(pw + 0.3, 0.3, 2.8))

## One masonry bay between the pier lines xl and xr: a round arch of
## radius r springing at `spring`, solid up to `top`, from y0 down.
static func _bay(lm: LandmarkMesh, key: String, xl: float, xr: float, y0: float, spring: float,
		r: float, top: float, pw: float, hz: float) -> void:
	var poly := PackedVector2Array([Vector2(xl, y0), Vector2(xl + pw * 0.5, y0)])
	poly.append_array(LandmarkBrKit.arch_pts((xl + xr) * 0.5, spring, r, r, 7))
	poly.append_array(PackedVector2Array([Vector2(xr - pw * 0.5, y0), Vector2(xr, y0),
		Vector2(xr, top), Vector2(xl, top)]))
	LandmarkBrKit.extrude_xy(lm, key, poly, -hz, hz)
