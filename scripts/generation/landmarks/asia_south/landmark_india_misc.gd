class_name LandmarkIndiaMisc
extends RefCounted

## Four Indian landmarks in true metres: the Gateway of India, the Hawa
## Mahal, the Charminar and the Lotus Temple. Fronts face +Z (south).

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")

## Gateway of India (26 m): yellow basalt Indo-Saracenic arch. The
## central block carries the pointed main arch (framed, jali spandrels,
## two storeys of jharokha windows either side), the octagonal drum and
## the 15 m dome behind a pierced parapet, and four corner turrets with
## open kiosks rising to 26 m; a hall for 600 people either side with a
## three-bay arcade, parapet and corner pinnacles.
static func gateway_of_india(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Basalt", LandmarkMaterials.pbr("stone", "#B79B6A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D2BE96", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#4F4638", 3.0))
	lm.box("Trim", Vector3(0, 0.5, 0), Vector3(66.0, 1.0, 32.0))
	lm.box("Trim", Vector3(0, 1.3, 0), Vector3(30.0, 0.6, 20.0))
	# Central block, 26 x 17 m: the main arch runs through along Z.
	U.arch_wall(lm, "Basalt", Vector3(0, 1.6, 0), Basis(), 26.0, 17.0, 17.0, 9.0, 16.0, 12, 6.0)
	for sz in [-1.0, 1.0]:
		var b := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
		var zf: float = sz * 8.5
		U.frame(lm, "Trim", Vector3(0, 1.6, zf), b, 12.4, 16.0, 0.6, 0.3)
		for tz in [0.06, 0.3]:
			LandmarkDetail.cornice(lm, "Trim", b * Vector3(-13.2, 18.6, 8.5 + tz), b * Vector3(13.2, 18.6, 8.5 + tz),
				b * Vector3(0, 0, 1), 0.8, false)
		# Jali spandrels over the arch.
		for sx in [-1.0, 1.0]:
			U.jali(lm, "Trim", b * Vector3(sx * 4.2, 15.6, 8.62), b, 2.4, 2.4, 0.45, 0.08)
			# Two storeys of jharokha windows on the piers.
			for y in [4.0, 10.6]:
				U.niche(lm, "Basalt", "Recess", b * Vector3(sx * 9.6, y, 8.5), b, 4.6, 5.6, 2.4, 0.6, 3.6, 1.5,
					0.6, 6)
				lm.box("Trim", b * Vector3(sx * 9.6, y + 0.25, 9.4), Vector3(4.0, 0.5, 0.9), b)
				for k in 4:
					lm.box("Trim", b * Vector3(sx * 9.6 - 1.5 + float(k), y - 0.3, 9.2), Vector3(0.25, 0.6, 0.5), b, 0.0)
			# Pilasters framing the pier.
			lm.box("Trim", b * Vector3(sx * 6.9, 9.5, 8.7), Vector3(0.6, 16.0, 0.4), b)
		# Pierced parapet along the top.
		U.merlons(lm, "Trim", b * Vector3(-11.0, 19.4, 8.0), b * Vector3(11.0, 19.4, 8.0), 16, 0.8, 1.4)
	lm.box("Basalt", Vector3(0, 18.9, 0), Vector3(26.4, 0.6, 17.4))
	for sx in [-1.0, 1.0]:
		U.merlons(lm, "Trim", Vector3(sx * 12.6, 19.2, -6.0), Vector3(sx * 12.6, 19.2, 6.0), 8, 0.8, 1.4)
	# Octagonal drum and the 15 m dome.
	lm.frustum("Basalt", Vector3(0, 19.2, 0), 7.6, 7.6, 2.2, 8, PI / 8.0)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		U.niche(lm, "Basalt", "Recess", d * 7.0 + Vector3(0, 19.2, 0), Basis.looking_at(-d), 4.8, 2.2, 1.6, 0.3,
			1.4, 0.4, 0.2, 4)
	lm.frustum("Trim", Vector3(0, 21.4, 0), 7.9, 7.9, 0.4, 8, PI / 8.0)
	U.dome(lm, "Trim", Vector3(0, 21.8, 0), 7.5, 3.4, 40, 10)
	U.finial(lm, "Trim", Vector3(0, 25.0, 0), 1.0, 0.2)
	# Corner turrets: octagonal shafts with balconies, open kiosks on top.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 13.0, 1.6, sz * 8.5)
			lm.frustum("Basalt", p, 2.3, 2.3, 1.2, 8, PI / 8.0)
			lm.frustum("Basalt", p, 2.0, 1.85, 18.4, 8, PI / 8.0)
			for y in [6.0, 12.0, 17.6]:
				lm.lathe("Trim", p + Vector3(0, y, 0), PackedVector2Array([Vector2(1.95, 0), Vector2(2.4, 0.4),
					Vector2(2.4, 0.8)]), 8, 1.0, 1.0, PI / 8.0, false)
			U.chhatri8(lm, "Trim", "Trim", "Trim", p + Vector3(0, 18.4, 0), 2.2, 2.3, 2.0)
	# Side halls with a three-bay arcade, parapet and pinnacles.
	for sx in [-1.0, 1.0]:
		var hx: float = sx * 22.5
		lm.box("Basalt", Vector3(hx, 6.0, 0), Vector3(17.0, 10.0, 13.0))
		for sz in [-1.0, 1.0]:
			var b := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
			U.arcade(lm, "Basalt", "Recess", Vector3(hx, 1.0, sz * 6.5), b, 16.0, 9.0, 3, 0.62, 0.0, 5.0, 1.3,
				0.7, 8)
			lm.box("Trim", Vector3(hx, 11.0, sz * 6.9), Vector3(17.6, 0.6, 0.9))
			U.merlons(lm, "Trim", Vector3(hx - 8.0, 11.3, sz * 6.6), Vector3(hx + 8.0, 11.3, sz * 6.6), 12, 0.6, 1.0)
		U.arcade(lm, "Basalt", "Recess", Vector3(sx * 31.0, 1.0, 0), Basis(Vector3.UP, sx * PI * 0.5), 12.0, 9.0,
			2, 0.6, 0.0, 5.0, 1.3, 0.7, 8)
		for sz in [-1.0, 1.0]:
			var pp := Vector3(sx * 31.0, 1.0, sz * 6.5)
			lm.frustum("Basalt", pp, 0.9, 0.8, 11.5, 8, PI / 8.0)
			lm.lathe("Trim", pp + Vector3(0, 11.5, 0), LandmarkKits.onion_profile(0.8, 1.8), 12)
	lm.commit(model)

## Hawa Mahal (15 m): the pink sandstone "palace of winds", 953
## jharokha windows over five floors stepping in to a pyramid, the top
## three one room thick. Each bay is a semi-hexagonal oriel on corbels:
## latticed openings, a chhajja eave and a small curved dome with a
## finial; an arcade on the ground floor, kiosks on the crest. Faces +Z;
## the real facade looks east.
static func hawa_mahal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Pink", LandmarkMaterials.pbr("stone", "#D4876E", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EBD9C4", 3.0))
	lm.use("Lattice", LandmarkMaterials.pbr("stone", "#5C3B30", 2.0))
	# width, depth, floor height
	var floors := [[44.0, 11.0, 3.4], [38.0, 8.0, 3.0], [26.0, 6.0, 2.8], [18.0, 5.0, 2.4],
		[11.0, 4.0, 1.8]]
	var y := 0.0
	var fi := 0
	for f in floors:
		var w: float = f[0]
		var d: float = f[1]
		var h: float = f[2]
		lm.box("Pink", Vector3(0, y + h * 0.5, 0), Vector3(w, h, d))
		lm.box("Trim", Vector3(0, y + h, 0.0), Vector3(w + 0.6, 0.3, d + 0.6))
		var bays := int(w / 3.2)
		if fi == 0:
			# Ground floor: a pointed arcade with the lattice behind.
			U.arcade(lm, "Pink", "Lattice", Vector3(0, 0, d * 0.5), Basis(), w, h, bays, 0.55, 0.3, h * 0.6,
				1.4, 0.4, 6)
		else:
			for k in bays:
				var x := -w * 0.5 + w * (float(k) + 0.5) / bays
				_oriel(lm, Vector3(x, y, d * 0.5), w / bays, h)
		# Crest of small domes on each floor's terrace edge.
		for sx in [-1.0, 1.0]:
			var ex: float = sx * (w * 0.5 - 0.7)
			lm.frustum("Pink", Vector3(ex, y + h + 0.15, 0), 0.5, 0.45, 0.8, 8)
			lm.lathe("Trim", Vector3(ex, y + h + 0.95, 0), LandmarkKits.onion_profile(0.45, 0.9), 10)
		y += h
		fi += 1
	U.chhatri8(lm, "Trim", "Pink", "Trim", Vector3(0, y, 0), 1.3, 0.5, 0.5)
	for sx in [-1.0, 1.0]:
		U.chhatri8(lm, "Trim", "Pink", "Trim", Vector3(sx * 4.0, 11.6, 0), 1.2, 0.5, 0.5)
		U.chhatri8(lm, "Trim", "Pink", "Trim", Vector3(sx * 7.5, 11.6, 0), 1.1, 0.4, 0.5)
		U.chhatri8(lm, "Trim", "Pink", "Trim", Vector3(sx * 11.5, 9.2, 0), 1.2, 0.5, 0.5)
		U.chhatri8(lm, "Trim", "Pink", "Trim", Vector3(sx * 17.0, 6.4, 0), 1.3, 0.5, 0.6)
	lm.commit(model)

## One jharokha oriel in a bay `bw` wide on a floor of height h whose
## wall face is at p (floor level): corbelled base, a latticed front and
## two splayed sides, the chhajja eave, a small dome and finial.
static func _oriel(lm: LandmarkMesh, p: Vector3, bw: float, h: float) -> void:
	var ow := bw * 0.72
	var dep := ow * 0.4
	lm.lathe("Trim", p + Vector3(0, 0.0, 0.0), PackedVector2Array([Vector2(ow * 0.15, 0),
		Vector2(ow * 0.5, h * 0.12)]), 6, 1.0, 0.8, 0.0, false)
	var bh := h * 0.68
	var y0 := p.y + h * 0.12
	# Front: a framed lattice opening on its panel.
	var fb := Basis()
	U.niche(lm, "Pink", "Lattice", Vector3(p.x, y0, p.z + dep), fb, ow * 0.6, bh, ow * 0.42, bh * 0.1,
		bh * 0.68, ow * 0.13, 0.08, 4)
	# Splayed sides, each with a lattice slit.
	for sx in [-1.0, 1.0]:
		var sb := Basis(Vector3.UP, sx * PI / 3.0)
		var sc := Vector3(p.x + sx * ow * 0.4, y0 + bh * 0.5, p.z + dep * 0.5)
		lm.box("Pink", sc, Vector3(ow * 0.42, bh, 0.12), sb, 0.0)
		lm.box("Lattice", sc + sb * Vector3(0, 0, 0.07), Vector3(ow * 0.22, bh * 0.6, 0.02), sb, 0.0)
	# Chhajja eave and a small dome on top, half-sunk in the wall.
	var top := y0 + bh
	lm.lathe("Trim", Vector3(p.x, top, p.z + dep * 0.4), PackedVector2Array([Vector2(ow * 0.62, 0),
		Vector2(ow * 0.62, 0.06), Vector2(ow * 0.4, h * 0.08)]), 6, 1.0, 0.75, PI / 6.0, false)
	lm.lathe("Pink", Vector3(p.x, top + h * 0.08, p.z + dep * 0.4), LandmarkKits.onion_profile(ow * 0.34,
		h * 0.15), 8, 1.0, 0.8)
	lm.frustum("Trim", Vector3(p.x, top + h * 0.21, p.z + dep * 0.4), 0.05, 0.0, h * 0.06, 4)

## Charminar (56 m): the four-arched gateway and mosque of 1591, 30.5 m
## a side (Archnet). Each face has an 11 m wide pointed arch rising 20 m
## to the apex, a corbelled balcony of small arches over it, the arcaded
## first floor, a second screen of arches and the kangura parapet; the
## mosque floor is on top. Four 16-lobed minarets rise from the corners
## with ring balconies, two of them above the roof, to bulb domes.
static func charminar(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#CBBFA6", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9B9183", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#524A40", 2.0))
	lm.box("Granite", Vector3(0, 0.5, 0), Vector3(40.0, 1.0, 40.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		# Main arch: 11 m wide, apex 20 m above the floor.
		U.arch_wall(lm, "Stucco", b * Vector3(0, 1.0, 12.0), b, 27.0, 20.5, 6.0, 11.0, 20.0, 14, 6.5)
		U.frame(lm, "Stucco", b * Vector3(0, 1.0, 15.0), b, 13.2, 20.6, 0.6, 0.35)
		# Balcony over the arch: chhajja on brackets, a row of small arches.
		lm.box("Stucco", b * Vector3(0, 21.7, 15.6), Vector3(26.0, 0.3, 1.6), b)
		for k in 14:
			lm.box("Stucco", b * Vector3(-12.0 + 24.0 * float(k) / 13.0, 21.1, 15.3), Vector3(0.3, 0.9, 0.9), b, 0.0)
		U.arcade(lm, "Stucco", "Recess", b * Vector3(0, 21.85, 13.6), b, 25.0, 2.6, 12, 0.6, 0.6, 1.6, 1.2, 0.25, 4)
		# First floor: five deep open arches.
		U.arcade(lm, "Stucco", "Recess", b * Vector3(0, 24.45, 13.5), b, 25.0, 5.6, 5, 0.6, 0.0, 3.4, 1.4, 0.8, 8)
		lm.box("Stucco", b * Vector3(0, 30.3, 14.0), Vector3(26.0, 0.5, 1.2), b)
		# Second floor screen of small arches, then the parapet.
		U.arcade(lm, "Stucco", "Recess", b * Vector3(0, 30.55, 13.5), b, 25.0, 3.6, 9, 0.55, 0.3, 2.1, 1.3, 0.4, 6)
		lm.box("Stucco", b * Vector3(0, 34.3, 13.9), Vector3(26.0, 0.4, 1.4), b)
		U.merlons(lm, "Stucco", b * Vector3(-11.6, 34.5, 14.0), b * Vector3(11.6, 34.5, 14.0), 20, 0.7, 1.2)
	lm.box("Stucco", Vector3(0, 21.8, 0), Vector3(27.0, 0.6, 27.0))
	lm.box("Stucco", Vector3(0, 28.2, 0), Vector3(27.0, 12.2, 27.0))
	# Mosque floor on the roof: a small domed prayer hall.
	lm.box("Stucco", Vector3(0, 36.0, -4.0), Vector3(14.0, 3.0, 8.0))
	for k in 3:
		U.dome(lm, "Stucco", Vector3(-4.5 + 4.5 * float(k), 37.5, -4.0), 1.8, 1.6, 16, 5)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_charminar_minaret(lm, Vector3(sx * 13.8, 1.0, sz * 13.8))
	lm.commit(model)

## One Charminar minaret from the plinth (y at p) to 56 m: a 16-lobed
## shaft, ring balconies at the gallery levels and two above the roof,
## a petalled neck, the bulb dome and finial.
static func _charminar_minaret(lm: LandmarkMesh, p: Vector3) -> void:
	U.fluted_shaft(lm, "Stucco", p, 3.4, 3.0, 34.0, 16, 0.25, 6, 3)
	U.fluted_shaft(lm, "Stucco", p + Vector3(0, 34.0, 0), 2.8, 2.3, 14.5, 16, 0.2, 3, 3)
	for y in [21.0, 29.5, 40.5, 47.0]:
		var r := 3.5 if y < 35.0 else 2.6
		lm.lathe("Stucco", p + Vector3(0, y - 1.4, 0), PackedVector2Array([Vector2(r, 0), Vector2(r + 0.5, 0.6),
			Vector2(r + 1.0, 1.2), Vector2(r + 1.2, 1.4), Vector2(r + 1.2, 1.7)]), 16)
		for i in 16:
			var a := TAU * (float(i) + 0.5) / 16.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.box("Stucco", p + d * (r + 1.05) + Vector3(0, y + 0.75, 0), Vector3(0.18, 1.1, 0.18), Basis(), 0.0)
			# Small arched openings in the railing screen.
			lm.box("Recess", p + d * (r + 1.0) + Vector3(0, y + 0.7, 0), Vector3(0.5, 0.7, 0.04),
				Basis.looking_at(d), 0.0)
		lm.frustum("Stucco", p + Vector3(0, y + 1.3, 0), r + 1.25, r + 1.25, 0.2, 16)
	var top := p + Vector3(0, 48.5, 0)
	lm.frustum("Stucco", top, 2.3, 2.1, 1.2, 16)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Stucco", top + d * 2.0 + Vector3(0, 1.0, 0), top + d * 2.7 + Vector3(0, 2.2, 0), 0.7, 0.15,
			d.cross(Vector3.UP))
	lm.lathe("Stucco", top + Vector3(0, 1.2, 0), LandmarkKits.onion_profile(2.4, 4.4), 16)
	U.finial(lm, "Stucco", top + Vector3(0, 5.4, 0), 1.1, 0.14)

## Lotus Temple (34.3 m: inner leaves 33.6 m on a 0.7 m podium): 27
## free-standing marble-clad shells in three rings of nine. The entrance
## leaves (7.8 m) flare outward over the nine doors, 70 m across; the
## outer leaves (22.5 m) curve in over the hall; the inner leaves almost
## close at the crown. Each shell has thickness and a ridge; nine
## petal-shaped pools ring the red sandstone podium between walkways.
static func lotus_temple(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EEEBE3", 3.0))
	lm.use("Core", LandmarkMaterials.pbr("limestone", "#CBC6BA", 3.0))
	lm.use("Pool", LandmarkMaterials.pbr("concrete", "#6C9097", 4.0, 0.12))
	lm.use("Podium", LandmarkMaterials.pbr("stone", "#A0604A", 3.0))
	lm.disc("Podium", Vector3(0, 0.02, 0), Vector3.UP, 66.0, 54)
	# Nine pools between the nine walkways, raised in their kerbs.
	for i in 9:
		var a0 := TAU * float(i) / 9.0 + 0.09
		var a1 := TAU * float(i + 1) / 9.0 - 0.09
		var poly := PackedVector2Array()
		var kerb := PackedVector2Array()
		for j in 9:
			var a := lerpf(a0, a1, float(j) / 8.0)
			poly.append(Vector2(cos(a), sin(a)) * 43.0)
			kerb.append(Vector2(cos(a), sin(a)) * 42.4)
		for j in 9:
			var a := lerpf(a1, a0, float(j) / 8.0)
			var rr := 43.0 + 14.0 * sin(PI * float(j) / 8.0)
			poly.append(Vector2(cos(a), sin(a)) * rr)
			kerb.append(Vector2(cos(a), sin(a)) * (rr + 0.6))
		lm.poly_prism("Podium", kerb, 0.0, 0.45)
		lm.poly_prism("Pool", poly, 0.0, 0.5)
	# Podium and its steps, then the inner hall core with its glazed crown.
	lm.frustum("Podium", Vector3.ZERO, 42.0, 41.5, 0.35, 54)
	lm.frustum("Podium", Vector3(0, 0.35, 0), 40.5, 40.0, 0.35, 54)
	lm.lathe("Core", Vector3(0, 0.7, 0), PackedVector2Array([Vector2(18.5, 0), Vector2(18.5, 10.0),
		Vector2(16.0, 18.0), Vector2(11.0, 25.0), Vector2(5.0, 30.0), Vector2(2.0, 31.8), Vector2(0.0, 32.2)]), 45)
	# Nine doors under the entrance leaves.
	for i in 9:
		var a := TAU * float(i) / 9.0
		var d := Vector3(cos(a), 0, sin(a))
		U.niche(lm, "Marble", "Core", d * 18.5 + Vector3(0, 0.7, 0), Basis.looking_at(-d), 7.0, 6.0, 4.0, 0.0,
			3.2, 2.0, 0.6, 8)
	# base radius, tip radius, height above podium, base width, thickness
	var leaves := [[23.0, 35.0, 7.8, 13.0, 0.35], [24.0, 12.0, 22.5, 16.0, 0.4], [17.5, 2.6, 33.6, 12.0, 0.4]]
	for i in 9:
		var a := TAU * float(i) / 9.0
		for li in 3:
			var lf: Array = leaves[li]
			var az := a + (PI / 9.0 if li == 2 else 0.0)
			_petal(lm, az, float(lf[0]), float(lf[1]), float(lf[2]), float(lf[3]), float(lf[4]))
	lm.commit(model)

## One curved shell leaf at azimuth `a` with thickness t: vertical at
## the foot, leaning in (or flaring out) to the tip at radius r1,
## narrowing from w0 to a point, convex across its width with a ridge.
static func _petal(lm: LandmarkMesh, a: float, r0: float, r1: float, h: float, w0: float, t: float) -> void:
	var dir := Vector3(cos(a), 0, sin(a))
	var tang := Vector3(-sin(a), 0, cos(a))
	var nr := 15
	var nc := 9
	var faces: Array = [[], []]
	for j in nr:
		var v := float(j) / float(nr - 1)
		var r := lerpf(r0, r1, v * v)
		var w := lerpf(w0, 0.25, pow(v, 2.2))
		for side in 2:
			var row := PackedVector3Array()
			for i in nc:
				var s := -1.0 + 2.0 * float(i) / float(nc - 1)
				var bulge := w * 0.22 * (1.0 - s * s) + (0.12 if i == nc / 2 else 0.0)
				var rr := r + bulge + (t if side == 0 else 0.0)
				row.append(dir * rr + tang * (s * w * 0.5) + Vector3(0, 0.7 + h * v, 0))
			(faces[side] as Array).append(row)
	var outer: Array = faces[0]
	var inner: Array = faces[1]
	lm.grid("Marble", outer, Vector3(0, 0.7 + h * 0.4, 0), true)
	lm.grid("Marble", inner, Vector3(0, 0.7 + h * 0.4, 0) + dir * 200.0, true)
	# Edge strips joining the two skins along both sides.
	for e in [0, nc - 1]:
		var rows: Array = []
		for j in nr:
			var ro: PackedVector3Array = outer[j]
			var ri: PackedVector3Array = inner[j]
			rows.append(PackedVector3Array([ro[e], ri[e]]))
		lm.grid("Marble", rows, tang * (1.0 if e > 0 else -1.0))
