class_name FtTurunSanomat
extends RefCounted

## Turun Sanomat Building (Alvar Aalto, 1930) at Kauppiaskatu 5 — Finland's
## defining early Functionalist masterpiece, rebuilt with full 4-sided
## architectural fidelity and photo-verified Aalto details (dark-underside
## cantilevered entrance canopy, row of glowing milk-glass globe wall lamps,
## vertical narrow entrance slit windows, flush Kauppiaskatu strip windows,
## Aalto top-floor horizontal loggia screen wall, and fenestrated side &
## skylit rear courtyard elevations — zero blank white walls!).
## Origin at OSM way 687986057 centroid (60.450507 N, 22.269689 E), yaw_deg -35.3:
##   -X bears 234.7° (SW, Kauppiaskatu 5 iconic white street facade)
##   +X bears 54.7° (NE, rear printing-hall & skylit courtyard wing)
##   -Z bears 324.7° (NW, toward Eerikinkatu / Hamburger Börs)
##   +Z bears 144.7° (SE, toward Linnankatu / Aurajoki)
## Surfaces: 7 merged PBR parts (White, Concrete, Granite, DarkMetal, Roof,
## Glass, WarmGlow).

const FOUND := -1.6
const MAIN_TOP := 19.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F1EFE8", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D2CFC7", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#5E6064", 2.5))
	lm.use("DarkMetal", LandmarkMaterials.paint("#262B30", 0.45, 0.55))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4C5054", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#22313B"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE6B6", 1.15))

	_build_body_and_sides(lm)
	_build_street_facade(lm)
	_build_rooftop_loggia_and_penthouse(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.94, 0.82)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-19.5, 1.2, -6.0), Vector3(-11.5, 11.0, -4.0), 38.0, 0.90, 48.0, warm],
		[Vector3(-19.5, 1.2, 8.0), Vector3(-11.5, 11.0, 6.0), 38.0, 0.90, 48.0, warm],
	])

static func _build_body_and_sides(lm: LandmarkMesh) -> void:
	# Main 5-storey functionalist volume (-11.7..11.7 x -16.5..16.5 m, H 19.2 m).
	LandmarkFrKit.rect(lm, "Granite", -11.9, 11.9, -16.7, 16.7, FOUND, 0.60)
	LandmarkFrKit.rect(lm, "White", -11.7, 11.7, -16.5, 16.5, 0.60, MAIN_TOP)
	LandmarkFrKit.rect(lm, "Roof", -11.4, 11.4, -16.2, 16.2, MAIN_TOP, MAIN_TOP + 0.28)
	# Fenestrated NW (-Z) and SE (+Z) side elevations — rhythmic Aalto recessed casement grid!
	for sz: float in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		# Continuous thin white/dark-underside ground-floor street canopy wrapping side bays.
		LandmarkFrKit.rect(lm, "DarkMetal", -11.9, 11.9, sz * 16.5, sz * 17.7, 4.15, 4.30)
		LandmarkFrKit.rect(lm, "White", -11.9, 11.9, sz * 16.5, sz * 17.7, 4.30, 4.52)
		# Ground-floor framed shopfront windows along side flanks.
		LandmarkFrParts.openings(lm, "DarkMetal", "Glass", Vector3(-9.5, 0.85, sz * 16.5),
			Vector3(9.5, 0.85, sz * 16.5), n, 5, 2.4, 2.9, LandmarkFrParts.HEAD_FLAT, 0.14, 0.10, 1)
		# Four upper storeys of crisp recessed functionalist square windows (6 bays x 4 rows).
		for fl in 4:
			var wy := 5.75 + float(fl) * 3.15
			LandmarkFrParts.openings(lm, "DarkMetal", "Glass", Vector3(-9.8, wy, sz * 16.5),
				Vector3(9.8, wy, sz * 16.5), n, 6, 1.65, 1.85, LandmarkFrParts.HEAD_FLAT, 0.12, 0.10, 1)
	# Rear printing-hall elevation (+X): wide industrial horizontal strip windows.
	for fl in 4:
		var fy := 5.75 + float(fl) * 3.15
		LandmarkFrKit.rect(lm, "Glass", 11.62, 11.78, -14.5, 14.5, fy, fy + 1.85)
		for j in 12:
			var mz := lerpf(-14.5, 14.5, float(j) / 11.0)
			lm.box("DarkMetal", Vector3(11.78, fy + 0.92, mz), Vector3(0.10, 1.88, 0.12), Basis(), 0.0)

