extends RefCounted

## Old Market Hall (Vanha kauppahalli, Nyström, 1889), on the South Harbour
## quay. Model origin at the OSM footprint centre (way 123814071, 85 x 20
## m), front +Z toward the Market Square, registry yaw -93.
##
## Red brick striped with cream limestone courses, polychrome diamond-patterned
## brick panels along the lower bays, round-headed windows along both long sides,
## large traceried round-headed gable windows at both ends, corner turrets under
## spires, warm Lamp clerestory ridge lantern, and architectural floodlights.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "old_market_hall_helsinki", "name": "Old Market Hall, Helsinki", "lat": 60.16616, "lon": 24.95279,
	"radius_m": 5000.0, "wiki_title": "Old Market Hall, Helsinki", "height_m": 19.0, "clear_m": 55.0,
	"base_at_m": [0.0, 0.0], "yaw_deg": -93.0, "kind": "Market hall", "aliases": ["old market hall, helsinki", "vanha kauppahalli",
		"gamla saluhallen helsingfors", "helsinki old market hall"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A4B38", 3.0))
	lm.use("DarkBrick", LandmarkMaterials.pbr("brick", "#4E2A22", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D9D0BC", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("sheet_metal", "#8C9896", 3.0, 0.55, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A4", 0.6))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	var x0 := -42.5
	var x1 := 42.8
	var cx := (x0 + x1) * 0.5
	var z0 := -9.0
	var z1 := 7.7
	var cz := (z0 + z1) * 0.5
	var w := x1 - x0
	var d := z1 - z0
	var eave := 8.2
	FhU.blk(lm, "Plinth", cx, 0.0, cz, w + 0.4, 1.0, d + 0.4)
	FhU.blk(lm, "Brick", cx, 1.0, cz, w, eave - 1.0, d)
	for k in 4:
		FhP.box_band(lm, "Trim", cx, cz, w, d, 1.6 + 1.5 * float(k), 0.3, 0.04)
	FhP.box_band(lm, "Trim", cx, cz, w, d, eave - 0.6, 0.6, 0.3)
	FhU.ridge_x(lm, "Copper", "Brick", Vector3(cx, eave, cz), w, d, 4.0, 0.6)
	# Ridge lantern with warm Lamp clerestory glow and mullions.
	FhU.blk(lm, "Brick", cx, eave + 2.6, cz, w - 14.0, 1.6, 3.6)
	FhU.blk(lm, "Lamp", cx, eave + 2.8, cz, w - 13.8, 1.0, 3.68)
	for k in 20:
		var mx := lerpf(x0 + 8.0, x1 - 8.0, float(k) / 19.0)
		lm.box("Trim", Vector3(mx, eave + 3.3, cz), Vector3(0.12, 1.1, 3.74), Basis(), 0.0)
	FhU.ridge_x(lm, "Copper", "Copper", Vector3(cx, eave + 4.2, cz), w - 14.0, 3.6, 1.0, 0.3)
	_long_sides(lm, x0, x1, z0, z1, eave)
	_gable_ends(lm, x0, x1, z0, z1, cz)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-22.0, 1.0, z1 + 20.0), Vector3(-18.0, 7.0, z1), 50.0, 0.9, 45.0, warm],
		[Vector3(22.0, 1.0, z1 + 20.0), Vector3(18.0, 7.0, z1), 50.0, 0.9, 45.0, warm],
		[Vector3(-22.0, 1.0, z0 - 20.0), Vector3(-18.0, 7.0, z0), 50.0, 0.8, 45.0, warm],
		[Vector3(22.0, 1.0, z0 - 20.0), Vector3(18.0, 7.0, z0), 50.0, 0.8, 45.0, warm],
		[Vector3(x0 - 18.0, 1.0, cz), Vector3(x0, 9.0, cz), 42.0, 0.9, 38.0, warm],
		[Vector3(x1 + 18.0, 1.0, cz), Vector3(x1, 9.0, cz), 42.0, 0.9, 38.0, warm],
	])

