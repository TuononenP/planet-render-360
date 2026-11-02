class_name LandmarkEahXian
extends RefCounted

## Xi'an in true metres: the Terracotta Army's Pit 1 hall (22 m to the
## skylight: the 1976 hangar, 230 x 72 m, of steel arched trusses over
## the 230 x 62 m pit, long axis east-west; eleven corridors between ten
## rammed-earth partitions, the excavated east end ranked with clay
## soldiers four abreast behind a three-row vanguard of 204 archers,
## chariot teams at the heads of the columns, the west still under the
## earth; the pit, really some 5 m deep, is shown at ground level inside
## a raised visitors' gallery) and the Big Wild Goose Pagoda (64.5 m:
## seven battered storeys of grey-yellow brick on a 4.2 m platform, each
## face divided by brick pilasters into nine, seven or five bays, an
## architrave and brick bracket course under corbelled eaves that step
## out and back in, an arched opening on every face, square top under a
## brick finial). Fronts face south (+Z); east is +X.

# --- Terracotta Army, Pit 1 ---

const PIT_M := 22.0
const HALL := Vector2(230.0, 72.0)
const SPRING_M := 10.0
const PIT := Vector2(212.0, 62.0)
const GALLERY_M := 5.0
const CORRIDOR_W := 3.2
const PARTITION_W := 2.5

static func terracotta_pit1(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#8E959A", 3.0, 0.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B2AEA4", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#5F7482"))
	lm.use("Earth", LandmarkMaterials.pbr("stone", "#8C6C4B", 3.0))
	lm.use("Clay", LandmarkMaterials.pbr("terracotta", "#826A55", 2.0))
	lm.use("Floor", LandmarkMaterials.pbr("gravel", "#9B8A70", 4.0))
	_pit_hall(lm)
	_pit(lm)
	lm.commit(model)

## The hangar: vault skin and soffit, ridge skylight, 25 arched steel
## trusses, purlins, piered side walls with clerestory glazing, glazed
## end walls with mullions.
static func _pit_hall(lm: LandmarkMesh) -> void:
	var hx := HALL.x * 0.5
	var hz := HALL.y * 0.5
	var rise := PIT_M - 0.4 - SPRING_M
	var arc := _vault(hz, SPRING_M, rise)
	var under := _vault(hz - 0.3, SPRING_M - 0.5, rise - 0.5)
	LandmarkEahParts.extrude_x(lm, "Roof", arc, -hx, hx, Vector2(0, 0))
	LandmarkEahParts.extrude_x(lm, "Concrete", under, -hx, hx, Vector2(0, 200))
	var sky := PackedVector2Array()
	for p in _vault(hz, SPRING_M, rise + 0.4):
		if absf(p.x) < 4.5:
			sky.append(p)
	LandmarkEahParts.extrude_x(lm, "Glass", sky, -hx, hx, Vector2(0, 0))
	# Skylight glazing bars every 2.4 m.
	for k in 96:
		var x := -hx + 2.4 * (k + 0.5)
		for i in sky.size() - 1:
			lm.beam("Concrete", Vector3(x, sky[i].y + 0.05, sky[i].x), Vector3(x, sky[i + 1].y + 0.05, sky[i + 1].x), 0.12, 0.12)
	# Arched trusses every 9.6 m under the soffit: outer and inner chords
	# with a zig-zag web.
	var outer := _vault(hz - 0.6, SPRING_M - 0.6, rise - 0.7)
	var inner := _vault(hz - 1.8, SPRING_M - 0.6, rise - 1.9)
	for k in 25:
		var x := -hx + 3.0 + 9.4 * k
		for i in outer.size() - 1:
			var a := Vector3(x, outer[i].y, outer[i].x)
			var b := Vector3(x, outer[i + 1].y, outer[i + 1].x)
			var c := Vector3(x, inner[i].y, inner[i].x)
			var d := Vector3(x, inner[i + 1].y, inner[i + 1].x)
			lm.beam("Concrete", a, b, 0.35, 0.3)
			lm.beam("Concrete", c, d, 0.3, 0.25)
			lm.beam("Concrete", a if i % 2 == 0 else c, d if i % 2 == 0 else b, 0.15, 0.15)
	# Purlins along the vault between the trusses.
	for i in range(2, 23, 3):
		var p := outer[i]
		lm.beam("Concrete", Vector3(-hx, p.y - 0.2, p.x), Vector3(hx, p.y - 0.2, p.x), 0.3, 0.4, Vector3.UP)
	# Long sides: piers every 10 m on a plinth wall, fascia, glazing.
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(0, SPRING_M - 0.6, s * hz), Vector3(HALL.x, 1.2, 1.6))
		lm.box("Concrete", Vector3(0, 1.5, s * hz), Vector3(HALL.x, 3.0, 1.0))
		lm.box("Glass", Vector3(0, 6.0, s * (hz - 0.2)), Vector3(HALL.x, 6.0, 0.1), Basis(), 0.0)
		for k in 23:
			var x := -hx + 5.0 + 10.0 * k
			lm.box("Concrete", Vector3(x, (SPRING_M - 1.2) * 0.5, s * hz), Vector3(1.5, SPRING_M - 1.2, 1.6))
			for m in 3:
				lm.box("Concrete", Vector3(x + 2.5 * (m + 1), 6.0, s * hz), Vector3(0.18, 6.0, 0.3), Basis(), 0.0)
			lm.box("Concrete", Vector3(x + 5.0, 6.0, s * hz), Vector3(10.0, 0.18, 0.3), Basis(), 0.0)
	# End walls with a big glazed window and its mullion grid.
	var full := PackedVector2Array([Vector2(-hz, 0)])
	full.append_array(arc)
	full.append(Vector2(hz, 0))
	var win := PackedVector2Array()
	for p in full:
		win.append(Vector2(p.x * 0.62, 1.6 + p.y * 0.72))
	for s in [-1.0, 1.0]:
		LandmarkEahParts.cap_x(lm, "Concrete", full, s * hx, s)
		LandmarkEahParts.cap_x(lm, "Glass", win, s * (hx + 0.08), s)
		for m in 15:
			var z := -hz * 0.62 + hz * 1.24 * (m + 0.5) / 15.0
			var t := absf(z) / (hz * 0.62)
			var top := 1.6 + (SPRING_M + rise * sqrt(maxf(1.0 - t * t, 0.0))) * 0.72
			lm.box("Concrete", Vector3(s * (hx + 0.15), (1.6 + top) * 0.5, z), Vector3(0.2, top - 1.6, 0.2), Basis(), 0.0)
		for r in 4:
			var y := 4.0 + 3.5 * r
			lm.box("Concrete", Vector3(s * (hx + 0.15), y, 0), Vector3(0.2, 0.2, hz * 1.1), Basis(), 0.0)

