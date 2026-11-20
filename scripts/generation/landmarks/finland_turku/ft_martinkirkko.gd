class_name FtMartinkirkko
extends RefCounted

## St. Martin's Church (Martinkirkko, Totti Sora & Gunnar Wahlroos, 1933)
## on the Huovinkatu granite ridge in Martti, Turku.
## Origin at OSM way 48988447 centroid (60.440857 N, 22.254405 E), yaw_deg -33.7:
##   +X bears 56.3° (NE, semicircular choir apse)
##   -X bears 236.3° (SW, stepped stone entrance terrace & portal)
##   +Z bears 146.3° (SE, freestanding-feel 52 m SW campanile bell tower)
##   -Z bears 326.3° (NW, north aisle & park flank)
##
## Architectural & facade spec (counted from Wikimedia Commons / Finna refs
## and turku_lod2: 49.2 m main ridge/tower, 32° gable, registry height_m = 52.0):
## - Nordic Classicist / early Functionalist pale-ochre rendered basilica
##   seated on a coursed grey-granite plinth (foundation dropped to y = -3.5 m
##   for the sloped Huovinkatu ridge).
## - Tall narrow central nave (38 x 13.6 m, eaves 15.4 m, 32° green-copper
##   gable roof rising 4.3 m to 19.7 m) with crisp white cornice and 7 tall
##   vertical clerestory windows per side.
## - Low flanking side aisles (37 x 4.0 m each, eaves 7.2 m, lean-to copper
##   roofs sloping up to 9.2 m) with rhythmic recessed Classicist windows.
## - Semicircular choir apse at +X (r = 6.4 m, eaves 13.8 m, half-conical
##   copper cap to 17.4 m) with slender vertical altar lancets.
## - Monumental stepped grey-granite entrance terrace (-X, x = -27.2..-20.0)
##   leading to a recessed Classicist west portal with fluted stone pilasters,
##   triple bronze doors, and tall gable window + minimalist cross relief.
## - Iconic 52.0 m SW campanile (-14.5, +13.8, 7.4 m square) linked to the
##   south aisle by a low colonnaded gallery: tall sleek pale-ochre shaft to
##   36.8 m, open columned belfry lantern (y = 36.8..42.4 m, 12 white columns
##   framing the dark bell chamber), stepped octagonal copper drum & slender
##   copper spirelet, gilt orb and cross peaking at 52.0 m (height_m = 52.0).
## - Night illumination: warm upward floodlights (LandmarkLights.FLOOD_META)
##   on the 52 m campanile, west portal and nave, plus warm belfry glow.

const FOUND := -3.5
const PLINTH_Y := 2.0
const NAVE_EAVE := 15.4
const NAVE_HW := 6.8
const AISLE_HW := 10.8
const TX := -14.5
const TZ := 13.8
const TW := 7.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E2D5B8", 3.0))
	lm.use("WallShade", LandmarkMaterials.pbr("render", "#CFC1A3", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F1ECE1", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8B8780", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#4D7E6B"))
	lm.use("Glass", LandmarkMaterials.glass("#212A30"))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#4A3A2C", 1.5))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE2A6", 0.90))

	_build_nave_and_aisles(lm)
	_build_apse(lm)
	_build_west_entrance(lm)
	_build_campanile(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.92, 0.78)
	var belfry_warm := Color(1.0, 0.88, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-24.0, 1.0, 22.0), Vector3(TX, 30.0, TZ), 16.0, 1.10, 95.0, warm],
		[Vector3(-6.0, 1.0, 23.0), Vector3(TX, 42.0, TZ), 14.0, 1.05, 105.0, belfry_warm],
		[Vector3(-32.0, 1.0, 0.0), Vector3(-20.0, 10.0, 0.0), 30.0, 0.95, 55.0, warm],
		[Vector3(2.0, 1.0, -18.5), Vector3(0.0, 10.0, -7.0), 36.0, 0.80, 50.0, warm],
	])

