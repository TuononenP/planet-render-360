class_name StoDjurgHazeliusGate
extends RefCounted

## Hazeliusporten, the main entrance to Skansen (visual-plan/refs/landmarks/
## skansen_hazelius_gate/; only the OSM entrance node 7082149942 is mapped,
## so every dimension below is scaled from the photos and is approximate).
## Origin on the gate line between the two gate pillars, -Z toward the hill
## (Skansen's slope rises behind), +Z the cobbled forecourt the visitor
## crosses. Registry yaw 90 turns +Z to face west onto Djurgårdsvägen.
##
## Spec:
## - Two square pavilions (7.5 m, centres x = +-11.4) with cream-white
##   plastered walls, large yellow panel fields, a granite foot, a cornice
##   band, a framed window with green shutters on the front and outer
##   faces, and a black hipped tile roof carrying a small square cupola
##   with its own pyramid cap (eaves 6 m, top 10.6 m).
## - Between them a concave semicircular wall (radius 7.6 m, 3.4 m high) in
##   the same cream and yellow: rectangular yellow wall panels, two arched
##   doorways each side with arch surrounds, a coping with yellow posts
##   and an iron railing. At the back, centred on the hill, the central
##   bay: pilasters, a shell-headed niche with a bronze bust on a granite
##   pedestal, a pediment and a three-step flight.
## - Two yellow gate pillars with black pyramid caps at x = +-5.3 carrying
##   a black wrought-iron arch with the cream SKANSEN lettering following
##   the curve, and two white flagpoles beside them (15.5 m) flying the
##   Swedish and the Skansen flag.
## Pole height is scaled from the photos (about 1.6 times the pavilion).

const PX := 11.4
const PZ := -1.55
const PW := 7.5
const WALL_R := 7.6
const WALL_ZC := -1.0
const WALL_H := 3.4
const TOP := 15.5

static func build(model: Node3D) -> void:
	var mats := {
		"Wall": LandmarkMaterials.pbr("render", "#EFE9D8", 3.0),
		"Yellow": LandmarkMaterials.pbr("render", "#E2B964", 3.0),
		"Stone": LandmarkMaterials.pbr("stone", "#7A6B66", 2.5),
		"Roof": LandmarkMaterials.pbr("slate", "#2C2E33", 3.0, 0.5, 0.2),
		"Frame": LandmarkMaterials.paint("#EFE9D8"),
		"Green": LandmarkMaterials.paint("#47623F"),
		"Glass": LandmarkMaterials.glass("#20282D"),
		"Metal": LandmarkMaterials.paint("#1C1D20", 0.5, 0.5),
		"Letter": LandmarkMaterials.paint("#E7D9AE", 0.6, 0.0),
		"Pole": LandmarkMaterials.paint("#F4F2EA", 0.5, 0.2),
		"Bronze": LandmarkMaterials.pbr("copper", "#4A4235", 2.0, 0.5, 0.6),
		"Blue": LandmarkMaterials.paint("#0B58A8", 0.7, 0.0),
		"Yellowflag": LandmarkMaterials.paint("#F2C515", 0.7, 0.0),
		"Green2": LandmarkMaterials.paint("#2F6B3A", 0.7, 0.0),
	}
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	var win := StoDjurgKit.unit(mats, 1.3, 2.2, false, 0.2)
	for s in [-1.0, 1.0]:
		_pavilion(lm, mats, win, PX * float(s), float(s))
	_wall(lm, mats)
	_centre(lm)
	_gate(lm)
	lm.commit(model)

