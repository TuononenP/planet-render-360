class_name FtAiristonTahti
extends RefCounted

## Airiston Tähti (Frank Schauman, 2001) at Majakkaranta / Korppolaismäki in
## true metres (skyline: true, +X long seaside axis, -Z facing Airisto sound /
## Aura mouth, turned by yaw_deg = 34.0°):
##   - Measured from OSM way:315922782 (60.427970, 22.237072, LoD2 57.4 m,
##     OSM height = 58 m, 18 storeys).
##   - Iconic 18-storey white seaside residential point tower overlooking the
##     Aura mouth & Airisto sound, rising from a coastal stone/concrete terrace
##     podium and lower 5-storey seaside wing.
##   - Crisp white precast concrete/render point-tower shaft (20.5 x 19.5 m,
##     rising to 53.6 m) with SkyKit lit residential windows, full-height
##     projecting glazed sea-view balcony stacks, and crisp horizontal white
##     floor slab bands.
##   - Signature glazed lighthouse/beacon penthouse crown & circular rooftop
##     lantern pavilion rising to 58.0 m with warm golden beacon glow and red
##     ICAO aviation warning halos (HALO_META).
## Surfaces: 9 merged PBR parts (White, Facade, Concrete, Stone, Glass, Frame,
## Roof, Lamp, Beacon).

const FOUND := -2.2
const SHAFT_H := 53.6
const TOP_M := 58.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var sk := SkyKit.new(lm)
	_materials(lm, sk)
	_build_podium_and_wing(lm, sk)
	_build_point_tower(lm, sk)
	_build_beacon_crown(lm, model)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh, sk: SkyKit) -> void:
	lm.use("White", LandmarkMaterials.pbr("render", "#F2F1EC", 2.8))
	sk.wall("Facade", "white_panel", 2.5, 2.95)
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C5C3BC", 2.8))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7C7B77", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#264052"))
	lm.use("Frame", LandmarkMaterials.paint("#343C44", 0.42, 0.58))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4C535A", 2.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8B8", 1.5))
	lm.use("Beacon", LandmarkMaterials.lit("#FF281A", 2.2))

static func _rect_poly(x0: float, x1: float, z0: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])

static func _build_podium_and_wing(lm: LandmarkMesh, sk: SkyKit) -> void:
	# Coastal stone/concrete terrace plinth across the Majakkaranta site.
	LandmarkFrKit.rect(lm, "Stone", -32.0, 26.0, -15.5, 15.5, FOUND, 1.4)
	# Adjacent 5-storey lower white residential wing on -X flank (x = -31..-10, z = -11..11, H 16.4 m).
	sk.prism("Facade", _rect_poly(-30.5, -10.0, -10.5, 10.5), 1.4, 16.0, "Roof")
	LandmarkFrKit.rect(lm, "White", -30.8, -9.8, -10.8, 10.8, 15.8, 16.45)
	# Glazed sea-facing balconies on the 5-storey wing (-Z).
	for fl in 4:
		var fy := 4.4 + float(fl) * 2.95
		LandmarkFrKit.rect(lm, "White", -29.0, -11.5, -12.6, -10.5, fy - 0.16, fy + 0.14)
		LandmarkFrKit.rect(lm, "Glass", -28.8, -11.7, -12.55, -12.42, fy + 0.14, fy + 1.25)