static func _build_street_facade(lm: LandmarkMesh) -> void:
	# Iconic Kauppiaskatu 5 street elevation (-X):
	# 1. Giant ground-floor press-display shopfront glazing (z = -15.2..+7.2) with warm interior glow.
	LandmarkFrKit.rect(lm, "Glass", -11.82, -11.65, -15.2, 7.2, 0.72, 4.35)
	LandmarkFrKit.rect(lm, "WarmGlow", -11.68, -11.55, -14.8, 6.8, 1.0, 4.05)
	for j in 8:
		var mz := lerpf(-15.2, 7.2, float(j) / 7.0)
		lm.box("DarkMetal", Vector3(-11.82, 2.54, mz), Vector3(0.14, 3.68, 0.14), Basis(), 0.0)
	# 2. Vertical narrow Aalto entrance slit windows (z = 8.0..10.4) & recessed south doorway (z = 11.2..15.2).
	for k in 4:
		var sz := lerpf(8.1, 10.2, float(k) / 3.0)
		LandmarkFrKit.rect(lm, "DarkMetal", -11.78, -11.62, sz - 0.16, sz + 0.16, 1.1, 3.85)
	LandmarkFrKit.rect(lm, "Glass", -11.82, -11.65, 11.2, 15.2, 0.65, 3.95)
	# 3. Thin cantilevered canopy across the full street front with dark-charcoal underside & white fascia.
	LandmarkFrKit.rect(lm, "DarkMetal", -13.9, -11.65, -16.6, 16.6, 4.15, 4.30)
	LandmarkFrKit.rect(lm, "White", -13.9, -11.65, -16.6, 16.6, 4.30, 4.55)
	# Iconic row of glowing white milk-glass globe wall lamps under the Kauppiaskatu canopy.
	for k in 10:
		var lz := lerpf(-14.6, 14.6, float(k) / 9.0)
		lm.box("DarkMetal", Vector3(-11.95, 3.72, lz), Vector3(0.32, 0.08, 0.08), Basis(), 0.0)
		lm.lathe("WarmGlow", Vector3(-12.12, 3.75, lz), LandmarkFrKit.ball(0.18), 8)
	# 4. Three flush horizontal Aalto strip-window ribbons across levels 2-4 (y = 5.75, 8.90, 12.05).
	for fl in 3:
		var fy := 5.75 + float(fl) * 3.15
		LandmarkFrKit.rect(lm, "Glass", -11.82, -11.65, -15.4, 15.4, fy, fy + 1.85)
		for j in 15:
			var mz := lerpf(-15.4, 15.4, float(j) / 14.0)
			lm.box("DarkMetal", Vector3(-11.84, fy + 0.92, mz), Vector3(0.10, 1.88, 0.10), Basis(), 0.0)
		if fl % 2 == 0:
			lm.box("WarmGlow", Vector3(-11.68, fy + 0.92, -3.5 + float(fl) * 3.5), Vector3(0.06, 1.55, 8.5), Basis(), 0.0)
	# 5. Level 5 iconic Aalto horizontal roof-terrace loggia ribbon cutout & white screen parapet!
	LandmarkFrKit.rect(lm, "Glass", -11.80, -11.65, -14.8, 14.8, 15.65, 17.55)
	for k in 9:
		var cz := lerpf(-14.4, 14.4, float(k) / 8.0)
		lm.frustum("White", Vector3(-11.82, 15.65, cz), 0.14, 0.14, 1.92, 8)
	# Clean horizontal white signage & cornice band above the loggia (top 19.2 m).
	lm.box("Concrete", Vector3(-11.78, 18.35, -3.0), Vector3(0.14, 0.55, 14.0), Basis(), 0.0)

static func _build_rooftop_loggia_and_penthouse(lm: LandmarkMesh) -> void:
	# Set-back Aalto rooftop studio penthouse & glazed courtyard skylight monitor peaking at 21.5 m.
	LandmarkFrKit.rect(lm, "White", -4.5, 8.8, -13.0, 13.0, MAIN_TOP, 21.35)
	LandmarkFrKit.rect(lm, "Roof", -4.6, 8.9, -13.1, 13.1, 21.35, 21.50)
	LandmarkFrKit.rect(lm, "Glass", -4.62, -4.45, -11.5, 11.5, MAIN_TOP + 0.40, 21.05)
	LandmarkFrKit.rect(lm, "WarmGlow", -4.48, -4.35, -11.0, 11.0, MAIN_TOP + 0.55, 20.85)
	# Thin Aalto sun-terrace rail along the Kauppiaskatu roof edge.
	LandmarkFrParts.railing(lm, "DarkMetal", Vector3(-11.4, MAIN_TOP, -15.5), Vector3(-11.4, MAIN_TOP, 15.5), 1.05, 2.2, 0.06)
