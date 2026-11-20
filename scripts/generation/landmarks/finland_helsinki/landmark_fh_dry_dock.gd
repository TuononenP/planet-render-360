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
const RIM := 3.4

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
	lm.box("Quay", Vector3(0, 0.03, 0), Vector3(156.0, 0.06, 52.0))
	_walls(lm)
	_floor(lm)
	_caisson(lm)
	_arch(lm)
	_crane(lm)
	lm.commit(model)

## Rim walls with three altar steps on the inside, and the closed end.
static func _walls(lm: LandmarkMesh) -> void:
	var step_h := RIM / 4.0
	for s in [-1.0, 1.0]:
		# Outer wall mass and the coping.
		U.blk(lm, "Granite", 0.0, 0.0, s * (HW + 2.5), 2.0 * HL + 5.0, RIM, 5.0)
		U.blk(lm, "Coping", 0.0, RIM, s * (HW + 2.0), 2.0 * HL + 5.4, 0.28, 4.4)
		# Altars: ledges that step the basin in towards the floor.
		for k in 3:
			var inset := 0.0 + 0.55 * float(k + 1)
			U.blk(lm, "Coping", 0.0, step_h * float(3 - k) - 0.1, s * (HW - inset * 0.5), 2.0 * HL, 0.22, inset)
	# Closed (west) end.
	U.blk(lm, "Granite", -HL - 2.5, 0.0, 0.0, 5.0, RIM, 2.0 * HW + 10.0)
	U.blk(lm, "Coping", -HL - 2.0, RIM, 0.0, 4.4, 0.28, 2.0 * HW + 9.4)
	for k in 3:
		var inset := 0.55 * float(k + 1)
		U.blk(lm, "Coping", -HL + inset * 0.5, step_h * float(3 - k) - 0.1, 0.0, inset, 0.22, 2.0 * HW - 1.0)

## Cobbled floor with rows of keel blocks and cribs.
static func _floor(lm: LandmarkMesh) -> void:
	lm.box("Floor", Vector3(0, 0.12, 0), Vector3(2.0 * HL, 0.24, 2.0 * HW - 2.2))
	var x := -HL + 4.0
	while x < HL - 4.0:
		lm.box("Timber", Vector3(x, 0.62, 0.0), Vector3(0.7, 0.8, 1.0))
		for s in [-1.0, 1.0]:
			lm.box("Timber", Vector3(x + 1.3, 0.5, s * 3.6), Vector3(0.6, 0.6, 0.6))
			lm.box("Timber", Vector3(x + 0.4, 0.5, s * 7.0), Vector3(0.6, 0.6, 0.6))
		x += 2.7

## The caisson closing the east end.
static func _caisson(lm: LandmarkMesh) -> void:
	U.blk(lm, "Steel", HL + 0.8, 0.0, 0.0, 3.6, RIM + 1.8, 2.0 * HW - 1.6)
	U.blk(lm, "Iron", HL + 0.8, RIM + 1.8, 0.0, 3.2, 0.25, 2.0 * HW - 2.0)
	for s in [-1.0, 1.0]:
		lm.beam("Iron", Vector3(HL + 0.2, RIM + 2.0, s * (HW - 1.0)), Vector3(HL + 0.2, RIM + 3.1, s * (HW - 1.0)), 0.07, 0.07)
	lm.beam("Iron", Vector3(HL + 0.2, RIM + 3.1, -(HW - 1.0)), Vector3(HL + 0.2, RIM + 3.1, HW - 1.0), 0.06, 0.06)

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

## A yellow gantry crane on the south rim and a grey mast behind the head.
static func _crane(lm: LandmarkMesh) -> void:
	var cx := -6.0
	var cz := HW + 3.2
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Yellow", Vector3(cx + sx * 3.0, RIM, cz + sz * 1.5), Vector3(cx + sx * 2.0, RIM + 15.0, cz + sz * 1.2), 0.45, 0.45)
	for k in 4:
		var y := RIM + 3.0 + float(k) * 3.2
		for sx in [-1.0, 1.0]:
			lm.beam("Yellow", Vector3(cx + sx * 2.8, y, cz - 1.4), Vector3(cx + sx * 2.1, y + 3.2, cz + 1.3), 0.14, 0.14)
	U.blk(lm, "Yellow", cx, RIM + 14.8, cz, 5.0, 2.0, 3.6)
	# Boom reaching out over the basin and up.
	lm.beam("Yellow", Vector3(cx, RIM + 15.5, cz), Vector3(cx + 9.0, 21.5, cz - 13.0), 0.5, 0.5)
	lm.beam("Yellow", Vector3(cx + 0.4, RIM + 15.5, cz), Vector3(cx + 9.4, 21.7, cz - 13.0), 0.15, 0.15)
	lm.beam("Iron", Vector3(cx + 9.0, 21.5, cz - 13.0), Vector3(cx + 9.0, RIM + 9.0, cz - 13.0), 0.04, 0.04)
	# Grey lattice mast beyond the head of the dock.
	var mx := HL + 8.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Iron", Vector3(mx + sx * 2.2, 0.0, 6.0 + sz * 2.2), Vector3(mx + sx * 0.9, 16.0, 6.0 + sz * 0.9), 0.3, 0.3)
	for k in 4:
		var y := 2.0 + float(k) * 3.6
		lm.box("Iron", Vector3(mx, y, 6.0), Vector3(3.6 - 0.5 * float(k), 0.2, 3.6 - 0.5 * float(k)))
