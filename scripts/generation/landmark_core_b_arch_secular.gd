class_name LandmarkCoreBArchSecular
extends RefCounted

## Generic secular landmarks for LandmarkArchetypes, in true metres,
## long side along local Z: the castle, lighthouse, stadium, tower mill
## and towers. Uses the keys Walls, Roof, Trim, Windows, Gilt
## registered by LandmarkArchetypes plus their own.

## Enclosure castle (Caernarfon, Bodiam, Carcassonne): curtain walls
## with wall-walk and crenellated parapet, arrow slits, round flanking
## towers at the corners and along long walls under machicolations and
## conical roofs, a twin-towered gatehouse with portcullis, a great hall
## in the bailey and the square keep with corner bartizans whose cones
## reach h.
static func castle(lm: LandmarkMesh, h: float, w: float, l: float) -> void:
	lm.use("Shadow", LandmarkMaterials.paint("#1E1D1B", 0.9, 0.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#5A4632", 2.0))
	var wall_h := clampf(h * 0.3, 7.0, 18.0)
	var tr := clampf(w * 0.08, 3.0, 8.0)
	var mw := clampf(wall_h * 0.08, 0.6, 1.2)
	var hx := w * 0.5 - tr * 1.25
	var hz := l * 0.5 - tr * 1.25
	var th := clampf(wall_h * 1.4, wall_h + 3.0, h * 0.72)
	var corners := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	var thick := clampf(wall_h * 0.22, 2.0, 4.0)
	for k in 4:
		var a: Vector3 = corners[k]
		var b: Vector3 = corners[(k + 1) % 4]
		var along := b - a
		var out := along.normalized().cross(Vector3.UP)
		if out.dot((a + b) * 0.5) < 0.0:
			out = -out
		var basis := Basis(along.normalized(), Vector3.UP, out)
		var mid := (a + b) * 0.5 - out * thick * 0.5
		lm.box("Walls", mid + Vector3.UP * wall_h * 0.5, Vector3(along.length(), wall_h, thick), basis)
		# Battered plinth along the foot.
		lm.box("Walls", mid + out * thick * 0.55 + Vector3.UP * 1.0, Vector3(along.length(), 2.0, thick * 0.4), basis)
		lm.box("Trim", mid + Vector3.UP * (wall_h * 0.6), Vector3(along.length(), 0.35, thick + 0.25), basis)
		LandmarkCoreBArchKit.battlement(lm, "Walls", a + Vector3.UP * wall_h, b + Vector3.UP * wall_h, out, 0.9, mw)
		var ns := maxi(int(along.length() / 7.0), 2)
		for i in ns:
			var p := a.lerp(b, (float(i) + 0.5) / float(ns))
			LandmarkCoreBArchKit.slit(lm, "Shadow", p + Vector3.UP * wall_h * 0.42, out, minf(wall_h * 0.18, 2.2))
		# Flanking towers along long walls.
		if along.length() > 70.0:
			var nt := int(along.length() / 60.0)
			for i in nt:
				var p := a.lerp(b, (float(i) + 1.0) / float(nt + 1))
				_round_tower(lm, p, tr * 0.8, th * 0.9, false, h)
	for c in corners:
		_round_tower(lm, c, tr, th, true, h * 0.85)
	# Gatehouse on the −Z wall: two drum towers, the arch, portcullis.
	var gz := -hz
	var gw := clampf(w * 0.08, 3.0, minf(6.0, wall_h * 0.45))
	for sx in [-1.0, 1.0]:
		_round_tower(lm, Vector3(float(sx) * (gw * 0.5 + tr * 0.7), 0, gz), tr * 0.75, th * 0.95, true, h * 0.8)
	lm.box("Walls", Vector3(0, wall_h * 0.6, gz - 0.5), Vector3(gw + 1.0, wall_h * 1.2, thick + 2.0))
	LandmarkCoreBArchKit.battlement(lm, "Walls", Vector3(-gw * 0.5 - 0.5, wall_h * 1.2, gz - thick * 0.5 - 1.0),
		Vector3(gw * 0.5 + 0.5, wall_h * 1.2, gz - thick * 0.5 - 1.0), Vector3(0, 0, -1), 0.9, mw, true)
	var gh := maxf(minf(wall_h * 0.55, 6.5), gw * 0.5 + 2.5)
	var face := Vector3(0, 0, gz - thick * 0.5 - 1.05)
	lm.box("Shadow", face + Vector3.UP * (gh - gw * 0.5) * 0.5, Vector3(gw, gh - gw * 0.5, 0.1), Basis(), 0.0)
	lm.disc("Shadow", face + Vector3.UP * (gh - gw * 0.5), Vector3(0, 0, -1), gw * 0.5, 12)
	LandmarkDetail.arch(lm, "Trim", face + Vector3.UP * (gh - gw * 0.5), Vector3(0, 0, -1), gw, -1.0, 0.4)
	for i in 5:
		var x := -gw * 0.4 + gw * 0.8 * float(i) / 4.0
		lm.box("Wood", face + Vector3(x, (gh - gw * 0.5) * 0.5 + 0.2, -0.12), Vector3(0.15, gh - gw * 0.5, 0.15), Basis(), 0.0)
	for j in 4:
		lm.box("Wood", face + Vector3(0, 0.6 + (gh - gw * 0.5) * float(j) / 4.0, -0.18), Vector3(gw, 0.15, 0.15), Basis(), 0.0)
	# Great hall against the +X wall.
	var hall_l := minf(hz * 0.8, 30.0)
	var hall_w := minf(hx * 0.45, 12.0)
	var hc := Vector3(hx - thick - hall_w * 0.5, 0, -hz * 0.25)
	var hall_h := wall_h * 0.85
	lm.box("Walls", hc + Vector3.UP * hall_h * 0.5, Vector3(hall_w, hall_h, hall_l))
	lm.gable("Roof", hc + Vector3.UP * hall_h, hall_w, hall_l, hall_w * 0.55, Basis(), 0.4, "Walls")
	var nwin := maxi(int(hall_l / 5.0), 2)
	for i in nwin:
		var z := hc.z - hall_l * 0.5 + hall_l * (float(i) + 0.5) / float(nwin)
		LandmarkCoreBArchKit.lancet(lm, "Trim", "Windows", Vector3(hc.x - hall_w * 0.5, hall_h * 0.35, z),
			Vector3(-1, 0, 0), 1.3, hall_h * 0.45, 0.25)
	lm.box("Walls", hc + Vector3(hall_w * 0.25, hall_h + hall_w * 0.55, 0), Vector3(1.4, hall_w * 0.4, 1.4))
	# The keep: a square donjon with pilaster buttresses, round-arched
	# windows, crenellations and four bartizans whose cones reach h.
	var kw := clampf(minf(hx, hz) * 0.7, 8.0, 26.0)
	var kc := Vector3(-hx * 0.2, 0, hz * 0.3)
	var br := kw * 0.11
	var cone := br * 2.8
	var kh := h - cone - 1.2
	lm.box("Walls", kc + Vector3.UP * kh * 0.5, Vector3(kw, kh, kw))
	lm.box("Walls", kc + Vector3.UP * 1.5, Vector3(kw + 1.6, 3.0, kw + 1.6))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(f))
		var n := r * Vector3(0, 0, 1)
		for i in 2:
			var px := (float(i) - 0.5) * kw * 0.5
			lm.box("Walls", kc + r * Vector3(px, kh * 0.48, kw * 0.5 + 0.3), Vector3(kw * 0.08, kh * 0.96, 0.6), r)
		lm.box("Trim", kc + r * Vector3(0, kh * 0.55, kw * 0.5 + 0.15), Vector3(kw + 0.3, 0.4, 0.3), r)
		var floors := clampi(int(kh / 6.0), 2, 6)
		for j in floors:
			var y := kh * (0.15 + 0.75 * float(j) / float(floors))
			if j < 1:
				LandmarkCoreBArchKit.slit(lm, "Shadow", kc + n * kw * 0.5 + Vector3.UP * (y + 1.0), n, 2.0)
				continue
			for i in [-1.0, 0.0, 1.0]:
				if i != 0.0 and j < floors - 1:
					continue
				LandmarkDetail.window(lm, "Trim", "Windows", kc + n * kw * 0.5 + r * Vector3(float(i) * kw * 0.25, y, 0),
					n, 1.1, 2.2, true, 0.25)
		var a := kc + r * Vector3(-kw * 0.5, kh, kw * 0.5)
		var b := kc + r * Vector3(kw * 0.5, kh, kw * 0.5)
		LandmarkCoreBArchKit.battlement(lm, "Walls", a, b, n, 1.0, mw, true)
	lm.lathe("Roof", kc + Vector3.UP * kh, PackedVector2Array([Vector2(kw * 0.62, 0), Vector2(0.0, kw * 0.25)]),
		4, 1.0, 1.0, PI * 0.25, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var bc := kc + Vector3(float(sx) * kw * 0.5, kh, float(sz) * kw * 0.5)
			lm.lathe("Walls", bc - Vector3.UP * br * 2.0, PackedVector2Array([Vector2(0.0, 0), Vector2(br * 0.7, br * 0.6),
				Vector2(br, br * 2.0), Vector2(br, br * 2.0 + 1.2)]), 10)
			lm.frustum("Trim", bc + Vector3.UP * 1.1, br * 1.12, br * 1.12, 0.3, 10)
			lm.lathe("Roof", bc + Vector3.UP * 1.2, PackedVector2Array([Vector2(br * 1.15, 0),
				Vector2(br * 0.5, cone * 0.6), Vector2(0.0, cone)]), 10)
	lm.box("Gilt", kc + Vector3(0, kh + kw * 0.25, 0), Vector3(0.1, 1.2, 0.1))

## Round tower at c: battered base, string course, arrow slits,
## machicolated battlement and (when `roofed`) a conical roof whose
## tip stays under `max_top`.
static func _round_tower(lm: LandmarkMesh, c: Vector3, r: float, h: float, roofed: bool, max_top: float) -> void:
	lm.lathe("Walls", c, PackedVector2Array([Vector2(r * 1.2, 0), Vector2(r * 1.02, h * 0.15),
		Vector2(r, h * 0.17), Vector2(r, h)]), 16)
	lm.frustum("Trim", c + Vector3.UP * h * 0.16, r * 1.04, r * 1.04, 0.35, 16)
	for i in 3:
		var a := TAU * (float(i) / 3.0 + 0.1)
		var d := Vector3(cos(a), 0, sin(a))
		for j in 2:
			LandmarkCoreBArchKit.slit(lm, "Shadow", c + d * r + Vector3.UP * h * (0.35 + 0.3 * float(j)), d,
				minf(h * 0.1, 2.0))
	var mw := clampf(r * 0.22, 0.6, 1.2)
	LandmarkCoreBArchKit.battlement_ring(lm, "Walls", c + Vector3.UP * h, r, mw, true)
	var cone := minf(r * 2.2, max_top - h - mw * 0.6)
	if roofed and cone > r * 0.5:
		lm.lathe("Roof", c + Vector3.UP * (h + mw * 0.6), PackedVector2Array([Vector2(r * 0.95, 0),
			Vector2(r * 0.45, cone * 0.6), Vector2(0.0, cone)]), 16)

## Banded lighthouse: octagonal plinth with a pedimented door, tapered
## tower with stair windows spiralling up, corbelled gallery with
## stanchions and rails, the watch room with portholes, a polygonal
## lantern with astragals round the lit lens, ventilator dome, lightning
## rod tip at h, and the keeper's cottage.
static func lighthouse(lm: LandmarkMesh, h: float, w: float, l: float) -> void:
	lm.use("Red", LandmarkMaterials.pbr("render", "#B03A2A", 3.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EEEAE0", 3.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD98A", 1.6))
	lm.use("Iron", LandmarkMaterials.paint("#2E3336", 0.55, 0.5))
	var r0 := clampf(h * 0.08, 2.5, minf(9.0, w * 0.3))
	var r1 := r0 * 0.62
	var top := h * 0.78
	var pl := h * 0.05
	lm.frustum("Trim", Vector3.ZERO, r0 * 1.35, r0 * 1.3, pl, 8, PI / 8.0)
	lm.frustum("Trim", Vector3.UP * pl, r0 * 1.38, r0 * 1.38, 0.3, 8, PI / 8.0)
	var bands := 5 if h > 40.0 else 4
	for k in bands:
		var y0 := top * float(k) / float(bands)
		var y1 := top * float(k + 1) / float(bands)
		lm.frustum("Red" if k % 2 == 0 else "White", Vector3(0, y0, 0),
			lerpf(r0, r1, y0 / top), lerpf(r0, r1, y1 / top), y1 - y0, 24)
	# Door with a small pediment on the plinth's −Z face.
	var dz := -r0 * 1.3
	lm.box("Iron", Vector3(0, minf(pl, 2.4) * 0.5 + 0.3, dz - 0.05), Vector3(1.2, minf(pl, 2.4), 0.1), Basis(), 0.0)
	lm.box("Trim", Vector3(0, minf(pl, 2.4) + 0.5, dz - 0.25), Vector3(1.9, 0.3, 0.5))
	lm.gable("Trim", Vector3(0, minf(pl, 2.4) + 0.65, dz - 0.25), 0.5, 2.0, 0.5, Basis(Vector3.UP, PI * 0.5), 0.0, "Trim")
	# Stair windows climbing round the shaft.
	var nw := int(top / 3.5)
	for i in nw:
		var y := pl + 2.0 + (top - pl - 4.0) * float(i) / float(maxi(nw - 1, 1))
		var a := -PI * 0.5 + float(i) * 2.3
		var rr := lerpf(r0, r1, y / top)
		var d := Vector3(cos(a), 0, sin(a))
		var b := Basis.looking_at(-d)
		lm.box("Windows", d * (rr + 0.02) + Vector3.UP * y, Vector3(0.6, 1.0, 0.06), b, 0.0)
		lm.box("Trim", d * (rr + 0.06) + Vector3.UP * (y - 0.58), Vector3(0.95, 0.16, 0.2), b, 0.0)
		lm.box("Trim", d * (rr + 0.06) + Vector3.UP * (y + 0.6), Vector3(0.9, 0.2, 0.16), b, 0.0)
	# Corbelled gallery deck, brackets, stanchions and rails.
	lm.lathe("White", Vector3(0, top - 1.6, 0), PackedVector2Array([Vector2(r1, 0), Vector2(r1 * 1.15, 0.8),
		Vector2(r1 * 1.45, 1.6)]), 24, 1.0, 1.0, 0.0, true, false)
	lm.frustum("White", Vector3(0, top, 0), r1 * 1.5, r1 * 1.5, 0.35, 24)
	for k in 16:
		var a := TAU * (float(k) + 0.5) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("White", d * r1 * 1.22 + Vector3.UP * (top - 0.9), Vector3(0.25, 1.6, r1 * 0.45), Basis.looking_at(d), 0.0)
	for k in 24:
		var a := TAU * float(k) / 24.0
		lm.box("Iron", Vector3(cos(a) * r1 * 1.45, top + 0.9, sin(a) * r1 * 1.45), Vector3(0.08, 1.1, 0.08), Basis(), 0.0)
	for y in [top + 0.75, top + 1.45]:
		lm.frustum("Iron", Vector3(0, y, 0), r1 * 1.46, r1 * 1.46, 0.07, 24)
	# Watch room with portholes.
	var wr := top + 0.35
	var wh := h * 0.035
	lm.frustum("White", Vector3(0, wr, 0), r1 * 0.95, r1 * 0.95, wh, 16)
	for k in 6:
		var a := TAU * float(k) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.disc("Iron", d * (r1 * 0.95 + 0.03) + Vector3.UP * (wr + wh * 0.5), d, minf(wh * 0.22, 0.4), 10)
	# Lantern: glazing, astragals, the lens and the lamp.
	var ly := wr + wh
	var lh := h * 0.09
	var lr := r1 * 0.82
	lm.frustum("Iron", Vector3(0, ly, 0), lr * 1.05, lr * 1.05, 0.4, 12)
	lm.frustum("Windows", Vector3(0, ly + 0.4, 0), lr, lr, lh, 12)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var p := Vector3(cos(a) * lr * 1.01, ly + 0.4, sin(a) * lr * 1.01)
		lm.beam("Iron", p, p + Vector3.UP * lh, 0.12, 0.12)
	for t in [0.33, 0.66]:
		lm.frustum("Iron", Vector3(0, ly + 0.4 + lh * float(t), 0), lr * 1.015, lr * 1.015, 0.08, 12)
	lm.lathe("Lamp", Vector3(0, ly + 0.4 + lh * 0.15, 0), PackedVector2Array([Vector2(lr * 0.3, 0),
		Vector2(lr * 0.42, lh * 0.25), Vector2(lr * 0.45, lh * 0.35), Vector2(lr * 0.42, lh * 0.45),
		Vector2(lr * 0.3, lh * 0.7)]), 16)
	# Roof: cornice, copper dome, ventilator ball and lightning rod.
	var ry := ly + 0.4 + lh
	lm.frustum("Iron", Vector3(0, ry, 0), lr * 1.12, lr * 1.12, 0.3, 16)
	var dome_h := lr * 0.8
	lm.lathe("Red", Vector3(0, ry + 0.3, 0), LandmarkCoreBArchKit.dome(lr * 1.1, dome_h, 6), 16)
	var vy := ry + 0.3 + dome_h
	lm.lathe("Iron", Vector3(0, vy - 0.1, 0), LandmarkCoreBArchKit.dome(lr * 0.18, lr * 0.3, 4), 10)
	lm.frustum("Iron", Vector3(0, vy + lr * 0.2, 0), 0.06, 0.02, maxf(h - vy - lr * 0.2, 0.3), 6)
	# Keeper's cottage beside the tower, along the long side.
	var cw := minf(6.0, w * 0.3)
	var cl := minf(9.0, l * 0.5 - r0 * 1.4 - 1.0)
	if cl > 4.0:
		var cc := Vector3(0, 0, r0 * 1.35 + 0.5 + cl * 0.5)
		lm.box("White", cc + Vector3.UP * 1.6, Vector3(cw, 3.2, cl))
		lm.gable("Red", cc + Vector3.UP * 3.2, cw, cl, cw * 0.4, Basis(), 0.3, "White")
		lm.box("White", cc + Vector3(cw * 0.25, 3.2 + cw * 0.35, cl * 0.35), Vector3(0.8, cw * 0.5, 0.8))
		for sx in [-1.0, 1.0]:
			for k in 2:
				var z := cc.z - cl * 0.25 + cl * 0.5 * float(k)
				LandmarkDetail.window(lm, "Trim", "Windows", Vector3(float(sx) * cw * 0.5, 1.8, z), Vector3(float(sx), 0, 0),
					0.8, 1.1, false, 0.12)

## Elliptical stadium bowl: ribbed façade with gates and stair towers,
## two terraced tiers of seating with radial aisles and vomitories, a
## cantilevered membrane roof on radial trusses round a tension ring,
## and the marked pitch. The roof's outer edge is at h.
static func stadium(lm: LandmarkMesh, h: float, w: float, l: float) -> void:
	lm.use("Concrete", LandmarkMaterials.pbr("render", "#C9C5BC", 4.0))
	lm.use("Canopy", LandmarkMaterials.pbr("membrane", "#E6E4DE", 6.0, 0.5))
	lm.use("Seats", LandmarkMaterials.pbr("concrete", "#7C8A96", 2.0))
	lm.use("Pitch", LandmarkMaterials.pbr("grass", "#4F7A35", 6.0))
	lm.use("Steel", LandmarkMaterials.paint("#D8DADC", 0.45, 0.6))
	lm.use("Lines", LandmarkMaterials.paint("#F2F2EE", 0.8, 0.0))
	var hh := h
	var a := w * 0.5 * 0.97
	var b := l * 0.5 * 0.97
	var seg := 48
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(1.0, 0), Vector2(1.0, hh * 0.45)]),
		seg, a, b, 0.0, true, false)
	lm.lathe("Windows", Vector3.ZERO, PackedVector2Array([Vector2(0.995, hh * 0.45),
		Vector2(0.99, hh * 0.78)]), seg, a, b, 0.0, true, false)
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(1.0, hh * 0.78),
		Vector2(1.0, hh * 0.84)]), seg, a, b, 0.0, true, false)
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(1.006, hh * 0.44),
		Vector2(1.006, hh * 0.47)]), seg, a, b, 0.0, true, false)
	# Façade ribs, gates between them, stair towers at the diagonals.
	var ribs := 32
	for k in ribs:
		var t := TAU * float(k) / float(ribs)
		var p := Vector3(cos(t) * a * 1.01, 0, sin(t) * b * 1.01)
		var dn := Vector3(cos(t) / a, 0, sin(t) / b).normalized()
		lm.beam("Concrete", p, p + Vector3.UP * hh * 0.84, 1.0, 1.4, dn.cross(Vector3.UP))
		var tm := TAU * (float(k) + 0.5) / float(ribs)
		var g := Vector3(cos(tm) * a * 1.002, 0, sin(tm) * b * 1.002)
		var gn := Vector3(cos(tm) / a, 0, sin(tm) / b).normalized()
		if k % 2 == 0:
			lm.box("Windows", g + Vector3.UP * 2.0, Vector3(3.0, 4.0, 0.1), Basis.looking_at(-gn), 0.0)
			lm.box("Concrete", g + gn * 0.2 + Vector3.UP * 4.3, Vector3(4.0, 0.5, 0.6), Basis.looking_at(-gn))
	var sr := clampf(minf(a, b) * 0.07, 2.5, 6.0)
	for k in 4:
		var t := PI * 0.25 + PI * 0.5 * float(k)
		var dn := Vector3(cos(t) / a, 0, sin(t) / b).normalized()
		var c := Vector3(cos(t) * a, 0, sin(t) * b) - dn * sr * 0.3
		lm.frustum("Concrete", c, sr, sr, hh * 0.78, 16)
		for j in 6:
			var y := hh * 0.78 * (float(j) + 0.5) / 6.0
			for q in 3:
				var qa := atan2(dn.z, dn.x) + (float(q) - 1.0) * 0.6 + float(j) * 0.4
				var d := Vector3(cos(qa), 0, sin(qa))
				lm.box("Windows", c + d * (sr + 0.02) + Vector3.UP * y, Vector3(0.6, 2.2, 0.06), Basis.looking_at(-d), 0.0)
		lm.frustum("Concrete", c + Vector3.UP * hh * 0.78, sr * 1.1, sr * 1.1, 0.5, 16)
	# Seating: terraced lower and upper tiers, aisles and vomitories.
	var tiers := [[0.66, 1.0, 0.85, hh * 0.36], [0.84, hh * 0.44, 0.985, hh * 0.78]]
	for ti in tiers:
		var r0 := float(ti[0])
		var y0 := float(ti[1])
		var r1 := float(ti[2])
		var y1 := float(ti[3])
		var steps := 8
		var prof := PackedVector2Array()
		for s in steps:
			var t0 := float(s) / float(steps)
			var t1 := float(s + 1) / float(steps)
			prof.append(Vector2(lerpf(r0, r1, t0), lerpf(y0, y1, t1)))
			prof.append(Vector2(lerpf(r0, r1, t1), lerpf(y0, y1, t1)))
		prof.insert(0, Vector2(r0, y0))
		lm.lathe("Seats", Vector3.ZERO, prof, seg, a, b, 0.0, false, false)
		var na := 24
		for k in na:
			var t := TAU * (float(k) + 0.5) / float(na)
			var d := Vector3(cos(t) * a, 0, sin(t) * b)
			lm.beam("Concrete", d * r0 + Vector3.UP * (y0 + 0.2), d * r1 + Vector3.UP * (y1 + 0.2), 1.4, 0.4)
	for k in 16:
		var t := TAU * float(k) / 16.0
		var d := Vector3(cos(t) * a, 0, sin(t) * b)
		var p := d * 0.755 + Vector3.UP * hh * 0.18
		var dn := Vector3(cos(t) / a, 0, sin(t) / b).normalized()
		lm.box("Windows", p, Vector3(2.4, 2.4, 3.0), Basis.looking_at(dn), 0.0)
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(0.84, hh * 0.36), Vector2(0.84, hh * 0.44)]),
		seg, a, b, 0.0, true, false)
	# Roof: membrane between radial cantilever trusses, tension ring.
	lm.lathe("Canopy", Vector3.ZERO, PackedVector2Array([Vector2(1.03, hh - 0.3), Vector2(0.72, hh * 0.9)]),
		seg, a, b, 0.0, true, false)
	lm.lathe("Canopy", Vector3.ZERO, PackedVector2Array([Vector2(0.72, hh * 0.9 - 0.2), Vector2(1.03, hh - 0.5)]),
		seg, a, b, 0.0, true, false)
	for k in ribs:
		var t := TAU * float(k) / float(ribs)
		var d := Vector3(cos(t) * a, 0, sin(t) * b)
		var o_top := d * 1.03 + Vector3.UP * (hh - 0.3)
		var i_end := d * 0.72 + Vector3.UP * hh * 0.9
		var o_bot := d * 1.01 + Vector3.UP * hh * 0.84
		var side := Vector3(-sin(t), 0, cos(t))
		lm.beam("Steel", o_top, i_end, 0.6, 0.6, side)
		lm.beam("Steel", o_bot, i_end - Vector3.UP * 0.6, 0.5, 0.5, side)
		for q in 4:
			var t0 := float(q) / 4.0
			var t1 := float(q + 1) / 4.0
			var top0 := o_top.lerp(i_end, t0)
			var bot1 := o_bot.lerp(i_end - Vector3.UP * 0.6, t1)
			lm.beam("Steel", top0, bot1, 0.3, 0.3, side)
			lm.beam("Steel", bot1, o_top.lerp(i_end, t1), 0.3, 0.3, side)
	lm.lathe("Steel", Vector3.ZERO, PackedVector2Array([Vector2(0.72, hh * 0.9 - 1.2), Vector2(0.72, hh * 0.9 + 0.2)]),
		seg, a, b, 0.0, true, false)
	# Pitch and its markings.
	var pitch := PackedVector2Array()
	for k in 32:
		var t := TAU * float(k) / 32.0
		pitch.append(Vector2(cos(t) * a * 0.67, sin(t) * b * 0.67))
	lm.poly_prism("Pitch", pitch, 0.0, 0.5)
	var px := minf(a * 0.62 * 0.72, 34.0)
	var pz := minf(b * 0.62 * 0.72, 52.5)
	var ly := 0.52
	for s in [-1.0, 1.0]:
		lm.box("Lines", Vector3(float(s) * px, ly, 0), Vector3(0.12, 0.04, pz * 2.0), Basis(), 0.0)
		lm.box("Lines", Vector3(0, ly, float(s) * pz), Vector3(px * 2.0, 0.04, 0.12), Basis(), 0.0)
		var bz := float(s) * (pz - pz * 0.16)
		lm.box("Lines", Vector3(0, ly, bz), Vector3(px * 1.18, 0.04, 0.12), Basis(), 0.0)
		for sx in [-1.0, 1.0]:
			lm.box("Lines", Vector3(float(sx) * px * 0.59, ly, (bz + float(s) * pz) * 0.5), Vector3(0.12, 0.04, pz * 0.16), Basis(), 0.0)
	lm.box("Lines", Vector3(0, ly, 0), Vector3(px * 2.0, 0.04, 0.12), Basis(), 0.0)
	var cr := minf(px, pz) * 0.27
	for k in 24:
		var t0 := TAU * float(k) / 24.0
		var t1 := TAU * float(k + 1) / 24.0
		lm.beam("Lines", Vector3(cos(t0) * cr, ly, sin(t0) * cr), Vector3(cos(t1) * cr, ly, sin(t1) * cr), 0.12, 0.04)

