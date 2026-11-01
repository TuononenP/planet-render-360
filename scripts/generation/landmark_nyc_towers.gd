class_name LandmarkNycTowers
extends RefCounted

## Manhattan's two skyline towers in true metres.

## One World Trade Center: a 61 m square podium faced in prismatic glass
## fins, then the tower whose square corners are chamfered away as it
## rises, so its faces are eight tall isosceles triangles and the top is
## the base square turned 45° (an octagon at mid height); the parapet at
## 417 m, and the 124 m spire on its ring to the 541.3 m tip.
const WTC_TIP_M := 541.3
const WTC_ROOF_M := 417.0
const WTC_PODIUM_M := 56.7
const WTC_HALF := 30.5

static func one_wtc(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#9DB0BE"))
	lm.use("Podium", LandmarkMaterials.paint("#C3C9CD", 0.3, 0.75))
	lm.use("Steel", LandmarkMaterials.paint("#DADDE0", 0.3, 0.8))
	lm.use("Base", LandmarkMaterials.pbr("concrete", "#B8B4AC", 3.0))
	lm.box("Podium", Vector3(0, WTC_PODIUM_M * 0.5, 0), Vector3(WTC_HALF * 2.0, WTC_PODIUM_M, WTC_HALF * 2.0))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * side)
		for k in 12:
			lm.box("Steel", r * Vector3(-WTC_HALF + 2.5 + 5.0 * k, WTC_PODIUM_M * 0.5, WTC_HALF + 0.3),
				Vector3(0.5, WTC_PODIUM_M - 4.0, 0.6), r)
	# The tower loft: base ring alternates square corners and edge
	# midpoints; at the top each corner has drawn in to the midpoint of
	# the turned square's edge while the midpoints stay put.
	var y0 := WTC_PODIUM_M
	var y1 := WTC_ROOF_M
	var bottom: Array[Vector3] = []
	var top: Array[Vector3] = []
	for i in 8:
		var a := PI * 0.25 * i + PI * 0.25
		if i % 2 == 0:
			var corner := Vector2(cos(a), sin(a)) * WTC_HALF * sqrt(2.0)
			bottom.append(Vector3(corner.x, y0, corner.y))
			top.append(Vector3(corner.x * 0.5, y1, corner.y * 0.5))
		else:
			var mid := Vector2(cos(a), sin(a)) * WTC_HALF
			bottom.append(Vector3(mid.x, y0, mid.y))
			top.append(Vector3(mid.x, y1, mid.y))
	for i in 8:
		var j := (i + 1) % 8
		# Corner i shrinks while midpoint j stays: two triangles per edge.
		var b_corner := bottom[i] if i % 2 == 0 else bottom[j]
		var b_mid := bottom[j] if i % 2 == 0 else bottom[i]
		var t_corner := top[i] if i % 2 == 0 else top[j]
		var t_mid := top[j] if i % 2 == 0 else top[i]
		_flat_tri(lm, "Glass", b_corner, b_mid, t_mid)
		_flat_tri(lm, "Glass", b_corner, t_mid, t_corner)
	# Roof and parapet on the turned square.
	var cap := PackedVector2Array()
	for p in top:
		cap.append(Vector2(p.x, p.z))
	lm.poly_prism("Steel", cap, y1, y1 + 3.0)
	# Spire: ring platform and the tapering mast with its rings.
	lm.frustum("Steel", Vector3(0, y1 + 3.0, 0), 9.0, 9.0, 4.0, 16)
	lm.lathe("Steel", Vector3(0, y1 + 7.0, 0), PackedVector2Array([Vector2(2.6, 0),
		Vector2(2.0, 60.0), Vector2(1.2, 105.0), Vector2(0.2, WTC_TIP_M - y1 - 7.0)]), 10)
	for k in 6:
		var ry := y1 + 20.0 + 16.0 * k
		lm.frustum("Steel", Vector3(0, ry, 0), 4.0 - 0.4 * k, 4.0 - 0.4 * k, 0.8, 16)
	lm.box("Base", Vector3(0, -0.5, 0), Vector3(WTC_HALF * 2.0 + 16.0, 1.6, WTC_HALF * 2.0 + 16.0))
	lm.commit(model)