## The pit at ground level inside the 5 m visitors' gallery: partitions,
## the unexcavated west under earth, the ranks in the east, the vanguard,
## the chariot teams and the gallery rails.
static func _pit(lm: LandmarkMesh) -> void:
	var px := PIT.x * 0.5
	var pz := PIT.y * 0.5
	var hx := HALL.x * 0.5
	var hz := HALL.y * 0.5
	lm.box("Floor", Vector3(0, 0.05, 0), Vector3(PIT.x, 0.1, PIT.y), Basis(), 0.0)
	# Raised gallery round the pit (the hall floor), with its rails.
	for s in [-1.0, 1.0]:
		LandmarkEahParts.slab(lm, "Concrete", Vector3(-hx + 1.0, 0.0, s * pz), Vector3(hx - 1.0, GALLERY_M, s * (hz - 0.6)))
		LandmarkEahParts.slab(lm, "Concrete", Vector3(s * px, 0.0, -pz), Vector3(s * (hx - 1.0), GALLERY_M, pz))
		LandmarkEahDetail.railing(lm, "Concrete", Vector3(-px, GALLERY_M, s * (pz + 0.3)), Vector3(px, GALLERY_M, s * (pz + 0.3)), 1.1, 2.0, 0.08)
		LandmarkEahDetail.railing(lm, "Concrete", Vector3(s * (px + 0.3), GALLERY_M, -pz), Vector3(s * (px + 0.3), GALLERY_M, pz), 1.1, 2.0, 0.08)
	# Ten rammed-earth partitions between eleven corridors, and the
	# transverse corridors at both ends.
	var pitch := CORRIDOR_W + PARTITION_W
	var z0 := -pz + 0.9 + CORRIDOR_W * 0.5
	for w in 10:
		var z := z0 + pitch * w + pitch * 0.5
		lm.box("Earth", Vector3(0, 1.6, z), Vector3(PIT.x - 14.0, 3.2, PARTITION_W))
	# The west, still unexcavated: earth level with the partitions, and
	# the trial trenches cut into it.
	lm.box("Earth", Vector3(-px * 0.5 + 3.0, 1.5, 0), Vector3(px - 6.0, 3.0, PIT.y - 1.8))
	for k in 4:
		lm.box("Floor", Vector3(-px + 20.0 + 18.0 * k, 3.01, 0), Vector3(4.0, 0.02, PIT.y - 4.0), Basis(), 0.0)
	# Ranks: four abreast in the nine central corridors, two in the
	# outer ones facing out, from behind the vanguard to x = 34.
	var x_head := px - 14.0
	var n_rank := 43
	for c in 11:
		var zc := z0 + pitch * c
		var files: Array = [-1.2, -0.4, 0.4, 1.2] if c > 0 and c < 10 else [-0.5, 0.5]
		var start := 0
		if c in [2, 5, 8]:
			_chariot(lm, Vector3(x_head - 3.5, 0.1, zc))
			start = 6
		for f in files:
			for k in range(start, n_rank):
				_soldier(lm, Vector3(x_head - 1.35 * k, 0.1, zc + float(f)))
	# Vanguard: three rows of 68 across the east transverse corridor.
	for r in 3:
		for k in 68:
			_soldier(lm, Vector3(px - 3.0 - 1.4 * r, 0.1, -pz + 1.2 + (PIT.y - 2.4) * (k + 0.5) / 68.0))

