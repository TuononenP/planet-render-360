class_name LandmarkWaterlooArch
extends RefCounted

## Waterloo's Victory Arch (1919-22), the station's main entrance and
## the London and South Western Railway's war memorial: Portland stone
## Imperial Baroque on a butterfly plan at the corner of York Road and
## Mepham Street. A broad flight with bronze balustrades climbs from the
## street to the concourse through a round arch between paired columns
## on pedestals; seated groups for 1914 and 1918 over the entablature,
## a clock in the attic, and Britannia with her torch on top. Canted
## wings of offices step back on both sides.

const D := preload("res://scripts/generation/landmarks/west_europe/landmark_waterloo_data.gd")
const MASS_Y := 20.5
const ATTIC_Y := 21.4
## Opening of the arch: span and springing.
const SPAN := 7.2
const SPRING_Y := D.PLAT_Y + 7.0
const ENTABLATURE_Y := 16.6
## Flight up from the street: steps, rise and tread.
const STEPS := 15
const TREAD := 0.4
const FLIGHT_W := 12.0
## Britannia's pedestal top and her height (to the crown; her torch's
## flame tops out at 1.53 of it, the registry height).
const BRITANNIA_Y := 22.4
const BRITANNIA_H := 3.0

static func victory_arch(lm: LandmarkMesh) -> void:
	var p1 := D.ARCH[1]
	var p2 := D.ARCH[2]
	var mid := (p1 + p2) * 0.5
	var r2 := (p2 - p1).normalized()
	var n2 := D.outward(p1, p2, D.ARCH)
	var r := Vector3(r2.x, 0, r2.y)
	var n := Vector3(n2.x, 0, n2.y)
	var at := func(x: float, y: float, d: float) -> Vector3:
		return D.v3(mid, y) + r * x + n * d
	var basis := Basis(r, Vector3.UP, n)
	lm.poly_prism("Stone", D.ARCH, 0.0, MASS_Y)
	_wing(lm, D.ARCH[0], D.ARCH[1])
	_wing(lm, D.ARCH[2], D.ARCH[3])
	_flight(lm, at, basis)
	_archway(lm, at, basis, n)
	_attic(lm, at, basis, n)
	_figure(lm, at.call(-5.7, ENTABLATURE_Y + 1.6, 0.9), n, r, 2.6, false)
	_figure(lm, at.call(5.7, ENTABLATURE_Y + 1.6, 0.9), n, r, 2.6, false)
	lm.box("Stone", at.call(0.0, ATTIC_Y + 0.5, -0.4), Vector3(3.2, 1.0, 2.6), basis)
	_figure(lm, at.call(0.0, BRITANNIA_Y, -0.4), n, r, BRITANNIA_H, true)

## The street flight: stone steps and the bronze balustrades with their
## lamp standards at the foot.
static func _flight(lm: LandmarkMesh, at: Callable, basis: Basis) -> void:
	var rise := D.PLAT_Y / float(STEPS)
	var run := TREAD * float(STEPS)
	for k in STEPS:
		var depth := run - TREAD * float(k)
		lm.box("Stone", at.call(0.0, rise * (float(k) + 0.5), depth * 0.5), Vector3(FLIGHT_W, rise, depth), basis, 0.0)
	for s in [-1.0, 1.0]:
		var x: float = float(s) * (FLIGHT_W * 0.5 - 0.3)
		lm.box("Rustic", at.call(x, D.PLAT_Y * 0.5, run * 0.5), Vector3(0.6, D.PLAT_Y, run), basis, 0.0)
		lm.beam("Bronze", at.call(x, 1.0, run), at.call(x, D.PLAT_Y + 1.0, 0.3), 0.14, 0.14)
		for k in 9:
			var t := float(k) / 8.0
			var foot: Vector3 = at.call(x, rise + (D.PLAT_Y - rise) * t, run - (run - 0.3) * t)
			lm.beam("Bronze", foot, foot + Vector3.UP * 1.0, 0.07, 0.07)
		var lamp: Vector3 = at.call(x, 0.0, run + 0.4)
		lm.lathe("Bronze", lamp, PackedVector2Array([Vector2(0.35, 0.0), Vector2(0.25, 0.5), Vector2(0.09, 0.8),
			Vector2(0.07, 3.4), Vector2(0.16, 3.5)]), 10)
		lm.lathe("Clock", lamp + Vector3(0, 3.5, 0), PackedVector2Array([Vector2(0.05, 0.0), Vector2(0.24, 0.12),
			Vector2(0.28, 0.32), Vector2(0.18, 0.55), Vector2(0.0, 0.6)]), 12)

