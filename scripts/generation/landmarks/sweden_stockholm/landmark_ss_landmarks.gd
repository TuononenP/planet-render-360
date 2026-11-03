class_name LandmarkSsLandmarks
extends RefCounted

## Three modern Stockholm landmarks in true metres (+X east, +Z south,
## origin at the OSM footprint centre, registry yaw 0 so the models keep
## their real compass bearings):
## - Avicii Arena (the Ericsson Globe, Berg Arkitektkontor 1989): the
##   world's largest spherical building, 110 m across and 85 m high
##   (Wikipedia; OSM way 25431325 height 85), its white skin of panel
##   rings and meridians, the 20 m podium of concourses (OSM way
##   109511512) with the glazed entrances, and the SkyView: two glass
##   gondolas on parallel tracks up the south side.
## - Kaknäs Tower (Borgström & Lindroos 1967): the slip-formed concrete
##   shaft whose plan is a 15.1 m square crossed by an equal square turned
##   45° (OSM way 593144774), the head of restaurant and observation floors
##   turned 45° to the shaft, gold-filmed glazing, 155 m roof and the mast
##   to 170 m (sv.wikipedia, Structurae).
## - Vasa Museum (Månsson & Dahlbäck 1990) over the 1878 Galärvarvet dry
##   dock: the nineteen OSM 3D parts of way 27288534 (skillion roofs 12 to
##   41 m) clad in Falu red, ochre and tar-black boarding under dark copper
##   roofs, and the three masts on the ship hall showing Vasa's rigged
##   height, 52.5 m (Chalmers Architecture, vasamuseet.se).

const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

# --- Avicii Arena (Ericsson Globe) -------------------------------------

const GLOBE_R := 55.0
## Sphere centre above the base: the top at 85 m, the 110 m equator at 30 m.
const GLOBE_CY := 30.0
const PODIUM_H := 7.0
const PODIUM_R := 64.0
const TIER_H := 12.0
const TIER_R := 58.0
## SkyView: track centre azimuths either side of south and the angle
## (latitude on the sphere) each rail starts and ends at.
const SKY_AZ := [-0.07, 0.07]
const SKY_PHI0 := -0.33
const SKY_PHI1 := 1.26

