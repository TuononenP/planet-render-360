class_name FtOrthodoxChurch
extends RefCounted

## Turku Orthodox Church (Pyhän marttyyrikeisarinna Aleksandran kirkko,
## Carl Ludvig Engel, 1845) on the NW edge of Kauppatori.
## Origin at OSM way 26491333 centroid (60.452285 N, 22.266010 E), yaw_deg -34.8:
##   +X bears 55.2° (NE, along Yliopistonkatu / Kauppatori NW edge)
##   +Z bears 145.2° (SE, facing Kauppatori — main entrance portico)
##   -Z bears 325.2° (NW, rear rectangular altar apse)
##
## Architectural & facade spec (counted from Wikimedia Commons / Finna refs):
## - Pale Empire yellow rendered rotunda (r = 10.8 m, walls y = 1.4..10.6 m)
##   on a coursed grey-granite plinth (foundation dropped to y = -1.6 m).
## - SINGLE tetrastyle Doric portico facing Kauppatori (+Z): 5 broad granite
##   steps with cheek walls, 4 fluted Doric columns (h = 8.0 m), white
##   entablature with triglyph frieze and dentil cornice, triangular pediment
##   with yellow tympanum, recessed pronaos with arched timber-and-bronze
##   double doors and semicircular fanlight.
## - Rear rectangular altar apse (-Z, 12.0 x 5.8 m, eaves 10.0 m) with white
##   corner pilasters, cornice, arched sanctuary windows and hipped copper roof.
## - 12 engaged white pilasters and tall round-arched windows around the rotunda.
## - Flanking low Empire yellow courtyard walls along Kauppatori (-X / +X)
##   with granite base, recessed blind arches, white coping and end gate piers.
## - Cylindrical drum (r = 6.9 m, y = 11.4..17.2 m) pierced by 12 round-arched
##   windows between 12 white pilasters, crowned by a moulded cornice.
## - Green-copper hemispherical dome (y = 17.2..23.3 m) with 12 standing-seam
##   ribs, white windowed lantern (y = 23.1..24.7 m), gilded onion finial, and
##   gilt three-bar Orthodox cross peaking at 27.0 m (matching height_m = 27.0).
## - Night illumination: warm upward floodlights (LandmarkLights.FLOOD_META)
##   on the Kauppatori portico, rotunda and copper dome, plus warm drum glow.

const FOUND := -1.6
const PLINTH_Y := 1.4
const ROT_R := 10.8
const ROT_TOP := 10.6
const DRUM_R := 6.9
const DRUM_Y0 := 11.4
const DRUM_Y1 := 17.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E6C97A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F4F0E6", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F8B83", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#4A7664"))
	lm.use("Glass", LandmarkMaterials.glass("#202A32"))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#4A3624", 1.5))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE2A8", 0.85))

	_build_rotunda(lm)
	_build_portico(lm)
	_build_rear_apse(lm)
	_build_flanking_walls(lm)
	_build_drum_and_dome(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.92, 0.78)
	var dome_warm := Color(0.95, 0.96, 0.88)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-6.0, 0.8, 19.5), Vector3(0.0, 7.5, 11.5), 32.0, 1.05, 55.0, warm],
		[Vector3(6.0, 0.8, 19.5), Vector3(0.0, 7.5, 11.5), 32.0, 1.05, 55.0, warm],
		[Vector3(-12.5, 1.2, 13.5), Vector3(0.0, 19.0, 0.0), 26.0, 0.95, 65.0, dome_warm],
		[Vector3(12.5, 1.2, 13.5), Vector3(0.0, 19.0, 0.0), 26.0, 0.95, 65.0, dome_warm],
		[Vector3(0.0, 1.2, -19.0), Vector3(0.0, 14.0, -4.0), 28.0, 0.75, 55.0, warm],
	])

