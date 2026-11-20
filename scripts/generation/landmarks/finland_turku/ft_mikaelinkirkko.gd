class_name FtMikaelinkirkko
extends RefCounted

## St. Michael's Church (Mikaelinkirkko, Lars Sonck, 1905) in Port Arthur /
## Puistokatu park, Turku.
## Origin at OSM way 34204417 centroid (60.448717 N, 22.247918 E), yaw_deg -34.4:
##   +X bears 55.6° (NE, polygonal choir apse)
##   -X bears 235.6° (SW, main Puistokatu entrance & gable)
##   +Z bears 145.6° (SE, south transept & sacristy)
##   -Z bears 325.6° (NW, north transept & iconic 77 m corner bell tower)
##
## Architectural & facade spec (counted from Wikimedia Commons / Finna refs):
## - Rough-hewn grey-granite plinth (foundation dropped to y = -2.5 m, top 2.6 m)
##   wrapping nave, transepts, choir apse, sacristy and tower, with sculpted
##   granite stepped entrance portals on the west (-X) and transept ends.
## - Red-brick Neo-Gothic / Jugend hall church: main nave 44 x 20.4 m (eaves
##   15.4 m, steep dark slate/copper-toned gable roof rising 11.8 m to 27.2 m),
##   wide crossing transepts 16 x 35 m, 8-sided polygonal choir apse (+X, r = 8 m)
##   and asymmetric SE sacristy wing.
## - Stepped red-brick gables on the west front and both transepts ornamented
##   with cream-white plastered blind tracery niches, Gothic rose windows with
##   radiating mullions, and triple pointed lancets below.
## - Stepped brick buttresses with granite weatherings framing tall pointed
##   mullioned lancet windows along nave, transepts and choir.
## - Twin cylindrical brick stair turrets with conical green-copper caps tucked
##   at the SW (-21.5, 10.6) and NE crossing (9.6, -10.8) re-entrant corners.
## - Iconic 77.0 m asymmetric NW bell tower (-17.5, -10.5, 9.4 m square):
##   granite base, tall red-brick shaft to 43.0 m with corner buttresses,
##   twin louvred gabled belfry openings, 4 clock dials at 39.8 m beneath 4
##   brick gablets, 4 octagonal brick-and-copper corner turret pinnacles,
##   and a soaring octagonal green-copper spire with lucarnes and gilt cross
##   reaching 77.0 m (matching height_m = 77.0).
## - Night illumination: warm upward floodlights (LandmarkLights.FLOOD_META)
##   on the 77 m spire, belfry, west portal and transepts + stained-glass glow.

const FOUND := -2.5
const PLINTH_Y := 2.6
const EAVE_Y := 15.4
const ROOF_RISE := 11.8
const TX := -17.5
const TZ := -10.5
const TW := 9.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#934330", 2.5))
	lm.use("BrickDark", LandmarkMaterials.pbr("brick", "#703123", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#86827B", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#ECE6D8", 3.0))
	lm.use("Copper", LandmarkFrKit.copper("#4D7E6B"))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#37403F", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#1E262C"))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#433122", 1.5))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFDFA0", 0.75))

	_build_nave_and_transepts(lm)
	_build_apse_and_sacristy(lm)
	_build_gables_and_portals(lm)
	_build_stair_turrets(lm)
	_build_bell_tower(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.92, 0.78)
	var spire_tint := Color(0.88, 0.98, 0.92)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-30.0, 1.0, -16.0), Vector3(TX, 36.0, TZ), 16.0, 1.15, 110.0, warm],
		[Vector3(-12.0, 1.0, -24.0), Vector3(TX, 58.0, TZ), 12.0, 1.05, 130.0, spire_tint],
		[Vector3(-31.0, 1.0, 5.0), Vector3(-22.0, 14.0, 0.0), 28.0, 0.95, 65.0, warm],
		[Vector3(2.0, 1.0, 26.0), Vector3(1.5, 14.0, 16.0), 30.0, 0.90, 60.0, warm],
		[Vector3(31.0, 1.0, 2.0), Vector3(22.0, 12.0, 0.0), 28.0, 0.80, 55.0, warm],
	])

