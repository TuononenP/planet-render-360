class_name VesselForms
extends RefCounted

## Marine mouldings and deck equipment. All geometry shares the vessel's
## existing material keys; dimensions are metres, +X points to the bow.

static func outline(cx: float, length: float, width: float, radius: float, steps: int = 6) -> PackedVector2Array:
	var out := PackedVector2Array()
	var r := minf(radius, minf(length, width) * 0.45)
	for corner in 4:
		var a := PI * 0.5 * float(corner)
		var centre := Vector2(cx + (length * 0.5 - r) * (1.0 if corner in [0, 3] else -1.0),
			(width * 0.5 - r) * (1.0 if corner < 2 else -1.0))
		for i in steps + 1:
			var angle := a + PI * 0.5 * float(i) / float(steps)
			out.append(centre + Vector2(cos(angle), sin(angle)) * r)
	return out

static func slab(lm: LandmarkMesh, key: String, centre: Vector3, size: Vector3, radius: float) -> void:
	var rows: Array = []
	var edge := minf(size.y * 0.3, 0.06)
	for band in 4:
		var inset := edge if band in [0, 3] else 0.0
		var y: float = centre.y + [-size.y * 0.5, -size.y * 0.5 + edge, size.y * 0.5 - edge, size.y * 0.5][band]
		var ring := PackedVector3Array()
		var poly := outline(centre.x, size.x - inset * 2.0, size.z - inset * 2.0, radius)
		for p in poly:
			ring.append(Vector3(p.x, y, p.y + centre.z))
		if band in [0, 3]:
			_cap(lm, key, ring, band == 3)
		ring.append(ring[0])
		rows.append(ring)
	lm.grid(key, rows, centre, true)

static func _cap(lm: LandmarkMesh, key: String, ring: PackedVector3Array, top: bool) -> void:
	var centre := Vector3.ZERO
	for p in ring:
		centre += p
	centre /= float(ring.size())
	var n := Vector3.UP if top else Vector3.DOWN
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		lm.tri(key, centre, a, b, n, n, n, Vector2(centre.z, -centre.x), Vector2(a.z, -a.x), Vector2(b.z, -b.x))

## A rounded deckhouse with a raked front. Glazing is part of the skin,
## so there is no opaque box behind the windscreen or floating glass.
static func cabin(lm: LandmarkMesh, cx: float, length: float, width: float, y: float, height: float,
		pitch: float = 0.0, wall: String = "White", rake: float = 0.25, glass: String = "Glass") -> void:
	var rows: Array = []
	var radius := minf(width * 0.14, height * 0.45)
	for f in [0.0, 0.28, 0.8, 1.0]:
		var ring := PackedVector3Array()
		for p in outline(cx - height * rake * float(f) * 0.5, length - height * rake * float(f),
				width * (1.0 - 0.06 * float(f)), radius):
			ring.append(Vector3(p.x, y + height * float(f), p.y))
		ring.append(ring[0])
		rows.append(ring)
	for band in 3:
		lm.grid(glass if band == 1 else wall, [rows[band], rows[band + 1]], Vector3(cx, y + height * 0.5, 0), true)
	if pitch > 0.0:
		var base: PackedVector3Array = rows[1]
		var top: PackedVector3Array = rows[2]
		for i in base.size() - 1:
			var distance := base[i].distance_to(base[i + 1])
			if i % 7 not in [0, 6]:
				continue
			var count := maxi(1, int(ceil(distance / pitch)))
			for k in count:
				var t := float(k) / float(count)
				var a := base[i].lerp(base[i + 1], t)
				var b := top[i].lerp(top[i + 1], t)
				lm.beam(wall, a, b, minf(0.065, height * 0.06))
	_cap(lm, wall, rows[3].slice(0, rows[3].size() - 1), true)

