class_name FtPortOfTurkuTerminals
extends RefCounted

## Port of Turku Passenger Terminals (Linnansatama: Viking Line Terminal &
## Tallink Silja Terminal + elevated Skywalk boarding gangways + historic
## red-brick Harbour Warehouse / Seamen's Mission) in true metres (+X ENE
## along quay/berths, -Z NNW inland, +Z SSE toward ferry berths, turned by
## yaw_deg = -21.0°):
##   - Measured from Linnansatama OSM ways 701583912 (128.9 x 31.6 m) &
##     701580263 (127.7 x 29.3 m) at 60.434800, 22.221500, LoD2 height 15.6 m.
##   - North-west Viking Line Terminal hall (white & crisp Viking-red fascia,
##     glazed departure concourse, twin elevated glazed steel-truss Skywalk
##     boarding gangways cantilevered out over the quay apron to ship berths).
##   - South-east Tallink Silja Terminal hall (white & Silja navy-blue fascia,
##     sweeping glazed passenger lobby, elevated Skywalk boarding bridge on
##     concrete & steel portal piers).
##   - Vehicle check-in marshalling booth canopy between the terminals and the
##     preserved red-brick Harbour Warehouse / customs hall on the east flank.
##   - Full terminal night illumination via FLOOD_META & warm interior Lamps.
## Surfaces: 10 merged PBR parts (White, Red, Blue, Brick, Concrete, Roof,
## Steel, Glass, Stone, Lamp).

const FOUND := -1.8
const TOP_M := 15.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_viking_terminal(lm)
	_build_silja_terminal(lm)
	_build_skywalk_gangways(lm)
	_build_warehouse_and_marshalling(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("White", LandmarkMaterials.pbr("render", "#ECEBE6", 2.8))
	lm.use("Red", LandmarkMaterials.paint("#C4262E", 0.42, 0.20))
	lm.use("Blue", LandmarkMaterials.paint("#1D3E6E", 0.42, 0.25))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#924838", 2.6))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BEB9B0", 2.8))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4A5056", 2.6))
	lm.use("Steel", LandmarkMaterials.paint("#363D44", 0.42, 0.62))
	lm.use("Glass", LandmarkMaterials.glass("#223748"))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7A7975", 2.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8B8", 1.5))

static func _build_viking_terminal(lm: LandmarkMesh) -> void:
	# Viking Line Terminal on -X / -Z side (x = -76..-8, z = -34..-4, H = 14.8 m).
	LandmarkFrKit.rect(lm, "Stone", -77.0, -7.0, -35.0, -3.0, FOUND, 0.8)
	LandmarkFrKit.rect(lm, "White", -76.0, -8.0, -34.0, -4.0, 0.8, 12.2)
	LandmarkFrKit.rect(lm, "Red", -76.4, -7.6, -34.4, -3.6, 11.4, 13.0)
	lm.gable("Roof", Vector3(-42.0, 12.9, -19.0), 30.0, 68.0, 2.5, Basis(Vector3.UP, PI * 0.5), 0.4, "White")
	# Panoramic glazed passenger departure hall facing the quay (+Z = -4.0) & drop-off (-Z = -34.0).
	for fz: float in [-4.0, -34.0]:
		var s := 1.0 if fz > -10.0 else -1.0
		LandmarkFrKit.rect(lm, "Glass", -70.0, -14.0, fz - 0.12, fz + 0.12, 2.2, 10.6)
		LandmarkFrKit.rect(lm, "Lamp", -68.0, -16.0, fz - 0.65 * s, fz - 0.35 * s, 2.6, 10.0)
		for k in 13:
			var mx := lerpf(-69.5, -14.5, float(k) / 12.0)
			lm.box("Steel", Vector3(mx, 6.4, fz + 0.10 * s), Vector3(0.22, 8.6, 0.24))
		lm.box("Steel", Vector3(-42.0, 6.4, fz + 0.10 * s), Vector3(56.0, 0.22, 0.24))
	# Drop-off canopy at Viking entrance (-Z).
	LandmarkFrKit.rect(lm, "Red", -58.0, -26.0, -40.5, -34.0, 4.8, 5.45)
	LandmarkFrKit.rect(lm, "Lamp", -56.0, -28.0, -38.5, -36.5, 4.68, 4.82)
	for k in 5:
		var px := lerpf(-56.0, -28.0, float(k) / 4.0)
		lm.beam("Steel", Vector3(px, 0.8, -39.5), Vector3(px, 4.85, -39.5), 0.26, 0.26)

