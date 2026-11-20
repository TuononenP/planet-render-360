extends RefCounted

## King's Gate (Kuninkaanportti, 1753-54), the sea gate of Suomenlinna in
## the Kustaanmiekka shore bastion, Susisaari. Front +Z is the harbour
## side, where the broad granite flight climbs to the gate.
##
## What the Commons photographs show (visual-plan/refs/landmarks/
## suomenlinna_kings_gate/): not a classical portico, but a plain ashlar
## granite pier with a rusticated round-headed arch (wedge voussoirs and a
## keystone under a stepped cornice), set in a curtain wall of grey and
## pink rubble granite. The wall carries a lighter string course, a
## coping, narrow loopholes and plaques, and the grassed earth rampart
## rises behind it. From the harbour the wall curves round the foot of the
## flight; the rear face has a flat-headed passage and low vaulted
## casemates either side.
##
## Measured from OSM: the gate point (node 3023195951 and the footway
## way 117478902 give the passage axis, 1.6 m long, 10 deg east of north),
## so yaw 191 turns +Z to the harbour; the wall footprint of building:part
## way 1258400732 (a 30 m deep wedge with one wing running out toward the
## harbour on the +X side). Estimated from the photos, not measured:
## every height, the arch size (3.2 x 4.6 m), the flight (14 treads), the
## wing curves and the loophole spacing.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "suomenlinna_kings_gate", "name": "Suomenlinna King's Gate", "lat": 60.139581, "lon": 24.989941,
	"radius_m": 4500.0, "wiki_title": "Suomenlinna", "height_m": 11.3, "clear_m": 32.0,
	"yaw_deg": 191.0, "kind": "Gate",
	"aliases": ["suomenlinna king's gate", "kuninkaanportti", "kungsporten suomenlinna"]}

## Landing level of the gate floor above the foot of the flight, curtain
## wall height, gate pier height (all above the foot of the flight).
const LANDING := 2.3
const WALL := 7.0
const PIER := 11.0
const PIER_HW := 4.3
const REAR := -9.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rubble", LandmarkMaterials.pbr("stone", "#827970", 3.0))
	lm.use("Ashlar", LandmarkMaterials.pbr("limestone", "#A39B90", 2.0))
	lm.use("Joint", LandmarkMaterials.paint("#6E675F", 0.9, 0.0))
	lm.use("Grass", LandmarkMaterials.pbr("grass", "#8E8E5A", 4.0))
	lm.use("Dark", LandmarkMaterials.paint("#15120F", 0.9, 0.0))
	lm.use("Iron", LandmarkMaterials.paint("#2A2C2B", 0.55, 0.5))
	lm.use("Gravel", LandmarkMaterials.pbr("gravel", "#A89E8A", 3.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A0", 0.9))
	_ground(lm)
	_wings(lm)
	_pier(lm)
	_rear(lm)
	_flight(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-6.0, 3.0, 22.0), Vector3(0.0, 7.0, 1.8), 34.0, 0.9, 40.0, Color(1.0, 0.88, 0.68)],
		[Vector3(7.0, 3.0, 22.0), Vector3(0.0, 7.0, 1.8), 34.0, 0.7, 40.0, Color(1.0, 0.88, 0.68)]])

## Gravel apron before the gate and the rampart earth behind it.
static func _ground(lm: LandmarkMesh) -> void:
	lm.box("Gravel", Vector3(0.0, 0.04, 8.0), Vector3(34.0, 0.08, 34.0))

