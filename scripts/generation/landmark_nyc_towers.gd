class_name LandmarkNycTowers
extends RefCounted

## Manhattan's two skyline towers in true metres.

## One World Trade Center (SOM, 2014): the 61 m (200 ft) square podium
## to 56.7 m (186 ft) behind its prismatic glass fins over a 15 m glass
## lobby with an entrance canopy on each side; then the tower whose
## square corners are chamfered away as it rises, so its faces are
## eight tall isosceles triangles and the top is the base square turned
## 45° (an octagon at mid height), glazed in vertical mullions with a
## spandrel line at every 4 m floor; the glass parapet at 417 m
## (1,368 ft), the circular communications ring on the roof and the
## 124 m (408 ft) spire of stacked lattice sections with its maintenance
## rings to the 541.3 m (1,776 ft) beacon.
const WTC_TIP_M := 541.3
const WTC_ROOF_M := 417.0
const WTC_PODIUM_M := 56.7
const WTC_HALF := 30.5
const WTC_LOBBY_M := 15.2
const WTC_FLOOR_M := 4.0
const WTC_MULLION_M := 1.52

static func one_wtc(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#9DB0BE"))
	lm.use("Podium", LandmarkMaterials.paint("#C3C9CD", 0.3, 0.75))
	lm.use("Steel", LandmarkMaterials.paint("#DADDE0", 0.3, 0.8))
	lm.use("Base", LandmarkMaterials.pbr("concrete", "#B8B4AC", 3.0))
	lm.use("Lobby", LandmarkMaterials.glass("#5E6E78"))
	lm.use("Beacon", LandmarkMaterials.lit("#FFFFFF", 0.8))
	# Granite plaza plinth (the memorial plaza level).
	lm.box("Base", Vector3(0, 0.3, 0), Vector3(WTC_HALF * 2.0 + 16.0, 0.6, WTC_HALF * 2.0 + 16.0))
	_wtc_podium(lm)
	_wtc_tower(lm)
	_wtc_spire(lm)
	lm.commit(model)

## Podium: a glass lobby set back under the solid podium, the podium
## faced in vertical glass fins in staggered tiers, a canopy over the
## entrance mid-side and the steel edge at the tower base.
static func _wtc_podium(lm: LandmarkMesh) -> void:
	var y0 := 0.6
	var inset := 1.8
	var lobby := WTC_HALF - inset
	lm.box("Lobby", Vector3(0, y0 + (WTC_LOBBY_M - y0) * 0.5, 0), Vector3(lobby * 2.0, WTC_LOBBY_M - y0, lobby * 2.0))
	lm.box("Podium", Vector3(0, (WTC_LOBBY_M + WTC_PODIUM_M) * 0.5, 0),
		Vector3(WTC_HALF * 2.0 - 0.6, WTC_PODIUM_M - WTC_LOBBY_M, WTC_HALF * 2.0 - 0.6))
	lm.box("Steel", Vector3(0, WTC_LOBBY_M + 0.4, 0), Vector3(WTC_HALF * 2.0 + 0.4, 0.8, WTC_HALF * 2.0 + 0.4))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * side)
		# Lobby mullions: tall glass panes 3 m apart, steel fins.
		var n_l := int(lobby * 2.0 / 3.0)
		for k in n_l + 1:
			var x := -lobby + lobby * 2.0 * k / n_l
			lm.box("Steel", r * Vector3(x, (y0 + WTC_LOBBY_M) * 0.5, lobby + 0.15),
				Vector3(0.18, WTC_LOBBY_M - y0, 0.5), r, 0.0)
		lm.box("Steel", r * Vector3(0, y0 + 4.6, lobby + 0.2), Vector3(lobby * 2.0, 0.3, 0.6), r, 0.0)
		# Entrance canopy and its doors.
		lm.box("Steel", r * Vector3(0, 6.2, WTC_HALF + 2.0), Vector3(16.0, 0.5, 7.6), r)
		for k in 6:
			lm.box("Podium", r * Vector3(-5.0 + 2.0 * k, y0 + 1.3, lobby + 0.35), Vector3(1.7, 2.6, 0.12), r, 0.0)
		# Prismatic fins: four tiers, each tier's fins offset half a pitch.
		var tiers := 4
		var tier_h := (WTC_PODIUM_M - WTC_LOBBY_M - 1.0) / tiers
		for t in tiers:
			var ty := WTC_LOBBY_M + 1.0 + tier_h * (t + 0.5)
			var off := 0.0 if t % 2 == 0 else 0.75
			var n_f := 40
			for k in n_f:
				var x := -WTC_HALF + 0.75 + off + 1.5 * k
				if x > WTC_HALF - 0.4:
					continue
				lm.box("Glass", r * Vector3(x, ty, WTC_HALF + 0.05), Vector3(0.9, tier_h - 0.35, 0.5),
					r * Basis(Vector3.UP, 0.35 if t % 2 == 0 else -0.35), 0.0)
			lm.box("Steel", r * Vector3(0, WTC_LOBBY_M + 1.0 + tier_h * t, WTC_HALF), Vector3(WTC_HALF * 2.0, 0.25, 0.8), r, 0.0)
	# Rooftop ledge of the podium round the tower base.
	lm.box("Steel", Vector3(0, WTC_PODIUM_M - 0.5, 0), Vector3(WTC_HALF * 2.0 + 0.8, 1.0, WTC_HALF * 2.0 + 0.8))