## One clay soldier on its foot plate, 1.86 m: robe, belted waist,
## armoured shoulders, neck, head and topknot.
static func _soldier(lm: LandmarkMesh, at: Vector3) -> void:
	lm.lathe("Clay", at, PackedVector2Array([Vector2(0.32, 0), Vector2(0.3, 0.9), Vector2(0.24, 1.0),
		Vector2(0.29, 1.42), Vector2(0.1, 1.52), Vector2(0.13, 1.75), Vector2(0.0, 1.86)]), 5, 1.0, 0.75, 0.0, true, false)

## A chariot team: four horses abreast and the (decayed) chariot box
## with its driver and two warriors behind.
static func _chariot(lm: LandmarkMesh, at: Vector3) -> void:
	for h in 4:
		var hz := at.z + (h - 1.5) * 0.75
		var c := Vector3(at.x + 1.2, at.y, hz)
		lm.box("Clay", c + Vector3(0, 1.15, 0), Vector3(1.8, 0.65, 0.5), Basis(), 0.0)
		lm.beam("Clay", c + Vector3(0.75, 1.3, 0), c + Vector3(1.15, 1.75, 0), 0.32, 0.4)
		lm.box("Clay", c + Vector3(1.35, 1.65, 0), Vector3(0.55, 0.25, 0.22), Basis(), 0.0)
		for lx in [-0.7, 0.7]:
			for lz in [-0.15, 0.15]:
				lm.box("Clay", c + Vector3(float(lx), 0.42, float(lz)), Vector3(0.12, 0.84, 0.12), Basis(), 0.0)
	lm.box("Earth", at + Vector3(-1.0, 0.6, 0), Vector3(1.2, 0.5, 1.4), Basis(), 0.0)
	for s in [-0.6, 0.0, 0.6]:
		_soldier(lm, at + Vector3(-2.1, 0, float(s)))

## Elliptical vault points (z, y) from wall top to wall top.
static func _vault(half: float, spring: float, rise: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 25:
		var a := PI * float(i) / 24.0
		out.append(Vector2(-half * cos(a), spring + rise * sin(a)))
	return out

# --- Big Wild Goose Pagoda ---

const GOOSE_M := 64.5
## Storey heights and bottom widths (the brick tower tapers 25 m to 15 m),
## and the pilasters per face (10 / 8 / 6: nine, seven and five bays).
const GOOSE_H := [11.6, 9.2, 8.0, 7.4, 6.8, 6.4, 6.0]
const GOOSE_W := [25.0, 22.2, 20.2, 18.6, 17.2, 16.0, 14.9]
const GOOSE_PIERS := [10, 10, 8, 8, 6, 6, 6]

static func wild_goose(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A59982", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B2AA9A", 3.0))
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())
	# 45.8 x 48.8 m platform, 4.2 m, with a plinth course, coping and
	# the south stair.
	LandmarkEahParts.slab(lm, "Brick", Vector3(-22.9, 0.0, -24.4), Vector3(22.9, 4.0, 24.4))
	LandmarkEahParts.slab(lm, "Stone", Vector3(-23.7, 0.0, -25.2), Vector3(23.7, 1.0, 25.2))
	LandmarkEahParts.slab(lm, "Stone", Vector3(-23.2, 3.9, -24.7), Vector3(23.2, 4.2, 24.7))
	LandmarkEahParts.stairs(lm, "Stone", 0.0, 29.4, 0.0, 7.0, 10, 0.42, 0.5)
	for s in [-1.0, 1.0]:
		lm.beam("Stone", Vector3(s * 3.8, 0.6, 29.6), Vector3(s * 3.8, 4.6, 24.6), 0.6, 0.5, Vector3.RIGHT)
	var y := 4.2
	for i in 7:
		var h: float = GOOSE_H[i]
		var wb: float = GOOSE_W[i]
		var wt := wb - 0.9
		var wall_h := h - 2.6
		LandmarkAeParts.batter(lm, "Brick", 0, 0, wb, wb, wt, wt, y, y + wall_h)
		_goose_faces(lm, i, y, wall_h, wb, wt)
		# Corbelled eave: courses stepping out, then stepping back in to
		# the next storey (or the top).
		var ey := y + wall_h
		var nxt: float = GOOSE_W[i + 1] if i < 6 else 13.0
		var outs := [[0.5, 0.3], [1.1, 0.3], [1.8, 0.3], [2.5, 0.32], [3.1, 0.3]]
		for c in outs:
			var cw: float = wt + float(c[0])
			LandmarkEahParts.slab(lm, "Brick", Vector3(-cw * 0.5, ey, -cw * 0.5), Vector3(cw * 0.5, ey + float(c[1]), cw * 0.5))
			ey += float(c[1])
		var back := y + h - ey
		for k in 4:
			var cw := lerpf(wt + 2.4, nxt + 0.3, float(k + 1) / 4.0)
			LandmarkEahParts.slab(lm, "Brick", Vector3(-cw * 0.5, ey, -cw * 0.5), Vector3(cw * 0.5, ey + back / 4.0, cw * 0.5))
			ey += back / 4.0
		y += h
	# Square stepped top under the brick finial and its gilt pearl.
	lm.box("Brick", Vector3(0, y + 0.4, 0), Vector3(12.0, 0.8, 12.0))
	lm.box("Brick", Vector3(0, y + 1.0, 0), Vector3(10.4, 0.4, 10.4))
	lm.spire("Brick", Vector3(0, y + 1.2, 0), 4.8, 2.7, 0.7)
	lm.lathe("Brick", Vector3(0, y + 3.9, 0), PackedVector2Array([Vector2(0.9, 0), Vector2(1.1, 0.3),
		Vector2(0.6, 0.6), Vector2(0.3, 0.7)]), 12)
	LandmarkAeParts.ball(lm, "Gold", Vector3(0, GOOSE_M - 0.5, 0), 0.5, 10, 6)
	lm.commit(model)