static func _build_rotunda(lm: LandmarkMesh) -> void:
	# Coursed granite plinth dropped below y = 0 for site seating.
	lm.frustum("Stone", Vector3(0.0, FOUND, 0.0), ROT_R + 0.55, ROT_R + 0.45, PLINTH_Y - FOUND, 28)
	lm.frustum("Trim", Vector3(0.0, PLINTH_Y - 0.16, 0.0), ROT_R + 0.52, ROT_R + 0.52, 0.22, 28)
	# Main pale Empire yellow cylindrical body.
	lm.frustum("Wall", Vector3(0.0, PLINTH_Y, 0.0), ROT_R, ROT_R, ROT_TOP - PLINTH_Y, 28)
	# Entablature: architrave, frieze band, and projecting white cornice.
	lm.frustum("Trim", Vector3(0.0, 9.65, 0.0), ROT_R + 0.18, ROT_R + 0.18, 0.30, 28)
	lm.frustum("Trim", Vector3(0.0, 10.22, 0.0), ROT_R + 0.42, ROT_R + 0.50, 0.44, 28)
	# Low-pitched green-copper skirt roof rising from rotunda rim to drum collar.
	lm.lathe("Copper", Vector3(0.0, ROT_TOP, 0.0), PackedVector2Array([
		Vector2(ROT_R + 0.55, 0.0), Vector2(DRUM_R + 0.35, 1.15), Vector2(DRUM_R + 0.10, 1.15),
	]), 28, 1.0, 1.0, 0.0, false)
	# 12 white engaged pilasters around the rotunda + arched windows on open bays
	# (skipping +Z portico bay and -Z rear apse bay).
	for i in 12:
		var a := TAU * float(i) / 12.0 + PI / 12.0
		var out := Vector3(cos(a), 0.0, sin(a))
		var b := Basis(Vector3.UP, atan2(out.x, out.z))
		var p := out * (ROT_R + 0.08)
		# Pilaster shaft, base block, and capital.
		lm.box("Trim", p + Vector3(0.0, 5.45, 0.0), Vector3(0.68, 7.9, 0.22), b, 0.0)
		lm.box("Trim", p + Vector3(0.0, PLINTH_Y + 0.22, 0.0), Vector3(0.84, 0.44, 0.30), b, 0.0)
		lm.box("Trim", p + Vector3(0.0, 9.48, 0.0), Vector3(0.88, 0.34, 0.32), b, 0.0)
		# Window centred in the bay between pilasters (skip front +Z and rear -Z).
		var wa := a + PI / 12.0
		var wn := Vector3(cos(wa), 0.0, sin(wa))
		if absf(wn.z) > 0.88:
			continue
		LandmarkFrParts.opening(lm, "Trim", "Glass", wn * ROT_R + Vector3(0.0, 3.2, 0.0), wn,
			1.55, 3.9, LandmarkFrParts.HEAD_ROUND, 0.24, 0.14, 1)
		# Subtle upper blind lunette panel above each main window.
		lm.box("Trim", wn * (ROT_R + 0.06) + Vector3(0.0, 8.2, 0.0), Vector3(1.5, 0.55, 0.10),
			Basis(Vector3.UP, atan2(wn.x, wn.z)), 0.0)