## Tower mill (Dutch / English smock and tower mills): battered
## octagonal body on a plinth, reefing stage on struts with a railing,
## framed windows and door, the boat cap with fantail, the windshaft and
## four patent sails (stocks, whips, hemlaths, sail bars and shutters)
## set as a St Andrew's cross; the upper sail tips reach h.
static func windmill(lm: LandmarkMesh, h: float, w: float) -> void:
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6E5642", 2.0))
	lm.use("Sails", LandmarkMaterials.pbr("wood", "#D8D0BE", 2.0))
	var arm := minf(h * 0.4, w * 0.5 / 0.86)
	var hub_y := h - arm * (0.707 + 0.2 * 0.707) - 0.15
	var r0 := clampf(h * 0.13, 3.0, 7.0)
	var body := hub_y - r0 * 0.4
	var rt := r0 * 0.62
	lm.frustum("Trim", Vector3.ZERO, r0 * 1.12, r0 * 1.08, 1.2, 8, PI / 8.0)
	lm.frustum("Walls", Vector3(0, 1.2, 0), r0, rt, body - 1.2, 8, PI / 8.0)
	lm.frustum("Trim", Vector3(0, body - 0.6, 0), rt * 1.08, rt * 1.08, 0.6, 8, PI / 8.0)
	var rad_at := func(y: float) -> float: return lerpf(r0, rt, clampf((y - 1.2) / (body - 1.2), 0.0, 1.0))
	# Reefing stage: deck, struts, stanchions and rail.
	var sy := clampf(body * 0.3, 3.5, body * 0.5)
	var sr := float(rad_at.call(sy)) + clampf(r0 * 0.5, 1.5, 3.0)
	lm.frustum("Wood", Vector3(0, sy, 0), sr, sr, 0.3, 8, PI / 8.0)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		var rb := float(rad_at.call(sy - 2.5))
		if k % 2 == 0:
			lm.beam("Wood", d * rb + Vector3.UP * (sy - 2.5), d * sr * 0.95 + Vector3.UP * sy, 0.2, 0.2)
		lm.box("Wood", d * sr * 0.97 + Vector3.UP * (sy + 0.85), Vector3(0.1, 1.1, 0.1), Basis(), 0.0)
	lm.frustum("Wood", Vector3(0, sy + 1.3, 0), sr * 0.98, sr * 0.98, 0.1, 16)
	lm.frustum("Wood", Vector3(0, sy + 0.7, 0), sr * 0.98, sr * 0.98, 0.06, 16)
	# Windows on each floor, staggered round the faces, and the door.
	var floors := maxi(int(body / 4.0), 2)
	for j in floors:
		var y := 2.4 + (body - 4.0) * float(j) / float(floors)
		for q in 2:
			var a := PI / 8.0 * 2.0 * float((j * 3 + q * 4) % 8)
			var d := Vector3(cos(a), 0, sin(a))
			var rr := float(rad_at.call(y)) * cos(PI / 8.0)
			if absf(y - sy) < 1.5 or y < 2.0:
				continue
			LandmarkDetail.window(lm, "Trim", "Windows", d * rr + Vector3.UP * y, d, 0.7, 1.0, false, 0.12)
	lm.box("Wood", Vector3(0, 1.2 + 1.1, -r0 * 0.93), Vector3(1.2, 2.2, 0.12), Basis(), 0.0)
	lm.box("Trim", Vector3(0, 1.2 + 2.35, -r0 * 0.95), Vector3(1.6, 0.3, 0.3))
	# Boat cap with the fantail at the back.
	lm.lathe("Wood", Vector3(0, body, 0), PackedVector2Array([Vector2(rt * 1.05, 0), Vector2(rt * 1.0, rt * 0.3),
		Vector2(rt * 0.75, rt * 0.75), Vector2(rt * 0.3, rt * 1.0), Vector2(0.0, rt * 1.05)]), 12, 1.0, 1.35)
	var ft := Vector3(0, body + rt * 0.5, rt * 1.4 + 1.5)
	lm.beam("Wood", Vector3(0, body + 0.2, rt * 1.2), ft, 0.25)
	lm.beam("Wood", Vector3(0, body + rt * 0.8, rt * 0.9), ft, 0.25)
	for k in 6:
		var a := TAU * float(k) / 6.0
		var d := Vector3(0, cos(a), sin(a))
		lm.beam("Sails", ft + d * 0.2, ft + d * rt * 0.75, 0.5, 0.06, Vector3(1, 0, 0))
	# Windshaft, poll end, and the four sails.
	var hub := Vector3(0, hub_y, -rt * 1.35 - 0.6)
	lm.beam("Wood", Vector3(0, hub_y - 0.2, 0), hub, 0.7, 0.7)
	lm.box("Wood", hub, Vector3(1.2, 1.2, 1.2))
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var d := Vector3(sin(a), cos(a), 0)
		var side := Vector3(cos(a), -sin(a), 0)
		var root := hub - Vector3(0, 0, 0.5)
		lm.beam("Wood", root, root + d * arm, 0.5, 0.4)
		var s0 := root + d * arm * 0.2
		var s1 := root + d * arm
		var sw := arm * 0.2
		# Hemlaths (leading and trailing frame) and the sail bars.
		lm.beam("Wood", s0 + side * sw, s1 + side * sw, 0.18, 0.15)
		lm.beam("Wood", s0 - side * sw * 0.3, s1 - side * sw * 0.3, 0.15, 0.12)
		var nb := 10
		for m in nb + 1:
			var p := s0.lerp(s1, float(m) / float(nb))
			lm.beam("Wood", p - side * sw * 0.3, p + side * sw, 0.12, 0.1)
			if m < nb:
				var q := s0.lerp(s1, (float(m) + 0.5) / float(nb))
				lm.box("Sails", q + side * sw * 0.5 - Vector3(0, 0, 0.08), Vector3(sw * 0.95, arm * 0.8 / float(nb) * 0.85, 0.04),
					Basis(side, d, Vector3(0, 0, 1)), 0.0)

