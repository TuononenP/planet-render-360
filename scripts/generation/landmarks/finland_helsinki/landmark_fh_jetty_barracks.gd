extends RefCounted

## Jetty Barracks (Rantakasarmi, 1800s Russian garrison), Iso Mustasaari:
## the long single-storey barracks that stands behind the main ferry
## quay. Frame: origin at the centre of the footprint (OSM way
## 117426266), long axis on X, front +Z; registry yaw 4 lays it on the
## map (+X a few degrees south of east, front to the south).
##
## What the photographs show (visual-plan/refs/landmarks/
## suomenlinna_jetty_barracks/): salmon-pink render over a granite plinth,
## one row of round-headed windows with pale arched hood moulds and sills,
## a pale string course at the eaves, a broad hipped roof of dark sheet
## metal with big chimney stacks, a round-arched carriage passage in the
## middle of the long front, and above it a square pink clock tower with
## a cornice and an iron-framed lantern. The ends carry small gabled
## pavilions.
##
## Measured from OSM: the outline (129.5 x 20.1 m: a 120.5 x 19.8 m main
## block plus a 4.5 m x 8.6 m pavilion at each end). LoD2 gives 10.4 m
## (3 m from the entry), the published figure 14 m is the lantern. Estimated
## from the photographs: eave height (5.3 m), roof pitch, tower height
## (14 m to the lantern's spike), window pitch (3.4 m) and size.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "suomenlinna_jetty_barracks", "name": "Suomenlinna Jetty Barracks", "lat": 60.148815, "lon": 24.98518,
	"radius_m": 4500.0, "wiki_title": "Suomenlinna", "height_m": 15.7, "clear_m": 5.0,
	"clear_rect_m": [0.0, 0.0, 64.8, 10.0],
	"yaw_deg": 4.0, "kind": "Barracks",
	"aliases": ["suomenlinna jetty barracks", "rantakasarmi suomenlinna", "jetty barracks helsinki"]}

## Main block half length and half depth, eave and plinth heights.
const HL := 60.3
const HD := 9.9
const EAVE := 5.3
const PLINTH := 0.7
const RISE := 3.6
## The arch and tower sit slightly west of the middle.
const AX := -0.4
const PITCH := 3.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D79A8D", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E9DCC8", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8C847C", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#3C3F42", 0.55, 0.45))
	lm.use("Window", LandmarkMaterials.glass("#2B3640"))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#7A5B4F", 2.5))
	lm.use("Iron", LandmarkMaterials.paint("#24272A", 0.5, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE7B0", 0.9))
	lm.use("Cobble", LandmarkMaterials.pbr("gravel", "#9C9487", 2.5))
	lm.box("Cobble", Vector3(0, 0.03, 0), Vector3(142.0, 0.06, 34.0))
	_block(lm)
	_ends(lm)
	_windows(lm)
	_roof(lm)
	_arch_and_tower(lm)
	_chimneys(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-34.0, 0.8, 15.0), Vector3(-34.0, 5.0, 9.9), 55.0, 0.8, 38.0, Color(1.0, 0.86, 0.66)],
		[Vector3(34.0, 0.8, 15.0), Vector3(34.0, 5.0, 9.9), 55.0, 0.8, 38.0, Color(1.0, 0.86, 0.66)],
		[Vector3(AX, 1.0, 16.0), Vector3(AX, 10.0, 2.6), 28.0, 0.9, 40.0, Color(1.0, 0.86, 0.66)]])
	model.set_meta(LandmarkLights.HALO_META, [[Vector3(AX, 12.6, 0.0), 2.6, Color(1.0, 0.9, 0.65)]])

static func _block(lm: LandmarkMesh) -> void:
	U.blk(lm, "Granite", 0.0, 0.0, 0.0, 2.0 * HL + 0.4, PLINTH, 2.0 * HD + 0.4)
	U.blk(lm, "Wall", 0.0, PLINTH, 0.0, 2.0 * HL, EAVE - PLINTH, 2.0 * HD)
	# String courses: eave band and a sill band.
	U.blk(lm, "Trim", 0.0, EAVE - 0.45, 0.0, 2.0 * HL + 0.5, 0.45, 2.0 * HD + 0.5)
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(0.0, 1.35, s * (HD + 0.04)), Vector3(2.0 * HL, 0.14, 0.1))