static func _build_portico(lm: LandmarkMesh) -> void:
	# SINGLE tetrastyle Doric portico facing Kauppatori (+Z).
	# Pronaos body projecting from rotunda (z = 9.2..12.2, width 9.2 m).
	LandmarkFrKit.rect(lm, "Stone", -4.85, 4.85, 9.2, 14.55, FOUND, PLINTH_Y)
	LandmarkFrKit.rect(lm, "Wall", -4.55, 4.55, 9.2, 12.15, PLINTH_Y, 9.65)
	# Corner antae pilasters framing the pronaos.
	for sx: float in [-1.0, 1.0]:
		lm.box("Trim", Vector3(sx * 4.25, 5.45, 12.2), Vector3(0.75, 8.1, 0.26), Basis(), 0.0)
		lm.box("Trim", Vector3(sx * 4.25, 9.52, 12.22), Vector3(0.92, 0.32, 0.34), Basis(), 0.0)
	# Broad 5-step granite entrance flight toward Kauppatori (z = 14.55..16.55).
	for s in 5:
		var t := float(s) / 5.0
		var y1 := lerpf(0.28, PLINTH_Y, float(s + 1) / 5.0)
		var z1 := 16.55 - t * 2.0
		LandmarkFrKit.rect(lm, "Stone", -4.85, 4.85, 14.4, z1, FOUND, y1)
	# Low granite cheek walls flanking the steps.
	for sx: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Stone", sx * 4.85 - 0.32, sx * 4.85 + 0.32, 14.4, 16.65, FOUND, 1.55)
	# Grand recessed arched entrance doorway & bronze-trimmed timber double doors.
	LandmarkFrParts.opening(lm, "Trim", "Door", Vector3(0.0, PLINTH_Y, 12.16), Vector3.BACK,
		2.5, 4.8, LandmarkFrParts.HEAD_ROUND, 0.34, 0.22, 0)
	# Semicircular fanlight glazing over door transom.
	lm.box("Trim", Vector3(0.0, PLINTH_Y + 3.55, 12.26), Vector3(2.45, 0.16, 0.14), Basis(), 0.0)
	lm.box("WarmGlow", Vector3(0.0, PLINTH_Y + 4.10, 12.22), Vector3(1.65, 0.85, 0.06), Basis(), 0.0)
	# Flanking shallow blind arched niches inside the pronaos.
	for sx: float in [-1.0, 1.0]:
		LandmarkFrParts.opening(lm, "Trim", "Wall", Vector3(sx * 2.85, PLINTH_Y + 1.0, 12.16), Vector3.BACK,
			1.15, 2.5, LandmarkFrParts.HEAD_ROUND, 0.18, 0.10, 0)
	# Four fluted Doric columns across the Kauppatori front (z = 13.95).
	for cx: float in [-3.75, -1.25, 1.25, 3.75]:
		LandmarkDetail.column(lm, "Trim", Vector3(cx, PLINTH_Y, 13.95), 0.42, 8.0, "doric", 16, 14)
	# Portico entablature (y = 9.40..10.65): architrave, triglyph frieze, cornice.
	LandmarkFrKit.rect(lm, "Trim", -4.75, 4.75, 9.4, 14.48, 9.40, 10.22)
	for tx in 9:
		var x := lerpf(-4.2, 4.2, float(tx) / 8.0)
		lm.box("Trim", Vector3(x, 9.96, 14.54), Vector3(0.32, 0.44, 0.10), Basis(), 0.0)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-4.85, 10.18, 14.48), Vector3(4.85, 10.18, 14.48),
		Vector3.BACK, 0.52, true)
	for sx: float in [-1.0, 1.0]:
		var x_side := sx * 4.75
		LandmarkDetail.cornice(lm, "Trim", Vector3(x_side, 10.18, 9.5), Vector3(x_side, 10.18, 14.48),
			Vector3(sx, 0.0, 0.0), 0.48, false)
	# Triangular classical pediment (y = 10.70..13.05) + copper portico roof behind.
	LandmarkFrKit.gable(lm, "Copper", -4.80, 4.80, 9.2, 14.55, 10.65, 2.35, 0.25, "Wall", 0)
	# White raking cornice boards framing the yellow tympanum.
	lm.beam("Trim", Vector3(-5.05, 10.62, 14.72), Vector3(0.0, 13.08, 14.72), 0.34, 0.34, Vector3.BACK)
	lm.beam("Trim", Vector3(5.05, 10.62, 14.72), Vector3(0.0, 13.08, 14.72), 0.34, 0.34, Vector3.BACK)
	lm.box("Trim", Vector3(0.0, 10.68, 14.72), Vector3(10.1, 0.22, 0.28), Basis(), 0.0)
	# Small gilt acroterion medallion in the tympanum + apex finial.
	lm.disc("Gilt", Vector3(0.0, 11.55, 14.66), Vector3.BACK, 0.48, 16)
	lm.box("Trim", Vector3(0.0, 13.32, 14.65), Vector3(0.42, 0.46, 0.32), Basis(), 0.0)

