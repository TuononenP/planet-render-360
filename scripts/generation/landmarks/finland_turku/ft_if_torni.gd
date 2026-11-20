class_name FtIfTorni
extends RefCounted

## If-torni (Sampo / If P&C Insurance HQ, Pekka Pitkänen, 1995) at Itäharju /
## Kupittaa in true metres (skyline: true, turned by yaw_deg = -34.0°):
##   - Measured/published: 60.447850, 22.302750; 17 storeys, 66.0 m total
##     height (shaft 60.5 m + mechanical crown & illuminated If logo parapet
##     to 66.0 m).
##   - Iconic heptagonal (7-sided) plan (circumradius 13.8 m) clad in polished
##     dark Finnish granite spandrels & corner piers alternating with continuous
##     dark reflective ribbon glazing via SkyKit (lit office floors at night).
##   - Deep horizontal granite spandrel ledges and chamfered vertical corner
##     granite fins articulating all 7 faces of the heptagon.
##   - Low 3-storey dark-granite & glass courtyard podium wings flanking the
##     tower base (H 11.8 m) with glazed main lobby canopy.
##   - Recessed rooftop penthouse crown with illuminated blue-and-white "If"
##     rooftop beacon & ICAO red aviation obstruction halos (HALO_META).
## Surfaces: 9 merged PBR parts (Granite, Facade, Glass, Metal, Roof, Concrete,
## Lamp, IfGlow, Beacon).

const FOUND := -2.0
const SHAFT_H := 60.5
const TOP_M := 66.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var sk := SkyKit.new(lm)
	_materials(lm, sk)
	_build_podium_wings(lm)
	_build_heptagonal_tower(lm, sk)
	_build_crown_and_beacons(lm, model)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh, sk: SkyKit) -> void:
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#474A4E", 2.4, 0.35, 0.15))
	sk.wall("Facade", "granite_strip", 2.4, 3.45)
	lm.use("Glass", LandmarkMaterials.glass("#1E3140"))
	lm.use("Metal", LandmarkMaterials.paint("#2E343B", 0.38, 0.65))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#464B50", 2.6))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#8E9194", 2.8))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BA", 1.4))
	lm.use("IfGlow", LandmarkMaterials.lit("#3B8CFF", 2.0))
	lm.use("Beacon", LandmarkMaterials.lit("#FF281A", 2.2))

static func _heptagon(radius: float, rot: float = -PI * 0.5) -> PackedVector2Array:
	var poly := PackedVector2Array()
	for i in 7:
		var a := rot + TAU * float(i) / 7.0
		poly.append(Vector2(cos(a) * radius, sin(a) * radius))
	return poly

static func _build_podium_wings(lm: LandmarkMesh) -> void:
	# Low 3-storey granite & glass courtyard office wings around the tower base.
	LandmarkFrKit.rect(lm, "Granite", -30.0, 28.0, -24.0, 22.0, FOUND, 1.2)
	# West & north-west 3-storey office wing (x = -28..-8, z = -22..14, H 11.8 m).
	LandmarkFrKit.rect(lm, "Granite", -28.0, -8.0, -22.0, 14.0, 1.2, 11.5)
	LandmarkFrKit.rect(lm, "Roof", -27.6, -8.4, -21.6, 13.6, 11.5, 11.85)
	# South-east low entrance & conference wing (x = -12..26, z = 8..21, H 11.4 m).
	LandmarkFrKit.rect(lm, "Granite", -12.0, 26.0, 8.0, 21.0, 1.2, 11.1)
	LandmarkFrKit.rect(lm, "Roof", -11.6, 25.6, 8.4, 20.6, 11.1, 11.45)
	# Ribbon glazing on podium wings.
	for fl in 3:
		var fy := 2.4 + float(fl) * 3.1
		LandmarkFrKit.rect(lm, "Glass", -28.12, -27.92, -19.5, 11.5, fy, fy + 1.75)
		LandmarkFrKit.rect(lm, "Glass", -9.5, 23.5, 20.92, 21.12, fy, fy + 1.75)
		if fl < 2:
			LandmarkFrKit.rect(lm, "Lamp", -27.5, -27.3, -18.5, 10.5, fy + 0.2, fy + 1.45)
			LandmarkFrKit.rect(lm, "Lamp", -8.5, 22.5, 20.3, 20.5, fy + 0.2, fy + 1.45)
	# Glazed main entrance canopy (+Z).
	LandmarkFrKit.rect(lm, "Glass", -6.0, 6.0, 12.5, 17.5, 1.2, 5.2)
	LandmarkFrKit.rect(lm, "Metal", -6.8, 6.8, 12.2, 18.2, 5.2, 5.65)
	LandmarkFrKit.rect(lm, "Lamp", -5.2, 5.2, 13.2, 16.8, 1.6, 4.8)

