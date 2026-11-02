class_name LandmarkCasino
extends RefCounted

## Monte Carlo Casino (Gobineau de la Bretonnerie 1863; Dutrou and
## Garnier 1878-81) in true metres: a cream stone Beaux-Arts block with
## a rusticated ground floor, round-arched first-floor windows between
## paired Ionic columns, a dentilled cornice and balustraded attic with
## urns, under verdigris copper mansards pierced by oeil-de-boeuf
## dormers. On the square side (−Z, Place du Casino) the entrance
## pavilion with its glass marquee, the clock under a sculpture group,
## two flanking towers with copper belvedere roofs and lanterns, and
## the central copper cupola behind; on the sea side (+Z, over the
## terraces) the Salle Garnier front between its own two square towers
## and the balustraded terrace.

const TOP_M := 34.0
const BLOCK := Vector3(80.0, 18.0, 46.0)
const GROUND_M := 7.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E9DFC8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F3ECDC", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#2C3438"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var hx := BLOCK.x * 0.5
	var hz := BLOCK.z * 0.5
	lm.box("Stone", Vector3(0, BLOCK.y * 0.5, 0), BLOCK)
	# Rusticated ground floor: channelled courses round the block.
	for k in 5:
		var y := 1.0 + 1.4 * k
		lm.box("Trim", Vector3(0, y, 0), Vector3(BLOCK.x + 0.5, 0.25, BLOCK.z + 0.5), Basis(), 0.0)
	lm.box("Trim", Vector3(0, 0.4, 0), Vector3(BLOCK.x + 0.8, 0.8, BLOCK.z + 0.8))
	lm.box("Trim", Vector3(0, GROUND_M, 0), Vector3(BLOCK.x + 1.0, 0.8, BLOCK.z + 1.0))
	# Entablature, dentilled cornice and balustraded attic.
	lm.box("Trim", Vector3(0, BLOCK.y - 0.8, 0), Vector3(BLOCK.x + 0.6, 1.6, BLOCK.z + 0.6))
	var corners := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	for i in 4:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		var out := (a + b).normalized()
		var y := Vector3(0, BLOCK.y, 0)
		LandmarkDetail.cornice(lm, "Trim", a + y + out * 0.3, b + y + out * 0.3, out, 1.0)
		var ins := -out * 0.4 + Vector3(0, BLOCK.y + 1.0, 0)
		_attic_rail(lm, a + ins + (b - a).normalized() * 1.0, b + ins - (b - a).normalized() * 1.0)
	lm.box("Stone", Vector3(0, BLOCK.y + 0.5, 0), Vector3(BLOCK.x - 1.0, 1.0, BLOCK.z - 1.0))
	# Mansard: steep lower slope then a low cap, copper, with dormers.
	lm.lathe("Copper", Vector3(0, BLOCK.y + 1.0, 0), PackedVector2Array([Vector2(sqrt(2.0) * 0.96, 0),
		Vector2(sqrt(2.0) * 0.84, 4.5), Vector2(sqrt(2.0) * 0.7, 6.0)]), 4, hx, hz, PI * 0.25, false)
	for s in [-1.0, 1.0]:
		for k in 8:
			var x := -hx + 10.0 + 8.6 * k
			_oeil(lm, Vector3(x, BLOCK.y + 3.0, s * (hz * 0.9 - 1.0)), Vector3(0, 0, s))
	# The long fronts: arched windows and paired columns; ground-floor
	# windows with their keystones.
	for s in [-1.0, 1.0]:
		var n := Vector3(0, 0, s)
		for k in 11:
			var x := -hx + 5.0 + 7.0 * k
			var z: float = s * hz
			LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 3.8, z), n, 2.2, 4.0, false, 0.3)
			LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 12.3, z), n, 2.6, 6.0, true, 0.3)
			if k < 10:
				for c in [-1.0, 1.0]:
					_column(lm, Vector3(x + 3.5 + c * 0.7, GROUND_M + 0.4, s * (hz + 0.6)), 0.34, 8.6)
		lm.box("Trim", Vector3(0, GROUND_M + 0.6, s * (hz + 0.5)), Vector3(BLOCK.x, 0.4, 1.4))
	for s in [-1.0, 1.0]:
		for k in 6:
			var z := -hz + 4.0 + 7.6 * k
			LandmarkDetail.window(lm, "Trim", "Windows", Vector3(s * hx, 12.3, z), Vector3(s, 0, 0), 2.6, 6.0, true, 0.3)
			LandmarkDetail.window(lm, "Trim", "Windows", Vector3(s * hx, 3.8, z), Vector3(s, 0, 0), 2.2, 4.0, false, 0.3)
	# Sea front: the two towers and the balustraded terrace.
	for s in [-1.0, 1.0]:
		_tower(lm, Vector3(s * (hx - 5.0), 0, hz - 3.0), Vector3(0, 0, 1))
	lm.box("Trim", Vector3(0, 0.4, hz + 9.0), Vector3(BLOCK.x + 10.0, 0.8, 18.0))
	_attic_rail(lm, Vector3(-hx - 4.5, 0.8, hz + 17.6), Vector3(hx + 4.5, 0.8, hz + 17.6))
	for s in [-1.0, 1.0]:
		_attic_rail(lm, Vector3(s * (hx + 4.6), 0.8, hz + 1.0), Vector3(s * (hx + 4.6), 0.8, hz + 17.4))
	_square_front(lm, hz)
	lm.commit(model)