static func _build_rear_apse(lm: LandmarkMesh) -> void:
	# Rectangular rear sanctuary / altar wing on the NW side (-Z).
	var z0 := -15.3
	var z1 := -9.2
	LandmarkFrKit.rect(lm, "Stone", -6.15, 6.15, z0 - 0.25, z1, FOUND, PLINTH_Y)
	LandmarkFrKit.rect(lm, "Wall", -5.85, 5.85, z0, z1, PLINTH_Y, 9.8)
	LandmarkFrParts.corner_strips(lm, "Trim", -5.85, 5.85, z0, z1, PLINTH_Y, 9.6, 0.65, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", -5.85, 5.85, z0, z1, 9.35, 0.50)
	LandmarkFrKit.hip(lm, "Copper", -5.85, 5.85, z0, z1, 9.8, 2.3, 0.45)
	# Large central rear sanctuary window + flanking smaller arched windows.
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(0.0, 3.0, z0), Vector3.FORWARD,
		2.2, 4.3, LandmarkFrParts.HEAD_ROUND, 0.28, 0.16, 1)
	for sx: float in [-1.0, 1.0]:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(sx * 3.55, 3.4, z0), Vector3.FORWARD,
			1.25, 3.2, LandmarkFrParts.HEAD_ROUND, 0.22, 0.14, 0)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(sx * 5.85, 3.3, -12.4), Vector3(sx, 0.0, 0.0),
			1.4, 3.5, LandmarkFrParts.HEAD_ROUND, 0.22, 0.14, 1)

static func _build_flanking_walls(lm: LandmarkMesh) -> void:
	# Low Empire yellow courtyard walls & piers framing the Kauppatori frontage.
	for sx: float in [-1.0, 1.0]:
		var xa := sx * 10.2
		var xb := sx * 19.6
		var x0 := minf(xa, xb)
		var x1 := maxf(xa, xb)
		LandmarkFrKit.rect(lm, "Stone", x0, x1, 10.6, 11.45, FOUND, 0.95)
		LandmarkFrKit.rect(lm, "Wall", x0, x1, 10.7, 11.35, 0.95, 3.05)
		LandmarkFrKit.rect(lm, "Trim", x0 - 0.1, x1 + 0.1, 10.62, 11.43, 3.05, 3.28)
		# Blind arched niches facing Kauppatori.
		for k in 2:
			var nx := lerpf(x0 + 1.8, x1 - 1.8, float(k))
			LandmarkFrParts.opening(lm, "Trim", "Wall", Vector3(nx, 1.25, 11.36), Vector3.BACK,
				1.7, 1.55, LandmarkFrParts.HEAD_ROUND, 0.16, 0.08, 0)
		# End gate pier with moulded cap and spherical finial.
		var px := sx * 20.1
		LandmarkFrKit.rect(lm, "Stone", px - 0.65, px + 0.65, 10.45, 11.6, FOUND, 1.05)
		LandmarkFrKit.rect(lm, "Wall", px - 0.58, px + 0.58, 10.52, 11.53, 1.05, 3.75)
		LandmarkFrKit.rect(lm, "Trim", px - 0.68, px + 0.68, 10.42, 11.63, 3.75, 4.05)
		lm.lathe("Trim", Vector3(px, 4.05, 11.02), LandmarkFrKit.ball(0.28), 10)