## The end pavilions: a gabled projection each end, a round attic window.
static func _ends(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var cx: float = s * (HL + 2.2)
		U.blk(lm, "Granite", cx, 0.0, 2.3, 4.7, PLINTH, 8.8)
		U.blk(lm, "Wall", cx, PLINTH, 2.3, 4.5, EAVE - PLINTH, 8.6)
		U.blk(lm, "Trim", cx, EAVE - 0.45, 2.3, 4.9, 0.45, 9.0)
		U.ridge_z(lm, "Roof", "Wall", Vector3(cx, EAVE, 2.3), 4.5, 8.6, 2.8, 0.35)
		var out := Vector3(s, 0, 0)
		FhP.win_row(lm, "Trim", "Window", Vector3(cx + s * 2.26, 0, 0.4), Vector3(cx + s * 2.26, 0, 4.2), out, 1.5, 2, 1.2, 2.2, true, 0.12)
		lm.disc("Window", Vector3(cx + s * 2.26, EAVE + 1.2, 2.3), out, 0.5, 14)

## One row of round-headed windows on both long faces, skipping the
## carriage arch bay, and a hood-moulded arch over each.
static func _windows(lm: LandmarkMesh) -> void:
	var n := int((2.0 * HL - 3.0) / PITCH)
	for s in [-1.0, 1.0]:
		var out := Vector3(0, 0, s)
		for i in n:
			var x := -HL + 1.7 + float(i) * PITCH
			if absf(x - AX) < 3.0:
				continue
			FhP.win_row(lm, "Trim", "Window", Vector3(x, 0, s * HD), Vector3(x, 0, s * HD), out, 1.5, 1, 1.25, 2.35, true, 0.14)

## Hipped roof: two slopes and two hipped ends, overhanging 0.5 m.
static func _roof(lm: LandmarkMesh) -> void:
	var ov := 0.55
	var hx := HL + ov
	var hz := HD + ov
	var y0 := EAVE
	var y1 := EAVE + RISE
	# Ridge runs from -(HL - HD + 0.6) to +(HL - HD + 0.6).
	var rx := HL - HD + 0.6
	lm.quad("Roof", Vector3(-hx, y0, hz), Vector3(hx, y0, hz), Vector3(rx, y1, 0.3), Vector3(-rx, y1, 0.3),
		Vector3(0, hz, RISE).normalized())
	lm.quad("Roof", Vector3(hx, y0, -hz), Vector3(-hx, y0, -hz), Vector3(-rx, y1, -0.3), Vector3(rx, y1, -0.3),
		Vector3(0, hz, -RISE).normalized())
	lm.quad("Roof", Vector3(hx, y0, hz), Vector3(hx, y0, -hz), Vector3(rx, y1, -0.3), Vector3(rx, y1, 0.3),
		Vector3(RISE, hz, 0).normalized())
	lm.quad("Roof", Vector3(-hx, y0, -hz), Vector3(-hx, y0, hz), Vector3(-rx, y1, 0.3), Vector3(-rx, y1, -0.3),
		Vector3(-RISE, hz, 0).normalized())
	# Ridge cap.
	lm.beam("Roof", Vector3(-rx, y1 + 0.05, 0), Vector3(rx, y1 + 0.05, 0), 0.5, 0.2)

## The carriage arch on both long faces and the clock tower over it.
static func _arch_and_tower(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var out := Vector3(0, 0, s)
		var z: float = s * (HD + 0.05)
		U.blk(lm, "Granite", AX, 0.0, s * (HD * 0.5), 5.6, 0.1, HD)
		U.opening(lm, "Window", Vector3(AX, 0.1, z), out, 3.6, 4.0, true)
		LandmarkDetail.arch(lm, "Trim", Vector3(AX, 2.3, z), out, 3.6, 0.4, 0.25, 11)
	# A pierced passage: dark floor and walls are enough at this scale.
	var t := 5.2
	var y0 := EAVE + 0.9
	U.blk(lm, "Wall", AX, y0, 0.0, t, 5.6, t)
	U.blk(lm, "Trim", AX, y0 + 5.6, 0.0, t + 0.7, 0.55, t + 0.7)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out: Vector3 = b * Vector3(0, 0, 1)
		var c := Vector3(AX, y0 + 3.4, 0.0) + out * (t * 0.5 + 0.04)
		lm.disc("Trim", c, out, 0.95, 20)
		lm.disc("Lamp", c + out * 0.03, out, 0.78, 20)
		lm.beam("Iron", c + out * 0.06, c + out * 0.06 + Vector3(0, 0.6, 0), 0.06, 0.04)
		FhP.win_row(lm, "Trim", "Window", Vector3(AX, 0, 0) + out * (t * 0.5), Vector3(AX, 0, 0) + out * (t * 0.5), out, y0 + 0.5, 1, 0.7, 1.4, true, 0.1)
	# Lantern: iron cage, glazing, hipped cap, spike.
	var ly := y0 + 6.15
	U.blk(lm, "Iron", AX, ly, 0.0, 3.0, 0.2, 3.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Iron", Vector3(AX + sx * 1.4, ly + 0.2, sz * 1.4), Vector3(AX + sx * 1.4, ly + 2.2, sz * 1.4), 0.12, 0.12)
	U.blk(lm, "Window", AX, ly + 0.2, 0.0, 2.7, 2.0, 2.7)
	for k in 3:
		lm.box("Iron", Vector3(AX, ly + 0.55 + float(k) * 0.6, 0.0), Vector3(3.0, 0.06, 3.0))
	U.hip(lm, "Roof", Vector3(AX, ly + 2.2, 0.0), 3.4, 3.4, 1.2, 0.0)
	lm.beam("Iron", Vector3(AX, ly + 3.4, 0.0), Vector3(AX, 14.0, 0.0), 0.08, 0.08)

## Tall chimney stacks along the ridge, pavilion stacks and caps.
static func _chimneys(lm: LandmarkMesh) -> void:
	for x in [-48.0, -30.0, -14.0, 14.0, 30.0, 48.0]:
		for s in [-1.0, 1.0]:
			U.blk(lm, "Brick", x, EAVE + RISE - 0.6, s * 0.8, 1.5, 2.6, 1.2)
			U.blk(lm, "Trim", x, EAVE + RISE + 2.0, s * 0.8, 1.8, 0.2, 1.5)