## Square side: entrance pavilion with arched doorway, glass marquee,
## the clock under a sculpture group and pediment, two flanking towers,
## and the copper cupola rising behind.
static func _square_front(lm: LandmarkMesh, hz: float) -> void:
	var ec := Vector3(0, 0, -hz - 2.0)
	var n := Vector3(0, 0, -1)
	lm.box("Stone", ec + Vector3(0, 12.0, 0), Vector3(22.0, 24.0, 6.0))
	lm.box("Trim", ec + Vector3(0, GROUND_M, -0.1), Vector3(22.6, 0.8, 6.4))
	lm.box("Windows", ec + Vector3(0, 4.0, -3.05), Vector3(5.6, 7.0, 0.1))
	LandmarkDetail.arch(lm, "Trim", ec + Vector3(0, 6.0, -3.0), n, 5.6, 0.7, 0.4)
	# Glass and iron marquee over the doors.
	lm.box("Gilt", ec + Vector3(0, 5.4, -6.0), Vector3(12.0, 0.25, 6.0))
	lm.box("Windows", ec + Vector3(0, 5.8, -6.0), Vector3(11.6, 0.15, 5.6), Basis(Vector3.RIGHT, 0.12), 0.0)
	for x in [-5.6, 5.6]:
		lm.beam("Gilt", ec + Vector3(float(x), 5.4, -8.8), ec + Vector3(float(x), 7.8, -3.0), 0.18, 0.18)
	# First floor: the great arched window between columns.
	LandmarkDetail.window(lm, "Trim", "Windows", ec + Vector3(0, 12.8, -3.0), n, 4.4, 7.0, true, 0.4)
	for x in [-6.2, -4.4, 4.4, 6.2]:
		_column(lm, ec + Vector3(float(x), GROUND_M + 0.4, -3.6), 0.42, 9.6)
	lm.box("Trim", ec + Vector3(0, 18.6, -3.2), Vector3(16.0, 1.2, 1.2))
	# Clock with its gilt surround, the pediment and sculpture group.
	lm.disc("Gilt", ec + Vector3(0, 21.0, -3.12), n, 1.6, 24)
	lm.disc("Trim", ec + Vector3(0, 21.0, -3.16), n, 1.3, 24)
	for k in 12:
		var a := TAU * k / 12.0
		lm.box("Gilt", ec + Vector3(cos(a) * 1.1, 21.0 + sin(a) * 1.1, -3.2), Vector3(0.12, 0.12, 0.06), Basis(), 0.0)
	lm.gable("Trim", ec + Vector3(0, 24.0, -2.0), 22.0, 2.0, 3.0, Basis(), 0.4, "Stone")
	for s in [-1.0, 1.0]:
		LandmarkKits.statue_figure(lm, "Trim", ec + Vector3(s * 2.2, 22.6, -3.4), 2.4, s > 0.0)
	LandmarkKits.statue_figure(lm, "Trim", ec + Vector3(0, 27.0, -2.4), 2.2, true)
	for s in [-1.0, 1.0]:
		_tower(lm, Vector3(s * 16.0, 0, -hz + 2.0), n)
	# Central cupola behind the pavilion.
	var cc := Vector3(0, BLOCK.y + 1.0, -hz + 9.0)
	lm.frustum("Stone", cc, 6.0, 6.0, 4.0, 24)
	for k in 8:
		var a := TAU * (k + 0.5) / 8.0
		lm.disc("Windows", cc + Vector3(cos(a) * 6.02, 2.0, sin(a) * 6.02), Vector3(cos(a), 0, sin(a)), 0.9, 12)
	lm.frustum("Trim", cc + Vector3(0, 3.8, 0), 6.4, 6.4, 0.5, 24)
	lm.lathe("Copper", cc + Vector3(0, 4.3, 0), PackedVector2Array([Vector2(6.4, 0),
		Vector2(6.0, 2.0), Vector2(4.6, 4.4), Vector2(2.4, 6.0), Vector2(0.0, 6.6)]), 24)
	for k in 12:
		var a := TAU * k / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Copper", cc + d * 6.5 + Vector3(0, 4.3, 0), cc + d * 4.7 + Vector3(0, 8.7, 0), 0.25, 0.2)
		lm.beam("Copper", cc + d * 4.7 + Vector3(0, 8.7, 0), cc + d * 2.4 + Vector3(0, 10.3, 0), 0.25, 0.2)
	lm.frustum("Gilt", cc + Vector3(0, 10.6, 0), 0.3, 0.05, 2.0, 6)

