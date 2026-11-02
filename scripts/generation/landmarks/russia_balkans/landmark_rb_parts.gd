class_name LandmarkRbParts
extends RefCounted

## Shared parts for the Russia and Balkans landmark batch, in true metres
## on LandmarkMesh: Orthodox crosses, domes on drums, classical porticoes,
## steps, roof statues and parapets. Each takes the material KEY to draw
## with (registered by the caller with lm.use).

## Basis whose Z axis is the horizontal unit `out` and whose X axis is
## the viewer's right when looking at a face that looks along `out`.
static func facing(out: Vector3) -> Basis:
	var z := Vector3(out.x, 0, out.z).normalized()
	return Basis(Vector3.UP.cross(z), Vector3.UP, z)

## Eastern Orthodox cross of height h standing on `base`, in the X-Y plane:
## upright, main bar, short top bar and the slanted foot bar.
static func cross(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	var w := maxf(h * 0.06, 0.08)
	lm.beam(key, base, base + Vector3(0, h, 0), w, w)
	lm.beam(key, base + Vector3(-h * 0.2, h * 0.68, 0), base + Vector3(h * 0.2, h * 0.68, 0), w, w)
	lm.beam(key, base + Vector3(-h * 0.11, h * 0.86, 0), base + Vector3(h * 0.11, h * 0.86, 0), w, w)
	lm.beam(key, base + Vector3(-h * 0.1, h * 0.2, 0), base + Vector3(h * 0.1, h * 0.12, 0), w, w)

## Drum with a cornice ring, an onion dome and a cross on `base`; the
## cross tip stands at base.y + drum_h + r * 0.1 + dome_h + cross_h.
static func onion_on_drum(lm: LandmarkMesh, wall: String, dome: String, gilt: String,
		base: Vector3, r: float, drum_h: float, dome_h: float, cross_h: float, seg: int = 16) -> void:
	lm.frustum(wall, base, r, r, drum_h, seg)
	lm.frustum(wall, base + Vector3(0, drum_h, 0), r * 1.08, r * 1.08, r * 0.1, seg)
	var top := base + Vector3(0, drum_h + r * 0.1, 0)
	LandmarkCeParts.onion(lm, dome, top, r * 1.1, dome_h, seg)
	cross(lm, gilt, top + Vector3(0, dome_h, 0), cross_h)

## Round dome profile (radius, y): half ellipse of radius r and height h
## closed at the apex.
static func dome_profile(r: float, h: float, steps: int = 8) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var a := PI * 0.5 * float(i) / steps
		p.append(Vector2(r * cos(a), h * sin(a)))
	p[steps] = Vector2(0.0, h)
	return p

## Small figure on a pedestal for roof balustrades (coarse, 5 sided).
static func roof_statue(lm: LandmarkMesh, key: String, base: Vector3, h: float, pedestal: float = 1.2) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(0.55, 0), Vector2(0.55, pedestal),
		Vector2(h * 0.17, pedestal + 0.1), Vector2(h * 0.14, pedestal + h * 0.5),
		Vector2(h * 0.08, pedestal + h * 0.85), Vector2(0.0, pedestal + h)]), 5, 1.0, 0.8, 0.0, false, false)

