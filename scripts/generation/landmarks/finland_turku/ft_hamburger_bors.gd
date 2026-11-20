class_name FtHamburgerBors
extends RefCounted

## Scandic Hamburger Börs (Schauman & Nordström 2021 + Frithiof Strandell 1894)
## facing Turku Market Square (Kauppatori) across Eerikinkatu & Kauppiaskatu.
## Origin at OSM way 1074264772 centroid (60.451003 N, 22.268718 E), yaw_deg -35.3:
##   -Z bears 324.7° (NW, Eerikinkatu front facing directly onto Kauppatori)
##   -X bears 234.7° (SW, Kauppiaskatu flank)
##   +X bears 54.7° (NE, preserved 1894 Vanha Börs Jugend corner wing)
##   +Z bears 144.7° (SE, courtyard & rear hotel wings)
##
## Architectural & facade spec (OSM way 1074264772 62.7 x 56.0 m + way 687986076
## Vanha Börs 22.9 x 23.5 m; turku_lod2 height 34.8 m, 9-10 storeys):
## - Dual architectural icon on a dark granite plinth (FOUND = -1.6 m):
##   1. 2021 Uusi Börs: rhythmic two-storey light-stone/limestone arched
##      colonnade along the Kauppatori (-Z) and Kauppiaskatu (-X) fronts with
##      tall warm-glazed hotel lobby arches; 5-storey pale warm-brick hotel
##      body with deep-set vertical windows; stepped-back dark bronze/copper
##      upper penthouses (levels 8-9) and glazed rooftop terrace bar peaking
##      at 34.8 m (matching LoD2 34.8 m).
##   2. 1894 Vanha Börs (Frithiof Strandell): preserved 3.5-storey ornate
##      Jugend / Neo-Renaissance corner palace on the NE side (+X, -Z) in warm
##      ochre/terracotta plaster with rusticated base, projecting bay windows,
##      ornate dormers, steep copper roof, and signature corner onion turret!
## - Night illumination: warm lobby/arcade glow, illuminated hotel room grid,
##   rooftop bar glow, and upward floodlights (LandmarkLights.FLOOD_META).

const FOUND := -1.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#DCD5C6", 3.0))
	lm.use("BrickLight", LandmarkMaterials.pbr("brick", "#C9B9A2", 2.5))
	lm.use("CopperDark", LandmarkMaterials.pbr("sheet_metal", "#4E3C30", 2.5, 0.45, 0.55))
	lm.use("Copper", LandmarkFrKit.copper("#4A7462"))
	lm.use("JugendWall", LandmarkMaterials.pbr("render", "#D9B98A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F1ECE0", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6D6963", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A0", 0.90))

	_build_uusi_bors(lm)
	_build_vanha_bors(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.92, 0.78)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 1.0, -34.0), Vector3(-6.0, 14.0, -24.0), 34.0, 1.05, 65.0, warm],
		[Vector3(18.0, 1.0, -34.0), Vector3(18.0, 10.0, -22.0), 32.0, 1.00, 55.0, warm],
		[Vector3(-38.0, 1.0, -4.0), Vector3(-28.0, 16.0, 0.0), 34.0, 0.95, 65.0, warm],
	])

