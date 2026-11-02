class_name LandmarkWhParis
extends RefCounted

## The Sainte-Chapelle in true metres, y = 0 at the street (the Palais
## Garnier, the other Paris landmark of the batch, is LandmarkWhGarnier).

## Sainte-Chapelle (75.5 m to the cross of the spire): the Rayonnant
## palace chapel on the Île de la Cité (1242-48), nave along X with the
## west porch at -X, 36 m long and 17 m wide over the buttresses. The
## low lower chapel, the upper chapel's fifteen 15.5 m windows (four
## four-light bays a side and seven in the semi-heptagonal apse) between
## pinnacled buttresses with a gablet over every bay and the pierced
## balustrade along the eaves; the steep lead roof (ridge 42.5 m) with
## its cresting and the angel on the chevet; the two-storey west porch
## under the Flamboyant rose, its two octagonal stair turrets, and the
## 33 m openwork lead flèche of 1853.
static func sainte_chapelle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBE9E", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#59626A", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#26385C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	var hw := 6.15
	var eave := 27.0
	# Nave walls: a plinth, the lower chapel and the upper-chapel wall.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 0, 24.0, eave, hw * 2.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 0, 24.4, 0.8, hw * 2.0 + 0.6)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		var face: float = sz * hw
		LandmarkWestKit.blk(lm, "Stone", 0, 8.0, face + sz * 0.15, 24.0, 0.7, 0.5)
		LandmarkWestKit.blk(lm, "Stone", 0, eave - 1.0, face + sz * 0.2, 24.0, 1.0, 0.6)
		for b in 4:
			var x := -9.0 + 6.0 * float(b)
			# Lower chapel: a trefoil-headed window per bay; upper chapel:
			# the four-light window with its rose-and-lancet tracery.
			LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(x, 2.6, face), n, 1.6, 2.4, 1.3, 1, 0.25)
			LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(x, 9.2, face), n, 4.3, 12.2, 3.8, 4, 0.35)
			# Gablet over the bay, rising through the balustrade.
			lm.gable("Stone", Vector3(x, eave - 0.6, face + sz * 0.5), 4.8, 1.0, 5.0, Basis(), 0.0, "Stone")
			LandmarkWhGothic.oculus(lm, "Glass", "Stone", Vector3(x, eave + 1.2, face + sz * 1.02), n, 0.9)
			LandmarkWhGothic.pinnacle(lm, "Stone", Vector3(x, eave + 4.4, face + sz * 0.5), 0.18, 0.4, 1.2)
		LandmarkWhGothic.parapet(lm, "Stone", Vector3(-12.0, eave, face), Vector3(12.0, eave, face), n, 1.4, 1.2)
		for p in 5:
			var px := -12.0 + 6.0 * float(p)
			LandmarkWhGothic.buttress(lm, "Stone", Vector3(px, 0, face), n, 1.5, 2.2, eave, 3)
			LandmarkWhGothic.pinnacle(lm, "Stone", Vector3(px, eave, face + sz * 0.75), 0.6, 2.4, 4.6)
	lm.gable("Lead", Vector3(0, eave, 0), hw * 2.0, 25.0, 15.5, rot, 0.5, "Stone")
	# Ridge cresting of lead fleurons.
	for k in 26:
		var x := -12.0 + float(k)
		lm.box("Lead", Vector3(x, eave + 15.5 + 0.5, 0), Vector3(0.12, 0.9, 0.12), Basis(), 0.0)
		lm.box("Lead", Vector3(x, eave + 15.5 + 0.75, 0), Vector3(0.12, 0.12, 0.5), Basis(), 0.0)
	lm.box("Lead", Vector3(0, eave + 15.5 + 0.1, 0), Vector3(25.0, 0.2, 0.3), Basis(), 0.0)
	_apse(lm, Vector3(12.0, 0, 0), hw, eave)
	# West porch: two storeys of arcades (the king's upper porch level with
	# the upper chapel), the terrace balustrade, the rose and gable above.
	LandmarkWestKit.blk(lm, "Stone", -15.2, 0, 0, 6.4, 6.6, hw * 2.0 + 1.0)
	LandmarkWestKit.blk(lm, "Stone", -15.2, 6.6, 0, 6.4, 0.9, hw * 2.0 + 1.4)
	LandmarkWestKit.blk(lm, "Stone", -14.4, 7.5, 0, 4.8, 6.0, hw * 2.0)
	var wn := Vector3(-1, 0, 0)
	for p in [[0.0, 4.6, 3.4], [-4.0, 1.8, 3.0], [4.0, 1.8, 3.0]]:
		LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-18.42, 0.6, p[0]), wn, p[1], p[2], p[1] * 0.7, 1, 0.4)
		LandmarkWhGothic.window(lm, "Glass", "Stone", Vector3(-16.82, 7.8, p[0]), wn, p[1], p[2] + 0.4, p[1] * 0.7, 2,
			0.4)
		lm.gable("Stone", Vector3(-18.6, 5.0, p[0]), p[1] + 1.4, 0.6, 2.6, rot, 0.0, "Stone")
	LandmarkWhGothic.parapet(lm, "Stone", Vector3(-18.4, 7.5, -hw - 0.5), Vector3(-18.4, 7.5, hw + 0.5), wn, 1.1, 1.1)
	LandmarkWhGothic.parapet(lm, "Stone", Vector3(-16.8, 13.5, -hw), Vector3(-16.8, 13.5, hw), wn, 1.2, 1.1)
	LandmarkWhGothic.rose(lm, "Glass", "Stone", Vector3(-12.1, 20.5, 0), wn, 4.5, 24)
	LandmarkWestKit.blk(lm, "Stone", -12.25, eave - 1.0, 0, 0.5, 1.0, hw * 2.0)
	LandmarkWhGothic.parapet(lm, "Stone", Vector3(-12.2, eave, -hw), Vector3(-12.2, eave, hw), wn, 1.4, 1.1)
	# Blind tracery on the west gable and its crowning cross.
	for k in 3:
		LandmarkWhGothic.window(lm, "Stone", "Stone", Vector3(-12.6, eave + 2.0, -3.2 + 3.2 * float(k)), wn, 1.6,
			4.0 - absf(float(k) - 1.0) * 2.0, 1.4, 2, 0.2, false)
	LandmarkWestKit.cross(lm, "Stone", Vector3(-12.5, eave + 15.5, 0), 2.0)
	# Octagonal stair turrets flanking the front, crowned and spired.
	for sz in [-1.0, 1.0]:
		var tc := Vector3(-17.2, 0, sz * 6.7)
		lm.lathe("Stone", tc, PackedVector2Array([Vector2(1.75, 0), Vector2(1.75, 0.8), Vector2(1.55, 1.2),
			Vector2(1.55, 30.0)]), 8, 1.0, 1.0, PI / 8.0, false)
		for y in [7.5, 14.0, 20.5, 27.0]:
			lm.frustum("Stone", tc + Vector3(0, y, 0), 1.75, 1.75, 0.45, 8, PI / 8.0)
		for k in 8:
			var a := TAU * (float(k) + 0.5) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.gable("Stone", tc + d * 1.3 + Vector3(0, 29.6, 0), 1.1, 0.5, 1.6, Basis(Vector3.UP, atan2(d.x, d.z)),
				0.0, "Stone")
			LandmarkWhGothic.slit(lm, "Glass", tc + d * 1.43 + Vector3(0, 11.0 + 6.5 * float(k % 3), 0), d, 1.6)
		LandmarkWhGothic.parapet(lm, "Stone", tc + Vector3(-1.6, 30.0, -1.6), tc + Vector3(1.6, 30.0, -1.6),
			Vector3(0, 0, -1), 1.0, 0.8, 0.25)
		LandmarkWhGothic.parapet(lm, "Stone", tc + Vector3(-1.6, 30.0, 1.6), tc + Vector3(1.6, 30.0, 1.6),
			Vector3(0, 0, 1), 1.0, 0.8, 0.25)
		lm.lathe("Stone", tc + Vector3(0, 30.0, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(0.9, 3.5),
			Vector2(0.0, 8.5)]), 8, 1.0, 1.0, PI / 8.0, false)
		LandmarkWestKit.cross(lm, "Gilt", tc + Vector3(0, 38.4, 0), 1.2)
	_fleche(lm, Vector3(2.0, 41.0, 0))
	lm.commit(model)