## The Globe: the white sphere truncated at the ground, its skin of
## panel rings (every 4°) and meridians (every 7.5°), the concourse podium
## of two glazed tiers with the north block on Globentorget, entrance
## canopies, and SkyView's twin tracks, station and spherical gondolas.
static func globe(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Skin", LandmarkMaterials.pbr("render", "#EDEFEC", 4.0, 0.42, 0.08))
	lm.use("Seam", LandmarkMaterials.paint("#C4C9CC", 0.5, 0.35))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#8F8C86", 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("pavement", "#77746F", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#26303A"))
	lm.use("Steel", LandmarkMaterials.paint("#4E545A", 0.45, 0.6))
	lm.use("Cabin", LandmarkMaterials.glass("#4A6276"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF1D6", 0.8))
	var c := Vector3(0, GLOBE_CY, 0)
	var phi0 := asin(-GLOBE_CY / GLOBE_R)
	var prof := PackedVector2Array()
	var steps := 40
	for i in steps + 1:
		var phi := lerpf(phi0, PI * 0.5, float(i) / float(steps))
		prof.append(Vector2(GLOBE_R * cos(phi), GLOBE_CY + GLOBE_R * sin(phi)))
	prof[steps] = Vector2(0.0, GLOBE_CY + GLOBE_R)
	lm.lathe("Skin", Vector3.ZERO, prof, 64)
	# Panel rings every 4° from the podium to the crown, meridians every
	# 7.5° (every other one stops short so they do not crowd the top).
	var k := -16
	while k <= 84:
		_lat_band(lm, "Seam", c, GLOBE_R + 0.09, deg_to_rad(float(k)), 0.14, 96)
		k += 4
	for m in 48:
		var top := 82.0 if m % 2 == 0 else 66.0
		_meridian(lm, "Seam", c, GLOBE_R + 0.1, TAU * float(m) / 48.0, deg_to_rad(-20.0), deg_to_rad(top), 0.14)
	lm.box("Lamp", c + Vector3(0, GLOBE_R + 0.2, 0), Vector3(0.5, 0.4, 0.5))
	_globe_podium(lm)
	_skyview(lm, c)
	lm.commit(model)

## A thin latitude band on the sphere (centre c, radius r) at latitude
## phi, `w` metres wide, as a ring of quads standing just proud.
static func _lat_band(lm: LandmarkMesh, key: String, c: Vector3, r: float, phi: float, w: float, seg: int) -> void:
	var dp := w * 0.5 / r
	for i in seg:
		var t0 := TAU * float(i) / float(seg)
		var t1 := TAU * float(i + 1) / float(seg)
		var a0 := _sph(c, r, t0, phi - dp)
		var a1 := _sph(c, r, t1, phi - dp)
		var b1 := _sph(c, r, t1, phi + dp)
		var b0 := _sph(c, r, t0, phi + dp)
		lm.quad(key, a0, a1, b1, b0, ((a0 + b1) * 0.5 - c).normalized())

## A thin meridian strip at azimuth `az` from latitude p0 to p1.
static func _meridian(lm: LandmarkMesh, key: String, c: Vector3, r: float, az: float, p0: float, p1: float,
		w: float) -> void:
	var n := maxi(int((p1 - p0) / deg_to_rad(3.0)), 2)
	for i in n:
		var q0 := lerpf(p0, p1, float(i) / float(n))
		var q1 := lerpf(p0, p1, float(i + 1) / float(n))
		var da0 := w * 0.5 / (r * maxf(cos(q0), 0.05))
		var da1 := w * 0.5 / (r * maxf(cos(q1), 0.05))
		var a0 := _sph(c, r, az - da0, q0)
		var a1 := _sph(c, r, az + da0, q0)
		var b1 := _sph(c, r, az + da1, q1)
		var b0 := _sph(c, r, az - da1, q1)
		lm.quad(key, a0, a1, b1, b0, ((a0 + b1) * 0.5 - c).normalized())

## Point on a sphere: azimuth `az` measured from +Z (south) toward +X,
## latitude `phi` above the equator.
static func _sph(c: Vector3, r: float, az: float, phi: float) -> Vector3:
	return c + Vector3(sin(az) * cos(phi), sin(phi), cos(az) * cos(phi)) * r

## The concourse podium: a glazed lower tier with a concrete fascia and
## deck, the set-back upper tier, the rectangular north block on
## Globentorget and the east block (OSM way 109511512), entrance canopies
## on posts and lamp heads along the deck.
static func _globe_podium(lm: LandmarkMesh) -> void:
	lm.frustum("Podium", Vector3.ZERO, PODIUM_R, PODIUM_R, 0.6, 48)
	lm.lathe("Glass", Vector3(0, 0.6, 0), PackedVector2Array([Vector2(PODIUM_R - 0.6, 0), Vector2(PODIUM_R - 0.6, 5.0)]),
		48, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Podium", Vector3(0, 5.6, 0), PackedVector2Array([Vector2(PODIUM_R - 0.6, 0), Vector2(PODIUM_R, 0.0),
		Vector2(PODIUM_R, PODIUM_H - 5.6)]), 48)
	# Mullions round the lower tier, parapet posts on its deck.
	for i in 72:
		var a := TAU * float(i) / 72.0
		var d := Vector3(sin(a), 0, cos(a))
		lm.box("Steel", d * (PODIUM_R - 0.45) + Vector3(0, 3.1, 0), Vector3(0.18, 5.0, 0.18),
			Basis(Vector3.UP, a), 0.0)
	lm.lathe("Steel", Vector3(0, PODIUM_H, 0), PackedVector2Array([Vector2(PODIUM_R - 0.1, 0),
		Vector2(PODIUM_R - 0.1, 1.1)]), 48, 1.0, 1.0, 0.0, true, false)
	# Upper tier: concrete with a ribbon window.
	lm.frustum("Podium", Vector3(0, PODIUM_H, 0), TIER_R, TIER_R, 1.2, 48)
	lm.lathe("Glass", Vector3(0, PODIUM_H + 1.2, 0), PackedVector2Array([Vector2(TIER_R - 0.4, 0),
		Vector2(TIER_R - 0.4, 2.4)]), 48, 1.0, 1.0, 0.0, true, false)
	lm.frustum("Podium", Vector3(0, PODIUM_H + 3.6, 0), TIER_R, TIER_R, TIER_H - PODIUM_H - 3.6, 48)
	# North block (Globentorget) and east block, 12 m, glass between
	# concrete floor bands.
	for b in [[6.0, -55.0, 116.0, 26.0], [58.5, -35.0, 11.0, 32.0]]:
		var bx: float = b[0]
		var bz: float = b[1]
		var bw: float = b[2]
		var bd: float = b[3]
		FhU.blk(lm, "Glass", bx, 0.0, bz, bw - 0.6, TIER_H, bd - 0.6)
		for y in [0.0, 5.4, 10.4]:
			FhU.blk(lm, "Podium", bx, float(y), bz, bw, 1.6 if y > 10.0 else 1.2, bd)
		var n := int(bw / 3.0)
		for s: float in [-1.0, 1.0]:
			FhP.ribs(lm, "Steel", Vector3(bx - bw * 0.5, 0, bz + s * bd * 0.5), Vector3(bx + bw * 0.5, 0, bz + s * bd * 0.5),
				Vector3(0, 0, s), 1.2, 10.4, bw / float(n), 0.16, 0.12)
	# Entrance canopies on posts: north-west toward the metro, west, east.
	for a_deg in [210.0, 270.0, 95.0, 160.0]:
		var a := deg_to_rad(float(a_deg))
		var d := Vector3(sin(a), 0, cos(a))
		var side := Vector3(d.z, 0, -d.x)
		var p := d * (PODIUM_R + 4.0)
		lm.box("Podium", p + Vector3(0, 5.2, 0), Vector3(14.0, 0.5, 8.0), Basis(Vector3.UP, a + PI * 0.5))
		for s: float in [-1.0, 1.0]:
			for f: float in [0.0, 1.0]:
				var q: Vector3 = p + side * s * 6.4 + d * (3.4 * float(f))
				lm.frustum("Steel", q, 0.2, 0.2, 5.0, 8)
		lm.box("Lamp", p + Vector3(0, 4.9, 0), Vector3(10.0, 0.08, 1.0), Basis(Vector3.UP, a + PI * 0.5), 0.0)
	for i in 16:
		var a := TAU * (float(i) + 0.5) / 16.0
		var q := Vector3(sin(a), 0, cos(a)) * (PODIUM_R - 2.0) + Vector3(0, PODIUM_H, 0)
		lm.frustum("Steel", q, 0.08, 0.06, 4.0, 6)
		lm.box("Lamp", q + Vector3(0, 4.1, 0), Vector3(0.35, 0.25, 0.35))

## SkyView on the south face: two tracks of twin steel rails on stand-off
## brackets with cross ties, the glazed boarding station on the upper
## tier, and the two spherical glass gondolas with their frames and
## bogies (one near the top, one leaving the station).
static func _skyview(lm: LandmarkMesh, c: Vector3) -> void:
	var rr := GLOBE_R + 1.0
	var n := 40
	for az: float in SKY_AZ:
		var e := Vector3(cos(az), 0, -sin(az))
		for side: float in [-1.0, 1.0]:
			var prev := _sph(c, rr, az, SKY_PHI0) + e * 0.9 * side
			for i in n:
				var phi := lerpf(SKY_PHI0, SKY_PHI1, float(i + 1) / float(n))
				var p := _sph(c, rr, az, phi) + e * 0.9 * side
				lm.beam("Steel", prev, p, 0.22, 0.3, e)
				prev = p
		for i in n + 1:
			var phi := lerpf(SKY_PHI0, SKY_PHI1, float(i) / float(n))
			var mid := _sph(c, rr, az, phi)
			lm.beam("Steel", mid - e * 1.0, mid + e * 1.0, 0.16, 0.16)
			if i % 3 == 0:
				lm.beam("Steel", _sph(c, GLOBE_R, az, phi), mid, 0.3, 0.3)
	# Boarding station on the upper tier at the foot of both tracks.
	var st := _sph(c, GLOBE_R, 0.0, SKY_PHI0)
	var sz := maxf(st.z, TIER_R - 4.0)
	FhU.blk(lm, "Glass", 0.0, TIER_H, sz, 15.0, 4.6, 7.0)
	FhU.blk(lm, "Podium", 0.0, TIER_H + 4.6, sz, 15.8, 0.6, 7.6)
	for x in [-7.2, -2.4, 2.4, 7.2]:
		FhU.blk(lm, "Steel", float(x), TIER_H, sz + 3.45, 0.16, 4.6, 0.16)
	# Gondolas: a glass ball (4.2 m) in a steel ring, hung off a bogie.
	var stops := [[SKY_AZ[0], 1.08], [SKY_AZ[1], -0.12]]
	for g in stops:
		var az: float = g[0]
		var phi: float = g[1]
		var gc := _sph(c, GLOBE_R + 3.3, az, phi)
		var out := (gc - c).normalized()
		lm.lathe("Cabin", gc - Vector3(0, 2.1, 0), FhU.ball(2.1), 16)
		FhP.ring(lm, "Steel", gc, Vector3.UP, 2.05, 2.3, 0.16, 20)
		FhP.ring(lm, "Steel", gc, Vector3(cos(az), 0, -sin(az)), 2.05, 2.25, 0.12, 20)
		lm.beam("Steel", gc - out * 2.0, _sph(c, rr, az, phi), 0.35, 0.35)
		lm.box("Steel", _sph(c, rr + 0.2, az, phi), Vector3(2.4, 0.5, 2.4),
			Basis(Vector3.UP, az) * Basis(Vector3.RIGHT, -phi))

# --- Kaknäs Tower ------------------------------------------------------

## Shaft plan half-sizes (OSM way 593144774): the square and the 45°
## square that cross it.
const KAK_S := 7.55
const KAK_D := 10.6
const KAK_SHAFT_H := 120.0
const KAK_HEAD_R := 15.0
const KAK_ROOF_H := 155.0
const KAK_TOP_H := 170.0

## Kaknäs Tower: the star-plan concrete shaft with its faint relief bands
## (the analogue TV test-signal pattern) and the stair-window slots, the
## entrance pavilion to the south, and the head turned 45°: a stepped
## concrete corbel, two gold-filmed glazed floors (restaurant on the 28th,
## café on the 30th, 134 m), the screened outdoor terrace on the 31st,
## the concrete crown of antenna floors with two antenna balconies, and
## the steel mast with its antenna rungs and beacon to 170 m.
static func kaknas(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#ABA79E", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("concrete", "#9C988F", 3.0))
	lm.use("GoldGlass", LandmarkMaterials.pbr("concrete", "#8C7746", 2.0, 0.14, 0.8))
	lm.use("Glass", LandmarkMaterials.glass("#2A3238"))
	lm.use("Steel", LandmarkMaterials.paint("#D9DBDA", 0.5, 0.5))
	lm.use("Red", LandmarkMaterials.paint("#B23A2E", 0.55, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#FF5A40", 1.2))
	var star := _kak_star(1.0)
	lm.poly_prism("Concrete", star, 0.0, KAK_SHAFT_H)
	# Relief bands: groups of thin bands of varying height, the faint
	# test-signal pattern slip-formed into the shaft.
	var big := _kak_star(1.0 + 0.12 / KAK_S)
	var y := 12.0
	var g := 0
	while y < KAK_SHAFT_H - 10.0:
		var widths := [0.35, 0.2, 0.6, 0.2] if g % 2 == 0 else [0.5, 0.25, 0.25, 0.8]
		var yy := y
		for w: float in widths:
			lm.poly_prism("Relief", big, yy, yy + w)
			yy += w + 0.45
		y += 9.0
		g += 1
	# Stair-window slots up the flat faces of the south-east and
	# north-west corners.
	var mid := KAK_D * 0.5
	for s: float in [-1.0, 1.0]:
		var yw := 6.0
		while yw < KAK_SHAFT_H - 4.0:
			lm.box("Glass", Vector3(s * (KAK_S + 0.02), yw, s * mid), Vector3(0.06, 1.6, 0.7), Basis(), 0.0)
			lm.box("Glass", Vector3(s * mid, yw, s * (KAK_S + 0.02)), Vector3(0.7, 1.6, 0.06), Basis(), 0.0)
			yw += 3.9
	# Entrance pavilion (OSM way 1303205070) and its link to the shaft.
	FhU.blk(lm, "Concrete", 0.0, 0.0, 27.5, 4.4, 4.2, 15.4)
	FhU.blk(lm, "Glass", 0.0, 0.0, 15.5, 5.0, 3.6, 9.0)
	FhU.blk(lm, "Concrete", 0.0, 3.6, 15.5, 5.6, 0.6, 9.6)
	FhU.blk(lm, "Glass", 0.0, 0.6, 27.5, 4.5, 2.6, 13.0)
	_kak_head(lm)
	lm.commit(model)

## The shaft plan: a 2*KAK_S square crossed by a 45° square of half
## diagonal KAK_D, scaled by `k`, as one 16-point outline.
static func _kak_star(k: float) -> PackedVector2Array:
	var e := KAK_D - KAK_S
	var base: Array[Vector2] = [Vector2(KAK_D, 0), Vector2(KAK_S, e), Vector2(KAK_S, KAK_S), Vector2(e, KAK_S)]
	var out := PackedVector2Array()
	for q in 4:
		for p in base:
			out.append(p.rotated(PI * 0.5 * float(q)) * k)
	return out

## Diamond (a square turned 45°, corners on the axes) of half diagonal
## r from y0 to y1; r1 < 0 keeps the same size at the top.
static func _diamond(lm: LandmarkMesh, key: String, r: float, y0: float, y1: float, r1: float = -1.0) -> void:
	lm.lathe(key, Vector3(0, y0, 0), PackedVector2Array([Vector2(r, 0), Vector2(r1 if r1 >= 0.0 else r, y1 - y0)]),
		4, 1.0, 1.0, 0.0, false)

## The four corners of a diamond of half diagonal r at height y.
static func _diamond_pts(r: float, y: float) -> Array[Vector3]:
	return [Vector3(r, y, 0), Vector3(0, y, r), Vector3(-r, y, 0), Vector3(0, y, -r)]

## Kaknäs head: corbel, glazed floors with mullions and slab edges,
## terrace screen, the antenna crown and the mast.
static func _kak_head(lm: LandmarkMesh) -> void:
	var r := KAK_HEAD_R
	_diamond(lm, "Concrete", KAK_D, KAK_SHAFT_H, 122.0, KAK_D + 1.6)
	_diamond(lm, "Concrete", KAK_D + 1.6, 122.0, 124.0, r)
	# Two glazed floors (124-135) between slab edges.
	_diamond(lm, "GoldGlass", r - 0.5, 124.0, 135.0)
	for sl in [[124.0, 0.8], [129.4, 0.7], [134.6, 0.9]]:
		_diamond(lm, "Concrete", r, float(sl[0]), float(sl[0]) + float(sl[1]))
	for fl in [[124.8, 129.4], [130.1, 134.6]]:
		var c4 := _diamond_pts(r - 0.35, 0.0)
		for i in 4:
			var a: Vector3 = c4[i]
			var b: Vector3 = c4[(i + 1) % 4]
			var o := ((a + b) * 0.5).normalized()
			FhP.ribs(lm, "Concrete", a, b, o, float(fl[0]), float(fl[1]), 1.45, 0.12, 0.22)
	# Terrace on the 31st floor: the screen and posts round the slab edge.
	var tr := r - 0.3
	var t4 := _diamond_pts(tr, 135.5)
	for i in 4:
		var a: Vector3 = t4[i]
		var b: Vector3 = t4[(i + 1) % 4]
		var n := ((a + b) * 0.5 - Vector3(0, 135.5, 0)).normalized()
		var dir := (b - a).normalized()
		var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
		lm.box("Glass", (a + b) * 0.5 + Vector3(0, 1.1, 0), Vector3(a.distance_to(b), 2.2, 0.05), basis, 0.0)
		lm.beam("Steel", a + Vector3(0, 2.25, 0), b + Vector3(0, 2.25, 0), 0.12, 0.12, n)
		var posts := int(a.distance_to(b) / 2.0)
		for k in posts + 1:
			var p := a.lerp(b, float(k) / float(posts))
			lm.box("Steel", p + Vector3(0, 1.15, 0), Vector3(0.1, 2.3, 0.1), Basis(), 0.0)
	# Antenna crown: concrete core with louvre bands, two balconies.
	_diamond(lm, "Concrete", 11.6, 135.5, KAK_ROOF_H - 1.0)
	for yl in [137.0, 141.5, 146.0, 150.5]:
		_diamond(lm, "Glass", 11.68, float(yl), float(yl) + 2.0)
		var c4 := _diamond_pts(11.68, 0.0)
		for i in 4:
			var a: Vector3 = c4[i]
			var b: Vector3 = c4[(i + 1) % 4]
			FhP.ribs(lm, "Concrete", a, b, ((a + b) * 0.5).normalized(), float(yl), float(yl) + 2.0, 0.9, 0.1, 0.12)
	for yb in [140.6, 149.6]:
		_diamond(lm, "Concrete", 13.4, float(yb), float(yb) + 0.4)
		var b4 := _diamond_pts(13.3, float(yb) + 0.4)
		for i in 4:
			lm.beam("Steel", b4[i] + Vector3(0, 1.0, 0), b4[(i + 1) % 4] + Vector3(0, 1.0, 0), 0.08, 0.08)
	_diamond(lm, "Concrete", 12.2, KAK_ROOF_H - 1.0, KAK_ROOF_H)
	_diamond(lm, "Concrete", 6.0, KAK_ROOF_H, KAK_ROOF_H + 1.2)
	# The mast: a steel tube in two diameters with red marking bands,
	# antenna rungs and a beacon at the top.
	var m0 := KAK_ROOF_H + 1.2
	lm.frustum("Steel", Vector3(0, m0, 0), 1.1, 0.95, 7.0, 16)
	lm.frustum("Steel", Vector3(0, m0 + 7.0, 0), 0.5, 0.32, KAK_TOP_H - m0 - 7.5, 12)
	for yr in [m0 + 5.6, m0 + 10.0, KAK_TOP_H - 2.2]:
		var rad := 1.0 if yr < m0 + 7.0 else 0.44
		lm.frustum("Red", Vector3(0, float(yr), 0), rad + 0.03, rad + 0.03, 1.1, 16)
	for k in 6:
		var yk := m0 + 0.8 + float(k) * 1.0
		for q in 4:
			var a := PI * 0.5 * float(q) + (PI * 0.25 if k % 2 == 1 else 0.0)
			var d := Vector3(cos(a), 0, sin(a))
			lm.box("Steel", Vector3(0, yk, 0) + d * 1.25, Vector3(0.3, 0.7, 0.3), Basis(Vector3.UP, -a), 0.0)
	lm.box("Lamp", Vector3(0, KAK_TOP_H - 0.25, 0), Vector3(0.5, 0.5, 0.5))

# --- Vasa Museum -------------------------------------------------------

## OSM 3D parts of the museum (way 27288534's building:part ways
## 1557707419-1557707438) in model metres: [height (high edge), skillion
## rise, roof:direction (compass, downhill), wall key, outline].
static func _vasa_parts() -> Array:
	return [
		[24.0, 5.0, 275.0, "Tar", _v([-22.6, 29.9, -18.2, 16.0, -3.5, 16.8, 12.4, -18.4, 9.9, -19.5, -0.2, -5.6,
			-12.2, -7.3, -15.7, -1.5, -32.6, 26.3, -26.9, 35.0])],
		[18.5, 4.5, 294.0, "Ochre", _v([-29.5, -48.8, -16.3, -42.9, -9.4, -39.8, 1.0, -49.3, 7.2, -48.6, 9.6, -48.4,
			11.7, -66.8, 9.7, -67.0, 4.7, -67.7, -14.2, -82.8])],
		[19.0, 6.5, 10.0, "Ochre", _v([26.5, -46.9, 20.3, -62.0, 11.8, -82.7, 10.5, -72.4, 9.7, -67.0, 11.7, -66.8,
			9.6, -48.4, 7.2, -48.6, 3.8, -27.2, 15.0, -23.7])],
		[26.0, 9.0, 270.0, "Tar", _v([-12.2, -7.3, -0.2, -5.6, 3.7, -23.0, -11.0, -27.0, -16.3, -7.9])],
		[33.5, 8.0, 114.0, "Copper", _v([41.5, 1.9, 34.7, -7.9, 18.2, 33.1, 23.5, 35.4, 26.5, 36.7])],
		[12.0, 0.0, 0.0, "FaluRed", _v([8.0, 48.8, 9.1, 49.1, 11.4, 68.1, 19.0, 67.9, 17.1, 47.1, 9.9, 44.8])],
		[27.5, 15.0, 68.0, "Copper", _v([41.5, 1.9, 44.5, 7.7, 45.4, 7.0, 33.8, -21.9, 34.1, -8.8, 34.7, -7.9])],
		[15.5, 0.0, 0.0, "FaluRed", _v([19.0, 67.9, 26.7, 70.8, 24.6, 46.7, 17.1, 47.1])],
		[20.5, 0.0, 0.0, "FaluRed", _v([24.2, 41.4, 23.5, 35.4, 18.2, 33.1, 16.1, 37.8])],
		[31.0, 3.5, 296.0, "Copper", _v([34.1, -8.8, 33.8, -21.9, 32.7, -31.1, 26.5, -46.9, 15.0, -23.7, 12.4, -18.4])],
		[41.0, 8.5, 294.0, "Copper", _v([13.0, 38.0, 15.5, 39.1, 16.1, 37.8, 18.2, 33.1, 34.7, -7.9, 34.1, -8.8,
			12.4, -18.4, -3.5, 16.8, -7.1, 24.8, -8.8, 28.6])],
		[33.0, 4.0, 285.0, "FaluRed", _v([-12.8, 43.1, -11.8, 43.3, 8.0, 48.8, 9.9, 44.8, 13.0, 38.0, -8.8, 28.6,
			-12.1, 40.6])],
		[28.5, 1.5, 315.0, "Copper", _v([-12.1, 40.6, -8.8, 28.6, -7.1, 24.8, -20.0, 37.7, -20.9, 38.6])],
		[24.0, 2.0, 287.0, "Tar", _v([-20.0, 37.7, -7.1, 24.8, -3.5, 16.8, -18.2, 16.0, -22.6, 29.9])],
		[15.5, 0.0, 0.0, "Ochre", _v([-24.2, -2.1, -25.5, 7.1, -39.9, 23.3, -37.3, 28.4, -31.4, 35.3, -29.8, 41.5,
			-26.9, 35.0, -32.6, 26.3, -15.7, -1.5])],
		[21.0, 8.0, 293.0, "Tar", _v([-12.2, -7.3, -16.3, -7.9, -11.0, -27.0, 3.7, -23.0, -0.2, -5.6, 9.9, -19.5,
			12.4, -18.4, 15.0, -23.7, 3.8, -27.2, -20.6, -34.7, -24.6, -35.6, -33.7, -14.6, -38.7, -2.9, -24.2, -2.1,
			-15.7, -1.5])],
		[15.5, 3.0, 294.0, "Ochre", _v([10.5, -72.4, 0.2, -96.9, -3.5, -106.6, -14.2, -82.8, 4.7, -67.7, 9.7, -67.0])],
		[17.5, 6.5, 318.0, "Ochre", _v([1.0, -49.3, -9.4, -39.8, -16.3, -42.9, -20.6, -34.7, 3.8, -27.2, 7.2, -48.6])],
		[18.5, 1.5, 178.0, "FaluRed", _v([24.2, 41.4, 16.1, 37.8, 15.5, 39.1, 13.0, 38.0, 9.9, 44.8, 17.1, 47.1,
			24.6, 46.7])],
	]

## Index of the 41 m ship-hall part in _vasa_parts().
const VASA_HALL := 10
## The ship hall's centreline (dock gate end to the north-east end) the
## masts stand on, and each mast as [position along it, top height,
## lower-mast radius]: mizzen aft by the dock gate, main, fore.
const VASA_AXIS := [Vector2(2.1, 33.3), Vector2(23.4, -13.4)]
const VASA_MASTS := [[0.2, 45.5, 0.32], [0.5, 52.5, 0.45], [0.78, 49.0, 0.38]]

## Flat [x0, z0, x1, z1, ...] list to a polygon.
static func _v(a: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(0, a.size(), 2):
		p.append(Vector2(float(a[i]), float(a[i + 1])))
	return p

## The Vasa Museum: every OSM part as walls rising to its skillion roof
## (copper standing seams and eave flashing), board-and-batten cladding
## on the outer walls of the wooden parts over a concrete plinth, the
## glazed entrance hall on the west, a few deep-set windows, the dock
## gate where Vasa came in, and the three masts on the ship hall.
static func vasa(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5A5149", 2.0, 0.5, 0.45))
	lm.use("Seam", LandmarkMaterials.pbr("concrete", "#6B6157", 2.0, 0.42, 0.55))
	lm.use("FaluRed", LandmarkMaterials.pbr("wood", "#7B2F24", 2.5))
	lm.use("Ochre", LandmarkMaterials.pbr("wood", "#C08B3C", 2.5))
	lm.use("Tar", LandmarkMaterials.pbr("wood", "#2B2825", 2.5))
	lm.use("Plinth", LandmarkMaterials.pbr("concrete", "#8A857D", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#28323A"))
	lm.use("Mast", LandmarkMaterials.pbr("wood", "#4E3B2A", 2.0))
	lm.use("Rig", LandmarkMaterials.paint("#2A2622", 0.7, 0.1))
	var parts := _vasa_parts()
	var polys: Array[PackedVector2Array] = []
	for p in parts:
		polys.append(p[4] as PackedVector2Array)
	for i in parts.size():
		_vasa_part(lm, parts[i], polys, i)
	_vasa_entrance(lm, parts[14])
	# Dock gate: the caisson across the old dock mouth, south.
	lm.beam("Plinth", Vector3(-13.3, 1.2, 47.8), Vector3(5.5, 1.2, 55.6), 1.6, 2.4)
	lm.beam("Rig", Vector3(-13.3, 2.5, 47.8), Vector3(5.5, 2.5, 55.6), 0.06, 0.06)
	_vasa_masts(lm, parts[VASA_HALL])
	lm.commit(model)

## Roof height of a part at xz point p: the skillion plane falling `rise`
## from the high edge to the low edge across roof:direction.
static func _roof_y(part: Array, p: Vector2) -> float:
	var h: float = part[0]
	var rise: float = part[1]
	if rise <= 0.0:
		return h
	var poly: PackedVector2Array = part[4]
	var down := _down(part)
	var s0 := INF
	var s1 := -INF
	for q in poly:
		s0 = minf(s0, q.dot(down))
		s1 = maxf(s1, q.dot(down))
	return h - rise * clampf((p.dot(down) - s0) / maxf(s1 - s0, 0.01), 0.0, 1.0)

## Downhill direction of a part's roof in model xz (compass bearing).
static func _down(part: Array) -> Vector2:
	var d := deg_to_rad(float(part[2]))
	return Vector2(sin(d), -cos(d))

## True when polygon edge i of part `idx` faces open air: a probe just
## outside it is not inside any other part taller than the edge's foot.
static func _outer_edge(polys: Array[PackedVector2Array], idx: int, i: int) -> bool:
	var poly := polys[idx]
	var a := poly[i]
	var b := poly[(i + 1) % poly.size()]
	var o := FhP.edge_out(poly, i)
	var probe := (a + b) * 0.5 + Vector2(o.x, o.z) * 0.6
	for k in polys.size():
		if k != idx and Geometry2D.is_point_in_polygon(probe, polys[k]):
			return false
	return true

## One part: walls up to the roof plane, the roof itself (triangulated
## outline lifted onto the plane), standing seams down the slope, eave
## flashing, and on outer walls the plinth and (wood) battens.
static func _vasa_part(lm: LandmarkMesh, part: Array, polys: Array[PackedVector2Array], idx: int) -> void:
	var poly: PackedVector2Array = part[4]
	var wall: String = part[3]
	var down := _down(part)
	var rise: float = part[1]
	var wood := wall != "Copper"
	var nv := poly.size()
	for i in nv:
		var a := poly[i]
		var b := poly[(i + 1) % nv]
		var ya := _roof_y(part, a)
		var yb := _roof_y(part, b)
		var o := FhP.edge_out(poly, i)
		var pa := Vector3(a.x, 0, a.y)
		var pb := Vector3(b.x, 0, b.y)
		var ln := a.distance_to(b)
		lm.tri(wall, pa, pb, Vector3(b.x, yb, b.y), o, o, o, Vector2(0, 0), Vector2(ln, 0), Vector2(ln, -yb))
		lm.tri(wall, pa, Vector3(b.x, yb, b.y), Vector3(a.x, ya, a.y), o, o, o, Vector2(0, 0), Vector2(ln, -yb),
			Vector2(0, -ya))
		# Copper flashing along the roof edge.
		lm.beam("Seam", Vector3(a.x, ya, a.y) + o * 0.15, Vector3(b.x, yb, b.y) + o * 0.15, 0.45, 0.3, o)
		if not _outer_edge(polys, idx, i) or ln < 0.8:
			continue
		var mid := (pa + pb) * 0.5
		var dir := (pb - pa) / ln
		var basis := Basis(dir, Vector3.UP, o)
		lm.box("Plinth", mid + o * 0.12 + Vector3(0, 0.45, 0), Vector3(ln + 0.2, 0.9, 0.24), basis, 0.0)
		if wood:
			var nb := int(ln / 1.2)
			for k in nb:
				var t := (float(k) + 0.5) / float(nb)
				var p := pa.lerp(pb, t)
				var yt := lerpf(ya, yb, t) - 0.3
				lm.beam(wall, p + o * 0.04 + Vector3(0, 0.9, 0), p + o * 0.04 + Vector3(0, yt, 0), 0.09, 0.08, dir)
			# A row of small deep-set windows high on the longer walls.
			if ln > 9.0 and minf(ya, yb) > 12.0:
				var nw := int(ln / 6.0)
				for k in nw:
					var p := pa.lerp(pb, (float(k) + 0.5) / float(nw))
					LandmarkDetail.window(lm, "Plinth", "Glass", p + Vector3(0, 9.0, 0) + o * 0.02, o, 1.2, 1.2)
	_vasa_roof(lm, part, down, rise)

## The roof plane of a part with copper standing seams 1.1 m apart down
## the slope (along X on the flat roofs).
static func _vasa_roof(lm: LandmarkMesh, part: Array, down: Vector2, rise: float) -> void:
	var poly: PackedVector2Array = part[4]
	var dir := down if rise > 0.0 else Vector2(1, 0)
	var n3 := Vector3.UP
	if rise > 0.0:
		var s0 := INF
		var s1 := -INF
		for q in poly:
			s0 = minf(s0, q.dot(down))
			s1 = maxf(s1, q.dot(down))
		n3 = (Vector3(down.x, 0, down.y) * rise / maxf(s1 - s0, 0.01) + Vector3.UP).normalized()
	var idx := Geometry2D.triangulate_polygon(poly)
	if idx.is_empty():
		idx = _fallback_tris(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri("Copper", Vector3(a.x, _roof_y(part, a), a.y), Vector3(b.x, _roof_y(part, b), b.y),
			Vector3(c.x, _roof_y(part, c), c.y), n3, n3, n3, a, b, c)
	var across := Vector2(-dir.y, dir.x)
	var lo := INF
	var hi := -INF
	var far := 0.0
	for q in poly:
		lo = minf(lo, q.dot(across))
		hi = maxf(hi, q.dot(across))
		far = maxf(far, q.length())
	var u := lo + 0.55
	while u < hi:
		var line := PackedVector2Array([across * u - dir * (far + 5.0), across * u + dir * (far + 5.0)])
		for seg: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(line, poly):
			if seg.size() < 2:
				continue
			var a := seg[0]
			var b := seg[seg.size() - 1]
			if a.distance_to(b) < 0.5:
				continue
			lm.beam("Seam", Vector3(a.x, _roof_y(part, a) + 0.05, a.y) + n3 * 0.02,
				Vector3(b.x, _roof_y(part, b) + 0.05, b.y) + n3 * 0.02, 0.07, 0.08, Vector3(across.x, 0, across.y))
		u += 1.1

## Triangles of an outline that triangulate_polygon rejects (touching
## edges): Delaunay triangles whose centroid lies inside it.
static func _fallback_tris(poly: PackedVector2Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	var d := Geometry2D.triangulate_delaunay(poly)
	for t in range(0, d.size(), 3):
		var c := (poly[d[t]] + poly[d[t + 1]] + poly[d[t + 2]]) / 3.0
		if Geometry2D.is_point_in_polygon(c, poly):
			out.append_array([d[t], d[t + 1], d[t + 2]])
	return out

## The glazed entrance hall (the 15.5 m west part): a curtain wall in
## the lower storeys of its outer faces, mullions and a canopy.
static func _vasa_entrance(lm: LandmarkMesh, part: Array) -> void:
	var poly: PackedVector2Array = part[4]
	for i in [1, 2, 3]:
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var o := FhP.edge_out(poly, i)
		var pa := Vector3(a.x, 0, a.y)
		var pb := Vector3(b.x, 0, b.y)
		var dir := (pb - pa).normalized()
		var basis := Basis(dir, Vector3.UP, o)
		lm.box("Glass", (pa + pb) * 0.5 + o * 0.18 + Vector3(0, 3.4, 0), Vector3(a.distance_to(b) - 0.6, 5.0, 0.1),
			basis, 0.0)
		FhP.ribs(lm, "Plinth", pa + dir * 0.3, pb - dir * 0.3, o, 0.9, 5.9, 1.8, 0.12, 0.3)
		lm.box("Copper", (pa + pb) * 0.5 + o * 1.6 + Vector3(0, 6.1, 0), Vector3(a.distance_to(b), 0.35, 3.2), basis)

## The three masts on the ship hall, after Vasa's rig: lower mast, the
## round top on its trestle, topmast with crosstrees and the topgallant
## pole, with shrouds from each top down to the roof either side.
static func _vasa_masts(lm: LandmarkMesh, hall: Array) -> void:
	var a: Vector2 = VASA_AXIS[0]
	var b: Vector2 = VASA_AXIS[1]
	var ax := (b - a).normalized()
	var side := Vector3(-ax.y, 0, ax.x)
	var fwd := Vector3(ax.x, 0, ax.y)
	for m in VASA_MASTS:
		var p2 := a.lerp(b, float(m[0]))
		var top: float = m[1]
		var r0: float = m[2]
		var y0 := _roof_y(hall, p2) - 0.3
		var base := Vector3(p2.x, y0, p2.y)
		var span := top - y0
		var y1 := y0 + span * 0.5
		var y2 := y0 + span * 0.8
		lm.frustum("Mast", base, r0, r0 * 0.85, span * 0.5 + 1.2, 12)
		# The top: trestle trees and the round platform with its rim.
		lm.box("Mast", Vector3(p2.x, y1, p2.y), Vector3(r0 * 6.0, 0.35, r0 * 3.0), Basis(Vector3.UP, atan2(ax.x, ax.y)))
		lm.frustum("Mast", Vector3(p2.x, y1 + 0.17, p2.y), r0 * 4.6, r0 * 4.8, 0.3, 16)
		lm.lathe("Mast", Vector3(p2.x, y1 + 0.47, p2.y), PackedVector2Array([Vector2(r0 * 4.8, 0),
			Vector2(r0 * 4.8, 0.6)]), 16, 1.0, 1.0, 0.0, true, false)
		lm.frustum("Mast", Vector3(p2.x, y1 - 1.0, p2.y), r0 * 0.6, r0 * 0.45, y2 - y1 + 2.0, 10)
		lm.beam("Mast", Vector3(p2.x, y2, p2.y) - side * r0 * 5.0, Vector3(p2.x, y2, p2.y) + side * r0 * 5.0,
			0.18, 0.18)
		lm.beam("Mast", Vector3(p2.x, y2, p2.y) - fwd * r0 * 2.0, Vector3(p2.x, y2, p2.y) + fwd * r0 * 2.0,
			0.16, 0.16)
		lm.frustum("Mast", Vector3(p2.x, y2 - 0.8, p2.y), r0 * 0.35, r0 * 0.18, top - y2 + 0.5, 8)
		lm.lathe("Mast", Vector3(p2.x, top - 0.3, p2.y), FhU.ball(0.15 + r0 * 0.2), 8)
		# Shrouds: lower ones to the roof, upper ones from the crosstrees.
		for s: float in [-1.0, 1.0]:
			for k in 5:
				var f := (float(k) - 2.0) * 0.9
				var foot2 := p2 + Vector2(side.x, side.z) * s * 6.0 + ax * f
				var foot := Vector3(foot2.x, _roof_y(hall, foot2) + 0.1, foot2.y)
				var head := Vector3(p2.x, y1, p2.y) + side * s * r0 * 4.2 + fwd * f * 0.25
				lm.beam("Rig", foot, head, 0.06, 0.06)
			for k in 3:
				var f := (float(k) - 1.0) * 0.6
				var rim := Vector3(p2.x, y1 + 0.5, p2.y) + side * s * r0 * 4.4 + fwd * f
				lm.beam("Rig", rim, Vector3(p2.x, y2, p2.y) + side * s * r0 * 4.6, 0.05, 0.05)
	# Stays between the mast heads.
	for i in VASA_MASTS.size() - 1:
		var m0: Array = VASA_MASTS[i]
		var m1: Array = VASA_MASTS[i + 1]
		var q0 := a.lerp(b, float(m0[0]))
		var q1 := a.lerp(b, float(m1[0]))
		lm.beam("Rig", Vector3(q0.x, float(m0[1]) * 0.94, q0.y), Vector3(q1.x, float(m1[1]) * 0.78, q1.y), 0.06, 0.06)