## Urn on a pedestal (roof vases).
static func urn(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.box(key, base + Vector3(0, h * 0.15, 0), Vector3(h * 0.4, h * 0.3, h * 0.4), Basis(), 0.0)
	lm.lathe(key, base + Vector3(0, h * 0.3, 0), PackedVector2Array([Vector2(h * 0.12, 0),
		Vector2(h * 0.2, h * 0.2), Vector2(h * 0.24, h * 0.4), Vector2(h * 0.14, h * 0.6),
		Vector2(h * 0.0, h * 0.7)]), 6)

## Low parapet from `a` to `b` (both at the parapet foot): a `h` high,
## `t` thick wall under a slightly wider cap.
static func parapet(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float, t: float = 0.5) -> void:
	lm.beam(key, a + Vector3(0, h * 0.5, 0), b + Vector3(0, h * 0.5, 0), t, h)
	lm.beam(key, a + Vector3(0, h + 0.1, 0), b + Vector3(0, h + 0.1, 0), t * 1.5, 0.2)

## Stair of `n` steps climbing toward the wall: the top tread meets the
## wall at `c` (ground), the flight runs out along `dir`, `width` wide.
## Steps are separate slabs, so nothing overlaps.
static func steps(lm: LandmarkMesh, key: String, c: Vector3, dir: Vector3, width: float,
		tread: float, riser: float, n: int) -> void:
	var basis := facing(dir)
	for k in n:
		var hgt := riser * float(n - k)
		lm.box(key, c + dir * (tread * (float(k) + 0.5)) + Vector3(0, hgt * 0.5, 0),
			Vector3(width, hgt, tread), basis)

## Column with a plain capital block: shaft radius r at the foot, 0.9 r
## at the neck, `h` tall including the capital.
static func column(lm: LandmarkMesh, shaft: String, cap: String, base: Vector3, r: float,
		h: float, seg: int = 10) -> void:
	var cap_h := r * 0.9
	lm.lathe(shaft, base, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.9, h - cap_h)]), seg,
		1.0, 1.0, 0.0, seg > 8, false)
	lm.box(cap, base + Vector3(0, h - cap_h * 0.5, 0), Vector3(r * 2.5, cap_h, r * 2.5))

## Classical portico on a wall face: `n` columns across at `pitch`, `rows`
## deep at `row_pitch`, an entablature of height `ent_h` and a pediment
## rising `rise`. `o` is the centre of the wall face at ground, `out` the
## horizontal face normal. Returns the y of the pediment base.
static func portico(lm: LandmarkMesh, shaft: String, trim: String, o: Vector3, out: Vector3,
		n: int, pitch: float, rows: int, row_pitch: float, r: float, col_h: float,
		ent_h: float, rise: float) -> float:
	var basis := facing(out)
	var right := basis.x
	var span := float(n - 1) * pitch + r * 5.0
	var depth := float(rows) * row_pitch
	for row in rows:
		var d := row_pitch * (float(row) + 0.5)
		for i in n:
			var s := (float(i) - float(n - 1) * 0.5) * pitch
			column(lm, shaft, trim, o + right * s + out * d, r, col_h)
	lm.box(trim, o + out * (depth * 0.5) + Vector3(0, col_h + ent_h * 0.5, 0), Vector3(span, ent_h, depth + 0.6), basis)
	lm.gable(trim, o + out * (depth * 0.5) + Vector3(0, col_h + ent_h, 0), span - 0.6, depth + 0.6, rise,
		basis, 0.3, trim)
	return col_h + ent_h

## Round-headed dark window recesses `n` across, at height `y`, on a wall
## face centred at `o` (ground) running along `right` with normal `out`.
static func windows(lm: LandmarkMesh, key: String, o: Vector3, right: Vector3, out: Vector3,
		y: float, n: int, pitch: float, w: float, h: float, pointed: bool = false) -> void:
	SEuUtil.face_row(lm, key, o, right, out, y, n, pitch, w, h, pointed)

## Plain rectangular window pane (two triangles) standing on `o` (bottom
## centre), facing `out`, running along `right`.
static func pane(lm: LandmarkMesh, key: String, o: Vector3, right: Vector3, out: Vector3,
		w: float, h: float) -> void:
	var hw := right * (w * 0.5)
	var up := Vector3(0, h, 0)
	lm.quad(key, o - hw, o + hw, o + hw + up, o - hw + up, out)

## Ring of `n` columns on a circle (peristyle) around `c` at ground.
static func peristyle(lm: LandmarkMesh, shaft: String, cap: String, c: Vector3, rad: float,
		n: int, r: float, h: float, start: float = 0.0) -> void:
	for i in n:
		var a := start + TAU * float(i) / float(n)
		column(lm, shaft, cap, c + Vector3(cos(a) * rad, 0, sin(a) * rad), r, h, 8)