static func _build_heptagonal_tower(lm: LandmarkMesh, sk: SkyKit) -> void:
	var base_poly := _heptagon(14.2)
	var shaft_poly := _heptagon(13.6)
	# Ground granite drum & double-height glazed lobby base (FOUND..5.6 m).
	lm.poly_prism("Granite", base_poly, FOUND, 2.0)
	lm.poly_prism("Glass", _heptagon(13.2), 2.0, 5.6)
	lm.poly_prism("Lamp", _heptagon(12.2), 2.2, 5.3)
	# Main 16-storey heptagonal SkyKit lit-window office shaft (5.6..60.5 m).
	sk.prism("Facade", shaft_poly, 5.6, SHAFT_H, "Roof")
	# Vertical dark-granite corner piers & horizontal spandrel ledges at all 7 corners.
	for i in 7:
		var p := shaft_poly[i]
		var q := shaft_poly[(i + 1) % 7]
		var edge := q - p
		var mid := (p + q) * 0.5
		var ang := atan2(edge.y, edge.x)
		var out_v := Vector2(p.x, p.y).normalized()
		# Corner chamfered granite pier rising full height of shaft.
		lm.box("Granite", Vector3(p.x + out_v.x * 0.22, SHAFT_H * 0.5 + 0.6, p.y + out_v.y * 0.22),
			Vector3(1.15, SHAFT_H - 1.2, 1.15), Basis(Vector3.UP, -ang))
		# Vertical mid-face mullion rib.
		var n_out := Vector2(edge.y, -edge.x).normalized()
		if n_out.dot(mid) < 0.0:
			n_out = -n_out
		lm.box("Metal", Vector3(mid.x + n_out.x * 0.16, (5.6 + SHAFT_H) * 0.5, mid.y + n_out.y * 0.16),
			Vector3(0.32, SHAFT_H - 5.6, 0.32), Basis(Vector3.UP, -ang))
	# Horizontal dark-granite floor spandrel rings every storey (16 levels).
	for fl in 17:
		var fy := 5.6 + float(fl) * ((SHAFT_H - 5.6) / 16.0)
		var sp_r := 13.85 if fl % 4 == 0 else 13.72
		lm.frustum("Granite", Vector3(0.0, fy - 0.38, 0.0), sp_r, sp_r, 0.76, 7, -PI * 0.5)

static func _build_crown_and_beacons(lm: LandmarkMesh, model: Node3D) -> void:
	# Stepped heptagonal mechanical penthouse & dark-granite crown parapet (60.5..66.0 m).
	lm.poly_prism("Granite", _heptagon(11.6), SHAFT_H, 63.8)
	lm.poly_prism("Metal", _heptagon(10.8), 63.8, 65.4)
	lm.poly_prism("Roof", _heptagon(10.5), 65.4, TOP_M)
	# Illuminated blue circular "If" rooftop logo discs on opposite crown faces.
	for a: float in [0.25, PI + 0.25]:
		var cx := cos(a) * 11.4
		var cz := sin(a) * 11.4
		var n := Vector3(cos(a), 0.0, sin(a))
		lm.disc("IfGlow", Vector3(cx, 62.6, cz), n, 1.75, 18)
	# Twin red ICAO aviation obstruction lights on rooftop crown.
	var b1 := Vector3(7.5, TOP_M + 0.35, 0.0)
	var b2 := Vector3(-7.5, TOP_M + 0.35, 0.0)
	lm.box("Beacon", b1, Vector3(0.45, 0.45, 0.45))
	lm.box("Beacon", b2, Vector3(0.45, 0.45, 0.45))
	model.set_meta(LandmarkLights.HALO_META, [
		[b1, 2.2, Color(1.0, 0.14, 0.08)],
		[b2, 2.2, Color(1.0, 0.14, 0.08)],
		[Vector3(cos(0.25) * 11.6, 62.6, sin(0.25) * 11.6), 3.4, Color(0.28, 0.58, 1.0)],
		[Vector3(cos(PI + 0.25) * 11.6, 62.6, sin(PI + 0.25) * 11.6), 3.4, Color(0.28, 0.58, 1.0)],
	])

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 26.0), Vector3(0.0, 28.0, 12.0), 54.0, 0.75, 48.0, Color(0.90, 0.94, 1.0)],
		[Vector3(24.0, 2.0, -14.0), Vector3(10.0, 32.0, -6.0), 54.0, 0.70, 48.0, Color(0.90, 0.94, 1.0)],
	])
