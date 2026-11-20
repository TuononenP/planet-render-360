class_name FtIkituuri
extends RefCounted

## Ikituuri (Sigge Architects, 2011, TYS Student Village) at Pispalantie 12 /
## Helsinginkatu junction in true metres (skyline: true, +X long ellipse axis,
## turned by yaw_deg = -30.0°):
##   - Published: 60.458150, 22.294350; 12 storeys, 43.0 m total height.
##   - Instantly recognisable oval/elliptical tower (major radius 12.2 m,
##     minor radius 8.4 m) clad in warm burnished & patinated copper horizontal
##     louvers and integrated dark-blue/anthracite solar-collector facade bands.
##   - SkyKit lit residential apartment windows recessed behind elliptical
##     copper balcony rings and vertical glazed bay slots.
##   - Glazed ground-floor entrance podium & curved concrete base plinth.
##   - Sculptural angled rooftop solar-collector & sauna terrace crown rising
##     to 43.0 m with warm architectural night uplighting and red aviation
##     warning beacons (HALO_META).
## Surfaces: 9 merged PBR parts (Copper, Patina, Solar, Facade, Concrete,
## Glass, Roof, Lamp, Beacon).

const FOUND := -2.0
const RX := 12.2
const RZ := 8.4
const SHAFT_H := 38.6
const TOP_M := 43.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var sk := SkyKit.new(lm)
	_materials(lm, sk)
	_build_base_and_shaft(lm, sk)
	_build_copper_louvers_and_solar(lm)
	_build_crown(lm, model)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh, sk: SkyKit) -> void:
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#9A5F3E", 2.2, 0.38, 0.68))
	lm.use("Patina", LandmarkFrKit.copper("#4E7266"))
	lm.use("Solar", LandmarkMaterials.paint("#1D2C3D", 0.22, 0.55))
	sk.wall("Facade", "waffle_bronze", 2.2, 3.05)
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B4B0A8", 2.8))
	lm.use("Glass", LandmarkMaterials.glass("#243A4A"))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#484D52", 2.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A4", 1.5))
	lm.use("Beacon", LandmarkMaterials.lit("#FF281A", 2.2))

static func _ellipse(rx: float, rz: float, seg: int = 24) -> PackedVector2Array:
	var poly := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / float(seg)
		poly.append(Vector2(cos(a) * rx, sin(a) * rz))
	return poly

static func _build_base_and_shaft(lm: LandmarkMesh, sk: SkyKit) -> void:
	# Concrete plinth & glazed ground-floor entrance lobby.
	lm.poly_prism("Concrete", _ellipse(RX + 0.9, RZ + 0.9, 24), FOUND, 0.85)
	lm.poly_prism("Glass", _ellipse(RX - 0.6, RZ - 0.6, 24), 0.85, 4.2)
	lm.poly_prism("Lamp", _ellipse(RX - 1.4, RZ - 1.4, 20), 1.2, 3.8)
	# Projecting copper entrance canopy on -Z side.
	LandmarkFrKit.rect(lm, "Copper", -5.2, 5.2, -RZ - 3.6, -RZ + 1.2, 3.8, 4.35)
	LandmarkFrKit.rect(lm, "Lamp", -4.4, 4.4, -RZ - 2.8, -RZ - 0.8, 3.68, 3.82)
	# Main 11-storey elliptical SkyKit lit-window residential core (4.2..38.6 m).
	sk.prism("Facade", _ellipse(RX - 0.35, RZ - 0.35, 24), 4.2, SHAFT_H, "Roof")

static func _build_copper_louvers_and_solar(lm: LandmarkMesh) -> void:
	# Signature rhythmic horizontal burnished-copper louver rings & solar-collector bands.
	var seg := 24
	for fl in 12:
		var fy := 4.2 + float(fl) * 3.12
		var mat := "Patina" if fl % 4 == 3 else "Copper"
		# Continuous oval copper slab/louver collar projecting outside the glass core.
		var outer := _ellipse(RX + 0.38, RZ + 0.38, seg)
		lm.poly_prism(mat, outer, fy - 0.42, fy + 0.42)
		# Integrated dark-blue solar collector spandrel panels on the sunny S/SW arc.
		for k in 9:
			var a := lerpf(-0.25 * PI, 0.75 * PI, float(k) / 8.0)
			var cx := cos(a) * (RX + 0.16)
			var cz := sin(a) * (RZ + 0.16)
			var tang := Vector2(-sin(a) * RX, cos(a) * RZ).normalized()
			var yaw := atan2(tang.y, tang.x)
			lm.box("Solar", Vector3(cx, fy + 1.15, cz), Vector3(2.4, 1.05, 0.18), Basis(Vector3.UP, -yaw))
		# Vertical copper shading fins alternating around the ellipse.
		for k in 12:
			var a := TAU * (float(k) + (0.5 if fl % 2 == 1 else 0.0)) / 12.0
			var cx := cos(a) * (RX + 0.24)
			var cz := sin(a) * (RZ + 0.24)
			var tang := Vector2(-sin(a) * RX, cos(a) * RZ).normalized()
			var yaw := atan2(tang.y, tang.x)
			lm.box(mat, Vector3(cx, fy + 1.55, cz), Vector3(0.22, 2.25, 0.55), Basis(Vector3.UP, -yaw))

static func _build_crown(lm: LandmarkMesh, model: Node3D) -> void:
	# Sculptural recessed rooftop sauna/terrace pavilion & angled solar-panel crown (38.6..43.0 m).
	lm.poly_prism("Glass", _ellipse(RX - 2.2, RZ - 2.0, 20), SHAFT_H, 41.6)
	lm.poly_prism("Lamp", _ellipse(RX - 3.0, RZ - 2.6, 16), SHAFT_H + 0.3, 41.2)
	lm.poly_prism("Copper", _ellipse(RX + 0.1, RZ + 0.1, 24), 41.4, 42.3)
	lm.poly_prism("Roof", _ellipse(RX - 0.4, RZ - 0.4, 24), 42.3, 42.65)
	# Slanted rooftop solar collector array reaching 43.0 m.
	lm.box("Solar", Vector3(0.0, 42.82, 0.8), Vector3(13.5, 0.36, 5.2), Basis(Vector3.RIGHT, 0.14))
	# Red aviation warning beacons on crown rim.
	var b1 := Vector3(RX - 1.5, TOP_M, 0.0)
	var b2 := Vector3(-(RX - 1.5), TOP_M, 0.0)
	lm.box("Beacon", b1, Vector3(0.36, 0.36, 0.36))
	lm.box("Beacon", b2, Vector3(0.36, 0.36, 0.36))
	model.set_meta(LandmarkLights.HALO_META, [
		[b1, 2.0, Color(1.0, 0.14, 0.08)],
		[b2, 2.0, Color(1.0, 0.14, 0.08)],
	])

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, -18.0), Vector3(0.0, 20.0, -8.4), 56.0, 0.85, 42.0, Color(1.0, 0.78, 0.52)],
		[Vector3(0.0, 2.0, 18.0), Vector3(0.0, 20.0, 8.4), 56.0, 0.80, 42.0, Color(1.0, 0.78, 0.52)],
	])