## A wall run along `path` (XZ points), thick `t`, from y0 up `h`: boxes
## along each segment, a string course, a coping and a grass top.
static func _run(lm: LandmarkMesh, path: Array, t: float, y0: float, h: float, loops: bool = true) -> void:
	for i in path.size() - 1:
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var d := b - a
		var yaw := atan2(d.x, d.y)
		var m := (a + b) * 0.5
		var basis := Basis(Vector3.UP, yaw)
		var ln := d.length() + 0.25
		lm.box("Rubble", Vector3(m.x, y0 + h * 0.5, m.y), Vector3(t, h, ln), basis)
		# String course at two thirds, coping on top, grass behind it.
		lm.box("Ashlar", Vector3(m.x, y0 + h * 0.62, m.y), Vector3(t + 0.14, 0.3, ln), basis)
		lm.box("Ashlar", Vector3(m.x, y0 + h + 0.12, m.y), Vector3(t + 0.2, 0.28, ln), basis)
		lm.box("Grass", Vector3(m.x, y0 + h + 0.36, m.y), Vector3(t - 0.1, 0.2, ln), basis)
		if loops:
			var out := Vector3(cos(yaw), 0, -sin(yaw))
			for k in int(d.length() / 3.5):
				var p := a.lerp(b, (float(k) + 0.5) * 3.5 / d.length())
				for s in [-1.0, 1.0]:
					var c: Vector3 = Vector3(p.x, y0 + h * 0.8, p.y) + out * float(s) * (t * 0.5 + 0.02)
					lm.box("Dark", c, Vector3(0.12, 0.7, 0.12) + Vector3(absf(out.x), 0, absf(out.z)) * 0.06)
				if k % 2 == 0:
					lm.box("Ashlar", Vector3(p.x, y0 + h * 0.8 - 0.55, p.y) + out * (t * 0.5 + 0.03),
						Vector3(0.9, 0.7, 0.07), basis)

## The two curtain wings: the +X one swings out toward the harbour as
## mapped, the -X one is shorter and straighter.
static func _wings(lm: LandmarkMesh) -> void:
	var right := [Vector2(PIER_HW - 0.4, 0.4), Vector2(7.2, 4.0), Vector2(8.8, 8.4), Vector2(11.4, 13.0),
		Vector2(15.4, 17.2), Vector2(18.2, 19.6)]
	var left := [Vector2(-PIER_HW + 0.4, 0.4), Vector2(-8.4, 1.2), Vector2(-12.6, 3.0), Vector2(-17.0, 6.0),
		Vector2(-20.0, 9.5)]
	_run(lm, right, 3.4, 0.0, WALL)
	_run(lm, left, 3.4, 0.0, WALL)

## The gate pier: ashlar block with the rusticated arch and the cornice.
static func _pier(lm: LandmarkMesh) -> void:
	var zf := 1.8
	U.blk(lm, "Ashlar", 0.0, 0.0, (zf + REAR) * 0.5, 2.0 * PIER_HW, PIER, zf - REAR)
	# Ashlar courses on the front and the sides: thin dark joints.
	var y := 0.7
	while y < PIER - 1.2:
		lm.box("Joint", Vector3(0.0, y, zf + 0.012), Vector3(2.0 * PIER_HW + 0.02, 0.06, 0.04))
		for s in [-1.0, 1.0]:
			lm.box("Joint", Vector3(s * (PIER_HW + 0.012), y, (zf + REAR) * 0.5), Vector3(0.04, 0.06, zf - REAR))
		y += 0.72
	# Quoins: alternate long and short blocks up each front corner.
	for k in 14:
		for s in [-1.0, 1.0]:
			var w := 1.1 if k % 2 == 0 else 0.7
			lm.box("Ashlar", Vector3(s * (PIER_HW - w * 0.5), 0.35 + float(k) * 0.72, zf + 0.06),
				Vector3(w, 0.66, 0.14))
	# The arch: dark passage, wedge voussoirs, keystone, impost blocks.
	var spring := LANDING + 3.0
	var hw := 1.6
	U.blk(lm, "Dark", 0.0, LANDING, zf + 0.02, 2.0 * hw, 3.0, 0.05)
	U.opening(lm, "Dark", Vector3(0.0, spring, zf + 0.03), Vector3(0, 0, 1), 2.0 * hw, hw, true)
	LandmarkDetail.arch(lm, "Ashlar", Vector3(0.0, spring, zf), Vector3(0, 0, 1), 2.0 * hw, 0.62, 0.4, 13)
	for s in [-1.0, 1.0]:
		U.blk(lm, "Ashlar", s * (hw + 0.1), spring - 0.3, zf, 0.5, 0.3, 0.45)
		U.blk(lm, "Ashlar", s * (hw + 0.45), LANDING, zf, 0.5, 3.0, 0.4)
	# Stepped cornice and the grass capping the pier.
	U.blk(lm, "Ashlar", 0.0, PIER - 0.9, (zf + REAR) * 0.5, 2.0 * PIER_HW + 0.8, 0.5, zf - REAR + 0.8)
	U.blk(lm, "Ashlar", 0.0, PIER - 0.4, (zf + REAR) * 0.5, 2.0 * PIER_HW + 1.2, 0.4, zf - REAR + 1.2)
	U.blk(lm, "Grass", 0.0, PIER, (zf + REAR) * 0.5, 2.0 * PIER_HW - 0.2, 0.3, zf - REAR - 0.4)
	# A tablet over the arch.
	U.blk(lm, "Joint", 0.0, spring + 2.3, zf + 0.02, 2.6, 1.2, 0.08)
	# Passage floor and the dark tunnel through the pier (seen from the rear).
	U.blk(lm, "Dark", 0.0, LANDING, REAR + 0.02, 2.0 * hw, 3.3, 0.05)

