class_name LandmarkFhHelsinkiCivic
extends RefCounted

## Four public buildings of central Helsinki in true metres: the National
## Museum (National Romantic granite castle), the Parliament House (red
## granite, 14 columns), the Presidential Palace (yellow neoclassical U)
## and the Ateneum (neo-Renaissance). Footprints follow OpenStreetMap.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

# --- National Museum of Finland -------------------------------------

## Gesellius-Lindgren-Saarinen (1910), origin at the OSM footprint centre,
## front +Z (the registry yaw turns it onto Mannerheimintie): grey
## Uusikaupunki granite and render round two courts, steep hipped roofs
## with gabled dormers, the round stair tower at the rear corner, the
## church-like rear hall, the entrance with Wikström's bear beside its
## steps, and the 58 m tower (7.5 x 9 m) at the front corner: granite
## shaft, arched belfry, and the copper spire with its lucarnes.
static func natmuseum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E918D", 4.0))
	lm.use("Soap", LandmarkMaterials.pbr("limestone", "#A9AFA6", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6B9A85", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	# Blocks [x0, x1, z0, z1, eave height, roof rise].
	var blocks := [[2.0, 43.0, -20.0, 15.5, 15.0, 9.0], [-13.3, 2.0, -37.7, 20.0, 15.0, 10.0],
		[-34.2, -13.3, -29.0, 3.3, 13.0, 8.0], [-13.6, 0.0, -46.9, -37.7, 11.0, 5.0]]
	for b in blocks:
		var bx0: float = b[0]
		var bx1: float = b[1]
		var bz0: float = b[2]
		var bz1: float = b[3]
		var eave: float = b[4]
		var w := bx1 - bx0
		var d := bz1 - bz0
		var cx := (bx0 + bx1) * 0.5
		var cz := (bz0 + bz1) * 0.5
		FhU.blk(lm, "Granite", cx, 0.0, cz, w + 0.5, 3.0, d + 0.5)
		FhU.blk(lm, "Soap", cx, 3.0, cz, w, eave - 3.0, d)
		FhU.blk(lm, "Granite", cx, eave - 0.6, cz, w + 0.6, 0.7, d + 0.6)
		FhU.hip(lm, "Copper", Vector3(cx, eave + 0.1, cz), w + 1.0, d + 1.0, float(b[5]), 0.12)
		for face in FhP.faces(cx, cz, w, d):
			var l := (face[0] as Vector3).distance_to(face[1])
			var n := maxi(int(l / 4.6), 1)
			FhP.pierce(lm, "Soap", "Glass", face[0], face[1], face[2], 3.0, eave - 3.6, n, 2,
				Vector2(1.4, 2.4), 1.0, (eave - 3.0) * 0.5, 0.3)
			FhU.openings(lm, "Glass", face[0], face[1], face[2], 1.0, n, 1.0, 1.2, false, 0.03)
			# Gabled dormers on the long roof slopes.
			if l > 14.0:
				var o: Vector3 = face[2]
				var rb := Basis(Vector3.UP, atan2(o.x, o.z))
				for k in maxi(int(l / 9.0), 1):
					var p := (face[0] as Vector3).lerp(face[1], (float(k) + 0.5) / float(maxi(int(l / 9.0), 1)))
					var dc := p - o * 1.6 + Vector3(0, eave + 1.0, 0)
					lm.box("Soap", dc + Vector3(0, 0.9, 0), Vector3(2.2, 1.8, 2.4), rb)
					lm.gable("Copper", dc + Vector3(0, 1.8, 0), 2.2, 2.4, 1.3, rb, 0.2, "Soap")
					lm.quad("Glass", dc + o * 1.22 + rb.x * -0.6 + Vector3(0, 0.3, 0), dc + o * 1.22 + rb.x * 0.6 + Vector3(0, 0.3, 0),
						dc + o * 1.22 + rb.x * 0.6 + Vector3(0, 1.5, 0), dc + o * 1.22 + rb.x * -0.6 + Vector3(0, 1.5, 0), o)
	# Gabled ends of the main block and the west wing toward the street.
	FhU.ridge_z(lm, "Copper", "Soap", Vector3(23.0, 15.0, 15.5), 12.0, 3.0, 5.0, 0.3)
	FhU.ridge_z(lm, "Copper", "Soap", Vector3(-24.0, 13.0, 3.3), 10.0, 3.0, 4.5, 0.3)
	FhP.win_row(lm, "Granite", "Glass", Vector3(19.0, 0, 17.05), Vector3(27.0, 0, 17.05), Vector3(0, 0, 1), 15.6, 3,
		1.0, 2.6, true, 0.2)
	# Round stair tower at the rear corner of the west wing, conical roof.
	var rt := Vector3(-31.0, 0.0, -29.7)
	lm.frustum("Granite", rt, 5.4, 5.3, 3.0, 20)
	lm.frustum("Soap", rt + Vector3(0, 3.0, 0), 5.2, 5.2, 13.0, 20)
	lm.frustum("Granite", rt + Vector3(0, 15.6, 0), 5.5, 5.5, 0.6, 20)
	lm.lathe("Copper", rt + Vector3(0, 16.2, 0), PackedVector2Array([Vector2(5.7, 0), Vector2(3.0, 3.6),
		Vector2(0.15, 7.6)]), 20)
	for k in 5:
		var a := PI * 0.5 + PI * 0.25 * float(k)
		FhU.opening(lm, "Glass", rt + Vector3(cos(a), 0, sin(a)) * 5.25 + Vector3(0, 6.0 + 2.0 * float(k % 2), 0),
			Vector3(cos(a), 0, sin(a)), 1.0, 2.2, false)
	# Rear hall: a church-like gable with a rose window.
	FhU.ridge_z(lm, "Copper", "Soap", Vector3(-6.8, 11.0, -42.3), 13.6, 9.2, 6.0, 0.4)
	lm.disc("Glass", Vector3(-6.8, 13.5, -46.98), Vector3(0, 0, -1), 1.6, 16)
	FhP.ring(lm, "Granite", Vector3(-6.8, 13.5, -46.95), Vector3(0, 0, -1), 1.6, 2.1, 0.25, 16)
	# Entrance: granite portal, steps and the bear on its pedestal.
	FhU.blk(lm, "Granite", -5.6, 0.0, 20.7, 7.6, 8.0, 1.4)
	LandmarkDetail.arch(lm, "Granite", Vector3(-5.6, 4.6, 21.4), Vector3(0, 0, 1), 3.4, 0.6, 0.4)
	lm.quad("Glass", Vector3(-7.3, 0.6, 21.42), Vector3(-3.9, 0.6, 21.42), Vector3(-3.9, 4.6, 21.42),
		Vector3(-7.3, 4.6, 21.42), Vector3(0, 0, 1))
	FhU.steps(lm, "Granite", Vector3(-5.6, 0.0, 21.4), Vector3(0, 0, 1), 8.0, 0.6, 0.15, 4)
	lm.box("Granite", Vector3(-0.6, 0.6, 23.5), Vector3(1.6, 1.2, 2.6))
	_bear(lm, "Granite", Vector3(-0.6, 1.2, 23.5), 2.4)
	# The tower: granite shaft with corner buttresses, slit windows, the
	# arched belfry, cornice and the copper spire with four lucarnes.
	var tx := -11.55
	var tz := 7.2
	FhU.blk(lm, "Granite", tx, 0.0, tz, 7.5, 36.0, 9.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Granite", Vector3(tx + sx * 3.5, 10.0, tz + sz * 4.25), Vector3(1.3, 20.0, 1.3))
	for y in [12.0, 24.0]:
		FhP.box_band(lm, "Soap", tx, tz, 7.5, 9.0, y, 0.4, 0.15)
	FhU.blk(lm, "Soap", tx, 36.0, tz, 8.3, 0.8, 9.8)
	FhU.blk(lm, "Granite", tx, 36.8, tz, 6.4, 6.0, 8.0)
	for face in FhP.faces(tx, tz, 6.4, 8.0):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		var nn := 2 if fa.distance_to(fb) < 7.0 else 3
		for k in nn:
			var p := fa.lerp(fb, (float(k) + 0.5) / float(nn))
			lm.quad("Glass", p + fo * 0.03 + Vector3(0, 37.6, 0) - fa.direction_to(fb) * 0.7,
				p + fo * 0.03 + Vector3(0, 37.6, 0) + fa.direction_to(fb) * 0.7,
				p + fo * 0.03 + Vector3(0, 40.6, 0) + fa.direction_to(fb) * 0.7,
				p + fo * 0.03 + Vector3(0, 40.6, 0) - fa.direction_to(fb) * 0.7, fo)
			LandmarkDetail.arch(lm, "Granite", p + Vector3(0, 40.6, 0), fo, 1.4, 0.3, 0.3)
		FhU.openings(lm, "Glass", fa, fb, fo, 18.0, 1, 0.9, 5.0, false, 0.04)
		FhU.openings(lm, "Glass", fa, fb, fo, 27.0, 1, 0.9, 4.0, false, 0.04)
	FhU.blk(lm, "Soap", tx, 42.8, tz, 7.0, 0.5, 8.6)
	FhU.hip(lm, "Copper", Vector3(tx, 43.3, tz), 6.8, 8.4, 13.4, 0.04)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var o: Vector3 = rb * Vector3(0, 0, 1)
		var half := 3.2 if f % 2 == 0 else 2.6
		lm.box("Copper", Vector3(tx, 46.0, tz) + o * (half - 0.6), Vector3(1.2, 1.6, 1.4), rb)
		lm.gable("Copper", Vector3(tx, 46.8, tz) + o * (half - 0.6), 1.2, 1.4, 0.8, rb, 0.1, "Copper")
	lm.frustum("Copper", Vector3(tx, 56.4, tz), 0.12, 0.05, 1.6, 6)
	lm.commit(model)

## Emil Wikström's granite bear, `l` long, lying on a pedestal at `base`.
static func _bear(lm: LandmarkMesh, key: String, base: Vector3, l: float) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(0.0, 0.0), Vector2(l * 0.2, l * 0.02), Vector2(l * 0.24, l * 0.12),
		Vector2(l * 0.2, l * 0.26), Vector2(l * 0.1, l * 0.32), Vector2(0.0, l * 0.33)]), 12, 0.8, 2.0)
	lm.lathe(key, base + Vector3(0, l * 0.14, l * 0.46), FhU.ball(l * 0.1), 10, 1.0, 1.3)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box(key, base + Vector3(sx * l * 0.14, l * 0.05, sz * l * 0.3), Vector3(l * 0.1, l * 0.1, l * 0.16))

