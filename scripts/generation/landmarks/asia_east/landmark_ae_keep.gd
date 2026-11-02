class_name LandmarkAeKeep
extends RefCounted

## Japanese castle parts for Himeji, in true metres on LandmarkMesh
## with the keys Stone, Plaster, Tile, Gold, Shadow and Wood: a tenshu
## keep on its fan-curved ishigaki (white plaster storeys with barred
## windows, tiled hip roofs with chidori and kara gables, a gabled top
## roof with shachihoko) and the watari-yagura corridor turrets.

## A keep centred at `c`: a battered stone base `stone_h` high, then
## `tiers` plastered storeys (each narrower, each under a hip roof with
## its gables) and a gabled top roof with golden shachihoko. `sc` scales
## the vertical dimensions (1.0 = the 46.4 m main keep).
static func keep(lm: LandmarkMesh, c: Vector2, plan: Vector2, stone_h: float, tiers: int,
		sc: float) -> void:
	# Stone base: the concave fan curve (ogi-kobai) in six slices.
	var w0 := plan.x + 5.0
	var d0 := plan.y + 5.0
	var prev_y := 0.0
	var prev_w := w0 + 11.0 * sc
	var prev_d := d0 + 9.0 * sc
	for i in range(1, 7):
		var t := float(i) / 6.0
		var sy := lerpf(0.0, stone_h, t)
		var k := pow(1.0 - t, 2.2)
		var sw := lerpf(w0, w0 + 11.0 * sc, k)
		var sd := lerpf(d0, d0 + 9.0 * sc, k)
		LandmarkAeParts.batter(lm, "Stone", c.x, c.y, prev_w, prev_d, sw, sd, prev_y, sy)
		prev_y = sy
		prev_w = sw
		prev_d = sd
	var y := stone_h
	for i in tiers:
		var w := plan.x - plan.x * 0.127 * i
		var d := plan.y - plan.y * 0.133 * i
		var top := i == tiers - 1
		var wall_h := (3.8 if top else 3.6) * sc
		_storey(lm, Vector3(c.x, y, c.y), w, d, wall_h, sc)
		var roof_y := y + wall_h
		var rc := Vector3(c.x, roof_y, c.y)
		if top:
			var rise := 4.35 * sc
			var gb := Basis(Vector3.UP, PI * 0.5)
			lm.gable("Tile", rc, d + 2.0, w + 4.0, rise, gb, 1.0, "Plaster")
			lm.box("Tile", rc + Vector3(0, rise + 0.2 * sc, 0), Vector3(w + 5.0, 0.6 * sc, 0.8 * sc))
			for s in [-1.0, 1.0]:
				_shachi(lm, rc + Vector3(s * (w * 0.5 + 2.0), rise + 0.2 * sc, 0), 0.9 * sc + 0.1, -s)
		else:
			var rise := 2.0 * sc
			var eave := Vector2(w + 5.0, d + 4.4)
			var ridge := Vector2(w - 2.0, d - 1.8)
			LandmarkAeParts.hip_roof(lm, "Tile", rc, eave, ridge, rise, 0.5 * sc)
			LandmarkAeParts.eave_fascia(lm, "Tile", rc, eave, 0.5 * sc, 0.35 * sc)
			LandmarkAeParts.hip_ridges(lm, "Tile", rc, eave, ridge, rise, 0.5 * sc, 0.4 * sc)
			# Gables on the roof: a kara-hafu over the front of the first
			# roof, chidori-hafu pairs and singles above, alternating
			# between the long and short faces.
			match i % 4:
				0:
					kara_hafu(lm, rc + Vector3(0, 0.1, d * 0.5 + 2.0), Vector3.BACK, 6.0 * sc + 1.0, 1.4 * sc, 4.0)
					_chidori(lm, rc, Vector3.RIGHT, w * 0.5 + 1.0, 0.0, 6.0 * sc + 1.0, 2.0 * sc)
					_chidori(lm, rc, Vector3.LEFT, w * 0.5 + 1.0, 0.0, 6.0 * sc + 1.0, 2.0 * sc)
				1:
					for s in [-1.0, 1.0]:
						_chidori(lm, rc, Vector3.BACK, d * 0.5 + 1.0, s * w * 0.22, 5.0 * sc + 1.0, 1.8 * sc)
						_chidori(lm, rc, Vector3.FORWARD, d * 0.5 + 1.0, s * w * 0.22, 5.0 * sc + 1.0, 1.8 * sc)
				2:
					_chidori(lm, rc, Vector3.BACK, d * 0.5 + 1.0, 0.0, 7.0 * sc + 1.0, 2.4 * sc)
					_chidori(lm, rc, Vector3.FORWARD, d * 0.5 + 1.0, 0.0, 7.0 * sc + 1.0, 2.4 * sc)
				_:
					kara_hafu(lm, rc + Vector3(w * 0.5 + 2.0, 0.1, 0), Vector3.RIGHT, 5.0 * sc + 1.0, 1.2 * sc, 3.5)
					kara_hafu(lm, rc + Vector3(-w * 0.5 - 2.0, 0.1, 0), Vector3.LEFT, 5.0 * sc + 1.0, 1.2 * sc, 3.5)
		y += (wall_h + 2.0 * sc) if not top else 0.0

