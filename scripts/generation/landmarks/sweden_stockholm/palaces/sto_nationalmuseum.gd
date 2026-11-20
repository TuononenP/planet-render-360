extends RefCounted

## Nationalmuseum (Friedrich August Stüler, 1866), Blasieholmen. Origin at the
## OSM footprint centre (way 24968329, 62 x 80 m), long axis local Z. The
## registry yaw (-39.1) turns local +X onto bearing 50.9 deg, so the FRONT on
## Strömkajen, facing the Royal Palace to the south-west, is the long -X
## face; local +Z is toward the Skeppsholmsbron end.
##
## From the photos (front, aerial in visual-plan/refs/landmarks/
## nationalmuseum_stockholm/; the sources doc's "limestone" is wrong, the walls
## are brick-red banded with pale sandstone courses):
## - Three storeys on a 1.2 m granite plinth: ground 8.0 m with plain
##   round-arched windows, a piano nobile to 16.2 m with tall round-arched
##   windows in sandstone surrounds, and a top storey with paired small arched
##   windows under a frieze of roundels and diamonds; cornice at 22.5 m.
## - Walls banded: terracotta-red brick between 0.3 m sandstone courses
##   every 1.4 m (drawn as thin proud bands).
## - Front: 80 m long, two 22 m wings of four bays, a 23 m central risalit
##   (3-arch portal on slender columns with a stair; above it six pairs of
##   arched windows with medallions between them; corner statues; a
##   cornice at 27.5 m, a roundel frieze and the gilt NATIONALMUSEUM lettering
##   on the glazed lantern block above) and two corner pavilions with
##   triple arched windows. The back and ends repeat the wing rhythm.
## - Dark brown low hipped roofs, green copper lantern pyramid over the
##   risalit (top 33.5 m, the registry height), glazed court roofs and small
##   green lanterns on the main roof.
## Window and bay counts are read from the photos; the courts are not
## modelled below the roof.

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")

const GX := 31.0
const GZ := 40.0
const PLINTH := 1.2
const STOREY1 := 8.0
const STOREY2 := 16.2
const EAVE := 22.5
const RISALIT_HW := 11.5
const RISALIT_X := -33.5
const PAV_W := 6.5
const BAY := 5.5
const TOP := 33.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("brick", "#C28A5F", 3.0))
	lm.use("Band", LandmarkMaterials.pbr("limestone", "#DDBC90", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DDC39F", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B2A596", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#3F3633", 3.0, 0.6, 0.35))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#7DA08D", 2.0, 0.55, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3238"))
	lm.use("Gilt", LandmarkMaterials.gold())
	_mass(lm)
	_front(lm)
	_ends_and_back(lm)
	_roofs(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-62.0, 1.5, -24.0), Vector3(-31.0, 12.0, -15.0), 45.0, 0.9, 60.0, warm],
		[Vector3(-62.0, 1.5, 24.0), Vector3(-31.0, 12.0, 15.0), 45.0, 0.9, 60.0, warm],
		[Vector3(-64.0, 1.5, 0.0), Vector3(-33.0, 20.0, 0.0), 40.0, 0.9, 66.0, warm],
		[Vector3(0.0, 1.5, 64.0), Vector3(0.0, 12.0, GZ), 50.0, 0.6, 50.0, warm],
	])

# --- Massing -----------------------------------------------------------

