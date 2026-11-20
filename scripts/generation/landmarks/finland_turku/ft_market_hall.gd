class_name FtMarketHall
extends RefCounted

## Turku Market Hall (Turun kauppahalli, Gustaf Nyström, 1896) spanning the
## full block from Eerikinkatu to Linnankatu in central Turku.
## Origin at OSM way 9166246 centroid (60.449761 N, 22.266060 E), yaw_deg 54.9:
##   -X bears 324.9° (NW, Eerikinkatu ornate Neo-Renaissance end gable)
##   +X bears 144.9° (SE, Linnankatu ornate Neo-Renaissance end gable)
##   +Z / -Z are the 118 m rhythmic pilastered side elevations
##
## Architectural & facade spec (counted from Wikimedia Commons / Finna refs
## and OSM way 9166246: 118.8 x 17.4 m, LoD2 10.8 m, pitch 18°, height_m = 13.0):
## - True 118.4 x 17.4 m through-block polychrome red-brick & cream-plaster
##   Neo-Renaissance market hall on a grey-granite plinth (foundation dropped
##   to y = -1.6 m).
## - 24 rhythmic side window bays along both 118 m flanks between 25 red-brick
##   pilasters with cream-plaster bands, capitals and round-arched windows
##   showing warm interior market glow at night.
## - Low-pitched 18° dark-slate main roof (eaves 6.8 m, ridge 9.5 m) crowned
##   by a full-length raised clerestory skylight lantern (108 x 5.2 m, y =
##   9.0..11.8 m) with 24 rhythmic mullions and warm interior night glow.
## - Ornate Neo-Renaissance stepped end gables on both Eerikinkatu (-X) and
##   Linnankatu (+X): polychrome red-brick & cream-plaster horizontal bands,
##   grand arched carriage entrance portals with rusticated surrounds & warm
##   vestibules, flanking arched shop windows, paired upper mezzanine windows,
##   gilded coat-of-arms relief medallions, 4 obelisk pinnacles per gable,
##   and central crowning finials peaking at 13.0 m (matching height_m = 13.0).
## - Night illumination: warm upward floodlights (LandmarkLights.FLOOD_META)
##   on both Eerikinkatu and Linnankatu stepped gables + clerestory glow.

const FOUND := -1.6
const PLINTH_Y := 1.25
const HALF_L := 59.0
const HALF_W := 8.7
const EAVE_Y := 6.85
const ROOF_RISE := 2.75

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#964532", 2.5))
	lm.use("BrickDark", LandmarkMaterials.pbr("brick", "#743324", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#EFE8D8", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#88847C", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#373D40", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#222B32"))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#4A3626", 1.5))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A0", 0.95))

	_build_hall_body(lm)
	_build_side_bays(lm)
	_build_clerestory_lantern(lm)
	_build_end_gables(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.91, 0.76)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-67.5, 0.9, -4.5), Vector3(-59.0, 7.5, 0.0), 34.0, 1.05, 45.0, warm],
		[Vector3(-67.5, 0.9, 4.5), Vector3(-59.0, 7.5, 0.0), 34.0, 1.05, 45.0, warm],
		[Vector3(67.5, 0.9, -4.5), Vector3(59.0, 7.5, 0.0), 34.0, 1.05, 45.0, warm],
		[Vector3(67.5, 0.9, 4.5), Vector3(59.0, 7.5, 0.0), 34.0, 1.05, 45.0, warm],
	])

static func _build_hall_body(lm: LandmarkMesh) -> void:
	# Coursed grey-granite plinth running the full 118.8 m length.
	LandmarkFrKit.rect(lm, "Stone", -HALF_L - 0.35, HALF_L + 0.35, -HALF_W - 0.3, HALF_W + 0.3, FOUND, PLINTH_Y)
	# Main red-brick through-block hall (-59..+59 x -8.7..+8.7).
	LandmarkFrKit.rect(lm, "Brick", -HALF_L, HALF_L, -HALF_W, HALF_W, PLINTH_Y, EAVE_Y)
	# Polychrome cream-plaster horizontal sill course and eave cornice band.
	LandmarkFrParts.band(lm, "Trim", -HALF_L, HALF_L, -HALF_W, HALF_W, 2.35, 0.24, 0.10)
	LandmarkFrParts.band(lm, "Trim", -HALF_L, HALF_L, -HALF_W, HALF_W, 5.75, 0.26, 0.12)
	LandmarkFrParts.cornice_ring(lm, "Trim", -HALF_L, HALF_L, -HALF_W, HALF_W, EAVE_Y - 0.45, 0.45)
	# 18° dark-slate pitched main hall roof (y = 6.85..9.60 m).
	LandmarkFrKit.gable(lm, "Roof", -HALF_L, HALF_L, -HALF_W, HALF_W, EAVE_Y, ROOF_RISE, 0.45, "Brick", 1)