## The arch: dark opening, archivolt with keystone, the paired Doric
## columns on pedestals, the entablature with its lettered frieze.
static func _archway(lm: LandmarkMesh, at: Callable, basis: Basis, n: Vector3) -> void:
	var h := SPAN * 0.5
	lm.quad("Recess", at.call(-h, D.PLAT_Y, 0.02), at.call(h, D.PLAT_Y, 0.02), at.call(h, SPRING_Y, 0.02),
		at.call(-h, SPRING_Y, 0.02), n)
	var c: Vector3 = at.call(0.0, SPRING_Y, 0.02)
	var r := basis.x
	for i in 16:
		var a0 := PI * float(i) / 16.0
		var a1 := PI * float(i + 1) / 16.0
		lm.tri("Recess", c, c + (r * cos(a0) + Vector3.UP * sin(a0)) * h, c + (r * cos(a1) + Vector3.UP * sin(a1)) * h,
			n, n, n, Vector2.ZERO, Vector2(cos(a0), sin(a0)), Vector2(cos(a1), sin(a1)))
	LandmarkDetail.arch(lm, "Stone", at.call(0.0, SPRING_Y, 0.06), n, SPAN, 0.9, 0.5)
	# Imposts and the reveal piers.
	for s in [-1.0, 1.0]:
		var x: float = float(s) * (h + 0.45)
		lm.box("Stone", at.call(x, (D.PLAT_Y + SPRING_Y) * 0.5, 0.2), Vector3(0.9, SPRING_Y - D.PLAT_Y, 0.4), basis)
		lm.box("Stone", at.call(x, SPRING_Y + 0.2, 0.3), Vector3(1.3, 0.4, 0.6), basis)
		for cx in [4.9, 6.6]:
			var px: float = float(s) * float(cx)
			lm.box("Stone", at.call(px, D.PLAT_Y + 1.0, 0.8), Vector3(1.3, 2.0, 1.3), basis)
			LandmarkDetail.column(lm, "Stone", at.call(px, D.PLAT_Y + 2.0, 0.8), 0.42, ENTABLATURE_Y - 0.6 - D.PLAT_Y - 2.0,
				"doric", 20, 12)
		# The groups' dates under them.
		lm.quad("Recess", at.call(x * 1.28 - 0.9, ENTABLATURE_Y - 0.3, 1.42), at.call(x * 1.28 + 0.9, ENTABLATURE_Y - 0.3, 1.42),
			at.call(x * 1.28 + 0.9, ENTABLATURE_Y + 0.2, 1.42), at.call(x * 1.28 - 0.9, ENTABLATURE_Y + 0.2, 1.42), n)
	lm.box("Stone", at.call(0.0, ENTABLATURE_Y, 0.7), Vector3(15.6, 1.2, 1.4), basis)
	lm.quad("Recess", at.call(-3.4, ENTABLATURE_Y - 0.25, 1.42), at.call(3.4, ENTABLATURE_Y - 0.25, 1.42),
		at.call(3.4, ENTABLATURE_Y + 0.25, 1.42), at.call(-3.4, ENTABLATURE_Y + 0.25, 1.42), n)
	LandmarkDetail.cornice(lm, "Stone", at.call(-7.8, ENTABLATURE_Y + 0.6, 1.4), at.call(7.8, ENTABLATURE_Y + 0.6, 1.4),
		n, 0.9, true)

## The attic over the arch: the clock between scrolls, the parapet.
static func _attic(lm: LandmarkMesh, at: Callable, basis: Basis, n: Vector3) -> void:
	lm.box("Stone", at.call(0.0, (ENTABLATURE_Y + 1.5 + ATTIC_Y) * 0.5, 0.4),
		Vector3(9.0, ATTIC_Y - ENTABLATURE_Y - 1.5, 1.0), basis)
	var dial: Vector3 = at.call(0.0, 19.6, 0.92)
	lm.disc("Bronze", dial, n, 1.35, 28)
	lm.disc("Clock", dial + n * 0.03, n, 1.1, 28)
	lm.beam("Recess", dial + n * 0.06, dial + n * 0.06 + Vector3.UP * 0.85, 0.08, 0.03)
	lm.beam("Recess", dial + n * 0.06, dial + n * 0.06 + basis.x * 0.6, 0.1, 0.03)
	for s in [-1.0, 1.0]:
		var x: float = float(s) * 3.4
		lm.lathe("Stone", at.call(x, ENTABLATURE_Y + 1.5, 1.0), PackedVector2Array([Vector2(0.6, 0.0),
			Vector2(0.7, 0.6), Vector2(0.45, 1.6), Vector2(0.2, 2.4), Vector2(0.35, 3.0), Vector2(0.0, 3.2)]), 10, 0.6, 1.0)
	LandmarkDetail.cornice(lm, "Stone", at.call(-4.6, ATTIC_Y - 0.6, 0.9), at.call(4.6, ATTIC_Y - 0.6, 0.9), n, 0.6, false)

