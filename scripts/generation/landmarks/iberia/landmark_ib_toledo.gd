class_name LandmarkIbToledo
extends RefCounted

## The Alcazar of Toledo in true metres, front toward +Z (the registry
## yaw_deg turns it onto the real bearing: the main front faces north).

const TOL_TOP := 60.0
const TOL_EAVE := 34.0

## The Imperial fortress-palace (Covarrubias, Villalpando, Herrera; rebuilt
## 1939-1957): a 66 x 84 m block of warm ashlar over a granite base, four
## storeys round a courtyard, under a hipped slate roof. The north front
## (Covarrubias) toward +Z: rusticated quoins, three floors of framed
## windows with pediments on the main floor, the Plateresque portal of
## paired columns under a balcony window and the great imperial arms.
## The four 14 m square corner towers rise to 47 m and carry the Madrid
## slate spires (chapiteles) with bulb, needle and vane to 60 m. In the
## courtyard, two storeys of round-arched arcades on columns, and Charles
## V's statue in the middle. The hill itself is the terrain: the model
## stands on a low granite terrace.
static func toledo_alcazar(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBB97", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A89E8A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4F5256", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3833", 3.0))
	lm.use("Glass", LandmarkMaterials.glass())
	lm.use("Bronze", LandmarkMaterials.paint("#4A4436", 0.45, 0.7))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Granite", Vector3(0, 0.4, 2.0), Vector3(74.0, 0.8, 96.0))
	lm.box("Granite", Vector3(0, 0.6, 49.5), Vector3(50.0, 1.2, 7.0))
	lm.box("Granite", Vector3(0, 1.0, 46.5), Vector3(30.0, 2.0, 3.0))
	var eave := TOL_EAVE
	# Four wings round the 20 x 38 m courtyard.
	for wg in [[Vector3(0, 0, -30.5), Vector3(66.0, 0, 23.0)], [Vector3(0, 0, 30.5), Vector3(66.0, 0, 23.0)],
			[Vector3(-21.5, 0, 0), Vector3(23.0, 0, 38.0)], [Vector3(21.5, 0, 0), Vector3(23.0, 0, 38.0)]]:
		var c: Vector3 = wg[0]
		var s: Vector3 = wg[1]
		lm.box("Granite", c + Vector3(0, 5.5, 0), Vector3(s.x, 11.0, s.z))
		lm.box("Stone", c + Vector3(0, 11.0 + (eave - 11.0) * 0.5, 0), Vector3(s.x, eave - 11.0, s.z))
		LandmarkCeParts.hip(lm, "Roof", c + Vector3(0, eave, 0), s.x - 1.0, s.z - 1.0, 5.5)
	for k in 4:
		_front(lm, k)
	_court(lm)
	_portal(lm)
	# Corner towers with their slate spires.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_tower(lm, Vector3(sx * 33.0, 0, sz * 42.0))
	lm.commit(model)

## One outer front (k = 0 north/+Z, 1 east, 2 south, 3 west).
static func _front(lm: LandmarkMesh, k: int) -> void:
	var r := Basis(Vector3.UP, PI * 0.5 * float(k))
	var out := r * Vector3(0, 0, 1)
	var right := r * Vector3(1, 0, 0)
	var half := 42.0 if k % 2 == 0 else 33.0
	var length := 66.0 if k % 2 == 0 else 84.0
	var inner := length - 14.0
	var bays := roundi(inner / 6.0)
	var pitch := inner / float(bays)
	var face := out * half
	var gap := 9.0 if k == 0 else 0.0
	LandmarkIbParts.band(lm, "Granite", face, right, out, length, 0.8, 1.6, 0.5)
	LandmarkIbParts.band(lm, "Granite", face, right, out, length, 11.2, 0.8, 0.5)
	LandmarkIbParts.band(lm, "Stone", face, right, out, length, 21.6, 0.6, 0.35)
	LandmarkIbParts.band(lm, "Stone", face, right, out, length, 28.6, 0.5, 0.3)
	var ca := face - right * (inner * 0.5) + Vector3(0, eave_y() - 1.4, 0)
	var cb := face + right * (inner * 0.5) + Vector3(0, eave_y() - 1.4, 0)
	LandmarkDetail.cornice(lm, "Stone", ca, cb, out, 1.4, false)
	for i in bays:
		var s := (float(i) - float(bays - 1) * 0.5) * pitch
		if absf(s) < gap:
			continue
		var c := face + right * s
		LandmarkIbParts.portal(lm, "Granite", "Glass", c + Vector3(0, 3.0, 0), right, out, 1.6, 3.2, 0, 0.3)
		LandmarkIbParts.portal(lm, "Granite", "Glass", c + Vector3(0, 7.6, 0), right, out, 1.2, 1.8, 0, 0.25)
		LandmarkDetail.window(lm, "Stone", "Glass", c + Vector3(0, 16.0, 0), out, 2.0, 4.4, false, 0.25)
		lm.gable("Stone", c + Vector3(0, 18.85, 0) + out * 0.35, 3.0, 0.7, 0.8, Basis(right, Vector3.UP, out), 0.0, "Stone")
		LandmarkDetail.window(lm, "Stone", "Glass", c + Vector3(0, 24.8, 0), out, 1.8, 3.8, false, 0.2)
		LandmarkIbParts.portal(lm, "Stone", "Glass", c + Vector3(0, 30.0, 0), right, out, 1.3, 1.8, 0, 0.2)

static func eave_y() -> float:
	return TOL_EAVE

## The courtyard: two storeys of round-arched arcades on Tuscan columns
## (Corinthian and Composite in reality), a balustrade over each, and the
## statue of Charles V on its granite pedestal.
static func _court(lm: LandmarkMesh) -> void:
	lm.box("Granite", Vector3(0, 0.95, 0), Vector3(20.0, 0.3, 38.0))
	for wg in [[Vector3(0, 0, -19.0), Vector3(0, 0, 1), 20.0], [Vector3(0, 0, 19.0), Vector3(0, 0, -1), 20.0],
			[Vector3(-10.0, 0, 0), Vector3(1, 0, 0), 38.0], [Vector3(10.0, 0, 0), Vector3(-1, 0, 0), 38.0]]:
		var o: Vector3 = wg[0]
		var out: Vector3 = wg[1]
		var length: float = wg[2]
		var right := Vector3.UP.cross(out)
		var n := roundi((length - 2.0) / 5.0)
		var pitch := (length - 2.0) / float(n)
		var basis := Basis(right, Vector3.UP, out)
		for lv in 2:
			var y0 := 1.1 + 9.0 * float(lv)
			var ch := 6.2 if lv == 0 else 5.6
			for i in n + 1:
				var s := (float(i) - float(n) * 0.5) * pitch
				LandmarkIbParts.post(lm, "Stone", o + right * s + out * 2.6 + Vector3(0, y0, 0), 0.32, ch)
			for i in n:
				var s := (float(i) - float(n - 1) * 0.5) * pitch
				LandmarkIbParts.arch_ring(lm, "Stone", o + right * s + out * 2.6 + Vector3(0, y0 + ch, 0), out,
					pitch - 0.9, 0.45, 0.6)
			lm.box("Stone", o + right * 0.0 + out * 2.6 + Vector3(0, y0 + ch + pitch * 0.5 + 0.4, 0),
				Vector3(length - 1.0, 0.8, 0.9), basis)
			LandmarkIbParts.rail(lm, "Stone", o - right * (length * 0.5 - 1.0) + out * 2.6 + Vector3(0, y0 + ch + pitch * 0.5 + 0.8, 0),
				o + right * (length * 0.5 - 1.0) + out * 2.6 + Vector3(0, y0 + ch + pitch * 0.5 + 0.8, 0), 1.0, pitch)
			# Gallery back wall: doors and windows behind the arcade.
			LandmarkIbParts.window_row(lm, "Stone", "Glass", o, right, out, y0 + 3.0, n, pitch, 1.6, 3.4)
		LandmarkIbParts.window_row(lm, "Stone", "Glass", o, right, out, 26.0, n, pitch, 1.6, 3.4)
	# Charles V on his pedestal.
	lm.box("Granite", Vector3(0, 2.1, 0), Vector3(3.0, 2.0, 3.0))
	lm.box("Granite", Vector3(0, 3.5, 0), Vector3(2.4, 0.8, 2.4))
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, 3.9, 0), 3.4, true)