## Tall (≥ 100 m): telecom tower — base building, tapered shaft with
## service balconies, antenna platforms with dishes, the glazed
## observation pod with an open deck, red-and-white antenna mast with
## the lit beacon at h. Lower: campanile / clock tower — plinth, quoined
## stages with string courses, arched windows, clock faces, a louvred
## belfry under a machicolated parapet, pyramid roof with lucarnes and
## a gilt finial at h.
static func tower(lm: LandmarkMesh, h: float, w: float) -> void:
	if h >= 100.0:
		_telecom(lm, h, w)
		return
	var tw := clampf(w * 0.5, maxf(6.0, h / 8.0), minf(18.0, w * 0.9))
	var th := h * 0.74
	var ph := clampf(th * 0.05, 1.0, 3.0)
	lm.box("Trim", Vector3(0, ph * 0.5, 0), Vector3(tw + 1.2, ph, tw + 1.2))
	lm.box("Walls", Vector3(0, th * 0.5, 0), Vector3(tw, th, tw))
	var stages := clampi(int(th / 9.0), 3, 7)
	var sh := (th - ph) / float(stages)
	var qh := 1.0
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		var n := r * Vector3(0, 0, 1)
		var face := n * tw * 0.5
		# Quoins up the corner, alternating long and short.
		var nq := int((th - ph) / qh)
		for q in nq:
			var y := ph + qh * (float(q) + 0.5)
			var long := q % 2 == 0
			lm.box("Trim", face + r * Vector3(tw * 0.5 - (0.6 if long else 0.4), y, 0.06),
				Vector3(1.2 if long else 0.8, qh * 0.9, 0.12), r, 0.0)
		for st in stages:
			var y0 := ph + sh * float(st)
			lm.box("Trim", face + Vector3.UP * (y0 + sh) + n * 0.12 - Vector3.UP * 0.2, Vector3(tw + 0.5, 0.4, 0.24), r)
			if st == stages - 1:
				for s in [-1.0, 1.0]:
					var c := face + r * Vector3(float(s) * tw * 0.2, y0 + sh * 0.45, 0)
					LandmarkDetail.window(lm, "Trim", "Windows", c, n, tw * 0.22, sh * 0.6, true, 0.3)
					for k in 4:
						lm.box("Roof", c + n * 0.08 + Vector3.UP * (-sh * 0.22 + sh * 0.1 * float(k)),
							Vector3(tw * 0.21, 0.1, 0.2), r * Basis(Vector3.RIGHT, 0.5), 0.0)
			elif st == stages - 2:
				var cc := face + n * 0.08 + Vector3.UP * (y0 + sh * 0.5)
				var cr := minf(tw * 0.3, sh * 0.38)
				lm.disc("Trim", cc, n, cr, 24)
				LandmarkCoreBArchKit.ring_beams(lm, "Gilt", cc + n * 0.05, n, cr * 0.95, cr * 0.08, 12)
				lm.beam("Gilt", cc + n * 0.1, cc + n * 0.1 + Vector3.UP * cr * 0.75, cr * 0.07, 0.05)
				lm.beam("Gilt", cc + n * 0.1, cc + n * 0.1 + r * Vector3(cr * 0.5, cr * 0.2, 0), cr * 0.09, 0.05)
			elif st == 0:
				LandmarkDetail.window(lm, "Trim", "Windows", face + Vector3.UP * (y0 + minf(sh * 0.35, 2.0)), n,
					minf(tw * 0.22, 2.4), minf(sh * 0.6, 3.6), true, 0.3)
			else:
				LandmarkDetail.window(lm, "Trim", "Windows", face + Vector3.UP * (y0 + sh * 0.5), n,
					minf(tw * 0.14, 1.4), sh * 0.42, true, 0.25)
		var a := r * Vector3(-tw * 0.5, th, tw * 0.5)
		var b := r * Vector3(tw * 0.5, th, tw * 0.5)
		LandmarkCoreBArchKit.battlement(lm, "Walls", a, b, n, 0.8, maxf(tw * 0.06, 0.5), true)
	# Pyramid roof with lucarnes and the finial.
	var rest := h - th
	var ry := th + 0.5
	var roof_h := rest * 0.86 - 0.5
	lm.spire("Roof", Vector3(0, ry, 0), tw * 0.5, roof_h)
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		var lw := tw * 0.16
		var lc := r * Vector3(0, ry + roof_h * 0.2, tw * 0.5 * 0.72)
		lm.box("Roof", lc + Vector3.UP * lw * 0.6, Vector3(lw, lw * 1.2, lw * 1.4), r)
		lm.box("Windows", lc + r * Vector3(0, lw * 0.55, lw * 0.71), Vector3(lw * 0.55, lw * 0.8, 0.04), r, 0.0)
		lm.gable("Roof", lc + Vector3.UP * lw * 1.2, lw, lw * 1.5, lw * 0.6, r, 0.05)
	var fy := ry + roof_h
	lm.lathe("Gilt", Vector3(0, fy - 0.2, 0), LandmarkCoreBArchKit.dome(rest * 0.03 + 0.2, rest * 0.04 + 0.3, 4), 10)
	lm.frustum("Gilt", Vector3(0, fy, 0), 0.08, 0.04, h - fy, 6)
	lm.beam("Gilt", Vector3(0, h - rest * 0.06, 0), Vector3(rest * 0.06, h - rest * 0.06, 0), 0.06, rest * 0.04)

