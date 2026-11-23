extends RefCounted

## Suomenlinna dry dock (Viaporin telakka, begun 1750s), Susisaari: the
## oldest working dry dock in Finland, a long granite-lined basin with a
## flat floor of timber keel blocks and a steel caisson closing it at the
## harbour end. Frame: origin at the basin centre, +X toward the entrance
## (the caisson), long axis along X; the registry yaw 21 lays +X toward
## east-south-east on the map.
##
## From the Commons photographs (visual-plan/refs/landmarks/
## suomenlinna_dry_dock/): the side walls are coursed granite ashlar that
## steps in three times (altars) down to the floor; the floor is cobbled
## with rows of short timber keel blocks and cribs; the caisson is a
## dark rust-red steel hull with a flat top; a bowed iron arch rises from
## the north rim (the gate-hoist frame); a yellow gantry crane runs along
## the south rim, and a grey lattice mast stands beyond the head.
##
## Measured from OSM (waterway=dock way 117478898, the basin lobe): about
## 124 m long and 27.5 m wide at the rim, axis 21 deg from east toward
## south. The registry used to point 170 m east of this basin. The model
## cannot cut the ground, so the basin is a raised rim: the real walls are
## about 9 m deep below the quay, here the rim stands 3.4 m above the floor
## and the floor is the terrain. Estimated: steps, block rows, caisson
## size, the arch (7 m span) and the crane (22 m).

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "suomenlinna_dry_dock", "name": "Suomenlinna Dry Dock", "lat": 60.145425, "lon": 24.98161,
	"radius_m": 4500.0, "wiki_title": "Suomenlinna", "height_m": 22.0, "clear_m": 6.0,
	"clear_rect_m": [0.0, 0.0, 66.0, 15.0],
	"yaw_deg": 21.0, "kind": "Dry dock",
	"aliases": ["suomenlinna dry dock", "suomenlinnan kuivatelakka", "suomenlinna telakka"]}

const HL := 62.0
const HW := 13.75
const RIM := 4.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8C8176", 2.5))
	lm.use("Coping", LandmarkMaterials.pbr("limestone", "#A59C90", 2.5))
	lm.use("Floor", LandmarkMaterials.pbr("gravel", "#837B6C", 2.5))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#8B5E43", 1.5))
	lm.use("Steel", LandmarkMaterials.paint("#5E3C30", 0.7, 0.55))
	lm.use("Yellow", LandmarkMaterials.paint("#D9B227", 0.55, 0.4))
	lm.use("Iron", LandmarkMaterials.paint("#2B2E31", 0.55, 0.5))
	lm.use("Quay", LandmarkMaterials.pbr("gravel", "#9B9385", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#964636", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3A3F42", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A343A"))
	lm.box("Quay", Vector3(0, 0.03, 0), Vector3(156.0, 0.06, 52.0))
	_walls(lm)
	_floor(lm)
	_pump_house(lm)
	_caisson(lm)
	_arch(lm)
	_crane(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.86, 0.64)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-56.0, 6.0, -18.0), Vector3(-72.0, 4.5, 0.0), 48.0, 0.9, 45.0, warm],
		[Vector3(-30.0, 6.0, 17.5), Vector3(-15.0, 1.0, 0.0), 55.0, 0.85, 55.0, warm],
		[Vector3(24.0, 6.0, -17.5), Vector3(16.0, 1.0, 0.0), 55.0, 0.85, 55.0, warm],
		[Vector3(-22.0, 5.5, 22.0), Vector3(-6.0, 16.0, 16.0), 38.0, 0.9, 55.0, warm],
		[Vector3(50.0, 6.0, -17.5), Vector3(62.8, 4.5, 0.0), 46.0, 0.85, 45.0, warm],
	])

## Deep stepped ashlar altar walls along both flanks and the dock head.
static func _walls(lm: LandmarkMesh) -> void:
	var tiers := 4
	var step_h := RIM / float(tiers + 1)
	for s in [-1.0, 1.0]:
		# Outer granite ashlar wall mass and dressed coping.
		U.blk(lm, "Granite", 0.0, 0.0, s * (HW + 2.5), 2.0 * HL + 5.0, RIM, 5.0)
		U.blk(lm, "Coping", 0.0, RIM, s * (HW + 2.0), 2.0 * HL + 5.4, 0.3, 4.4)
		# Four altar steps stepping inward toward the basin floor.
		for k in tiers:
			var inset := 0.55 * float(k + 1)
			var top_y := step_h * float(tiers - k)
			U.blk(lm, "Granite", 0.0, 0.0, s * (HW - inset * 0.5), 2.0 * HL, top_y - 0.16, inset)
			U.blk(lm, "Coping", 0.0, top_y - 0.16, s * (HW - inset * 0.5), 2.0 * HL + 0.1, 0.16, inset + 0.08)
		# Granite ashlar buttress joints along the coping.
		var bx := -HL + 8.0
		while bx < HL - 6.0:
			U.blk(lm, "Granite", bx, RIM - 0.5, s * (HW + 0.25), 0.8, 0.5, 0.5)
			bx += 12.0
	# Closed west dock head with stepped ashlar altars.
	U.blk(lm, "Granite", -HL - 2.5, 0.0, 0.0, 5.0, RIM, 2.0 * HW + 10.0)
	U.blk(lm, "Coping", -HL - 2.0, RIM, 0.0, 4.4, 0.3, 2.0 * HW + 9.4)
	for k in tiers:
		var inset := 0.55 * float(k + 1)
		var top_y := step_h * float(tiers - k)
		U.blk(lm, "Granite", -HL + inset * 0.5, 0.0, 0.0, inset, top_y - 0.16, 2.0 * HW - 1.2)
		U.blk(lm, "Coping", -HL + inset * 0.5, top_y - 0.16, 0.0, inset + 0.08, 0.16, 2.0 * HW - 1.1)