static func _build_silja_terminal(lm: LandmarkMesh) -> void:
	# Tallink Silja Terminal on +X / +Z side (x = 12..82, z = -12..18, H = 15.6 m).
	LandmarkFrKit.rect(lm, "Stone", 11.0, 83.0, -13.0, 19.0, FOUND, 0.8)
	LandmarkFrKit.rect(lm, "White", 12.0, 82.0, -12.0, 18.0, 0.8, 12.8)
	LandmarkFrKit.rect(lm, "Blue", 11.6, 82.4, -12.4, 18.4, 12.0, 13.6)
	lm.gable("Roof", Vector3(47.0, 13.5, 3.0), 30.0, 70.0, 2.1, Basis(Vector3.UP, PI * 0.5), 0.4, "White")
	# Glazed Silja check-in & departure lounge facades.
	for fz: float in [18.0, -12.0]:
		var s := 1.0 if fz > 0.0 else -1.0
		LandmarkFrKit.rect(lm, "Glass", 18.0, 76.0, fz - 0.12, fz + 0.12, 2.2, 11.2)
		LandmarkFrKit.rect(lm, "Lamp", 20.0, 74.0, fz - 0.65 * s, fz - 0.35 * s, 2.6, 10.6)
		for k in 13:
			var mx := lerpf(18.5, 75.5, float(k) / 12.0)
			lm.box("Steel", Vector3(mx, 6.7, fz + 0.10 * s), Vector3(0.22, 9.2, 0.24))
		lm.box("Steel", Vector3(47.0, 6.7, fz + 0.10 * s), Vector3(58.0, 0.22, 0.24))
	# Drop-off canopy at Silja entrance (-Z).
	LandmarkFrKit.rect(lm, "Blue", 30.0, 64.0, -18.5, -12.0, 4.8, 5.45)
	LandmarkFrKit.rect(lm, "Lamp", 32.0, 62.0, -16.5, -14.5, 4.68, 4.82)
	for k in 5:
		var px := lerpf(32.0, 62.0, float(k) / 4.0)
		lm.beam("Steel", Vector3(px, 0.8, -17.5), Vector3(px, 4.85, -17.5), 0.26, 0.26)