static func _long_sides(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, eave: float) -> void:
	for s in [-1.0, 1.0]:
		var z: float = z1 if s > 0.0 else z0
		var o := Vector3(0, 0, s)
		for seg in [[x0 + 1.0, -6.6], [7.5, x1 - 1.0]]:
			var a := Vector3(float(seg[0]), 0, z)
			var b := Vector3(float(seg[1]), 0, z)
			var n := int(a.distance_to(b) / 3.4)
			FhP.win_row(lm, "Trim", "Glass", a, b, o, 2.0, n, 1.8, 4.6, true, 0.25)
			FhP.strips(lm, "Brick", a, b, o, 1.0, eave - 1.6, n + 1, 0.6, 0.25)
			# Polychrome diamond-patterned brick panels along the lower bays.
			_diamond_panels(lm, a, b, o, n, 1.15)
		var ez: float = z + s * 1.25
		FhU.blk(lm, "Brick", 0.45, 0.0, ez - s * 0.6, 12.3, 10.6, 3.7)
		FhU.ridge_z(lm, "Copper", "Brick", Vector3(0.45, 10.6, ez - s * 1.6), 12.3, 5.7, 3.6, 0.3)
		FhP.box_band(lm, "Trim", 0.45, ez - s * 0.6, 12.3, 3.7, 10.0, 0.6, 0.2)
		var face := Vector3(0.45, 0, ez + s * 1.25)
		LandmarkDetail.arch(lm, "Trim", face + Vector3(0, 5.6, 0), o, 4.2, 0.5, 0.35)
		lm.quad("Glass", face + Vector3(-2.1, 1.0, s * 0.02), face + Vector3(2.1, 1.0, s * 0.02),
			face + Vector3(2.1, 5.6, s * 0.02), face + Vector3(-2.1, 5.6, s * 0.02), o)
		for k in 3:
			lm.box("Trim", face + Vector3(-1.4 + 1.4 * float(k), 3.3, s * 0.05),
				Vector3(0.1, 4.6, 0.1), Basis(), 0.0)
		FhP.strips(lm, "Trim", face + Vector3(-5.6, 0, 0), face + Vector3(5.6, 0, 0), o, 1.0, 9.0, 2, 0.9, 0.3)
		lm.disc("Lamp", face + Vector3(0, 11.6, s * 0.03), o, 0.9, 14)
		FhP.ring(lm, "Trim", face + Vector3(0, 11.6, 0), o, 0.9, 1.2, 0.2, 14)
		lm.spire("Copper", face + Vector3(0, 14.1, -s * 0.2), 0.3, 1.6, 0.0, 4)
		FhU.steps(lm, "Plinth", face, o, 6.0, 0.4, 0.2, 3)

static func _diamond_panels(lm: LandmarkMesh, a: Vector3, b: Vector3, o: Vector3, n: int, y: float) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, o) * Basis(o, PI * 0.25)
	for i in n:
		var c := a.lerp(b, (float(i) + 0.5) / float(n)) + o * 0.06
		for dx in [-0.65, 0.0, 0.65]:
			var key := "DarkBrick" if absf(dx) > 0.1 else "Trim"
			lm.box(key, c + dir * dx + Vector3(0, y + 0.35, 0), Vector3(0.42, 0.42, 0.08), basis, 0.0)

static func _gable_ends(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, cz: float) -> void:
	for s in [-1.0, 1.0]:
		var x: float = x1 if s > 0.0 else x0
		var o := Vector3(s, 0, 0)
		# Large central traceried round-headed gable window.
		var wc := Vector3(x, 0.0, cz)
		LandmarkDetail.window(lm, "Trim", "Glass", wc + Vector3(0, 5.4, 0), o, 4.8, 6.8, true, 0.32)
		LandmarkDetail.arch(lm, "Trim", wc + Vector3(0, 6.4, 0), o, 5.2, 0.45, 0.36)
		lm.disc("Lamp", wc + Vector3(s * 0.03, 6.5, 0), o, 2.2, 16)
		FhP.ring(lm, "Trim", wc + Vector3(s * 0.1, 6.5, 0), o, 1.25, 1.45, 0.14, 14)
		for k in 6:
			var ang := PI * float(k + 1) / 7.0
			var spoke := Vector3(0.0, sin(ang), cos(ang)) * 2.2
			lm.beam("Trim", wc + Vector3(s * 0.1, 6.5, 0), wc + Vector3(s * 0.1, 6.5, 0) + spoke, 0.08, 0.08, o)
		for dz in [-1.2, 0.0, 1.2]:
			lm.box("Trim", wc + Vector3(s * 0.1, 4.2, dz), Vector3(0.08, 4.6, 0.10), Basis(), 0.0)
		# Flanking narrow arched bays and polychrome diamond brick dado.
		for sz in [-4.5, 4.5]:
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 4.3, cz + sz), o, 1.4, 4.4, true, 0.22)
		_diamond_panels(lm, Vector3(x, 0, z0 + 2.5), Vector3(x, 0, z1 - 2.5), o, 4, 1.15)
		for tz in [z0 + 0.9, z1 - 0.9]:
			var tc := Vector3(x - s * 0.9, 0, float(tz))
			lm.frustum("Brick", tc, 1.5, 1.5, 13.4, 8, PI / 8.0)
			lm.frustum("Trim", tc + Vector3(0, 7.6, 0), 1.65, 1.65, 0.4, 8, PI / 8.0)
			lm.frustum("Trim", tc + Vector3(0, 13.0, 0), 1.75, 1.75, 0.5, 8, PI / 8.0)
			for k in 8:
				var a := TAU * (float(k) + 0.5) / 8.0
				lm.box("Glass", tc + Vector3(cos(a), 0, sin(a)) * 1.4 + Vector3(0, 11.0, 0),
					Vector3(0.6, 1.6, 0.05), Basis.looking_at(Vector3(cos(a), 0, sin(a))), 0.0)
			lm.spire("Copper", tc + Vector3(0, 13.5, 0), 1.6, 5.2, 0.0, 8)
			lm.box("Copper", tc + Vector3(0, 18.85, 0), Vector3(0.12, 0.3, 0.12), Basis(), 0.0)