# --- Parliament House ------------------------------------------------

## Sirén's Eduskuntatalo (1931), origin at the OSM footprint centre, front
## +Z (turned onto Mannerheimintie by the registry yaw): the 77.8 x 56 m
## block of red Kalvola granite, 25 m tall in six storeys, raised on its
## plinth; the broad flight of steps up to the terrace and the 14 fluted
## columns with stylised Corinthian capitals rising to the fourth storey,
## carrying the entablature and the attic with its round windows; tall
## windows in pilastered bays down the flanks, and the set-back top
## storey round the shallow dome of the 25 m session hall.
static func parliament(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A9786C", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#C7A89B", 3.0))
	lm.use("Step", LandmarkMaterials.pbr("stone", "#9A8F88", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5A6068", 3.0))
	var x0 := -35.0
	var x1 := 42.8
	var cx := (x0 + x1) * 0.5
	var w := x1 - x0
	var zb := -26.8
	var zf := 29.3
	var zw := 24.7
	var top := 23.0
	# Core block behind the portico, the two corner masses flanking it.
	FhU.blk(lm, "Granite", cx, 0.0, (zb + zw) * 0.5, w, top, zw - zb)
	FhU.blk(lm, "Step", cx, 0.0, (zb + zw) * 0.5, w + 0.6, 1.4, zw - zb + 0.6)
	var cl := -29.5
	var cr := 37.3
	for p in [[x0, cl], [cr, x1]]:
		var px0: float = p[0]
		var px1: float = p[1]
		FhU.blk(lm, "Granite", (px0 + px1) * 0.5, 0.0, (zw + zf) * 0.5, px1 - px0, top, zf - zw)
		FhU.blk(lm, "Step", (px0 + px1) * 0.5, 0.0, (zw + zf) * 0.5 + 0.3, px1 - px0 + 0.6, 1.4, zf - zw + 0.6)
		FhP.pierce(lm, "Granite", "Glass", Vector3(px0, 0, zf), Vector3(px1, 0, zf), Vector3(0, 0, 1), 1.4, 21.0,
			1, 6, Vector2(1.5, 2.3), 0.9, 3.45, 0.3)
	# Terrace, steps and the colonnade of 14 columns.
	FhU.blk(lm, "Step", (cl + cr) * 0.5, 0.0, (zw + zf) * 0.5, cr - cl, 2.4, zf - zw)
	FhU.steps(lm, "Step", Vector3((cl + cr) * 0.5, 0.0, zf), Vector3(0, 0, 1), cr - cl - 1.0, 0.45, 0.2, 12)
	for s in [-1.0, 1.0]:
		FhU.blk(lm, "Granite", (cl + cr) * 0.5 + s * ((cr - cl) * 0.5 + 0.6), 0.0, zf + 2.8, 1.6, 2.6, 5.6)
	var ca := Vector3(-27.0, 2.4, 27.5)
	var cb := Vector3(34.75, 2.4, 27.5)
	for i in 14:
		var p := ca.lerp(cb, float(i) / 13.0)
		lm.box("Step", p + Vector3(0, 0.25, 0), Vector3(2.2, 0.5, 2.2))
		LandmarkDetail.column(lm, "Granite", p + Vector3(0, 0.5, 0), 0.8, 15.1, "corinthian", 20)
	# Recessed wall behind the columns: three storeys of tall windows between them.
	FhP.pierce(lm, "Granite", "Glass", Vector3(cl, 0, zw + 0.3), Vector3(ca.x, 0, zw + 0.3), Vector3(0, 0, 1),
		2.4, 15.6, 1, 1, Vector2(0.01, 0.01), 20.0, 3.6, 0.3)
	FhP.pierce(lm, "Granite", "Glass", Vector3(cb.x, 0, zw + 0.3), Vector3(cr, 0, zw + 0.3), Vector3(0, 0, 1),
		2.4, 15.6, 1, 1, Vector2(0.01, 0.01), 20.0, 3.6, 0.3)
	FhP.pierce(lm, "Granite", "Glass", Vector3(ca.x, 0, zw), Vector3(cb.x, 0, zw), Vector3(0, 0, 1), 2.4, 15.6,
		13, 4, Vector2(1.7, 2.6), 1.6, 3.6, 0.3)
	FhP.win_row(lm, "Trim", "Glass", Vector3(ca.x, 0, zw + 0.3), Vector3(cb.x, 0, zw + 0.3), Vector3(0, 0, 1), 2.6,
		13, 2.2, 3.2, false, 0.3)
	# Entablature over the columns, then the attic with its round windows.
	FhU.blk(lm, "Trim", (cl + cr) * 0.5, 18.0, (zw + zf) * 0.5, cr - cl, 1.2, zf - zw)
	FhU.blk(lm, "Granite", (cl + cr) * 0.5, 19.2, (zw + zf) * 0.5, cr - cl, top - 19.2, zf - zw)
	LandmarkDetail.cornice(lm, "Trim", Vector3(cl, 19.2, zf), Vector3(cr, 19.2, zf), Vector3(0, 0, 1), 0.7, true)
	for i in 13:
		var p := ca.lerp(cb, (float(i) + 0.5) / 13.0)
		var rc := Vector3(p.x, 21.1, zf)
		lm.disc("Glass", rc + Vector3(0, 0, 0.03), Vector3(0, 0, 1), 0.7, 16)
		FhP.ring(lm, "Trim", rc, Vector3(0, 0, 1), 0.7, 1.0, 0.25, 16)
	# Crowning cornice round the whole block.
	for face in FhP.faces(cx, (zb + zf) * 0.5, w, zf - zb):
		LandmarkDetail.cornice(lm, "Trim", (face[0] as Vector3) + Vector3(0, top - 0.8, 0),
			(face[1] as Vector3) + Vector3(0, top - 0.8, 0), face[2], 0.8, false)
	# Flanks and back: pilastered bays of windows over the granite base.
	for s in [-1.0, 1.0]:
		var x: float = x0 if s < 0.0 else x1
		var a := Vector3(x, 0, zf if s < 0.0 else zb)
		var b := Vector3(x, 0, zb if s < 0.0 else zf)
		FhP.pierce(lm, "Granite", "Glass", a, b, Vector3(s, 0, 0), 1.4, 21.0, 14, 6, Vector2(1.3, 2.3), 0.9,
			3.45, 0.3)
		FhP.strips(lm, "Granite", Vector3(x, 0, zb + 2.0), Vector3(x, 0, zf - 2.0), Vector3(s, 0, 0), 4.6, 17.0,
			15, 0.6, 0.55)
	FhP.pierce(lm, "Granite", "Glass", Vector3(x1, 0, zb), Vector3(x0, 0, zb), Vector3(0, 0, -1), 1.4, 21.0, 20,
		6, Vector2(1.3, 2.3), 0.9, 3.45, 0.3)
	FhP.strips(lm, "Granite", Vector3(x1 - 2.0, 0, zb), Vector3(x0 + 2.0, 0, zb), Vector3(0, 0, -1), 4.6, 17.0,
		21, 0.6, 0.55)
	# Set-back top storey, parapet and the shallow session-hall dome.
	var tz0 := zb + 2.5
	var tz1 := zw - 1.0
	FhU.blk(lm, "Granite", cx, top, (tz0 + tz1) * 0.5, w - 5.0, 1.9, tz1 - tz0)
	for face in FhP.faces(cx, (tz0 + tz1) * 0.5, w - 5.0, tz1 - tz0):
		FhU.openings(lm, "Glass", face[0], face[1], face[2], top + 0.4, int((face[0] as Vector3).distance_to(face[1]) / 3.5),
			1.0, 1.1, false, 0.04)
	FhU.blk(lm, "Trim", cx, top + 1.9, (tz0 + tz1) * 0.5, w - 4.6, 0.25, tz1 - tz0 + 0.4)
	FhU.blk(lm, "Roof", cx, top - 0.1, (zb + zf) * 0.5, w - 1.0, 0.25, zf - zb - 1.0)
	lm.lathe("Roof", Vector3(3.4, top + 2.15, 0.9), FhU.dome_prof(6.4, 0.7, 6), 24)
	lm.commit(model)

# --- Presidential Palace -------------------------------------------

## The palace by the Market Square (Granstedt's merchant house of 1820,
## rebuilt by Engel in 1843), origin at the OSM footprint centre, the
## forecourt side +Z (registry yaw -3): the three-storey ochre range
## round its inner court (St Petersburg Empire style, about 100 rooms),
## a rusticated ground floor, pedimented windows on the piano nobile, the
## central risalit with four Ionic columns under a pediment, the
## three-storey west wing and the low east wing framing the forecourt,
## low metal hips and the small lanterns over the stair halls.
static func presidential(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#DDB96E", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F0EAD8", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6C7378", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8C8A84", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	var h := 16.0
	# Ranges [x0, x1, z0, z1, eave]: the main range and the two wings.
	var parts := [[-37.0, 12.9, -37.9, 12.9, h], [-35.9, -27.8, 12.9, 34.4, h], [4.4, 12.8, 12.9, 34.4, 5.0]]
	for p in parts:
		var px0: float = p[0]
		var px1: float = p[1]
		var pz0: float = p[2]
		var pz1: float = p[3]
		var eave: float = p[4]
		var w := px1 - px0
		var d := pz1 - pz0
		var cx := (px0 + px1) * 0.5
		var cz := (pz0 + pz1) * 0.5
		FhU.blk(lm, "Plinth", cx, 0.0, cz, w + 0.4, 1.0, d + 0.4)
		FhU.blk(lm, "Wall", cx, 1.0, cz, w, eave - 1.0, d)
		FhU.hip(lm, "Roof", Vector3(cx, eave + 0.4, cz), w + 0.9, d + 0.9, 3.6 if eave > 10.0 else 1.6, 0.25)
		for face in FhP.faces(cx, cz, w, d):
			var fa: Vector3 = face[0]
			var fb: Vector3 = face[1]
			var fo: Vector3 = face[2]
			LandmarkDetail.cornice(lm, "Trim", fa + Vector3(0, eave - 0.6, 0), fb + Vector3(0, eave - 0.6, 0), fo, 0.9,
				true)
			# Skip the faces hidden against the main range.
			if eave < 10.0 or (pz0 > 12.0 and fo.z < -0.5):
				FhP.pierce(lm, "Wall", "Glass", fa, fb, fo, 1.0, eave - 1.6, maxi(int(fa.distance_to(fb) / 3.8), 1),
					1, Vector2(1.3, 2.2), 0.8, 3.0, 0.2)
				continue
			var n := maxi(int(fa.distance_to(fb) / 3.8), 1)
			var skip_mid := pz1 > 12.0 and pz1 < 13.0 and fo.z > 0.5
			# Rusticated ground floor with its joints, then three window rows.
			for k in 4:
				FhP.band(lm, "Wall", fa, fb, fo, 1.0 + 1.1 * float(k + 1), 0.1, 0.06)
			FhP.band(lm, "Trim", fa, fb, fo, 5.4, 0.45, 0.2)
			if skip_mid:
				for seg in [[fa, fa.lerp(fb, 0.4)], [fa.lerp(fb, 0.7), fb]]:
					var sa: Vector3 = seg[0]
					var sb: Vector3 = seg[1]
					var m := maxi(int(sa.distance_to(sb) / 3.8), 1)
					FhP.win_row(lm, "Trim", "Glass", sa, sb, fo, 1.8, m, 1.3, 2.4, false, 0.2)
					FhP.win_row(lm, "Trim", "Glass", sa, sb, fo, 6.6, m, 1.5, 3.0, false, 0.22)
					FhP.win_row(lm, "Trim", "Glass", sa, sb, fo, 11.3, m, 1.3, 2.2, false, 0.2)
			else:
				FhP.win_row(lm, "Trim", "Glass", fa, fb, fo, 1.8, n, 1.3, 2.4, false, 0.2)
				FhP.win_row(lm, "Trim", "Glass", fa, fb, fo, 6.6, n, 1.5, 3.0, false, 0.22)
				FhP.win_row(lm, "Trim", "Glass", fa, fb, fo, 11.3, n, 1.3, 2.2, false, 0.2)
			FhP.strips(lm, "Trim", fa + fa.direction_to(fb) * 0.3, fb - fa.direction_to(fb) * 0.3, fo, 1.0,
				eave - 1.6, 2, 0.8, 0.15)
	# Central risalit on the forecourt: rusticated arcade, four Ionic
	# columns through the upper storeys, entablature and pediment.
	var rx0 := -18.9
	var rx1 := -4.2
	var rz := 14.1
	var rc := (rx0 + rx1) * 0.5
	FhU.blk(lm, "Wall", rc, 1.0, 13.5, rx1 - rx0, h - 1.0, 1.2)
	for k in 3:
		var px := rc + (float(k) - 1.0) * 4.2
		lm.quad("Glass", Vector3(px - 1.2, 1.0, rz + 0.02), Vector3(px + 1.2, 1.0, rz + 0.02),
			Vector3(px + 1.2, 4.0, rz + 0.02), Vector3(px - 1.2, 4.0, rz + 0.02), Vector3(0, 0, 1))
		LandmarkDetail.arch(lm, "Trim", Vector3(px, 4.0, rz), Vector3(0, 0, 1), 2.4, 0.35, 0.3)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(px, 8.1, rz + 1.0), Vector3(0, 0, 1), 1.6, 3.2, true, 0.2)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(px, 12.4, rz + 1.0), Vector3(0, 0, 1), 1.4, 2.2, false, 0.2)
	FhU.blk(lm, "Trim", rc, 5.4, rz + 0.9, rx1 - rx0, 0.6, 1.8)
	for k in 4:
		var px := rc + (float(k) - 1.5) * 4.2
		LandmarkDetail.column(lm, "Trim", Vector3(px, 6.0, rz + 1.2), 0.42, 8.6, "ionic", 20)
	FhU.blk(lm, "Trim", rc, 14.6, rz + 0.7, rx1 - rx0, 1.4, 2.2)
	lm.gable("Roof", Vector3(rc, h, rz - 2.0), rx1 - rx0, 6.2, 3.2, Basis(), 0.3, "Trim")
	LandmarkDetail.balustrade(lm, "Trim", Vector3(rc - 6.5, 6.0, rz + 1.95), Vector3(rc + 6.5, 6.0, rz + 1.95), 0.9,
		4.3)
	# Lanterns over the stair halls.
	for q in [Vector3(-11.45, 0, 4.8), Vector3(5.9, 0, 3.7)]:
		FhU.blk(lm, "Wall", q.x, h, q.z, 3.6, 2.2, 3.6)
		FhU.blk(lm, "Glass", q.x, h + 0.5, q.z, 3.65, 1.2, 3.65)
		FhU.hip(lm, "Roof", q + Vector3(0, h + 2.2, 0), 4.0, 4.0, 1.4)
	lm.commit(model)

# --- Ateneum -----------------------------------------------------------

## Höijer's Ateneum (1887), origin at the OSM footprint centre, front +Z
## (the registry yaw turns it north onto the station square): the 77 x
## 49 m neo-Renaissance block of three storeys over a granite plinth, the
## rusticated ground floor with round-arched windows, pedimented windows
## on the first floor with Vallgren's 16 medallion reliefs between them,
## the shallow side risalits and the central risalit: three arched portals
## up a flight of steps, the busts of Bramante, Raphael and Phidias above
## them, four caryatids carrying the pediment and Sjöström's sculpture
## group on its crown. Low metal hips with the glazed roof of the halls.
static func ateneum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D9CFAE", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EDE6D2", 2.5))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6B9A85", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	var x0 := -38.5
	var x1 := 38.5
	var zb := -24.5
	var zf := 24.9
	var cz := (zb + zf) * 0.5
	var w := x1 - x0
	var d := zf - zb
	var eave := 17.2
	FhU.blk(lm, "Plinth", 0.0, 0.0, cz, w + 0.6, 1.3, d + 0.6)
	FhU.blk(lm, "Wall", 0.0, 1.3, cz, w, eave - 1.3, d)
	# Rusticated ground floor: horizontal joints as thin bands, then the
	# first-floor band and the main cornice round the block.
	for k in 5:
		FhP.box_band(lm, "Wall", 0.0, cz, w, d, 1.3 + 1.0 * float(k) + 0.9, 0.12, 0.08)
	FhP.box_band(lm, "Trim", 0.0, cz, w, d, 6.1, 0.5, 0.25)
	FhP.box_band(lm, "Trim", 0.0, cz, w, d, 11.9, 0.35, 0.15)
	for face in FhP.faces(0.0, cz, w, d):
		LandmarkDetail.cornice(lm, "Trim", (face[0] as Vector3) + Vector3(0, eave - 0.9, 0),
			(face[1] as Vector3) + Vector3(0, eave - 0.9, 0), face[2], 0.95, true)
	# Low hips and the glazed hall roof.
	FhU.hip(lm, "Copper", Vector3(0, eave, cz), w + 0.6, d + 0.6, 2.4, 0.62)
	FhU.ridge_x(lm, "Glass", "Glass", Vector3(0, eave + 2.4, cz), 44.0, 28.0, 2.2, 0.0)
	for k in 9:
		var x := -21.0 + 5.25 * float(k)
		lm.beam("Trim", Vector3(x, eave + 2.45, cz - 14.0), Vector3(x, eave + 4.6, cz), 0.15, 0.2)
		lm.beam("Trim", Vector3(x, eave + 2.45, cz + 14.0), Vector3(x, eave + 4.6, cz), 0.15, 0.2)
	# Front wings either side of the central risalit, with their side risalits.
	var fo := Vector3(0, 0, 1)
	for s in [-1.0, 1.0]:
		var wa := Vector3(s * 10.2, 0, zf)
		var wb := Vector3(s * 38.3, 0, zf)
		var l := wa if s < 0.0 else wb
		var r := wb if s < 0.0 else wa
		l = Vector3(minf(wa.x, wb.x), 0, zf)
		r = Vector3(maxf(wa.x, wb.x), 0, zf)
		FhP.win_row(lm, "Trim", "Glass", l, r, fo, 2.0, 7, 1.7, 3.2, true, 0.25)
		FhP.win_row(lm, "Trim", "Glass", l, r, fo, 7.4, 7, 1.8, 3.4, false, 0.25)
		FhP.win_row(lm, "Trim", "Glass", l, r, fo, 12.9, 7, 1.5, 2.6, false, 0.2)
		# Medallion reliefs between the first-floor windows.
		for k in 6:
			var p := l.lerp(r, (float(k) + 1.0) / 7.0)
			FhP.ring(lm, "Trim", p + Vector3(0, 9.4, 0.02), fo, 0.55, 0.75, 0.15, 14)
			lm.disc("Trim", p + Vector3(0, 9.4, 0.12), fo, 0.56, 12)
		# Side risalit: a shallow projecting bay with quoins and a raised attic.
		var rx: float = s * 33.0
		FhU.blk(lm, "Wall", rx, 1.3, zf + 0.5, 5.6, eave - 1.3, 1.0)
		FhP.strips(lm, "Trim", Vector3(rx - 2.8, 0, zf + 1.0), Vector3(rx + 2.8, 0, zf + 1.0), fo, 6.6, 10.2, 2,
			0.7, 0.15)
		FhU.blk(lm, "Wall", rx, eave, zf + 0.3, 6.2, 1.6, 1.6)
		LandmarkDetail.balustrade(lm, "Trim", Vector3(rx - 2.9, eave + 1.6, zf + 0.9), Vector3(rx + 2.9, eave + 1.6,
			zf + 0.9), 0.9, 2.9)
	# Central risalit: portals, busts, caryatids and the pediment.
	var rz := zf + 1.7
	FhU.blk(lm, "Wall", 0.35, 1.3, zf + 0.85, 20.3, eave - 1.3, 1.7)
	FhU.blk(lm, "Plinth", 0.35, 0.0, zf + 1.0, 21.0, 1.3, 2.4)
	FhU.steps(lm, "Plinth", Vector3(0.35, 0.0, rz + 0.3), fo, 14.0, 0.4, 0.26, 5)
	for k in 3:
		var px := 0.35 + (float(k) - 1.0) * 5.4
		var pc := Vector3(px, 1.3, rz)
		lm.quad("Glass", pc + Vector3(-1.3, 0, 0.02), pc + Vector3(1.3, 0, 0.02), pc + Vector3(1.3, 3.8, 0.02),
			pc + Vector3(-1.3, 3.8, 0.02), fo)
		LandmarkDetail.arch(lm, "Trim", pc + Vector3(0, 3.8, 0), fo, 2.6, 0.45, 0.35)
		for sx in [-1.0, 1.0]:
			lm.box("Trim", pc + Vector3(sx * 1.55, 1.9, 0.15), Vector3(0.5, 3.8, 0.3))
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(px, 9.0, rz + 0.02), fo, 1.9, 3.6, true, 0.3)
		# A bust on its console over each portal.
		_bust(lm, "Trim", Vector3(px + (2.6 if k < 2 else -2.6), 7.6, rz + 0.4), 1.1)
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(px, 14.3, rz + 0.02), fo, 1.6, 2.6, false, 0.25)
	for k in 4:
		var px := 0.35 + (float(k) - 1.5) * 5.4
		lm.box("Trim", Vector3(px, 12.4, rz + 0.45), Vector3(1.0, 0.5, 0.9))
		LandmarkKits.statue_figure(lm, "Trim", Vector3(px, 12.65, rz + 0.5), 3.6, false)
		lm.box("Trim", Vector3(px, 16.4, rz + 0.45), Vector3(1.1, 0.4, 0.9))
	FhU.blk(lm, "Trim", 0.35, eave - 0.6, rz - 0.6, 21.2, 0.9, 1.8)
	FhU.blk(lm, "Wall", 0.35, eave + 0.3, rz - 0.75, 20.3, 1.2, 1.5)
	lm.gable("Copper", Vector3(0.35, eave + 1.5, rz - 7.0), 20.6, 14.0, 3.6, Basis(), 0.3, "Trim")
	# Raking cornices and the sculpture group on the pediment.
	for sx in [-1.0, 1.0]:
		lm.beam("Trim", Vector3(0.35 + sx * 10.6, eave + 1.5, rz + 0.1), Vector3(0.35, eave + 5.1, rz + 0.1), 0.45,
			0.6, Vector3.RIGHT)
		LandmarkKits.statue_figure(lm, "Trim", Vector3(0.35 + sx * 3.2, eave + 1.6, rz - 0.2), 2.2, false)
		lm.box("Trim", Vector3(0.35 + sx * 10.4, eave + 1.9, rz - 0.2), Vector3(0.8, 0.8, 0.8))
	lm.box("Trim", Vector3(0.35, eave + 1.7, rz - 0.2), Vector3(2.0, 0.4, 1.0))
	LandmarkKits.statue_figure(lm, "Trim", Vector3(0.35, eave + 1.9, rz - 0.2), 3.0, true)
	# Sides and back: recessed windows in three storeys.
	for s in [-1.0, 1.0]:
		var x: float = x1 if s > 0.0 else x0
		FhP.pierce(lm, "Wall", "Glass", Vector3(x, 0, zf), Vector3(x, 0, zb), Vector3(s, 0, 0), 1.3, 15.6, 9, 3,
			Vector2(1.7, 3.0), 1.2, 5.4, 0.25)
	FhP.pierce(lm, "Wall", "Glass", Vector3(x1, 0, zb), Vector3(x0, 0, zb), Vector3(0, 0, -1), 1.3, 15.6, 15, 3,
		Vector2(1.7, 3.0), 1.2, 5.4, 0.25)
	lm.commit(model)

## A portrait bust of height h on a console: shoulders, neck and head.
static func _bust(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.box(key, base + Vector3(0, h * 0.12, 0), Vector3(h * 0.5, h * 0.24, h * 0.4))
	lm.lathe(key, base + Vector3(0, h * 0.24, 0), PackedVector2Array([Vector2(h * 0.18, 0), Vector2(h * 0.3, h * 0.1),
		Vector2(h * 0.28, h * 0.32), Vector2(h * 0.08, h * 0.42), Vector2(h * 0.07, h * 0.5)]), 12, 1.0, 0.6)
	lm.lathe(key, base + Vector3(0, h * 0.72, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(h * 0.09, h * 0.04),
		Vector2(h * 0.12, h * 0.13), Vector2(h * 0.1, h * 0.22), Vector2(0.0, h * 0.28)]), 12, 0.9, 1.0)
