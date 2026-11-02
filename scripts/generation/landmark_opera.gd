class_name LandmarkOpera
extends RefCounted

## Sydney Opera House in true metres: the granite-faced podium on
## Bennelong Point with the Monumental Steps to the south, the Concert
## Hall (west) and Joan Sutherland Theatre (east) shell groups — each a
## file of tiled sails rising south to the 67 m crest, the northern
## mouths closed by faceted bronze-tinted glass walls, a small
## reversed shell over the steps — and the Bennelong restaurant shells.
## Shells are doubly curved lancet sails: chevron-tiled outside
## (LandmarkMaterials.opera_tile) with the joints between the precast
## tile lids running up from the pedestals and a raised crest along the
## ridge; inside, the fans of precast concrete ribs. The glass walls
## hang on bronze-clad steel mullions and transoms. The podium is faced
## in pink granite panels, the Monumental Steps climb 6 m in twenty
## risers.

const PODIUM := 6.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Tiles", LandmarkMaterials.opera_tile())
	lm.use("Ribs", LandmarkMaterials.pbr("concrete", "#CFC6B2", 3.0))
	lm.use("Podium", LandmarkMaterials.pbr("limestone", "#C4A486", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#3B3A33"))
	lm.use("Bronze", LandmarkMaterials.paint("#4A3B2A", 0.5, 0.6))
	_podium(lm)
	# [x, mouth z, length back, height above podium, half width, facing]
	var shells := [
		[-30.0, -70.0, 34.0, 38.0, 18.0, -1.0], [-30.0, -46.0, 42.0, 52.0, 24.0, -1.0],
		[-30.0, -14.0, 44.0, 61.0, 27.0, -1.0], [-30.0, 46.0, 30.0, 33.0, 19.0, 1.0],
		[26.0, -62.0, 30.0, 33.0, 16.0, -1.0], [26.0, -40.0, 38.0, 46.0, 21.0, -1.0],
		[26.0, -10.0, 40.0, 54.0, 24.0, -1.0], [26.0, 42.0, 27.0, 29.0, 17.0, 1.0],
		[-44.0, 82.0, 18.0, 20.0, 10.0, 1.0], [-44.0, 66.0, 14.0, 14.0, 8.0, -1.0],
	]
	for s in shells:
		_shell(lm, float(s[0]), float(s[1]), float(s[2]), float(s[3]), float(s[4]), float(s[5]))
	lm.commit(model)

static func _podium(lm: LandmarkMesh) -> void:
	lm.box("Podium", Vector3(-6.0, PODIUM * 0.5, 0), Vector3(118.0, PODIUM, 186.0))
	# Monumental Steps: 98 m wide, descending south off the podium.
	for k in 20:
		var z := 93.0 + float(k) * 1.2
		var h := PODIUM * (1.0 - float(k) / 20.0)
		lm.box("Podium", Vector3(-6.0, h * 0.5, z + 0.6), Vector3(98.0, h, 1.2), Basis(), 0.0)
	# Granite cladding: panel joints round the podium and its coping.
	lm.box("Podium", Vector3(-6.0, PODIUM + 0.2, 0), Vector3(119.0, 0.4, 187.0))
	for side in [-1.0, 1.0]:
		for k in 46:
			var z := -92.0 + float(k) * 4.0
			lm.box("Podium", Vector3(-6.0 + float(side) * 59.05, PODIUM * 0.5, z), Vector3(0.12, PODIUM, 0.1),
				Basis(), 0.0)
		lm.box("Podium", Vector3(-6.0 + float(side) * 59.1, PODIUM * 0.5, 0), Vector3(0.1, 0.1, 186.0), Basis(), 0.0)
	# Northern broadwalk glazing band under the podium edge.
	lm.box("Glass", Vector3(-6.0, PODIUM * 0.45, -93.05), Vector3(110.0, PODIUM * 0.6, 0.2))

## One sail. Mouth (pointed lancet arch) at z = zm, sweeping back
## `length` to a point on the podium; `face` -1 opens north (-Z).
static func _shell(lm: LandmarkMesh, x: float, zm: float, length: float, h: float,
		hw: float, face: float) -> void:
	var nu := 30
	var nv := 18
	var back := Vector3(x, PODIUM, zm - face * length)
	var outer: Array = []
	var inner: Array = []
	var mouth := PackedVector3Array()
	for j in nv + 1:
		var t := float(j) / float(nv)
		var row := PackedVector3Array()
		var row_in := PackedVector3Array()
		for i in nu + 1:
			var s := -1.0 + 2.0 * float(i) / float(nu)
			var y := h * sqrt(1.0 - absf(s))
			var lean := face * 6.0 * pow(y / h, 2.0)
			var m := Vector3(x + s * hw, PODIUM + y, zm + lean)
			if j == 0:
				mouth.append(m)
			var p := m.lerp(back, t)
			var radial := Vector3(m.x - x, m.y - PODIUM, 0).normalized()
			var bulge := 0.16 * Vector2(s * hw, y).length() * sin(PI * t) * (1.0 - 0.5 * t)
			p += (radial + Vector3.UP * 0.4).normalized() * bulge
			row.append(p)
			row_in.append(p - (radial + Vector3.UP * 0.4).normalized() * 0.9)
		outer.append(row)
		inner.append(row_in)
	var axis_pt := Vector3(x, PODIUM - h * 0.3, (zm + back.z) * 0.5)
	lm.grid("Tiles", outer, axis_pt, true)
	# Inside (ribbed concrete) faces the axis.
	_flip_toward(lm, inner, axis_pt)
	# Mouth edge band.
	var row0: PackedVector3Array = outer[0]
	var rin0: PackedVector3Array = inner[0]
	for i in nu:
		lm.quad("Ribs", row0[i], row0[i + 1], rin0[i + 1], rin0[i], Vector3(0, 0, face))
	# Tile-lid joints up the outside and the crest along the ridge;
	# concrete rib fans inside.
	for i in range(3, nu, 3):
		var prev: Vector3 = (outer[0] as PackedVector3Array)[i]
		var prev_in: Vector3 = (inner[0] as PackedVector3Array)[i]
		for j in range(1, nv + 1):
			var q: Vector3 = (outer[j] as PackedVector3Array)[i]
			var q_in: Vector3 = (inner[j] as PackedVector3Array)[i]
			var n := (q - axis_pt).normalized()
			lm.beam("Ribs", prev + n * 0.08, q + n * 0.08, 0.18, 0.1, n)
			lm.beam("Ribs", prev_in - n * 0.35, q_in - n * 0.35, 0.5, 0.7, n)
			prev = q
			prev_in = q_in
	var mid := nu / 2
	for j in nv:
		var p0: Vector3 = (outer[j] as PackedVector3Array)[mid]
		var p1: Vector3 = (outer[j + 1] as PackedVector3Array)[mid]
		lm.beam("Ribs", p0, p1, 0.8, 0.4, Vector3.UP)
	# Glass wall: faceted fan closing the mouth, set back slightly, on
	# bronze mullions with transoms.
	var foot := Vector3(x, PODIUM, zm - face * 4.0)
	for i in nu:
		var a := mouth[i] - Vector3(0, 0, face * 2.0)
		var b := mouth[i + 1] - Vector3(0, 0, face * 2.0)
		var n := Vector3(0, 0.2, face).normalized()
		lm.tri("Glass", foot, a, b, n, n, n, Vector2(foot.x, foot.y), Vector2(a.x, a.y), Vector2(b.x, b.y))
		lm.beam("Bronze", foot + n * 0.1, a + n * 0.1, 0.3, 0.4, n)
		for t in [0.25, 0.5, 0.75]:
			lm.beam("Bronze", foot.lerp(a, float(t)) + n * 0.1, foot.lerp(b, float(t)) + n * 0.1, 0.15, 0.3, n)

## Inner shell surface: re-emit facing the shell's axis point.
static func _flip_toward(lm: LandmarkMesh, rows: Array, pt: Vector3) -> void:
	var nv := rows.size()
	var nu := (rows[0] as PackedVector3Array).size()
	for j in nv - 1:
		var r0: PackedVector3Array = rows[j]
		var r1: PackedVector3Array = rows[j + 1]
		for i in nu - 1:
			var c := (r0[i] + r1[i + 1]) * 0.5
			var n := (pt - c).normalized()
			lm.tri("Ribs", r0[i], r0[i + 1], r1[i + 1], n, n, n,
				Vector2(i, j), Vector2(i + 1, j), Vector2(i + 1, j + 1))
			lm.tri("Ribs", r0[i], r1[i + 1], r1[i], n, n, n,
				Vector2(i, j), Vector2(i + 1, j + 1), Vector2(i, j + 1))