## Classical column for long façade runs, about 200 triangles at 10
## sides (lighter than LandmarkDetail.column): square plinth, attic base
## mouldings, a shaft with entasis and a capital: "corinthian" (acanthus
## bell, one leaf tier, two at 16+ sides, corner volutes), "ionic"
## (volutes on the face looking along `face`) or Tuscan. `h` runs from
## the plinth foot to the top of the abacus; base and capital draw in
## `cap` when set (bronze capitals on granite shafts).
static func order_column(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		order: String = "corinthian", face: Vector3 = Vector3(0, 0, 1), seg: int = 10, cap: String = "") -> void:
	var ck := key if cap == "" else cap
	var base_h := r * 0.9
	var cap_h := r * (2.2 if order == "corinthian" else (1.2 if order == "ionic" else 0.8))
	lm.box(ck, base + Vector3(0, base_h * 0.2, 0), Vector3(r * 2.6, base_h * 0.4, r * 2.6), Basis(), 0.0)
	var torus := PackedVector2Array([Vector2(r * 1.25, 0), Vector2(r * 1.3, base_h * 0.2),
		Vector2(r * 1.08, base_h * 0.35), Vector2(r * 1.14, base_h * 0.5), Vector2(r * 1.02, base_h * 0.6)])
	if seg < 10:
		torus = PackedVector2Array([Vector2(r * 1.28, 0), Vector2(r * 1.2, base_h * 0.3), Vector2(r * 1.02, base_h * 0.6)])
	lm.lathe(ck, base + Vector3(0, base_h * 0.4, 0), torus, seg, 1.0, 1.0, 0.0, true, false)
	var sh := h - base_h - cap_h
	var sb := base + Vector3(0, base_h, 0)
	lm.lathe(key, sb, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.98, sh * 0.35),
		Vector2(r * 0.86, sh)]), seg, 1.0, 1.0, 0.0, true, false)
	var cb := sb + Vector3(0, sh, 0)
	var ra := r * 0.86
	var fb := facing(face)
	match order:
		"corinthian":
			lm.lathe(ck, cb, PackedVector2Array([Vector2(ra * 1.06, 0), Vector2(ra, cap_h * 0.08),
				Vector2(ra * 1.04, cap_h * 0.5), Vector2(ra * 1.3, cap_h * 0.85)]), seg, 1.0, 1.0, 0.0, true, false)
			var tiers := 2 if seg >= 16 else 1
			for tier in tiers:
				for i in 8:
					var a := TAU * (float(i) + 0.5 * float(tier) + 0.5) / 8.0
					var d := Vector3(cos(a), 0, sin(a))
					var tall := 0.62 if (i + tier) % 2 == 0 else 0.4
					var lb := cb + d * ra + Vector3(0, cap_h * 0.25 * float(tier), 0)
					lm.beam(ck, lb, lb + d * r * 0.36 + Vector3(0, cap_h * tall, 0), r * 0.55, r * 0.12,
						d.cross(Vector3.UP))
			for i in 4:
				var a := TAU * (float(i) + 0.5) / 4.0 + PI * 0.25
				var d := Vector3(cos(a), 0, sin(a))
				lm.beam(ck, cb + d * ra + Vector3(0, cap_h * 0.55, 0), cb + d * r * 1.6 + Vector3(0, cap_h * 0.86, 0),
					r * 0.2)
			lm.box(ck, cb + Vector3(0, cap_h * 0.93, 0), Vector3(r * 2.9, cap_h * 0.14, r * 2.9), fb, 0.0)
		"ionic":
			lm.lathe(ck, cb, PackedVector2Array([Vector2(ra, 0), Vector2(ra * 1.15, cap_h * 0.35)]), seg,
				1.0, 1.0, 0.0, true, false)
			lm.box(ck, cb + Vector3(0, cap_h * 0.55, 0), Vector3(r * 2.8, cap_h * 0.4, r * 1.8), fb, 0.0)
			for s in [-1.0, 1.0]:
				for f in [-1.0, 1.0]:
					lm.disc(ck, cb + fb.x * (s * r * 1.15) + fb.z * (f * r * 0.92) + Vector3(0, cap_h * 0.5, 0),
						fb.z * f, r * 0.42, 8)
			lm.box(ck, cb + Vector3(0, cap_h * 0.87, 0), Vector3(r * 2.7, cap_h * 0.26, r * 2.7), fb, 0.0)
		_:
			lm.lathe(ck, cb, PackedVector2Array([Vector2(ra * 1.06, 0), Vector2(ra * 1.06, cap_h * 0.15),
				Vector2(ra, cap_h * 0.2), Vector2(ra * 1.4, cap_h * 0.62)]), seg, 1.0, 1.0, 0.0, true, false)
			lm.box(ck, cb + Vector3(0, cap_h * 0.81, 0), Vector3(r * 2.6, cap_h * 0.38, r * 2.6), fb, 0.0)

