class_name LandmarkEgAlexandria
extends RefCounted

## Two landmarks of the Alexandria waterfront in true metres, +X east and
## -Z north (the sea): the Mamluk Citadel of Qaitbay on the Pharos spit
## and the Bibliotheca Alexandrina.

# --- Citadel of Qaitbay ---

## The 1477 sea fort: a 100 x 68 m curtain wall of 9 m with merlons and
## round corner towers, the gate towers on the east side and the square
## keep with its corner towers, upper storey, central tower and the
## small lead dome of the mosque at 24 m.
static func qaitbay(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#D2BC90", 3.5))
	lm.use("Lead", LandmarkMaterials.paint("#8E949A", 0.5, 0.3))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#A39278", 6.0))
	lm.box("Rock", Vector3(0, -3.0, 0), Vector3(112.0, 6.0, 80.0))
	lm.box("Rock", Vector3(0, -0.1, 0), Vector3(106.0, 0.5, 74.0))
	var hx := 50.0
	var hz := 34.0
	LandmarkEgParts.wall(lm, "Wall", Vector2(-hx, -hz), Vector2(hx, -hz), 9.0, 3.0)
	LandmarkEgParts.wall(lm, "Wall", Vector2(-hx, hz), Vector2(hx, hz), 9.0, 3.0)
	LandmarkEgParts.wall(lm, "Wall", Vector2(-hx, -hz), Vector2(-hx, hz), 9.0, 3.0)
	LandmarkEgParts.wall(lm, "Wall", Vector2(hx, -hz), Vector2(hx, hz), 9.0, 3.0)
	for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		lm.frustum("Wall", Vector3(s.x * hx, 0, s.y * hz), 6.2, 5.6, 12.0, 14)
		lm.frustum("Wall", Vector3(s.x * hx, 12.0, s.y * hz), 6.8, 6.8, 1.2, 14)
	for z in [-9.0, 9.0]:
		lm.frustum("Wall", Vector3(hx, 0, z), 3.6, 3.2, 11.5, 12)
	lm.box("Dark", Vector3(hx + 1.6, 3.0, 0), Vector3(0.4, 6.0, 5.0))
	# Merlons along the wall tops.
	for i in 30:
		var x := -hx + 4.0 + 3.1 * i
		for z in [-hz, hz]:
			lm.box("Wall", Vector3(x, 9.6, z), Vector3(1.3, 1.2, 3.0))
	for i in 19:
		var z := -hz + 4.0 + 3.1 * i
		for x in [-hx, hx]:
			lm.box("Wall", Vector3(x, 9.6, z), Vector3(3.0, 1.2, 1.3))
	# Keep: square block with round corner towers, upper storey, tower, dome.
	lm.box("Wall", Vector3(-2.0, 7.0, 0), Vector3(30.0, 14.0, 30.0))
	for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		lm.frustum("Wall", Vector3(-2.0 + s.x * 15.0, 0, s.y * 15.0), 5.0, 4.6, 17.0, 12)
		lm.frustum("Lead", Vector3(-2.0 + s.x * 15.0, 17.0, s.y * 15.0), 5.2, 0.0, 2.6, 12)
	lm.box("Wall", Vector3(-2.0, 15.75, 0), Vector3(20.0, 3.5, 20.0))
	lm.box("Wall", Vector3(-2.0, 18.75, 0), Vector3(9.0, 2.5, 9.0))
	lm.box("Dark", Vector3(-2.0, 4.0, 15.1), Vector3(4.0, 7.0, 0.4))
	LandmarkEgParts.dome(lm, "Lead", Vector3(-2.0, 20.0, 0), 3.2, 4.0, 14)
	lm.commit(model)

# --- Bibliotheca Alexandrina ---

## The 160 m cylinder of granite carved with letters of 120 alphabets,
## capped by a tilted disc roof of alternating glass and aluminium
## wedges that rises from 10 m on the sea side (-Z) to 32 m inland,
## standing on a round granite plaza.
static func bibliotheca(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8B86", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#6C8EA3"))
	lm.use("Alu", LandmarkMaterials.paint("#B9BEC2", 0.35, 0.6))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#BDB6A8", 6.0))
	var r := 80.0
	lm.disc("Plaza", Vector3(0, 0.15, 0), Vector3.UP, r + 14.0, 48)
	var foot := PackedVector3Array()
	var rim := PackedVector3Array()
	var n := 48
	for i in n + 1:
		var a := TAU * float(i) / float(n)
		foot.append(Vector3(r * sin(a), -3.0, r * cos(a)))
		rim.append(Vector3(r * sin(a), _roof_y(r * cos(a)), r * cos(a)))
	lm.grid("Granite", [foot, rim], Vector3.ZERO, true)
	# Tilted roof disc in wedges: centre cap, then two rings.
	var normal := Vector3(0, 1.0, -11.0 / 80.0).normalized()
	var radii: Array[float] = [0.0, 30.0, 58.0, r]
	for i in n:
		var key := "Glass" if i % 4 < 2 else "Alu"
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		for k in 3:
			var p0 := _roof_pt(radii[k], a0)
			var p1 := _roof_pt(radii[k], a1)
			var q0 := _roof_pt(radii[k + 1], a0)
			var q1 := _roof_pt(radii[k + 1], a1)
			if k == 0:
				lm.tri(key, p0, q1, q0, normal, normal, normal, Vector2(p0.x, p0.z),
					Vector2(q1.x, q1.z), Vector2(q0.x, q0.z))
			else:
				lm.quad(key, p0, p1, q1, q0, normal)
	# Aluminium rim ring.
	for i in n:
		lm.beam("Alu", rim[i] - Vector3(0, 0.2, 0), rim[i + 1] - Vector3(0, 0.2, 0), 1.0, 1.4,
			Vector3.UP, true)
	lm.commit(model)

## Roof plane height at depth z (10 m at the sea side, 32 m inland).
static func _roof_y(z: float) -> float:
	return 20.7 + 11.0 * z / 80.0

static func _roof_pt(rad: float, a: float) -> Vector3:
	var z := rad * cos(a)
	return Vector3(rad * sin(a), _roof_y(z), z)
