class_name LandmarkMaMosques
extends RefCounted

## Three mosques in true metres, built in the compass frame (+X east,
## +Z south): the Hassan II Mosque (Casablanca), the mud-brick Great
## Mosque of Djenne (Mali) and the Dome of the Rock (Jerusalem). The
## Sheikh Zayed Grand Mosque is LandmarkMaZayed.

# --- Hassan II Mosque ---

## Esplanade level: the mosque stands on its raised forecourt.
const HII_G := 1.0

## Casablanca (1993), placed from its OpenStreetMap parts: the 204 x 108 m
## prayer hall on the sea edge, its side naves to 27 m, the central nave
## to 40 m, green-tiled hipped roofs stepping up to the 60 m retractable
## roof; tall horseshoe-pointed doorways all round under a zellige
## frieze; the 25 m square minaret on the south front (210 m: shaft to
## 172 m, lantern, dome and the gilded three-ball finial); galleries
## framing the south esplanade.
static func hassan_ii(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E9E1CE", 6.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#2E6B52", 4.0))
	lm.use("Tile", LandmarkMaterials.pbr("render", "#2B7A78", 3.0))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#D8CDB6", 5.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#1F2E2D"))
	var g := HII_G
	lm.box("Plaza", Vector3(16, g * 0.5, 45), Vector3(260, g, 230))
	# Outer hall: side naves, doorways on all four fronts.
	var x0 := -86.0
	var x1 := 118.0
	var z0 := -50.0
	var z1 := 58.0
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var w := x1 - x0
	var d := z1 - z0
	lm.box("Stone", Vector3(cx, g + 13.5, cz), Vector3(w, 27, d))
	_hii_front(lm, Vector3(x0, g, z1), Vector3.RIGHT, Vector3.BACK, w, 17)
	_hii_front(lm, Vector3(x1, g, z0), Vector3.LEFT, Vector3.FORWARD, w, 17)
	_hii_front(lm, Vector3(x1, g, z1), Vector3.FORWARD, Vector3.RIGHT, d, 9)
	_hii_front(lm, Vector3(x0, g, z0), Vector3.BACK, Vector3.LEFT, d, 9)
	LandmarkMaParts.hip_roof(lm, "Roof", Vector3(cx, g + 27, cz), w + 3.0, d + 3.0, 4.0, w - 10.0, d - 10.0)
	# Central nave clerestory and the stepped roofs.
	var nx0 := -78.0
	var nx1 := 108.0
	var nz0 := -42.0
	var nz1 := 50.0
	var ncx := (nx0 + nx1) * 0.5
	var ncz := (nz0 + nz1) * 0.5
	lm.box("Stone", Vector3(ncx, g + 34, ncz), Vector3(nx1 - nx0 - 6.0, 12, nz1 - nz0 - 6.0))
	for s in [-1.0, 1.0]:
		var zf: float = ncz + s * ((nz1 - nz0) * 0.5 - 3.0)
		var o := Vector3(nx0 + 3.0 if s > 0.0 else nx1 - 3.0, g + 28, zf)
		LandmarkMaParts.arched_bays(lm, "Stone", "Glass", o, Vector3(s, 0, 0), Vector3(0, 0, s),
			nx1 - nx0 - 6.0, 11.5, 30, 2.6, 5.0, 2.6, 0.5, "Tile", 4)
	lm.box("Tile", Vector3(ncx, g + 39.4, ncz), Vector3(nx1 - nx0 - 5.0, 1.2, nz1 - nz0 - 5.0))
	LandmarkMaParts.hip_roof(lm, "Roof", Vector3(ncx, g + 40, ncz), nx1 - nx0 - 4.0, nz1 - nz0 - 4.0, 10.0,
		70.0, 52.0)
	# The 3,400 m2 retractable roof: a pyramid-hipped block to 60 m.
	var rc := Vector3(17.5, g + 50, 1.0)
	lm.box("Tile", rc + Vector3(0, 0.6, 0), Vector3(80, 1.2, 56))
	LandmarkMaParts.hip_roof(lm, "Roof", rc + Vector3(0, 1.2, 0), 80.0, 56.0, 8.8, 26.0, 2.0)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(17.5 + s * 49.0, g + 51.5, 1.0), Vector3(14, 3, 50))
	_hii_minaret(lm, Vector3(10, g, 70))
	# Galleries framing the esplanade, east and west.
	for gx in [-70.0, 102.0]:
		_hii_gallery(lm, Vector3(gx, g, 72), 86.0)
	lm.commit(model)

