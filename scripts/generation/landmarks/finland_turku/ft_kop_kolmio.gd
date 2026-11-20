class_name FtKopKolmio
extends RefCounted

## KOP-kolmio (Viljo Revell, 1964) — sharp triangular/wedge modernist commercial
## & office landmark at Aurakatu / Yliopistonkatu / Eerikinkatu by Kauppatori.
## Origin at OSM way 315833855 centroid (60.450125 N, 22.266478 E), yaw_deg -35.3:
##   -Z bears 324.7° (NW, Eerikinkatu front facing Kauppatori)
##   +X bears 54.7° (NE, Aurakatu corner prow)
##   +Z bears 144.7° (SE, Linnankatu / Market Hall side)
##   -X bears 234.7° (SW, Kristiinankatu side)
##
## Architectural & facade spec (OSM way 315833855 56.9 x 77.6 m, 8-10 lv,
## turku_lod2 height 30.5 m):
## - Recessed ground-floor modernist pillar colonnade & glazed shopping arcade
##   (y = 0..4.8 m) on a dark granite plinth (FOUND = -1.6 m) with warm glow.
## - 2-storey commercial podium (y = 4.8..10.2 m) wrapping the block perimeter.
## - Iconic Viljo Revell 1964 triangular/wedge 8-storey modernist tower rising
##   above the podium to 28.4 m + recessed rooftop penthouse to 30.5 m
##   (matching LoD2 30.5 m): crisp pale travertine/stone horizontal spandrel
##   bands alternating with continuous flush dark-glass ribbon windows and
##   fine vertical metal mullions.
## - Night illumination: warm ground arcade glow, illuminated office ribbon
##   windows, and upward facade floodlights (LandmarkLights.FLOOD_META).

const FOUND := -1.6
const PODIUM_H := 9.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("StoneLight", LandmarkMaterials.pbr("limestone", "#E4DFD4", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#5C5F64", 2.5))
	lm.use("DarkMetal", LandmarkMaterials.paint("#272C32", 0.45, 0.58))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#484C50", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#1E2C36"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE2AA", 0.90))

	_build_colonnade_podium(lm)
	_build_wedge_tower(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.93, 0.80)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(8.0, 1.0, -40.0), Vector3(2.0, 16.0, -24.0), 36.0, 1.00, 75.0, warm],
		[Vector3(34.0, 1.0, -10.0), Vector3(18.0, 16.0, -4.0), 36.0, 0.95, 75.0, warm],
		[Vector3(-32.0, 1.0, 8.0), Vector3(-16.0, 14.0, 4.0), 36.0, 0.80, 70.0, warm],
	])

static func _build_colonnade_podium(lm: LandmarkMesh) -> void:
	# Trapezoidal/triangular commercial base matching the sharp KOP-kolmio corner.
	var base_poly := PackedVector2Array([
		Vector2(-26.5, -34.0), Vector2(24.5, -34.0),
		Vector2(24.5, 16.0), Vector2(-4.0, 34.0), Vector2(-26.5, 34.0),
	])
	lm.poly_prism("Granite", base_poly, FOUND, 0.5)
	# Recessed ground-floor glazed shopping arcade behind structural colonnade pillars.
	var inset_poly := PackedVector2Array([
		Vector2(-23.5, -31.0), Vector2(21.5, -31.0),
		Vector2(21.5, 14.0), Vector2(-3.5, 31.0), Vector2(-23.5, 31.0),
	])
	lm.poly_prism("Glass", inset_poly, 0.5, 4.8)
	lm.poly_prism("WarmGlow", PackedVector2Array([
		Vector2(-23.0, -30.5), Vector2(21.0, -30.5),
		Vector2(21.0, 13.5), Vector2(-3.5, 30.5), Vector2(-23.0, 30.5),
	]), 0.8, 4.3)
	# Free-standing modernist colonnade pillars along the perimeter edges.
	for e in base_poly.size():
		var a := base_poly[e]
		var b := base_poly[(e + 1) % base_poly.size()]
		var n := maxi(int(a.distance_to(b) / 6.0), 3)
		for i in n:
			var p := a.lerp(b, float(i) / float(n))
			lm.box("StoneLight", Vector3(p.x, 2.65, p.y), Vector3(0.65, 4.3, 0.65), Basis(), 0.0)
	# 2nd-storey cantilevered podium band with continuous ribbon window (y = 4.8..9.8 m).
	lm.poly_prism("StoneLight", base_poly, 4.8, 6.1)
	lm.poly_prism("Glass", PackedVector2Array([
		Vector2(-26.3, -33.8), Vector2(24.3, -33.8),
		Vector2(24.3, 15.8), Vector2(-4.0, 33.8), Vector2(-26.3, 33.8),
	]), 6.1, 8.5)
	lm.poly_prism("StoneLight", base_poly, 8.5, PODIUM_H)
	lm.poly_prism("Roof", base_poly, PODIUM_H, PODIUM_H + 0.30)

static func _build_wedge_tower(lm: LandmarkMesh) -> void:
	# Iconic sharp triangular / wedge 8-storey Viljo Revell tower (y = 9.8..28.4 m).
	var tri_poly := PackedVector2Array([
		Vector2(-22.0, -30.5),
		Vector2(21.5, -30.5),
		Vector2(21.5, 11.0),
		Vector2(-22.0, 26.0),
	])
	var glass_poly := PackedVector2Array([
		Vector2(-21.85, -30.35),
		Vector2(21.35, -30.35),
		Vector2(21.35, 10.85),
		Vector2(-21.85, 25.85),
	])
	# 6 upper office storeys above podium: alternating pale stone spandrels & flush dark ribbon glass.
	var fl_h := 3.10
	for fl in 6:
		var y0 := PODIUM_H + float(fl) * fl_h
		lm.poly_prism("StoneLight", tri_poly, y0, y0 + 1.15)
		lm.poly_prism("Glass", glass_poly, y0 + 1.15, y0 + fl_h)
		# Crisp dark vertical ribbon mullions around all 4 wedge faces.
		for e in tri_poly.size():
			var a := tri_poly[e]
			var b := tri_poly[(e + 1) % tri_poly.size()]
			var cnt := maxi(int(a.distance_to(b) / 2.4), 6)
			for i in cnt + 1:
				var p := a.lerp(b, float(i) / float(cnt))
				lm.box("DarkMetal", Vector3(p.x, y0 + 1.15 + (fl_h - 1.15) * 0.5, p.y),
					Vector3(0.14, fl_h - 1.12, 0.14), Basis(), 0.0)
			# Select warmly lit office ribbon bays at night.
			if (fl + e) % 2 == 0:
				var m := a.lerp(b, 0.35 + float(fl % 3) * 0.18)
				var dir := (b - a).normalized()
				var ang := atan2(-dir.y, dir.x)
				lm.box("WarmGlow", Vector3(m.x, y0 + 2.05, m.y), Vector3(5.2, 1.55, 0.08), Basis(Vector3.UP, ang), 0.0)
	var top_y := PODIUM_H + 6.0 * fl_h
	lm.poly_prism("StoneLight", tri_poly, top_y, top_y + 0.85)
	lm.poly_prism("Roof", tri_poly, top_y + 0.85, top_y + 1.05)
	# Recessed modernist rooftop penthouse peaking at 30.5 m (matching LoD2 30.5 m).
	LandmarkFrKit.rect(lm, "StoneLight", -14.0, 12.0, -21.0, 2.0, top_y + 0.85, 30.25)
	LandmarkFrKit.rect(lm, "Roof", -14.2, 12.2, -21.2, 2.2, 30.25, 30.50)