static func _mass(lm: LandmarkMesh) -> void:
	K.rb(lm, "Granite", -GX - 0.5, GX + 0.5, 0.0, PLINTH, -GZ - 0.5, GZ + 0.5)
	K.rb(lm, "Wall", -GX, GX, 0.0, EAVE, -GZ, GZ)
	# Corner pavilions, risalit and the lantern block over it.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cx: float = float(sx) * (GX - PAV_W * 0.5 + 0.4)
			var cz: float = float(sz) * (GZ - PAV_W * 0.5 + 0.4)
			K.rb(lm, "Wall", cx - PAV_W * 0.5, cx + PAV_W * 0.5, 0.0, EAVE + 0.4, cz - PAV_W * 0.5, cz + PAV_W * 0.5)
	K.rb(lm, "Wall", RISALIT_X, -GX + 1.0, 0.0, 27.5, -RISALIT_HW, RISALIT_HW)
	K.rb(lm, "Wall", -29.0, -16.0, 27.5, 31.5, -RISALIT_HW - 1.0, RISALIT_HW + 1.0)
	# Sandstone courses on every wall, and the storey cornices.
	for f in [[Vector3(-GX - 0.0, 0, 0), Vector3(-1, 0, 0), 2.0 * GZ], [Vector3(GX, 0, 0), Vector3(1, 0, 0), 2.0 * GZ],
			[Vector3(0, 0, -GZ), Vector3(0, 0, -1), 2.0 * GX], [Vector3(0, 0, GZ), Vector3(0, 0, 1), 2.0 * GX]]:
		var out: Vector3 = f[1]
		K.courses(lm, "Band", f[0], out, float(f[2]), PLINTH, EAVE - 1.0, 1.4, 0.3, 0.03)
		LandmarkDetail.cornice(lm, "Stone", f[0] - K.right(out) * float(f[2]) * 0.5 + Vector3(0, EAVE - 1.3, 0) + out * 0.35,
			f[0] + K.right(out) * float(f[2]) * 0.5 + Vector3(0, EAVE - 1.3, 0) + out * 0.35, out, 1.3, true)
	for y in [STOREY1 - 0.2, STOREY2 - 0.2]:
		K.rb(lm, "Stone", -GX - 0.15, GX + 0.15, float(y), float(y) + 0.4, -GZ - 0.15, GZ + 0.15, 0.0)

# --- Front -------------------------------------------------------------

## One wing bay: ground arched window, piano-nobile arched window with a
## surround, a pair of small arched windows under the frieze.
static func _bay(lm: LandmarkMesh, p: Vector3, out: Vector3, offs: Array) -> void:
	K.wins(lm, "Stone", "Glass", p, out, offs, 2.0, 1.7, 3.6, true, 0.25)
	K.wins(lm, "Stone", "Glass", p, out, offs, 9.6, 2.1, 4.4, true, 0.3)
	var pair: Array = []
	for t in offs:
		pair.append(float(t) - 0.75)
		pair.append(float(t) + 0.75)
	K.wins(lm, "Stone", "Glass", p, out, pair, 17.4, 0.95, 2.0, true, 0.2)