## Tower loft: base ring alternates square corners and edge midpoints;
## at the top each corner has drawn in to the midpoint of the turned
## square's edge while the midpoints stay put. Floor spandrels and
## vertical mullions are laid on each triangular face.
static func _wtc_tower(lm: LandmarkMesh) -> void:
	var y0 := WTC_PODIUM_M
	var y1 := WTC_ROOF_M
	var bottom: Array[Vector3] = []
	var top: Array[Vector3] = []
	for i in 8:
		var a := PI * 0.25 * i + PI * 0.25
		if i % 2 == 0:
			var corner := Vector2(cos(a), sin(a)) * WTC_HALF * sqrt(2.0)
			bottom.append(Vector3(corner.x, y0, corner.y))
			top.append(Vector3(corner.x * 0.5, y1, corner.y * 0.5))
		else:
			var mid := Vector2(cos(a), sin(a)) * WTC_HALF
			bottom.append(Vector3(mid.x, y0, mid.y))
			top.append(Vector3(mid.x, y1, mid.y))
	for i in 8:
		var j := (i + 1) % 8
		# Corner i shrinks while midpoint j stays: two triangles per edge.
		var b_corner := bottom[i] if i % 2 == 0 else bottom[j]
		var b_mid := bottom[j] if i % 2 == 0 else bottom[i]
		var t_corner := top[i] if i % 2 == 0 else top[j]
		var t_mid := top[j] if i % 2 == 0 else top[i]
		_flat_tri(lm, "Glass", b_corner, b_mid, t_mid)
		_flat_tri(lm, "Glass", b_corner, t_mid, t_corner)
		_face_mullions(lm, b_corner, b_mid, t_mid, true)
		_face_mullions(lm, t_corner, t_mid, b_corner, false)
	# Floor spandrel lines: a thin steel ring round the section per floor.
	var y := y0 + WTC_FLOOR_M
	while y < y1 - 2.0:
		var t := (y - y0) / (y1 - y0)
		var ring: Array[Vector3] = []
		for i in 8:
			ring.append(bottom[i].lerp(top[i], t))
		for i in 8:
			var a := ring[i]
			var b := ring[(i + 1) % 8]
			var mid := (a + b) * 0.5
			var out := Vector3(mid.x, 0, mid.z).normalized()
			var ax := (b - a).normalized()
			lm.box("Steel", mid + out * 0.08, Vector3(a.distance_to(b) + 0.2, 0.32, 0.18),
				Basis(ax, Vector3.UP, ax.cross(Vector3.UP).normalized()), 0.0)
		y += WTC_FLOOR_M
	# Glass parapet on the turned square, its steel frame, and the roof.
	var cap := PackedVector2Array()
	for p in top:
		cap.append(Vector2(p.x, p.z))
	lm.poly_prism("Steel", cap, y1 - 0.5, y1 + 0.3)
	for i in 4:
		var a := top[i * 2 + 1]
		var b := top[(i * 2 + 3) % 8]
		var ax := (b - a).normalized()
		var bas := Basis(ax, Vector3.UP, ax.cross(Vector3.UP).normalized())
		lm.box("Glass", (a + b) * 0.5 + Vector3(0, 2.4, 0), Vector3(a.distance_to(b), 4.2, 0.3), bas, 0.0)
		lm.box("Steel", (a + b) * 0.5 + Vector3(0, 4.6, 0), Vector3(a.distance_to(b) + 0.4, 0.4, 0.6), bas, 0.0)
		for k in 15:
			lm.box("Steel", a.lerp(b, k / 14.0) + Vector3(0, 2.4, 0), Vector3(0.25, 4.2, 0.5), bas, 0.0)