## A plastered storey w x d, `h` tall from `base`: a white mass, a
## pierced plaster skin with barred windows on each face, a dark timber
## sill band at its foot.
static func _storey(lm: LandmarkMesh, base: Vector3, w: float, d: float, h: float, sc: float) -> void:
	lm.box("Plaster", base + Vector3(0, h * 0.5, 0), Vector3(w - 0.4, h, d - 0.4))
	lm.box("Wood", base + Vector3(0, 0.15, 0), Vector3(w + 0.1, 0.3, d + 0.1), Basis(), 0.0)
	var win := Vector2(0.8 * sc + 0.4, 0.9 * sc + 0.3)
	var sill := h * 0.38
	for f in 4:
		var a := PI * 0.5 * f
		var n := Vector3(cos(a), 0, sin(a))
		var r := Vector3.UP.cross(n).normalized() * -1.0
		var fw := (d if f % 2 == 0 else w) - 0.4
		var half := (w if f % 2 == 0 else d) * 0.5 - 0.2
		var cols := maxi(int(fw / 3.0), 2)
		var origin := base + n * half - r * fw * 0.5
		LandmarkDetail.pierced_face(lm, "Plaster", "Shadow", origin, r, n, fw, h, cols, 1, win, sill, h, 0.2)
		var basis := Basis(r, Vector3.UP, n)
		for i in cols:
			var cx := fw / float(cols) * (float(i) + 0.5)
			for k in 3:
				lm.box("Wood", origin + r * (cx + win.x * (float(k) + 1.0) / 4.0 - win.x * 0.5)
					+ Vector3(0, sill + win.y * 0.5, 0) + n * 0.1, Vector3(0.07, win.y, 0.07), basis, 0.0)

## Chidori-hafu: a triangular dormer gable on a hip roof at `rc`, its
## gable end facing `out` at `dist` from the centre, offset `along` the
## face, `w` wide and `rise` high, white gable board with a dark rim.
static func _chidori(lm: LandmarkMesh, rc: Vector3, out: Vector3, dist: float, along: float, w: float,
		rise: float) -> void:
	var side := Vector3.UP.cross(out).normalized() * -1.0
	var basis := Basis(side, Vector3.UP, out)
	var c := rc + out * (dist - 1.5) + side * along + Vector3(0, rise * 0.35, 0)
	lm.gable("Tile", c, w, 3.0, rise, basis, 0.5, "Plaster")
	var apex := c + out * 1.5 + Vector3(0, rise, 0)
	for s in [-1.0, 1.0]:
		lm.beam("Wood", apex + Vector3(0, 0.1, 0), c + out * 1.5 + side * s * (w * 0.5 + 0.5) + Vector3(0, -0.2, 0),
			0.3, 0.2, out)
	# Gegyo: the pendant board under the apex.
	lm.box("Gold", apex - Vector3(0, 0.45, 0) + out * 0.08, Vector3(0.7, 0.5, 0.06), basis, 0.0)