## One hall front `length` m from `origin` along `right`: `bays` tall
## pointed doorways with cedar-and-bronze doors, a zellige frieze and
## the green-tiled eave cornice.
static func _hii_front(lm: LandmarkMesh, origin: Vector3, right: Vector3, normal: Vector3, length: float,
		bays: int) -> void:
	var pitch := length / float(bays)
	LandmarkMaParts.arched_bays(lm, "Stone", "Glass", origin, right, normal, length, 21.0, bays,
		pitch * 0.55, 11.0, 7.5, 1.2, "Tile", 6)
	# Twin columns between the doorways.
	for i in bays + 1:
		var p := origin + right * pitch * float(i) + normal * 1.9
		for k in [-1.0, 1.0]:
			lm.frustum("Stone", p + right * k * 0.9, 0.55, 0.5, 11.0, 10)
			lm.box("Tile", p + right * k * 0.9 + Vector3(0, 11.3, 0), Vector3(1.4, 0.6, 1.4), Basis(), 0.0)
	var mid := origin + right * length * 0.5 + normal * 0.8
	var basis := Basis(right, Vector3.UP, normal)
	lm.box("Tile", mid + Vector3(0, 23.5, 0), Vector3(length, 4.6, 1.2), basis)
	lm.box("Stone", mid + Vector3(0, 21.4, 0.3), Vector3(length + 0.6, 0.6, 1.8), basis)
	LandmarkDetail.cornice(lm, "Stone", origin + Vector3(0, 25.8, 0) + normal * 1.4,
		origin + right * length + Vector3(0, 25.8, 0) + normal * 1.4, normal, 1.2, false)

