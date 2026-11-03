class_name LandmarkSsRoyal2
extends RefCounted

## Three Stockholm churches in true metres, each built in the frame of
## its OpenStreetMap outline (origin at the outline's centroid) and
## turned onto the map by the registry yaw_deg:
##   Storkyrkan (way 8049504, yaw -15: the nave runs to 75 degrees) -
##     the five-aisled brick hall church given its uniform Baroque
##     exterior by J. E. Carlberg in 1736-1743: 65.5 x 37.2 m under one
##     great copper roof, pilaster-buttressed sides with tall round-headed
##     windows, the dressed east gable to Slottsbacken, and the west
##     tower (main portal in its base) with corner quoins, four clocks,
##     the belfry stage and a pediment on each face, its chamfered
##     terrace and the lantern of timber clad in copper - painted deep
##     red again in 2022 - in two open stages under bell caps, with the
##     gilt orb and crown, 63 m to the tip.
##   Katarina Church (way 37079169, yaw -15) - Jean de la Vallée's Greek
##     cross (1656-1695), 50 x 50 m: arms 21.4 m wide under gabled
##     roofs with dressed end gables, four small corner towers in the
##     re-entrant angles, and Adelcrantz's octagonal crossing tower with
##     its bell-shaped copper dome and lantern, 72 m above the ground;
##     yellow with grey pilasters (the 1784 scheme), rebuilt after the
##     fire of 17 May 1990 and reopened in 1995 with 5000 m2 of new
##     copper, now darkened.
##   Hedvig Eleonora Church (way 27741605, yaw 22.5: the axis runs to
##     112.5 degrees) - the octagonal centralised church (de la Vallée,
##     completed by G. J. Adelcrantz, 1737), 40.6 m across the flats,
##     with pediments on its four axial faces, the two low burial vaults
##     at the west front (towers begun 1755, never finished), the copper
##     roof rising to the tall drum, and Scholander's ribbed copper dome
##     of 1866-1868 with dormers and the lantern, 59 m to the cross.
## Sources: the OpenStreetMap ways above (outlines, height tags: 63 m,
## 59 m), Wikipedia "Storkyrkan" (63 x 37.2 m, west tower and portal,
## east front), svenskakyrkan.se (Storkyrkan lantern of copper-clad
## timber, deep red since 2022, light warm pink tower), Swedish
## Wikipedia "Katarina kyrka" (Greek cross, 72 m tower, four smaller
## towers, colours, 1990 fire) and "Hedvig Eleonora kyrka" (octagonal
## plan, dome 1866-1868, west burial vaults).

const STORKYRKAN_TOP_M := 63.0
const KATARINA_TOP_M := 72.0
const HEDVIG_TOP_M := 59.0
## Octagon circumradius per unit apothem: 1 / cos(PI / 8).
const K8 := 1.0823922

static func _keys(lm: LandmarkMesh, wall: String, trim: String, copper: String) -> void:
	lm.use("Wall", LandmarkMaterials.pbr("render", wall, 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", trim, 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A29A8D", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", copper, 2.0, 0.55, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#1E2427"))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#2E2A26", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())

## Box in a face frame: x along `r`, y up, d out along `o` from `a`.
static func _fb(lm: LandmarkMesh, key: String, a: Vector3, r: Vector3, o: Vector3, x: float, y: float,
		d: float, size: Vector3) -> void:
	lm.box(key, a + r * x + Vector3.UP * y + o * d, size, Basis(r, Vector3.UP, o), 0.0)

## Half disc of radius `rad` standing on its diameter at `c` in the
## plane facing `o` (the head of a round-arched opening).
static func _half_disc(lm: LandmarkMesh, key: String, c: Vector3, r: Vector3, o: Vector3, rad: float) -> void:
	for i in 10:
		var t0 := PI * float(i) / 10.0
		var t1 := PI * float(i + 1) / 10.0
		lm.tri(key, c, c + (r * cos(t0) + Vector3.UP * sin(t0)) * rad, c + (r * cos(t1) + Vector3.UP * sin(t1)) * rad,
			o, o, o, Vector2.ZERO, Vector2(cos(t0), sin(t0)) * rad, Vector2(cos(t1), sin(t1)) * rad)

## A wall skin from `a` along `r` (`length` x `height`) facing `o` with
## `n` round-headed windows: openings `w` wide from `sill` for `h` with
## real reveals, the glazed head, a stone archivolt and sill each. The
## bays listed in `skip` stay blind.
static func _arched_row(lm: LandmarkMesh, wall: String, a: Vector3, r: Vector3, o: Vector3, length: float,
		height: float, n: int, sill: float, w: float, h: float, skip: Array = []) -> void:
	var pitch := length / float(n)
	if skip.is_empty():
		LandmarkDetail.pierced_face(lm, wall, "Glass", a, r, o, length, height, n, 1, Vector2(w, h), sill, height, 0.4)
	else:
		for i in n:
			if i in skip:
				_fb(lm, wall, a, r, o, pitch * (float(i) + 0.5), height * 0.5, 0.2, Vector3(pitch, height, 0.4))
			else:
				LandmarkDetail.pierced_face(lm, wall, "Glass", a + r * pitch * float(i), r, o, pitch, height, 1, 1,
					Vector2(w, h), sill, height, 0.4)
	for i in n:
		if i in skip:
			continue
		var x := pitch * (float(i) + 0.5)
		var spring := a + r * x + Vector3.UP * (sill + h)
		_half_disc(lm, "Glass", spring + o * 0.41, r, o, w * 0.5)
		LandmarkDetail.arch(lm, "Trim", spring + o * 0.4, o, w, clampf(w * 0.13, 0.2, 0.45), 0.2, 12)
		_fb(lm, "Trim", a, r, o, x, sill - 0.12, 0.5, Vector3(w + 0.5, 0.24, 0.2))