## Kara-hafu: the bow-shaped cusped gable at the eave, centred at `c`
## (front edge), facing `out`, `w` wide, `rise` high, `depth` back into
## the roof; a curved tiled bow over a white board.
static func kara_hafu(lm: LandmarkMesh, c: Vector3, out: Vector3, w: float, rise: float, depth: float) -> void:
	var side := Vector3.UP.cross(out).normalized() * -1.0
	var n := 16
	var front := PackedVector3Array()
	var back := PackedVector3Array()
	for i in n + 1:
		var u := float(i) / float(n) * 2.0 - 1.0
		var y := rise * (0.5 + 0.5 * cos(PI * u)) + rise * 0.25 * pow(absf(u), 6.0)
		var p := c + side * u * w * 0.5 + Vector3(0, y, 0)
		front.append(p)
		back.append(p - out * depth + Vector3(0, 0.6, 0))
	lm.grid("Tile", [front, back], Vector3.UP)
	for i in n:
		var a := front[i]
		var b := front[i + 1]
		lm.beam("Wood", a + Vector3(0, -0.12, 0) + out * 0.05, b + Vector3(0, -0.12, 0) + out * 0.05, 0.28, 0.2, out)
		var fa := Vector3(a.x, c.y - 0.4, a.z) - out * 0.1
		var fb := Vector3(b.x, c.y - 0.4, b.z) - out * 0.1
		lm.quad("Plaster", fa, fb, b - out * 0.1, a - out * 0.1, out)

## Shachihoko: a gilt tiger-headed carp on the ridge end at `base`,
## `h` tall, head toward `inward` (+-1 on x), tail flung up.
static func _shachi(lm: LandmarkMesh, base: Vector3, h: float, inward: float) -> void:
	lm.box("Gold", base + Vector3(inward * h * 0.12, h * 0.25, 0), Vector3(h * 0.5, h * 0.45, h * 0.28),
		Basis(Vector3.BACK, inward * 0.5), 0.0)
	var prev := base + Vector3(-inward * h * 0.05, h * 0.4, 0)
	for k in 3:
		var p := base + Vector3(-inward * (h * 0.1 + 0.08 * h * k), h * (0.6 + 0.15 * k), 0)
		lm.beam("Gold", prev, p, h * 0.22 * (1.0 - 0.2 * k), h * 0.18)
		prev = p
	for s in [-1.0, 1.0]:
		lm.beam("Gold", prev, prev + Vector3(-inward * h * 0.12, h * 0.12, s * h * 0.15), h * 0.14, h * 0.04)

## Watari-yagura: a corridor turret from a to b (ground points) on a
## stone wall `stone_h` high: plastered storey with barred windows on
## both long faces, a gabled tile roof.
static func yagura(lm: LandmarkMesh, a: Vector3, b: Vector3, stone_h: float) -> void:
	var dir := (b - a).normalized()
	var run := a.distance_to(b)
	var r := Vector3.UP.cross(dir).normalized()
	var basis := Basis(r, Vector3.UP, dir)
	var mid := (a + b) * 0.5
	lm.box("Stone", mid + Vector3(0, stone_h * 0.5, 0), Vector3(9.0, stone_h, run), basis)
	var h := 3.6
	var w := 6.0
	_corridor_face(lm, mid + Vector3(0, stone_h, 0), dir, r, w, run, h)
	lm.gable("Tile", mid + Vector3(0, stone_h + h, 0), w, run, 2.0, basis, 0.9, "Plaster")
	lm.box("Tile", mid + Vector3(0, stone_h + h + 2.1, 0), Vector3(0.6, 0.4, run + 0.6), basis)

static func _corridor_face(lm: LandmarkMesh, base: Vector3, dir: Vector3, r: Vector3, w: float, run: float,
		h: float) -> void:
	lm.box("Plaster", base + Vector3(0, h * 0.5, 0), Vector3(w - 0.4, h, run), Basis(r, Vector3.UP, dir))
	for s in [-1.0, 1.0]:
		var n: Vector3 = r * s
		var rr := Vector3.UP.cross(n).normalized() * -1.0
		var origin := base + n * (w * 0.5 - 0.2) - rr * run * 0.5
		LandmarkDetail.pierced_face(lm, "Plaster", "Shadow", origin, rr, n, run, h, maxi(int(run / 3.2), 1), 1,
			Vector2(0.9, 0.8), 1.5, h, 0.2)