## Cobbled floor with drainage channels, grates, keel blocks and bilge cribs.
static func _floor(lm: LandmarkMesh) -> void:
	lm.box("Floor", Vector3(0, 0.12, 0), Vector3(2.0 * HL, 0.24, 2.0 * HW - 2.4))
	# Side drainage channels framed by granite kerbs and iron drain grates.
	for s: float in [-1.0, 1.0]:
		var cz := s * (HW - 3.3)
		lm.box("Granite", Vector3(0, 0.27, cz - s * 0.55), Vector3(2.0 * HL - 4.0, 0.08, 0.28))
		lm.box("Granite", Vector3(0, 0.27, cz + s * 0.55), Vector3(2.0 * HL - 4.0, 0.08, 0.28))
		lm.box("Quay", Vector3(0, 0.25, cz), Vector3(2.0 * HL - 4.0, 0.03, 0.82))
	var gx := -HL + 6.0
	while gx < HL - 4.0:
		for s in [-1.0, 1.0]:
			lm.box("Iron", Vector3(gx, 0.27, s * (HW - 3.3)), Vector3(0.8, 0.04, 0.75))
		gx += 10.0
	# Central drainage sump & keel-block rows.
	lm.box("Granite", Vector3(-HL + 3.8, 0.26, 0.0), Vector3(2.2, 0.06, 2.0 * HW - 6.0))
	var x := -HL + 6.0
	while x < HL - 4.0:
		lm.box("Timber", Vector3(x, 0.64, 0.0), Vector3(0.75, 0.84, 1.1))
		for s in [-1.0, 1.0]:
			lm.box("Timber", Vector3(x + 1.3, 0.52, s * 3.6), Vector3(0.65, 0.62, 0.65))
			lm.box("Timber", Vector3(x + 0.4, 0.52, s * 7.0), Vector3(0.65, 0.62, 0.65))
		x += 2.7

## 19th-century red-brick pump house and boiler chimney at the west dock head.
static func _pump_house(lm: LandmarkMesh) -> void:
	var px := -72.0
	var pz := 0.0
	var w := 8.4
	var d := 13.0
	U.blk(lm, "Granite", px, 0.0, pz, w + 0.4, 0.8, d + 0.4)
	U.blk(lm, "Brick", px, 0.8, pz, w, 5.8, d)
	U.blk(lm, "Coping", px, 6.4, pz, w + 0.5, 0.35, d + 0.5)
	U.ridge_z(lm, "Roof", "Brick", Vector3(px, 6.75, pz), w + 0.4, d + 0.4, 2.5, 0.35)
	# Arched windows along the dock-facing (+X) and outer (-X) walls.
	for s: float in [-1.0, 1.0]:
		var fx := px + s * (w * 0.5)
		U.openings(lm, "Glass", Vector3(fx, 0, pz - 4.2), Vector3(fx, 0, pz + 4.2), Vector3(s, 0, 0), 2.1, 3, 1.2, 2.4, true, 0.08)
	# Double timber engine-room doors facing the dock.
	U.blk(lm, "Timber", px + w * 0.5 + 0.05, 0.8, pz, 0.14, 3.2, 2.2)
	# Brick boiler chimney stack at the north corner of the pump house.
	var cx := px - 2.2
	var cz := pz - 7.8
	U.blk(lm, "Granite", cx, 0.0, cz, 2.2, 1.4, 2.2)
	lm.frustum("Brick", Vector3(cx, 1.4, cz), 0.95, 0.62, 13.2, 10)
	lm.frustum("Coping", Vector3(cx, 14.6, cz), 0.78, 0.78, 0.35, 10)

## The steel caisson closing the east end, with full walkway deck and handrails.
static func _caisson(lm: LandmarkMesh) -> void:
	var cx := HL + 0.8
	var top_y := RIM + 1.8
	U.blk(lm, "Steel", cx, 0.0, 0.0, 3.6, top_y, 2.0 * HW - 1.6)
	U.blk(lm, "Iron", cx, top_y, 0.0, 3.4, 0.22, 2.0 * HW - 1.8)
	U.blk(lm, "Timber", cx, top_y + 0.22, 0.0, 2.6, 0.1, 2.0 * HW - 2.2)
	# Twin handrails and stanchions along both sides of the caisson walkway.
	var span_z := HW - 1.0
	for sx in [-1.45, 1.45]:
		for k in 11:
			var z := lerpf(-span_z, span_z, float(k) / 10.0)
			lm.beam("Iron", Vector3(cx + sx, top_y + 0.2, z), Vector3(cx + sx, top_y + 1.35, z), 0.07, 0.07)
		lm.beam("Iron", Vector3(cx + sx, top_y + 1.35, -span_z), Vector3(cx + sx, top_y + 1.35, span_z), 0.06, 0.06)
		lm.beam("Iron", Vector3(cx + sx, top_y + 0.8, -span_z), Vector3(cx + sx, top_y + 0.8, span_z), 0.05, 0.05)

