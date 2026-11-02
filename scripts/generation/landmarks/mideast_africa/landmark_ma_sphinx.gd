class_name LandmarkMaSphinx
extends RefCounted

## The Great Sphinx of Giza in true metres, facing east (+X).

## Body stations from the rump to the chest: (x, half-width, top height).
const BODY := [[-38.0, 0.4, 3.5], [-37.2, 4.6, 7.0], [-35.5, 7.8, 9.2], [-32.0, 9.5, 10.2],
	[-27.0, 9.3, 10.4], [-21.0, 8.4, 10.6], [-14.0, 8.0, 10.8], [-7.0, 8.0, 11.2], [0.0, 8.2, 11.8],
	[5.0, 8.4, 12.4], [9.0, 7.8, 12.6], [11.5, 6.5, 12.0], [13.0, 4.5, 10.0], [13.8, 0.6, 7.0]]

## Khafre's recumbent lion (c. 2500 BC) carved from the bedrock: 73 m
## from paws to tail, 20 m to the crown of the head, 19 m across the
## haunches. A lofted lion body with haunches, hind paws and the tail
## curled along the right (south) flank; the forelegs reaching 21 m
## forward with their toes; the king's head in the striped nemes with
## its lappets, the eroded face without nose or beard; the granite Dream
## Stele of Thutmose IV between the paws in its little walled chapel;
## the rock-cut enclosure rising round it in eroded strata (raised from
## the pit floor) and the ruined Sphinx Temple in front.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sphinx", LandmarkMaterials.pbr("limestone", "#C9AE7C", 3.0))
	lm.use("Pit", LandmarkMaterials.pbr("limestone", "#A98F66", 6.0))
	lm.use("Stele", LandmarkMaterials.pbr("stone", "#8F6C5A", 1.5))
	lm.box("Pit", Vector3(-6, 0.15, 0), Vector3(96, 0.3, 46))
	_body(lm)
	_head(lm, Vector3(10.6, 0, 0))
	for s in [-1.0, 1.0]:
		_foreleg(lm, s)
		_hind(lm, s)
	_tail(lm)
	# Dream Stele and the low walls of its chapel between the paws.
	lm.box("Stele", Vector3(14.6, 2.1, 0), Vector3(0.8, 3.6, 2.4))
	lm.lathe("Stele", Vector3(14.6, 3.9, 0), PackedVector2Array([Vector2(1.2, 0), Vector2(0.9, 0.5),
		Vector2(0.0, 0.7)]), 12, 0.35, 1.0)
	for s in [-1.0, 1.0]:
		lm.box("Pit", Vector3(19.5, 1.0, s * 2.15), Vector3(9.0, 1.4, 0.5))
	lm.box("Pit", Vector3(24.2, 0.8, 0), Vector3(0.6, 1.0, 4.8))
	_enclosure(lm)
	_temple(lm, Vector3(52, 0, 0))
	lm.commit(model)

## Lofted body: rounded sections through BODY, sides dropping to the
## bedrock, the back sagging between the haunches and the shoulders.
static func _body(lm: LandmarkMesh) -> void:
	var rows: Array = []
	var k := 14
	for st in BODY:
		var x := float(st[0])
		var w := float(st[1])
		var top := float(st[2])
		var row := PackedVector3Array()
		for i in k + 1:
			var th := PI * float(i) / float(k)
			var c := cos(th)
			var sn := sin(th)
			var z := w * signf(c) * pow(absf(c), 0.55)
			var y := 0.3 + (top - 0.3) * pow(sn, 0.4)
			row.append(Vector3(x, y, z))
		rows.append(row)
	lm.grid("Sphinx", rows, Vector3(0, -60, 0), true)
	# The spine and the shoulder blades as low ridges on the back.
	for i in BODY.size() - 5:
		var a: Array = BODY[i + 2]
		var b: Array = BODY[i + 3]
		lm.beam("Sphinx", Vector3(float(a[0]), float(a[2]) - 0.2, 0), Vector3(float(b[0]), float(b[2]) - 0.2, 0),
			1.4, 0.6)
	for s in [-1.0, 1.0]:
		LandmarkMaParts.sphere(lm, "Sphinx", Vector3(4.5, 9.2, s * 7.4), 3.4, 12, 6, 0.9)

## Ellipsoid of radii (rx, ry, rz) centred on c.
static func _blob(lm: LandmarkMesh, c: Vector3, rx: float, ry: float, rz: float, seg: int = 12) -> void:
	var p := PackedVector2Array()
	for i in 7:
		var a := -PI * 0.5 + PI * float(i) / 6.0
		p.append(Vector2(cos(a), ry * (1.0 + sin(a))))
	lm.lathe("Sphinx", c - Vector3(0, ry, 0), p, seg, rx, rz)