static func _build_nave_and_transepts(lm: LandmarkMesh) -> void:
	# Main nave (-23..21 x -10.2..10.2).
	LandmarkFrKit.rect(lm, "Granite", -23.6, 21.4, -10.7, 10.7, FOUND, PLINTH_Y)
	LandmarkFrKit.rect(lm, "Brick", -23.0, 21.0, -10.2, 10.2, PLINTH_Y, EAVE_Y)
	LandmarkFrParts.band(lm, "BrickDark", -23.0, 21.0, -10.2, 10.2, EAVE_Y - 0.55, 0.55, 0.16)
	LandmarkFrKit.gable(lm, "Roof", -23.0, 21.0, -10.2, 10.2, EAVE_Y, ROOF_RISE, 0.65, "Brick", 1)
	LandmarkFrParts.roof_trim(lm, "Copper", -23.0, 21.0, -10.2, 10.2, EAVE_Y, ROOF_RISE, 0.65, 1, 0.34)
	# Crossing transepts (-6.5..9.5 x -17.5..17.5).
	LandmarkFrKit.rect(lm, "Granite", -7.0, 10.0, -18.0, 18.0, FOUND, PLINTH_Y)
	LandmarkFrKit.rect(lm, "Brick", -6.5, 9.5, -17.5, 17.5, PLINTH_Y, EAVE_Y)
	LandmarkFrParts.band(lm, "BrickDark", -6.5, 9.5, -17.5, 17.5, EAVE_Y - 0.55, 0.55, 0.16)
	LandmarkFrKit.gable(lm, "Roof", -6.5, 9.5, -17.5, 17.5, EAVE_Y, ROOF_RISE, 0.65, "Brick", 0)
	LandmarkFrParts.roof_trim(lm, "Copper", -6.5, 9.5, -17.5, 17.5, EAVE_Y, ROOF_RISE, 0.65, 0, 0.34)
	# Small copper ridge flèche over the crossing (x = 1.5, z = 0).
	lm.frustum("Copper", Vector3(1.5, EAVE_Y + ROOF_RISE - 0.6, 0.0), 1.05, 0.85, 3.0, 8, PI / 8.0)
	lm.lathe("Copper", Vector3(1.5, EAVE_Y + ROOF_RISE + 2.4, 0.0), PackedVector2Array([
		Vector2(1.0, 0.0), Vector2(0.10, 5.2),
	]), 8, 1.0, 1.0, PI / 8.0, false)
	LandmarkFrKit.cross(lm, "Gilt", Vector3(1.5, EAVE_Y + ROOF_RISE + 7.5, 0.0), 1.4)
	# Nave buttresses and tall pointed lancets on both sides.
	for sz: float in [-1.0, 1.0]:
		var n := Vector3(0.0, 0.0, sz)
		for x: float in [-17.5, -11.5, 14.5]:
			if sz < 0.0 and x < -10.0:
				continue
			LandmarkFrParts.opening(lm, "BrickDark", "Glass", Vector3(x, 4.4, sz * 10.2), n,
				2.3, 8.6, LandmarkFrParts.HEAD_POINTED, 0.36, 0.18, 1)
			lm.box("WarmGlow", Vector3(x, 7.8, sz * 10.22), Vector3(1.3, 4.5, 0.04), Basis(), 0.0)
		for bx: float in [-20.5, -14.5, -8.5, 11.5, 17.5]:
			if sz < 0.0 and bx < -10.0:
				continue
			LandmarkFrParts.buttress(lm, "BrickDark", Vector3(bx, PLINTH_Y, sz * 10.2), n, 1.35, 1.75, 11.6, 2)
			LandmarkFrKit.rect(lm, "Granite", bx - 0.8, bx + 0.8, sz * 10.2, sz * 12.15, FOUND, PLINTH_Y + 0.3)
		# Transept side walls (-6.5 and +9.5).
		for tx_side: float in [-6.5, 9.5]:
			var sn := Vector3(-1.0 if tx_side < 0.0 else 1.0, 0.0, 0.0)
			LandmarkFrParts.opening(lm, "BrickDark", "Glass", Vector3(tx_side, 4.8, sz * 13.8), sn,
				1.9, 7.6, LandmarkFrParts.HEAD_POINTED, 0.32, 0.15, 1)
			LandmarkFrParts.buttress(lm, "BrickDark", Vector3(tx_side, PLINTH_Y, sz * 17.2), sn, 1.2, 1.4, 11.2, 2)