static func _pavilion(lm: LandmarkMesh, _mats: Dictionary, win: LandmarkMesh, cx: float, sg: float) -> void:
	var hw := PW * 0.5
	var eave := 6.0
	lm.box("Stone", Vector3(cx, 0.35, PZ), Vector3(PW + 0.3, 0.7, PW + 0.3), Basis(), 0.0)
	LandmarkFhUtil.blk(lm, "Wall", cx, 0.7, PZ, PW, eave - 0.7, PW)
	lm.box("Wall", Vector3(cx, eave - 0.15, PZ), Vector3(PW + 0.5, 0.3, PW + 0.5), Basis(), 0.0)
	# Front (+Z) and outer (x * sg) faces: yellow field, framed window, shutters.
	for face in [Vector3(0, 0, 1), Vector3(sg, 0, 0)]:
		var n: Vector3 = face
		var side := Vector3.UP.cross(n)
		var basis := Basis(side, Vector3.UP, n)
		var c := Vector3(cx, 0, PZ) + n * (hw + 0.03)
		lm.box("Yellow", c + Vector3(0, 3.1, 0), Vector3(5.6, 3.7, 0.06), basis, 0.0)
		lm.box("Yellow", c + Vector3(0, 0.95, 0), Vector3(5.6, 0.5, 0.06), basis, 0.0)
		StoChurchKit.place(lm, win, c + Vector3(0, 2.1, 0) + n * 0.02, n)
		for s in [-1.0, 1.0]:
			lm.box("Green", c + side * float(s) * 1.25 + Vector3(0, 3.2, 0) + n * 0.08, Vector3(0.6, 2.2, 0.08), basis, 0.0)
	# Black hipped roof with a small cupola.
	LandmarkFhUtil.hip(lm, "Roof", Vector3(cx, eave, PZ), PW + 1.2, PW + 1.2, 2.7, 0.3)
	var cb := Vector3(cx, eave + 2.7, PZ)
	lm.box("Roof", cb + Vector3(0, 0.55, 0), Vector3(2.2, 1.1, 2.2), Basis(), 0.0)
	lm.spire("Roof", cb + Vector3(0, 1.1, 0), 1.35, 0.9, 0.0)

static func _arc_pt(theta: float, r: float) -> Vector3:
	return Vector3(r * cos(theta), 0.0, WALL_ZC - r * sin(theta))

## The concave wall: panels, doorways, coping, posts and railing.
static func _wall(lm: LandmarkMesh, _mats: Dictionary) -> void:
	var n_seg := 28
	for i in n_seg:
		var t0 := PI * float(i) / float(n_seg)
		var t1 := PI * float(i + 1) / float(n_seg)
		var p0 := _arc_pt(t0, WALL_R + 0.35)
		var p1 := _arc_pt(t1, WALL_R + 0.35)
		var d := p1 - p0
		var mid := (p0 + p1) * 0.5
		var basis := Basis(Vector3.UP, atan2(d.x, d.z))
		lm.box("Wall", mid + Vector3(0, WALL_H * 0.5, 0), Vector3(0.7, WALL_H, d.length() * 1.03), basis, 0.0)
		lm.box("Stone", mid + Vector3(0, 0.2, 0) + _inward(t0 + (t1 - t0) * 0.5) * 0.05, Vector3(0.9, 0.4, d.length() * 1.03), basis, 0.0)
		# Coping and the railing rail above it.
		lm.box("Wall", mid + Vector3(0, WALL_H + 0.1, 0), Vector3(0.95, 0.2, d.length() * 1.03), basis, 0.0)
		var q0 := p0 + Vector3(0, WALL_H + 0.2, 0)
		var q1 := p1 + Vector3(0, WALL_H + 0.2, 0)
		lm.beam("Metal", q0 + Vector3(0, 0.85, 0), q1 + Vector3(0, 0.85, 0), 0.05, 0.05)
		lm.beam("Metal", q0 + Vector3(0, 0.3, 0), q1 + Vector3(0, 0.3, 0), 0.04, 0.04)
		if i % 2 == 0:
			lm.box("Yellow", q0 + Vector3(0, 0.45, 0), Vector3(0.55, 0.9, 0.55), basis, 0.0)
	# Yellow rectangular panels on the inner face, clear of the doorways and the centre.
	for deg in [52.0, 66.0, 80.0, 100.0, 114.0, 128.0]:
		var t := deg_to_rad(deg)
		var inn := _inward(t)
		var c := _arc_pt(t, WALL_R) + inn * 0.01 + Vector3(0, 1.95, 0)
		lm.box("Yellow", c, Vector3(0.05, 1.6, 2.0), Basis(Vector3.UP, atan2(-inn.z, inn.x)), 0.0)
	# Two arched doorways each side, with arch surrounds.
	for deg in [12.0, 30.0, 150.0, 168.0]:
		var t := deg_to_rad(deg)
		var inn := _inward(t)
		var base := _arc_pt(t, WALL_R) + inn * 0.02
		LandmarkFhUtil.opening(lm, "Glass", base, inn, 1.6, 2.7, true)
		LandmarkDetail.arch(lm, "Yellow", base + Vector3(0, 1.9, 0), inn, 1.9, 0.3, 0.14, 12)
		for s in [-1.0, 1.0]:
			lm.box("Yellow", base + Vector3.UP.cross(inn) * float(s) * 1.05 + Vector3(0, 1.0, 0),
				Vector3(0.3, 2.0, 0.16), Basis(Vector3.UP.cross(inn), Vector3.UP, inn), 0.0)