## Foreleg on side s: the upper leg at the chest, the long forearm on the
## ground and the paw with four toes.
static func _foreleg(lm: LandmarkMesh, s: float) -> void:
	var z := s * 4.7
	_blob(lm, Vector3(10.5, 4.2, z * 1.12), 3.4, 4.0, 2.4)
	lm.box("Sphinx", Vector3(21.0, 1.75, z), Vector3(20, 3.2, 4.0))
	_blob(lm, Vector3(31.0, 1.7, z), 2.4, 1.6, 2.2)
	for t in 4:
		var tz := z + (float(t) - 1.5) * 0.95
		lm.beam("Sphinx", Vector3(31.5, 0.75, tz), Vector3(33.6, 0.65, tz), 0.85, 1.1)
		_blob(lm, Vector3(33.7, 0.65, tz), 0.5, 0.55, 0.45, 8)

## Haunch bulge and the hind paw tucked forward along the flank.
static func _hind(lm: LandmarkMesh, s: float) -> void:
	_blob(lm, Vector3(-28.5, 5.2, s * 8.6), 6.8, 5.0, 2.2)
	lm.beam("Sphinx", Vector3(-25.0, 1.3, s * 10.2), Vector3(-15.0, 1.2, s * 10.4), 2.2, 2.4)
	_blob(lm, Vector3(-14.6, 1.2, s * 10.4), 1.6, 1.2, 1.4, 10)
	for t in 3:
		var tz := s * 10.4 + (float(t) - 1.0) * 0.8
		lm.beam("Sphinx", Vector3(-14.4, 0.55, tz), Vector3(-13.1, 0.5, tz), 0.6, 0.8)

## Tail from the rump curling round the right (south) haunch and
## forward along the flank.
static func _tail(lm: LandmarkMesh) -> void:
	var pts := [Vector3(-37.6, 3.0, 5.0), Vector3(-37.4, 2.0, 7.8), Vector3(-35.8, 1.4, 10.2),
		Vector3(-33.0, 1.1, 11.0), Vector3(-29.0, 1.0, 11.2), Vector3(-25.0, 1.0, 11.0), Vector3(-23.4, 1.2, 10.8)]
	for i in pts.size() - 1:
		lm.beam("Sphinx", pts[i], pts[i + 1], 0.9 - 0.06 * float(i), 0.9 - 0.06 * float(i))

## The king's head at x = c.x: neck, striped nemes with its wings and
## lappets, the face (nose and beard lost), eyes, ears and the uraeus
## stump; crown of the head at 20 m.
static func _head(lm: LandmarkMesh, c: Vector3) -> void:
	lm.lathe("Sphinx", c + Vector3(0, 10.5, 0), PackedVector2Array([Vector2(3.6, 0), Vector2(3.0, 2.5),
		Vector2(2.7, 4.5)]), 14, 1.0, 1.15)
	var hb := c + Vector3(0, 13.4, 0)
	var nemes := PackedVector2Array([Vector2(3.9, 0), Vector2(4.0, 1.4), Vector2(3.8, 3.2), Vector2(3.3, 4.6),
		Vector2(2.4, 5.7), Vector2(1.2, 6.4), Vector2(0.0, 6.6)])
	lm.lathe("Sphinx", hb, nemes, 18, 0.95, 1.2)
	# Nemes stripes: shallow raised bands round the cloth.
	for y in [1.0, 2.0, 3.0, 4.0, 4.9]:
		var r := LandmarkMesh.profile_at(PackedVector2Array([Vector2(0, 3.9), Vector2(1.4, 4.0),
			Vector2(3.2, 3.8), Vector2(4.6, 3.3), Vector2(5.7, 2.4)]), y)
		lm.lathe("Sphinx", hb + Vector3(0, y, 0), PackedVector2Array([Vector2(r + 0.08, 0),
			Vector2(r + 0.08, 0.25)]), 18, 0.95, 1.2, 0.0, true, false)
	# Wings of the nemes flaring behind the face down to the shoulders.
	for s in [-1.0, 1.0]:
		lm.beam("Sphinx", hb + Vector3(1.2, 4.0, s * 3.8), hb + Vector3(1.0, -1.0, s * 5.0), 1.2, 3.4,
			Vector3(1, 0, 0))
		# Lappets hanging in front of the shoulders beside the face.
		lm.box("Sphinx", hb + Vector3(3.3, 0.2, s * 2.9), Vector3(1.0, 5.0, 1.4))
		lm.box("Sphinx", hb + Vector3(3.4, 4.5, s * 2.35), Vector3(0.6, 1.4, 0.4))
	# Face: brow, cheeks, the nose stump, mouth and chin, eyes, ears.
	var f := hb + Vector3(3.4, 2.6, 0)
	lm.box("Sphinx", f, Vector3(1.6, 4.0, 4.1))
	lm.box("Sphinx", f + Vector3(0.6, 1.0, 0), Vector3(0.6, 0.4, 3.6))
	lm.box("Sphinx", f + Vector3(0.75, -0.05, 0), Vector3(0.5, 1.2, 0.9))
	lm.box("Sphinx", f + Vector3(0.7, -1.1, 0), Vector3(0.4, 0.25, 1.6))
	lm.box("Sphinx", f + Vector3(0.55, -1.75, 0), Vector3(0.7, 0.6, 2.2))
	for s in [-1.0, 1.0]:
		lm.box("Pit", f + Vector3(0.83, 0.55, s * 1.0), Vector3(0.08, 0.45, 0.9), Basis(), 0.0)
		lm.box("Sphinx", f + Vector3(-0.6, 0.4, s * 2.2), Vector3(1.0, 1.6, 0.5))
	lm.box("Sphinx", hb + Vector3(3.9, 5.1, 0), Vector3(0.5, 0.8, 0.5))