static func _build_side_bays(lm: LandmarkMesh) -> void:
	# 24 rhythmic pilastered side window bays along both long flanks (+Z and -Z).
	var bays := 24
	var x0 := -55.2
	var x1 := 55.2
	var bay_w := (x1 - x0) / float(bays)
	for sz: float in [-1.0, 1.0]:
		var n := Vector3(0.0, 0.0, sz)
		var wz := sz * HALF_W
		# 25 rhythmic brick pilasters with cream-plaster bases and capitals.
		for i in bays + 1:
			var px := x0 + float(i) * bay_w
			lm.box("BrickDark", Vector3(px, 4.05, wz + sz * 0.12), Vector3(0.62, 5.4, 0.26), Basis(), 0.0)
			lm.box("Trim", Vector3(px, PLINTH_Y + 0.18, wz + sz * 0.16), Vector3(0.76, 0.36, 0.32), Basis(), 0.0)
			lm.box("Trim", Vector3(px, 6.25, wz + sz * 0.16), Vector3(0.78, 0.30, 0.32), Basis(), 0.0)
		# 24 round-arched market windows with cream archivolts and warm interior glow.
		for i in bays:
			var wx := x0 + (float(i) + 0.5) * bay_w
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 2.60, wz), n,
				2.35, 3.15, LandmarkFrParts.HEAD_ROUND, 0.22, 0.12, 1)
			lm.box("WarmGlow", Vector3(wx, 3.95, wz + sz * 0.02), Vector3(1.85, 2.0, 0.04), Basis(), 0.0)
			# Small cream-plaster keystone at each arch crown.
			lm.box("Trim", Vector3(wx, 5.72, wz + sz * 0.14), Vector3(0.32, 0.42, 0.14), Basis(), 0.0)

static func _build_clerestory_lantern(lm: LandmarkMesh) -> void:
	# Full-length raised clerestory skylight monitor along the central ridge (108 x 5.2 m).
	var lx := 54.0
	var lw := 2.6
	LandmarkFrKit.rect(lm, "Trim", -lx - 0.3, lx + 0.3, -lw - 0.18, lw + 0.18, 8.85, 9.25)
	LandmarkFrKit.rect(lm, "Glass", -lx, lx, -lw, lw, 9.25, 10.85)
	LandmarkFrKit.rect(lm, "WarmGlow", -lx + 0.25, lx - 0.25, -lw + 0.18, lw - 0.18, 9.35, 10.75)
	# Pitched glazed-and-slate skylight monitor roof rising to 11.75 m.
	LandmarkFrKit.gable(lm, "Roof", -lx - 0.35, lx + 0.35, -lw - 0.25, lw + 0.25, 10.85, 0.90, 0.25, "Trim", 1)
	# 24 rhythmic vertical mullions along both sides of the clerestory lantern.
	for i in 25:
		var mx := lerpf(-lx, lx, float(i) / 24.0)
		lm.box("Trim", Vector3(mx, 10.05, lw + 0.06), Vector3(0.18, 1.65, 0.14), Basis(), 0.0)
		lm.box("Trim", Vector3(mx, 10.05, -lw - 0.06), Vector3(0.18, 1.65, 0.14), Basis(), 0.0)