static func _front(lm: LandmarkMesh) -> void:
	var out := Vector3(-1, 0, 0)
	var wing: Array = []
	for k in 4:
		wing.append(RISALIT_HW + BAY * 0.5 + BAY * float(k))
	var left: Array = wing.map(func(v: float) -> float: return -v)
	_bay(lm, Vector3(-GX, 0, 0), out, wing + left)
	# Corner pavilions: ground window, triple arched windows above.
	for s in [-1.0, 1.0]:
		var zc: float = float(s) * (GZ - PAV_W * 0.5 + 0.4)
		var p := Vector3(-GX - 0.4 + 0.0, 0, zc)
		K.wins(lm, "Stone", "Glass", p, out, [0.0], 2.0, 1.7, 3.6, true, 0.25)
		K.wins(lm, "Stone", "Glass", p, out, [-1.7, 0.0, 1.7], 9.6, 1.2, 4.4, true, 0.25)
		K.wins(lm, "Stone", "Glass", p, out, [-1.7, 0.0, 1.7], 17.4, 1.0, 2.3, true, 0.2)
		var sz: float = float(s)
		K.rb(lm, "Stone", -GX - 0.55, -GX - 0.4, 0.0, EAVE + 0.4, sz * GZ - 0.5, sz * GZ + 0.5, 0.0)
	# Risalit: portal arches on slender columns, stair, paired windows with
	# medallions, corner statues, cornice, frieze and the lantern lettering.
	var rx := RISALIT_X
	var bays := [-7.2, 0.0, 7.2]
	K.wins(lm, "Stone", "Glass", Vector3(rx, 0, 0), out, bays, PLINTH + 0.4, 4.6, 5.6, true, 0.35)
	for z in [-10.8, -3.6, 3.6, 10.8]:
		LandmarkDetail.column(lm, "Stone", Vector3(rx - 0.9, PLINTH, float(z)), 0.3, 5.2, "ionic", 0, 10)
		K.rb(lm, "Stone", rx - 1.2, rx - 0.6, PLINTH + 5.2, PLINTH + 5.9, float(z) - 0.5, float(z) + 0.5)
	K.rb(lm, "Stone", rx - 1.3, rx, PLINTH + 5.9, PLINTH + 6.5, -RISALIT_HW, RISALIT_HW)
	var pairs: Array = []
	for t in bays:
		pairs.append(float(t) - 1.25)
		pairs.append(float(t) + 1.25)
	K.wins(lm, "Stone", "Glass", Vector3(rx, 0, 0), out, pairs, 9.6, 1.5, 4.6, true, 0.3)
	K.wins(lm, "Stone", "Glass", Vector3(rx, 0, 0), out, pairs, 17.2, 1.2, 3.2, true, 0.25)
	for t in [-3.6, 3.6, -10.8, 10.8]:
		lm.disc("Band", Vector3(rx - 0.15, 12.0, float(t)), out, 0.55, 12)
		lm.disc("Band", Vector3(rx - 0.15, 19.4, float(t)), out, 0.55, 12)
	for s in [-1.0, 1.0]:
		K.figure(lm, "Stone", Vector3(rx - 0.4, 11.3, float(s) * (RISALIT_HW - 0.9)), 3.2)
		K.rb(lm, "Stone", rx - 0.3, rx + 0.6, PLINTH, 27.0, float(s) * (RISALIT_HW - 0.2) - 0.45, float(s) * (RISALIT_HW - 0.2) + 0.45)
	K.rb(lm, "Stone", rx - 0.1, rx, 21.3, 22.2, -RISALIT_HW, RISALIT_HW, 0.0)
	for t in K.evenly(5, 4.2):
		lm.disc("Band", Vector3(rx - 0.15, 24.2, float(t)), out, 0.6, 12)
	K.rb(lm, "Gilt", rx - 0.15, rx, 25.2, 25.6, -7.0, 7.0, 0.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(rx - 0.1, 26.1, -RISALIT_HW - 0.2), Vector3(rx - 0.1, 26.1, RISALIT_HW + 0.2), out, 1.4, true)
	LandmarkDetail.cornice(lm, "Stone", Vector3(rx - 0.1, 26.1, -RISALIT_HW - 0.2), Vector3(-GX + 1.0, 26.1, -RISALIT_HW - 0.2), Vector3(0, 0, -1), 1.4, true)
	LandmarkDetail.cornice(lm, "Stone", Vector3(rx - 0.1, 26.1, RISALIT_HW + 0.2), Vector3(-GX + 1.0, 26.1, RISALIT_HW + 0.2), Vector3(0, 0, 1), 1.4, true)
	# Lantern block lettering (NATIONALMUSEUM).
	K.rb(lm, "Gilt", -29.08, -29.0, 28.9, 29.9, -8.5, 8.5, 0.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-29.0, 30.0, -RISALIT_HW - 1.1), Vector3(-29.0, 30.0, RISALIT_HW + 1.1), out, 1.5, false)
	# Portal stair and the low quay steps.
	for k in 5:
		K.rb(lm, "Granite", rx - 1.3 - 0.45 * float(k + 1), rx - 1.3, 0.0, 0.26 * float(5 - k), -RISALIT_HW - 0.5, RISALIT_HW + 0.5, 0.0)
	K.rb(lm, "Granite", -GX - 4.6, -GX - 0.5, 0.0, 0.3, -GZ + 6.0, GZ - 6.0, 0.0)
	K.rb(lm, "Granite", -GX - 7.2, -GX - 4.6, 0.0, 0.15, -GZ + 6.0, GZ - 6.0, 0.0)

