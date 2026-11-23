class_name LandmarkMiDouglasEntrance
extends RefCounted

## Douglas Entrance, La Puerta del Sol (MI-10). OSM way 435375023 (25.764887, -80.255528, yaw -2.6).
## Paist & Fink (1927): 73.5 x 28.2 m Mediterranean Revival gateway straddling the road.
##   - Central stone-vaulted vehicular portal, 11 m wide x 6.8 m tall, open through Z.
##   - 2-3 storey coral-stone and stucco wings, iron balconies, clay barrel-tile roofs.
##   - Stout square crenellated bell tower reaching exactly 24.0 m.
## Local axes: road runs along Z; the long facade runs along X.

const HEIGHT_M := 24.0
const PORTAL_W := 11.0
const PORTAL_H := 6.8
const DEPTH := 12.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6C6A0", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#EBD9B4", 3.2))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B5502B", 2.4))
	lm.use("Iron", LandmarkMaterials.paint("#24272A", 0.5, 0.6))
	lm.use("Glass", LandmarkMaterials.glass("#2F3F48"))
	lm.use("Frieze", LandmarkMaterials.paint("#2F6B8A", 0.7, 0.0))
	_build_gate(lm)
	_build_wings(lm)
	_build_tower(lm)
	lm.commit(model)

static func _build_gate(lm: LandmarkMesh) -> void:
	var hw := PORTAL_W * 0.5
	# gate piers either side of the clear portal
	for sx: float in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * (hw + 2.2), 5.0, 0.0), Vector3(4.4, 10.0, DEPTH), Basis(), 0.0)
		lm.box("Frieze", Vector3(sx * (hw + 2.2), 10.15, 0.0), Vector3(4.6, 0.3, DEPTH + 0.2), Basis(), 0.0)
	# vault: semicircular ring springing at y=1.3; inner face leaves 11 m x 6.8 m clear
	var n := 14
	var spring := PORTAL_H - hw
	var prev := Vector3(-(hw + 0.5), spring, 0.0)
	for i: int in n + 1:
		var a := PI - PI * float(i) / float(n)
		var cur := Vector3(cos(a) * (hw + 0.5), spring + sin(a) * (hw + 0.5), 0.0)
		if i > 0:
			lm.beam("Stone", prev, cur, 1.0, DEPTH, Vector3(0, 0, 1))
		prev = cur
	for sx: float in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * (hw - 0.5), 5.9, 0.0), Vector3(1.0, 2.8, DEPTH), Basis(), 0.0)
	# spandrel infill over the arch up to lintel
	lm.box("Stone", Vector3(0.0, (PORTAL_H + 0.6 + 10.0) * 0.5 + 0.3, 0.0),
		Vector3(PORTAL_W, 10.0 - PORTAL_H - 0.6 + 0.0, DEPTH), Basis(), 0.0)
	lm.box("Frieze", Vector3(0.0, 9.0, DEPTH * 0.5 + 0.05), Vector3(PORTAL_W, 0.5, 0.1), Basis(), 0.0)
	# crenellations along gate top
	for k: int in 9:
		var x := -hw - 4.0 + float(k) * ((PORTAL_W + 8.0) / 8.0)
		lm.box("Stone", Vector3(x, 10.9, 0.0), Vector3(0.9, 1.0, DEPTH), Basis(), 0.0)

static func _build_wings(lm: LandmarkMesh) -> void:
	var inner := PORTAL_W * 0.5 + 4.4
	var wing_l := 36.75 - inner
	for sx: float in [-1.0, 1.0]:
		var cx := sx * (inner + wing_l * 0.5)
		var h := 8.0 if sx < 0.0 else 9.5
		lm.box("Stucco", Vector3(cx, h * 0.5, 0.0), Vector3(wing_l, h, DEPTH - 1.0), Basis(), 0.0)
		lm.box("Stone", Vector3(cx, 0.6, 0.0), Vector3(wing_l + 0.2, 1.2, DEPTH - 0.6), Basis(), 0.0)
		lm.gable("Tile", Vector3(cx, h, 0.0), DEPTH + 0.4, wing_l + 0.6, 2.2, Basis(Vector3.UP, PI * 0.5), 0.0, "Stucco")
		# windows, iron balconies, arched ground-floor doors on both faces
		var bays := int(wing_l / 4.0)
		for k: int in bays:
			var x := cx - wing_l * 0.5 + (float(k) + 0.5) * wing_l / float(bays)
			for face: float in [-1.0, 1.0]:
				var z := face * (DEPTH * 0.5 - 0.45)
				lm.box("Glass", Vector3(x, 2.3, z), Vector3(1.3, 2.4, 0.12), Basis(), 0.0)
				lm.box("Glass", Vector3(x, 5.6, z), Vector3(1.2, 1.9, 0.12), Basis(), 0.0)
				lm.box("Iron", Vector3(x, 4.6, z + face * 0.45), Vector3(2.0, 0.1, 0.9), Basis(), 0.0)
				lm.box("Iron", Vector3(x, 5.1, z + face * 0.88), Vector3(2.0, 0.9, 0.06), Basis(), 0.0)
				lm.box("Stone", Vector3(x, 7.2 if h < 9.0 else 7.4, z), Vector3(1.6, 0.25, 0.18), Basis(), 0.0)

static func _build_tower(lm: LandmarkMesh) -> void:
	var tx := PORTAL_W * 0.5 + 4.4 + 4.0
	var tz := 0.0
	# stout square Spanish bell tower on the east wing
	lm.box("Stucco", Vector3(tx, 10.5, tz), Vector3(7.0, 21.0, 7.0), Basis(), 0.0)
	lm.box("Stone", Vector3(tx, 9.6, tz), Vector3(7.5, 0.4, 7.5), Basis(), 0.0)
	lm.box("Frieze", Vector3(tx, 14.5, tz), Vector3(7.3, 0.35, 7.3), Basis(), 0.0)
	# belfry arched openings
	for d: Vector3 in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		lm.box("Glass", Vector3(tx, 18.0, tz) + d * 3.52,
			Vector3(0.12 + absf(d.z) * 1.8, 3.0, 0.12 + absf(d.x) * 1.8), Basis(), 0.0)
		lm.box("Stone", Vector3(tx, 19.7, tz) + d * 3.55,
			Vector3(0.14 + absf(d.z) * 2.3, 0.3, 0.14 + absf(d.x) * 2.3), Basis(), 0.0)
	# cornice, tiled pyramidal cap and crenellated corners to exactly 24.0 m
	lm.box("Stone", Vector3(tx, 21.0, tz), Vector3(7.8, 0.5, 7.8), Basis(), 0.0)
	lm.box("Stone", Vector3(tx, 21.6, tz), Vector3(7.0, 0.8, 7.0), Basis(), 0.0)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			lm.box("Stone", Vector3(tx + sx * 3.1, 22.4, tz + sz * 3.1), Vector3(0.9, 0.8, 0.9), Basis(), 0.0)
	lm.frustum("Tile", Vector3(tx, 22.0, tz), 3.6, 0.0, 1.8, 4, PI * 0.25)
	lm.beam("Iron", Vector3(tx, 23.8, tz), Vector3(tx, HEIGHT_M, tz), 0.06, 0.06, Vector3.RIGHT, true)
