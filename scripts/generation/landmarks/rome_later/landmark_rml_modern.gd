class_name LandmarkRmLModern
extends RefCounted

## The Palazzo della Civiltà Italiana, the Stadio Olimpico and the Sistine
## Chapel with the Vatican palaces around it, in true metres.

# --- Palazzo della Civiltà Italiana -------------------------------------------

## The "Square Colosseum" of EUR (1938-43), origin at its centre: a
## 51.6 m square block of white travertine with six rows of nine
## identical round arches on each of its four faces (54 a face), open
## loggias behind them, and an attic carrying the inscription "Un popolo
## di poeti di artisti di eroi..."; it stands on a three-tier stylobate
## with a broad flight on the front (68 m in all). Twenty-eight 3.4 m
## marble statues fill the ground-floor arches and the Dioscuri groups
## stand at the corners of the podium.
static func civilta(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E4DABF", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EFE7D2", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#D6CDB4", 2.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 2.0))
	var y0 := 10.25
	for t in 3:
		var side := 69.6 - 6.0 * float(t)
		var tier_h := y0 / 3.0 * float(t + 1)
		lm.box("Steps", Vector3(0, tier_h * 0.5, 0), Vector3(side, tier_h, side))
		# Coping moulding round each tier.
		lm.box("Trim", Vector3(0, tier_h - 0.15, 0), Vector3(side + 0.4, 0.3, side + 0.4))
	# Front flight up the three tiers, 26 m wide, with side cheeks.
	for k in 30:
		var hgt := y0 * float(k + 1) / 30.0
		lm.box("Steps", Vector3(0, hgt * 0.5, 28.8 + 14.0 - 0.47 * (float(k) + 0.5)), Vector3(26.0, hgt, 0.47), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.beam("Trim", Vector3(s * 13.5, 1.2, 42.8), Vector3(s * 13.5, y0 + 1.2, 28.8), 1.0, 2.4, Vector3.RIGHT)
	var side_w := 51.6
	var body_h := 57.25
	lm.box("Stone", Vector3(0, y0 + body_h * 0.5, 0), Vector3(side_w - 3.0, body_h, side_w - 3.0))
	var row_h := 7.9
	var attic := body_h - row_h * 6.0
	for f in 4:
		var out := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f))
		var right := Vector3.UP.cross(out)
		var o := Vector3(0, y0, 0) + out * (side_w * 0.5 - 1.5) - right * side_w * 0.5
		for r in 6:
			var ro := o + Vector3(0, row_h * float(r), 0)
			LandmarkRmLKit.arcade(lm, "Stone", "Shadow", ro, right, out, side_w, row_h, 9, 3.6, 4.0, 1.5)
			# Thin string course at each floor line, flush and crisp.
			lm.box("Trim", ro + right * side_w * 0.5 + out * 1.6 + Vector3(0, row_h - 0.15, 0),
				Vector3(side_w + 0.2, 0.3, 0.3), Basis(right, Vector3.UP, out), 0.0)
			# Glazed back wall of the loggia behind every arch (Shadow back
			# is the glass); a transom bar across each opening.
			for i in 9:
				var c := ro + right * (side_w / 9.0 * (float(i) + 0.5)) + out * 0.1
				lm.box("Trim", c + Vector3(0, 4.0, 0), Vector3(3.6, 0.12, 0.12), Basis(right, Vector3.UP, out), 0.0)
				lm.box("Trim", c + Vector3(0, 2.8, 0), Vector3(0.1, 5.6, 0.12), Basis(right, Vector3.UP, out), 0.0)
		# Attic with the inscription: a raised band and a run of letters.
		var ao := o + Vector3(0, row_h * 6.0, 0)
		lm.box("Stone", ao + right * side_w * 0.5 + out * 0.75 + Vector3(0, attic * 0.5, 0),
			Vector3(side_w, attic, 1.5), Basis(right, Vector3.UP, out))
		LandmarkDetail.cornice(lm, "Trim", ao + out * 1.5 + Vector3(0, attic - 0.9, 0) - right * 0.2,
			ao + out * 1.5 + Vector3(0, attic - 0.9, 0) + right * (side_w + 0.2), out, 0.9, false)
		for i in 58:
			var lx := 3.0 + 45.6 * float(i) / 57.0
			if i % 7 == 6:
				continue
			lm.box("Shadow", ao + right * lx + out * 1.55 + Vector3(0, attic * 0.45, 0),
				Vector3(0.55, 1.3, 0.1), Basis(right, Vector3.UP, out), 0.0)
		# Statues in seven ground-floor arches of every face (28 in all).
		for i in range(1, 8):
			var sp := o + right * (side_w / 9.0 * (float(i) + 0.5)) + out * 0.9
			lm.box("Marble", sp + Vector3(0, 0.5, 0), Vector3(1.3, 1.0, 1.0), Basis(right, Vector3.UP, out))
			LandmarkKits.statue_figure(lm, "Marble", sp + Vector3(0, 1.0, 0), 3.4, i % 2 == 0)
	lm.box("Trim", Vector3(0, y0 + body_h + 0.25, 0), Vector3(side_w + 0.6, 0.5, side_w + 0.6))
	lm.box("Trim", Vector3(0, y0 + 0.4, 0), Vector3(side_w + 0.4, 0.8, side_w + 0.4))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(float(sx) * 31.5, y0, float(sz) * 31.5)
			lm.box("Marble", c + Vector3(0, 0.6, 0), Vector3(3.6, 1.2, 6.4))
			lm.box("Marble", c + Vector3(0, 1.3, 0), Vector3(3.9, 0.2, 6.7), Basis(), 0.0)
			LandmarkRmLUtil.horse(lm, "Marble", c + Vector3(0, 1.4, 0.0))
			LandmarkKits.statue_figure(lm, "Marble", c + Vector3(1.6, 1.4, -0.8), 5.0, true)
	lm.commit(model)