## The four faces of storey i: pilasters dividing the face into bays,
## the architrave tying them, a brick bracket (dou) on each pilaster,
## an arched opening with a brick archivolt in the middle bay (the stone
## door frames with carved lintels on the ground floor).
static func _goose_faces(lm: LandmarkMesh, i: int, y: float, wall_h: float, wb: float, wt: float) -> void:
	var wm := (wb + wt) * 0.5
	var n_p: int = GOOSE_PIERS[i]
	var ww := 3.4 if i == 0 else 2.4
	var wh := 5.6 if i == 0 else wall_h * 0.55
	var wy := 0.0 if i == 0 else wall_h * 0.22
	for n in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var nv: Vector3 = n
		var along := Vector3(absf(nv.z), 0, absf(nv.x))
		var basis := Basis(along, Vector3.UP, nv)
		var face := nv * (wm * 0.5)
		for k in n_p:
			var t := float(k) / float(n_p - 1) - 0.5
			var pc := face + along * t * (wm - 0.6) + nv * 0.12
			if absf(t * (wm - 0.6)) < ww * 0.5 + 0.4:
				continue
			lm.box("Brick", pc + Vector3(0, y + wall_h * 0.5, 0), Vector3(0.55, wall_h, 0.3), basis)
			lm.box("Brick", pc + Vector3(0, y + wall_h - 0.2, 0) + nv * 0.15, Vector3(0.8, 0.4, 0.5), basis, 0.0)
			lm.box("Brick", pc + Vector3(0, y + wall_h + 0.05, 0) + nv * 0.25, Vector3(1.1, 0.12, 0.7), basis, 0.0)
		# Architrave and the plinth band.
		lm.box("Brick", face + nv * 0.18 + Vector3(0, y + wall_h - 0.75, 0), Vector3(wm - 0.2, 0.4, 0.25), basis, 0.0)
		lm.box("Brick", face + nv * 0.3 + Vector3(0, y + 0.2, 0), Vector3(wb - 0.2, 0.4, 0.3), basis, 0.0)
		LandmarkEahParts.arch_open(lm, "Shadow", face, nv, y + wy, ww, wh)
		LandmarkDetail.arch(lm, "Brick" if i > 0 else "Stone", face + Vector3(0, y + wy + wh - ww * 0.5, 0) + nv * 0.05,
			nv, ww, 0.35, 0.3)
		for s in [-1.0, 1.0]:
			lm.box("Brick" if i > 0 else "Stone", face + along * s * (ww * 0.5 + 0.3) + nv * 0.15
				+ Vector3(0, y + wy + (wh - ww * 0.5) * 0.5, 0), Vector3(0.6, wh - ww * 0.5, 0.35), basis, 0.0)
		if i == 0:
			lm.box("Stone", face + nv * 0.2 + Vector3(0, y + wh - ww * 0.5, 0), Vector3(ww + 1.2, 0.6, 0.4), basis, 0.0)
			lm.box("Stone", face + nv * 0.2 + Vector3(0, y + 0.15, 0), Vector3(ww + 1.4, 0.3, 0.5), basis, 0.0)