## A front tower: stone shaft with corner pilasters, an arched window
## and an oculus on each face, cornice and balustrade, then the copper
## belvedere roof (convex pavilion with ribs), lantern and gilt finial.
static func _tower(lm: LandmarkMesh, tc: Vector3, front: Vector3) -> void:
	lm.box("Stone", tc + Vector3(0, 13.0, 0), Vector3(10.0, 26.0, 10.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Trim", tc + Vector3(sx * 4.8, 13.0, sz * 4.8), Vector3(1.0, 26.0, 1.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var n := r * Vector3(0, 0, 1)
		LandmarkDetail.window(lm, "Trim", "Windows", tc + n * 5.0 + Vector3(0, 20.6, 0), n, 2.0, 4.6, true, 0.3)
		lm.disc("Gilt", tc + n * 5.05 + Vector3(0, 25.0, 0), n, 0.8, 16)
		lm.disc("Windows", tc + n * 5.08 + Vector3(0, 25.0, 0), n, 0.55, 12)
	lm.box("Trim", tc + Vector3(0, 26.4, 0), Vector3(11.0, 0.8, 11.0))
	lm.lathe("Copper", tc + Vector3(0, 26.8, 0), PackedVector2Array([Vector2(7.4, 0), Vector2(7.0, 1.0),
		Vector2(5.6, 2.6), Vector2(3.6, 3.8), Vector2(2.2, 4.6)]), 4, 1.0, 1.0, PI * 0.25, false)
	for k in 4:
		var a := PI * 0.5 * k + PI * 0.25
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Gilt", tc + d * 7.3 + Vector3(0, 26.9, 0), tc + d * 2.3 + Vector3(0, 31.4, 0), 0.22, 0.18)
	# Lantern: four little arched openings, cap and finial.
	lm.frustum("Copper", tc + Vector3(0, 31.4, 0), 1.5, 1.3, 1.2, 8)
	for k in 4:
		var a := PI * 0.5 * k
		lm.box("Windows", tc + Vector3(cos(a) * 1.42, 32.0, sin(a) * 1.42), Vector3(0.6, 0.9, 0.08),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	lm.frustum("Gilt", tc + Vector3(0, 32.6, 0), 0.4, 0.05, TOP_M - 32.6, 6)
	if front.z < 0.0:
		LandmarkKits.statue_figure(lm, "Trim", tc + front * 5.6 + Vector3(0, GROUND_M + 0.4, 0), 2.4)

## Paired-column shaft: a plain Ionic column of radius r, height h.
static func _column(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.box("Trim", base + Vector3(0, 0.3, 0), Vector3(r * 2.8, 0.6, r * 2.8))
	lm.lathe("Trim", base + Vector3(0, 0.6, 0), PackedVector2Array([Vector2(r * 1.15, 0), Vector2(r, 0.2),
		Vector2(r, h * 0.4), Vector2(r * 0.88, h - 1.4), Vector2(r * 1.1, h - 1.2), Vector2(r * 1.3, h - 0.9)]), 12)
	lm.box("Trim", base + Vector3(0, h - 0.6, 0), Vector3(r * 3.0, 0.5, r * 2.4))

## An oeil-de-boeuf dormer on the mansard: round window in a stone
## surround under a little copper hood.
static func _oeil(lm: LandmarkMesh, c: Vector3, n: Vector3) -> void:
	var r := Basis.looking_at(-n)
	lm.box("Stone", c + Vector3(0, 0.6, 0), Vector3(2.4, 2.4, 1.6), r)
	lm.disc("Trim", c + Vector3(0, 0.7, 0) + n * 0.82, n, 1.0, 16)
	lm.disc("Windows", c + Vector3(0, 0.7, 0) + n * 0.85, n, 0.7, 16)
	lm.gable("Copper", c + Vector3(0, 1.8, 0), 2.4, 1.6, 0.9, r, 0.15, "Stone")

## Attic balustrade seen from the street: plinth, rail, a pedestal
## carrying an urn every 7 m, and turned balusters 0.6 m apart.
static func _attic_rail(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var dl := a.distance_to(b)
	lm.box("Trim", (a + b) * 0.5 + Vector3(0, 0.1, 0), Vector3(dl, 0.2, 0.5), basis, 0.0)
	lm.box("Trim", (a + b) * 0.5 + Vector3(0, 1.0, 0), Vector3(dl, 0.2, 0.55), basis, 0.0)
	var vase := PackedVector2Array([Vector2(0.09, 0), Vector2(0.15, 0.3), Vector2(0.07, 0.8)])
	var n := int(dl / 0.6)
	for i in n:
		lm.lathe("Trim", a.lerp(b, (i + 0.5) / n) + Vector3(0, 0.2, 0), vase, 6)
	var piers := maxi(1, int(dl / 7.0))
	for i in piers + 1:
		var p := a.lerp(b, float(i) / piers)
		lm.box("Trim", p + Vector3(0, 0.6, 0), Vector3(0.6, 1.2, 0.6), basis)
		lm.lathe("Trim", p + Vector3(0, 1.2, 0), PackedVector2Array([Vector2(0.15, 0), Vector2(0.3, 0.3),
			Vector2(0.28, 0.6), Vector2(0.12, 0.8), Vector2(0.0, 0.95)]), 8)
