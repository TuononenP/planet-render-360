class_name LandmarkNaTowers
extends RefCounted

## Three observation towers in true metres: Toronto's CN Tower, Seattle's
## Space Needle and Las Vegas's STRAT.

const CN_TIP_M := 553.3
const CN_SKYPOD_M := 447.0
const NEEDLE_TIP_M := 184.0
const STRAT_TIP_M := 350.2

## CN Tower: the hexagonal concrete shaft with three tapering buttress
## legs (the Y plan) that merge into it below the main pod (335 m), the
## seven-storey pod and its glazed band, the SkyPod at 447 m and the
## steel broadcast mast to the 553.3 m tip.
static func cn_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B9B6AE", 5.0))
	lm.use("Glass", LandmarkMaterials.glass("#5E7686"))
	lm.use("Mast", LandmarkMaterials.paint("#D9DBDC", 0.4, 0.5))
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(12.0, -3.0), Vector2(11.0, 0.0),
		Vector2(8.6, 90.0), Vector2(6.8, 200.0), Vector2(5.8, 320.0), Vector2(5.4, 335.0),
		Vector2(5.0, CN_SKYPOD_M)]), 6, 1.0, 1.0, PI / 6.0, false)
	for k in 3:
		_fin(lm, TAU * float(k) / 3.0 + PI / 6.0, 8.0, 26.0, 335.0, 3.4)
	# Main pod: flared underside, the glazed observation band, roof cap.
	var pod := Vector3(0, 331.0, 0)
	lm.lathe("Concrete", pod, PackedVector2Array([Vector2(5.4, 0.0), Vector2(11.0, 3.0),
		Vector2(17.5, 7.5), Vector2(19.2, 10.5), Vector2(19.2, 14.0), Vector2(16.0, 19.0),
		Vector2(10.0, 24.0), Vector2(6.0, 28.0)]), 28)
	lm.lathe("Glass", pod + Vector3(0, 10.5, 0), PackedVector2Array([Vector2(19.35, 0.0),
		Vector2(19.35, 3.5)]), 28, 1.0, 1.0, 0.0, true, false)
	# SkyPod and the mast.
	var sky := Vector3(0, CN_SKYPOD_M, 0)
	lm.lathe("Concrete", sky, PackedVector2Array([Vector2(5.0, 0.0), Vector2(8.2, 1.8),
		Vector2(8.6, 4.5), Vector2(6.0, 7.5), Vector2(3.8, 10.0)]), 16)
	lm.lathe("Mast", sky + Vector3(0, 10.0, 0), PackedVector2Array([Vector2(3.6, 0.0),
		Vector2(2.6, 30.0), Vector2(1.6, 65.0), Vector2(0.9, 90.0),
		Vector2(0.15, CN_TIP_M - CN_SKYPOD_M - 10.0)]), 10)
	lm.frustum("Concrete", Vector3(0, -3.0, 0), 34.0, 34.0, 3.0, 6, PI / 6.0)
	lm.commit(model)

## One concave buttress fin: a thin radial slab `thick` wide, `r_in` at
## the shaft and `r_out` at the ground, narrowing to nothing at `h`.
static func _fin(lm: LandmarkMesh, yaw: float, r_in: float, r_out: float, h: float,
		thick: float) -> void:
	var b := Basis(Vector3.UP, -yaw)
	var steps := 9
	var prev := Vector2(r_out, 0.0)
	for k in range(1, steps + 1):
		var f := float(k) / steps
		var cur := Vector2(r_in + (r_out - r_in) * pow(1.0 - f, 2.2), h * f)
		var s := cur - prev
		var n_out: Vector3 = b * Vector3(s.y, -s.x, 0.0).normalized()
		for z in [-1.0, 1.0]:
			var zz: float = z * thick * 0.5
			var side: Vector3 = b * Vector3(0, 0, z)
			# Face of the slab between the shaft line and the outer edge.
			lm.quad("Concrete", b * Vector3(r_in, prev.y, zz), b * Vector3(prev.x, prev.y, zz),
				b * Vector3(cur.x, cur.y, zz), b * Vector3(r_in, cur.y, zz), side)
		lm.quad("Concrete", b * Vector3(prev.x, prev.y, -thick * 0.5), b * Vector3(prev.x, prev.y, thick * 0.5),
			b * Vector3(cur.x, cur.y, thick * 0.5), b * Vector3(cur.x, cur.y, -thick * 0.5), n_out)
		prev = cur

