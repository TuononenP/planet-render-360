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

## London Eye (135 m): the 120 m wheel in the plane of the river (axle
## along X): a rim of triangular-section truss — two outer chords and an
## inner chord laced with diagonals — tensioned by 64 spoke cables to
## the 23 m spindle; 32 ovoid glass capsules, 8 m long, each held in a
## pair of mounting rings outside the rim; the single A-frame of tapered
## legs on the east bank (+X) with its tie and backstay cables; and the
## boarding pier.
static func london_eye(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#EEF0F2", 0.45, 0.55))
	lm.use("Cable", LandmarkMaterials.paint("#B9C0C7", 0.5, 0.7))
	lm.use("Capsule", LandmarkMaterials.glass("#7F97A6"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDB9B0", 4.0))
	var hub := Vector3(0, 71.7, 0)
	var r := 58.0
	var seg := 64
	var at := func(a: float, rr: float, x: float) -> Vector3:
		return hub + Vector3(x, cos(a) * rr, sin(a) * rr)
	for k in seg:
		var a0 := TAU * float(k) / float(seg)
		var a1 := TAU * float(k + 1) / float(seg)
		for sx in [-1.5, 1.5]:
			lm.beam("Steel", at.call(a0, r, sx), at.call(a1, r, sx), 0.9, 0.9, Vector3.RIGHT)
		lm.beam("Steel", at.call(a0, r - 3.0, 0.0), at.call(a1, r - 3.0, 0.0), 0.7, 0.7, Vector3.RIGHT)
		# Lacing: across the outer chords and down to the inner chord.
		lm.beam("Steel", at.call(a0, r, -1.5), at.call(a1, r, 1.5), 0.3)
		for sx in [-1.5, 1.5]:
			lm.beam("Steel", at.call(a0, r, sx), at.call(a0, r - 3.0, 0.0), 0.3)
			lm.beam("Steel", at.call(a0, r - 3.0, 0.0), at.call(a1, r, sx), 0.25)
		# Spoke cables from both ends of the spindle.
		var sxs := -1.0 if k % 2 == 0 else 1.0
		lm.beam("Cable", hub + Vector3(sxs * 11.5, 0, 0), at.call(a0, r - 3.0, 0.0), 0.16)
	# Hub and spindle.
	LandmarkWestKit.tube(lm, "Steel", hub + Vector3(-11.5, 0, 0), hub + Vector3(11.5, 0, 0), 1.6, 16)
	for sx in [-11.5, -3.0, 3.0, 11.5]:
		LandmarkWestKit.tube(lm, "Steel", hub + Vector3(sx - 0.5, 0, 0), hub + Vector3(sx + 0.5, 0, 0), 3.2, 16)
	# Capsules: ovoids 8 m long along X in their pairs of mounting rings.
	var egg := PackedVector2Array()
	for k in 9:
		var t := PI * float(k) / 8.0
		egg.append(Vector2(sin(t) * 2.0, 2.0 - cos(t) * 2.0))
	for k in 32:
		var a := TAU * (float(k) + 0.5) / 32.0
		var dir := Vector3(0, cos(a), sin(a))
		var c := hub + dir * (r + 3.0)
		lm.lathe("Capsule", c - Vector3(0, 2.0, 0), egg, 16, 2.0, 1.0)
		lm.frustum("Steel", c - Vector3(0, 2.05, 0), 3.0, 3.0, 0.15, 12, 0.0, 1.0, 0.5)
		for sx in [-2.6, 2.6]:
			var ring_c := c + Vector3(sx, 0, 0)
			for j in 12:
				var t0 := TAU * float(j) / 12.0
				var t1 := TAU * float(j + 1) / 12.0
				lm.beam("Steel", ring_c + Vector3(0, cos(t0), sin(t0)) * 2.3, ring_c + Vector3(0, cos(t1), sin(t1)) * 2.3,
					0.22, 0.3, Vector3.RIGHT)
			lm.beam("Steel", hub + dir * r + Vector3(sx * 0.6, 0, 0), ring_c - dir * 2.3, 0.3)
	# A-frame of tapered legs, tie, backstays; footings and boarding pier.
	for sz in [-1.0, 1.0]:
		var foot := Vector3(40.0, 1.5, sz * 30.0)
		var top := hub + Vector3(10.0, 0, sz * 1.0)
		var steps := 6
		for i in steps:
			var t0 := float(i) / float(steps)
			var t1 := float(i + 1) / float(steps)
			var w := lerpf(4.2, 2.2, (t0 + t1) * 0.5)
			lm.beam("Steel", foot.lerp(top, t0), foot.lerp(top, t1), w, w)
		lm.box("Concrete", Vector3(40.0, 0.75, sz * 30.0), Vector3(10.0, 1.5, 10.0))
		lm.beam("Cable", top + Vector3(0, 1.0, 0), Vector3(80.0, 0.5, sz * 22.0), 0.25)
		lm.beam("Cable", top + Vector3(0, 1.0, 0), Vector3(80.0, 0.5, sz * 8.0), 0.25)
		lm.box("Concrete", Vector3(80.0, 0.5, sz * 15.0), Vector3(6.0, 1.0, 22.0))
	lm.beam("Steel", Vector3(24.0, 38.0, -15.6), Vector3(24.0, 38.0, 15.6), 1.6)
	lm.beam("Steel", Vector3(32.0, 18.0, -22.8), Vector3(32.0, 18.0, 22.8), 1.2)
	lm.box("Concrete", Vector3(-2.0, 1.0, 0), Vector3(36.0, 2.0, 40.0))
	for k in 9:
		lm.box("Steel", Vector3(-2.0 + float(k % 3 - 1) * 14.0, 4.0, -16.0 + 16.0 * floorf(float(k) / 3.0)), Vector3(0.4, 4.0, 0.4), Basis(), 0.0)
	lm.box("Steel", Vector3(-2.0, 6.1, 0), Vector3(34.0, 0.2, 38.0), Basis(), 0.0)
	lm.commit(model)

## The Shard (309.6 m, Renzo Piano, 2012): eight inclined glass facets
## ("shards") — two per side — rising from the irregular 58 x 48 m plan,
## the vertical fractures between them showing the winter-garden vents,
## floor lines every 3.9 m and mullions on the facets, the facets
## splintering apart above 288 m round the open steel spire, and the
## podium canopy at the foot.
static func shard(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#9DB5C2"))
	lm.use("Fins", LandmarkMaterials.paint("#C9D1D6", 0.3, 0.85))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9A59C", 4.0))
	lm.use("Dark", LandmarkMaterials.glass("#26323A"))
	# Each side: two facets meeting at a fracture; facet = (side, half,
	# top height, plan offset of the half).
	var hx := 29.0
	var hz := 24.0
	var tops := [[296.0, 304.0], [280.0, 306.0], [300.0, 288.0], [292.0, 298.0]]
	var apex := Vector3(0, 309.6, 0)
	for s in 4:
		var b := Basis(Vector3.UP, -PI * 0.5 * float(s))
		var half_w := hx if s % 2 == 0 else hz
		var depth := hz if s % 2 == 0 else hx
		var n: Vector3 = b * Vector3(0, 0, 1)
		var r: Vector3 = b * Vector3(1, 0, 0)
		for h in 2:
			var sgn := -1.0 if h == 0 else 1.0
			var top_h: float = tops[s][h]
			var shift := 0.9 * sgn
			# Base edge from the corner to just short of the fracture.
			var e0: Vector3 = r * sgn * half_w + n * (depth + shift)
			var e1: Vector3 = r * sgn * 1.2 + n * (depth + shift)
			var k := top_h / 309.6
			var t0: Vector3 = e0.lerp(Vector3.ZERO, k * 0.97) + Vector3(0, top_h, 0)
			var t1: Vector3 = e1.lerp(Vector3.ZERO, k * 0.97) + Vector3(0, top_h, 0)
			var fn := (e1 - e0).cross(t0 - e0).normalized()
			if fn.dot(n) < 0.0:
				fn = -fn
			lm.quad("Glass", e0, e1, t1, t0, fn)
			var back := Vector3(fn.x, 0, fn.z) * 0.6
			lm.quad("Glass", e0 - back, e1 - back, t1 - back, t0 - back, -fn)
			# Floor lines every 3.9 m (every second floor drawn) and mullions.
			var y := 3.9
			while y < top_h - 2.0:
				var f := y / top_h
				lm.beam("Fins", e0.lerp(t0, f) + fn * 0.08, e1.lerp(t1, f) + fn * 0.08, 0.14, 0.12, fn.cross(e1 - e0))
				y += 7.8
			for m in 7:
				var u := (float(m) + 0.5) / 7.0
				lm.beam("Fins", e0.lerp(t0, 0.002).lerp(e1.lerp(t1, 0.002), u) + fn * 0.1 + Vector3(0, 0.3, 0), t0.lerp(t1, u) + fn * 0.1, 0.18, 0.12, e1 - e0)
			# Top edge of the splinter.
			lm.beam("Fins", t0, t1, 0.4, 0.4)
		# Fracture: recessed dark vents between the two facets.
		var f0: Vector3 = n * (depth - 1.5)
		var fk := 272.0 / 309.6
		lm.quad("Dark", f0 + r * 1.3, f0 - r * 1.3, f0.lerp(Vector3.ZERO, fk) - r * 1.3 + Vector3(0, 272.0, 0),
			f0.lerp(Vector3.ZERO, fk) + r * 1.3 + Vector3(0, 272.0, 0), n)
		var y2 := 8.0
		while y2 < 268.0:
			var p := f0.lerp(Vector3.ZERO, y2 / 309.6) + Vector3(0, y2, 0)
			lm.box("Fins", p + n * 0.3, Vector3(2.6, 0.25, 0.6), b, 0.0)
			y2 += 15.6
		# Corner: the facets of adjacent sides close on a slim mullion.
		var corner: Vector3 = r * half_w + n * depth
		lm.beam("Fins", corner + Vector3(0, 0.45, 0), corner.lerp(Vector3.ZERO, 0.88) + Vector3(0, 272.0, 0), 0.6, 0.6)
	# Inner core seen through the fractures, and the open steel spire.
	lm.spire("Dark", Vector3.ZERO, 20.0, 280.0, 2.0)
	for s in 4:
		var a := PI * 0.5 * float(s) + PI * 0.25
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Fins", d * 3.4 + Vector3(0, 268.0, 0), apex - Vector3(0, 0.3, 0), 0.5, 0.5)
		for j in 5:
			var y := 272.0 + 7.0 * float(j)
			var rr := 3.4 * (309.6 - y) / (309.6 - 268.0)
			var a2 := a + PI * 0.5
			lm.beam("Fins", d * rr + Vector3(0, y, 0), Vector3(cos(a2), 0, sin(a2)) * rr + Vector3(0, y + 3.5, 0), 0.25)
	# Podium canopy and plaza.
	lm.box("Concrete", Vector3(0, 0.15, 0), Vector3(70.0, 0.3, 60.0))
	lm.box("Fins", Vector3(0, 6.5, -26.5), Vector3(30.0, 0.4, 6.0))
	for x in [-14.0, 14.0]:
		lm.box("Fins", Vector3(x, 3.3, -29.0), Vector3(0.4, 6.4, 0.4), Basis(), 0.0)
	lm.commit(model)

## 30 St Mary Axe, "The Gherkin" (180 m, Foster, 2004): the bulging
## 41-storey tower (49 m at the foot, 56.5 m at its belly), its glass
## skin on a steel diagrid of 18 helices each way crossing at a node
## every two floors with a hoop at each node level, the six dark
## light-wells spiralling 5 degrees a floor, and the glass lens of the
## top-floor bar.
static func gherkin(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#6D8A96"))
	lm.use("Well", LandmarkMaterials.glass("#1F2E34"))
	lm.use("Frame", LandmarkMaterials.paint("#AEB6BC", 0.35, 0.8))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9A59C", 4.0))
	var table := PackedVector2Array([Vector2(0, 24.5), Vector2(8, 25.5), Vector2(30, 27.8),
		Vector2(56, 28.25), Vector2(80, 26.5), Vector2(105, 23.0), Vector2(130, 18.0),
		Vector2(150, 13.0), Vector2(165, 8.5), Vector2(175, 4.5), Vector2(180, 0.0)])
	var levels := 21
	var node_h := 8.3
	var prof := PackedVector2Array()
	for j in 44:
		var y := minf(180.0 * float(j) / 43.0, 180.0)
		prof.append(Vector2(LandmarkMesh.profile_at(table, y) if j < 43 else 0.0, y))
	lm.lathe("Glass", Vector3.ZERO, prof, 36)
	var twist := deg_to_rad(10.0) / node_h
	var rad := func(y: float) -> float: return LandmarkMesh.profile_at(table, y)
	# Diagrid: 18 helices each way, nodes every two floors; hoops.
	for dir in [-1.0, 1.0]:
		for i in 18:
			var a0 := TAU * float(i) / 18.0
			for j in levels - 1:
				var y0 := maxf(node_h * float(j), 0.35)
				var y1 := node_h * float(j + 1)
				if y1 > 172.0:
					break
				var b0: float = a0 + dir * y0 * twist
				var b1: float = a0 + dir * y1 * twist
				lm.beam("Frame", Vector3(cos(b0), 0, sin(b0)) * (rad.call(y0) + 0.25) + Vector3(0, y0, 0),
					Vector3(cos(b1), 0, sin(b1)) * (rad.call(y1) + 0.25) + Vector3(0, y1, 0), 0.5, 0.4)
	for j in range(1, levels - 1):
		var y := node_h * float(j)
		if y > 170.0:
			break
		var rr: float = rad.call(y) + 0.22
		lm.frustum("Frame", Vector3(0, y - 0.2, 0), rr, rr, 0.4, 36)
	# Six light-wells spiralling 5 degrees a floor (about 1.2 per metre).
	var well_twist := deg_to_rad(5.0) / 4.15
	for i in 6:
		var a0 := TAU * float(i) / 6.0
		var rows: Array = []
		for j in 39:
			var y := 4.0 + 4.15 * float(j)
			var rr: float = rad.call(y) + 0.12
			var row := PackedVector3Array()
			for e in [-0.1, 0.1]:
				var a: float = a0 + y * well_twist + float(e) * (24.5 / maxf(rr, 4.0))
				row.append(Vector3(cos(a), 0, sin(a)) * rr + Vector3(0, y, 0))
			rows.append(row)
		lm.grid("Well", rows, Vector3(0, 80.0, 0), true)
	# The lens: glass cap with radial ribs over the top-floor bar.
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in range(36, 43):
			lm.beam("Frame", d * (prof[j].x + 0.15) + Vector3(0, prof[j].y, 0),
				d * (prof[j + 1].x + 0.15) + Vector3(0, prof[j + 1].y, 0), 0.35, 0.3)
	# Plaza and the recessed entrance lobby.
	lm.frustum("Concrete", Vector3(0, 0.0, 0), 34.0, 34.0, 0.3, 36)
	for k in 4:
		var a := TAU * float(k) / 4.0 + 0.4
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Frame", d * 25.4 + Vector3(0, 3.5, 0), Vector3(6.0, 0.3, 2.5), Basis.looking_at(d))
	lm.commit(model)