static func _build_end_gables(lm: LandmarkMesh) -> void:
	# Ornate Neo-Renaissance stepped end facades on Eerikinkatu (-X) and Linnankatu (+X).
	for sx: float in [-1.0, 1.0]:
		var n := Vector3(sx, 0.0, 0.0)
		var ex := sx * HALF_L
		# Slightly projecting end frontispiece framing the carriage portal.
		LandmarkFrKit.rect(lm, "Stone", ex - sx * 0.4, ex + sx * 0.65, -HALF_W - 0.35, HALF_W + 0.35, FOUND, PLINTH_Y)
		LandmarkFrKit.rect(lm, "Brick", ex - sx * 0.3, ex + sx * 0.50, -HALF_W - 0.1, HALF_W + 0.1, PLINTH_Y, EAVE_Y + 0.4)
		# Polychrome cream-plaster horizontal bands across the brick frontispiece.
		for by: float in [2.35, 4.10, 5.75, 7.05]:
			lm.box("Trim", Vector3(ex + sx * 0.52, by, 0.0), Vector3(0.14, 0.28, HALF_W * 2.0 + 0.35), Basis(), 0.0)
		# Grand central arched carriage portal (w = 4.6 m, h = 5.4 m) with paired pilasters.
		LandmarkFrParts.opening(lm, "Stone", "Door", Vector3(ex + sx * 0.50, 0.25, 0.0), n,
			4.6, 5.4, LandmarkFrParts.HEAD_ROUND, 0.48, 0.28, 0)
		lm.box("WarmGlow", Vector3(ex + sx * 0.53, 3.7, 0.0), Vector3(0.05, 2.2, 3.4), Basis(), 0.0)
		for pz: float in [-3.15, 3.15]:
			lm.box("Trim", Vector3(ex + sx * 0.62, 3.9, pz), Vector3(0.32, 5.6, 0.72), Basis(), 0.0)
			lm.box("Trim", Vector3(ex + sx * 0.65, 6.85, pz), Vector3(0.42, 0.40, 0.90), Basis(), 0.0)
		# Flanking arched shop/market windows on either side of the carriage portal.
		for sz: float in [-1.0, 1.0]:
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(ex + sx * 0.50, 2.45, sz * 5.85), n,
				2.1, 3.25, LandmarkFrParts.HEAD_ROUND, 0.24, 0.14, 1)
			lm.box("WarmGlow", Vector3(ex + sx * 0.52, 3.85, sz * 5.85), Vector3(0.04, 2.0, 1.5), Basis(), 0.0)
		# Multi-tiered Neo-Renaissance stepped gable rising from 7.2 m to 12.1 m.
		var tiers := [
			[7.2, 8.6, 15.8],
			[8.6, 9.9, 11.4],
			[9.9, 11.1, 7.2],
			[11.1, 12.1, 3.8],
		]
		for t: Array in tiers:
			var y0: float = t[0]
			var y1: float = t[1]
			var gw: float = t[2]
			lm.box("Brick", Vector3(ex + sx * 0.25, (y0 + y1) * 0.5, 0.0), Vector3(0.75, y1 - y0, gw), Basis(), 0.0)
			lm.box("Trim", Vector3(ex + sx * 0.30, y1, 0.0), Vector3(0.92, 0.24, gw + 0.36), Basis(), 0.0)
		# Paired upper mezzanine arched windows + gilded Turku coat-of-arms medallion.
		for sz: float in [-1.0, 1.0]:
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(ex + sx * 0.62, 7.65, sz * 2.15), n,
				1.6, 2.05, LandmarkFrParts.HEAD_ROUND, 0.20, 0.12, 1)
		lm.disc("Trim", Vector3(ex + sx * 0.66, 10.55, 0.0), n, 0.85, 16)
		lm.disc("Gilt", Vector3(ex + sx * 0.70, 10.55, 0.0), n, 0.54, 16)
		# Four brick-and-plaster obelisk pinnacles on the gable steps & corners.
		for pin: Array in [[8.6, 7.6], [8.6, -7.6], [10.0, 5.4], [10.0, -5.4]]:
			var py: float = pin[0]
			var pz: float = pin[1]
			lm.box("Trim", Vector3(ex + sx * 0.30, py + 0.35, pz), Vector3(0.68, 0.70, 0.68), Basis(), 0.0)
			lm.spire("Brick", Vector3(ex + sx * 0.30, py + 0.70, pz), 0.34, 1.35, 0.0, 4)
			lm.lathe("Gilt", Vector3(ex + sx * 0.30, py + 2.02, pz), LandmarkFrKit.ball(0.14), 8)
		# Central crowning gable pinnacle peaking at 13.0 m (matching height_m = 13.0).
		lm.box("Trim", Vector3(ex + sx * 0.30, 12.35, 0.0), Vector3(0.85, 0.50, 1.25), Basis(), 0.0)
		lm.spire("Gilt", Vector3(ex + sx * 0.30, 12.60, 0.0), 0.22, 0.40, 0.0, 8)