static func _inward(t: float) -> Vector3:
	return Vector3(-cos(t), 0.0, sin(t))

## The central bay at the back of the wall: niche with the bust.
static func _centre(lm: LandmarkMesh) -> void:
	var z := WALL_ZC - WALL_R + 0.0
	var wallface := z + 0.0
	lm.box("Wall", Vector3(0, 2.8, wallface - 0.3), Vector3(5.6, 5.6, 1.0), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Yellow", Vector3(float(s) * 2.35, 2.2, wallface + 0.24), Vector3(0.55, 4.4, 0.12), Basis(), 0.0)
	lm.box("Yellow", Vector3(0, 3.4, wallface + 0.22), Vector3(3.6, 4.4, 0.08), Basis(), 0.0)
	LandmarkFhUtil.opening(lm, "Glass", Vector3(0, 0.9, wallface + 0.28), Vector3.BACK, 2.2, 3.7, true)
	LandmarkDetail.arch(lm, "Wall", Vector3(0, 3.5, wallface + 0.26), Vector3.BACK, 2.6, 0.3, 0.14, 12)
	lm.lathe("Yellow", Vector3(0, 4.3, wallface + 0.32), PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.9, 0.1), Vector2(0.0, 0.9)]), 10, 1.0, 0.25, 0.0, false)
	# Entablature and the small curved pediment.
	lm.box("Wall", Vector3(0, 5.15, wallface + 0.15), Vector3(5.9, 0.45, 1.3), Basis(), 0.0)
	lm.gable("Wall", Vector3(0, 5.35, wallface + 0.1), 3.6, 0.9, 0.8, Basis(), 0.1, "Yellow")
	# Bust on a granite pedestal, three steps to the forecourt.
	lm.box("Stone", Vector3(0, 0.9, wallface + 1.2), Vector3(0.9, 1.8, 0.9), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 1.85, wallface + 1.2), Vector3(1.1, 0.14, 1.1), Basis(), 0.0)
	lm.box("Bronze", Vector3(0, 2.2, wallface + 1.2), Vector3(0.5, 0.55, 0.35), Basis(), 0.0)
	lm.lathe("Bronze", Vector3(0, 2.5, wallface + 1.2), LandmarkFhUtil.ball(0.22), 8)
	LandmarkFhUtil.steps(lm, "Stone", Vector3(0, 0, wallface + 0.4), Vector3.BACK, 3.4, 0.4, 0.14, 3)