static func _build_apse_and_sacristy(lm: LandmarkMesh) -> void:
	# 8-sided polygonal choir apse at +X (x = 21.0, r = 8.0 m).
	lm.lathe("Granite", Vector3(21.0, FOUND, 0.0), PackedVector2Array([
		Vector2(8.6, 0.0), Vector2(8.4, PLINTH_Y - FOUND),
	]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Brick", Vector3(21.0, PLINTH_Y, 0.0), PackedVector2Array([
		Vector2(8.0, 0.0), Vector2(8.0, 11.8),
	]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Roof", Vector3(21.0, 14.4, 0.0), PackedVector2Array([
		Vector2(8.7, 0.0), Vector2(0.25, 8.8),
	]), 8, 1.0, 1.0, PI / 8.0, false)
	# Choir lancet windows & polygonal corner buttresses around the eastern half.
	for i in range(-2, 3):
		var a := float(i) * (TAU / 8.0)
		var out := Vector3(cos(a), 0.0, sin(a))
		LandmarkFrParts.opening(lm, "BrickDark", "Glass", Vector3(21.0, 4.4, 0.0) + out * 7.45, out,
			1.75, 7.2, LandmarkFrParts.HEAD_POINTED, 0.28, 0.14, 1)
		lm.box("WarmGlow", Vector3(21.0, 7.2, 0.0) + out * 7.48, Vector3(0.95, 3.8, 0.04),
			Basis(Vector3.UP, atan2(out.x, out.z)), 0.0)
	for i in range(-2, 4):
		var ba := (float(i) - 0.5) * (TAU / 8.0)
		var bout := Vector3(cos(ba), 0.0, sin(ba))
		LandmarkFrParts.buttress(lm, "BrickDark", Vector3(21.0, PLINTH_Y, 0.0) + bout * 7.8, bout, 1.0, 1.35, 10.6, 2)
	# Asymmetric SE sacristy wing tucked between south transept and choir apse.
	LandmarkFrKit.rect(lm, "Granite", 10.0, 20.5, 7.5, 14.8, FOUND, PLINTH_Y)
	LandmarkFrKit.rect(lm, "Brick", 10.2, 20.2, 7.8, 14.4, PLINTH_Y, 8.6)
	LandmarkFrKit.gable(lm, "Roof", 10.2, 20.2, 7.8, 14.4, 8.6, 4.4, 0.45, "Brick", 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(11.6, 4.2, 14.4), Vector3(18.8, 4.2, 14.4),
		Vector3.BACK, 3, 1.3, 2.8, LandmarkFrParts.HEAD_POINTED, 0.22, 0.12)