# --- Stadio Olimpico ----------------------------------------------------------------

## The Foro Italico stadium (1953, roofed 1990), origin at the centre of
## the pitch, long axis along X (yaw_deg lays it on the real N-S axis):
## a 319 x 190 m bowl of two straight stands and two curves of 95 m
## radius round the 105 x 68 m pitch and its nine-lane track; two tiers
## of stepped seating, the travertine-clad outer wall, and the roof: a
## steel lattice compression ring 29-36 m up on twelve steel pillars and
## four concrete stair towers, 88 radial cables down to the inner
## tension ring, and the white PTFE membrane between them.
static func olimpico(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Grass", LandmarkMaterials.pbr("lawn", "#5E8F3E", 4.0))
	lm.use("Track", LandmarkMaterials.pbr("terracotta", "#B5553A", 3.0))
	lm.use("Seats", LandmarkMaterials.pbr("concrete", "#6F7F99", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("concrete", "#B8B4AA", 4.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3C3A36", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("render", "#EDEDED", 4.0, 0.7))
	lm.use("Steel", LandmarkMaterials.paint("#D9DADA", 0.5, 0.5))
	var hl := 64.5
	lm.box("Grass", Vector3(0, 0.1, 0), Vector3(105.0, 0.2, 68.0))
	# Track: the 400 m oval (84.4 m straights, 36.5 m bends), nine lanes.
	var lane_rows: Array = []
	for k in [36.5, 47.5]:
		lane_rows.append(_track_ring(42.2, float(k), 0.13))
	lm.grid("Track", lane_rows, Vector3.UP)
	for k in range(1, 9):
		var ring := _track_ring(42.2, 36.5 + 1.22 * float(k), 0.15)
		for i in ring.size() - 1:
			lm.beam("Steel", ring[i], ring[i + 1], 0.06, 0.02, Vector3.UP)
	# Seating bowl: two tiers of stepped rows on the racetrack plan.
	var prof := PackedVector2Array()
	prof.append(Vector2(51.0, 0.0))
	prof.append(Vector2(51.0, 1.4))
	for k in 24:
		prof.append(Vector2(51.6 + 0.8 * float(k), 1.4 + 0.33 * float(k + 1)))
		prof.append(Vector2(52.4 + 0.8 * float(k), 1.4 + 0.33 * float(k + 1)))
	prof.append(Vector2(72.0, 9.4))
	prof.append(Vector2(73.0, 10.6))
	for k in 24:
		prof.append(Vector2(73.6 + 0.8 * float(k), 10.6 + 0.42 * float(k + 1)))
		prof.append(Vector2(74.4 + 0.8 * float(k), 10.6 + 0.42 * float(k + 1)))
	prof.append(Vector2(93.5, 21.2))
	prof.append(Vector2(95.0, 21.2))
	var rows: Array = []
	for q in prof:
		rows.append(_track_ring(hl, q.x, q.y))
	# Outer rows first: the grid then faces up and in toward the pitch.
	rows.reverse()
	lm.grid("Seats", rows)
	# Vomitories into the upper tier and the walkway between the tiers.
	var mid := _track_ring(hl, 72.5, 9.6)
	for i in range(0, mid.size() - 1, 3):
		var n := _ring_normal(mid, i)
		lm.box("Shadow", mid[i] + n * 0.5 + Vector3(0, 1.1, 0), Vector3(2.4, 2.2, 1.0),
			Basis(Vector3.UP.cross(n), Vector3.UP, n), 0.0)
	# Outer wall: travertine-clad, vertical fins and two rows of openings.
	lm.grid("Wall", [_track_ring(hl, 95.0, 0.0), _track_ring(hl, 95.0, 21.2)], Vector3.ZERO)
	var foot := _track_ring(hl, 95.0, 0.0)
	for i in foot.size() - 1:
		var n := _ring_normal(foot, i)
		var b := Basis(Vector3.UP.cross(n), Vector3.UP, n)
		lm.box("Wall", foot[i] + n * 0.5 + Vector3(0, 10.6, 0), Vector3(0.7, 21.2, 1.0), b, 0.0)
		var nxt: Vector3 = foot[i + 1]
		var mp := (foot[i] + nxt) * 0.5 + n * 0.05
		lm.box("Shadow", mp + Vector3(0, 3.2, 0), Vector3(3.2, 4.4, 0.1), b, 0.0)
		lm.box("Shadow", mp + Vector3(0, 13.5, 0), Vector3(3.2, 2.6, 0.1), b, 0.0)
	# Roof: membrane between the compression ring and the tension ring.
	var mem: Array = []
	for k in 7:
		var t := float(k) / 6.0
		mem.append(_track_ring(hl, lerpf(96.0, 50.0, t), lerpf(33.0, 27.0, t) + sin(t * PI) * 1.2))
	lm.grid("Roof", mem, Vector3.UP)
	var under: Array = []
	for k in 7:
		var t := float(k) / 6.0
		under.append(_track_ring(hl, lerpf(96.0, 50.0, t), lerpf(32.8, 26.8, t) + sin(t * PI) * 1.2))
	lm.grid("Roof", under, Vector3.DOWN)
	# Compression ring: a triangular steel lattice truss.
	var top_c := _track_ring(hl, 97.0, 36.0)
	var in_c := _track_ring(hl, 94.0, 29.5)
	var out_c := _track_ring(hl, 100.0, 29.5)
	for i in top_c.size() - 1:
		for ch in [top_c, in_c, out_c]:
			var chord: PackedVector3Array = ch
			lm.beam("Steel", chord[i], chord[i + 1], 0.8, 0.8)
		var j := i + 1
		lm.beam("Steel", in_c[i], top_c[j] if i % 2 == 0 else top_c[i], 0.3, 0.3)
		lm.beam("Steel", out_c[i], top_c[j] if i % 2 == 0 else top_c[i], 0.3, 0.3)
		lm.beam("Steel", in_c[i], out_c[i], 0.3, 0.3)
	# Radial cables and the inner tension ring.
	var inner := _track_ring(hl, 50.0, 27.0)
	var inner_lo := _track_ring(hl, 50.0, 23.5)
	for i in inner.size() - 1:
		lm.beam("Steel", inner[i], inner[i + 1], 0.5, 0.5)
		lm.beam("Steel", inner_lo[i], inner_lo[i + 1], 0.4, 0.4)
		lm.beam("Steel", inner[i], inner_lo[i], 0.25, 0.25)
		lm.beam("Steel", in_c[i], inner[i], 0.18, 0.18)
		lm.beam("Steel", top_c[i] - Vector3(0, 0.5, 0), inner_lo[i], 0.14, 0.14)
	# Twelve steel pillars and four concrete stair towers carry the ring.
	for k in 12:
		var i := int(float(k) / 12.0 * float(out_c.size() - 1) + 3.0)
		var p: Vector3 = out_c[i % (out_c.size() - 1)]
		var g := Vector3(p.x, 0, p.z)
		lm.frustum("Steel", g, 1.3, 0.9, 29.5, 12)
		lm.box("Steel", g + Vector3(0, 0.5, 0), Vector3(3.4, 1.0, 3.4))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tc := Vector3(float(sx) * 40.0, 0, float(sz) * 99.0)
			lm.box("Wall", tc + Vector3(0, 15.0, 0), Vector3(9.0, 30.0, 8.0))
			lm.box("Shadow", tc + Vector3(0, 15.0, float(sz) * 4.05), Vector3(2.0, 26.0, 0.1), Basis(), 0.0)
	lm.commit(model)

## Points round the racetrack plan of the stadium: straights 2 hl long
## along X at z = +/- r, joined by half circles of radius r centred at
## x = +/- hl; at height y, closed (the last point repeats the first).
static func _track_ring(hl: float, r: float, y: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var straight := 10
	var bend := 24
	for i in straight:
		pts.append(Vector3(-hl + 2.0 * hl * float(i) / float(straight), y, r))
	for i in bend:
		var a := PI * 0.5 - PI * float(i) / float(bend)
		pts.append(Vector3(hl + cos(a) * r, y, sin(a) * r))
	for i in straight:
		pts.append(Vector3(hl - 2.0 * hl * float(i) / float(straight), y, -r))
	for i in bend:
		var a := -PI * 0.5 - PI * float(i) / float(bend)
		pts.append(Vector3(-hl + cos(a) * r, y, sin(a) * r))
	pts.append(pts[0])
	return pts

## Outward horizontal normal of a _track_ring at point i.
static func _ring_normal(ring: PackedVector3Array, i: int) -> Vector3:
	var t := ring[(i + 1) % ring.size()] - ring[i]
	if t.length() < 0.001:
		t = ring[1] - ring[0]
	var n := Vector3(t.z, 0, -t.x).normalized()
	var c := Vector3(clampf(ring[i].x, -64.5, 64.5), ring[i].y, 0)
	if n.dot(ring[i] - c) < 0.0:
		n = -n
	return n

# --- Sistine Chapel ---------------------------------------------------------------------

## Origin at the middle of the chapel, long axis along X: Sixtus IV's
## plain brick hall (1473-81; 40.9 x 13.4 m, 20.7 m to the ridge) with
## six tall round-arched windows down each side under the crenellated
## parapet and its guard walk, two windows in each end wall, the heavy
## buttresses added when the walls cracked, and the low tiled roof; the
## Vatican palaces close the courts round it (Apostolic Palace to the
## east, the Museums' wings north and south).
static func sistine(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9A6A4C", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#CDB48A", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E1D6BC", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	var lx := 40.9
	var wz := 13.4
	lm.box("Brick", Vector3(0, 5.0, 0), Vector3(lx, 10.0, wz))
	lm.box("Brick", Vector3(0, 13.6, 0), Vector3(lx - 1.6, 7.2, wz - 1.6))
	lm.box("Trim", Vector3(0, 10.0, 0), Vector3(lx + 0.4, 0.4, wz + 0.4))
	for s in [-1.0, 1.0]:
		var n := Vector3(0, 0, s)
		var r := Vector3.UP.cross(n)
		# Window band: six arched windows between the buttresses.
		var o := Vector3(0, 10.2, s * (wz * 0.5 - 0.8)) - r * lx * 0.5
		LandmarkRmLKit.arcade(lm, "Brick", "Shadow", o, r, n, lx, 7.0, 6, 2.6, 3.4, 0.8, 0.4)
		LandmarkRmLKit.archivolts(lm, "Trim", o, r, n, lx, 6, 2.6, 3.4, 0.82, 0.3)
		# Buttresses: battered piers with sloped caps.
		for i in 7:
			var x := -lx * 0.5 + 0.6 + (lx - 1.2) * float(i) / 6.0
			lm.box("Brick", Vector3(x, 7.0, s * (wz * 0.5 + 0.9)), Vector3(1.6, 14.0, 1.8))
			lm.beam("Brick", Vector3(x, 14.0, s * (wz * 0.5 + 1.75)), Vector3(x, 16.6, s * (wz * 0.5 - 0.6)),
				1.6, 0.6, Vector3.RIGHT)
			lm.box("Brick", Vector3(x, 1.0, s * (wz * 0.5 + 1.2)), Vector3(2.0, 2.0, 2.4))
	for s in [-1.0, 1.0]:
		var n := Vector3(s, 0, 0)
		var r := Vector3.UP.cross(n)
		var o := Vector3(s * (lx * 0.5 - 0.8), 10.2, 0) - r * (wz - 1.6) * 0.5
		LandmarkRmLKit.arcade(lm, "Brick", "Shadow", o, r, n, wz - 1.6, 7.0, 2, 2.4, 3.4, 0.8, 0.4)
	# Crenellated parapet with the guard walk behind it, then the roof.
	lm.box("Trim", Vector3(0, 17.3, 0), Vector3(lx + 0.6, 0.4, wz + 0.6))
	for s in [-1.0, 1.0]:
		lm.box("Brick", Vector3(0, 17.9, s * (wz * 0.5 - 0.3)), Vector3(lx, 0.8, 0.6))
		lm.box("Brick", Vector3(s * (lx * 0.5 - 0.3), 17.9, 0), Vector3(0.6, 0.8, wz))
		SEuUtil.crenels(lm, "Brick", Vector3(-lx * 0.5, 18.3, s * (wz * 0.5 - 0.3)),
			Vector3(lx * 0.5, 18.3, s * (wz * 0.5 - 0.3)), 0.9, 1.1, 0.6)
		SEuUtil.crenels(lm, "Brick", Vector3(s * (lx * 0.5 - 0.3), 18.3, -wz * 0.5),
			Vector3(s * (lx * 0.5 - 0.3), 18.3, wz * 0.5), 0.9, 1.1, 0.6)
	lm.gable("Tile", Vector3(0, 17.5, 0), wz - 2.4, lx - 2.4, 3.2, Basis(Vector3.UP, PI * 0.5), 0.2, "Brick")
	# The chimney of the conclave on the roof's west end.
	lm.box("Brick", Vector3(-15.0, 19.6, 3.0), Vector3(0.8, 2.8, 0.8))
	lm.box("Shadow", Vector3(-15.0, 20.1, 3.0), Vector3(0.3, 0.7, 0.3))
	# Palaces closing the courts: north and south wings, east palace, west range.
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(0, 0, -27.0), 52.0, 16.5, 16.0, Vector3(0, 0, 1), 4, 11, 1.6, 2.4, "Tile")
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(0, 0, 28.0), 60.0, 16.0, 22.0, Vector3(0, 0, -1), 4, 12, 1.6, 2.4, "Tile")
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(62.0, 0, 2.0), 90.0, 19.5, 24.0, Vector3(-1, 0, 0), 4, 12, 1.8, 2.5, "", 1)
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(-42.0, 0, 2.0), 44.0, 15.5, 16.0, Vector3(1, 0, 0), 4, 8, 1.6, 2.4, "Tile")
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(38.0, 0, -27.0), 24.0, 16.5, 16.0, Vector3(0, 0, 1), 4, 5, 1.6, 2.4, "Tile")
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(40.0, 0, 28.0), 20.0, 16.0, 22.0, Vector3(0, 0, -1), 4, 4, 1.6, 2.4, "Tile")
	lm.commit(model)