## Rear: the plain face with its flat-headed passage and two vaulted
## casemates in the rubble wall either side.
static func _rear(lm: LandmarkMesh) -> void:
	U.blk(lm, "Rubble", 0.0, 0.0, REAR + 2.0, 29.0, WALL, 4.0)
	U.blk(lm, "Ashlar", 0.0, WALL + 0.0, REAR + 2.0, 29.4, 0.3, 4.4)
	U.blk(lm, "Grass", 0.0, WALL + 0.3, REAR + 2.0, 28.8, 0.3, 3.8)
	for s in [-1.0, 1.0]:
		var cx: float = s * 9.0
		U.opening(lm, "Dark", Vector3(cx, 0.4, REAR - 0.02), Vector3(0, 0, -1), 4.4, 3.6, true)
		LandmarkDetail.arch(lm, "Ashlar", Vector3(cx, 0.4 + 2.2, REAR), Vector3(0, 0, -1), 4.4, 0.4, 0.3, 11)
	# Lintel over the rear passage.
	U.blk(lm, "Ashlar", 0.0, LANDING + 3.2, REAR - 0.15, 4.2, 0.6, 0.4)

## The flight of broad granite steps and the iron rails along it.
static func _flight(lm: LandmarkMesh) -> void:
	var zf := 1.8
	U.steps(lm, "Ashlar", Vector3(0.0, 0.0, zf), Vector3(0, 0, 1), 9.2, 0.5, LANDING / 14.0, 14)
	for s in [-1.0, 1.0]:
		U.blk(lm, "Ashlar", s * 4.9, 0.0, zf + 3.6, 0.6, 1.1, 7.2)
		for k in 6:
			var z := zf + 0.6 + float(k) * 1.3
			var h := LANDING - (z - zf) / 0.5 * LANDING / 14.0
			lm.beam("Iron", Vector3(s * 4.3, h, z), Vector3(s * 4.3, h + 1.0, z), 0.06, 0.06)
		lm.beam("Iron", Vector3(s * 4.3, LANDING + 1.0, zf + 0.6), Vector3(s * 4.3, 1.1, zf + 7.4), 0.07, 0.07)
		# Lamp post at the head of the flight.
		lm.frustum("Iron", Vector3(s * 5.6, 0.0, zf + 1.2), 0.1, 0.08, 4.4, 6)
		lm.frustum("Lamp", Vector3(s * 5.6, 4.4, zf + 1.2), 0.3, 0.22, 0.5, 8)