static func _build_gables_and_portals(lm: LandmarkMesh) -> void:
	# Stepped brick gables with white blind tracery niches on both transepts (+Z, -Z) and west (-X).
	for sz: float in [-1.0, 1.0]:
		var n := Vector3(0.0, 0.0, sz)
		var gz := sz * 17.5
		_stepped_gable_parapet(lm, Vector3(1.5, EAVE_Y, gz), Vector3.RIGHT, n, 16.2, ROOF_RISE, 7)
		LandmarkFrParts.gable_niches(lm, "Trim", Vector3(1.5, EAVE_Y + 0.4, gz + sz * 0.04), n, 13.5, ROOF_RISE - 0.8, 7)
		# Large transept rose window with white trim ring & radiating mullions.
		_rose_window(lm, Vector3(1.5, 13.4, gz), n, 2.55)
		# Triple pointed lancets beneath the rose window.
		for k in 3:
			var lx := -2.5 + 4.0 * float(k)
			LandmarkFrParts.opening(lm, "BrickDark", "Glass", Vector3(lx, 4.0, gz), n,
				1.9, 6.6, LandmarkFrParts.HEAD_POINTED, 0.30, 0.15, 1)
		# Granite transept portal with short stone steps.
		LandmarkFrKit.rect(lm, "Granite", -1.4, 4.4, gz, gz + sz * 2.2, FOUND, PLINTH_Y - 0.4)
		LandmarkFrParts.opening(lm, "Granite", "Door", Vector3(1.5, 0.6, gz + sz * 2.2), n,
			2.4, 4.2, LandmarkFrParts.HEAD_POINTED, 0.42, 0.24, 0)
	# West entrance gable (-X, Puistokatu front).
	_stepped_gable_parapet(lm, Vector3(-23.0, EAVE_Y, 0.0), Vector3.BACK, Vector3.LEFT, 20.6, ROOF_RISE, 9)
	LandmarkFrParts.gable_niches(lm, "Trim", Vector3(-23.04, EAVE_Y + 0.4, 0.0), Vector3.LEFT, 16.5, ROOF_RISE - 0.8, 7)
	_rose_window(lm, Vector3(-23.0, 13.2, 0.0), Vector3.LEFT, 2.75)
	# Monumental sculpted grey-granite west entrance porch & steps.
	LandmarkFrKit.rect(lm, "Granite", -26.8, -23.0, -4.6, 4.6, FOUND, 7.6)
	LandmarkFrKit.gable(lm, "Roof", -26.8, -23.0, -4.6, 4.6, 7.6, 3.6, 0.35, "Granite", 1)
	# Stepped granite approach stairs (-X).
	for s in 6:
		var sy := lerpf(0.35, PLINTH_Y - 0.2, float(s + 1) / 6.0)
		var sx0 := -29.2 + float(s) * 0.42
		LandmarkFrKit.rect(lm, "Granite", sx0, -26.5, -4.2, 4.2, FOUND, sy)
	LandmarkFrParts.opening(lm, "Granite", "Door", Vector3(-26.8, 0.6, 0.0), Vector3.LEFT,
		3.6, 6.2, LandmarkFrParts.HEAD_POINTED, 0.58, 0.36, 0)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-23.0, 8.6, -5.2), Vector3.LEFT,
		1.5, 4.2, LandmarkFrParts.HEAD_POINTED, 0.24, 0.14, 0)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-23.0, 8.6, 5.2), Vector3.LEFT,
		1.5, 4.2, LandmarkFrParts.HEAD_POINTED, 0.24, 0.14, 0)

static func _stepped_gable_parapet(lm: LandmarkMesh, base_c: Vector3, along: Vector3, normal: Vector3,
		w: float, rise: float, steps: int) -> void:
	var a := along.normalized()
	var n := normal.normalized()
	var b := Basis(a, Vector3.UP, n)
	var half_steps := steps / 2
	for i in range(-half_steps, half_steps + 1):
		var frac := absf(float(i)) / float(maxi(half_steps, 1))
		var step_w := w / float(steps) + 0.12
		var step_h := rise * (1.0 - frac * 0.88) + 1.15
		var pos := base_c + a * (float(i) * (w / float(steps))) + n * 0.18
		lm.box("Brick", pos + Vector3(0.0, step_h * 0.5 - 0.2, 0.0), Vector3(step_w, step_h, 0.55), b, 0.0)
		lm.box("Granite", pos + Vector3(0.0, step_h - 0.12, 0.0), Vector3(step_w + 0.14, 0.22, 0.68), b, 0.0)

static func _rose_window(lm: LandmarkMesh, c: Vector3, normal: Vector3, r: float) -> void:
	var n := normal.normalized()
	var rt := Vector3.UP.cross(n).normalized()
	lm.disc("Trim", c + n * 0.06, n, r + 0.32, 20)
	lm.disc("Glass", c + n * 0.11, n, r, 20)
	lm.disc("WarmGlow", c + n * 0.12, n, r * 0.58, 16)
	# Radiating Gothic stone mullions.
	for k in 8:
		var ang := TAU * float(k) / 8.0
		var dir := rt * cos(ang) + Vector3.UP * sin(ang)
		lm.beam("Trim", c + n * 0.14, c + dir * r + n * 0.14, 0.11, 0.10, n)
	lm.disc("Trim", c + n * 0.16, n, r * 0.24, 12)

