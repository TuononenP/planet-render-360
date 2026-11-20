class_name FtCrichtonVulcanCrane
extends RefCounted

## Aurajoki Harbour Crane (Nosturi Numero 37, Crichton-Vulcan / Wärtsilä
## shipyard preserved portal jib crane) at Telakkaranta / Aura mouth in true
## metres (skyline: true, +X boom outreach toward Aurajoki, turned by
## yaw_deg = -34.0°):
##   - Location: 60.435750, 22.238350, published height ~38.0 m.
##   - Four-legged splayed steel portal gantry straddling quay crane rails
##     (10.5 x 10.5 m base, portal arch clearance 8.2 m, slew-ring deck at
##     13.2 m) with diagonal portal bracing and steel access ladder.
##   - Circular slewing ring, corrugated industrial blue-grey machinery house
##     with rear concrete/steel counterweight block, and cantilevered glazed
##     operator's cab overhanging the river side with warm interior glow.
##   - Tall raked steel-lattice A-frame apex pylon (y = 17.5..27.5 m) and
##     30 m raked steel-lattice luffing jib boom rising to 38.0 m with wire-
##     rope luffing cables, pulley sheaves, and suspended hook block.
##   - Dramatic architectural night accent lighting (warm amber/gold portal
##     and jib floodlights + glowing operator cab + red aviation warning halo
##     at the 38 m jib head via HALO_META).
## Surfaces: 8 merged PBR parts (SteelBlue, SteelDark, Concrete, CabPanel,
## Glass, Cable, Lamp, Beacon).