## A canted wing a-b of the arch block: rusticated base, three storeys
## of windows, cornice and balustrade.
static func _wing(lm: LandmarkMesh, a: Vector2, b: Vector2) -> void:
	var o := D.outward(a, b, D.ARCH)
	var dir := (b - a).normalized()
	var out := Vector3(o.x, 0, o.y)
	var right := Vector3(dir.x, 0, dir.y)
	var basis := Basis(right, Vector3.UP, out)
	var w := a.distance_to(b)
	var mid := (a + b) * 0.5
	for k in int(D.PLAT_Y / 0.75):
		var depth := 0.45 if k % 2 == 0 else 0.35
		lm.box("Rustic", D.v3(mid, 0.375 + 0.75 * float(k)) + out * depth * 0.5, Vector3(w, 0.7, depth), basis, 0.0)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", D.v3(a, D.PLAT_Y + 0.5), right, out, w, MASS_Y - 2.0 - D.PLAT_Y,
		maxi(int(w / 3.6), 1), 3, Vector2(1.5, 2.5), 1.0, 4.1, 0.3)
	LandmarkDetail.cornice(lm, "Stone", D.v3(a, MASS_Y - 1.3) + out * 0.3, D.v3(b, MASS_Y - 1.3) + out * 0.3,
		out, 1.0, true)
	LandmarkDetail.balustrade(lm, "Stone", D.v3(a, MASS_Y) + out * 0.2, D.v3(b, MASS_Y) + out * 0.2, 1.0, 3.5, 6)

## A seated stone figure at `base` facing `face`: a draped lap and
## torso, head, a shield at her side and an arm raised; Britannia's
## (`torch`) holds a torch whose gilded flame ends 1.53 h up.
static func _figure(lm: LandmarkMesh, base: Vector3, face: Vector3, side: Vector3, h: float, torch: bool) -> void:
	var basis := Basis(side, Vector3.UP, face)
	lm.box("Stone", base + Vector3.UP * h * 0.13 + face * h * 0.1, Vector3(h * 0.5, h * 0.26, h * 0.5), basis)
	lm.lathe("Stone", base + Vector3.UP * h * 0.22 - face * h * 0.04, PackedVector2Array([Vector2(h * 0.2, 0.0),
		Vector2(h * 0.18, h * 0.2), Vector2(h * 0.13, h * 0.42), Vector2(h * 0.07, h * 0.55)]), 12, 1.0, 0.75)
	var neck := base + Vector3.UP * h * 0.77 - face * h * 0.04
	lm.lathe("Stone", neck, PackedVector2Array([Vector2(0.0, 0.0), Vector2(h * 0.05, h * 0.02),
		Vector2(h * 0.065, h * 0.07), Vector2(h * 0.05, h * 0.12), Vector2(0.0, h * 0.14)]), 10)
	lm.disc("Stone", base + Vector3.UP * h * 0.4 - side * h * 0.24, -side, h * 0.17, 16)
	var shoulder := base + Vector3.UP * h * 0.7 + side * h * 0.13
	var hand := base + Vector3.UP * h * 0.95 + side * h * 0.2 + face * h * 0.05
	lm.beam("Stone", shoulder, hand, h * 0.07, h * 0.07)
	if torch:
		var top := base + Vector3.UP * h * 1.25 + side * h * 0.2 + face * h * 0.05
		lm.beam("Bronze", hand, top, h * 0.04, h * 0.04)
		lm.lathe("Gold", top, PackedVector2Array([Vector2(h * 0.07, 0.0), Vector2(h * 0.09, h * 0.08),
			Vector2(h * 0.05, h * 0.18), Vector2(0.0, h * 0.28)]), 10)
		# Her helmet's crest.
		lm.box("Stone", neck + Vector3.UP * h * 0.16, Vector3(h * 0.03, h * 0.06, h * 0.14), basis)