static func _build_stair_turrets(lm: LandmarkMesh) -> void:
	# Two circular brick stair turrets with conical green-copper caps.
	var turrets := [
		[Vector2(-21.8, 10.6), 2.3, 18.2, 7.6],
		[Vector2(9.6, -10.8), 2.1, 17.4, 6.8],
	]
	for t: Array in turrets:
		var pos: Vector2 = t[0]
		var r: float = t[1]
		var top_y: float = t[2]
		var cap_h: float = t[3]
		lm.frustum("Granite", Vector3(pos.x, FOUND, pos.y), r + 0.35, r + 0.25, PLINTH_Y - FOUND + 0.6, 14)
		lm.frustum("Brick", Vector3(pos.x, PLINTH_Y + 0.6, pos.y), r, r * 0.96, top_y - PLINTH_Y - 0.6, 14)
		lm.frustum("BrickDark", Vector3(pos.x, top_y - 0.55, pos.y), r + 0.18, r + 0.24, 0.55, 14)
		lm.lathe("Copper", Vector3(pos.x, top_y, pos.y), PackedVector2Array([
			Vector2(r + 0.35, 0.0), Vector2(r * 0.65, cap_h * 0.28), Vector2(0.08, cap_h),
		]), 14, 1.0, 1.0, 0.0, false)
		lm.beam("Gilt", Vector3(pos.x, top_y + cap_h - 0.1, pos.y), Vector3(pos.x, top_y + cap_h + 1.1, pos.y), 0.07, 0.07)
		# Small spiral-stair slit windows.
		for k in 4:
			var a := float(k) * 1.15
			var wn := Vector3(cos(a), 0.0, sin(a))
			LandmarkFrParts.opening(lm, "Granite", "Glass", Vector3(pos.x, 5.2 + float(k) * 2.7, pos.y) + wn * r,
				wn, 0.55, 1.4, LandmarkFrParts.HEAD_POINTED, 0.14, 0.08)