const FOUND := -1.8
const TOP_M := 38.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_portal_gantry(lm)
	_build_machinery_house_and_cab(lm)
	_build_lattice_jib_and_cables(lm)
	lm.commit(model)
	_set_night_lights(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("SteelBlue", LandmarkMaterials.paint("#4B6374", 0.45, 0.62))
	lm.use("SteelDark", LandmarkMaterials.paint("#2C343C", 0.48, 0.68))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#928F88", 2.6))
	lm.use("CabPanel", LandmarkMaterials.paint("#6A7F8D", 0.42, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#223646"))
	lm.use("Cable", LandmarkMaterials.paint("#1E2226", 0.40, 0.75))
	lm.use("Lamp", LandmarkMaterials.lit("#FFCE76", 1.8))
	lm.use("Beacon", LandmarkMaterials.lit("#FF2618", 2.2))

static func _build_portal_gantry(lm: LandmarkMesh) -> void:
	# Quay crane rail bogie tracks & concrete rail sleepers.
	for sz: float in [-5.4, 5.4]:
		LandmarkFrKit.rect(lm, "Concrete", -9.0, 9.0, sz - 0.65, sz + 0.65, FOUND, 0.22)
		lm.beam("SteelDark", Vector3(-9.0, 0.28, sz), Vector3(9.0, 0.28, sz), 0.18, 0.16)
	# Four splayed steel box-girder portal legs rising from (±5.2, ±5.4) to slew deck (±2.8, ±2.8) at y = 13.0 m.
	var corners := [[-1.0, -1.0], [1.0, -1.0], [1.0, 1.0], [-1.0, 1.0]]
	for c in corners:
		var sx: float = c[0]
		var sz: float = c[1]
		var foot := Vector3(5.2 * sx, 0.35, 5.4 * sz)
		var knee := Vector3(4.3 * sx, 6.2, 4.4 * sz)
		var top := Vector3(2.8 * sx, 13.0, 2.8 * sz)
		# Wheeled bogie truck at rail foot.
		lm.box("SteelDark", Vector3(5.2 * sx, 0.85, 5.4 * sz), Vector3(2.8, 0.95, 1.0))
		lm.beam("SteelBlue", foot, knee, 0.85, 0.85)
		lm.beam("SteelBlue", knee, top, 0.72, 0.72)
	# Portal cross-girders at knee height (8.4 m clearance) and top slew platform (13.0 m).
	for i in 4:
		var c0: Array = corners[i]
		var c1: Array = corners[(i + 1) % 4]
		var k0 := Vector3(4.3 * float(c0[0]), 7.8, 4.4 * float(c0[1]))
		var k1 := Vector3(4.3 * float(c1[0]), 7.8, 4.4 * float(c1[1]))
		var t0 := Vector3(2.8 * float(c0[0]), 12.8, 2.8 * float(c0[1]))
		var t1 := Vector3(2.8 * float(c1[0]), 12.8, 2.8 * float(c1[1]))
		lm.beam("SteelBlue", k0, k1, 0.65, 0.85)
		lm.beam("SteelBlue", t0, t1, 0.60, 0.75)
		# Diagonal knee gusset struts.
		lm.beam("SteelDark", k0, t1, 0.26, 0.26)
		lm.beam("SteelDark", k1, t0, 0.26, 0.26)
	# Circular slewing pedestal drum & walkway deck (y = 12.8..15.2 m).
	LandmarkFrKit.rect(lm, "SteelDark", -3.4, 3.4, -3.4, 3.4, 12.7, 13.3)
	lm.frustum("SteelDark", Vector3(0.0, 13.3, 0.0), 2.55, 2.55, 1.8, 20)

static func _build_machinery_house_and_cab(lm: LandmarkMesh) -> void:
	# Slewing machinery house (x = -5.6..2.8, z = -2.4..2.4, y = 15.1..19.2 m).
	LandmarkFrKit.rect(lm, "CabPanel", -5.6, 2.8, -2.4, 2.4, 15.1, 19.2)
	LandmarkFrKit.rect(lm, "SteelDark", -5.8, 3.0, -2.55, 2.55, 19.1, 19.45)
	# Heavy rear counterweight block (-X = -6.8..-5.4).
	LandmarkFrKit.rect(lm, "Concrete", -6.8, -5.4, -2.2, 2.2, 15.2, 18.8)
	# Cantilevered forward glazed operator's cab (+X = 2.8..5.6, y = 15.6..18.8) with warm interior glow.
	LandmarkFrKit.rect(lm, "CabPanel", 2.8, 5.4, -1.65, 1.65, 15.6, 16.5)
	LandmarkFrKit.rect(lm, "Glass", 2.8, 5.5, -1.6, 1.6, 16.5, 18.45)
	LandmarkFrKit.rect(lm, "Lamp", 3.3, 5.0, -1.2, 1.2, 16.7, 18.2)
	LandmarkFrKit.rect(lm, "SteelDark", 2.7, 5.7, -1.75, 1.75, 18.45, 18.85)
	# Raked A-frame steel apex tower rising above the machinery house to 26.8 m.
	var apex_l := Vector3(-1.2, 26.8, -1.1)
	var apex_r := Vector3(-1.2, 26.8, 1.1)
	lm.beam("SteelBlue", Vector3(1.8, 19.2, -1.9), apex_l, 0.36, 0.36)
	lm.beam("SteelBlue", Vector3(1.8, 19.2, 1.9), apex_r, 0.36, 0.36)
	lm.beam("SteelBlue", Vector3(-4.8, 19.2, -1.9), apex_l, 0.36, 0.36)
	lm.beam("SteelBlue", Vector3(-4.8, 19.2, 1.9), apex_r, 0.36, 0.36)
	lm.beam("SteelDark", apex_l, apex_r, 0.40, 0.40)

static func _build_lattice_jib_and_cables(lm: LandmarkMesh) -> void:
	# 28 m raked steel-lattice luffing jib boom extending +X from pivot (2.4, 17.6) to head (22.0, 38.0).
	var j0 := Vector3(2.4, 17.6, 0.0)
	var j1 := Vector3(22.0, TOP_M - 0.35, 0.0)
	var segs := 10
	var dir := (j1 - j0).normalized()
	var up_n := Vector3(-dir.y, dir.x, 0.0).normalized()
	var prev_pts: Array = []
	for i in segs + 1:
		var t := float(i) / float(segs)
		var c := j0.lerp(j1, t)
		var hw := lerpf(1.25, 0.45, t)
		var hd := lerpf(1.15, 0.42, t)
		var pts := [
			c + up_n * hd + Vector3(0, 0, -hw),
			c + up_n * hd + Vector3(0, 0, hw),
			c - up_n * hd + Vector3(0, 0, hw),
			c - up_n * hd + Vector3(0, 0, -hw),
		]
		if i > 0:
			for k in 4:
				var kn := (k + 1) % 4
				# Main 4 corner chord angles of the lattice jib.
				lm.beam("SteelBlue", prev_pts[k], pts[k], 0.18, 0.18)
				# Diagonal lattice lacing on all 4 faces.
				lm.beam("SteelDark", prev_pts[k], pts[kn], 0.09, 0.09)
				lm.beam("SteelDark", pts[k], pts[kn], 0.10, 0.10)
		prev_pts = pts
	# Sheave head pulley wheel & red aviation warning lamp at 38.0 m jib tip.
	lm.disc("SteelDark", j1, Vector3(0, 0, 1), 0.72, 12)
	lm.box("Beacon", Vector3(j1.x, TOP_M, 0.0), Vector3(0.45, 0.45, 0.45))
	# Wire-rope luffing cables from A-frame apex to jib head & suspended crane hook block.
	lm.beam("Cable", Vector3(-1.2, 26.8, -1.0), j1 + Vector3(0, 0, -0.4), 0.07, 0.07)
	lm.beam("Cable", Vector3(-1.2, 26.8, 1.0), j1 + Vector3(0, 0, 0.4), 0.07, 0.07)
	lm.beam("Cable", Vector3(-5.2, 19.0, 0.0), Vector3(-1.2, 26.8, 0.0), 0.08, 0.08)
	# Hoist cable dropping vertically from jib tip to weighted hook block at y = 16.0 m.
	lm.beam("Cable", j1, Vector3(j1.x, 16.5, 0.0), 0.07, 0.07)
	lm.box("SteelDark", Vector3(j1.x, 15.8, 0.0), Vector3(0.85, 1.35, 0.65))
	# Architectural amber accent lighting strip along portal underside.
	LandmarkFrKit.rect(lm, "Lamp", -2.2, 2.2, -2.2, 2.2, 12.55, 12.72)

static func _set_night_lights(model: Node3D) -> void:
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(22.0, TOP_M + 0.15, 0.0), 2.8, Color(1.0, 0.12, 0.06)],
	])
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-6.0, 1.5, 8.0), Vector3(0.0, 15.0, 0.0), 54.0, 0.85, 38.0, Color(1.0, 0.78, 0.42)],
		[Vector3(8.0, 1.5, -8.0), Vector3(8.0, 24.0, 0.0), 56.0, 0.85, 44.0, Color(1.0, 0.78, 0.42)],
		[Vector3(2.0, 19.5, 0.0), Vector3(18.0, 34.0, 0.0), 48.0, 0.80, 34.0, Color(1.0, 0.84, 0.52)],
	])