## The Plateresque north portal: paired columns on pedestals either side
## of the door, entablature, a balcony window between smaller columns,
## and the great imperial arms over it.
static func _portal(lm: LandmarkMesh) -> void:
	var f := Vector3(0, 0, 42.0)
	var zn := Vector3(0, 0, 1)
	lm.box("Stone", f + Vector3(0, 15.0, 0.75), Vector3(16.0, 30.0, 1.5))
	LandmarkIbParts.portal(lm, "Stone", "Shadow", f + Vector3(0, 2.0, 1.5), Vector3.RIGHT, zn, 4.6, 8.4, 1, 0.6)
	for x in [-5.6, -4.0, 4.0, 5.6]:
		lm.box("Stone", f + Vector3(x, 3.0, 2.2), Vector3(1.4, 2.0, 1.4))
		LandmarkDetail.column(lm, "Stone", f + Vector3(x, 4.0, 2.2), 0.45, 7.4, "ionic", 0)
	lm.box("Stone", f + Vector3(0, 11.9, 2.0), Vector3(13.6, 1.2, 1.8))
	LandmarkDetail.cornice(lm, "Stone", f + Vector3(-6.8, 12.5, 2.9), f + Vector3(6.8, 12.5, 2.9), zn, 0.8, true)
	LandmarkIbParts.rail(lm, "Stone", f + Vector3(-3.4, 13.3, 2.6), f + Vector3(3.4, 13.3, 2.6), 1.0, 3.4)
	LandmarkDetail.window(lm, "Stone", "Glass", f + Vector3(0, 16.8, 1.5), zn, 2.6, 5.0, true)
	for x in [-3.0, 3.0]:
		LandmarkDetail.column(lm, "Stone", f + Vector3(x, 13.3, 2.1), 0.3, 6.6, "corinthian", 0)
	lm.box("Stone", f + Vector3(0, 20.4, 2.0), Vector3(8.4, 0.8, 1.6))
	# The arms: shield on the double-headed eagle, under the crown.
	var ac := f + Vector3(0, 25.0, 1.6)
	lm.box("Stone", ac, Vector3(7.0, 7.4, 0.6))
	lm.disc("Gilt", ac + Vector3(0, -0.2, 0.32), zn, 1.9, 20)
	for sx in [-1.0, 1.0]:
		lm.beam("Stone", ac + Vector3(sx * 1.6, 0.6, 0.4), ac + Vector3(sx * 3.8, 2.6, 0.4), 1.4, 0.4, zn)
		lm.lathe("Stone", ac + Vector3(sx * 1.3, 2.3, 0.4), SEuUtil.dome(0.45, 0.7, 4), 8)
	lm.lathe("Gilt", ac + Vector3(0, 3.5, 0.4), PackedVector2Array([Vector2(0.9, 0), Vector2(1.1, 0.5),
		Vector2(0.7, 0.9), Vector2(0.0, 1.3)]), 10)
	lm.gable("Stone", f + Vector3(0, 28.8, 1.0), 9.0, 2.0, 1.4, Basis(), 0.0, "Stone")