## The bowed iron arch (gate-hoist frame) standing on the north rim.
static func _arch(lm: LandmarkMesh) -> void:
	var cx := -24.0
	var cz := -(HW + 2.5)
	var r := 3.6
	var prev := Vector3(cx - r, RIM, cz)
	for k in 1 + 14:
		var a := PI * float(k) / 14.0
		var p := Vector3(cx - cos(a) * r, RIM + sin(a) * 6.0, cz)
		lm.beam("Iron", prev, p, 0.35, 0.35)
		prev = p
	lm.beam("Iron", Vector3(cx - r, RIM, cz), Vector3(cx + r, RIM, cz), 0.3, 0.3)

## Yellow gantry crane on the south rim with A-frame portal, cab, counterweight,
## lattice jib, pulley sheave and hoist hook; grey mast beyond the dock head.
static func _crane(lm: LandmarkMesh) -> void:
	var cx := -6.0
	var cz := HW + 3.2
	var portal_h := 13.6
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Yellow", Vector3(cx + sx * 3.0, RIM, cz + sz * 1.5), Vector3(cx + sx * 2.0, RIM + portal_h, cz + sz * 1.2), 0.45, 0.45)
	for k in 4:
		var y := RIM + 2.6 + float(k) * 2.75
		for sx in [-1.0, 1.0]:
			lm.beam("Yellow", Vector3(cx + sx * 2.8, y, cz - 1.4), Vector3(cx + sx * 2.1, y + 2.75, cz + 1.3), 0.14, 0.14)
	# Machinery house, glazed cab and rear counterweight box.
	U.blk(lm, "Yellow", cx, RIM + portal_h - 0.2, cz, 5.4, 2.2, 3.8)
	U.blk(lm, "Glass", cx + 1.2, RIM + portal_h + 0.4, cz - 1.95, 2.0, 1.2, 0.15)
	U.blk(lm, "Iron", cx - 3.0, RIM + portal_h - 0.2, cz + 1.2, 2.2, 1.6, 2.6)
	# Lattice jib boom reaching over the basin up to 22.0 m.
	var j0 := Vector3(cx, RIM + portal_h + 0.8, cz)
	var j1 := Vector3(cx + 9.6, 21.85, cz - 13.2)
	var j_side := Vector3(0.55, 0.0, 0.38)
	lm.beam("Yellow", j0 - j_side, j1 - j_side * 0.5, 0.32, 0.32)
	lm.beam("Yellow", j0 + j_side, j1 + j_side * 0.5, 0.32, 0.32)
	lm.beam("Yellow", Vector3(cx - 1.2, RIM + portal_h + 2.2, cz + 0.6), j1, 0.18, 0.18)
	for k in 6:
		var t0 := float(k) / 6.0
		var t1 := float(k + 1) / 6.0
		var a0 := (j0 - j_side).lerp(j1 - j_side * 0.5, t0)
		var b0 := (j0 + j_side).lerp(j1 + j_side * 0.5, t0)
		var a1 := (j0 - j_side).lerp(j1 - j_side * 0.5, t1)
		var b1 := (j0 + j_side).lerp(j1 + j_side * 0.5, t1)
		lm.beam("Yellow", a0, b1, 0.12, 0.12)
		lm.beam("Yellow", b0, a1, 0.12, 0.12)
	# Tip pulley sheave, twin hoist cables and hook block.
	lm.frustum("Iron", j1 - Vector3(0, 0.35, 0), 0.45, 0.45, 0.3, 10)
	lm.beam("Iron", j1 - Vector3(0.2, 0.35, 0), Vector3(j1.x - 0.2, RIM + 8.5, j1.z), 0.04, 0.04)
	lm.beam("Iron", j1 + Vector3(0.2, -0.35, 0), Vector3(j1.x + 0.2, RIM + 8.5, j1.z), 0.04, 0.04)
	U.blk(lm, "Yellow", j1.x, RIM + 7.8, j1.z, 0.7, 0.7, 0.5)
	# Grey lattice mast beyond the head of the dock.
	var mx := HL + 8.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Iron", Vector3(mx + sx * 2.2, 0.0, 6.0 + sz * 2.2), Vector3(mx + sx * 0.9, 16.0, 6.0 + sz * 0.9), 0.3, 0.3)
	for k in 4:
		var y := 2.0 + float(k) * 3.6
		lm.box("Iron", Vector3(mx, y, 6.0), Vector3(3.6 - 0.5 * float(k), 0.2, 3.6 - 0.5 * float(k)))