## 210 m square minaret: a 25.6 m shaft to 172 m with arched window
## pairs and sebka (lozenge) relief panels, the green zellige upper
## third, a crenellated gallery, the lantern, its dome and the finial of
## three gilded balls.
static func _hii_minaret(lm: LandmarkMesh, base: Vector3) -> void:
	var sw := 25.6
	var shaft := 172.0
	lm.box("Stone", base + Vector3(0, 2, 0), Vector3(sw + 4.0, 4, sw + 4.0))
	lm.box("Stone", base + Vector3(0, shaft * 0.5, 0), Vector3(sw, shaft, sw))
	for dv in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var n: Vector3 = dv
		var r: Vector3 = Vector3.UP.cross(n)
		var face: Vector3 = base + n * sw * 0.5
		var o: Vector3 = face - r * sw * 0.5
		# Corner pilasters and string courses.
		for k in [-1.0, 1.0]:
			lm.box("Stone", face + r * k * (sw * 0.5 - 1.2) + n * 0.4 + Vector3(0, shaft * 0.5, 0),
				Vector3(2.4, shaft, 0.8), Basis(r, Vector3.UP, n))
		for y in [30.0, 62.0, 96.0, 118.0]:
			lm.box("Tile", face + n * 0.5 + Vector3(0, y, 0), Vector3(sw + 0.4, 1.4, 1.0), Basis(r, Vector3.UP, n))
		# Window pairs at three levels.
		for y in [14.0, 44.0, 76.0]:
			LandmarkMaParts.arched_bays(lm, "Stone", "Glass", o + r * 6.0 + Vector3(0, y, 0), r, n, sw - 12.0,
				12.0, 2, 3.0, 6.5, 2.4, 0.5, "Tile", 4)
		# Sebka lozenge net in the panel above each window tier.
		for y in [32.0, 64.0]:
			for c in 4:
				var a0: Vector3 = o + r * (5.0 + 3.9 * float(c)) + n * 0.5 + Vector3(0, y + 2.0, 0)
				lm.lattice_panel("Tile", a0, a0 + r * 3.9, a0 + Vector3(0, 9.0, 0), a0 + r * 3.9 + Vector3(0, 9.0, 0),
					0.35, 3, false)
		# The green zellige upper third with tall arched openings.
		lm.box("Tile", face + n * 0.3 + Vector3(0, 145, 0), Vector3(sw - 4.8, 50, 0.6), Basis(r, Vector3.UP, n))
		LandmarkMaParts.arched_bays(lm, "Stone", "Glass", o + r * 4.0 + n * 0.6 + Vector3(0, 124, 0), r, n,
			sw - 8.0, 16.0, 3, 3.0, 10.0, 2.8, 0.6, "Gold", 4)
		for c in 3:
			var a1: Vector3 = o + r * (4.0 + 5.87 * float(c)) + n * 1.0 + Vector3(0, 142, 0)
			lm.lattice_panel("Stone", a1, a1 + r * 5.87, a1 + Vector3(0, 24.0, 0),
				a1 + r * 5.87 + Vector3(0, 24.0, 0), 0.4, 5, false)
		# Crenellated parapet round the gallery.
		LandmarkMaParts.merlons(lm, "Stone", face + n * 0.6 - r * (sw * 0.5 + 0.6) + Vector3(0, shaft + 1.0, 0),
			face + n * 0.6 + r * (sw * 0.5 + 0.6) + Vector3(0, shaft + 1.0, 0), 9, 1.6, 2.6, 0.8, true)
	lm.box("Tile", base + Vector3(0, shaft + 0.5, 0), Vector3(sw + 2.4, 1.0, sw + 2.4))
	# Lantern: 15 m square, arched windows each side, its own merlons.
	var lb := base + Vector3(0, shaft, 0)
	var lw := 15.0
	lm.box("Stone", lb + Vector3(0, 9, 0), Vector3(lw, 18, lw))
	for dv in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var n: Vector3 = dv
		var r: Vector3 = Vector3.UP.cross(n)
		var o: Vector3 = lb + n * lw * 0.5 - r * lw * 0.5
		LandmarkMaParts.arched_bays(lm, "Tile", "Glass", o + Vector3(0, 2, 0), r, n, lw, 12.0, 2, 3.4, 6.0,
			2.8, 0.4, "Gold", 4)
		LandmarkMaParts.merlons(lm, "Stone", o + Vector3(0, 18, 0) + n * 0.2, o + r * lw + Vector3(0, 18, 0) + n * 0.2,
			5, 1.6, 2.2, 0.6, true)
	lm.box("Tile", lb + Vector3(0, 17.4, 0), Vector3(lw + 0.8, 1.2, lw + 0.8))
	var db := lb + Vector3(0, 18, 0)
	lm.frustum("Tile", db, 5.4, 5.4, 1.2, 16)
	LandmarkMaParts.dome(lm, "Roof", db + Vector3(0, 1.2, 0), 5.2, 4.2, 20, 0.2)
	# Jamour: a mast through three gilded balls of falling size.
	var fb := db + Vector3(0, 5.2, 0)
	lm.frustum("Gold", fb, 0.35, 0.12, 14.8, 6)
	var y := 0.8
	for k in 3:
		var br := 1.4 - 0.3 * float(k)
		LandmarkMaParts.sphere(lm, "Gold", fb + Vector3(0, y + br, 0), br, 12, 6)
		y += br * 2.0 + 0.9

## Esplanade gallery `length` m south from `start`: an arcade on both
## faces under a green-tiled hipped roof.
static func _hii_gallery(lm: LandmarkMesh, start: Vector3, length: float) -> void:
	var dw := 12.0
	var h := 14.0
	var bays := 12
	for s in [-1.0, 1.0]:
		var o := start + Vector3(s * dw * 0.5, 0, 0.0 if s > 0.0 else length)
		LandmarkMaParts.arched_bays(lm, "Stone", "", o, Vector3(0, 0, s), Vector3(s, 0, 0), length, h, bays,
			4.6, 6.0, 3.6, 0.8, "Tile", 5)
	lm.box("Stone", start + Vector3(0, h - 1.5, length * 0.5), Vector3(dw, 3.0, length))
	lm.box("Tile", start + Vector3(0, h + 0.4, length * 0.5), Vector3(dw + 1.6, 0.8, length + 1.6))
	LandmarkMaParts.hip_roof(lm, "Roof", start + Vector3(0, h + 0.8, length * 0.5), dw + 1.6, length + 1.6, 3.0,
		0.0, length - 10.0)
	lm.box("Plaza", start + Vector3(0, 0.15, length * 0.5), Vector3(dw, 0.3, length))