static func _build_skywalk_gangways(lm: LandmarkMesh) -> void:
	# Elevated glazed steel-truss Skywalk boarding gangways extending toward the ferry berths (+Z).
	var walks := [
		[Vector3(-54.0, 8.6, -4.0), Vector3(-62.0, 9.2, 34.0), "Red"],
		[Vector3(-26.0, 8.6, -4.0), Vector3(-28.0, 9.2, 30.0), "Red"],
		[Vector3(34.0, 8.8, 18.0), Vector3(30.0, 9.4, 52.0), "Blue"],
		[Vector3(62.0, 8.8, 18.0), Vector3(68.0, 9.4, 48.0), "Blue"],
	]
	for w in walks:
		var a: Vector3 = w[0]
		var b: Vector3 = w[1]
		var accent: String = w[2]
		var dir := (b - a).normalized()
		var side := Vector3(-dir.z, 0.0, dir.x).normalized()
		var segs := 6
		for i in segs:
			var t0 := float(i) / float(segs)
			var t1 := float(i + 1) / float(segs)
			var p0 := a.lerp(b, t0)
			var p1 := a.lerp(b, t1)
			# Floor slab & roof hood of the Skywalk tube.
			lm.beam("Concrete", p0 - Vector3(0, 1.6, 0), p1 - Vector3(0, 1.6, 0), 3.4, 0.55)
			lm.beam(accent, p0 + Vector3(0, 1.8, 0), p1 + Vector3(0, 1.8, 0), 3.6, 0.45)
			lm.beam("Lamp", p0 + Vector3(0, 1.35, 0), p1 + Vector3(0, 1.35, 0), 1.4, 0.14)
			# Glazed side walls & diagonal steel truss members.
			for s: float in [-1.0, 1.0]:
				var o := side * (1.65 * s)
				lm.quad("Glass", p0 + o - Vector3(0, 1.3, 0), p1 + o - Vector3(0, 1.3, 0),
					p1 + o + Vector3(0, 1.5, 0), p0 + o + Vector3(0, 1.5, 0), side * s)
				lm.beam("Steel", p0 + o - Vector3(0, 1.4, 0), p1 + o + Vector3(0, 1.6, 0), 0.14, 0.14)
				lm.beam("Steel", p0 + o + Vector3(0, 1.6, 0), p1 + o - Vector3(0, 1.4, 0), 0.14, 0.14)
			# Concrete/steel support portal piers at intermediate stations.
			if i in [2, 4, 5]:
				var base_y := FOUND
				lm.beam("Concrete", Vector3(p1.x, base_y, p1.z) - side * 1.4, p1 - Vector3(0, 1.6, 0) - side * 1.4, 0.55, 0.55)
				lm.beam("Concrete", Vector3(p1.x, base_y, p1.z) + side * 1.4, p1 - Vector3(0, 1.6, 0) + side * 1.4, 0.55, 0.55)
		# Articulated ship-boarding docking head at the berth end.
		lm.box(accent, b, Vector3(4.8, 4.2, 4.4))
		lm.box("Glass", b + dir * 2.25, Vector3(3.6, 2.8, 0.24))

static func _build_warehouse_and_marshalling(lm: LandmarkMesh) -> void:
	# Vehicle check-in marshalling booth canopy in the central plaza (-8..12, z = -22..-4).
	LandmarkFrKit.rect(lm, "White", -6.0, 10.0, -22.0, -6.0, 5.2, 5.75)
	LandmarkFrKit.rect(lm, "Lamp", -4.5, 8.5, -16.0, -12.0, 5.08, 5.22)
	for px: float in [-4.5, 2.0, 8.5]:
		LandmarkFrKit.rect(lm, "Glass", px - 1.1, px + 1.1, -15.5, -12.5, 0.0, 3.2)
		lm.beam("Steel", Vector3(px, 0.0, -20.5), Vector3(px, 5.25, -20.5), 0.24, 0.24)
		lm.beam("Steel", Vector3(px, 0.0, -7.5), Vector3(px, 5.25, -7.5), 0.24, 0.24)
	# Historic red-brick Harbour Warehouse / Seamen's Mission flanking inland (-X = -16..18, z = -54..-36).
	LandmarkFrKit.rect(lm, "Stone", -16.5, 18.5, -54.5, -35.5, FOUND, 1.1)
	LandmarkFrKit.rect(lm, "Brick", -16.0, 18.0, -54.0, -36.0, 1.1, 10.4)
	lm.gable("Roof", Vector3(1.0, 10.4, -45.0), 18.0, 34.0, 3.6, Basis(Vector3.UP, PI * 0.5), 0.35, "Brick")
	for k in 8:
		var wx := lerpf(-13.5, 15.5, float(k) / 7.0)
		lm.box("Glass", Vector3(wx, 4.2, -35.94), Vector3(2.0, 2.8, 0.16))
		lm.box("Glass", Vector3(wx, 8.0, -35.94), Vector3(2.0, 2.2, 0.16))

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-42.0, 2.5, 8.0), Vector3(-42.0, 8.0, -4.0), 62.0, 0.80, 44.0, Color(1.0, 0.90, 0.74)],
		[Vector3(47.0, 2.5, 30.0), Vector3(47.0, 8.5, 18.0), 62.0, 0.80, 44.0, Color(0.92, 0.95, 1.0)],
		[Vector3(2.0, 2.5, -30.0), Vector3(2.0, 6.0, -42.0), 56.0, 0.70, 38.0, Color(1.0, 0.84, 0.62)],
	])
