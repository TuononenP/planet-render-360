extends RefCounted

## Ursa Observatory (Ursan tahtitorni, Kaivopuisto; the 1830s Engel-period
## pavilion the Ursa association now runs). A small round building, not the
## hipped box the first massing model made it.
##
## From the Commons photos in visual-plan/refs/landmarks/ursa_observatory/:
## - a round drum of pale yellow render on a grey concrete plinth with two
##   steps to a black door in a white frame (the door faces +Z, south);
## - eight white pilasters with plain capitals round the drum, white round
##   medallions between them, and a stepped white entablature with a dark
##   line and a small clock dial;
## - a tall ribbed dome of dark patinated copper, bulging at the lower
##   third, with a ball and a short spike on top.
##
## Measured: the position and the 5.4 m diameter of the drum (OSM way
## 23571010, a 19-node circle). The old registry point was 380 m away. The
## heights (plinth 0.9 m, drum to 4.3 m, entablature to 5.9 m, dome crown to
## 9.1 m, ball tip at 9.6 m) are scaled from the photographs and are
## uncertain by about 0.5 m; the old registry height of 15 m was an error.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "ursa_observatory", "name": "Ursa Observatory", "lat": 60.155496, "lon": 24.95544,
	"radius_m": 1500.0, "wiki_title": "Ursa Astronomical Association", "height_m": 9.6, "clear_m": 10.0,
	"kind": "Observatory", "aliases": ["ursa observatory", "ursan observatorio", "ursas observatorium"]}

const R := 2.7
const PLINTH := 0.9
const WALL := 4.3
const CORNICE := 5.9
const SEG := 24

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#EBD688", 3.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#F4F2EA", 2.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#8B8984", 3.0))
	lm.use("Dome", LandmarkMaterials.paint("#3A362F", 0.5, 0.5))
	lm.use("Door", LandmarkMaterials.paint("#1E2022", 0.6, 0.3))
	lm.frustum("Concrete", Vector3.ZERO, R + 0.35, R + 0.25, PLINTH, SEG)
	lm.frustum("Render", Vector3(0, PLINTH, 0), R, R, WALL - PLINTH, SEG)
	# Eight pilasters with capitals, medallions between them.
	for k in 8:
		var a := deg_to_rad(22.5 + 45.0 * float(k))
		var d := Vector3(sin(a), 0, cos(a))
		var basis := Basis(Vector3.UP, a)
		lm.box("White", d * (R + 0.04) + Vector3(0, (PLINTH + WALL - 0.3) * 0.5, 0), Vector3(0.7, WALL - PLINTH - 0.3, 0.3), basis, 0.0)
		lm.box("White", d * (R + 0.1) + Vector3(0, WALL - 0.2, 0), Vector3(0.95, 0.25, 0.4), basis, 0.0)
		var m := deg_to_rad(45.0 * float(k + 1))
		var md := Vector3(sin(m), 0, cos(m))
		P.ring(lm, "White", md * (R + 0.01) + Vector3(0, 3.2, 0), md, 0.0, 0.5, 0.1, 14)
		P.ring(lm, "White", md * (R + 0.01) + Vector3(0, 3.2, 0), md, 0.5, 0.6, 0.14, 14)
	# Door and frame, two concrete steps.
	var door := Vector3(0, PLINTH, R)
	lm.box("Door", door + Vector3(0, 1.0, 0.04), Vector3(1.0, 2.0, 0.14))
	lm.box("White", door + Vector3(0, 2.1, 0.06), Vector3(1.4, 0.2, 0.2))
	for s: float in [-1.0, 1.0]:
		lm.box("White", door + Vector3(s * 0.62, 1.05, 0.06), Vector3(0.16, 2.1, 0.2))
	U.steps(lm, "Concrete", Vector3(0, 0, R + 0.2), Vector3.BACK, 2.4, 0.45, 0.45, 2)
	# Entablature: frieze, a dark line, the cornice courses.
	lm.frustum("White", Vector3(0, WALL, 0), R + 0.15, R + 0.15, 1.1, SEG)
	lm.frustum("Door", Vector3(0, WALL + 1.1, 0), R + 0.18, R + 0.18, 0.08, SEG)
	lm.frustum("White", Vector3(0, WALL + 1.18, 0), R + 0.2, R + 0.2, 0.3, SEG)
	lm.frustum("White", Vector3(0, CORNICE - 0.4, 0), R + 0.45, R + 0.45, 0.2, SEG)
	lm.frustum("White", Vector3(0, CORNICE - 0.2, 0), R + 0.2, R + 0.5, 0.2, SEG)
	# Ribbed copper dome, bulging in the lower third.
	var prof := PackedVector2Array([Vector2(2.55, 0), Vector2(2.75, 0.35), Vector2(2.78, 0.9), Vector2(2.55, 1.6),
		Vector2(2.05, 2.2), Vector2(1.35, 2.65), Vector2(0.6, 2.95), Vector2(0.15, 3.1), Vector2(0, 3.15)])
	var base := Vector3(0, CORNICE, 0)
	lm.lathe("Dome", base, prof, SEG)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 2:
			lm.beam("Dome", base + d * (prof[j].x + 0.03) + Vector3(0, prof[j].y, 0),
				base + d * (prof[j + 1].x + 0.03) + Vector3(0, prof[j + 1].y, 0), 0.09, 0.08, d.cross(Vector3.UP))
	lm.lathe("Dome", base + Vector3(0, 3.1, 0), U.ball(0.3), 12)
	lm.beam("Dome", base + Vector3(0, 3.6, 0), base + Vector3(0, 3.7, 0), 0.05)
	lm.commit(model)