# --- Great Mosque of Djenne ---

## Platform top above the market square.
const DJ_G := 3.0

## Sudano-Sahelian mud-brick mosque (1907) on its 75 x 75 m, 3 m plinth:
## the 26 x 50 m prayer hall in the east half behind the qibla wall with
## its three box towers (the central one ~16 m above the plinth) crowned
## by cone pinnacles and ostrich eggs and its 18 pinnacled buttresses,
## the 20 x 46 m courtyard to the west within lower galleried walls,
## toron palm-stick scaffolding bristling from every face, roof vents
## and rain spouts, the north stair tower and six pinnacled stairways up
## the plinth.
static func djenne(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Mud", LandmarkMaterials.pbr("render", "#A6865E", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#9A8666", 4.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6B4F35", 1.5))
	lm.use("Egg", LandmarkMaterials.pbr("render", "#E6DDC8", 1.0))
	var g := DJ_G
	lm.box("Plinth", Vector3(0, g * 0.5, 0), Vector3(75, g, 75))
	lm.box("Plinth", Vector3(0, g + 0.2, 0), Vector3(76, 0.4, 76))
	# Prayer hall (x 1..27) to 11 m; courtyard walls to the west to 8 m.
	var hall_h := 11.0
	lm.box("Mud", Vector3(14, g + hall_h * 0.5, 0), Vector3(26, hall_h, 52))
	lm.box("Mud", Vector3(-26.0, g + 4.0, 0), Vector3(2, 8, 52))
	for s in [-1.0, 1.0]:
		lm.box("Mud", Vector3(-12.5, g + 4.0, s * 25.0), Vector3(27, 8, 2))
		# Galleries round the courtyard (north, south and the women's west).
		lm.box("Mud", Vector3(-12.5, g + 3.2, s * 21.5), Vector3(25, 6.4, 5))
	lm.box("Mud", Vector3(-21.5, g + 3.2, 0), Vector3(7, 6.4, 38))
	# Parapets round the hall roof and crenels of mud cones.
	for e in [[Vector3(1, 0, -26), Vector3(27, 0, -26)], [Vector3(1, 0, 26), Vector3(27, 0, 26)],
			[Vector3(1, 0, -26), Vector3(1, 0, 26)]]:
		var a: Vector3 = e[0] + Vector3(0, g + hall_h, 0)
		var b: Vector3 = e[1] + Vector3(0, g + hall_h, 0)
		lm.beam("Mud", a + Vector3(0, 0.5, 0), b + Vector3(0, 0.5, 0), 0.6, 1.0)
	# Roof vents (inverted fired bowls) over the hall.
	for i in 5:
		for j in 9:
			var p := Vector3(3.5 + 4.6 * float(i), g + hall_h, -20.0 + 5.0 * float(j))
			lm.frustum("Mud", p, 0.55, 0.5, 0.3, 8)
			LandmarkMaParts.dome(lm, "Egg", p + Vector3(0, 0.3, 0), 0.5, 0.35, 8)
	# Qibla (east) wall: 18 buttresses, then the three towers.
	for seg in [[-25.4, -19.6, 4], [-12.4, -3.8, 5], [3.8, 12.4, 5], [19.6, 25.4, 4]]:
		for i in int(seg[2]):
			var z := lerpf(float(seg[0]), float(seg[1]), float(i) / float(int(seg[2]) - 1))
			_dj_buttress(lm, Vector3(27.5, g, z), hall_h + 2.6, Vector3.RIGHT)
	for z in [-16.0, 0.0, 16.0]:
		var top := 19.6 if is_zero_approx(z) else 17.4
		_dj_tower(lm, Vector3(29.0, g, z), top, 3.0 if is_zero_approx(z) else 2.6)
	# Corner buttresses, then the north and south walls' pilasters.
	for c in [Vector2(27.6, -25.6), Vector2(27.6, 25.6), Vector2(-26.6, -25.6), Vector2(-26.6, 25.6)]:
		var hc := hall_h + 3.2 if c.x > 0.0 else 9.6
		lm.spire("Mud", Vector3(c.x, g, c.y), 1.9, hc, 1.2)
		lm.spire("Mud", Vector3(c.x, g + hc, c.y), 1.2, 1.8, 0.0)
		_dj_toron(lm, Vector3(c.x, g, c.y), Vector3(signf(c.x), 0, 0), hc, 1.6)
		_dj_toron(lm, Vector3(c.x, g, c.y), Vector3(0, 0, signf(c.y)), hc, 1.6)
	for s in [-1.0, 1.0]:
		for i in 9:
			var x := 3.0 + 2.8 * float(i)
			_dj_buttress(lm, Vector3(x, g, s * 26.6), hall_h + 2.0, Vector3(0, 0, s))
		for i in 7:
			var x := -24.0 + 3.6 * float(i)
			_dj_buttress(lm, Vector3(x, g, s * 26.4), 9.0, Vector3(0, 0, s))
		# Rain spouts off the hall roof.
		for i in 6:
			lm.beam("Plinth", Vector3(4.0 + 4.0 * float(i), g + hall_h - 0.3, s * 26.0),
				Vector3(4.0 + 4.0 * float(i), g + hall_h - 0.6, s * 27.8), 0.35, 0.3)
	for i in 9:
		var z := -21.0 + 5.25 * float(i)
		_dj_buttress(lm, Vector3(-27.4, g, z), 9.0, Vector3.LEFT)
	# Toron rows along the qibla wall between the buttresses.
	for y in [4.0, 7.5]:
		for i in 26:
			var z := -25.0 + 50.0 * float(i) / 25.0
			lm.box("Wood", Vector3(27.6, g + y, z), Vector3(1.2, 0.16, 0.16), Basis(), 0.0)
	# North entrance porch and the square stair tower beside it.
	lm.box("Mud", Vector3(10, g + 5.5, -28.5), Vector3(8, 11, 4))
	lm.box("Wood", Vector3(10, g + 2.6, -30.55), Vector3(2.4, 4.6, 0.1), Basis(), 0.0)
	lm.spire("Mud", Vector3(-4, g, -28.0), 2.6, 13.5, 1.9)
	lm.spire("Mud", Vector3(-4, g + 13.5, -28.0), 1.9, 2.0, 0.0)
	_dj_toron(lm, Vector3(-4, g, -28.0), Vector3.FORWARD, 13.5, 2.4)
	# Pinnacled stairways up the plinth: two each north and south, one
	# east and west.
	for st in [[Vector3(10, 0, -37.5), Vector3.FORWARD], [Vector3(-14, 0, -37.5), Vector3.FORWARD],
			[Vector3(10, 0, 37.5), Vector3.BACK], [Vector3(-14, 0, 37.5), Vector3.BACK],
			[Vector3(37.5, 0, 0), Vector3.RIGHT], [Vector3(-37.5, 0, 0), Vector3.LEFT]]:
		_dj_stair(lm, st[0], st[1])
	lm.commit(model)

## Tapering pilaster-buttress `h` tall on face `out`, a cone pinnacle
## over the parapet and a toron stick pair.
static func _dj_buttress(lm: LandmarkMesh, base: Vector3, h: float, out: Vector3) -> void:
	lm.spire("Mud", base, 0.6, h, 0.4)
	lm.spire("Mud", base + Vector3(0, h, 0), 0.4, 1.5, 0.0)
	_dj_toron(lm, base, out, h, 0.5)

## Rows of toron palm sticks projecting 0.6 m off a face `out` of half-
## width hw over height h.
static func _dj_toron(lm: LandmarkMesh, base: Vector3, out: Vector3, h: float, hw: float) -> void:
	var side := out.cross(Vector3.UP)
	var rows := int(h / 2.8)
	for j in rows:
		var y := 2.2 + 2.8 * float(j)
		var p := base + Vector3(0, y, 0) + out * (hw * (1.0 - 0.3 * y / h) + 0.25)
		var n := 1 if hw < 1.0 else 3
		for k in n:
			var o := 0.0 if n == 1 else (float(k) - 1.0) * hw * 0.55
			lm.beam("Wood", p + side * o, p + side * o + out * 0.7, 0.14, 0.14)

## Box tower on the qibla wall: a battered square shaft with toron rows,
## a stepped crown, the cone pinnacle and its ostrich egg; `top` is the
## egg's top, hw the half-width at the base.
static func _dj_tower(lm: LandmarkMesh, base: Vector3, top: float, hw: float) -> void:
	var body := top - base.y - 3.2
	lm.spire("Mud", base, hw, body, hw * 0.62)
	# Corner pinnacles of the crown and a toron rack on each face.
	var tw := hw * 0.62
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var p := base + Vector3(c.x * tw * 0.85, body, c.y * tw * 0.85)
		lm.spire("Mud", p, 0.4, 1.2, 0.0)
	for d in [Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var side: Vector3 = (d as Vector3).cross(Vector3.UP)
		var rows := int(body / 2.0)
		for j in rows:
			var y := 1.8 + 2.0 * float(j)
			var hwy := lerpf(hw, tw, y / body)
			for k in 4:
				var o := (float(k) - 1.5) * hwy * 0.45
				var p: Vector3 = base + Vector3(0, y, 0) + d * (hwy + 0.05) + side * o
				lm.beam("Wood", p, p + d * 0.65, 0.15, 0.15)
		# Small window slit in the tower face.
		lm.box("Wood", base + Vector3(0, body * 0.55, 0) + d * (lerpf(hw, tw, 0.55) + 0.02),
			Vector3(0.5, 1.1, 0.5), Basis(), 0.0)
	lm.spire("Mud", base + Vector3(0, body, 0), tw * 0.8, 2.4, 0.18)
	LandmarkMaParts.sphere(lm, "Egg", Vector3(base.x, top - 0.45, base.z), 0.32, 10, 6, 1.4)

## Stair of seven steps from the market up the plinth, on the plinth
## face at `at` heading out along `out`, between two pinnacled cheeks.
static func _dj_stair(lm: LandmarkMesh, at: Vector3, out: Vector3) -> void:
	var side := out.cross(Vector3.UP)
	var basis := Basis(side, Vector3.UP, out)
	for k in 7:
		var y := DJ_G * float(k + 1) / 7.0
		var run := 0.45 * float(7 - k)
		lm.box("Plinth", at + out * run * 0.5 + Vector3(0, y * 0.5, 0), Vector3(4.0, y, run + 0.01), basis, 0.0)
	for s in [-1.0, 1.0]:
		var p: Vector3 = at + side * s * 2.5 + out * 1.6
		lm.box("Mud", p + Vector3(0, DJ_G * 0.5 + 0.2, 0), Vector3(0.9, DJ_G + 0.4, 3.2), basis)
		lm.spire("Mud", p + out * 1.2 + Vector3(0, DJ_G * 0.4, 0), 0.4, 1.7, 0.0)

# --- Dome of the Rock ---

## Octagon circumradius (side 20.59 m).
const DOR_R := 26.9
const DOR_G := 0.6

## Octagonal Umayyad shrine (691), on its paved platform: walls 9.5 m
## plus a 2.6 m parapet, marble-panelled below and blue-tiled above, with
## seven arched bays a side (the five middle ones windows), a lead roof
## behind the parapet, the 16-window tiled drum and the gilded 20.2 m dome
## (ribbed plates) and crescent finial at 35.3 m; four gabled porches,
## the deep south one on columns.
static func dome_of_rock(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4DFD0", 5.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#2F76A6", 4.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#8D98A3", 5.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Platform", LandmarkMaterials.pbr("stone", "#CFC5AE", 6.0))
	lm.use("Door", LandmarkMaterials.glass("#1E2426"))
	var g := DOR_G
	var rr := DOR_R
	var rot := PI / 8.0
	lm.box("Platform", Vector3(0, g * 0.5, 0), Vector3(84, g, 84))
	# Marble dado with a moulded plinth, then the tiled upper wall.
	lm.frustum("Marble", Vector3(0, g, 0), rr + 0.3, rr + 0.3, 0.5, 8, rot)
	lm.frustum("Marble", Vector3(0, g, 0), rr, rr, 5.0, 8, rot)
	lm.frustum("Marble", Vector3(0, g + 5.0, 0), rr + 0.25, rr + 0.25, 0.35, 8, rot)
	lm.frustum("Tile", Vector3(0, g + 5.0, 0), rr - 0.1, rr - 0.1, 7.1, 8, rot)
	var side := 2.0 * rr * sin(PI / 8.0)
	for i in 8:
		var a0 := rot + TAU * float(i) / 8.0
		var a1 := rot + TAU * float(i + 1) / 8.0
		var p0 := Vector3(cos(a0), 0, sin(a0)) * rr
		var p1 := Vector3(cos(a1), 0, sin(a1)) * rr
		var r := (p1 - p0).normalized()
		var am := (a0 + a1) * 0.5
		var n := Vector3(cos(am), 0, sin(am))
		var o := p0 + Vector3(0, g + 5.35, 0)
		var bw := side / 7.0
		LandmarkMaParts.arched_bays(lm, "Tile", "Tile", o, r, n, bw, 6.75, 1, 1.9, 2.2, 0.95, 0.35, "Marble", 4)
		LandmarkMaParts.arched_bays(lm, "Tile", "Door", o + r * bw, r, n, bw * 5.0, 6.75, 5, 1.9, 2.2, 0.95,
			0.35, "Marble", 4)
		LandmarkMaParts.arched_bays(lm, "Tile", "Tile", o + r * bw * 6.0, r, n, bw, 6.75, 1, 1.9, 2.2, 0.95,
			0.35, "Marble", 4)
		# Marble dado panels and the inscription band under the parapet.
		for k in 7:
			var pc := p0 + r * bw * (float(k) + 0.5) + n * 0.05 + Vector3(0, g + 2.6, 0)
			lm.box("Marble", pc, Vector3(bw - 0.7, 3.6, 0.12), Basis(r, Vector3.UP, n), 0.0)
		lm.box("Marble", (p0 + p1) * 0.5 + n * 0.42 + Vector3(0, g + 10.9, 0), Vector3(side - 0.6, 0.18, 0.1),
			Basis(r, Vector3.UP, n), 0.0)
		lm.box("Marble", (p0 + p1) * 0.5 + n * 0.42 + Vector3(0, g + 11.8, 0), Vector3(side - 0.6, 0.18, 0.1),
			Basis(r, Vector3.UP, n), 0.0)
	lm.frustum("Marble", Vector3(0, g + 12.1, 0), rr + 0.45, rr + 0.45, 0.3, 8, rot)
	# Lead roof sloping up from behind the parapet to the drum.
	lm.lathe("Lead", Vector3(0, g + 11.0, 0), PackedVector2Array([Vector2(rr - 0.6, 0), Vector2(rr - 1.2, 0.5),
		Vector2(12.6, 3.0)]), 8, 1.0, 1.0, rot, false)
	# Drum: tiled, 16 arched windows under a band, its cornice.
	var db := Vector3(0, g + 13.6, 0)
	lm.frustum("Tile", db, 11.6, 11.6, 9.0, 16, PI / 16.0)
	LandmarkMaParts.arched_ring(lm, "Tile", "Door", db + Vector3(0, 2.0, 0), 11.85, 16, 6.2, 1.5, 3.3, 0.9,
		0.3, PI / 16.0, "Marble")
	lm.frustum("Marble", db + Vector3(0, 1.6, 0), 12.0, 12.0, 0.3, 32)
	lm.frustum("Marble", db + Vector3(0, 8.6, 0), 12.1, 12.3, 0.6, 32)
	# Gilded dome: slightly stilted, ribbed plates, the finial.
	var sb := db + Vector3(0, 9.2, 0)
	var prof := PackedVector2Array()
	for q in [[1.0, 0.0], [1.0, 0.08], [0.97, 0.3], [0.9, 0.48], [0.78, 0.64], [0.62, 0.78], [0.42, 0.89],
			[0.2, 0.97], [0.0, 1.0]]:
		prof.append(Vector2(11.3 * float(q[0]), 10.2 * float(q[1])))
	lm.lathe("Gold", sb, prof, 40)
	for i in 32:
		var a := TAU * float(i) / 32.0
		var dv := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 2:
			var q0 := sb + dv * (prof[j].x + 0.06) + Vector3(0, prof[j].y, 0)
			var q1 := sb + dv * (prof[j + 1].x + 0.06) + Vector3(0, prof[j + 1].y, 0)
			lm.beam("Gold", q0, q1, 0.16, 0.1, dv.cross(Vector3.UP))
	var ft := sb + Vector3(0, 10.2, 0)
	lm.frustum("Gold", ft - Vector3(0, 0.2, 0), 0.7, 0.3, 0.7, 10)
	LandmarkMaParts.sphere(lm, "Gold", ft + Vector3(0, 0.85, 0), 0.32, 10, 6)
	lm.frustum("Gold", ft + Vector3(0, 0.5, 0), 0.08, 0.05, 1.6, 6)
	LandmarkMaParts.crescent(lm, "Gold", ft + Vector3(0, 1.7, 0), 0.6, 0.12)
	# Porches on the four doors (south one deep, on columns).
	var apothem := rr * cos(PI / 8.0)
	for k in 4:
		var d := Vector3(sin(PI * 0.5 * k), 0, cos(PI * 0.5 * k))
		_dor_porch(lm, d * apothem + Vector3(0, g, 0), d, k == 0)
	lm.commit(model)

## Porch on the door in the face at `c` facing `d`: a vaulted gate with
## an arched front on twin columns and a gabled lead roof; `deep` for
## the south porch's open eight-column arcade.
static func _dor_porch(lm: LandmarkMesh, c: Vector3, d: Vector3, deep: bool) -> void:
	var r := Vector3.UP.cross(d).normalized()
	var basis := Basis(r, Vector3.UP, d)
	var w := 13.0 if deep else 9.0
	var dp := 5.6 if deep else 3.6
	var h := 9.0
	lm.box("Door", c + d * 0.05 + Vector3(0, 2.9, 0), Vector3(3.6, 5.8, 0.2), basis, 0.0)
	if deep:
		LandmarkMaParts.arched_bays(lm, "Marble", "", c + d * dp - r * w * 0.5, r, d, w, h, 4, 2.4, 4.6, 1.4,
			0.5, "Tile", 5)
		for i in 5:
			lm.frustum("Marble", c + d * (dp + 0.8) - r * w * 0.5 + r * w * float(i) / 4.0, 0.32, 0.3, 4.6, 10)
		for s in [-1.0, 1.0]:
			lm.box("Marble", c + d * dp * 0.5 + r * s * (w * 0.5 - 0.4) + Vector3(0, h * 0.5, 0),
				Vector3(0.8, h, dp), basis)
	else:
		lm.box("Marble", c + d * dp * 0.5 + Vector3(0, h * 0.5, 0), Vector3(w, h, dp), basis)
		LandmarkMaParts.arched_bays(lm, "Marble", "Door", c + d * dp - r * w * 0.5, r, d, w, h - 0.6, 1, 4.2,
			4.4, 2.1, 0.5, "Tile", 6)
		for s in [-1.0, 1.0]:
			for k in [2.6, 3.4]:
				lm.frustum("Marble", c + d * (dp + 0.9) + r * s * k * 0.75, 0.28, 0.26, 4.4, 10)
	lm.gable("Lead", c + d * dp * 0.5 + Vector3(0, h, 0), w, dp + 0.4, 2.2, Basis(r, Vector3.UP, d), 0.3, "Tile")