## Vertical mullions on one half-face, a right triangle: a-b the
## level edge, c the third corner, and the face's vertical through b
## (b-c, `axis_at_b`) or through a (a-c). Every WTC_MULLION_M along a-b
## a member runs up the face parallel to that axis to the sloping edge.
static func _face_mullions(lm: LandmarkMesh, a: Vector3, b: Vector3, c: Vector3, axis_at_b: bool) -> void:
	var n := (b - a).cross(c - a).normalized()
	var mid := (a + b + c) / 3.0
	if n.dot(Vector3(mid.x, 0.0, mid.z)) < 0.0:
		n = -n
	var count := int(a.distance_to(b) / WTC_MULLION_M)
	for k in range(1, count):
		var t := float(k) / count
		var p := a.lerp(b, t)
		var q := a.lerp(c, t) if axis_at_b else c.lerp(b, t)
		lm.beam("Steel", p + n * 0.12, q + n * 0.12, 0.22, 0.2, b - a)

static func _flat_tri(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	var mid := (a + b + c) / 3.0
	if n.dot(Vector3(mid.x, 0.0, mid.z)) < 0.0:
		n = -n
	var u := (b - a).normalized()
	lm.tri(key, a, b, c, n, n, n, Vector2(0, -a.y), Vector2((b - a).dot(u), -b.y),
		Vector2((c - a).dot(u), -c.y))

## Roof plant and the spire: the circular communications ring (about
## 20 m across) on its plinth, eight raking struts to the mast, then the
## 18-section spire: a lattice of eight chords with X bracing and a
## catwalk ring every section in its lower part, a slim mast above, and
## the 288 LED beacon at the tip.
static func _wtc_spire(lm: LandmarkMesh) -> void:
	var base := WTC_ROOF_M + 0.3
	lm.frustum("Steel", Vector3(0, base, 0), 12.0, 12.0, 2.0, 24)
	lm.frustum("Podium", Vector3(0, base + 2.0, 0), 10.0, 10.0, 6.0, 24)
	lm.frustum("Steel", Vector3(0, base + 8.0, 0), 10.6, 10.6, 0.8, 24)
	for k in 24:
		var a := TAU * k / 24.0
		lm.box("Steel", Vector3(cos(a) * 10.05, base + 5.0, sin(a) * 10.05), Vector3(0.3, 6.0, 0.4),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	var s0 := base + 8.8
	var lat_top := s0 + 72.0
	for k in 8:
		var a := TAU * k / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Steel", d * 10.0 + Vector3(0, s0, 0), d * 3.0 + Vector3(0, s0 + 20.0, 0), 0.6, 0.6)
	# Lattice: eight chords tapering from 3.2 to 1.6 m radius.
	var sections := 12
	for sct in sections:
		var ya := s0 + (lat_top - s0) * sct / sections
		var yb := s0 + (lat_top - s0) * (sct + 1) / sections
		var ra := lerpf(3.2, 1.6, float(sct) / sections)
		var rb := lerpf(3.2, 1.6, float(sct + 1) / sections)
		for k in 8:
			var a0 := TAU * k / 8.0
			var a1 := TAU * (k + 1) / 8.0
			var p0 := Vector3(cos(a0) * ra, ya, sin(a0) * ra)
			var p1 := Vector3(cos(a1) * ra, ya, sin(a1) * ra)
			var q0 := Vector3(cos(a0) * rb, yb, sin(a0) * rb)
			var q1 := Vector3(cos(a1) * rb, yb, sin(a1) * rb)
			lm.beam("Steel", p0, q0, 0.35, 0.35)
			lm.beam("Steel", p0, q1, 0.14, 0.14)
			lm.beam("Steel", p1, q0, 0.14, 0.14)
		lm.frustum("Steel", Vector3(0, yb - 0.2, 0), rb + 0.9, rb + 0.9, 0.3, 16)
	# Mast above the lattice, its rings, the beacon and lightning rod.
	var tip := WTC_TIP_M
	lm.lathe("Steel", Vector3(0, lat_top, 0), PackedVector2Array([Vector2(1.6, 0), Vector2(1.1, 18.0),
		Vector2(0.7, 30.0), Vector2(0.35, tip - lat_top - 6.0)]), 12)
	for k in 4:
		lm.frustum("Steel", Vector3(0, lat_top + 4.0 + 7.0 * k, 0), 1.9 - 0.25 * k, 1.9 - 0.25 * k, 0.5, 12)
	lm.frustum("Beacon", Vector3(0, tip - 6.0, 0), 0.6, 0.6, 2.4, 12)
	lm.frustum("Steel", Vector3(0, tip - 3.6, 0), 0.25, 0.04, 3.6, 6)

## Empire State Building (Shreve, Lamb & Harmon, 1931): the five-storey
## base filling the 129 x 57 m (424 x 187 ft) block, the setbacks at
## the 6th, 21st, 25th, 30th, 72nd, 81st and 85th floors with notched
## (re-entrant) corners on the tower, the limestone piers running up
## between recessed window columns of glass over cast aluminium
## spandrels with chrome-nickel steel trim, the Fifth Avenue entrance,
## the 86th floor deck, the Art Deco mooring mast with its four winged
## buttresses and aluminium ribs to the 381 m roof, and the antenna to
## the 443.2 m tip. Long side along the cross streets (X; +X Fifth
## Avenue); LocationData turns it onto Manhattan's grid.
const ESB_TIP_M := 443.2
const ESB_ROOF_M := 381.0
const ESB_FLOOR_M := 3.81

static func empire_state(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#CFC6B4", 3.0))
	lm.use("Spandrel", LandmarkMaterials.paint("#9EA3A6", 0.4, 0.7))
	lm.use("Windows", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Mast", LandmarkMaterials.paint("#B9B5AA", 0.45, 0.55))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6E6A66", 2.5))
	# [y0, y1, length (X), depth (Z), corner notch] stacked masses.
	var masses := [[0.0, 24.6, 129.0, 57.0, 0.0], [24.6, 84.0, 112.0, 52.0, 0.0],
		[84.0, 99.0, 92.0, 48.0, 3.0], [99.0, 118.0, 76.0, 44.0, 3.0], [118.0, 280.0, 58.0, 40.0, 4.0],
		[280.0, 314.0, 46.0, 34.0, 3.0], [314.0, 330.0, 36.0, 28.0, 2.0]]
	for m in masses:
		_esb_mass(lm, float(m[0]), float(m[1]), float(m[2]), float(m[3]), float(m[4]))
	_esb_base(lm)
	# 86th-floor deck: parapet with its pierced balustrade and the
	# observatory walls under the mast.
	lm.box("Limestone", Vector3(0, 331.2, 0), Vector3(38.0, 2.4, 30.0))
	for s in [-1.0, 1.0]:
		lm.box("Limestone", Vector3(0, 333.8, s * 14.6), Vector3(38.0, 1.6, 0.8))
		lm.box("Limestone", Vector3(s * 18.6, 333.8, 0), Vector3(0.8, 1.6, 30.0))
		for k in 18:
			lm.box("Spandrel", Vector3(-17.0 + 2.0 * k, 335.2, s * 14.6), Vector3(0.12, 1.4, 0.12), Basis(), 0.0)
		for k in 14:
			lm.box("Spandrel", Vector3(s * 18.6, 335.2, -13.0 + 2.0 * k), Vector3(0.12, 1.4, 0.12), Basis(), 0.0)
	_esb_mast(lm)
	lm.commit(model)

## One setback mass: a dark core (window glass), limestone piers about
## 1.5 m wide every bay standing 0.4 m proud with the cast aluminium
## spandrel per floor between them, wide corner piers, a coping and,
## where `notch` > 0, re-entrant corners.
static func _esb_mass(lm: LandmarkMesh, y0: float, y1: float, lx: float, lz: float, notch: float) -> void:
	var h := y1 - y0
	var yc := (y0 + y1) * 0.5
	if notch > 0.0:
		lm.box("Windows", Vector3(0, yc, 0), Vector3(lx - 0.8 - notch * 2.0, h, lz - 0.8))
		lm.box("Windows", Vector3(0, yc, 0), Vector3(lx - 0.8, h, lz - 0.8 - notch * 2.0))
	else:
		lm.box("Windows", Vector3(0, yc, 0), Vector3(lx - 0.8, h, lz - 0.8))
	lm.box("Limestone", Vector3(0, y1 + 0.5, 0), Vector3(lx - notch * 2.0 + 0.4, 1.0, lz + 0.4))
	if notch > 0.0:
		lm.box("Limestone", Vector3(0, y1 + 0.5, 0), Vector3(lx + 0.4, 1.0, lz - notch * 2.0 + 0.4))
	if h < 12.0:
		return
	var floors := maxi(1, roundi(h / ESB_FLOOR_M))
	var fh := h / floors
	for face in [[lx, lz, Basis()], [lz, lx, Basis(Vector3.UP, PI * 0.5)]]:
		var span := float(face[0])
		var depth := float(face[1])
		var r: Basis = face[2]
		# Each face: a centre run and, with a notch, the two returns.
		var runs: Array = [[-span * 0.5 + notch, span * 0.5 - notch, depth * 0.5]]
		if notch > 0.0:
			runs.append([-span * 0.5, -span * 0.5 + notch, depth * 0.5 - notch])
			runs.append([span * 0.5 - notch, span * 0.5, depth * 0.5 - notch])
		for run in runs:
			var xa := float(run[0])
			var xb := float(run[1])
			var zf := float(run[2])
			var bays := maxi(1, roundi((xb - xa) / 4.6))
			var pitch := (xb - xa) / bays
			for s in [-1.0, 1.0]:
				for k in bays + 1:
					var x := xa + pitch * k
					var pw := 2.2 if k == 0 or k == bays else 1.5
					lm.box("Limestone", r * Vector3(x, yc, s * (zf - 0.2)), Vector3(pw, h, 0.8), r, 0.0)
					# Chrome-nickel trim up the pier edges.
					if k > 0 and k < bays:
						lm.box("Spandrel", r * Vector3(x, yc, s * (zf + 0.2)), Vector3(0.2, h, 0.06), r, 0.0)
				for k in bays:
					var x := xa + pitch * (k + 0.5)
					for f in floors:
						lm.box("Spandrel", r * Vector3(x, y0 + fh * f + 0.55, s * (zf - 0.35)),
							Vector3(pitch - 1.5, 1.1, 0.1), r, 0.0)

## Ground floors: dark granite plinth, shopfronts and the Fifth Avenue
## (+X) entrance, three storeys high under its metal-framed transom.
static func _esb_base(lm: LandmarkMesh) -> void:
	lm.box("Granite", Vector3(0, 1.2, 0), Vector3(129.6, 2.4, 57.6))
	lm.box("Limestone", Vector3(0, 8.0, 0), Vector3(129.4, 0.8, 57.4))
	var ex := 64.5
	lm.box("Limestone", Vector3(ex + 0.6, 7.5, 0), Vector3(1.6, 15.0, 15.0))
	lm.box("Windows", Vector3(ex + 1.45, 6.5, 0), Vector3(0.1, 11.0, 8.0))
	for k in 5:
		lm.box("Spandrel", Vector3(ex + 1.55, 6.5, -4.0 + 2.0 * k), Vector3(0.2, 11.0, 0.25), Basis(), 0.0)
	for k in 3:
		lm.box("Spandrel", Vector3(ex + 1.55, 2.0 + 3.5 * k, 0), Vector3(0.2, 0.25, 8.0), Basis(), 0.0)
	lm.box("Spandrel", Vector3(ex + 2.6, 12.6, 0), Vector3(2.4, 0.4, 10.0))

## Mooring mast: octagonal setback stages with aluminium ribs, the four
## winged buttresses at its foot, the 102nd floor observatory under the
## glass cap, and the antenna.
static func _esb_mast(lm: LandmarkMesh) -> void:
	lm.frustum("Mast", Vector3(0, 332.4, 0), 10.0, 7.5, 22.6, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * k
		for o in [-0.25, 0.25]:
			var aa: float = a + float(o) * 0.35
			lm.beam("Spandrel", Vector3(cos(aa) * 9.9, 332.4, sin(aa) * 9.9),
				Vector3(cos(aa) * 7.45, 355.0, sin(aa) * 7.45), 0.45, 0.4)
	# Winged buttresses on the diagonals, stepped Art Deco profile.
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * k
		var d := Vector3(cos(a), 0, sin(a))
		var b := Basis.looking_at(d)
		for st in 3:
			var reach := 4.0 - 1.2 * st
			lm.box("Mast", d * (9.0 + reach * 0.5) + Vector3(0, 334.0 + 5.0 * st, 0),
				Vector3(1.2, 5.0, reach), b)
	lm.frustum("Mast", Vector3(0, 355.0, 0), 7.5, 5.0, 14.0, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * k
		lm.beam("Spandrel", Vector3(cos(a) * 7.55, 355.0, sin(a) * 7.55),
			Vector3(cos(a) * 5.05, 369.0, sin(a) * 5.05), 0.35, 0.3)
		lm.box("Windows", Vector3(cos(a + PI / 8.0) * 6.2, 362.0, sin(a + PI / 8.0) * 6.2), Vector3(1.4, 8.0, 0.2),
			Basis(Vector3.UP, -(a + PI / 8.0) + PI * 0.5), 0.0)
	lm.frustum("Limestone", Vector3(0, 368.6, 0), 5.4, 5.4, 0.8, 8, PI / 8.0)
	lm.frustum("Mast", Vector3(0, 369.0, 0), 5.0, 3.2, 8.0, 8, PI / 8.0)
	lm.frustum("Windows", Vector3(0, 372.0, 0), 4.2, 3.9, 4.0, 16)
	lm.lathe("Mast", Vector3(0, 377.0, 0), PackedVector2Array([Vector2(3.2, 0),
		Vector2(2.0, ESB_ROOF_M - 377.0), Vector2(1.0, ESB_ROOF_M - 377.0 + 6.0)]), 8)
	lm.lathe("Spandrel", Vector3(0, ESB_ROOF_M + 6.0, 0), PackedVector2Array([Vector2(1.0, 0),
		Vector2(0.6, 30.0), Vector2(0.12, ESB_TIP_M - ESB_ROOF_M - 6.0)]), 8)
	for k in 5:
		lm.frustum("Spandrel", Vector3(0, ESB_ROOF_M + 10.0 + 6.0 * k, 0), 1.5 - 0.18 * k, 1.5 - 0.18 * k, 0.6, 8)
