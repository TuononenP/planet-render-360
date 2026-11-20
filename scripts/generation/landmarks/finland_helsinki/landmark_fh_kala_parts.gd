extends RefCounted

## Curtain-wall parts shared by the five Kalasatama (Redi) towers of Pekka
## Helin & Co: a glazed shaft built over an OSM outline in true metres, one
## ribbon of glass per storey between mullions and floor slabs, optional
## balconies and lit panes, and the glazed crown under a thin projecting
## roof canopy. Each tower class sets its own colours, bay widths, balcony
## pattern and crown; these helpers keep the repeated geometry in one place.
##
## Keys a tower must register: Panel (wall), Glass, Mull, Slab, and for the
## crown Canopy; Rail, Lamp and Beacon are optional.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

## Deterministic 0..1 hash of three ints (lit panes, balcony choice).
static func hash3(a: int, b: int, c: int) -> float:
	var h := (a * 73856093) ^ (b * 19349663) ^ (c * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xffff) / 65535.0

## The glazed shaft of `poly` from y0 to y1. Options in `o`: pitch (storey,
## 3.2), bay (target bay width, 1.4), glass_from/glass_to (fraction of the
## storey the glass spans, 0.14..0.88), mull_w (0.12), slab_h (0.28),
## slab_out (0.1), lit (share of panes lit, 0.0), skip (storeys at the
## foot left unglazed, 0), bal_every / bal_mod / bal_shift (balcony every
## n-th storey on every m-th bay, shifted per storey), bal_out (1.3).
static func shaft(lm: LandmarkMesh, poly: PackedVector2Array, y0: float, y1: float, o: Dictionary = {}) -> void:
	var pitch: float = o.get("pitch", 3.2)
	var bay: float = o.get("bay", 1.4)
	var g0: float = o.get("glass_from", 0.14)
	var g1: float = o.get("glass_to", 0.88)
	var mw: float = o.get("mull_w", 0.12)
	var slab_h: float = o.get("slab_h", 0.28)
	var slab_out: float = o.get("slab_out", 0.1)
	var lit: float = o.get("lit", 0.0)
	var skip: int = o.get("skip", 0)
	var rows := int((y1 - y0) / pitch)
	var seed_i: int = o.get("seed", 1)
	if o.get("wall", true):
		lm.poly_prism("Panel", poly, y0, y1)
	# Floor slabs standing a little proud of the wall.
	if slab_h > 0.0:
		var ring := F.offset(poly, slab_out)
		for r in range(skip, rows + 1):
			var y := y0 + pitch * float(r)
			if y + slab_h <= y1 + 0.01:
				lm.poly_prism("Slab", ring, maxf(y - slab_h * 0.5, y0), y + slab_h * 0.5, false)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var len := a.distance_to(b)
		if len < 2.5:
			continue
		var n := maxi(int(round(len / bay)), 1)
		var along := (b - a) / len
		var out := W.outward(poly, a, b)
		var out3 := Vector3(out.x, 0, out.y)
		var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
		var pa := a + along * 0.45
		var pb := b - along * 0.45
		var span := pa.distance_to(pb)
		var step := span / float(n)
		# Mullions: one full-height member per bay line.
		var first := y0 + pitch * float(skip)
		for k in n + 1:
			var p := pa.lerp(pb, float(k) / float(n)) + out * 0.07
			lm.box("Mull", Vector3(p.x, (first + y1) * 0.5, p.y), Vector3(mw, y1 - first, 0.14), basis, 0.0)
		# Glass ribbon and lit panes per storey.
		for r in range(skip, rows):
			var yb := y0 + pitch * (float(r) + g0)
			var yt := y0 + pitch * (float(r) + g1)
			var q0 := Vector3(pa.x, yb, pa.y) + out3 * 0.05
			var q1 := Vector3(pb.x, yb, pb.y) + out3 * 0.05
			lm.quad("Glass", q0, q1, q1 + Vector3(0, yt - yb, 0), q0 + Vector3(0, yt - yb, 0), out3)
			if lit > 0.0:
				for k in n:
					if hash3(i + seed_i * 31, r, k) < lit:
						var s0 := pa + along * (step * float(k) + mw)
						var s1 := pa + along * (step * float(k + 1) - mw)
						var l0 := Vector3(s0.x, yb + 0.1, s0.y) + out3 * 0.08
						var l1 := Vector3(s1.x, yb + 0.1, s1.y) + out3 * 0.08
						lm.quad("Lamp", l0, l1, l1 + Vector3(0, yt - yb - 0.2, 0), l0 + Vector3(0, yt - yb - 0.2, 0), out3)
		# Balconies: a slab with a glass rail on chosen bays.
		var every: int = o.get("bal_every", 0)
		if every > 0:
			var bmod: int = maxi(o.get("bal_mod", 3), 1)
			var bout: float = o.get("bal_out", 1.3)
			for r in range(skip + 1, rows):
				if r % every != 0:
					continue
				for k in n:
					if (k + r * int(o.get("bal_shift", 1))) % bmod != 0:
						continue
					var c := pa.lerp(pb, (float(k) + 0.5) / float(n)) + out * (bout * 0.5 + 0.1)
					var y := y0 + pitch * float(r)
					lm.box("Slab", Vector3(c.x, y, c.y), Vector3(step * 0.94, 0.2, bout), basis, 0.0)
					lm.box("Rail", Vector3(c.x, y + 0.6, c.y) + Vector3(out.x, 0, out.y) * (bout * 0.5 - 0.04),
						Vector3(step * 0.94, 1.0, 0.05), basis, 0.0)