## The semi-heptagonal apse on its chord at `c` (x = the nave's east
## end): seven faces of a 14-gon on the nave half-width, a two-light
## window in each (the apse's seven 15 m lancets), a buttress with a
## pinnacle at each angle, the balustrade, and the half-cone lead roof
## to the ridge end, where the lead angel stands.
static func _apse(lm: LandmarkMesh, c: Vector3, hw: float, eave: float) -> void:
	var pts: Array[Vector3] = []
	for k in 8:
		var a := -PI * 0.5 + PI * float(k) / 7.0
		pts.append(c + Vector3(cos(a), 0, sin(a)) * hw)
	var poly := PackedVector2Array([Vector2(c.x - 0.5, -hw), Vector2(c.x - 0.5, hw)])
	for k in range(7, -1, -1):
		poly.append(Vector2(pts[k].x, pts[k].z))
	lm.poly_prism("Stone", poly, 0.0, eave)
	var ridge := c + Vector3(0, eave + 15.5, 0)
	for k in 7:
		var p0 := pts[k]
		var p1 := pts[k + 1]
		var mid := (p0 + p1) * 0.5
		var d := (mid - c).normalized()
		LandmarkWhGothic.window(lm, "Glass", "Stone", mid + Vector3(0, 9.2, 0), d, 1.9, 12.6, 2.2, 2, 0.3)
		LandmarkWhGothic.window(lm, "Glass", "Stone", mid + Vector3(0, 2.6, 0), d, 1.2, 2.4, 1.0, 1, 0.25)
		LandmarkWhGothic.parapet(lm, "Stone", p0 + Vector3(0, eave, 0), p1 + Vector3(0, eave, 0), d, 1.4, 1.0)
		var e0 := p0 + (p0 - c).normalized() * 0.5 + Vector3(0, eave, 0)
		var e1 := p1 + (p1 - c).normalized() * 0.5 + Vector3(0, eave, 0)
		var fn := (d * 15.5 + Vector3.UP * hw).normalized()
		lm.tri("Lead", e0, e1, ridge, fn, fn, fn, Vector2.ZERO, Vector2(e0.distance_to(e1), 0), Vector2(0, -16.0))
		lm.gable("Stone", mid + d * 0.4 + Vector3(0, eave - 0.6, 0), 2.6, 0.8, 3.6,
			Basis(Vector3.UP, atan2(d.x, d.z)), 0.0, "Stone")
	for k in range(1, 7):
		var d := (pts[k] - c).normalized()
		LandmarkWhGothic.buttress(lm, "Stone", pts[k], d, 1.3, 2.0, eave, 3)
		LandmarkWhGothic.pinnacle(lm, "Stone", pts[k] + d * 0.7 + Vector3(0, eave, 0), 0.5, 2.0, 4.0)
	# The lead angel on the chevet, at the east end of the ridge.
	lm.box("Lead", ridge + Vector3(-0.3, 0.6, 0), Vector3(1.0, 1.2, 1.0))
	LandmarkKits.statue_figure(lm, "Lead", ridge + Vector3(-0.3, 1.2, 0), 3.0, true)