static func _flat_tri(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	var mid := (a + b + c) / 3.0
	if n.dot(Vector3(mid.x, 0.0, mid.z)) < 0.0:
		n = -n
	var u := (b - a).normalized()
	lm.tri(key, a, b, c, n, n, n, Vector2(0, -a.y), Vector2((b - a).dot(u), -b.y),
		Vector2((c - a).dot(u), -c.y))

## Empire State Building: the five-storey base filling the block, the
## setbacks at the 6th, 21st, 25th, 30th, 72nd, 81st and 85th floors
## with the limestone tower and its aluminium spandrel strips, the 86th
## floor deck, the Art Deco mooring mast to the 381 m roof and the
## antenna to the 443.2 m tip. Long side along the cross streets (X);
## LocationData turns it onto Manhattan's grid.
const ESB_TIP_M := 443.2
const ESB_ROOF_M := 381.0

static func empire_state(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#CFC6B4", 3.0))
	lm.use("Spandrel", LandmarkMaterials.paint("#9EA3A6", 0.4, 0.7))
	lm.use("Windows", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Mast", LandmarkMaterials.paint("#B9B5AA", 0.45, 0.55))
	# [y0, y1, length (X), depth (Z)] stacked masses.
	var masses := [[0.0, 25.0, 129.0, 57.0], [25.0, 84.0, 112.0, 52.0], [84.0, 99.0, 92.0, 48.0],
		[99.0, 118.0, 76.0, 44.0], [118.0, 280.0, 58.0, 40.0], [280.0, 314.0, 46.0, 34.0],
		[314.0, 330.0, 36.0, 28.0]]
	for m in masses:
		var my0 := float(m[0])
		var my1 := float(m[1])
		var lx := float(m[2])
		var lz := float(m[3])
		lm.box("Limestone", Vector3(0, (my0 + my1) * 0.5, 0), Vector3(lx, my1 - my0, lz))
		lm.box("Limestone", Vector3(0, my1 + 0.6, 0), Vector3(lx + 0.6, 1.2, lz + 0.6))
		if my1 - my0 < 12.0:
			continue
		# Vertical window bays with aluminium spandrels between piers.
		for face in [[lx, lz, Basis()], [lz, lx, Basis(Vector3.UP, PI * 0.5)]]:
			var span := float(face[0])
			var depth := float(face[1])
			var r: Basis = face[2]
			var bays := maxi(2, floori(span / 4.6))
			for s in [-1.0, 1.0]:
				for k in bays:
					var x := -span * 0.5 + span * (k + 0.5) / bays
					var c := r * Vector3(x, (my0 + my1) * 0.5, s * (depth * 0.5 + 0.12))
					lm.box("Windows", c, Vector3(1.4, my1 - my0 - 3.0, 0.2), r)
					lm.box("Spandrel", c + r * Vector3(0, 0, s * 0.08), Vector3(0.5, my1 - my0 - 3.0, 0.2), r)
	# 86th-floor deck parapet and the mooring mast.
	lm.box("Limestone", Vector3(0, 331.5, 0), Vector3(38.0, 3.0, 30.0))
	lm.frustum("Mast", Vector3(0, 333.0, 0), 10.0, 7.5, 22.0, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * k
		lm.beam("Spandrel", Vector3(cos(a) * 10.2, 333.0, sin(a) * 10.2),
			Vector3(cos(a) * 7.7, 355.0, sin(a) * 7.7), 0.8, 0.5)
	lm.frustum("Mast", Vector3(0, 355.0, 0), 7.5, 5.0, 14.0, 8, PI / 8.0)
	lm.frustum("Mast", Vector3(0, 369.0, 0), 5.0, 3.2, 8.0, 8, PI / 8.0)
	lm.lathe("Mast", Vector3(0, 377.0, 0), PackedVector2Array([Vector2(3.2, 0),
		Vector2(2.0, ESB_ROOF_M - 377.0), Vector2(1.0, ESB_ROOF_M - 377.0 + 6.0)]), 8)
	lm.lathe("Spandrel", Vector3(0, ESB_ROOF_M + 6.0, 0), PackedVector2Array([Vector2(1.0, 0),
		Vector2(0.6, 30.0), Vector2(0.12, ESB_TIP_M - ESB_ROOF_M - 6.0)]), 8)
	lm.commit(model)
