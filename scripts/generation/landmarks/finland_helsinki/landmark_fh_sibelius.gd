extends RefCounted

## Sibelius Monument (Eila Hiltunen, "Passio Musicae", 1967), Sibelius Park.
## Origin at the centre of the sculpture's footprint (registry point 60.18203 N
## 24.91342 E, the OSM artwork node), yaw 0.
##
## From the photographs (visual-plan/refs/landmarks/sibelius_monument/): a
## dense wave of silvery stainless-steel organ pipes of many lengths, taller
## to one side, the lower ends hanging free at varying heights, standing on
## a pink-grey granite outcrop; Hiltunen's steel portrait of Sibelius on its
## own rock beside it. The model keeps the earlier pipe-field generator (a
## packed staggered grid with a swell, bottoms in a second wave) and raises
## the density to about 650 pipes (the real work has more than 600).
##
## Measured (published): 8.5 m high, 10.5 m long, 6.5 m deep, 24 t. No LoD2
## row exists. Estimated: pipe radii, leg positions, the outcrop's outline and
## the portrait's size and placement.

## Sibelius Monument (moved from LandmarkFhHelsinkiMonuments).



const ENTRY := {"type": "sibelius_monument", "name": "Sibelius Monument", "lat": 60.18203, "lon": 24.91342,
	"radius_m": 5500.0, "wiki_title": "Sibelius Monument", "height_m": 8.5, "clear_m": 22.0,
	"kind": "Monument", "aliases": ["sibelius monument", "sibelius-monumentti", "sibeliusmonumentet",
		"sibelius park monument"]}


## Eila Hiltunen's "Passio Musicae" (1967): more than 600 welded pipes of
## acid-proof stainless steel, 24 tonnes, in a wave-like cluster 8.5 m
## high, 10.5 m long and 6.5 m deep, lifted off the rock on a few legs so
## the lower ends hang free at varying heights, the open ends cut and
## textured; beside it on its own rock the steel portrait of Sibelius.
## Origin at the centre of the sculpture's footprint.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.pbr("concrete", "#C3C9CC", 2.0, 0.25, 0.85))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#7C776E", 4.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A8782", 3.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4F4A3C", 2.0, 0.4, 0.6))
	# The rock of Sibelius Park under the sculpture.
	lm.lathe("Rock", Vector3(0, 0, 0), PackedVector2Array([Vector2(10.5, 0), Vector2(9.0, 0.5),
		Vector2(7.2, 0.8), Vector2(6.4, 0.85)]), 18, 1.1, 0.9, 0.4, false)
	# Pipes on a packed staggered grid: tops rise in a swell toward the
	# back left and fall in waves; the bottoms hang free in a second wave.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1967
	var tops: Array = []
	var top_max := 0.0
	for iz in 26:
		for ix in 42:
			var x := -5.1 + 10.2 * float(ix) / 41.0 + (0.12 if iz % 2 == 1 else 0.0)
			var z := -3.1 + 6.2 * float(iz) / 25.0
			var e := pow(x / 5.25, 2.0) + pow(z / 3.25, 2.0)
			if e > 1.0 or rng.randf() < 0.04:
				continue
			var swell := exp(-(pow(x + 2.0, 2.0) / 9.0 + pow(z + 0.6, 2.0) / 5.0))
			var top := 3.6 + 4.2 * swell + 1.2 * sin(0.7 * x + 0.5 * z) + 0.7 * sin(1.4 * z - 0.3 * x) \
				+ rng.randf_range(-0.35, 0.35)
			tops.append([x, z, top, rng.randf_range(0.07, 0.14)])
			top_max = maxf(top_max, top)
	var scale_h := 8.5 / top_max
	for p in tops:
		var x: float = p[0]
		var z: float = p[1]
		var top: float = float(p[2]) * scale_h
		var bot := 1.3 + 0.9 * sin(0.9 * x + 1.1 * z) + 0.4 * sin(2.3 * x) + (top - 4.0) * 0.12
		bot = clampf(bot, 0.9, top - 1.5)
		var r: float = p[3]
		lm.frustum("Steel", Vector3(x, bot, z), r, r, top - bot, 6, x * 3.0)
		# Cut, flared lower ends on a few pipes.
		if int(absf(x * 7.0 + z * 3.0)) % 5 == 0:
			lm.frustum("Steel", Vector3(x, bot - 0.08, z), r * 1.25, r, 0.12, 6, x)
	# Legs carrying the cluster down to the rock.
	for q in [Vector3(-3.4, 0.8, -1.2), Vector3(-1.0, 0.8, 1.6), Vector3(1.6, 0.8, -1.4), Vector3(3.6, 0.8, 0.8),
			Vector3(-0.2, 0.8, -0.2)]:
		lm.frustum("Steel", q, 0.22, 0.18, 1.2, 8)
	# The portrait of Sibelius on its own rock beside the pipes.
	var ph := Vector3(6.4, 0.0, 3.6)
	lm.lathe("Rock", ph, PackedVector2Array([Vector2(1.8, 0), Vector2(1.5, 0.9), Vector2(1.0, 1.4), Vector2(0.6, 1.5)]),
		10, 1.0, 0.8, 0.3, false)
	var pb := Basis(Vector3.UP, 0.5)
	lm.box("Steel", ph + Vector3(0, 1.6, 0), Vector3(0.3, 0.3, 0.3), pb)
	lm.lathe("Steel", ph + Vector3(0, 1.7, 0), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.45, 0.1),
		Vector2(0.62, 0.5), Vector2(0.66, 1.0), Vector2(0.58, 1.5), Vector2(0.4, 1.85), Vector2(0.0, 2.0)]), 14, 0.8, 1.0)
	for k in 9:
		lm.beam("Bronze", ph + pb * Vector3(-0.5 + 0.12 * float(k), 3.2, 0.1),
			ph + pb * Vector3(-0.6 + 0.15 * float(k), 3.85, 0.0), 0.08, 0.06)
	lm.commit(model)
	var silver := Color(0.95, 0.96, 1.0)
	var warm := Color(1.0, 0.90, 0.74)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 1.2, 10.0), Vector3(-1.0, 5.0, 0.0), 42.0, 0.9, 28.0, silver],
		[Vector3(12.0, 1.2, 11.0), Vector3(2.0, 5.0, 1.0), 44.0, 0.95, 28.0, warm],
		[Vector3(-11.0, 1.2, -10.0), Vector3(-1.0, 5.0, 0.0), 42.0, 0.85, 28.0, silver],
		[Vector3(11.0, 1.2, -10.0), Vector3(2.0, 5.0, 0.0), 42.0, 0.85, 28.0, warm],
	])