## Pilaster strips at the `n` + 1 bay lines of a face from y0 to y1,
## with a base block and a capital each.
static func _pilasters(lm: LandmarkMesh, key: String, a: Vector3, r: Vector3, o: Vector3, length: float, n: int,
		y0: float, y1: float, w: float) -> void:
	for k in n + 1:
		var x := clampf(length * float(k) / float(n), w * 0.5, length - w * 0.5)
		_fb(lm, key, a, r, o, x, (y0 + y1) * 0.5, 0.55, Vector3(w, y1 - y0, 0.3))
		_fb(lm, key, a, r, o, x, y0 + 0.3, 0.6, Vector3(w + 0.3, 0.6, 0.4))
		_fb(lm, key, a, r, o, x, y1 - 0.3, 0.62, Vector3(w + 0.4, 0.6, 0.45))

## An arched doorway at `x` on a face: dark leaf `w` x `h` to the
## springing, its head, a stone surround and a cornice over it.
static func _door(lm: LandmarkMesh, a: Vector3, r: Vector3, o: Vector3, x: float, w: float, h: float,
		d: float = 0.4) -> void:
	_fb(lm, "Dark", a, r, o, x, h * 0.5, d + 0.05, Vector3(w, h, 0.1))
	_half_disc(lm, "Dark", a + r * x + Vector3.UP * h + o * (d + 0.1), r, o, w * 0.5)
	LandmarkDetail.arch(lm, "Trim", a + r * x + Vector3.UP * h + o * d, o, w, 0.45, 0.3, 12)
	for s in [-1.0, 1.0]:
		_fb(lm, "Trim", a, r, o, x + float(s) * (w * 0.5 + 0.5), h * 0.5 + 0.6, d + 0.2, Vector3(0.6, h + 1.2, 0.4))
	_fb(lm, "Trim", a, r, o, x, h + w * 0.5 + 0.9, d + 0.3, Vector3(w + 2.4, 0.4, 0.6))

## Baroque dressing of a gable end facing `o` whose eave line is
## centred at `c` (half width `hw`, `rise` to the apex): raking
## cornices, pilasters stopped under the slopes, an oculus, scrolls at
## the foot of each slope and urns on the corners and the apex.
static func _gable_end(lm: LandmarkMesh, c: Vector3, o: Vector3, hw: float, rise: float) -> void:
	var r := Vector3.UP.cross(o)
	var apex := c + Vector3.UP * rise + o * 0.25
	for s in [-1.0, 1.0]:
		lm.beam("Trim", c + r * float(s) * (hw + 0.4) + o * 0.25 + Vector3.UP * 0.15, apex + Vector3.UP * 0.35, 0.7,
			0.5, o)
		# Scroll: a quarter-round of beams at the foot of the slope.
		var sc := c + r * float(s) * (hw - 1.2) + o * 0.3 + Vector3.UP * 0.6
		var prev := sc + r * float(s) * 1.2
		for k in 6:
			var t := PI * 0.5 * float(k + 1) / 6.0
			var p := sc + r * float(s) * cos(t) * 1.2 + Vector3.UP * sin(t) * 1.2
			lm.beam("Trim", prev, p, 0.35, 0.4, o)
			prev = p
		lm.lathe("Trim", c + r * float(s) * (hw - 0.2) + Vector3.UP * 0.5, _urn(1.4), 8)
	lm.box("Trim", c + o * 0.2 + Vector3.UP * 0.3, Vector3(2.0 * hw + 0.6, 0.6, 0.4), Basis(r, Vector3.UP, o), 0.0)
	for k in [-0.62, -0.22, 0.22, 0.62]:
		var x: float = float(k) * hw
		var top := rise * (1.0 - absf(float(k))) - 0.8
		lm.box("Trim", c + r * x + Vector3.UP * (0.6 + top * 0.5) + o * 0.12, Vector3(0.9, top, 0.25),
			Basis(r, Vector3.UP, o), 0.0)
	var oc := c + Vector3.UP * rise * 0.42 + o * 0.06
	var orad := minf(rise * 0.13, 1.8)
	lm.disc("Glass", oc, o, orad, 16)
	var prev_o := oc + r * (orad + 0.2)
	for k in 16:
		var t := TAU * float(k + 1) / 16.0
		var p := oc + (r * cos(t) + Vector3.UP * sin(t)) * (orad + 0.2)
		lm.beam("Trim", prev_o, p, 0.35, 0.3, o)
		prev_o = p
	lm.lathe("Trim", apex + Vector3.UP * 0.5, _urn(1.6), 8)

## Urn / vase profile `h` tall.
static func _urn(h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(h * 0.18, 0), Vector2(h * 0.1, h * 0.1), Vector2(h * 0.24, h * 0.32),
		Vector2(h * 0.26, h * 0.5), Vector2(h * 0.12, h * 0.68), Vector2(h * 0.16, h * 0.76), Vector2(0.0, h)])

## Octagon (flats facing the axes) of apothem `ap` round `c`, as XZ.
static func _oct(c: Vector3, ap: float) -> PackedVector2Array:
	var poly := PackedVector2Array()
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * float(k)
		poly.append(Vector2(c.x + cos(a) * ap * K8, c.z + sin(a) * ap * K8))
	return poly

