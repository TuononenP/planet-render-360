class_name LandmarkFrCities
extends RefCounted

## Landmarks of the Finnish towns Kuopio, Oulu and Vaasa in true metres,
## in the frame of the real plan (+X east, +Z south, turned onto the map
## by yaw_deg): Puijo Tower, Kuopio Cathedral, Oulu Cathedral and the
## Vaasa Church. Plans follow the OpenStreetMap footprints.

## Puijo Tower (Puijon torni), Kuopio, Seppo Ruotsalainen, 1963 (on the
## pattern of Stuttgart's television tower): the 75 m concrete tower on
## the Puijo hill, its top 306 m above sea level. The head carries the
## revolving restaurant (a 16 m steel gear ring turning once or twice an
## hour), the cafe floor below it and the observation terrace on the roof
## under the mast. y = 0 is the base platform.
const PUIJO_TOP := 75.0

static func puijo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C9C6BE", 4.0))
	lm.use("Head", LandmarkMaterials.paint("#E6E3DA", 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#26323A"))
	lm.use("Mast", LandmarkMaterials.paint("#C4C7C8", 0.5, 0.5))
	lm.use("Lit", LandmarkMaterials.lit("#FF9B3D", 0.8))
	# Base: the stepped plinth with the entrance hall round the foot.
	lm.frustum("Concrete", Vector3.ZERO, 6.3, 6.0, 5.5, 24, 0.3)
	lm.frustum("Head", Vector3(0, 5.5, 0), 6.5, 6.5, 0.5, 24, 0.3)
	LandmarkFrParts.ring_openings(lm, "Head", "Glass", Vector3.ZERO, 6.15, 6, 2.0, 2.8, LandmarkFrParts.HEAD_FLAT,
		0.3, 0.14)
	lm.lathe("Concrete", Vector3(0, 6.0, 0), PackedVector2Array([Vector2(3.7, 0), Vector2(3.5, 10.0),
		Vector2(3.3, 21.0), Vector2(3.1, 43.0)]), 32)
	# Stairwell windows in a column up the shaft.
	for k in 17:
		var y := 8.0 + 2.5 * float(k)
		var r := 3.7 - 0.6 * (y - 6.0) / 43.0
		LandmarkFrParts.opening(lm, "", "Glass", Vector3(r + 0.02, y, 0), Vector3.RIGHT, 0.3, 1.2)
	# Head: tapered underside on brackets, the cafe and restaurant window
	# bands with mullions and floor slabs, the terrace parapet and roof.
	lm.lathe("Head", Vector3(0, 49.0, 0), PackedVector2Array([Vector2(3.1, 0), Vector2(4.4, 1.2),
		Vector2(7.0, 3.4), Vector2(8.3, 5.4), Vector2(8.6, 7.4)]), 40)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Head", d * 3.2 + Vector3(0, 47.5, 0), d * 8.0 + Vector3(0, 54.6, 0), 0.25, 0.4, d.cross(Vector3.UP))
	lm.frustum("Glass", Vector3(0, 56.4, 0), 8.6, 8.6, 4.2, 40)
	lm.frustum("Head", Vector3(0, 58.3, 0), 8.75, 8.75, 0.4, 40)
	for k in 40:
		var a2 := TAU * float(k) / 40.0
		lm.box("Head", Vector3(cos(a2) * 8.62, 58.5, sin(a2) * 8.62), Vector3(0.12, 4.2, 0.12), Basis(Vector3.UP, -a2))
	lm.lathe("Head", Vector3(0, 60.6, 0), PackedVector2Array([Vector2(8.9, 0), Vector2(8.9, 1.1),
		Vector2(8.6, 1.2), Vector2(8.6, 0.3)]), 40)
	lm.frustum("Head", Vector3(0, 60.6, 0), 8.6, 8.6, 0.35, 40)
	LandmarkFrParts.ring_railing(lm, "Mast", Vector3(0, 61.8, 0), 8.75, 0.5, 40)
	# Roof-top observation room and the mast with its platforms.
	lm.frustum("Glass", Vector3(0, 60.95, 0), 3.6, 3.6, 2.6, 24)
	lm.lathe("Head", Vector3(0, 63.55, 0), PackedVector2Array([Vector2(4.0, 0), Vector2(4.0, 0.4),
		Vector2(2.4, 0.85)]), 24)
	for k in 12:
		var a3 := TAU * float(k) / 12.0
		lm.box("Head", Vector3(cos(a3) * 3.62, 62.25, sin(a3) * 3.62), Vector3(0.14, 2.6, 0.14), Basis(Vector3.UP, -a3))
	lm.lathe("Mast", Vector3(0, 64.4, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(1.0, 4.0),
		Vector2(0.6, 7.5), Vector2(0.25, 10.6)]), 16)
	lm.frustum("Lit", Vector3(0, 66.4, 0), 1.2, 1.0, 4.0, 16)
	lm.frustum("Mast", Vector3(0, 70.5, 0), 1.3, 1.3, 0.2, 16)
	for k in 4:
		var a4 := TAU * float(k) / 4.0 + PI / 4.0
		var d4 := Vector3(cos(a4), 0, sin(a4))
		lm.beam("Mast", d4 * 0.6 + Vector3(0, 71.0, 0), d4 * 2.2 + Vector3(0, 71.0, 0), 0.08, 0.08)
		lm.beam("Mast", d4 * 2.2 + Vector3(0, 70.2, 0), d4 * 2.2 + Vector3(0, 72.6, 0), 0.06, 0.06)
	lm.commit(model)

## Kuopio Cathedral (Kuopion tuomiokirkko), Pehr Granstedt, 1815: the
## Neoclassical equal-armed cross church of stone (floor area 1,091 m2,
## about 1,500 seats) in cream stucco with white pilasters and cornices,
## round-arched windows, pedimented Tuscan porches on the transept ends,
## and the square bell tower (35.5 m to the roof) at the east end with its
## clock stage, octagonal lantern and green cupola; the altar is at the
## west end (+Z in this frame), the tower east (-Z).
const KUOPIO_TOP := 35.5

static func kuopio_cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E1D6B0", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F1ECDF", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4B5054", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#5E8F7C"))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var eave := 11.0
	var rh := LandmarkFrParts.HEAD_ROUND
	LandmarkFrKit.rect(lm, "Trim", -7.9, 9.1, -24.5, 30.8, 0.0, 1.0)
	LandmarkFrKit.rect(lm, "Trim", -27.2, 28.3, -5.2, 11.9, 0.0, 1.0)
	LandmarkFrKit.rect(lm, "Wall", -7.6, 8.8, -24.2, 30.5, 0.0, eave)
	LandmarkFrKit.gable(lm, "Roof", -7.6, 8.8, -24.2, 30.5, eave, 6.5, 0.6, "Wall", 0)
	LandmarkFrParts.roof_trim(lm, "Trim", -7.6, 8.8, -24.2, 30.5, eave, 6.5, 0.6, 0, 0.3)
	LandmarkFrKit.rect(lm, "Wall", -26.9, 28.0, -4.9, 11.6, 0.0, eave)
	LandmarkFrKit.gable(lm, "Roof", -26.9, 28.0, -4.9, 11.6, eave, 6.5, 0.6, "Wall", 1)
	LandmarkFrParts.roof_trim(lm, "Trim", -26.9, 28.0, -4.9, 11.6, eave, 6.5, 0.6, 1, 0.3)
	LandmarkFrParts.cornice_ring(lm, "Trim", -7.6, 8.8, -24.2, 30.5, eave - 0.7, 0.7)
	LandmarkFrParts.cornice_ring(lm, "Trim", -26.9, 28.0, -4.9, 11.6, eave - 0.7, 0.7)
	# Corner pilasters of every arm.
	LandmarkFrParts.corner_strips(lm, "Trim", -7.6, 8.8, -24.2, 30.5, 1.0, eave - 0.7, 0.9, 0.12)
	LandmarkFrParts.corner_strips(lm, "Trim", -26.9, 28.0, -4.9, 11.6, 1.0, eave - 0.7, 0.9, 0.12)
	# Porches of the transept ends: Tuscan columns, entablature, pediment.
	for sx: float in [-1.0, 1.0]:
		var px: float = sx * 29.4
		LandmarkFrKit.rect(lm, "Trim", px - 1.6, px + 1.6, 0.6, 7.2, 0.0, 0.6)
		for k in 4:
			LandmarkDetail.column(lm, "Trim", Vector3(px + sx * 1.0, 0.6, 1.4 + 1.65 * float(k)), 0.36, 7.6, "tuscan", 0)
		lm.box("Trim", Vector3(px, 8.5, 3.9), Vector3(3.4, 0.9, 6.6))
		LandmarkDetail.cornice(lm, "Trim", Vector3(px + sx * 1.7, 8.95, 0.4), Vector3(px + sx * 1.7, 8.95, 7.4),
			Vector3(sx, 0, 0), 0.4, true)
		LandmarkFrKit.gable(lm, "Trim", px - 1.7, px + 1.7, 0.6, 7.2, 9.35, 1.5, 0.2, "Trim", 1)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(sx * 26.9, 0.0, 3.35), Vector3(sx, 0, 0), 2.0, 4.0, rh,
			0.3, 0.15)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(sx * 26.9, 6.2, 3.35), Vector3(sx, 0, 0), 1.2, 2.0, rh,
			0.2, 0.1)
		lm.disc("Trim", Vector3(sx * 26.95, 13.6, 3.35), Vector3(sx, 0, 0), 0.9, 16)
		lm.disc("Glass", Vector3(sx * 27.0, 13.6, 3.35), Vector3(sx, 0, 0), 0.65, 16)
	# Round-arched windows in two tiers along the nave and transept fronts.
	for sx2: float in [-1.0, 1.0]:
		var wx: float = 8.8 if sx2 > 0.0 else -7.6
		for z: float in [14.5, 20.5, 26.5, -9.5, -15.5, -21.0]:
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 2.6, z), Vector3(sx2, 0, 0), 1.6, 4.4, rh,
				0.22, 0.12, 1)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 7.8, z), Vector3(sx2, 0, 0), 1.2, 1.8, rh,
				0.18, 0.1)
	for k in 3:
		for side in [[-4.9, -1.0], [11.6, 1.0]]:
			var n := Vector3(0, 0, side[1])
			for x0: float in [-20.0, 9.5]:
				LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x0 + 5.0 * float(k), 2.6, side[0]), n, 1.6, 4.4, rh,
					0.22, 0.12, 1)
				LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x0 + 5.0 * float(k), 7.8, side[0]), n, 1.2, 1.8,
					rh, 0.18, 0.1)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-3.5 + 3.5 * float(k), 2.6, 30.5), Vector3.BACK, 1.4,
			4.4, rh, 0.22, 0.12, 1)
	lm.disc("Trim", Vector3(0.6, 13.6, 30.56), Vector3.BACK, 0.9, 16)
	lm.disc("Glass", Vector3(0.6, 13.6, 30.6), Vector3.BACK, 0.65, 16)
	# Bell tower: stucco shaft with pilasters and cornice, the clock stage
	# with louvred openings, the lantern, green cupola, ball and cross.
	var tx := 0.45
	var tz := -27.35
	LandmarkFrKit.rect(lm, "Wall", tx - 4.65, tx + 4.65, -30.5, -24.2, 0.0, 22.0)
	LandmarkFrKit.rect(lm, "Trim", tx - 4.95, tx + 4.95, -30.8, -24.2, 0.0, 1.0)
	LandmarkFrParts.corner_strips(lm, "Trim", tx - 4.65, tx + 4.65, -30.5, -24.2, 1.0, 21.6, 0.8, 0.12)
	LandmarkFrParts.cornice_ring(lm, "Trim", tx - 4.65, tx + 4.65, -30.5, -24.2, 21.0, 0.7)
	LandmarkFrKit.rect(lm, "Trim", tx - 5.0, tx + 5.0, -30.9, -23.9, 21.6, 22.6)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(tx, 0.0, -30.5), Vector3.FORWARD, 2.2, 4.4, rh, 0.35, 0.2)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(tx, 9.0, -30.5), Vector3.FORWARD, 1.4, 3.0, rh, 0.22, 0.12, 1)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(tx, 15.0, -30.5), Vector3.FORWARD, 1.2, 2.4, rh, 0.2, 0.12)
	for sx3: float in [-1.0, 1.0]:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(tx + sx3 * 4.65, 15.0, -27.35), Vector3(sx3, 0, 0), 1.2,
			2.4, rh, 0.2, 0.12)
	LandmarkFrKit.rect(lm, "Wall", tx - 3.1, tx + 3.1, tz - 3.1, tz + 3.1, 22.6, 29.4)
	LandmarkFrParts.corner_strips(lm, "Trim", tx - 3.1, tx + 3.1, tz - 3.1, tz + 3.1, 22.6, 29.0, 0.55, 0.1)
	LandmarkFrKit.clocks(lm, "Gilt", "Trim", tx, tz, 3.1, 27.2, 0.9)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rb * Vector3(0, 0, 1)
		LandmarkFrParts.opening(lm, "Trim", "Roof", Vector3(tx, 23.0, tz) + fn * 3.1, fn, 1.2, 2.4, rh, 0.18, 0.1)
		LandmarkFrParts.louvre(lm, "Roof", Vector3(tx, 23.0, tz) + fn * 3.12, fn, 1.1, 1.8, 5)
	LandmarkFrKit.rect(lm, "Trim", tx - 3.5, tx + 3.5, tz - 3.5, tz + 3.5, 29.0, 29.8)
	lm.frustum("Trim", Vector3(tx, 29.8, tz), 2.4, 2.2, 2.6, 8, PI / 8.0)
	LandmarkFrParts.ring_openings(lm, "Wall", "Glass", Vector3(tx, 30.3, tz), 2.15, 8, 0.6, 1.5, rh, PI / 8.0, 0.1)
	lm.lathe("Copper", Vector3(tx, 32.4, tz), PackedVector2Array([Vector2(2.6, 0), Vector2(2.5, 0.3), Vector2(2.2, 0.8),
		Vector2(1.3, 1.5), Vector2(0.15, 2.0)]), 8, 1.0, 1.0, PI / 8.0)
	lm.lathe("Gilt", Vector3(tx, 34.3, tz), LandmarkFrKit.ball(0.3), 10)
	LandmarkFrKit.cross(lm, "Gilt", Vector3(tx, 34.7, tz), 0.8)
	lm.commit(model)