static func _build_nave_and_aisles(lm: LandmarkMesh) -> void:
	# Coursed granite plinth under nave and side aisles.
	LandmarkFrKit.rect(lm, "Stone", -20.5, 18.5, -AISLE_HW - 0.4, AISLE_HW + 0.4, FOUND, PLINTH_Y)
	# Tall narrow central nave (-20..18 x -6.8..6.8).
	LandmarkFrKit.rect(lm, "Wall", -20.0, 18.0, -NAVE_HW, NAVE_HW, PLINTH_Y, NAVE_EAVE)
	LandmarkFrParts.cornice_ring(lm, "Trim", -20.0, 18.0, -NAVE_HW, NAVE_HW, NAVE_EAVE - 0.55, 0.55)
	LandmarkFrKit.gable(lm, "Copper", -20.0, 18.0, -NAVE_HW, NAVE_HW, NAVE_EAVE, 4.3, 0.55, "Wall", 1)
	LandmarkFrParts.roof_trim(lm, "Copper", -20.0, 18.0, -NAVE_HW, NAVE_HW, NAVE_EAVE, 4.3, 0.55, 1, 0.28)
	# Low flanking side aisles with lean-to copper roofs.
	for sz: float in [-1.0, 1.0]:
		var z_in := sz * NAVE_HW
		var z_out := sz * AISLE_HW
		var z0 := minf(z_in, z_out)
		var z1 := maxf(z_in, z_out)
		LandmarkFrKit.rect(lm, "Wall", -19.5, 17.5, z0, z1, PLINTH_Y, 7.2)
		LandmarkFrParts.band(lm, "Trim", -19.5, 17.5, z0, z1, 6.8, 0.40, 0.14)
		# Lean-to copper roof sloping from outer aisle eave (7.2 m) up to nave wall (9.1 m).
		var za := z_out + sz * 0.45
		var zb := z_in
		var p00 := Vector3(-19.8, 7.15, za)
		var p10 := Vector3(17.8, 7.15, za)
		var p11 := Vector3(17.8, 9.15, zb)
		var p01 := Vector3(-19.8, 9.15, zb)
		LandmarkFrKit.face(lm, "Copper", [p00, p10, p11, p01] if sz > 0.0 else [p10, p00, p01, p11])
		# End triangular fills on the lean-to roofs.
		for ex: float in [-19.5, 17.5]:
			var en := Vector3(-1.0 if ex < 0.0 else 1.0, 0.0, 0.0)
			lm.tri("Wall", Vector3(ex, 7.2, z_out), Vector3(ex, 7.2, z_in), Vector3(ex, 9.15, z_in),
				en, en, en, Vector2.ZERO, Vector2(4.0, 0.0), Vector2(4.0, -1.95))
		# 7 rhythmic vertical aisle windows + 7 tall clerestory windows above.
		var n := Vector3(0.0, 0.0, sz)
		for k in 7:
			var wx := -15.5 + 5.0 * float(k)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 3.1, z_out), n,
				1.35, 2.8, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 1)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 9.9, z_in), n,
				1.55, 4.3, LandmarkFrParts.HEAD_FLAT, 0.20, 0.12, 1)
			# Subtle vertical wall pilasters between clerestory bays.
			if k < 6:
				var px := wx + 2.5
				lm.box("Trim", Vector3(px, 12.1, z_in + sz * 0.06), Vector3(0.32, 5.2, 0.14), Basis(), 0.0)