## Space Needle: the hourglass of four braced steel legs pinched at the
## waist (96 m), the flying-saucer top house (underside cone, glazed
## restaurant band, gold roof) on its core and the 184 m beacon mast.
static func space_needle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.paint("#F1EFE9", 0.5, 0.15))
	lm.use("Gold", LandmarkMaterials.paint("#C98A2B", 0.4, 0.45))
	lm.use("Glass", LandmarkMaterials.glass("#4F6674"))
	lm.use("Base", LandmarkMaterials.pbr("concrete", "#A9A59C", 4.0))
	var ys := [0.0, 24.0, 52.0, 80.0, 96.0, 112.0, 128.0, 140.0]
	var rs := [15.0, 10.5, 6.6, 4.0, 3.4, 4.6, 6.8, 8.2]
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			for i in ys.size() - 1:
				var a := Vector3(sx * float(rs[i]), float(ys[i]), sz * float(rs[i]))
				var b := Vector3(sx * float(rs[i + 1]), float(ys[i + 1]), sz * float(rs[i + 1]))
				lm.beam("White", a, b, 2.2, 2.2)
	# Horizontal ring bracing between neighbouring legs.
	for i in ys.size():
		var r: float = rs[i]
		for q in 4:
			var d := Vector3(cos(PI * 0.5 * q), 0, sin(PI * 0.5 * q))
			var t := Vector3(-d.z, 0, d.x)
			var c := (d + t) * r
			var n := (d - t) * r
			lm.beam("White", Vector3(c.x, float(ys[i]), c.z), Vector3(n.x, float(ys[i]), n.z), 0.9, 0.9)
	lm.frustum("White", Vector3.ZERO, 3.4, 3.0, 150.0, 12)
	# Top house: underside cone, glazed band, gold roof, pod and mast.
	lm.lathe("White", Vector3(0, 138.0, 0), PackedVector2Array([Vector2(6.0, 0.0), Vector2(12.0, 3.0),
		Vector2(18.0, 6.0), Vector2(21.0, 8.5), Vector2(21.6, 10.5)]), 32)
	lm.frustum("Glass", Vector3(0, 148.5, 0), 21.4, 21.4, 7.5, 32)
	lm.lathe("Gold", Vector3(0, 156.0, 0), PackedVector2Array([Vector2(22.4, 0.0), Vector2(22.6, 1.0),
		Vector2(19.0, 3.2), Vector2(6.0, 4.0)]), 32)
	lm.lathe("White", Vector3(0, 160.0, 0), PackedVector2Array([Vector2(3.6, 0.0), Vector2(2.6, 6.0),
		Vector2(1.0, 14.0), Vector2(0.1, NEEDLE_TIP_M - 160.0)]), 12)
	lm.frustum("Base", Vector3(0, -3.0, 0), 20.0, 20.0, 3.2, 16)
	lm.commit(model)

## The STRAT (Stratosphere Tower): three fluted concrete legs round a
## core, the seven-storey pod flaring out at 250 m with its glazed
## deck, and the steel needle with the thrill-ride masts to 350.2 m.
static func strat(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C9C3B8", 5.0))
	lm.use("Glass", LandmarkMaterials.glass("#6A8494"))
	lm.use("Mast", LandmarkMaterials.paint("#D6D8DA", 0.4, 0.55))
	lm.use("Light", LandmarkMaterials.lit("#E9C46A", 0.5))
	for k in 3:
		var a := TAU * float(k) / 3.0 + PI * 0.5
		lm.lathe("Concrete", Vector3(cos(a) * 7.0, 0, sin(a) * 7.0), PackedVector2Array([
			Vector2(5.6, -2.0), Vector2(5.0, 120.0), Vector2(4.2, 250.0)]), 14)
	lm.frustum("Concrete", Vector3(0, -2.0, 0), 7.0, 5.6, 256.0, 12)
	var pod := Vector3(0, 250.0, 0)
	lm.lathe("Concrete", pod, PackedVector2Array([Vector2(8.0, 0.0), Vector2(15.0, 3.0),
		Vector2(24.0, 8.0), Vector2(28.5, 13.0), Vector2(28.5, 20.0), Vector2(25.0, 26.0),
		Vector2(14.0, 29.0), Vector2(6.0, 30.0)]), 36)
	lm.lathe("Glass", pod + Vector3(0, 13.0, 0), PackedVector2Array([Vector2(28.7, 0.0),
		Vector2(28.7, 6.5)]), 36, 1.0, 1.0, 0.0, true, false)
	lm.frustum("Light", pod + Vector3(0, 8.0, 0), 25.6, 25.6, 0.5, 36)
	# The needle: concrete lower mast, steel upper mast to the tip.
	var top := pod + Vector3(0, 30.0, 0)
	lm.lathe("Concrete", top, PackedVector2Array([Vector2(7.5, 0.0), Vector2(5.8, 22.0),
		Vector2(4.2, 45.0)]), 14)
	lm.lathe("Mast", top + Vector3(0, 45.0, 0), PackedVector2Array([Vector2(3.4, 0.0),
		Vector2(2.2, 9.0), Vector2(1.0, 18.0), Vector2(0.15, STRAT_TIP_M - 325.0)]), 10)
	lm.frustum("Concrete", Vector3(0, -3.0, 0), 22.0, 22.0, 3.0, 12)
	lm.commit(model)