## Oulu Cathedral (Oulun tuomiokirkko), Carl Ludvig Engel, 1832: the 1777
## church burnt in 1822 and rebuilt Neoclassical on its old stone walls, a
## Greek cross in cream stucco with white pilasters and cornices, the
## pedimented portico of Tuscan columns on the east, the central drum and
## green copper dome with its lantern, and the square bell tower at the
## west end (its ridge raised in 1845), 56.5 m from the street to the top
## of the cross. Tower at the west (-X) end of this frame.
const OULU_TOP := 56.5

static func oulu_cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E6DFC8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F3EFE3", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4A5155", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#5F9180"))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var eave := 12.0
	var rh := LandmarkFrParts.HEAD_ROUND
	# Greek cross: central square with four arms and the lower side annex.
	LandmarkFrKit.rect(lm, "Wall", -4.1, 14.3, -10.3, 8.9, 0.0, eave + 1.0)
	var arms := [[-21.8, -4.1, -10.3, 8.9, 1], [14.3, 32.0, -10.3, 8.9, 1], [-4.1, 14.5, -21.0, -10.3, 0],
		[-4.1, 14.3, 8.9, 20.9, 0]]
	for a in arms:
		LandmarkFrKit.rect(lm, "Wall", a[0], a[1], a[2], a[3], 0.0, eave)
		LandmarkFrKit.rect(lm, "Trim", float(a[0]) - 0.3, float(a[1]) + 0.3, float(a[2]) - 0.3, float(a[3]) + 0.3,
			0.0, 0.9)
		LandmarkFrKit.gable(lm, "Roof", a[0], a[1], a[2], a[3], eave, 5.0, 0.6, "Wall", a[4])
		LandmarkFrParts.roof_trim(lm, "Trim", a[0], a[1], a[2], a[3], eave, 5.0, 0.6, a[4], 0.3)
		LandmarkFrParts.cornice_ring(lm, "Trim", a[0], a[1], a[2], a[3], eave - 0.7, 0.7)
		LandmarkFrParts.corner_strips(lm, "Trim", a[0], a[1], a[2], a[3], 0.9, eave - 0.7, 0.9, 0.12)
	LandmarkFrKit.rect(lm, "Wall", 14.5, 23.1, -17.8, -10.3, 0.0, 8.0)
	LandmarkFrKit.gable(lm, "Roof", 14.5, 23.1, -17.8, -10.3, 8.0, 3.0, 0.4, "Wall", 1)
	LandmarkFrKit.rect(lm, "Trim", -4.4, 14.6, -10.6, 9.2, eave + 0.6, eave + 1.4)
	# East portico: four Tuscan columns, entablature and pediment.
	LandmarkFrKit.rect(lm, "Trim", 32.0, 34.0, -7.4, 7.4, 0.0, 0.5)
	for k in 4:
		LandmarkDetail.column(lm, "Trim", Vector3(33.0, 0.5, -5.4 + 3.6 * float(k)), 0.5, 9.5, "tuscan", 0)
	lm.box("Trim", Vector3(32.6, 10.5, 0), Vector3(2.4, 1.0, 13.6))
	LandmarkDetail.cornice(lm, "Trim", Vector3(33.8, 11.0, -6.8), Vector3(33.8, 11.0, 6.8), Vector3.RIGHT, 0.5, true)
	lm.gable("Trim", Vector3(32.6, 11.5, 0), 13.6, 2.4, 2.6, Basis(Vector3.UP, PI * 0.5), 0.2, "Trim")
	# Windows in the arm walls: tall round-arched, with a lunette over each
	# arm's gable end; doors in the north and south arms.
	for k in 3:
		for side in [[20.9, 1.0], [-21.0, -1.0]]:
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(1.0 + 4.1 * float(k), 3.6, side[0]),
				Vector3(0, 0, side[1]), 1.6, 5.4, rh, 0.24, 0.12, 1)
		for side2 in [[8.9, 1.0], [-10.3, -1.0]]:
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-17.0 + 4.6 * float(k), 3.6, side2[0]),
				Vector3(0, 0, side2[1]), 1.6, 5.4, rh, 0.24, 0.12, 1)
			if k < 2:
				LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(19.5 + 6.0 * float(k), 3.6, side2[0]),
					Vector3(0, 0, side2[1]), 1.6, 5.4, rh, 0.24, 0.12, 1)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-21.8, 3.6, -5.0 + 5.0 * float(k)), Vector3.LEFT, 1.6,
			5.4, rh, 0.24, 0.12, 1)
	for side3 in [[20.9, 1.0], [-21.0, -1.0]]:
		lm.disc("Trim", Vector3(5.1, 14.4, float(side3[0]) + float(side3[1]) * 0.05), Vector3(0, 0, side3[1]), 1.2, 16)
		lm.disc("Glass", Vector3(5.1, 14.4, float(side3[0]) + float(side3[1]) * 0.09), Vector3(0, 0, side3[1]), 0.9, 16)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(32.0, 0.0, 0.0), Vector3.RIGHT, 2.4, 4.8, rh, 0.35, 0.2)
	# Central drum with windows between pilasters, the ribbed green dome,
	# the lantern and cross.
	var c := Vector3(5.1, eave + 1.4, -0.7)
	lm.frustum("Wall", c, 8.6, 8.6, 4.4, 40)
	for k in 8:
		var a2 := TAU * float(k) / 8.0 + PI / 8.0
		var dn := Vector3(cos(a2), 0, sin(a2))
		LandmarkFrParts.opening(lm, "Trim", "Glass", c + dn * 8.6 + Vector3(0, 1.0, 0), dn, 1.4, 2.6, rh, 0.2, 0.12)
		var ap := a2 + PI / 8.0
		lm.box("Trim", c + Vector3(cos(ap) * 8.65, 2.2, sin(ap) * 8.65), Vector3(0.7, 4.4, 0.2), Basis(Vector3.UP, -ap + PI * 0.5))
	lm.frustum("Trim", c + Vector3(0, 4.4, 0), 9.2, 9.0, 0.8, 40)
	lm.lathe("Copper", c + Vector3(0, 5.2, 0), LandmarkFrKit.dome(8.9, 7.4), 40)
	for k in 16:
		var a3 := TAU * float(k) / 16.0
		var prev := Vector3.ZERO
		for j in 9:
			var t := PI * 0.5 * float(j) / 8.0 * 0.92
			var p := c + Vector3(0, 5.2, 0) + Vector3(cos(a3) * cos(t) * 8.98, sin(t) * 7.45, sin(a3) * cos(t) * 8.98)
			if j > 0:
				lm.beam("Copper", prev, p, 0.18, 0.14)
			prev = p
	lm.frustum("Trim", c + Vector3(0, 12.4, 0), 2.3, 2.3, 0.3, 16)
	lm.frustum("Trim", c + Vector3(0, 12.6, 0), 1.9, 1.9, 2.4, 16)
	for k in 8:
		var a4 := TAU * float(k) / 8.0
		var ln := Vector3(cos(a4), 0, sin(a4))
		LandmarkFrParts.opening(lm, "", "Glass", c + ln * 1.92 + Vector3(0, 13.0, 0), ln, 0.5, 1.4, rh)
	lm.lathe("Copper", c + Vector3(0, 15.0, 0), LandmarkFrKit.dome(2.2, 2.4), 16)
	lm.lathe("Gilt", c + Vector3(0, 17.2, 0), LandmarkFrKit.ball(0.25), 8)
	LandmarkFrKit.cross(lm, "Gilt", c + Vector3(0, 17.4, 0), 1.8)
	# West bell tower: shaft with pilasters and windows, cornice, clock
	# stage, belfry with louvred openings, lantern and copper spire.
	var tx := -27.0
	LandmarkFrKit.rect(lm, "Wall", -32.2, -21.8, -5.2, 5.2, 0.0, 27.0)
	LandmarkFrKit.rect(lm, "Trim", -32.5, -21.5, -5.5, 5.5, 0.0, 0.9)
	LandmarkFrParts.corner_strips(lm, "Trim", -32.2, -21.8, -5.2, 5.2, 0.9, 26.4, 1.0, 0.14)
	LandmarkFrParts.band(lm, "Trim", -32.2, -21.8, -5.2, 5.2, 13.0, 0.5, 0.12)
	LandmarkFrParts.cornice_ring(lm, "Trim", -32.2, -21.8, -5.2, 5.2, 26.0, 0.8)
	LandmarkFrKit.rect(lm, "Trim", -32.6, -21.4, -5.6, 5.6, 26.6, 27.6)
	for sz: float in [-1.0, 1.0]:
		for k in 2:
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(tx - 2.0 + 4.0 * float(k), 8.6, sz * 5.2),
				Vector3(0, 0, sz), 1.4, 4.0, rh, 0.22, 0.12, 1)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(tx - 2.0 + 4.0 * float(k), 17.0, sz * 5.2),
				Vector3(0, 0, sz), 1.2, 3.0, rh, 0.2, 0.12)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-32.2, 0.0, 0), Vector3.LEFT, 2.6, 5.4, rh, 0.4, 0.22)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-32.2, 9.0, 0), Vector3.LEFT, 1.6, 4.2, rh, 0.22, 0.12, 1)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-32.2, 17.0, 0), Vector3.LEFT, 1.4, 3.2, rh, 0.2, 0.12)
	LandmarkFrKit.rect(lm, "Wall", tx - 3.8, tx + 3.8, -3.8, 3.8, 27.6, 36.0)
	LandmarkFrParts.corner_strips(lm, "Trim", tx - 3.8, tx + 3.8, -3.8, 3.8, 27.6, 35.6, 0.6, 0.1)
	LandmarkFrKit.clocks(lm, "Gilt", "Trim", tx, 0.0, 3.8, 33.6, 1.3)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rb * Vector3(0, 0, 1)
		LandmarkFrParts.opening(lm, "Trim", "Roof", Vector3(tx, 28.2, 0) + fn * 3.8, fn, 1.6, 3.4, rh, 0.2, 0.1)
		LandmarkFrParts.louvre(lm, "Roof", Vector3(tx, 28.2, 0) + fn * 3.82, fn, 1.5, 2.6, 7)
	LandmarkFrKit.rect(lm, "Trim", tx - 4.2, tx + 4.2, -4.2, 4.2, 35.6, 36.6)
	lm.frustum("Wall", Vector3(tx, 36.6, 0), 3.0, 2.8, 3.6, 8, PI / 8.0)
	LandmarkFrParts.ring_openings(lm, "Trim", "Glass", Vector3(tx, 37.1, 0), 2.85, 8, 0.8, 2.2, rh, PI / 8.0, 0.12)
	lm.frustum("Trim", Vector3(tx, 39.9, 0), 3.3, 3.3, 0.3, 8, PI / 8.0)
	lm.lathe("Copper", Vector3(tx, 40.2, 0), PackedVector2Array([Vector2(3.4, 0), Vector2(3.0, 1.0),
		Vector2(1.8, 5.0), Vector2(0.9, 9.0), Vector2(0.12, 13.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gilt", Vector3(tx, 53.2, 0), LandmarkFrKit.ball(0.45), 10)
	LandmarkFrKit.cross(lm, "Gilt", Vector3(tx, 54.0, 0), 2.5)
	lm.commit(model)

## Vaasa Church, the Holy Trinity Church (Vaasan kirkko), Carl Axel
## Setterberg, planned 1857-58, first service 1862, consecrated 1869: the
## long three-aisled red-brick church in English Neo-Gothic (about 900
## seats) with buttressed walls, pointed windows in stone dressings and
## stone string courses under a steep slate roof, the gabled transept
## porches, the polygonal apse at the east and the west tower with its
## corner pinnacles and tall slate spire. Tower at the west (-X) end,
## apse east (+X).
const VAASA_TOP := 49.3

static func vaasa(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A0503A", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#C9C2B2", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4A5054", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var ph := LandmarkFrParts.HEAD_POINTED
	# Nave and aisles, transept porches and the east chapels.
	LandmarkFrKit.rect(lm, "Stone", -19.4, 23.6, -13.9, 13.2, 0.0, 1.0)
	LandmarkFrKit.house(lm, "Brick", "Roof", -19.1, 23.4, -11.1, 11.0, 0.0, 11.0, 8.0, 0.6, 1)
	LandmarkFrParts.roof_trim(lm, "Stone", -19.1, 23.4, -11.1, 11.0, 11.0, 8.0, 0.6, 1, 0.25)
	LandmarkFrKit.house(lm, "Brick", "Roof", -1.4, 5.2, -14.8, 14.8, 0.0, 10.0, 4.2, 0.4, 0)
	LandmarkFrParts.roof_trim(lm, "Stone", -1.4, 5.2, -14.8, 14.8, 10.0, 4.2, 0.4, 0, 0.25)
	LandmarkFrKit.house(lm, "Brick", "Roof", 13.1, 23.4, -13.5, 12.8, 0.0, 8.0, 3.0, 0.3, 0)
	LandmarkFrParts.band(lm, "Stone", -19.1, 23.4, -11.1, 11.0, 10.6, 0.5, 0.15)
	LandmarkFrParts.band(lm, "Stone", -19.1, 23.4, -11.1, 11.0, 3.0, 0.3, 0.1)
	# Transept porch gables: a pointed door, a window and a cross apex.
	for sz: float in [-1.0, 1.0]:
		var gz := sz * 14.8
		var n := Vector3(0, 0, sz)
		LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(1.9, 0.0, gz), n, 2.2, 4.6, ph, 0.4, 0.22)
		LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(1.9, 6.0, gz), n, 1.6, 4.0, ph, 0.3, 0.15, 1)
		lm.box("Stone", Vector3(1.9, 14.8, gz), Vector3(0.25, 1.4, 0.25))
		lm.box("Stone", Vector3(1.9, 14.9, gz), Vector3(0.9, 0.25, 0.25))
		for s2: float in [-1.0, 1.0]:
			LandmarkFrParts.buttress(lm, "Brick", Vector3(1.9 + s2 * 3.3, 0, gz), n, 0.8, 1.0, 9.0, 2)
	# Polygonal apse with buttresses at its angles and a conical roof.
	lm.frustum("Brick", Vector3(21.5, 0, 0), 6.4, 6.2, 11.0, 6)
	lm.lathe("Roof", Vector3(21.5, 11.0, 0), PackedVector2Array([Vector2(7.2, 0), Vector2(0.0, 8.0)]), 6,
		1.0, 1.0, 0.0, false)
	for k in 6:
		var a := TAU * float(k) / 6.0
		var on := Vector3(cos(a), 0, sin(a))
		if on.x > -0.6:
			LandmarkFrParts.buttress(lm, "Brick", Vector3(21.5, 0, 0) + on * 6.3, on, 0.8, 1.1, 10.0, 2)
			var am := a + PI / 6.0
			var mn := Vector3(cos(am), 0, sin(am))
			if mn.x > -0.3:
				LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(21.5, 2.8, 0) + mn * 6.3 * cos(PI / 6.0), mn,
					1.3, 5.6, ph, 0.25, 0.12, 1)
	# Buttresses and pointed windows along the long fronts, clerestory.
	for sz2: float in [-1.0, 1.0]:
		var n2 := Vector3(0, 0, sz2)
		for k in 7:
			var x := -15.0 + 5.2 * float(k)
			if absf(x - 1.9) < 4.6:
				continue
			LandmarkFrParts.buttress(lm, "Brick", Vector3(x, 0, sz2 * 11.05), n2, 0.9, 1.2, 10.4, 2)
			lm.spire("Stone", Vector3(x, 10.4, sz2 * 11.05) + n2 * 0.4, 0.3, 1.6)
			if x + 2.6 < 13.1:
				LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(x + 2.6, 2.6, sz2 * 11.05), n2, 1.6, 6.2, ph,
					0.25, 0.12, 1)
	# West tower: brick shaft with stone string courses and angle
	# buttresses, the portal, lancets, the louvred belfry, pinnacles,
	# the octagonal slate spire with lucarnes and the gilt cross.
	var tx := -23.45
	LandmarkFrKit.rect(lm, "Brick", tx - 4.45, tx + 4.45, -4.45, 4.45, 0.0, 30.0)
	for y: float in [10.0, 20.0, 29.4]:
		LandmarkFrKit.rect(lm, "Stone", tx - 4.7, tx + 4.7, -4.7, 4.7, y, y + 0.6)
	for sx: float in [-1.0, 1.0]:
		for sz3: float in [-1.0, 1.0]:
			var cp := Vector3(tx + sx * 4.45, 0, sz3 * 4.45)
			LandmarkFrParts.buttress(lm, "Brick", cp - Vector3(0, 0, sz3 * 1.0), Vector3(sx, 0, 0), 0.9, 1.1, 24.0, 3)
			LandmarkFrParts.buttress(lm, "Brick", cp - Vector3(sx * 1.0, 0, 0), Vector3(0, 0, sz3), 0.9, 1.1, 24.0, 3)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(tx - 4.45, 0.0, 0), Vector3.LEFT, 2.4, 5.4, ph, 0.5, 0.3)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(tx - 4.45, 11.2, 0), Vector3.LEFT, 1.8, 6.4, ph, 0.3, 0.15, 1)
	for sz4: float in [-1.0, 1.0]:
		LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(tx, 13.0, sz4 * 4.45), Vector3(0, 0, sz4), 1.2, 4.0, ph,
			0.22, 0.12)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(tx, 21.6, -4.45), Vector3.FORWARD, 1.2, 4.0, ph, 0.22, 0.12)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(tx, 21.6, 4.45), Vector3.BACK, 1.2, 4.0, ph, 0.22, 0.12)
	LandmarkFrKit.rect(lm, "Brick", tx - 3.9, tx + 3.9, -3.9, 3.9, 30.0, 38.0)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rb * Vector3(0, 0, 1)
		var al: Vector3 = rb * Vector3.RIGHT
		for s3: float in [-1.0, 1.0]:
			LandmarkFrParts.opening(lm, "Stone", "Roof", Vector3(tx, 31.4, 0) + fn * 3.9 + al * s3 * 1.1, fn, 1.2, 5.0,
				ph, 0.22, 0.12)
			LandmarkFrParts.louvre(lm, "Roof", Vector3(tx, 31.4, 0) + fn * 3.92 + al * s3 * 1.1, fn, 1.1, 3.8, 7)
	LandmarkFrKit.rect(lm, "Stone", tx - 4.3, tx + 4.3, -4.3, 4.3, 37.6, 38.4)
	for sx2: float in [-1.0, 1.0]:
		for sz5: float in [-1.0, 1.0]:
			var pc := Vector3(tx + sx2 * 3.8, 38.4, sz5 * 3.8)
			lm.frustum("Stone", pc, 0.6, 0.55, 2.4, 8, PI / 8.0)
			lm.spire("Roof", pc + Vector3(0, 2.4, 0), 0.6, 3.2)
			lm.lathe("Gilt", pc + Vector3(0, 5.5, 0), LandmarkFrKit.ball(0.1), 6)
	for sx3: float in [-1.0, 1.0]:
		lm.beam("Stone", Vector3(tx - 3.8, 38.6, sx3 * 3.8), Vector3(tx + 3.8, 38.6, sx3 * 3.8), 0.5, 0.3, Vector3.UP)
		lm.beam("Stone", Vector3(tx + sx3 * 3.8, 38.6, -3.8), Vector3(tx + sx3 * 3.8, 38.6, 3.8), 0.5, 0.3, Vector3.UP)
	lm.lathe("Roof", Vector3(tx, 38.4, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(3.6, 3.0),
		Vector2(1.3, 8.4), Vector2(0.14, 10.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 4:
		var a2 := TAU * float(k) / 4.0
		var ln := Vector3(cos(a2), 0, sin(a2))
		LandmarkFrParts.dormer(lm, "Stone", "Roof", "Glass", Vector3(tx, 40.4, 0) + ln * 3.0, ln, 0.9, 1.4, 1.0)
	lm.box("Gilt", Vector3(tx, 48.5, 0), Vector3(0.14, 1.6, 0.14))
	lm.box("Gilt", Vector3(tx, 48.9, 0), Vector3(0.8, 0.14, 0.14))
	lm.commit(model)