static func _build_bell_tower(lm: LandmarkMesh) -> void:
	var hw := TW * 0.5
	# Heavy rough-granite tower base (y = FOUND..4.2 m).
	LandmarkFrKit.rect(lm, "Granite", TX - hw - 0.45, TX + hw + 0.45, TZ - hw - 0.45, TZ + hw + 0.45, FOUND, 4.2)
	# Main red-brick shaft (y = 4.2..43.0 m) with subtle corner buttresses.
	LandmarkFrKit.rect(lm, "Brick", TX - hw, TX + hw, TZ - hw, TZ + hw, 4.2, 43.0)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var cx := TX + sx * (hw - 0.1)
			var cz := TZ + sz * (hw - 0.1)
			LandmarkFrKit.rect(lm, "BrickDark", cx - 0.85, cx + 0.85, cz - 0.85, cz + 0.85, 4.2, 41.5)
	# Corbelled string courses at 24.5 m and 38.2 m.
	LandmarkFrParts.band(lm, "Granite", TX - hw, TX + hw, TZ - hw, TZ + hw, 15.2, 0.5, 0.22)
	LandmarkFrParts.band(lm, "BrickDark", TX - hw, TX + hw, TZ - hw, TZ + hw, 28.5, 0.65, 0.22)
	LandmarkFrParts.band(lm, "Trim", TX - hw, TX + hw, TZ - hw, TZ + hw, 38.2, 0.55, 0.18)
	# Four faces: lower lancets, twin louvred belfry arches, clock dials, and brick gablets.
	for f in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rot * Vector3(0.0, 0.0, 1.0)
		var rt: Vector3 = rot * Vector3(1.0, 0.0, 0.0)
		var fc := Vector3(TX, 0.0, TZ) + fn * hw
		# Lower paired narrow lancets with white blind recess strips.
		for s: float in [-1.45, 1.45]:
			LandmarkFrParts.opening(lm, "BrickDark", "Glass", fc + rt * s + Vector3(0.0, 17.5, 0.0), fn,
				1.15, 6.2, LandmarkFrParts.HEAD_POINTED, 0.24, 0.14)
		# Twin pointed louvred belfry openings (y = 29.8..37.2 m).
		for s: float in [-1.65, 1.65]:
			var bc := fc + rt * s + Vector3(0.0, 29.8, 0.0)
			LandmarkFrParts.opening(lm, "Trim", "Glass", bc, fn, 1.9, 7.2, LandmarkFrParts.HEAD_POINTED, 0.28, 0.16)
			LandmarkFrParts.louvre(lm, "Copper", bc + Vector3(0.0, 0.4, 0.0), fn, 1.65, 5.2, 8)
		# Tall brick transition gablet framing the clock dial (y = 39.0..46.8 m).
		LandmarkFrParts.gable_wall(lm, "Brick", fc + Vector3(0.0, 41.8, 0.0), rt, fn, TW - 1.8, 5.2, 0.65)
		lm.beam("Granite", fc - rt * (hw - 0.9) + Vector3(0.0, 41.8, 0.0) + fn * 0.12,
			fc + Vector3(0.0, 47.0, 0.0) + fn * 0.12, 0.28, 0.28, fn)
		lm.beam("Granite", fc + rt * (hw - 0.9) + Vector3(0.0, 41.8, 0.0) + fn * 0.12,
			fc + Vector3(0.0, 47.0, 0.0) + fn * 0.12, 0.28, 0.28, fn)
	# Four clock dials at y = 40.6 m (dark dial with gilt centre/hands).
	LandmarkFrKit.clocks(lm, "Trim", "Glass", TX, TZ, hw + 0.04, 40.6, 1.55)
	for f in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rot * Vector3(0.0, 0.0, 1.0)
		var rt: Vector3 = rot * Vector3(1.0, 0.0, 0.0)
		var cc := Vector3(TX, 40.6, TZ) + fn * (hw + 0.16)
		lm.beam("Gilt", cc, cc + Vector3(0.0, 1.05, 0.0), 0.11, 0.08, fn)
		lm.beam("Gilt", cc, cc + rt * 0.78, 0.11, 0.08, fn)
	# Four octagonal corner turret pinnacles around the spire base (y = 39.5..53.5 m).
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var px := TX + sx * (hw - 0.55)
			var pz := TZ + sz * (hw - 0.55)
			lm.frustum("Brick", Vector3(px, 39.5, pz), 1.32, 1.18, 6.8, 8, PI / 8.0)
			lm.frustum("Trim", Vector3(px, 46.1, pz), 1.30, 1.36, 0.45, 8, PI / 8.0)
			lm.lathe("Copper", Vector3(px, 46.5, pz), PackedVector2Array([
				Vector2(1.38, 0.0), Vector2(0.85, 2.2), Vector2(0.07, 7.0),
			]), 8, 1.0, 1.0, PI / 8.0, false)
			lm.beam("Gilt", Vector3(px, 53.4, pz), Vector3(px, 54.4, pz), 0.07, 0.07)
	# Tall octagonal green-copper spire rising from 42.5 m to 74.6 m.
	lm.lathe("Copper", Vector3(TX, 42.5, TZ), PackedVector2Array([
		Vector2(4.75, 0.0), Vector2(4.10, 3.8), Vector2(3.10, 10.0),
		Vector2(2.00, 18.5), Vector2(0.95, 26.5), Vector2(0.22, 32.1),
	]), 8, 1.0, 1.0, PI / 8.0, false)
	# Four small gabled copper lucarne dormers midway up the spire (y = 54.0 m).
	for f in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rot * Vector3(0.0, 0.0, 1.0)
		var lc := Vector3(TX, 54.0, TZ) + fn * 2.55
		lm.box("Copper", lc + Vector3(0.0, 1.1, 0.0), Vector3(1.1, 2.2, 1.2), rot, 0.0)
		lm.spire("Copper", lc + Vector3(0.0, 2.2, 0.0) + fn * 0.2, 0.62, 1.9, 0.0, 4)
	# Gilt orb and cross crowning the 77.0 m spire.
	lm.lathe("Gilt", Vector3(TX, 74.5, TZ), LandmarkFrKit.ball(0.36), 10)
	LandmarkFrKit.cross(lm, "Gilt", Vector3(TX, 75.15, TZ), 1.85)