## The glazed top storey and its roof canopy. `y` is the shaft top; options
## in `o`: lounge (glazed storey height, 3.6), inset (recess of the glass
## from the wall, 0.8), ov (canopy overhang past the wall, 2.0), shift
## (canopy offset, Vector2, 0), t (canopy thickness, 0.45), struts (corner
## struts up to the canopy, true), lamp (lit lounge, true). The canopy top
## lands on y + lounge + t.
static func crown(lm: LandmarkMesh, poly: PackedVector2Array, y: float, o: Dictionary = {}) -> float:
	var lounge: float = o.get("lounge", 3.6)
	var inset: float = o.get("inset", 0.8)
	var ov: float = o.get("ov", 2.0)
	var shift: Vector2 = o.get("shift", Vector2.ZERO)
	var t: float = o.get("t", 0.45)
	var core := F.offset(poly, -inset)
	if core.size() < 3:
		core = poly
	var glass_key: String = "Lamp" if o.get("lamp", true) else "Glass"
	lm.poly_prism("Slab", F.offset(poly, 0.12), y, y + 0.35)
	lm.poly_prism(glass_key, core, y + 0.35, y + lounge, false)
	W.ribs(lm, "Mull", core, y + 0.35, y + lounge, 2.4, 0.1, 0.1)
	var canopy := F.offset(poly, ov)
	var shifted := PackedVector2Array()
	for p in canopy:
		shifted.append(p + shift)
	var top := y + lounge
	lm.poly_prism("Canopy", shifted, top, top + t)
	if o.get("struts", true):
		var cnt := 0
		for i in core.size():
			var p := core[i]
			var q := p + shift * 0.5
			if p.distance_to(core[(i + core.size() - 1) % core.size()]) < 1.5:
				continue
			lm.beam("Mull", Vector3(p.x, y + 0.35, p.y), Vector3(q.x, top, q.y), 0.14)
			cnt += 1
			if cnt > 6:
				break
	return top + t

## Red aviation lights on the canopy corners: small lit boxes, with the halo
## list the caller may hand to LandmarkLights.HALO_META.
static func beacons(lm: LandmarkMesh, poly: PackedVector2Array, y: float, o: Dictionary = {}) -> Array:
	var halos: Array = []
	var big := F.offset(poly, float(o.get("ov", 2.0)))
	var shift: Vector2 = o.get("shift", Vector2.ZERO)
	var picks := [0, big.size() / 2]
	for idx in picks:
		var p: Vector2 = big[idx] + shift
		lm.box("Beacon", Vector3(p.x, y + 0.2, p.y), Vector3(0.4, 0.4, 0.4))
		halos.append([Vector3(p.x, y + 0.2, p.y), 2.2, Color(1.0, 0.1, 0.05)])
	return halos