## Square pilaster on a wall face (`out` its normal, `base` on the face
## at the foot): plinth, shaft and a moulded capital block.
static func pilaster(lm: LandmarkMesh, key: String, base: Vector3, out: Vector3, w: float, h: float,
		d: float = 0.35) -> void:
	var b := facing(out)
	lm.box(key, base + out * (d * 0.65) + Vector3(0, w * 0.35, 0), Vector3(w * 1.25, w * 0.7, d * 1.3), b, 0.0)
	lm.box(key, base + out * (d * 0.5) + Vector3(0, h * 0.5, 0), Vector3(w, h - w * 0.6, d), b, 0.0)
	lm.box(key, base + out * (d * 0.7) + Vector3(0, h - w * 0.3, 0), Vector3(w * 1.3, w * 0.6, d * 1.4), b, 0.0)

## Light balustrade from `a` to `b` (both at its foot), for long roof
## runs: plinth, handrail, square balusters at `pitch` and a pedestal
## every `bay` metres.
static func balustrade(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float = 1.0,
		pitch: float = 0.55, bay: float = 5.0) -> void:
	var dl := a.distance_to(b)
	if dl < 0.5:
		return
	var dir := (b - a) / dl
	var bs := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var mid := (a + b) * 0.5
	lm.box(key, mid + Vector3(0, h * 0.07, 0), Vector3(dl, h * 0.14, h * 0.32), bs, 0.0)
	lm.box(key, mid + Vector3(0, h * 0.92, 0), Vector3(dl, h * 0.16, h * 0.36), bs, 0.0)
	var n := int(dl / pitch)
	for i in n:
		lm.box(key, a + dir * (pitch * (float(i) + 0.5)) + Vector3(0, h * 0.5, 0),
			Vector3(h * 0.16, h * 0.7, h * 0.16), bs, 0.0)
	var piers := maxi(int(dl / bay), 1)
	for i in piers + 1:
		lm.box(key, a.lerp(b, float(i) / float(piers)) + Vector3(0, h * 0.5, 0), Vector3(h * 0.4, h, h * 0.4), bs, 0.0)

## Robed roof statue of height h on a pedestal (about 120 triangles):
## draped body, shoulders, head and two arms.
static func figure(lm: LandmarkMesh, key: String, base: Vector3, h: float, pedestal: float = 1.0) -> void:
	lm.box(key, base + Vector3(0, pedestal * 0.5, 0), Vector3(h * 0.36, pedestal, h * 0.36), Basis(), 0.0)
	var b := base + Vector3(0, pedestal, 0)
	lm.lathe(key, b, PackedVector2Array([Vector2(h * 0.15, 0), Vector2(h * 0.13, h * 0.3),
		Vector2(h * 0.1, h * 0.55), Vector2(h * 0.12, h * 0.72), Vector2(h * 0.06, h * 0.8)]), 6, 1.0, 0.75)
	lm.lathe(key, b + Vector3(0, h * 0.8, 0), PackedVector2Array([Vector2(h * 0.03, 0),
		Vector2(h * 0.06, h * 0.06), Vector2(h * 0.05, h * 0.15), Vector2(0.0, h * 0.2)]), 6)
	for s in [-1.0, 1.0]:
		var sh := b + Vector3(s * h * 0.11, h * 0.7, 0)
		lm.beam(key, sh, sh + Vector3(s * h * 0.04, -h * 0.18, h * 0.06), h * 0.05)
		lm.beam(key, sh + Vector3(s * h * 0.04, -h * 0.18, h * 0.06), sh + Vector3(0, -h * 0.2, h * 0.16), h * 0.045)