static func _build_drum_and_dome(lm: LandmarkMesh) -> void:
	# Drum plinth collar and main 12-window cylindrical drum.
	lm.frustum("Trim", Vector3(0.0, DRUM_Y0 - 0.2, 0.0), DRUM_R + 0.30, DRUM_R + 0.22, 0.55, 32)
	lm.frustum("Wall", Vector3(0.0, DRUM_Y0 + 0.35, 0.0), DRUM_R, DRUM_R, DRUM_Y1 - DRUM_Y0 - 0.35, 32)
	# 12 engaged pilasters and 12 round-arched drum windows with warm interior glow.
	for i in 12:
		var a := TAU * float(i) / 12.0
		var out := Vector3(cos(a), 0.0, sin(a))
		var b := Basis(Vector3.UP, atan2(out.x, out.z))
		lm.box("Trim", out * (DRUM_R + 0.07) + Vector3(0.0, 14.3, 0.0), Vector3(0.46, 4.8, 0.16), b, 0.0)
		var wa := a + PI / 12.0
		var wn := Vector3(cos(wa), 0.0, sin(wa))
		LandmarkFrParts.opening(lm, "Trim", "Glass", wn * DRUM_R + Vector3(0.0, 12.65, 0.0), wn,
			1.18, 3.1, LandmarkFrParts.HEAD_ROUND, 0.18, 0.11, 1)
		lm.box("WarmGlow", wn * (DRUM_R - 0.02) + Vector3(0.0, 14.0, 0.0), Vector3(0.75, 2.1, 0.04),
			Basis(Vector3.UP, atan2(wn.x, wn.z)), 0.0)
	# Moulded white drum cornice.
	lm.frustum("Trim", Vector3(0.0, DRUM_Y1 - 0.55, 0.0), DRUM_R + 0.16, DRUM_R + 0.24, 0.30, 32)
	lm.frustum("Trim", Vector3(0.0, DRUM_Y1 - 0.25, 0.0), DRUM_R + 0.34, DRUM_R + 0.44, 0.38, 32)
	# Smooth hemispherical green-copper dome (y = 17.25..23.30, r = 7.15 m).
	var dome_prof := PackedVector2Array()
	for k in 13:
		var t := PI * 0.5 * float(k) / 12.0
		var r := maxf(cos(t) * 7.15, 0.95)
		var dy := sin(t) * 6.05
		dome_prof.append(Vector2(r, dy))
	lm.lathe("Copper", Vector3(0.0, 17.25, 0.0), dome_prof, 32, 1.0, 1.0, 0.0, false)
	# 12 subtle standing-seam dome ribs.
	for i in 12:
		var a := TAU * float(i) / 12.0
		var ca := cos(a)
		var sa := sin(a)
		for s in 6:
			var t0 := PI * 0.44 * float(s) / 6.0
			var t1 := PI * 0.44 * float(s + 1) / 6.0
			var p0 := Vector3(ca * cos(t0) * 7.20, 17.25 + sin(t0) * 6.05, sa * cos(t0) * 7.20)
			var p1 := Vector3(ca * cos(t1) * 7.20, 17.25 + sin(t1) * 6.05, sa * cos(t1) * 7.20)
			lm.beam("Copper", p0, p1, 0.10, 0.10)
	# Cylindrical lantern (y = 23.15..24.70) with 8 narrow arched windows.
	lm.frustum("Trim", Vector3(0.0, 23.15, 0.0), 1.32, 1.24, 0.35, 16)
	lm.frustum("Trim", Vector3(0.0, 23.48, 0.0), 1.15, 1.12, 1.15, 16)
	lm.frustum("Trim", Vector3(0.0, 24.58, 0.0), 1.28, 1.34, 0.20, 16)
	LandmarkFrParts.ring_openings(lm, "Trim", "WarmGlow", Vector3(0.0, 23.62, 0.0), 1.14, 8,
		0.32, 0.78, LandmarkFrParts.HEAD_ROUND, 0.0, 0.06)
	# Gilt onion cupola finial (y = 24.75..25.60) + three-bar Orthodox cross to 27.0 m.
	lm.lathe("Gilt", Vector3(0.0, 24.75, 0.0), PackedVector2Array([
		Vector2(0.45, 0.0), Vector2(0.72, 0.22), Vector2(0.68, 0.45),
		Vector2(0.32, 0.70), Vector2(0.10, 0.90),
	]), 14)
	# Three-bar Orthodox cross peaking at y = 27.0 m.
	lm.beam("Gilt", Vector3(0.0, 25.55, 0.0), Vector3(0.0, 27.0, 0.0), 0.11, 0.11)
	lm.beam("Gilt", Vector3(-0.28, 26.74, 0.0), Vector3(0.28, 26.74, 0.0), 0.09, 0.09)
	lm.beam("Gilt", Vector3(-0.52, 26.44, 0.0), Vector3(0.52, 26.44, 0.0), 0.10, 0.10)
	lm.beam("Gilt", Vector3(-0.28, 25.88, 0.0), Vector3(0.28, 26.06, 0.0), 0.08, 0.08)
