class_name LandmarkWestModern
extends RefCounted

## Four modern western-European icons in true metres, y = 0 at street
## level: the Atomium, the London Eye, The Shard and 30 St Mary Axe.

## Atomium (102 m, 1958): nine 18 m stainless-steel spheres on the
## corners and centre of an iron-crystal cube balanced on one vertex,
## clad in triangular panels; 3.3 m tubes along the twelve cube edges
## and the eight diagonals (escalators in the oblique ones, a lift in
## the vertical one); the windowed restaurant band of the top sphere and
## the portholes of the other public spheres; the three bipods under the
## lower ring of spheres; and the entrance pavilion at the foot.
static func atomium(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sphere", LandmarkMaterials.paint("#C7CCD1", 0.3, 0.85))
	lm.use("Tube", LandmarkMaterials.paint("#B3B9BF", 0.38, 0.8))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B4AA", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#3A4A55"))
	var edge := 48.5
	var centre := Vector3(0, 51.12, 0)
	var yv := Vector3(1, 1, 1).normalized()
	var xv := Vector3(1, -1, 0).normalized()
	var to_world := Basis(xv, yv, xv.cross(yv)).transposed()
	var corners: Array[Vector3] = []
	for i in 8:
		var p := Vector3(1 if i & 1 else -1, 1 if i & 2 else -1, 1 if i & 4 else -1) * edge * 0.5
		corners.append(centre + to_world * p)
	for i in 8:
		_atom_tube(lm, centre, corners[i])
		for bit in [1, 2, 4]:
			if (i & bit) == 0:
				_atom_tube(lm, corners[i], corners[i | bit])
	var prof := PackedVector2Array()
	for k in 17:
		var t := PI * float(k) / 16.0
		prof.append(Vector2(sin(t) * 9.0, 9.0 - cos(t) * 9.0))
	var spheres: Array[Vector3] = corners.duplicate()
	spheres.append(centre)
	for p in spheres:
		lm.lathe("Sphere", p - Vector3(0, 9, 0), prof, 28)
		# Panel seams: latitude rings and meridians standing proud.
		for lat in [-0.55, 0.0, 0.55]:
			var y: float = 9.0 * sin(float(lat))
			var rr: float = 9.0 * cos(float(lat)) + 0.06
			lm.frustum("Tube", p + Vector3(0, y - 0.08, 0), rr, rr, 0.16, 28)
		for m in 6:
			var a := PI * float(m) / 6.0
			var d := Vector3(cos(a), 0, sin(a))
			for k in 16:
				var t0 := TAU * float(k) / 16.0
				var t1 := TAU * float(k + 1) / 16.0
				lm.beam("Tube", p + (d * cos(t0) + Vector3.UP * sin(t0)) * 9.06, p + (d * cos(t1) + Vector3.UP * sin(t1)) * 9.06,
					0.14, 0.1)
		# Three splayed bipods from the lower ring of spheres to footings.
		if p.y > 30.0 and p.y < 45.0:
			var out := Vector3(p.x, 0, p.z).normalized()
			var side := out.cross(Vector3.UP)
			for s in [-1.0, 1.0]:
				var foot := Vector3(p.x, 0, p.z) * 1.22 + side * 5.0 * float(s)
				lm.beam("Tube", p - Vector3(0, 7.5, 0), foot + Vector3(0, 1.0, 0), 1.6, 1.6)
				lm.box("Concrete", foot + Vector3(0, 0.5, 0), Vector3(5.0, 1.0, 5.0))
	# Top sphere: the restaurant's window band; portholes on the lower spheres.
	var top := centre
	for p in spheres:
		if p.y > top.y:
			top = p
	lm.frustum("Glass", top + Vector3(0, 1.0, 0), 9.05, 8.7, 2.2, 28)
	lm.frustum("Glass", top + Vector3(0, -3.6, 0), 8.3, 8.95, 2.6, 28)
	for p in spheres:
		if p.y < 45.0 or p == centre:
			for k in 10:
				var a := TAU * float(k) / 10.0
				var d := Vector3(cos(a), 0, sin(a))
				lm.disc("Glass", p + d * 9.02 + Vector3(0, 0.8, 0), d, 0.9, 10)
	# Entrance pavilion round the foot of the bottom sphere.
	lm.frustum("Concrete", Vector3.ZERO, 14.0, 14.0, 0.6, 24)
	lm.box("Concrete", Vector3(0, 2.4, 13.0), Vector3(16.0, 4.8, 8.0))
	lm.box("Glass", Vector3(0, 2.2, 17.05), Vector3(14.0, 3.6, 0.1), Basis(), 0.0)
	lm.box("Concrete", Vector3(0, 4.95, 13.5), Vector3(18.0, 0.3, 10.0))
	lm.commit(model)

## One 3.3 m connecting tube between two sphere centres: a 14-sided
## barrel between the sphere skins, collar flanges at both ends and a
## strip of windows along its side.
static func _atom_tube(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var dir := (b - a).normalized()
	var a1 := a + dir * 8.4
	var b1 := b - dir * 8.4
	LandmarkWestKit.tube(lm, "Tube", a1, b1, 1.65, 14)
	for e in [a1 + dir * 0.5, b1 - dir * 0.5]:
		var ep: Vector3 = e
		LandmarkWestKit.tube(lm, "Tube", ep - dir * 0.4, ep + dir * 0.4, 1.95, 14)
	var side := dir.cross(Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT).normalized()
	var up := side.cross(dir).normalized()
	if up.y < 0.0:
		up = -up
	lm.beam("Glass", a1 + dir * 1.5 + up * 1.62, b1 - dir * 1.5 + up * 1.62, 0.9, 0.06, side)

## London Eye: built by LandmarkLondonEye.
static func london_eye(model: Node3D) -> void:
	LandmarkLondonEye.build(model)

## The Shard: built by LandmarkLondonTowers.
static func shard(model: Node3D) -> void:
	LandmarkLondonTowers.shard(model)

## 30 St Mary Axe, "the Gherkin": built by LandmarkLondonTowers.
static func gherkin(model: Node3D) -> void:
	LandmarkLondonTowers.gherkin(model)