## Rock-cut enclosure walls (north, south, west) in stepped, eroded
## strata standing on the pit floor (y = 0), opening east.
static func _enclosure(lm: LandmarkMesh) -> void:
	for wall in [[Vector2(-52, -24), Vector2(30, -24), Vector3(0, 0, -1)],
			[Vector2(-52, 24), Vector2(30, 24), Vector3(0, 0, 1)],
			[Vector2(-50, -24), Vector2(-50, 24), Vector3(-1, 0, 0)]]:
		var a: Vector2 = wall[0]
		var b: Vector2 = wall[1]
		var out: Vector3 = wall[2]
		var n := int(a.distance_to(b) / 6.0)
		for i in n:
			var t0 := float(i) / float(n)
			var t1 := float(i + 1) / float(n)
			var p := a.lerp(b, (t0 + t1) * 0.5)
			var run := a.distance_to(b) / float(n)
			var h := 8.5 + 2.0 * sin(float(i) * 1.3) + (1.5 if out.x != 0.0 else 0.0)
			var basis := Basis(Vector3(b.x - a.x, 0, b.y - a.y).normalized(), Vector3.UP, out)
			for k in 4:
				var lh := h / 4.0
				var inset := 0.6 * float(k) + 0.4 * sin(float(i + k) * 2.1)
				lm.box("Pit", Vector3(p.x, lh * (float(k) + 0.5), p.y) + out * (2.5 + inset),
					Vector3(run + 0.05, lh, 5.0), basis)

## The ruined Sphinx Temple east of the paws: a 46 x 44 m enclosure of
## core-masonry walls with gaps, and the stumps of the 24 pillars round
## its open court.
static func _temple(lm: LandmarkMesh, c: Vector3) -> void:
	for e in [[Vector3(-23, 0, -22), Vector3(23, 0, -22)], [Vector3(-23, 0, 22), Vector3(23, 0, 22)],
			[Vector3(23, 0, -22), Vector3(23, 0, 22)]]:
		var a: Vector3 = e[0]
		var b: Vector3 = e[1]
		var n := 7
		for i in n:
			var p := c + a.lerp(b, (float(i) + 0.5) / float(n))
			var h := 3.0 + 1.8 * absf(sin(float(i) * 2.7))
			var dir := (b - a).normalized()
			lm.box("Pit", p + Vector3(0, h * 0.5, 0), Vector3(dir.x * a.distance_to(b) / n * 0.9 + 2.4 * absf(dir.z),
				h, dir.z * a.distance_to(b) / n * 0.9 + 2.4 * absf(dir.x)))
	for s in [-1.0, 1.0]:
		lm.box("Pit", c + Vector3(-23, 2.0, s * 13.0), Vector3(2.4, 4.0, 18.0))
	for i in 24:
		var t := float(i) / 24.0
		var p: Vector3
		if t < 0.25:
			p = Vector3(-10 + 80.0 * t, 0, -9)
		elif t < 0.5:
			p = Vector3(10, 0, -9 + 72.0 * (t - 0.25))
		elif t < 0.75:
			p = Vector3(10 - 80.0 * (t - 0.5), 0, 9)
		else:
			p = Vector3(-10, 0, 9 - 72.0 * (t - 0.75))
		var ph := 1.2 + 1.6 * absf(sin(float(i) * 1.9))
		lm.box("Stele", c + p + Vector3(0, ph * 0.5, 0), Vector3(1.4, ph, 1.4))
