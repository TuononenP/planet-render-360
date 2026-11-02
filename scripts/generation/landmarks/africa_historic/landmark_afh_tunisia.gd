class_name LandmarkAfhTunisia
extends RefCounted

## The Roman amphitheatre of El Jem (Thysdrus) in true metres. The
## Great Mosque of Kairouan is LandmarkAfhKairouan.

# --- Amphitheatre of El Jem ---

const EJ_A := 73.8
const EJ_B := 61.2
const EJ_BAYS := 64
const EJ_TIERS := [[0.0, 11.5], [11.5, 23.0], [23.0, 33.5]]

## Three-tier limestone amphitheatre (c. 238), 148 x 122 m and 36 m
## high, the long axis along X, the arena 65 x 39 m. 64 bays of arches
## in Corinthian / composite order: engaged columns with bases and
## capitals, moulded archivolts and entablatures, a partly surviving
## attic, the 30 m breach opened in 1695 and widened about 1850 (bays
## 18-28), radial walls and vaulted floors of the two ambulatories, the
## inner corridor ring and the ruined stepped cavea round the arena.
static func el_djem(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDB48A", 3.0))
	lm.use("Seats", LandmarkMaterials.pbr("limestone", "#BCA37B", 3.0))
	lm.use("Shade", LandmarkMaterials.pbr("stone", "#5A4A38", 4.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#CDB68E", 6.0))
	_el_djem_outer(lm)
	_el_djem_inner(lm)
	_el_djem_cavea(lm)
	var arena := PackedVector2Array()
	for i in 40:
		var t := TAU * float(i) / 40.0
		arena.append(Vector2(cos(t) * 32.5, -sin(t) * 19.5))
	lm.poly_prism("Sand", arena, -1.0, 0.1)
	lm.commit(model)

static func _ej_pt(a: float, b: float, i: float, y: float = 0.0) -> Vector3:
	var t := TAU * i / float(EJ_BAYS)
	return Vector3(cos(t) * a, y, -sin(t) * b)

## Storeys of the outer wall left standing at bay i (3 = full height).
static func _ej_tiers(i: int) -> int:
	if i >= 22 and i <= 24:
		return 0
	if (i >= 20 and i <= 21) or (i >= 25 and i <= 26):
		return 1
	if (i >= 18 and i <= 19) or (i >= 27 and i <= 28):
		return 2
	return 3

static func _el_djem_outer(lm: LandmarkMesh) -> void:
	for i in EJ_BAYS:
		var keep := _ej_tiers(i)
		var p0 := _ej_pt(EJ_A, EJ_B, float(i))
		var p1 := _ej_pt(EJ_A, EJ_B, float(i + 1))
		var out := Vector3(p0.x / (EJ_A * EJ_A), 0, p0.z / (EJ_B * EJ_B)).normalized()
		var out1 := Vector3(p1.x / (EJ_A * EJ_A), 0, p1.z / (EJ_B * EJ_B)).normalized()
		for t in keep:
			var y0: float = EJ_TIERS[t][0]
			var y1: float = EJ_TIERS[t][1]
			LandmarkColosseum.arch_bay(lm, "Stone", "Shade", p0, p1, y0, y1 - y0, 0.56, 0.52, 2.6)
			# Engaged column on the pier (moulded base, tapering shaft,
			# capital and abacus), impost moulding and the storey's
			# entablature.
			_ej_column(lm, p0 + out * 0.5 + Vector3(0, y0 + 0.3, 0), y1 - y0 - 1.3)
			_ej_archivolt(lm, p0, p1, out, y0, y1 - y0)
			lm.beam("Stone", p0 + out * 0.6 + Vector3(0, y1 - 0.65, 0),
				p1 + out1 * 0.6 + Vector3(0, y1 - 0.65, 0), 1.3, 1.4, Vector3.UP)
			lm.beam("Stone", p0 + out * 0.95 + Vector3(0, y1 - 0.05, 0),
				p1 + out1 * 0.95 + Vector3(0, y1 - 0.05, 0), 0.3, 0.5, Vector3.UP)
		# Radial wall carrying the vaults of the two ambulatories.
		if keep > 0:
			var q0 := _ej_pt(EJ_A - 2.6, EJ_B - 2.6, float(i))
			var q1 := _ej_pt(EJ_A - 10.4, EJ_B - 10.4, float(i))
			var top: float = EJ_TIERS[mini(keep, 2) - 1][1]
			var mid := (q0 + q1) * 0.5
			lm.box("Stone", mid + Vector3(0, top * 0.5, 0), Vector3(1.2, top, q0.distance_to(q1)),
				Basis(Vector3.UP, atan2(q0.x - q1.x, q0.z - q1.z)))
			# Vault floors of the ambulatory between the storeys.
			var r0 := _ej_pt(EJ_A - 10.4, EJ_B - 10.4, float(i + 1))
			var r1 := _ej_pt(EJ_A - 2.6, EJ_B - 2.6, float(i + 1))
			for t in mini(keep, 2):
				var y: float = EJ_TIERS[t][1]
				var up := Vector3(0, y, 0)
				lm.quad("Stone", q0 + up, r1 + up, r0 + up, q1 + up, Vector3.UP)
				lm.quad("Shade", q0 + up - Vector3(0, 0.6, 0), r1 + up - Vector3(0, 0.6, 0),
					r0 + up - Vector3(0, 0.6, 0), q1 + up - Vector3(0, 0.6, 0), Vector3.DOWN)
		# The attic survives only round the south and east.
		if keep == 3 and i >= 38 and i <= 62:
			lm.beam("Stone", p0 + out * 0.4 + Vector3(0, 34.75, 0), p1 + out1 * 0.4 + Vector3(0, 34.75, 0),
				2.5, 1.8, Vector3.UP)
			if i % 2 == 0:
				var m := (p0 + p1) * 0.5 + out * 1.3
				lm.box("Shade", m + Vector3(0, 34.6, 0), Vector3(1.6, 1.6, 0.1),
					Basis(Vector3.UP, atan2(out.x, out.z)))

## Engaged half-column of height h on the pier at `b`: plinth and torus,
## a tapering shaft and a flared composite capital under its abacus.
static func _ej_column(lm: LandmarkMesh, b: Vector3, h: float) -> void:
	lm.lathe("Stone", b, PackedVector2Array([Vector2(0.8, 0), Vector2(0.8, 0.3), Vector2(0.68, 0.38),
		Vector2(0.72, 0.52), Vector2(0.58, 0.66), Vector2(0.56, h * 0.33), Vector2(0.48, h - 1.0),
		Vector2(0.53, h - 0.92), Vector2(0.62, h - 0.6), Vector2(0.76, h - 0.22), Vector2(0.8, h)]), 10)

## Moulded archivolt round the outer arch of a bay (the arch geometry of
## LandmarkColosseum.arch_bay: 56% open, springing at 52%), with the
## impost blocks it springs from.
static func _ej_archivolt(lm: LandmarkMesh, p0: Vector3, p1: Vector3, out: Vector3, y0: float,
		h: float) -> void:
	var o0 := p0.lerp(p1, 0.22)
	var o1 := p0.lerp(p1, 0.78)
	var ow := o0.distance_to(o1)
	var spring := y0 + h * 0.52
	var r := minf(ow * 0.5, (h - h * 0.52) * 0.85)
	var c := (o0 + o1) * 0.5 + out * 0.12
	var dir := (o1 - o0).normalized()
	var prev := c + dir * -(ow * 0.5 + 0.22) + Vector3(0, spring, 0)
	for k in range(1, 8):
		var t := PI - PI * float(k) / 7.0
		var pt := c + dir * cos(t) * (ow * 0.5 + 0.22) + Vector3(0, spring + sin(t) * (r + 0.22), 0)
		lm.beam("Stone", prev, pt, 0.24, 0.4, out)
		prev = pt
	for e in [o0, o1]:
		lm.beam("Stone", (e as Vector3) + out * 0.1 + Vector3(0, spring - 0.12, 0) - dir * 0.35,
			(e as Vector3) + out * 0.1 + Vector3(0, spring - 0.12, 0) + dir * 0.35, 0.3, 0.24, Vector3.UP)

## Inner corridor wall: two arcaded storeys all round.
static func _el_djem_inner(lm: LandmarkMesh) -> void:
	for i in EJ_BAYS:
		var p0 := _ej_pt(EJ_A - 11.0, EJ_B - 11.0, float(i))
		var p1 := _ej_pt(EJ_A - 11.0, EJ_B - 11.0, float(i + 1))
		var tiers := 2 if i < 22 or i > 26 else 1
		for t in tiers:
			var y0: float = EJ_TIERS[t][0]
			var y1: float = EJ_TIERS[t][1]
			LandmarkColosseum.arch_bay(lm, "Stone", "Shade", p0, p1, y0, y1 - y0, 0.5, 0.52, 2.0)

## Stepped seating from the arena wall up to the inner ring, with the
## breach and random missing blocks.
static func _el_djem_cavea(lm: LandmarkMesh) -> void:
	var k_steps := 21
	for i in EJ_BAYS:
		if i >= 21 and i <= 25:
			continue
		for k in k_steps:
			if LandmarkAfhParts.hash01(i, k) < 0.1 * float(k) / 9.0:
				continue
			var f0 := float(k) / float(k_steps)
			var f1 := float(k + 1) / float(k_steps)
			var a0 := lerpf(32.5, EJ_A - 13.0, f0)
			var b0 := lerpf(19.5, EJ_B - 13.0, f0)
			var a1 := lerpf(32.5, EJ_A - 13.0, f1)
			var b1 := lerpf(19.5, EJ_B - 13.0, f1)
			var y := 2.0 + 3.2 * float(k + 1) / 3.0
			lm.quad("Seats", _ej_pt(a0, b0, float(i), y), _ej_pt(a0, b0, float(i + 1), y),
				_ej_pt(a1, b1, float(i + 1), y), _ej_pt(a1, b1, float(i), y), Vector3.UP)
			var q0 := _ej_pt(a0, b0, float(i), y - 3.2 / 3.0)
			var q1 := _ej_pt(a0, b0, float(i + 1), y - 3.2 / 3.0)
			var inward := -Vector3(q0.x / (a0 * a0), 0, q0.z / (b0 * b0)).normalized()
			lm.quad("Seats", q0, q1, q1 + Vector3(0, 3.2 / 3.0, 0), q0 + Vector3(0, 3.2 / 3.0, 0), inward)