## Round-arched kokoshnik gable (the Russian ogee/semicircular gable) of
## width w standing on `c` (centre of its foot on the wall face) facing
## `out`: a curved band of `depth` with an infill shield.
static func kokoshnik(lm: LandmarkMesh, band: String, fill: String, c: Vector3, out: Vector3, w: float,
		depth: float = 0.5, ogee: bool = false) -> void:
	var right := facing(out).x
	var r := w * 0.5
	var bw := maxf(w * 0.09, 0.15)
	var pts: Array[Vector3] = []
	var n := 8
	for i in n + 1:
		var t := PI * float(i) / float(n)
		var y := sin(t) * r
		if ogee:
			y = sin(t) * r * 1.15 + (r * 0.45 * pow(sin(t), 6.0))
		pts.append(c + right * (cos(t) * r) + Vector3(0, y, 0))
	for i in n:
		lm.beam(band, pts[i] + out * (depth * 0.5), pts[i + 1] + out * (depth * 0.5), depth, bw, out)
	for i in n:
		lm.tri(fill, c + out * 0.06, pts[i] + out * 0.06, pts[i + 1] + out * 0.06, out, out, out,
			Vector2.ZERO, Vector2(cos(PI * float(i) / n), 0.5), Vector2(cos(PI * float(i + 1) / n), 0.5))

## Onion dome of radius r, height h at `base`, in `n` vertical gores
## cycling through the material `keys` (the enamelled and gilded
## patterned domes); `twist` turns the gores into spiral bands, `sub`
## splits each gore for a rounder shell.
static func striped_onion(lm: LandmarkMesh, keys: Array, base: Vector3, r: float, h: float,
		n: int = 12, twist: float = 0.0, sub: int = 2) -> void:
	var prof := PackedVector2Array([Vector2(r * 0.55, 0), Vector2(r * 0.85, h * 0.07),
		Vector2(r, h * 0.24), Vector2(r * 0.92, h * 0.42), Vector2(r * 0.58, h * 0.62),
		Vector2(r * 0.22, h * 0.82), Vector2(0.0, h)])
	var m := n * sub
	for g in m:
		var key: String = keys[(g / sub) % keys.size()]
		for j in prof.size() - 1:
			var p0 := prof[j]
			var p1 := prof[j + 1]
			var tw0 := twist * p0.y / h
			var tw1 := twist * p1.y / h
			var a0 := TAU * float(g) / float(m)
			var a1 := TAU * float(g + 1) / float(m)
			var v00 := base + Vector3(cos(a0 + tw0) * p0.x, p0.y, sin(a0 + tw0) * p0.x)
			var v10 := base + Vector3(cos(a1 + tw0) * p0.x, p0.y, sin(a1 + tw0) * p0.x)
			var v01 := base + Vector3(cos(a0 + tw1) * p1.x, p1.y, sin(a0 + tw1) * p1.x)
			var v11 := base + Vector3(cos(a1 + tw1) * p1.x, p1.y, sin(a1 + tw1) * p1.x)
			var dp := p1 - p0
			var n0 := (Vector3(cos(a0 + tw0), 0, sin(a0 + tw0)) * dp.y - Vector3.UP * dp.x).normalized()
			var n1 := (Vector3(cos(a1 + tw0), 0, sin(a1 + tw0)) * dp.y - Vector3.UP * dp.x).normalized()
			var u0 := Vector2(a0 * r, -p0.y)
			var u1 := Vector2(a1 * r, -p1.y)
			if p0.x > 0.0001:
				lm.tri(key, v00, v10, v11, n0, n1, n1, u0, Vector2(u1.x, u0.y), u1)
			if p1.x > 0.0001:
				lm.tri(key, v00, v11, v01, n0, n1, n0, u0, u1, Vector2(u0.x, u1.y))