## Corner tower: granite base, quoins, framed windows on three floors,
## a cornice and the chapitel spire.
static func _tower(lm: LandmarkMesh, t: Vector3) -> void:
	lm.box("Granite", t + Vector3(0, 5.5, 0), Vector3(15.0, 11.0, 15.0))
	lm.box("Stone", t + Vector3(0, 28.75, 0), Vector3(14.0, 35.5, 14.0))
	lm.box("Stone", t + Vector3(0, 46.2, 0), Vector3(15.6, 1.6, 15.6))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var f := t + out * 7.0
		for wy in [16.0, 24.8, 33.6]:
			LandmarkIbParts.window_row(lm, "Stone", "Glass", f, right, out, wy, 2, 5.0, 1.6, 3.6)
		LandmarkIbParts.window_row(lm, "Stone", "Glass", f, right, out, 41.0, 2, 5.0, 1.4, 2.6)
		LandmarkDetail.cornice(lm, "Stone", f - right * 7.0 + Vector3(0, 44.6, 0), f + right * 7.0 + Vector3(0, 44.6, 0), out, 0.8, false)
		# Quoins up the corner: alternating long and short blocks.
		for j in 12:
			var y := 11.6 + 2.8 * float(j)
			var lw := 1.8 if j % 2 == 0 else 1.1
			lm.box("Stone", f + right * (7.0 - lw * 0.5) + out * 0.08 + Vector3(0, y + 0.65, 0),
				Vector3(lw, 1.3, 0.16), r, 0.0)
	LandmarkIbParts.chapitel(lm, "Roof", "Gilt", t + Vector3(0, 47.0, 0), 7.2, TOL_TOP - 47.0)