static func _build_apse(lm: LandmarkMesh) -> void:
	# Semicircular choir apse at +X (centred at x = 18.0, r = 6.4 m).
	lm.frustum("Stone", Vector3(18.0, FOUND, 0.0), 6.75, 6.65, PLINTH_Y - FOUND, 20)
	lm.frustum("Wall", Vector3(18.0, PLINTH_Y, 0.0), 6.4, 6.4, 11.8, 20)
	lm.frustum("Trim", Vector3(18.0, 13.45, 0.0), 6.65, 6.72, 0.45, 20)
	lm.lathe("Copper", Vector3(18.0, 13.9, 0.0), PackedVector2Array([
		Vector2(6.8, 0.0), Vector2(4.8, 1.5), Vector2(2.2, 2.8), Vector2(0.15, 3.6),
	]), 20, 1.0, 1.0, 0.0, false)
	# 5 slender vertical sanctuary windows around the apse drum.
	for i in range(-2, 3):
		var a := float(i) * (PI * 0.22)
		var out := Vector3(cos(a), 0.0, sin(a))
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(18.0, 5.2, 0.0) + out * 6.4, out,
			1.05, 6.4, LandmarkFrParts.HEAD_FLAT, 0.18, 0.10, 0)
		lm.box("WarmGlow", Vector3(18.0, 8.2, 0.0) + out * 6.42, Vector3(0.65, 4.2, 0.04),
			Basis(Vector3.UP, atan2(out.x, out.z)), 0.0)

static func _build_west_entrance(lm: LandmarkMesh) -> void:
	# Projecting Classicist west vestibule (-23.6..-20.0, z = -6.4..6.4, h = 11.4 m).
	LandmarkFrKit.rect(lm, "Stone", -24.0, -20.0, -7.2, 7.2, FOUND, PLINTH_Y)
	LandmarkFrKit.rect(lm, "Wall", -23.5, -20.0, -6.4, 6.4, PLINTH_Y, 11.2)
	LandmarkFrParts.cornice_ring(lm, "Trim", -23.5, -20.0, -6.4, 6.4, 10.7, 0.50)
	LandmarkFrKit.hip(lm, "Copper", -23.5, -20.0, -6.4, 6.4, 11.2, 1.6, 0.35)
	# Stepped grey-granite entrance approach (-27.4..-24.0) with low cheek walls.
	for s in 6:
		var sy := lerpf(0.32, PLINTH_Y, float(s + 1) / 6.0)
		var x0 := -27.4 + float(s) * 0.56
		LandmarkFrKit.rect(lm, "Stone", x0, -23.8, -5.8, 5.8, FOUND, sy)
	for sz: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Stone", -27.6, -23.8, sz * 5.8 - 0.35, sz * 5.8 + 0.35, FOUND, 2.3)
	# Recessed triple-door Classicist granite portal framed by 4 tall pilasters.
	for pz: float in [-3.4, -1.25, 1.25, 3.4]:
		lm.box("Stone", Vector3(-23.62, 5.1, pz), Vector3(0.38, 6.2, 0.48), Basis(), 0.0)
	lm.box("Stone", Vector3(-23.62, 8.35, 0.0), Vector3(0.46, 0.55, 7.6), Basis(), 0.0)
	for dz: float in [-2.3, 0.0, 2.3]:
		LandmarkFrParts.opening(lm, "Stone", "Door", Vector3(-23.52, PLINTH_Y, dz), Vector3.LEFT,
			1.6, 4.4, LandmarkFrParts.HEAD_FLAT, 0.22, 0.14, 0)
	# Tall vertical west gable window & minimalist cross relief on the nave gable.
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-20.0, 12.6, 0.0), Vector3.LEFT,
		2.0, 4.4, LandmarkFrParts.HEAD_FLAT, 0.24, 0.14, 1)
	lm.box("Trim", Vector3(-20.08, 17.8, 0.0), Vector3(0.14, 2.1, 0.24), Basis(), 0.0)
	lm.box("Trim", Vector3(-20.08, 18.25, 0.0), Vector3(0.14, 0.24, 1.35), Basis(), 0.0)