static func cleat(lm: LandmarkMesh, at: Vector3, size: float) -> void:
	lm.box("Steel", at + Vector3(0, size * 0.14, 0), Vector3(size * 0.45, size * 0.28, size * 0.24), Basis(), 0.0)
	HullLoft.tube(lm, "Steel", [at + Vector3(-size * 0.5, size * 0.3, 0), at + Vector3(size * 0.5, size * 0.3, 0)], size * 0.065, 8)

static func fittings(lm: LandmarkMesh, spec: Dictionary) -> void:
	var length: float = spec["length"]
	var beam: float = spec["beam"]
	var scale := clampf(length * 0.025, 0.18, 0.65)
	for side in [-1.0, 1.0]:
		for frac in [-0.4, 0.3]:
			var x: float = length * float(frac)
			cleat(lm, Vector3(x, HullLoft.sheer(spec, x) + 0.02, float(side) * (HullLoft.half(spec, x) - scale * 0.65)), scale)
		for frac in [-0.25, 0.04]:
			var x: float = length * float(frac)
			var r := clampf(beam * 0.035, 0.07, 0.18)
			var at := Vector3(x, maxf(0.15, HullLoft.sheer(spec, x) - r * 5.0), float(side) * (HullLoft.half(spec, x) + r * 0.5))
			lm.lathe("Dark", at, PackedVector2Array([Vector2(r * 0.5, 0), Vector2(r, r),
				Vector2(r, r * 4.0), Vector2(r * 0.5, r * 5.0)]), 8)
			HullLoft.tube(lm, "Steel", [at + Vector3(0, r * 5.0, 0), Vector3(x, HullLoft.sheer(spec, x), float(side) * (HullLoft.half(spec, x) - r))], r * 0.09, 4)
	# Foredeck anchor winch and its short chain, behind the stem.
	var ax := length * 0.37
	var ay := HullLoft.sheer(spec, ax)
	lm.lathe("Steel", Vector3(ax, ay, 0), PackedVector2Array([Vector2(scale * 0.45, 0), Vector2(scale * 0.45, scale * 0.5)]), 8)
	HullLoft.tube(lm, "Dark", [Vector3(ax, ay + 0.025, 0), Vector3(length * 0.46, HullLoft.sheer(spec, length * 0.46) + 0.025, 0)], scale * 0.04, 5)
	if bool(spec.get("anchors", true)):
		var anchor_x := length * 0.42
		var anchor_y := HullLoft.sheer(spec, anchor_x) - scale * 1.2
		for side in [-1.0, 1.0]:
			var z: float = float(side) * (HullLoft.side_z(spec, anchor_x, anchor_y) + 0.025)
			var points := PackedVector2Array()
			for p in [Vector2(-0.08, 0.7), Vector2(0.08, 0.7), Vector2(0.08, 0.0), Vector2(0.45, 0.22),
				Vector2(0.28, -0.15), Vector2(-0.28, -0.15), Vector2(-0.45, 0.22), Vector2(-0.08, 0.0)]:
				points.append(Vector2(anchor_x, anchor_y) + (p as Vector2) * scale)
			HullLoft.fin(lm, "Steel", points, scale * 0.04, z)

static func hatch(lm: LandmarkMesh, centre: Vector3, length: float, width: float) -> void:
	slab(lm, "Steel", centre, Vector3(length, 0.05, width), minf(width * 0.1, 0.1))
	lm.box("Glass", centre + Vector3(0, 0.032, 0), Vector3(length * 0.85, 0.02, width * 0.82), Basis(), 0.0)

static func davit(lm: LandmarkMesh, at: Vector3, height: float, reach: float) -> void:
	HullLoft.tube(lm, "White", [at, at + Vector3(0, height * 0.85, 0), at + Vector3(0, height, reach * 0.55),
		at + Vector3(0, height, reach)], 0.045, 6)
	HullLoft.tube(lm, "Steel", [at + Vector3(0, height, reach), at + Vector3(0, height * 0.4, reach)], 0.016, 4)
