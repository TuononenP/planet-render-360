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
	lm.box(key, base + Vector3(0, h * 0.15, 0), Vector3(h * 0.4, h * 0.3, h * 0.4))
	lm.lathe(key, base + Vector3(0, h * 0.3, 0), PackedVector2Array([Vector2(h * 0.12, 0),
		Vector2(h * 0.2, h * 0.2), Vector2(h * 0.24, h * 0.4), Vector2(h * 0.14, h * 0.6),
		Vector2(h * 0.0, h * 0.7)]), 8)

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