## Pillars, the iron arch with its lettering, the flagpoles.
static func _gate(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var sg: float = s
		var x := 5.3 * sg
		lm.box("Stone", Vector3(x, 0.3, 2.0), Vector3(1.9, 0.6, 1.9), Basis(), 0.0)
		lm.box("Yellow", Vector3(x, 1.9, 2.0), Vector3(1.55, 2.6, 1.55), Basis(), 0.0)
		lm.box("Wall", Vector3(x, 3.3, 2.0), Vector3(1.8, 0.3, 1.8), Basis(), 0.0)
		lm.spire("Roof", Vector3(x, 3.45, 2.0), 1.0, 1.1, 0.0)
		# Flagpole behind the pillar.
		lm.lathe("Pole", Vector3(x * 1.15, 0, 3.0), PackedVector2Array([
			Vector2(0.14, 0.0), Vector2(0.09, TOP - 0.3)]), 8)
		lm.lathe("Pole", Vector3(x * 1.15, TOP - 0.3, 3.0), LandmarkFhUtil.ball(0.14), 8)
		var fk := "Blue" if sg < 0.0 else "Green2"
		var fx := x * 1.15
		lm.box(fk, Vector3(fx + sg * 0.9, TOP - 1.3, 3.0), Vector3(1.8, 1.1, 0.04), Basis(), 0.0)
		if sg < 0.0:
			lm.box("Yellowflag", Vector3(fx + sg * 0.55, TOP - 1.3, 3.0), Vector3(0.3, 1.1, 0.06), Basis(), 0.0)
			lm.box("Yellowflag", Vector3(fx + sg * 0.9, TOP - 1.3, 3.0), Vector3(1.8, 0.3, 0.06), Basis(), 0.0)
	# Arch: two parallel curved members, legs from the pillars, struts.
	var z := 2.0
	var prev_lo := Vector3.ZERO
	var prev_hi := Vector3.ZERO
	var n := 24
	for i in n + 1:
		var x := lerpf(-5.3, 5.3, float(i) / float(n))
		var y := 4.1 + 4.0 * (1.0 - (x / 5.3) * (x / 5.3))
		var lo := Vector3(x, y, z)
		var hi := Vector3(x, y + 2.0, z)
		if i > 0:
			lm.beam("Metal", prev_lo, lo, 0.13, 0.16, Vector3.BACK)
			lm.beam("Metal", prev_hi, hi, 0.13, 0.16, Vector3.BACK)
		if i % 2 == 0:
			lm.beam("Metal", lo, hi, 0.07, 0.08, Vector3.BACK)
		prev_lo = lo
		prev_hi = hi
	for s in [-5.3, 5.3]:
		lm.beam("Metal", Vector3(float(s), 3.45, z), Vector3(float(s), 4.15, z), 0.16, 0.16)
	_lettering(lm, z)

# Stroke font in a 0.7 x 1.0 cell: letters S K A N S E N.
const GLYPHS := {
	"S": [[0.7, 0.85, 0.35, 1.0], [0.35, 1.0, 0.0, 0.8], [0.0, 0.8, 0.35, 0.52], [0.35, 0.52, 0.7, 0.28],
		[0.7, 0.28, 0.35, 0.0], [0.35, 0.0, 0.0, 0.15]],
	"K": [[0.0, 0.0, 0.0, 1.0], [0.7, 1.0, 0.0, 0.45], [0.2, 0.62, 0.7, 0.0]],
	"A": [[0.0, 0.0, 0.35, 1.0], [0.35, 1.0, 0.7, 0.0], [0.12, 0.35, 0.58, 0.35]],
	"N": [[0.0, 0.0, 0.0, 1.0], [0.0, 1.0, 0.7, 0.0], [0.7, 0.0, 0.7, 1.0]],
	"E": [[0.0, 0.0, 0.0, 1.0], [0.0, 1.0, 0.7, 1.0], [0.0, 0.5, 0.55, 0.5], [0.0, 0.0, 0.7, 0.0]],
}

## Cream letters riding the iron arch, each turned to the curve.
static func _lettering(lm: LandmarkMesh, z: float) -> void:
	var word := "SKANSEN"
	var letter_h := 1.5
	for i in word.length():
		var x := (float(i) - 3.0) * 1.38
		var y := 4.1 + 4.0 * (1.0 - (x / 5.3) * (x / 5.3)) + 0.25
		var slope := -8.0 * x / 28.09
		var tang := Vector3(1, slope, 0).normalized()
		var up := Vector3(-tang.y, tang.x, 0)
		var org := Vector3(x, y, z) - tang * 0.52 * letter_h * 0.7
		for seg in GLYPHS[word[i]]:
			var a: Array = seg
			var p0 := org + tang * (float(a[0]) * letter_h) + up * (float(a[1]) * letter_h)
			var p1 := org + tang * (float(a[2]) * letter_h) + up * (float(a[3]) * letter_h)
			lm.beam("Letter", p0, p1, 0.2, 0.24, Vector3.BACK)