## Open octagonal lantern of apothem `ap` from `base` for `h`: dark core
## with arched openings on every face between corner posts, sill and
## cornice rings.
static func _lantern(lm: LandmarkMesh, key: String, base: Vector3, ap: float, h: float) -> void:
	lm.poly_prism("Dark", _oct(base, ap * 0.82), base.y, base.y + h)
	lm.frustum(key, base, ap * K8 + 0.25, ap * K8 + 0.25, 0.5, 8, PI / 8.0)
	lm.frustum(key, base + Vector3.UP * (h - 0.6), ap * K8 + 0.35, ap * K8 + 0.35, 0.6, 8, PI / 8.0)
	var side := 2.0 * ap * tan(PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box(key, base + d * ap * K8 + Vector3.UP * h * 0.5, Vector3(0.45, h, 0.45), Basis(Vector3.UP, -a), 0.0)
		var fa := a + PI / 8.0
		var o := Vector3(cos(fa), 0, sin(fa))
		var r := Vector3.UP.cross(o)
		var fc := base + o * ap
		# Spandrel band over the arched opening.
		lm.box(key, fc + Vector3.UP * (h - 1.3), Vector3(side, 1.4, 0.3), Basis(r, Vector3.UP, o), 0.0)
		LandmarkDetail.arch(lm, key, fc + Vector3.UP * (h - 1.4 - side * 0.3), o, side * 0.6, 0.2, 0.2, 9)

## A small open crown of radius `r`: band and four arches with points.
static func _crown(lm: LandmarkMesh, base: Vector3, r: float) -> void:
	lm.frustum("Gilt", base, r, r * 1.15, r * 0.6, 12)
	for k in 4:
		var a := TAU * float(k) / 4.0
		var p := base + Vector3(cos(a) * r * 1.1, r * 0.6, sin(a) * r * 1.1)
		lm.beam("Gilt", p, base + Vector3(0, r * 1.5, 0), r * 0.18, r * 0.18)
		lm.frustum("Gilt", p, r * 0.16, 0.0, r * 0.5, 4)
	lm.lathe("Gilt", base + Vector3(0, r * 1.4, 0), LandmarkFhUtil.ball(r * 0.25), 8)

## A gilt cross `h` tall standing on `base`.
static func _cross(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.box("Gilt", base + Vector3.UP * h * 0.5, Vector3(h * 0.08, h, h * 0.08), Basis(), 0.0)
	lm.box("Gilt", base + Vector3.UP * h * 0.68, Vector3(h * 0.5, h * 0.08, h * 0.08), Basis(), 0.0)

# --- Storkyrkan -------------------------------------------------------

static func storkyrkan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_keys(lm, "#E0C0A6", "#EEE5D6", "#6E9C88")
	lm.use("Tower", LandmarkMaterials.pbr("render", "#E8C5B1", 3.0))
	lm.use("Lantern", LandmarkMaterials.paint("#7C2D25", 0.5, 0.35))
	var x0 := -32.5
	var x1 := 33.0
	var hz := 18.6
	var eave := 17.0
	var length := x1 - x0
	lm.box("Wall", Vector3((x0 + x1) * 0.5, eave * 0.5, 0), Vector3(length, eave, 2.0 * hz), Basis(), 0.0)
	lm.box("Stone", Vector3((x0 + x1) * 0.5, 0.6, 0), Vector3(length + 1.0, 1.2, 2.0 * hz + 1.0))
	# Long sides: eight bays of round-headed windows between the
	# buttresses treated as pilasters; the north door and two south doors.
	for s in [-1.0, 1.0]:
		var o := Vector3(0, 0, float(s))
		var r := Vector3.UP.cross(o)
		var a := Vector3(x0 if r.x > 0.0 else x1, 0, float(s) * hz)
		_arched_row(lm, "Wall", a + Vector3.UP * 1.2, r, o, length, eave - 2.2, 8, 4.0, 3.0, 7.0)
		_pilasters(lm, "Trim", a, r, o, length, 8, 1.2, eave - 1.0, 1.5)
		LandmarkDetail.cornice(lm, "Trim", a + Vector3.UP * (eave - 1.0) + o * 0.4,
			a + r * length + Vector3.UP * (eave - 1.0) + o * 0.4, o, 1.0, false)
		var bay := length / 8.0
		for b in ([3] if s < 0.0 else [2, 5]):
			_door(lm, a, r, o, bay * (float(b) + 0.5), 1.8, 3.2, 0.6)
	# The great copper roof over all five aisles: ridge roll, seams.
	var along := Basis(Vector3.UP, PI * 0.5)
	var rise := 11.0
	lm.gable("Copper", Vector3((x0 + x1) * 0.5, eave, 0), 2.0 * hz, length, rise, along, 0.6, "Wall")
	lm.box("Copper", Vector3((x0 + x1) * 0.5, eave + rise + 0.15, 0), Vector3(length + 0.6, 0.4, 0.5), Basis(), 0.0)
	var seams := int(length / 1.6)
	for k in seams + 1:
		var x := x0 + length * float(k) / float(seams)
		for sz in [-1.0, 1.0]:
			lm.beam("Copper", Vector3(x, eave - 0.07, float(sz) * (hz + 0.6)), Vector3(x, eave + rise + 0.08, 0), 0.08,
				0.1)
	# Dormers in two rows down both slopes.
	for k in 5:
		var x := x0 + 12.0 + 10.0 * float(k)
		for sz in [-1.0, 1.0]:
			var dc := Vector3(x, eave + rise * 0.4, float(sz) * hz * 0.6)
			var fb := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
			lm.box("Copper", dc + Vector3.UP * 0.8, Vector3(1.6, 1.6, 2.4), fb)
			lm.box("Glass", dc + fb * Vector3(0, 0.8, 1.22), Vector3(0.9, 0.9, 0.05), fb, 0.0)
			lm.gable("Copper", dc + Vector3.UP * 1.6, 1.6, 2.4, 0.7, fb, 0.1, "Copper")
	# East front to Slottsbacken: three tall windows, pilasters, gable.
	var ea := Vector3(x1, 0, hz)
	var er := Vector3.FORWARD
	var eo := Vector3.RIGHT
	_arched_row(lm, "Wall", ea + Vector3.UP * 1.2, er, eo, 2.0 * hz, eave - 2.2, 3, 3.6, 3.4, 7.6)
	_pilasters(lm, "Trim", ea, er, eo, 2.0 * hz, 3, 1.2, eave - 1.0, 1.6)
	LandmarkDetail.cornice(lm, "Trim", ea + Vector3.UP * (eave - 1.0) + eo * 0.4,
		ea + er * 2.0 * hz + Vector3.UP * (eave - 1.0) + eo * 0.4, eo, 1.0, false)
	_gable_end(lm, Vector3(x1, eave, 0), eo, hz, rise)
	lm.box("Stone", Vector3(x1 + 0.45, 3.0, 0), Vector3(0.1, 1.6, 2.6), Basis(), 0.0)
	# West front either side of the tower.
	for side in [[-hz, -9.0], [6.8, hz]]:
		var za: float = side[0]
		var zb: float = side[1]
		var wa := Vector3(x0, 0, za)
		_arched_row(lm, "Wall", wa + Vector3.UP * 1.2, Vector3.BACK, Vector3.LEFT, zb - za, eave - 2.2, 1, 4.0, 3.0, 7.0)
		_pilasters(lm, "Trim", wa, Vector3.BACK, Vector3.LEFT, zb - za, 1, 1.2, eave - 1.0, 1.5)
	_gable_end(lm, Vector3(x0, eave, 0), Vector3.LEFT, hz, rise)
	# Palmstedt's stair tower on the south side of the tower.
	lm.box("Wall", Vector3(-30.0, 7.0, 9.0), Vector3(5.4, 14.0, 4.6), Basis(), 0.0)
	lm.spire("Copper", Vector3(-30.0, 14.0, 9.0), 3.0, 2.2, 0.0)
	_sk_tower(lm, Vector3(-26.8, 0, -1.1), 7.8)
	lm.commit(model)

## Storkyrkan's west tower on centre `tc`, half width `tw`: stone
## plinth, quoined shaft in three stages to 34 m with the main portal,
## a window and clock on each face, paired louvred belfry openings, the
## entablature and a pediment per face; the chamfered terrace with its
## railing, and the red lantern: octagonal base with oculi, bell cap,
## open lantern, ogee cap, small lantern and cone, gilt orb and crown.
static func _sk_tower(lm: LandmarkMesh, tc: Vector3, tw: float) -> void:
	var ttop := 34.0
	lm.box("Tower", tc + Vector3.UP * ttop * 0.5, Vector3(2.0 * tw, ttop, 2.0 * tw), Basis(), 0.0)
	lm.box("Stone", tc + Vector3.UP * 0.6, Vector3(2.0 * tw + 0.8, 1.2, 2.0 * tw + 0.8))
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var o: Vector3 = rb * Vector3.BACK
		var r: Vector3 = rb * Vector3.RIGHT
		var a := tc + o * tw - r * tw
		# Quoins: long and short blocks alternating up both corners.
		for k in int((ttop - 2.2) / 1.1):
			var y := 1.2 + 1.1 * float(k) + 0.5
			var qw := 1.8 if (k + f) % 2 == 0 else 1.2
			_fb(lm, "Trim", a, r, o, qw * 0.5, y, 0.1, Vector3(qw, 0.95, 0.2))
			_fb(lm, "Trim", a, r, o, 2.0 * tw - qw * 0.5, y, 0.1, Vector3(qw, 0.95, 0.2))
		for y in [17.0, 27.0]:
			_fb(lm, "Trim", a, r, o, tw, float(y), 0.2, Vector3(2.0 * tw + 0.4, 0.6, 0.4))
		# Middle stage: a round-headed window and the clock above it.
		_fb(lm, "Dark", a, r, o, tw, 20.2, 0.04, Vector3(1.6, 2.8, 0.08))
		_half_disc(lm, "Dark", a + r * tw + Vector3.UP * 21.6 + o * 0.09, r, o, 0.8)
		LandmarkDetail.arch(lm, "Trim", a + r * tw + Vector3.UP * 21.6, o, 1.6, 0.25, 0.2, 10)
		var cc := a + r * tw + Vector3.UP * 24.6 + o * 0.12
		lm.disc("Trim", cc, o, 1.7, 20)
		lm.disc("Dark", cc + o * 0.03, o, 1.45, 20)
		lm.beam("Gilt", cc + o * 0.08, cc + o * 0.08 + Vector3.UP * 1.1, 0.12, 0.05, r)
		lm.beam("Gilt", cc + o * 0.1, cc + o * 0.1 + r * 0.8, 0.1, 0.05, Vector3.UP)
		# Belfry: paired louvred openings.
		for s in [-1.0, 1.0]:
			var x := tw + float(s) * 3.0
			_fb(lm, "Dark", a, r, o, x, 29.8, 0.04, Vector3(1.8, 3.6, 0.08))
			_half_disc(lm, "Dark", a + r * x + Vector3.UP * 31.6 + o * 0.09, r, o, 0.9)
			LandmarkDetail.arch(lm, "Trim", a + r * x + Vector3.UP * 31.6, o, 1.8, 0.3, 0.2, 10)
			for m in 5:
				_fb(lm, "Tower", a, r, o, x, 28.4 + 0.7 * float(m), 0.1, Vector3(1.8, 0.12, 0.16))
		# Entablature and pediment.
		_fb(lm, "Trim", a, r, o, tw, ttop - 0.5, 0.25, Vector3(2.0 * tw + 0.6, 1.0, 0.5))
		var pl := a + r * 0.3 + Vector3.UP * ttop + o * 0.2
		var pr := a + r * (2.0 * tw - 0.3) + Vector3.UP * ttop + o * 0.2
		var pa := a + r * tw + Vector3.UP * (ttop + 2.8) + o * 0.2
		lm.tri("Tower", pl, pr, pa, o, o, o, Vector2.ZERO, Vector2(2.0 * tw, 0), Vector2(tw, -2.8))
		lm.tri("Tower", pl - o * 0.6, pr - o * 0.6, pa - o * 0.6, -o, -o, -o, Vector2.ZERO, Vector2(2.0 * tw, 0),
			Vector2(tw, -2.8))
		for e in [pl, pr]:
			var ev: Vector3 = e
			lm.beam("Trim", ev + o * 0.05, pa + o * 0.05 + Vector3.UP * 0.2, 0.5, 0.7, o)
		lm.lathe("Trim", pa - o * 0.3 + Vector3.UP * 0.2, _urn(1.2), 8)
	# Main portal in the tower's west face.
	_door(lm, tc + Vector3(-tw, 0, tw), Vector3.FORWARD, Vector3.LEFT, tw, 2.8, 4.6, 0.0)
	# Terrace with chamfered corners and its railing.
	var tb := tc + Vector3.UP * ttop
	lm.frustum("Tower", tb, tw * K8 * 0.98, tw * K8 * 0.98, 0.6, 8, PI / 8.0)
	for k in 8:
		var a0 := PI / 8.0 + PI * 0.25 * float(k)
		var a1 := a0 + PI * 0.25
		var p0 := tb + Vector3(cos(a0), 0, sin(a0)) * (tw * K8 - 0.6) + Vector3.UP * 0.6
		var p1 := tb + Vector3(cos(a1), 0, sin(a1)) * (tw * K8 - 0.6) + Vector3.UP * 0.6
		lm.beam("Lantern", p0 + Vector3.UP * 1.0, p1 + Vector3.UP * 1.0, 0.12, 0.12)
		for m in 7:
			var p := p0.lerp(p1, (float(m) + 0.5) / 7.0)
			lm.box("Lantern", p + Vector3.UP * 0.5, Vector3(0.08, 1.0, 0.08), Basis(), 0.0)
	# The red lantern.
	var ly := ttop + 0.6
	var lb := tc + Vector3.UP * ly
	lm.frustum("Lantern", lb, 5.4 * K8, 5.2 * K8, 4.2, 8, PI / 8.0)
	for k in 4:
		var a := PI * 0.5 * float(k)
		var o := Vector3(cos(a), 0, sin(a))
		lm.disc("Dark", lb + o * 5.35 + Vector3.UP * 2.2, o, 0.8, 12)
		lm.disc("Gilt", lb + o * 5.3 + Vector3.UP * 2.2, o, 1.0, 12)
	lm.frustum("Lantern", lb + Vector3.UP * 4.2, 5.6 * K8, 5.6 * K8, 0.4, 8, PI / 8.0)
	lm.lathe("Lantern", lb + Vector3.UP * 4.6, PackedVector2Array([Vector2(5.4 * K8, 0), Vector2(4.8 * K8, 1.6),
		Vector2(3.6 * K8, 3.2), Vector2(3.0 * K8, 4.4)]), 8, 1.0, 1.0, PI / 8.0, false)
	_lantern(lm, "Lantern", lb + Vector3.UP * 9.0, 2.9, 5.6)
	lm.lathe("Lantern", lb + Vector3.UP * 14.6, PackedVector2Array([Vector2(3.4 * K8, 0), Vector2(3.2 * K8, 0.8),
		Vector2(2.2 * K8, 2.0), Vector2(1.2 * K8, 3.0), Vector2(0.75 * K8, 3.8)]), 8, 1.0, 1.0, PI / 8.0, false)
	_lantern(lm, "Lantern", lb + Vector3.UP * 18.4, 0.8, 2.0)
	lm.lathe("Lantern", lb + Vector3.UP * 20.4, PackedVector2Array([Vector2(1.0, 0), Vector2(0.75, 0.6),
		Vector2(0.3, 2.0), Vector2(0.12, 2.7)]), 8, 1.0, 1.0, PI / 8.0, false)
	var oy := ly + 23.1
	lm.lathe("Gilt", tc + Vector3.UP * oy, LandmarkFhUtil.ball(0.55), 12)
	_crown(lm, tc + Vector3.UP * (oy + 1.15), 0.62)
	lm.frustum("Gilt", tc + Vector3.UP * (oy + 2.0), 0.07, 0.03, STORKYRKAN_TOP_M - oy - 2.0, 6)
	lm.beam("Gilt", tc + Vector3(0, STORKYRKAN_TOP_M - 0.8, 0), tc + Vector3(0.9, STORKYRKAN_TOP_M - 0.8, 0), 0.5,
		0.04, Vector3.UP)

# --- Katarina Church --------------------------------------------------

static func katarina(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_keys(lm, "#E8CB90", "#A9A69E", "#575B53")
	var arm := 10.7
	var reach := 25.0
	var core := 17.0
	var eave := 15.5
	var rise := 9.0
	lm.box("Wall", Vector3(0, eave * 0.5, 0), Vector3(2.0 * core, eave, 2.0 * core), Basis(), 0.0)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var o: Vector3 = rb * Vector3.BACK
		var r: Vector3 = rb * Vector3.RIGHT
		lm.box("Wall", rb * Vector3(0, eave * 0.5, (core + reach) * 0.5),
			(rb * Vector3(2.0 * arm, eave, reach - core)).abs(), Basis(), 0.0)
		lm.box("Stone", rb * Vector3(0, 0.6, reach * 0.5), (rb * Vector3(2.0 * arm + 1.0, 1.2, reach + 1.0)).abs(),
			Basis(), 0.0)
		# The arm's end front: two tall windows either side of the portal.
		var a := o * reach - r * arm
		_arched_row(lm, "Wall", a + Vector3.UP * 1.2, r, o, 2.0 * arm, eave - 2.2, 3, 4.6, 2.8, 6.0,
			[1] if f % 2 == 0 else [])
		_pilasters(lm, "Trim", a, r, o, 2.0 * arm, 3, 0.0, eave - 1.0, 1.3)
		LandmarkDetail.cornice(lm, "Trim", a + Vector3.UP * (eave - 1.0) + o * 0.4,
			a + r * 2.0 * arm + Vector3.UP * (eave - 1.0) + o * 0.4, o, 1.0, false)
		if f % 2 == 0:
			_door(lm, a, r, o, arm, 2.4, 3.8)
		else:
			lm.disc("Glass", a + r * arm + Vector3.UP * 12.4 + o * 0.42, o, 0.9, 12)
		# The arm's sides between the corner towers and the end.
		for s in [-1.0, 1.0]:
			var so: Vector3 = r * float(s)
			var sr := Vector3.UP.cross(so)
			var start := so * arm + o * (core if sr.dot(o) > 0.0 else reach)
			_arched_row(lm, "Wall", start + Vector3.UP * 1.2, sr, so, reach - core, eave - 2.2, 1, 4.6, 2.6, 6.0)
			_pilasters(lm, "Trim", start, sr, so, reach - core, 1, 0.0, eave - 1.0, 1.1)
		# Gabled roof along the arm, dressed end gable.
		lm.gable("Copper", rb * Vector3(0, eave, reach * 0.5), 2.0 * arm, reach, rise, rb, 0.5, "Wall")
		var run := reach
		var seams := int(run / 1.5)
		for k in seams + 1:
			var u := run * float(k) / float(seams)
			for s in [-1.0, 1.0]:
				lm.beam("Copper", rb * Vector3(float(s) * (arm + 0.5), eave - 0.1, u), rb * Vector3(0, eave + rise + 0.05, u),
					0.08, 0.1)
		_gable_end(lm, o * reach + Vector3.UP * eave, o, arm, rise)
		# Corner tower in the angle between this arm and the next.
		var cc := (o + r) * (arm + core) * 0.5
		_k_corner_tower(lm, cc, (core - arm) * 0.5, eave)
	_k_crossing(lm, eave)
	lm.commit(model)

## A small corner tower of half width `hw` at `cc`: square shaft with
## bands and small windows to 22 m, octagonal lantern, cupola, finial.
static func _k_corner_tower(lm: LandmarkMesh, cc: Vector3, hw: float, eave: float) -> void:
	var top := 22.0
	lm.box("Wall", cc + Vector3.UP * top * 0.5, Vector3(2.0 * hw, top, 2.0 * hw), Basis(), 0.0)
	lm.box("Stone", cc + Vector3.UP * 0.6, Vector3(2.0 * hw + 0.6, 1.2, 2.0 * hw + 0.6))
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var o: Vector3 = rb * Vector3.BACK
		var r: Vector3 = rb * Vector3.RIGHT
		var a := cc + o * hw - r * hw
		for y in [eave - 0.5, top - 0.6]:
			_fb(lm, "Trim", a, r, o, hw, float(y), 0.15, Vector3(2.0 * hw + 0.3, 0.7, 0.3))
		for s in [0.4, 2.0 * hw - 0.4]:
			_fb(lm, "Trim", a, r, o, float(s), top * 0.5, 0.1, Vector3(0.8, top - 1.0, 0.2))
		_fb(lm, "Glass", a, r, o, hw, 9.0, 0.03, Vector3(1.0, 1.8, 0.05))
		_fb(lm, "Glass", a, r, o, hw, 18.4, 0.03, Vector3(1.1, 2.2, 0.05))
	var b := cc + Vector3.UP * top
	lm.frustum("Copper", b, hw * 1.45, hw * 0.95, 1.2, 4, PI * 0.25)
	_lantern(lm, "Copper", b + Vector3.UP * 1.2, 1.5, 2.6)
	lm.lathe("Copper", b + Vector3.UP * 3.8, PackedVector2Array([Vector2(1.9, 0), Vector2(1.7, 0.9), Vector2(1.0, 1.9),
		Vector2(0.3, 2.6), Vector2(0.18, 3.6)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gilt", b + Vector3.UP * 7.4, LandmarkFhUtil.ball(0.3), 8)

## Adelcrantz's crossing tower: octagonal drum with round-headed windows
## in two tiers, corner pilasters and the crowning cornice, the bell-
## shaped octagonal copper dome with ribs and dormer oculi, the lantern,
## its cupola, spire, orb and cross to KATARINA_TOP_M.
static func _k_crossing(lm: LandmarkMesh, eave: float) -> void:
	var ap := 9.2
	var top := 40.5
	var c := Vector3.ZERO
	lm.poly_prism("Wall", _oct(c, ap), eave, top)
	var side := 2.0 * ap * tan(PI / 8.0)
	for k in 8:
		var ang := PI * 0.25 * float(k)
		var o := Vector3(cos(ang), 0, sin(ang))
		var r := Vector3.UP.cross(o)
		var a := c + o * ap - r * side * 0.5
		_arched_row(lm, "Wall", a + Vector3.UP * 25.0, r, o, side, top - 26.2, 1, 2.0, 2.4, 6.0)
		lm.disc("Glass", a + r * side * 0.5 + Vector3.UP * 37.0 + o * 0.42, o, 0.75, 12)
		_pilasters(lm, "Trim", a, r, o, side, 1, 24.0, top - 1.0, 1.0)
		_fb(lm, "Trim", a, r, o, side * 0.5, 24.6, 0.3, Vector3(side + 0.6, 0.6, 0.5))
		LandmarkDetail.cornice(lm, "Trim", a + Vector3.UP * (top - 1.0) + o * 0.4,
			a + r * side + Vector3.UP * (top - 1.0) + o * 0.4,
			o, 1.0, false)
	var db := c + Vector3.UP * top
	var prof := PackedVector2Array([Vector2(10.3, 0), Vector2(10.0, 2.6), Vector2(8.9, 6.4), Vector2(6.8, 9.8),
		Vector2(4.2, 12.3), Vector2(2.9, 13.6)])
	lm.lathe("Copper", db, prof, 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * float(k)
		for j in prof.size() - 1:
			lm.beam("Copper", db + Vector3(cos(a) * (prof[j].x + 0.1), prof[j].y, sin(a) * (prof[j].x + 0.1)),
				db + Vector3(cos(a) * (prof[j + 1].x + 0.1), prof[j + 1].y, sin(a) * (prof[j + 1].x + 0.1)), 0.4, 0.25)
		var fa := a + PI / 8.0
		var o := Vector3(cos(fa), 0, sin(fa))
		var dc := db + o * 8.1 + Vector3.UP * 4.6
		var fb := Basis(Vector3.UP, -fa + PI * 0.5)
		lm.box("Copper", dc, Vector3(1.6, 1.8, 1.4), fb)
		lm.disc("Glass", dc + o * 0.72, o, 0.55, 12)
	var lb := db + Vector3.UP * 13.6
	_lantern(lm, "Copper", lb, 2.6, 7.0)
	lm.lathe("Copper", lb + Vector3.UP * 7.0, PackedVector2Array([Vector2(3.1, 0), Vector2(2.9, 1.0), Vector2(1.9, 2.4),
		Vector2(0.7, 3.4), Vector2(0.45, 3.9)]), 8, 1.0, 1.0, PI / 8.0, false)
	var sy := top + 13.6 + 7.0 + 3.9
	lm.frustum("Copper", c + Vector3.UP * sy, 0.45, 0.08, 4.2, 8, PI / 8.0)
	lm.lathe("Gilt", c + Vector3.UP * (sy + 4.0), LandmarkFhUtil.ball(0.42), 10)
	_cross(lm, c + Vector3.UP * (sy + 4.8), KATARINA_TOP_M - sy - 4.8)

# --- Hedvig Eleonora Church -------------------------------------------

static func hedvig_eleonora(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_keys(lm, "#E2BE78", "#EFEBE1", "#6E9C88")
	var c := Vector3(2.25, 0, 0)
	var ap := 20.3
	var eave := 17.0
	var side := 2.0 * ap * tan(PI / 8.0)
	lm.poly_prism("Wall", _oct(c, ap), 0.0, eave)
	lm.poly_prism("Stone", _oct(c, ap + 0.4), 0.0, 1.2)
	for k in 8:
		var ang := PI * 0.25 * float(k)
		var o := Vector3(cos(ang), 0, sin(ang))
		var r := Vector3.UP.cross(o)
		var a := c + o * ap - r * side * 0.5
		var axial := k % 2 == 0
		var west := k == 4
		if axial:
			_arched_row(lm, "Wall", a + Vector3.UP * 1.2, r, o, side, eave - 2.2, 3, 5.4 if not west else 9.0, 2.2,
				5.6 if not west else 2.6, [1])
			lm.box("Glass", a + r * side * 0.5 + Vector3.UP * 9.2 + o * 0.41, Vector3(3.2, 6.4, 0.04),
				Basis(r, Vector3.UP, o), 0.0)
			_half_disc(lm, "Glass", a + r * side * 0.5 + Vector3.UP * 12.4 + o * 0.42, r, o, 1.6)
			LandmarkDetail.arch(lm, "Trim", a + r * side * 0.5 + Vector3.UP * 12.4 + o * 0.4, o, 3.2, 0.4, 0.25, 12)
			if west:
				_door(lm, a, r, o, side * 0.5, 2.6, 4.2)
			else:
				_door(lm, a, r, o, side * 0.5, 1.8, 3.0)
		else:
			_arched_row(lm, "Wall", a + Vector3.UP * 1.2, r, o, side, eave - 2.2, 2, 4.6, 2.4, 6.4)
		# Paired pilasters at the angles, plain between.
		for s in [0.55, 1.55, side - 1.55, side - 0.55]:
			_fb(lm, "Trim", a, r, o, float(s), eave * 0.5, 0.55, Vector3(0.8, eave - 1.2, 0.3))
		LandmarkDetail.cornice(lm, "Trim", a + Vector3.UP * (eave - 1.0) + o * 0.4,
			a + r * side + Vector3.UP * (eave - 1.0) + o * 0.4, o, 1.0, false)
		if axial:
			# Pediment over the axial face, its raking cornices and urn.
			var pl := a + r * 0.6 + Vector3.UP * eave + o * 0.3
			var pr := a + r * (side - 0.6) + Vector3.UP * eave + o * 0.3
			var pa := a + r * side * 0.5 + Vector3.UP * (eave + 4.0) + o * 0.3
			lm.tri("Wall", pl, pr, pa, o, o, o, Vector2.ZERO, Vector2(side, 0), Vector2(side * 0.5, -4.0))
			lm.tri("Wall", pl - o * 2.0, pr - o * 2.0, pa - o * 2.0, -o, -o, -o, Vector2.ZERO, Vector2(side, 0),
				Vector2(side * 0.5, -4.0))
			for e in [pl, pr]:
				var ev: Vector3 = e
				lm.beam("Trim", ev + o * 0.1, pa + o * 0.1 + Vector3.UP * 0.3, 0.7, 0.8, o)
				lm.beam("Wall", ev - o, pa - o, 2.0, 0.2, o)
			lm.disc("Glass", a + r * side * 0.5 + Vector3.UP * (eave + 1.6) + o * 0.32, o, 0.9, 12)
			lm.lathe("Trim", pa + Vector3.UP * 0.6, _urn(1.5), 8)
	# Copper roof rising from the eaves to the drum.
	lm.lathe("Copper", c + Vector3.UP * eave, PackedVector2Array([Vector2((ap + 0.7) * K8, 0),
		Vector2((ap - 3.0) * K8, 3.4), Vector2(11.4 * K8, 6.6)]), 8, 1.0, 1.0, PI / 8.0, false)
	# The two low burial vaults at the west front.
	for s in [-1.0, 1.0]:
		var vc := Vector3(-21.05, 0, float(s) * 11.65)
		lm.box("Wall", vc + Vector3.UP * 4.75, Vector3(8.1, 9.5, 8.5), Basis(), 0.0)
		lm.box("Stone", vc + Vector3.UP * 0.6, Vector3(8.5, 1.2, 8.9))
		lm.box("Trim", vc + Vector3.UP * 9.3, Vector3(8.6, 0.6, 9.0))
		for f in [Vector3.LEFT, Vector3(0, 0, float(s))]:
			var o: Vector3 = f
			var r := Vector3.UP.cross(o)
			var half := 4.25 if absf(o.x) > 0.0 else 4.05
			var depth := 4.05 if absf(o.x) > 0.0 else 4.25
			var a := vc + o * depth - r * half
			_arched_row(lm, "Wall", a + Vector3.UP * 1.2, r, o, 2.0 * half, 7.4, 1, 2.6, 1.8, 2.8)
			for x in [0.4, 2.0 * half - 0.4]:
				_fb(lm, "Trim", a, r, o, float(x), 4.75, 0.1, Vector3(0.8, 8.3, 0.2))
		lm.spire("Copper", vc + Vector3.UP * 9.6, 4.3, 2.6, 1.2)
		lm.lathe("Trim", vc + Vector3.UP * 12.2, _urn(1.2), 8)
	_he_dome(lm, c)
	lm.commit(model)

## Hedvig Eleonora's drum and dome: the octagonal drum with a round-
## headed window per face between paired pilasters, cornice and
## balustrade; the ribbed octagonal copper dome of 1866-68 with eight
## dormers, the open lantern, cupola, orb and cross to HEDVIG_TOP_M.
static func _he_dome(lm: LandmarkMesh, c: Vector3) -> void:
	var ap := 10.8
	var y0 := 22.0
	var top := 33.5
	lm.poly_prism("Wall", _oct(c, ap), y0, top)
	var side := 2.0 * ap * tan(PI / 8.0)
	for k in 8:
		var ang := PI * 0.25 * float(k)
		var o := Vector3(cos(ang), 0, sin(ang))
		var r := Vector3.UP.cross(o)
		var a := c + o * ap - r * side * 0.5
		_arched_row(lm, "Wall", a + Vector3.UP * (y0 + 1.6), r, o, side, top - y0 - 2.8, 1, 1.4, 2.4, 4.6)
		for s in [0.4, 1.2, side - 1.2, side - 0.4]:
			_fb(lm, "Trim", a, r, o, float(s), (y0 + top) * 0.5 + 0.6, 0.55, Vector3(0.6, top - y0 - 2.2, 0.3))
		LandmarkDetail.cornice(lm, "Trim", a + Vector3.UP * (top - 1.0) + o * 0.4,
			a + r * side + Vector3.UP * (top - 1.0) + o * 0.4,
			o, 1.0, false)
	var db := c + Vector3.UP * top
	var prof := PackedVector2Array([Vector2(11.4, 0), Vector2(11.1, 3.0), Vector2(10.0, 6.4), Vector2(8.0, 9.6),
		Vector2(5.2, 12.3), Vector2(3.0, 13.8)])
	lm.lathe("Copper", db, prof, 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * float(k)
		for j in prof.size() - 1:
			lm.beam("Copper", db + Vector3(cos(a) * (prof[j].x + 0.12), prof[j].y, sin(a) * (prof[j].x + 0.12)),
				db + Vector3(cos(a) * (prof[j + 1].x + 0.12), prof[j + 1].y, sin(a) * (prof[j + 1].x + 0.12)), 0.5, 0.3)
		var fa := a + PI / 8.0
		var o := Vector3(cos(fa), 0, sin(fa))
		var fb := Basis(Vector3.UP, -fa + PI * 0.5)
		var dc := db + o * 9.2 + Vector3.UP * 4.2
		lm.box("Copper", dc + Vector3.UP * 0.9, Vector3(1.6, 1.8, 1.6), fb)
		lm.gable("Copper", dc + Vector3.UP * 1.8, 1.6, 1.6, 0.8, fb, 0.1, "Copper")
		lm.box("Glass", dc + o * 0.82 + Vector3.UP * 0.9, Vector3(0.9, 1.2, 0.04), fb, 0.0)
	var lb := db + Vector3.UP * 13.8
	_lantern(lm, "Copper", lb, 2.5, 6.0)
	lm.lathe("Copper", lb + Vector3.UP * 6.0, PackedVector2Array([Vector2(3.0, 0), Vector2(2.6, 1.0), Vector2(1.2, 2.0),
		Vector2(0.35, 2.4)]), 8, 1.0, 1.0, PI / 8.0, false)
	var sy := top + 13.8 + 6.0 + 2.4
	lm.frustum("Copper", c + Vector3.UP * sy, 0.35, 0.08, 1.4, 8, PI / 8.0)
	lm.lathe("Gilt", c + Vector3.UP * (sy + 1.3), LandmarkFhUtil.ball(0.38), 10)
	_cross(lm, c + Vector3.UP * (sy + 2.0), HEDVIG_TOP_M - sy - 2.0)