static func _build_point_tower(lm: LandmarkMesh, sk: SkyKit) -> void:
	# Main 18-storey white seaside point tower centred around x = +6, z = 0 (20 x 19 m).
	var tx0 := -4.0
	var tx1 := 16.0
	var tz0 := -9.5
	var tz1 := 9.5
	# Ground lobby & stone podium collar (1.4..4.6 m).
	LandmarkFrKit.rect(lm, "White", tx0 - 0.6, tx1 + 0.6, tz0 - 0.6, tz1 + 0.6, 1.4, 4.6)
	LandmarkFrKit.rect(lm, "Glass", tx0 + 2.0, tx1 - 2.0, tz1 + 0.5, tz1 + 0.72, 1.6, 4.2)
	LandmarkFrKit.rect(lm, "Lamp", tx0 + 2.5, tx1 - 2.5, tz1 - 0.2, tz1 + 0.3, 1.8, 3.9)
	# Main 17-storey SkyKit lit-window white shaft (4.6..53.6 m).
	sk.prism("Facade", _rect_poly(tx0, tx1, tz0, tz1), 4.6, SHAFT_H, "Roof")
	# Crisp white corner pilasters framing the point tower.
	for cx: float in [tx0, tx1]:
		for cz: float in [tz0, tz1]:
			lm.box("White", Vector3(cx, (4.6 + SHAFT_H) * 0.5, cz), Vector3(1.4, SHAFT_H - 4.6, 1.4))
	# Full-height projecting glazed seaside balcony stacks on -Z (Airisto), +X, and +Z faces.
	for fl in 16:
		var fy := 4.6 + float(fl) * 3.05
		# Sea-view (-Z) twin projecting curved/stepped glazed balcony stacks.
		for bx: float in [1.0, 11.0]:
			LandmarkFrKit.rect(lm, "White", bx - 3.6, bx + 3.6, tz0 - 2.6, tz0, fy - 0.15, fy + 0.14)
			LandmarkFrKit.rect(lm, "Glass", bx - 3.5, bx + 3.5, tz0 - 2.55, tz0 - 2.42, fy + 0.14, fy + 2.85)
			LandmarkFrKit.rect(lm, "Glass", bx - 3.55, bx - 3.42, tz0 - 2.55, tz0, fy + 0.14, fy + 2.85)
			LandmarkFrKit.rect(lm, "Glass", bx + 3.42, bx + 3.55, tz0 - 2.55, tz0, fy + 0.14, fy + 2.85)
		# East (+X) glazed corner balcony stack.
		LandmarkFrKit.rect(lm, "White", tx1, tx1 + 2.4, -4.5, 4.5, fy - 0.15, fy + 0.14)
		LandmarkFrKit.rect(lm, "Glass", tx1 + 2.28, tx1 + 2.42, -4.4, 4.4, fy + 0.14, fy + 2.85)
		# South (+Z) central balcony stack.
		LandmarkFrKit.rect(lm, "White", 2.0, 10.0, tz1, tz1 + 2.2, fy - 0.15, fy + 0.14)
		LandmarkFrKit.rect(lm, "Glass", 2.1, 9.9, tz1 + 2.08, tz1 + 2.22, fy + 0.14, fy + 2.85)
	# Crisp white roof parapet slab.
	LandmarkFrKit.rect(lm, "White", tx0 - 0.8, tx1 + 0.8, tz0 - 0.8, tz1 + 0.8, SHAFT_H - 0.4, SHAFT_H + 0.8)

static func _build_beacon_crown(lm: LandmarkMesh, model: Node3D) -> void:
	# Signature glazed penthouse & circular lighthouse beacon crown rising to 58.0 m.
	var cx := 6.0
	LandmarkFrKit.rect(lm, "Glass", cx - 6.2, cx + 6.2, -5.8, 5.8, SHAFT_H + 0.8, 56.6)
	LandmarkFrKit.rect(lm, "Lamp", cx - 5.2, cx + 5.2, -4.8, 4.8, SHAFT_H + 1.0, 56.2)
	LandmarkFrKit.rect(lm, "White", cx - 7.2, cx + 7.2, -6.8, 6.8, 56.6, 57.35)
	lm.frustum("White", Vector3(cx, 57.35, 0.0), 3.6, 2.2, 0.65, 16)
	# Red aviation warning beacons + warm lighthouse crown halo.
	var b1 := Vector3(cx - 6.6, 57.55, -6.2)
	var b2 := Vector3(cx + 6.6, 57.55, 6.2)
	lm.box("Beacon", b1, Vector3(0.4, 0.4, 0.4))
	lm.box("Beacon", b2, Vector3(0.4, 0.4, 0.4))
	model.set_meta(LandmarkLights.HALO_META, [
		[b1, 2.2, Color(1.0, 0.14, 0.08)],
		[b2, 2.2, Color(1.0, 0.14, 0.08)],
		[Vector3(cx, 55.6, 0.0), 4.0, Color(1.0, 0.88, 0.65)],
	])

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(6.0, 2.0, -20.0), Vector3(6.0, 28.0, -9.5), 54.0, 0.75, 48.0, Color(0.96, 0.94, 0.90)],
		[Vector3(24.0, 2.0, 0.0), Vector3(16.0, 28.0, 0.0), 54.0, 0.70, 44.0, Color(0.96, 0.94, 0.90)],
	])
