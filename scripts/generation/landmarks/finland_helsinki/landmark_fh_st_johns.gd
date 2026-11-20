extends RefCounted

## St John's Church (Johanneksenkirkko, Adolf Melander, 1891), Korkeavuorenkatu.
## Origin at the OSM footprint centre, front +Z (turned onto the north-east by
## the registry yaw -126).
##
## Measured: footprint, the 28.8 m hipped body and the two 74 m tower parts from
## OSM (ways 123901485, 438660862, 438660863; the LoD2 peak is 75.2 m). Checked
## by eye against visual-plan/refs/st_johns_church_helsinki/: deep red brick,
## verdigris copper roof and octagonal spires with corner pinnacles and
## lucarnes, the pale stone portal gable and rose window, the twin towers with
## their paired belfry lancets, the buttressed nave. Tower positions sit 3 m
## off the OSM parts. Estimated: buttress spacing, lancet sizes, the
## transept proportions.
##
## Night: the church is floodlit from the park (spots round the towers).
##
## Melander's church (1891): the 29 m wide nave (eaves 11.6 m, ridge 28.8 m)
## running into the polygonal chancel under one hipped roof, the 46 m
## transept, buttresses and tall lancets down every wall, and the entrance
## front: pointed portal under a gablet, rose window, and the twin 7.8 m
## square towers whose octagonal copper spires, ringed by pinnacles and
## gablets, reach 74 m.
const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "st_johns_church_helsinki", "skyline": true, "name": "St. John's Church, Helsinki", "lat": 60.16182, "lon": 24.94504,
	"radius_m": 5000.0, "wiki_title": "St. John's Church, Helsinki", "height_m": 74.0, "clear_m": 50.0,
	"yaw_deg": -126.0, "kind": "Church", "aliases": ["st. john's church, helsinki", "johanneksenkirkko",
		"johanneskyrkan", "st john's church, helsinki"]}

static func build(model: Node3D) -> void:
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
	D.flood(model, [
		[Vector3(-30.0, 1.0, 44.0), Vector3(-9.0, 30.0, 24.0), 16.0, 0.9, 95.0, Color(1.0, 0.9, 0.72)],
		[Vector3(30.0, 1.0, 44.0), Vector3(9.0, 30.0, 24.0), 16.0, 0.9, 95.0, Color(1.0, 0.9, 0.72)],
		[Vector3(-8.0, 1.0, 46.0), Vector3(0.0, 12.0, 28.0), 40.0, 0.7, 60.0, Color(1.0, 0.9, 0.72)],
		[Vector3(-40.0, 1.0, 0.0), Vector3(-20.0, 10.0, 0.0), 45.0, 0.6, 60.0, Color(1.0, 0.9, 0.72)],
		[Vector3(44.0, 1.0, 0.0), Vector3(22.0, 10.0, 0.0), 45.0, 0.6, 60.0, Color(1.0, 0.9, 0.72)]])

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