static func _build_uusi_bors(lm: LandmarkMesh) -> void:
	# Main 2021 hotel footprint: x = -30.5..+11.5 (Kauppatori front) & rear wing to x = +29.5.
	LandmarkFrKit.rect(lm, "Granite", -31.0, 30.5, -27.5, 27.5, FOUND, 0.8)
	# Two-storey rhythmic arched limestone colonnade podium (y = 0.8..8.2 m).
	LandmarkFrKit.rect(lm, "Limestone", -30.5, 11.5, -27.0, 26.8, 0.8, 8.2)
	LandmarkFrKit.rect(lm, "Limestone", 11.5, 30.0, -4.0, 26.8, 0.8, 8.2)
	LandmarkFrParts.band(lm, "Trim", -30.5, 11.5, -27.0, 26.8, 7.8, 0.45, 0.22)
	# Rhythmic 2-storey colonnade arches facing Kauppatori (-Z) & Kauppiaskatu (-X).
	for i in 9:
		var ax := lerpf(-27.8, 8.8, float(i) / 8.0)
		LandmarkFrParts.opening(lm, "Limestone", "Glass", Vector3(ax, 0.9, -27.0), Vector3.FORWARD,
			3.3, 6.2, LandmarkFrParts.HEAD_ROUND, 0.36, 0.24, 1)
		lm.box("WarmGlow", Vector3(ax, 3.6, -27.02), Vector3(2.4, 3.8, 0.04), Basis(), 0.0)
	for j in 11:
		var az := lerpf(-24.0, 23.5, float(j) / 10.0)
		LandmarkFrParts.opening(lm, "Limestone", "Glass", Vector3(-30.5, 0.9, az), Vector3.LEFT,
			3.2, 6.2, LandmarkFrParts.HEAD_ROUND, 0.36, 0.24, 1)
		lm.box("WarmGlow", Vector3(-30.52, 3.6, az), Vector3(0.04, 3.8, 2.3), Basis(), 0.0)
	# Mid-rise pale warm-brick hotel body (levels 3-7, y = 8.2..26.0 m).
	LandmarkFrKit.rect(lm, "BrickLight", -30.2, 11.2, -26.6, 26.4, 8.2, 26.0)
	LandmarkFrKit.rect(lm, "BrickLight", 11.2, 29.6, -3.5, 26.4, 8.2, 24.5)
	LandmarkFrParts.band(lm, "Limestone", -30.2, 11.2, -26.6, 26.4, 25.4, 0.65, 0.24)
	# Deep rhythmic hotel windows on Kauppatori (-Z), Kauppiaskatu (-X), and rear (+Z).
	LandmarkFrParts.facade(lm, "BrickLight", "Glass", Vector3(-29.0, 9.0, -26.6), Vector3(10.0, 9.0, -26.6),
		Vector3.FORWARD, 16.4, 10, 5, Vector2(1.75, 2.15), 0.7, 3.25, 0.26)
	LandmarkFrParts.facade(lm, "BrickLight", "Glass", Vector3(-30.2, 9.0, 25.0), Vector3(-30.2, 9.0, -25.0),
		Vector3.LEFT, 16.4, 12, 5, Vector2(1.75, 2.15), 0.7, 3.25, 0.26)
	LandmarkFrParts.facade(lm, "BrickLight", "Glass", Vector3(-29.0, 9.0, 26.4), Vector3(28.0, 9.0, 26.4),
		Vector3.BACK, 15.0, 14, 5, Vector2(1.65, 2.0), 0.7, 3.0, 0.24)
	# Warm lit accent room panes on the Kauppatori elevation.
	for k in 8:
		var gx := -25.0 + float(k) * 4.8
		var gy := 10.6 + float((k * 2) % 5) * 3.25
		lm.box("WarmGlow", Vector3(gx, gy, -26.64), Vector3(1.4, 1.7, 0.04), Basis(), 0.0)
	# Recessed dark copper/bronze upper setbacks (levels 8-9, y = 26.0..32.6 m) + rooftop bar to 34.8 m.
	LandmarkFrKit.rect(lm, "CopperDark", -27.8, 9.2, -23.8, 22.0, 26.0, 32.4)
	LandmarkFrParts.facade(lm, "CopperDark", "Glass", Vector3(-26.8, 26.5, -23.8), Vector3(8.2, 26.5, -23.8),
		Vector3.FORWARD, 5.6, 9, 2, Vector2(2.2, 2.0), 0.5, 2.8, 0.20)
	LandmarkFrParts.facade(lm, "CopperDark", "Glass", Vector3(-27.8, 26.5, 20.5), Vector3(-27.8, 26.5, -22.5),
		Vector3.LEFT, 5.6, 10, 2, Vector2(2.2, 2.0), 0.5, 2.8, 0.20)
	# Rooftop terrace glass bar pavilion & canopy peaking at 34.8 m.
	LandmarkFrKit.rect(lm, "Glass", -21.0, 4.0, -19.5, -9.5, 32.4, 34.5)
	LandmarkFrKit.rect(lm, "WarmGlow", -20.5, 3.5, -19.0, -10.0, 32.6, 34.2)
	LandmarkFrKit.rect(lm, "CopperDark", -21.8, 4.8, -20.2, -8.8, 34.45, 34.80)

static func _build_vanha_bors(lm: LandmarkMesh) -> void:
	# Preserved 1894 Frithiof Strandell Jugend / Neo-Renaissance corner wing (+X, -Z).
	var x0 := 11.2
	var x1 := 30.8
	var z0 := -27.0
	var z1 := -3.5
	LandmarkFrKit.rect(lm, "Granite", x0 - 0.2, x1 + 0.3, z0 - 0.3, z1, FOUND, 1.4)
	LandmarkFrKit.rect(lm, "JugendWall", x0, x1, z0, z1, 1.4, 14.6)
	LandmarkFrParts.band(lm, "Trim", x0, x1, z0, z1, 5.2, 0.38, 0.16)
	LandmarkFrParts.band(lm, "Trim", x0, x1, z0, z1, 10.2, 0.32, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", x0, x1, z0, z1, 14.1, 0.55)
	LandmarkFrKit.hip(lm, "Copper", x0, x1, z0, z1, 14.6, 4.6, 0.50)
	# Ornate Jugend arched windows & projecting bay window facing Kauppatori (-Z).
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(13.2, 2.0, z0), Vector3(28.5, 2.0, z0),
		Vector3.FORWARD, 4, 2.0, 2.8, LandmarkFrParts.HEAD_ROUND, 0.24, 0.14, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(13.2, 6.4, z0), Vector3(28.5, 6.4, z0),
		Vector3.FORWARD, 4, 1.8, 2.8, LandmarkFrParts.HEAD_ROUND, 0.24, 0.14, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(13.2, 10.9, z0), Vector3(28.5, 10.9, z0),
		Vector3.FORWARD, 4, 1.6, 2.4, LandmarkFrParts.HEAD_FLAT, 0.22, 0.12, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(x1, 6.4, -24.0), Vector3(x1, 6.4, -6.0),
		Vector3.RIGHT, 4, 1.7, 2.8, LandmarkFrParts.HEAD_ROUND, 0.24, 0.14, 1)
	# Projecting ornate corner onion turret at NE corner (x1, z0).
	var tx := x1 - 0.6
	var tz := z0 + 0.6
	lm.frustum("JugendWall", Vector3(tx, 5.0, tz), 2.5, 2.45, 11.2, 12)
	lm.frustum("Trim", Vector3(tx, 15.8, tz), 2.65, 2.75, 0.45, 12)
	LandmarkFrParts.ring_openings(lm, "Trim", "Glass", Vector3(tx, 11.2, tz), 2.48, 6, 0.85, 2.2, LandmarkFrParts.HEAD_ROUND, 0.0, 0.14)
	lm.lathe("Copper", Vector3(tx, 16.25, tz), PackedVector2Array([
		Vector2(2.75, 0.0), Vector2(3.10, 1.1), Vector2(2.40, 2.4),
		Vector2(1.10, 3.8), Vector2(0.18, 5.8),
	]), 12, 1.0, 1.0, 0.0, false)
	lm.beam("Trim", Vector3(tx, 22.0, tz), Vector3(tx, 23.4, tz), 0.08, 0.08)