static func _telecom(lm: LandmarkMesh, h: float, w: float) -> void:
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#CFCBC2", 4.0))
	lm.use("Mast", LandmarkMaterials.paint("#C8CACC", 0.4, 0.6))
	lm.use("Red", LandmarkMaterials.paint("#C23B2E", 0.5, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#FF5A3C", 2.0))
	var r := clampf(h * 0.05, 4.0, maxf(w * 0.2, 4.0))
	var rb := minf(r * 3.2, maxf(w * 0.48, r * 1.8))
	var pod := h * 0.66
	# Base building ring with its window band.
	lm.frustum("Concrete", Vector3.ZERO, rb, rb, 7.0, 32)
	lm.frustum("Windows", Vector3(0, 2.5, 0), rb + 0.02, rb + 0.02, 3.0, 32)
	lm.frustum("Concrete", Vector3(0, 7.0, 0), rb + 0.2, rb + 0.2, 0.6, 32)
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(r * 1.6, 0), Vector2(r * 1.2, h * 0.06),
		Vector2(r, h * 0.14), Vector2(r * 0.72, pod)]), 24)
	# Lift-shaft window slot and service balconies.
	var slot := pod - h * 0.08
	lm.box("Windows", Vector3(0, h * 0.08 + slot * 0.5, -r * 0.86), Vector3(r * 0.25, slot, 0.2), Basis(Vector3.RIGHT, 0.0), 0.0)
	for k in 4:
		var y := pod * (0.25 + 0.17 * float(k))
		var rr := lerpf(r, r * 0.72, (y - h * 0.14) / (pod - h * 0.14))
		lm.frustum("Concrete", Vector3(0, y, 0), rr * 1.25, rr * 1.25, 0.4, 24)
		lm.frustum("Red", Vector3(0, y + 0.4, 0), rr * 1.24, rr * 1.24, 0.08, 24)
	# Antenna platforms with dishes below the pod.
	for k in 2:
		var y := pod - h * (0.07 - 0.03 * float(k))
		lm.frustum("Concrete", Vector3(0, y, 0), r * 1.8, r * 1.8, 0.5, 24)
		for q in 6:
			var a := TAU * (float(q) + 0.5 * float(k)) / 6.0
			var d := Vector3(cos(a), 0, sin(a))
			var dc := d * r * 1.6 + Vector3.UP * (y + 1.6)
			lm.beam("Mast", d * r * 1.3 + Vector3.UP * (y + 0.5), dc, 0.15)
			lm.lathe("Mast", dc, PackedVector2Array([Vector2(0.0, 0), Vector2(0.7, 0.15), Vector2(1.2, 0.45)]), 12, 1.0, 1.0,
				0.0, true, false)
	# Pod: underside, glazed restaurant ring with mullions, open deck.
	lm.lathe("Concrete", Vector3(0, pod, 0), PackedVector2Array([Vector2(r * 0.72, 0),
		Vector2(r * 2.4, h * 0.03), Vector2(r * 2.5, h * 0.035)]), 24, 1.0, 1.0, 0.0, true, false)
	var gy := pod + h * 0.035
	var gh := h * 0.04
	lm.frustum("Windows", Vector3(0, gy, 0), r * 2.5, r * 2.3, gh, 24)
	for k in 24:
		var a := TAU * float(k) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Mast", d * r * 2.51 + Vector3.UP * gy, d * r * 2.31 + Vector3.UP * (gy + gh), 0.18, 0.18)
	lm.frustum("Mast", Vector3(0, gy + gh * 0.5, 0), r * 2.42, r * 2.42, 0.15, 24)
	var dy := gy + gh
	lm.lathe("Concrete", Vector3(0, dy, 0), PackedVector2Array([Vector2(r * 2.3, 0),
		Vector2(r * 1.4, h * 0.03), Vector2(r * 0.6, h * 0.045)]), 24)
	for k in 32:
		var a := TAU * float(k) / 32.0
		lm.box("Mast", Vector3(cos(a), 0, sin(a)) * r * 2.28 + Vector3.UP * (dy + 0.6), Vector3(0.08, 1.1, 0.08), Basis(), 0.0)
	lm.frustum("Mast", Vector3(0, dy + 1.15, 0), r * 2.29, r * 2.29, 0.08, 24)
	# Mast in red-and-white bands with antenna rings and the beacon.
	var my := pod + h * 0.12
	var mh := h - my - 1.0
	var mr := r * 0.25
	for k in 6:
		var t0 := float(k) / 6.0
		var t1 := float(k + 1) / 6.0
		lm.frustum("Red" if k % 2 == 1 else "Mast", Vector3(0, my + mh * t0, 0), lerpf(mr, mr * 0.3, t0),
			lerpf(mr, mr * 0.3, t1), mh / 6.0, 8)
		if k < 4:
			lm.frustum("Mast", Vector3(0, my + mh * (t0 + 0.08), 0), lerpf(mr, mr * 0.3, t0) * 1.8,
				lerpf(mr, mr * 0.3, t0) * 1.8, 0.6, 8)
	lm.frustum("Lamp", Vector3(0, h - 1.0, 0), mr * 0.35, mr * 0.2, 1.0, 8)