## Lassus's openwork lead flèche (1853), 33 m from the ridge to the
## cross: an octagonal base with eight gabled lucarnes and pinnacles,
## an open arcaded lantern stage, a crowned gallery and the crocketed
## needle with its gilded ball and cross.
static func _fleche(lm: LandmarkMesh, sb: Vector3) -> void:
	lm.lathe("Lead", sb, PackedVector2Array([Vector2(3.1, 0), Vector2(3.1, 6.5), Vector2(3.3, 7.0),
		Vector2(3.3, 7.5)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var bs := Basis(Vector3.UP, atan2(d.x, d.z))
		lm.gable("Lead", sb + d * 2.75 + Vector3(0, 5.5, 0), 1.9, 0.8, 3.6, bs, 0.0, "Lead")
		LandmarkWhKit.lancet(lm, "Glass", sb + d * 3.0 + Vector3(0, 1.4, 0), d, 1.1, 3.2, 0.9)
		var pd := Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0))
		LandmarkWhGothic.pinnacle(lm, "Lead", sb + pd * 3.35 + Vector3(0, 6.0, 0), 0.28, 1.8, 3.4)
	# Open lantern: eight posts carrying pointed arches round a slim core.
	var lb := sb + Vector3(0, 7.5, 0)
	lm.frustum("Lead", lb, 1.0, 0.9, 6.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Lead", lb + d * 2.45, lb + d * 2.3 + Vector3(0, 5.6, 0), 0.3, 0.3)
		var a2 := TAU * (float(k) + 1.5) / 8.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		var mid := (d + d2).normalized()
		LandmarkWhGothic._run(lm, "Lead", LandmarkWhGothic._arch_pts(lb + mid * 2.2, LandmarkWhKit.along(mid),
			0.85, 4.0, 1.2, 2), mid, 0.2, 0.25)
	lm.frustum("Lead", lb + Vector3(0, 5.6, 0), 2.6, 2.7, 0.6, 8, PI / 8.0)
	LandmarkWhKit.crenel_ring(lm, "Lead", lb + Vector3(0, 6.2, 0), 2.45, 16, 0.4, 0.7, 0.2)
	# The needle, crocketed up its eight arrises.
	var nb := lb + Vector3(0, 6.2, 0)
	lm.lathe("Lead", nb, PackedVector2Array([Vector2(2.2, 0), Vector2(1.5, 5.0), Vector2(0.9, 10.0),
		Vector2(0.4, 15.0), Vector2(0.0, 19.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in 6:
			var t := (float(j) + 0.7) / 7.0
			var rr := LandmarkMesh.profile_at(PackedVector2Array([Vector2(0, 2.2), Vector2(5, 1.5), Vector2(10, 0.9),
				Vector2(15, 0.4), Vector2(19, 0.0)]), 19.0 * t)
			lm.box("Lead", nb + d * (rr * 1.08 + 0.1) + Vector3(0, 19.0 * t, 0), Vector3(0.22, 0.3, 0.22),
				Basis(Vector3.UP, -a), 0.0)
	LandmarkWhKit.ball(lm, "Gilt", nb + Vector3(0, 18.7, 0), 0.4)
	LandmarkWestKit.cross(lm, "Gilt", nb + Vector3(0, 19.4, 0), 1.6)