## Ends (+/-Z) and back (+X): the wing rhythm between corner pavilions.
static func _ends_and_back(lm: LandmarkMesh) -> void:
	var ends: Array = K.evenly(9, (2.0 * GX - 2.0 * PAV_W) / 9.0)
	for s in [-1.0, 1.0]:
		var sz: float = float(s)
		var out := Vector3(0, 0, sz)
		var offs: Array = ends if sz > 0.0 else ends.map(func(v: float) -> float: return -v)
		_bay(lm, Vector3(0, 0, sz * GZ), out, offs)
		# Corner pavilion faces on the end, triple windows.
		for sx in [-1.0, 1.0]:
			var xc: float = float(sx) * (GX - PAV_W * 0.5 + 0.4)
			var q := Vector3(xc, 0, sz * (GZ + 0.4))
			var tw: Array = [-1.7, 0.0, 1.7]
			K.wins(lm, "Stone", "Glass", q, out, [0.0], 2.0, 1.7, 3.6, true, 0.25)
			K.wins(lm, "Stone", "Glass", q, out, tw, 9.6, 1.2, 4.4, true, 0.25)
			K.wins(lm, "Stone", "Glass", q, out, tw, 17.4, 1.0, 2.3, true, 0.2)
	var back: Array = K.evenly(13, (2.0 * GZ - 2.0 * PAV_W) / 13.0)
	_bay(lm, Vector3(GX, 0, 0), Vector3(1, 0, 0), back)
	for s in [-1.0, 1.0]:
		var zc: float = float(s) * (GZ - PAV_W * 0.5 + 0.4)
		var q := Vector3(GX + 0.4, 0, zc)
		var tw: Array = [-1.7, 0.0, 1.7]
		K.wins(lm, "Stone", "Glass", q, Vector3(1, 0, 0), [0.0], 2.0, 1.7, 3.6, true, 0.25)
		K.wins(lm, "Stone", "Glass", q, Vector3(1, 0, 0), tw, 9.6, 1.2, 4.4, true, 0.25)
		K.wins(lm, "Stone", "Glass", q, Vector3(1, 0, 0), tw, 17.4, 1.0, 2.3, true, 0.2)
	# Side faces of the risalit (above the wing line none): the ends of the
	# pavilion cornices.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cx: float = float(sx) * (GX - PAV_W * 0.5 + 0.4)
			var cz: float = float(sz) * (GZ - PAV_W * 0.5 + 0.4)
			K.rb(lm, "Stone", cx - PAV_W * 0.5 - 0.2, cx + PAV_W * 0.5 + 0.2, EAVE - 0.3, EAVE + 0.5,
				cz - PAV_W * 0.5 - 0.2, cz + PAV_W * 0.5 + 0.2, 0.0)

# --- Roofs -------------------------------------------------------------

static func _roofs(lm: LandmarkMesh) -> void:
	LandmarkFhUtil.hip(lm, "Roof", Vector3(0, EAVE, 0), 2.0 * GX + 0.8, 2.0 * GZ + 0.8, 4.4, 0.5)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cx: float = float(sx) * (GX - PAV_W * 0.5 + 0.4)
			var cz: float = float(sz) * (GZ - PAV_W * 0.5 + 0.4)
			LandmarkFhUtil.hip(lm, "Roof", Vector3(cx, EAVE + 0.4, cz), PAV_W + 0.6, PAV_W + 0.6, 2.2, 0.3)
	# Risalit roof and the lantern block's copper pyramid (registry top).
	LandmarkFhUtil.hip(lm, "Copper", Vector3(-22.5, 31.5, 0.0), 15.0, 2.0 * RISALIT_HW + 2.6, TOP - 31.5, 0.18)
	# Glazed court roofs and small green lanterns on the main roof.
	for s in [-1.0, 1.0]:
		LandmarkFhUtil.hip(lm, "Glass", Vector3(8.0, EAVE + 3.6, float(s) * 19.0), 20.0, 14.0, 1.8, 0.5)
		LandmarkFhUtil.hip(lm, "Copper", Vector3(-8.0, EAVE + 3.6, float(s) * 24.0), 6.0, 6.0, 2.0, 0.2)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(10.0, EAVE + 3.6, 0.0), 8.0, 8.0, 2.4, 0.2)
