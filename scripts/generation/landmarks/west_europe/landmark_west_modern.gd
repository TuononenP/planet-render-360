class_name LandmarkWestModern
extends RefCounted

## Four modern western-European icons in true metres, y = 0 at street
## level: the Atomium, the London Eye, The Shard and 30 St Mary Axe.

## Atomium (102 m): nine 18 m aluminium spheres on the corners and centre
## of a cube balanced on one vertex, joined by 3.3 m tubes along the
## twelve cube edges and the eight diagonals, on three splayed legs.
static func atomium(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sphere", LandmarkMaterials.paint("#C7CCD1", 0.3, 0.85))
	lm.use("Tube", LandmarkMaterials.paint("#B3B9BF", 0.38, 0.8))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B4AA", 4.0))
	var edge := 48.5
	var centre := Vector3(0, 51, 0)
	var yv := Vector3(1, 1, 1).normalized()
	var xv := Vector3(1, -1, 0).normalized()
	var to_world := Basis(xv, yv, xv.cross(yv)).transposed()
	var corners: Array[Vector3] = []
	for i in 8:
		var p := Vector3(1 if i & 1 else -1, 1 if i & 2 else -1, 1 if i & 4 else -1) * edge * 0.5
		corners.append(centre + to_world * p)
	for i in 8:
		LandmarkWestKit.tube(lm, "Tube", centre, corners[i], 1.65)
		for bit in [1, 2, 4]:
			if (i & bit) == 0:
				LandmarkWestKit.tube(lm, "Tube", corners[i], corners[i | bit], 1.65)
	var prof := PackedVector2Array()
	for k in 13:
		var t := PI * float(k) / 12.0
		prof.append(Vector2(sin(t) * 9.0, 9.0 - cos(t) * 9.0))
	var spheres: Array[Vector3] = corners.duplicate()
	spheres.append(centre)
	for p in spheres:
		lm.lathe("Sphere", p - Vector3(0, 9, 0), prof, 20)
		# Three splayed legs from the lower ring of spheres to footings.
		if p.y > 30.0 and p.y < 45.0:
			var foot := Vector3(p.x * 1.25, 0, p.z * 1.25)
			lm.beam("Tube", p - Vector3(0, 6, 0), foot + Vector3(0, 0.5, 0), 2.2)
			lm.box("Concrete", foot + Vector3(0, 0.5, 0), Vector3(7.0, 1.0, 7.0))
	lm.commit(model)

## London Eye (135 m): 120 m cable-spoked wheel in the plane of the
## river (axle along X), 32 egg-shaped glass capsules, cantilevered from
## the hub over the water on a single A-frame on the east bank (+X).
static func london_eye(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#EEF0F2", 0.45, 0.55))
	lm.use("Cable", LandmarkMaterials.paint("#B9C0C7", 0.5, 0.7))
	lm.use("Capsule", LandmarkMaterials.glass("#7F97A6"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDB9B0", 4.0))
	var hub := Vector3(0, 74.0, 0)
	var r := 58.0
	var seg := 48
	var pts: Array[Vector3] = []
	for k in seg:
		var a := TAU * float(k) / float(seg)
		pts.append(Vector3(0, cos(a) * r, sin(a) * r))
	for k in seg:
		for sx in [-1.5, 1.5]:
			lm.beam("Steel", hub + pts[k] + Vector3(sx, 0, 0), hub + pts[(k + 1) % seg] + Vector3(sx, 0, 0),
				1.0, 1.0, Vector3.RIGHT)
		lm.beam("Steel", hub + pts[k] + Vector3(-1.5, 0, 0), hub + pts[(k + 1) % seg] + Vector3(1.5, 0, 0), 0.45)
		if k % 2 == 0:
			for sx in [-1.0, 1.0]:
				lm.beam("Cable", hub + Vector3(sx * 3.0, 0, 0), hub + pts[k] + Vector3(-sx * 1.5, 0, 0), 0.2)
	lm.beam("Steel", hub + Vector3(-4.0, 0, 0), hub + Vector3(8.0, 0, 0), 4.0)
	# Egg-shaped capsules hanging upright outside the rim.
	var egg := PackedVector2Array()
	for k in 7:
		var t := PI * float(k) / 6.0
		egg.append(Vector2(sin(t) * 2.0, 2.0 - cos(t) * 2.0))
	for k in 32:
		var a := TAU * (float(k) + 0.5) / 32.0
		var c := hub + Vector3(0, cos(a), sin(a)) * (r + 1.3)
		lm.lathe("Capsule", c - Vector3(0, 2.0, 0), egg, 12, 1.3, 1.0)
		lm.beam("Steel", hub + Vector3(0, cos(a), sin(a)) * r, c, 0.4)
	# A-frame (legs spread along the river), tie and boarding pier.
	for sz in [-1.0, 1.0]:
		lm.beam("Steel", Vector3(8.0, 74.0, 0), Vector3(40.0, 1.0, sz * 30.0), 3.0)
		lm.box("Concrete", Vector3(40.0, 0.75, sz * 30.0), Vector3(9.0, 1.5, 9.0))
	lm.beam("Steel", Vector3(24.0, 38.0, -15.0), Vector3(24.0, 38.0, 15.0), 1.6)
	lm.box("Concrete", Vector3(-2.0, 1.0, 0), Vector3(36.0, 2.0, 40.0))
	lm.commit(model)

## The Shard (309.6 m): the pyramidal glass tower of fractured facets
## tapering from the 49 m base, floor-band rings, and the splintered
## shards of the crown round the central spire.
static func shard(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#9DB5C2"))
	lm.use("Fins", LandmarkMaterials.paint("#C9D1D6", 0.3, 0.85))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9A59C", 4.0))
	var top := 250.0
	lm.spire("Glass", Vector3.ZERO, 26.0, top, 6.0)
	# Facets breaking out of the four corners, each a different height.
	var facets := [[15.0, 14.0, 130.0], [-15.0, 14.0, 175.0], [15.0, -14.0, 205.0], [-15.0, -14.0, 160.0]]
	for f in facets:
		lm.spire("Glass", Vector3(f[0], 0, f[1]), 12.0, f[2], 0.0)
	# Splintered crown and the top spire (309.6 m).
	lm.spire("Glass", Vector3(0, top, 0), 6.0, 59.6, 0.0)
	for f in [[3.0, 3.0, 40.0], [-3.0, 3.0, 50.0], [3.0, -3.0, 32.0], [-3.0, -3.0, 46.0]]:
		lm.spire("Glass", Vector3(f[0], top - 20.0, f[1]), 4.5, 20.0 + f[2], 0.0)
	# Floor bands every 40 m, corner fins and the viewing-gallery block.
	for k in 6:
		var y := 30.0 + 40.0 * float(k)
		var hw := 26.0 - 20.0 * y / top
		lm.spire("Fins", Vector3(0, y, 0), hw + 0.3, 1.4, hw + 0.2)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Fins", Vector3(sx * 26.0, 0, sz * 26.0), Vector3(sx * 6.0, top, sz * 6.0), 1.0, 1.0)
	lm.box("Fins", Vector3(0, 245.0, 0), Vector3(12.0, 2.0, 12.0))
	lm.frustum("Concrete", Vector3(0, -1.0, 0), 44.0, 44.0, 1.0, 4, PI * 0.25)
	lm.commit(model)

## 30 St Mary Axe, "The Gherkin" (180 m): the bulging 41-storey tower
## (49 m at the foot, 56.5 m at its belly), a glass skin on a steel
## diagrid with six spiralling dark light-wells and the lens-shaped
## cap.
static func gherkin(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#6D8A96"))
	lm.use("Well", LandmarkMaterials.glass("#1F2E34"))
	lm.use("Frame", LandmarkMaterials.paint("#AEB6BC", 0.35, 0.8))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9A59C", 4.0))
	var table := PackedVector2Array([Vector2(0, 24.5), Vector2(8, 25.5), Vector2(30, 27.8),
		Vector2(56, 28.25), Vector2(80, 26.5), Vector2(105, 23.0), Vector2(130, 18.0),
		Vector2(150, 13.0), Vector2(165, 8.5), Vector2(175, 4.5), Vector2(180, 0.0)])
	var steps := 36
	var prof := PackedVector2Array()
	for j in steps + 1:
		var y := 180.0 * float(j) / float(steps)
		prof.append(Vector2(LandmarkMesh.profile_at(table, y) if j < steps else 0.0, y))
	lm.lathe("Glass", Vector3.ZERO, prof, 24)
	# Diagrid: two opposed families of helices, plus six light-well spirals.
	for dir in [-1.0, 1.0]:
		for i in 14:
			var a0 := TAU * float(i) / 14.0
			for j in range(0, steps - 2, 2):
				var p0 := prof[j]
				var p1 := prof[j + 2]
				var a_0: float = a0 + dir * p0.y * 0.012
				var a_1: float = a0 + dir * p1.y * 0.012
				lm.beam("Frame", Vector3(cos(a_0), 0, sin(a_0)) * (p0.x + 0.25) + Vector3(0, p0.y, 0),
					Vector3(cos(a_1), 0, sin(a_1)) * (p1.x + 0.25) + Vector3(0, p1.y, 0), 0.5, 0.4)
	for i in 6:
		var a0 := TAU * float(i) / 6.0
		for j in range(0, steps - 2, 2):
			var p0 := prof[j]
			var p1 := prof[j + 2]
			var a_0 := a0 + p0.y * 0.012
			var a_1 := a0 + p1.y * 0.012
			lm.beam("Well", Vector3(cos(a_0), 0, sin(a_0)) * (p0.x + 0.12) + Vector3(0, p0.y, 0),
				Vector3(cos(a_1), 0, sin(a_1)) * (p1.x + 0.12) + Vector3(0, p1.y, 0), 3.4, 0.3,
				Vector3(-sin(a_0), 0, cos(a_0)))
	lm.frustum("Concrete", Vector3(0, -1.0, 0), 34.0, 34.0, 1.0, 24)
	lm.commit(model)
