class_name LandmarkFhHelsinkiChurches
extends RefCounted

## Two Helsinki Lutheran churches in true metres: St John's (Melander's
## red-brick neo-Gothic basilica, twin 74 m spires) and Kallio Church
## (Sonck's granite Art Nouveau church, 65 m tower). Footprints and part
## heights follow the OpenStreetMap 3D outlines.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

# --- St John's Church ------------------------------------------------

## Melander's church (1891), origin at the OSM footprint centre, front +Z
## (turned onto the north-east by the registry yaw): the 29 m wide nave
## (eaves 11.6 m, ridge 28.8 m) running into the polygonal chancel under
## one hipped roof, the 46 m transept, buttresses and tall lancets down
## every wall, and the entrance front: pointed portal under a gablet,
## rose window, and the twin 7.8 m square towers whose octagonal copper
## spires, ringed by pinnacles and gablets, reach 74 m.
static func stjohns(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E4B3B", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#C9C1B0", 2.5))
	lm.use("Slate", LandmarkMaterials.pbr("concrete", "#6F9583", 2.0, 0.5, 0.3))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7A7771", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	var eave := 11.6
	var nx := 0.35
	var nw := 29.3
	# Granite plinth, nave and transept walls, the polygonal chancel.
	FhU.blk(lm, "Granite", nx, 0.0, 5.0, nw + 0.8, 1.2, 46.0)
	FhU.blk(lm, "Granite", 1.35, 0.0, -11.1, 46.5, 1.2, 14.0)
	FhU.blk(lm, "Brick", nx, 0.0, 5.05, nw, eave, 45.5)
	FhU.blk(lm, "Brick", 1.35, 0.0, -11.1, 45.7, eave, 13.2)
	var ac := Vector3(nx, 0.0, -17.7)
	lm.frustum("Granite", ac, 15.4, 15.4, 1.2, 8, PI / 8.0)
	lm.frustum("Brick", ac, 14.65 / cos(PI / 8.0), 14.65 / cos(PI / 8.0), eave, 8, PI / 8.0)
	# Roofs: nave ridge at 28.8 m hipped round the chancel, transept gables.
	FhU.ridge_z(lm, "Slate", "Brick", Vector3(nx, eave, 5.05), nw, 45.5, 17.2, 0.6)
	lm.lathe("Slate", ac + Vector3(0, eave, 0), PackedVector2Array([Vector2((14.65 + 0.6) / cos(PI / 8.0), -0.5),
		Vector2(0.0, 17.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	FhU.ridge_x(lm, "Slate", "Brick", Vector3(1.35, eave, -11.1), 45.7, 13.2, 10.0, 0.6)
	# Eaves cornice of moulded brick round the walls.
	for s in [-1.0, 1.0]:
		FhP.arch_frieze(lm, "Brick", Vector3(nx + s * nw * 0.5, 0, -4.5), Vector3(nx + s * nw * 0.5, 0, 20.0),
			Vector3(s, 0, 0), eave - 0.1, 1.1, 0.2)
	# Nave flanks: buttresses between seven bays of tall lancets.
	for s in [-1.0, 1.0]:
		var x: float = nx + s * nw * 0.5
		var out := Vector3(s, 0, 0)
		FhP.lancet_row(lm, "Trim", "Glass", Vector3(x, 0, -4.4), Vector3(x, 0, 19.6), out, 2.6, 6, 2.2, 8.0)
		for k in 7:
			var z := -4.4 + 4.0 * float(k)
			_buttress(lm, Vector3(x, 0, z), out, 1.0, 1.3, 10.2)
		# Transept ends: a great traceried lancet, buttresses and gable pinnacles.
		var tx: float = 1.35 + s * 22.85
		FhP.lancet(lm, "Trim", "Glass", Vector3(tx, 2.6, -11.1), out, 4.4, 12.0, 0.45)
		FhP.lancet_row(lm, "Trim", "Glass", Vector3(tx, 0, -16.5), Vector3(tx, 0, -5.7), out, 15.5, 2, 1.0, 3.2)
		for z in [-17.4, -4.8]:
			_buttress(lm, Vector3(tx, 0, z), out, 1.1, 1.4, 11.0)
			lm.spire("Trim", Vector3(tx + s * 0.4, eave + 0.2, z), 0.45, 4.2, 0.0, 4)
		lm.spire("Trim", Vector3(tx + s * 0.3, eave + 10.0, -11.1), 0.4, 3.0, 0.0, 4)
		FhP.lancet_row(lm, "Trim", "Glass", Vector3(1.35 + s * 15.0, 0, -17.7), Vector3(1.35 + s * 21.0, 0, -17.7),
			Vector3(0, 0, -1), 2.6, 2, 2.0, 7.5)
		FhP.lancet_row(lm, "Trim", "Glass", Vector3(1.35 + s * 15.0, 0, -4.5), Vector3(1.35 + s * 21.0, 0, -4.5),
			Vector3(0, 0, 1), 2.6, 2, 2.0, 7.5)
	# Chancel: lancets on the three outer faces, buttresses at its corners.
	for k in 3:
		var a := PI * (1.25 + 0.25 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		FhP.lancet(lm, "Trim", "Glass", ac + d * 14.66 + Vector3(0, 2.6, 0), d, 2.4, 8.2, 0.35)
	for k in 4:
		var ca := PI * (1.125 + 0.25 * float(k))
		var cd := Vector3(cos(ca), 0, sin(ca))
		_buttress(lm, ac + cd * 15.85, cd, 1.0, 1.3, 10.2)
	# Entrance front between the towers (z 27.8): portal, gablet, rose, arcade.
	var fz := 27.8
	var fo := Vector3(0, 0, 1)
	FhU.blk(lm, "Trim", nx, 0.0, fz + 0.5, 6.4, 8.6, 1.0)
	FhP.lancet(lm, "Trim", "Glass", Vector3(nx, 0.4, fz + 1.0), fo, 3.0, 6.6, 0.5, false)
	lm.gable("Brick", Vector3(nx, 8.6, fz + 0.6), 6.4, 1.2, 3.2, Basis(), 0.1, "Brick")
	lm.spire("Trim", Vector3(nx, 11.6, fz + 0.6), 0.35, 2.4, 0.0, 4)
	FhU.steps(lm, "Granite", Vector3(nx, 0, fz + 1.0), fo, 9.0, 0.4, 0.2, 5)
	var rose := Vector3(nx, 17.2, fz + 0.05)
	lm.disc("Glass", rose + fo * 0.02, fo, 3.0, 24)
	FhP.ring(lm, "Trim", rose, fo, 3.0, 3.7, 0.45, 24)
	for k in 12:
		var a := TAU * float(k) / 12.0
		lm.beam("Trim", rose + fo * 0.15, rose + fo * 0.15 + Vector3(cos(a), sin(a), 0) * 3.0, 0.16, 0.2, fo)
	lm.disc("Trim", rose + fo * 0.3, fo, 0.7, 12)
	for k in 6:
		var a := TAU * (float(k) + 0.5) / 6.0
		FhP.ring(lm, "Trim", rose + Vector3(cos(a), sin(a), 0) * 1.95, fo, 0.75, 0.9, 0.2, 12)
	FhP.arcade(lm, "Trim", Vector3(nx - 5.0, 0, fz + 0.05), Vector3(nx + 5.0, 0, fz + 0.05), fo, 21.5, 3.4, 5, 0.12)
	lm.spire("Trim", Vector3(nx, 28.8, fz + 0.3), 0.6, 4.0, 0.0, 4)
	FhP.latin_cross(lm, "Trim", Vector3(nx, 32.6, fz + 0.3), 1.6, fo)
	# The twin towers: corner buttresses, string courses, belfry lancets,
	# pinnacles and gablets ringing the octagonal spires.
	for s in [-1.0, 1.0]:
		var tc := Vector3(nx + s * 9.55, 0.0, 23.9)
		FhU.blk(lm, "Brick", tc.x, 0.0, tc.z, 7.8, 37.0, 7.8)
		FhU.blk(lm, "Granite", tc.x, 0.0, tc.z, 8.4, 1.4, 8.4)
		for y in [12.0, 21.0, 30.0]:
			FhP.box_band(lm, "Trim", tc.x, tc.z, 7.8, 7.8, y, 0.45, 0.2)
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(f))
			var out: Vector3 = r * Vector3(0, 0, 1)
			var rt: Vector3 = r * Vector3(1, 0, 0)
			var fc: Vector3 = tc + out * 3.9
			if f == 0 or (f == 1 and s > 0.0) or (f == 3 and s < 0.0):
				FhP.lancet(lm, "Trim", "Glass", fc + Vector3(0, 13.4, 0), out, 1.5, 6.0, 0.3)
				FhP.lancet(lm, "Trim", "Glass", fc + Vector3(0, 3.2, 0), out, 1.2, 4.6, 0.3)
			FhP.lancet_row(lm, "Trim", "Glass", fc - rt * 2.2 + Vector3(0, 0, 0), fc + rt * 2.2, out, 22.4, 2, 1.3,
				6.6, 0.3)
			FhP.arch_frieze(lm, "Brick", fc - rt * 3.9, fc + rt * 3.9, out, 36.4, 0.9, 0.22)
			# Gablet over each face at the spire's foot.
			lm.gable("Brick", tc + out * 3.6 + Vector3(0, 37.0, 0), 5.0, 0.8, 4.6, Basis(Vector3.UP, PI * 0.5 * float(f)),
				0.15, "Brick")
			lm.disc("Glass", tc + out * 4.02 + Vector3(0, 38.6, 0), out, 0.9, 12)
		for qx in [-1.0, 1.0]:
			for qz in [-1.0, 1.0]:
				var cp := tc + Vector3(qx * 3.55, 0, qz * 3.55)
				lm.box("Brick", cp + Vector3(0, 17.0, 0), Vector3(1.1, 34.0, 1.1))
				lm.frustum("Brick", cp + Vector3(0, 37.0, 0), 0.7, 0.7, 2.2, 8, PI / 8.0)
				lm.spire("Slate", cp + Vector3(0, 39.2, 0), 0.75, 5.2, 0.0, 8)
		lm.frustum("Brick", tc + Vector3(0, 36.6, 0), 4.2, 4.2, 0.6, 8, PI / 8.0)
		lm.spire("Slate", tc + Vector3(0, 37.2, 0), 3.55, 35.4, 0.0, 8)
		# Spire lucarnes low on the cardinal faces.
		for f in 4:
			var out2: Vector3 = Basis(Vector3.UP, PI * 0.5 * float(f)) * Vector3(0, 0, 1)
			lm.gable("Slate", tc + out2 * 2.6 + Vector3(0, 45.0, 0), 1.0, 1.4, 1.2,
				Basis(Vector3.UP, PI * 0.5 * float(f)), 0.1, "Slate")
		lm.lathe("Trim", tc + Vector3(0, 72.2, 0), FhU.ball(0.25), 10)
		FhP.latin_cross(lm, "Trim", tc + Vector3(0, 72.6, 0), 1.6, fo)
	lm.commit(model)

# --- Kallio Church ---------------------------------------------------

## Lars Sonck's church on the Kallio hill (1912), grey Uusikaupunki
## granite over brick, origin at the OSM footprint centre, entrance and
## tower south (+Z), parts after the OSM 3D outline: the tall 16 m nave
## (eaves 22.5 m, ridge 30.8 m) between lower aisles, the polygonal
## chancel, the 49 m wide transverse front block, the half-round porch
## under its copper half-dome (30 m) at the foot of the tower, and the
## 65 m tower: buttressed shaft, the tall belfry slits of the seven bells,
## the corner pinnacles and the steep copper spire with its cross.
static func kallio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8F8D", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5E605F", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9D89", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	# Nave and its steep copper roof.
	FhU.blk(lm, "Granite", -0.5, 0.0, -2.4, 16.2, 22.5, 34.0)
	FhU.ridge_z(lm, "Copper", "Granite", Vector3(-0.5, 22.5, -2.4), 16.2, 34.0, 8.3, 0.5)
	FhP.box_band(lm, "Dark", -0.5, -2.4, 16.2, 34.0, 21.8, 0.7, 0.3)
	# Aisles under lean-to roofs, tall windows in each bay.
	for s in [-1.0, 1.0]:
		var ax: float = -0.5 + s * 11.1
		FhU.blk(lm, "Granite", ax, 0.0, -1.7, 6.0, 11.0, 27.4)
		lm.quad("Copper", Vector3(ax + s * 3.3, 11.0, -15.6), Vector3(ax + s * 3.3, 11.0, 12.2),
			Vector3(ax - s * 3.0, 14.5, 12.2), Vector3(ax - s * 3.0, 14.5, -15.6), Vector3(s * 0.5, 1.0, 0).normalized())
		var wx: float = -0.5 + s * 14.1
		FhP.win_row(lm, "Dark", "Glass", Vector3(wx, 0, -14.0), Vector3(wx, 0, 10.0), Vector3(s, 0, 0), 2.5, 6, 1.4,
			6.0, true, 0.3)
		FhP.strips(lm, "Granite", Vector3(wx, 0, -15.4), Vector3(wx, 0, 12.0), Vector3(s, 0, 0), 0.0, 10.0, 7, 0.9,
			0.6)
		# Clerestory: tall round-headed windows high in the nave walls.
		FhP.win_row(lm, "Dark", "Glass", Vector3(-0.5 + s * 8.1, 0, -14.0), Vector3(-0.5 + s * 8.1, 0, 10.0),
			Vector3(s, 0, 0), 15.0, 6, 1.6, 5.4, true, 0.3)
	# Chancel: polygonal apse at the north end.
	var ch := Vector3(-0.4, 0.0, -19.4)
	FhU.blk(lm, "Granite", -0.4, 0.0, -20.3, 10.8, 17.0, 1.8)
	lm.frustum("Granite", ch, 5.6, 5.6, 17.0, 8, PI / 8.0)
	lm.lathe("Copper", ch + Vector3(0, 17.0, 0), PackedVector2Array([Vector2(6.2, 0), Vector2(0.4, 5.0)]), 8, 1.0,
		1.0, PI / 8.0, false)
	for k in 3:
		var a := PI * (1.25 + 0.25 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Dark", "Glass", ch + d * 5.2 + Vector3(0, 8.0, 0), d, 1.3, 6.0, true, 0.3)
	# Transverse front block with its gabled ends and windows.
	FhU.blk(lm, "Granite", -0.25, 0.0, 18.5, 48.9, 18.0, 12.8)
	FhU.ridge_x(lm, "Copper", "Granite", Vector3(-0.25, 18.0, 18.5), 48.9, 12.8, 7.0, 0.5)
	for s in [-1.0, 1.0]:
		var ex: float = -0.25 + s * 24.45
		var o := Vector3(s, 0, 0)
		FhP.win_row(lm, "Dark", "Glass", Vector3(ex, 0, 14.0), Vector3(ex, 0, 23.0), o, 3.0, 2, 1.8, 9.0, true, 0.3)
		LandmarkDetail.window(lm, "Dark", "Glass", Vector3(ex, 21.0, 18.5) + o * 0.02, o, 1.2, 2.6, true)
		FhP.win_row(lm, "Dark", "Glass", Vector3(-0.25 + s * 8.0, 0, 24.9), Vector3(-0.25 + s * 22.0, 0, 24.9),
			Vector3(0, 0, 1), 3.0, 3, 1.6, 8.0, true, 0.3)
		for z in [12.4, 24.6]:
			lm.box("Granite", Vector3(ex - s * 0.3, 9.0, z), Vector3(1.6, 18.0, 1.4))
	# Half-round porch at the foot of the tower, copper half-dome.
	var pc := Vector3(-0.05, 0.0, 26.6)
	lm.frustum("Granite", pc, 5.75, 5.75, 22.0, 16)
	lm.frustum("Dark", pc + Vector3(0, 21.4, 0), 6.05, 6.05, 0.6, 16)
	lm.lathe("Copper", pc + Vector3(0, 22.0, 0), FhU.dome_prof(6.0, 8.0, 10), 16)
	LandmarkDetail.arch(lm, "Dark", pc + Vector3(0, 6.0, 5.75), Vector3(0, 0, 1), 4.0, 0.7, 0.5)
	lm.quad("Glass", pc + Vector3(-2.0, 0.0, 5.8), pc + Vector3(2.0, 0.0, 5.8), pc + Vector3(2.0, 6.0, 5.8),
		pc + Vector3(-2.0, 6.0, 5.8), Vector3(0, 0, 1))
	FhU.steps(lm, "Dark", pc + Vector3(0, 0, 5.7), Vector3(0, 0, 1), 7.0, 0.45, 0.17, 4)
	for k in 5:
		var a := PI * (0.15 + 0.175 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		if k != 2:
			LandmarkDetail.window(lm, "Dark", "Glass", pc + d * 5.76 + Vector3(0, 13.0, 0), d, 1.0, 4.6, true, 0.25)
	# The tower: buttressed granite shaft, bands, belfry slits, pinnacles,
	# copper spire and cross (65 m).
	var tc := Vector3(-0.1, 0.0, 19.7)
	FhU.blk(lm, "Granite", tc.x, 0.0, tc.z, 12.1, 54.0, 10.6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Granite", Vector3(tc.x + sx * 5.6, 26.0, tc.z + sz * 4.85), Vector3(1.6, 52.0, 1.6))
	for y in [22.0, 36.0]:
		FhP.box_band(lm, "Dark", tc.x, tc.z, 12.1, 10.6, y, 0.6, 0.25)
	for face in FhP.faces(tc.x, tc.z, 12.1, 10.6):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		var m := (fa + fb) * 0.5
		var r := fa.direction_to(fb)
		if fo.z > -0.5:
			for k in 3:
				LandmarkDetail.window(lm, "Dark", "Glass", m + r * (float(k) - 1.0) * 2.4 + Vector3(0, 45.0, 0) + fo * 0.02,
					fo, 1.1, 12.0, true, 0.35)
			LandmarkDetail.window(lm, "Dark", "Glass", m + Vector3(0, 30.0, 0) + fo * 0.02, fo, 1.2, 5.0, true, 0.3)
		FhP.arch_frieze(lm, "Dark", fa + r * 0.8, fb - r * 0.8, fo, 53.4, 1.0, 0.25)
	FhU.blk(lm, "Dark", tc.x, 53.6, tc.z, 12.9, 0.8, 11.4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var pp := Vector3(tc.x + sx * 5.6, 54.4, tc.z + sz * 4.85)
			lm.frustum("Granite", pp, 0.85, 0.7, 2.4, 8)
			lm.spire("Copper", pp + Vector3(0, 2.4, 0), 0.8, 2.6, 0.0, 8)
	FhU.blk(lm, "Granite", tc.x, 54.4, tc.z, 9.4, 1.4, 8.0)
	FhU.hip(lm, "Copper", Vector3(tc.x, 55.8, tc.z), 9.6, 8.2, 7.0, 0.04)
	FhP.latin_cross(lm, "Dark", Vector3(tc.x, 62.6, tc.z), 2.4, Vector3(0, 0, 1))
	lm.commit(model)

## A stepped brick buttress against the wall point `p` (ground), `w` wide,
## projecting `d`, `h` tall, with two set-offs and a sloped cap.
static func _buttress(lm: LandmarkMesh, p: Vector3, out: Vector3, w: float, d: float, h: float) -> void:
	var o := out.normalized()
	var basis := Basis(Vector3.UP.cross(o).normalized(), Vector3.UP, o)
	lm.box("Granite", p + o * d * 0.55 + Vector3(0, 0.7, 0), Vector3(w + 0.2, 1.4, d * 1.1), basis)
	lm.box("Brick", p + o * d * 0.5 + Vector3(0, h * 0.3, 0), Vector3(w, h * 0.6, d), basis)
	lm.box("Brick", p + o * d * 0.35 + Vector3(0, h * 0.75, 0), Vector3(w * 0.9, h * 0.3, d * 0.7), basis)
	lm.quad("Trim", p + o * d * 0.7 - basis.x * w * 0.5 + Vector3(0, h * 0.9, 0),
		p + o * d * 0.7 + basis.x * w * 0.5 + Vector3(0, h * 0.9, 0),
		p + basis.x * w * 0.5 + Vector3(0, h, 0), p - basis.x * w * 0.5 + Vector3(0, h, 0))
	lm.box("Trim", p + o * d * 0.5 + Vector3(0, h * 0.6, 0), Vector3(w + 0.1, 0.25, d + 0.1), basis, 0.0)