static func _build_campanile(lm: LandmarkMesh) -> void:
	# Low covered link connecting south aisle (+10.8) to SW campanile (tz = 13.8).
	LandmarkFrKit.rect(lm, "Stone", TX - 2.6, TX + 2.6, AISLE_HW - 0.5, TZ - 2.5, FOUND, PLINTH_Y)
	LandmarkFrKit.rect(lm, "Wall", TX - 2.4, TX + 2.4, AISLE_HW - 0.5, TZ - 2.5, PLINTH_Y, 6.4)
	LandmarkFrKit.gable(lm, "Copper", TX - 2.4, TX + 2.4, AISLE_HW - 0.5, TZ - 2.5, 6.4, 1.2, 0.3, "Wall", 0)
	var hw := TW * 0.5
	# Heavy granite base (y = FOUND..2.8 m) + tall sleek pale-ochre shaft (2.8..36.8 m).
	LandmarkFrKit.rect(lm, "Stone", TX - hw - 0.4, TX + hw + 0.4, TZ - hw - 0.4, TZ + hw + 0.4, FOUND, 2.8)
	LandmarkFrKit.rect(lm, "Wall", TX - hw, TX + hw, TZ - hw, TZ + hw, 2.8, 36.8)
	LandmarkFrParts.corner_strips(lm, "Trim", TX - hw, TX + hw, TZ - hw, TZ + hw, 2.8, 36.4, 0.48, 0.10)
	# Horizontal string course & moulded cornice under the open belfry.
	LandmarkFrParts.band(lm, "Trim", TX - hw, TX + hw, TZ - hw, TZ + hw, 26.5, 0.42, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", TX - hw, TX + hw, TZ - hw, TZ + hw, 36.1, 0.70)
	# Narrow vertical slit windows up the campanile shaft.
	for f in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rot * Vector3(0.0, 0.0, 1.0)
		var fc := Vector3(TX, 0.0, TZ) + fn * hw
		for wy: float in [10.0, 18.0, 28.0]:
			LandmarkFrParts.opening(lm, "Trim", "Glass", fc + Vector3(0.0, wy, 0.0), fn,
				0.75, 3.6, LandmarkFrParts.HEAD_FLAT, 0.16, 0.08)
	# Open columned Classicist belfry lantern (y = 36.8..42.4 m):
	# recessed dark bell core with warm night interior glow + 12 outer white columns.
	LandmarkFrKit.rect(lm, "WallShade", TX - 2.2, TX + 2.2, TZ - 2.2, TZ + 2.2, 36.8, 41.8)
	LandmarkFrKit.rect(lm, "WarmGlow", TX - 2.26, TX + 2.26, TZ - 2.26, TZ + 2.26, 37.6, 41.0)
	var bhw := hw - 0.45
	for i in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(i))
		var fn: Vector3 = rot * Vector3(0.0, 0.0, 1.0)
		var rt: Vector3 = rot * Vector3(1.0, 0.0, 0.0)
		for k: float in [-1.0, -0.35, 0.35, 1.0]:
			var col_pos := Vector3(TX, 36.8, TZ) + fn * bhw + rt * (k * bhw)
			LandmarkDetail.column(lm, "Trim", col_pos, 0.24, 5.1, "tuscan", 0, 10)
	# Belfry entablature & projecting copper cornice (y = 41.9..42.9 m).
	LandmarkFrKit.rect(lm, "Trim", TX - hw - 0.1, TX + hw + 0.1, TZ - hw - 0.1, TZ + hw + 0.1, 41.9, 42.65)
	LandmarkFrKit.rect(lm, "Copper", TX - hw - 0.35, TX + hw + 0.35, TZ - hw - 0.35, TZ + hw + 0.35, 42.65, 43.0)
	# Stepped octagonal copper drum (43.0..45.2 m) + slender copper spirelet (45.2..49.8 m).
	lm.frustum("Copper", Vector3(TX, 43.0, TZ), 3.35, 2.55, 2.2, 8, PI / 8.0)
	lm.lathe("Copper", Vector3(TX, 45.2, TZ), PackedVector2Array([
		Vector2(2.65, 0.0), Vector2(1.45, 1.3), Vector2(0.55, 3.0), Vector2(0.14, 4.6),
	]), 8, 1.0, 1.0, PI / 8.0, false)
	# Gilt orb & tall slender cross peaking at 52.0 m.
	lm.lathe("Gilt", Vector3(TX, 49.7, TZ), LandmarkFrKit.ball(0.28), 10)
	LandmarkFrKit.cross(lm, "Gilt", Vector3(TX, 50.2, TZ), 1.80)
