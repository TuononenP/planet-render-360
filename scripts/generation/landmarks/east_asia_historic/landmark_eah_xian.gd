class_name LandmarkEahXian
extends RefCounted

## Xi'an in true metres: the Terracotta Army's Pit 1 hall (22 m to the
## skylight: a 230 m barrel-vaulted hangar on concrete piers over the
## rammed-earth corridors and their ranks of clay soldiers, long axis
## east-west) and the Big Wild Goose Pagoda (64.5 m: seven battered
## storeys of grey-yellow brick with corbelled eaves and arched windows
## on a 4.2 m platform, square top, gilt finial). Fronts face south (+Z).

# --- Terracotta Army, Pit 1 ---

const PIT_M := 22.0
const HALL := Vector2(230.0, 72.0)
const SPRING_M := 10.0

static func terracotta_pit1(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#8E959A", 3.0, 0.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B2AEA4", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#5F7482"))
	lm.use("Earth", LandmarkMaterials.pbr("stone", "#8C6C4B", 3.0))
	lm.use("Clay", LandmarkMaterials.pbr("terracotta", "#826A55", 2.0))
	lm.use("Floor", LandmarkMaterials.pbr("gravel", "#9B8A70", 4.0))
	var hx := HALL.x * 0.5
	var hz := HALL.y * 0.5
	var rise := PIT_M - 0.4 - SPRING_M
	# Cross-section: the shallow elliptical vault from wall top to wall top.
	var arc := _vault(hz, SPRING_M, rise)
	var under := _vault(hz - 0.3, SPRING_M - 0.5, rise - 0.5)
	LandmarkEahParts.extrude_x(lm, "Roof", arc, -hx, hx, Vector2(0, 0))
	LandmarkEahParts.extrude_x(lm, "Concrete", under, -hx, hx, Vector2(0, 200))
	# Glazed skylight along the ridge, arch ribs every 19.2 m.
	var sky := PackedVector2Array()
	for p in _vault(hz, SPRING_M, rise + 0.4):
		if absf(p.x) < 4.5:
			sky.append(p)
	LandmarkEahParts.extrude_x(lm, "Glass", sky, -hx, hx, Vector2(0, 0))
	for k in 13:
		var x := -hx + HALL.x * float(k) / 12.0
		var rib := _vault(hz + 0.1, SPRING_M, rise + 0.35)
		for i in rib.size() - 1:
			lm.beam("Concrete", Vector3(x, rib[i].y, rib[i].x), Vector3(x, rib[i + 1].y, rib[i + 1].x), 0.6, 0.5)
	# Long sides: concrete piers every 10 m under a fascia, open between.
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(0, SPRING_M - 0.6, s * hz), Vector3(HALL.x, 1.2, 1.6))
		for k in 23:
			lm.box("Concrete", Vector3(-hx + 5.0 + 10.0 * k, (SPRING_M - 1.2) * 0.5, s * hz),
				Vector3(1.5, SPRING_M - 1.2, 1.6))
	# End walls with a big glazed window.
	var full := PackedVector2Array([Vector2(-hz, 0)])
	full.append_array(arc)
	full.append(Vector2(hz, 0))
	var win := PackedVector2Array()
	for p in full:
		win.append(Vector2(p.x * 0.62, 1.6 + p.y * 0.72))
	for s in [-1.0, 1.0]:
		LandmarkEahParts.cap_x(lm, "Concrete", full, s * hx, s)
		LandmarkEahParts.cap_x(lm, "Glass", win, s * (hx + 0.08), s)
	# The pit: floor, twelve rammed-earth partitions, two files of soldiers
	# in each corridor.
	lm.box("Floor", Vector3(0, -0.1, 0), Vector3(HALL.x - 2.0, 0.3, HALL.y - 3.0))
	var pitch := 62.0 / 11.0
	for w in 12:
		var z := -31.0 + pitch * w
		lm.box("Earth", Vector3(0, 1.1, z), Vector3(216.0, 2.2, 2.6))
	for c in range(1, 10):
		var zc := -31.0 + pitch * (c + 0.5)
		for f in [-0.8, 0.8]:
			for k in 68:
				lm.box("Clay", Vector3(-100.0 + 3.0 * k, 0.95, zc + f), Vector3(1.2, 1.85, 1.0))
	lm.commit(model)

## Elliptical vault points (z, y) from wall top to wall top.
static func _vault(half: float, spring: float, rise: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 25:
		var a := PI * float(i) / 24.0
		out.append(Vector2(-half * cos(a), spring + rise * sin(a)))
	return out

# --- Big Wild Goose Pagoda ---

const GOOSE_M := 64.5
## Storey heights and bottom widths (the brick tower tapers 25 m to 15 m).
const GOOSE_H := [11.6, 9.2, 8.0, 7.4, 6.8, 6.4, 6.0]
const GOOSE_W := [25.0, 22.2, 20.2, 18.6, 17.2, 16.0, 14.9]

static func wild_goose(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A59982", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B2AA9A", 3.0))
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())
	# 45.8 x 48.8 m platform, 4.2 m, with a plinth course and the south stair.
	LandmarkEahParts.slab(lm, "Stone", Vector3(-22.9, -0.6, -24.4), Vector3(22.9, 4.2, 24.4))
	LandmarkEahParts.slab(lm, "Stone", Vector3(-23.7, -0.6, -25.2), Vector3(23.7, 1.0, 25.2))
	LandmarkEahParts.stairs(lm, "Stone", 0.0, 29.4, 0.0, 7.0, 10, 0.42, 0.5)
	var y := 4.2
	for i in 7:
		var h: float = GOOSE_H[i]
		var wb: float = GOOSE_W[i]
		var wt := wb - 0.9
		var wall_h := h - 1.75
		LandmarkAeParts.batter(lm, "Brick", 0, 0, wb, wb, wt, wt, y, y + wall_h)
		# Four corbelled eave courses, each wider than the last.
		var ey := y + wall_h
		var courses := [[1.0, 0.45], [2.0, 0.5], [3.0, 0.55], [3.4, 0.25]]
		for c in courses:
			var cw: float = wt + float(c[0])
			LandmarkEahParts.slab(lm, "Brick", Vector3(-cw * 0.5, ey, -cw * 0.5),
				Vector3(cw * 0.5, ey + float(c[1]), cw * 0.5))
			ey += float(c[1])
		# Corner pilasters, then an arched window (a door below) and flank
		# pilasters on each of the four faces.
		var wm := (wb + wt) * 0.5
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				lm.box("Brick", Vector3(sx * (wm * 0.5 - 0.25), y + wall_h * 0.5, sz * (wm * 0.5 - 0.25)),
					Vector3(1.0, wall_h, 1.0))
		var ww := 3.4 if i == 0 else 2.4
		var wh := 5.6 if i == 0 else wall_h * 0.55
		var wy := 0.0 if i == 0 else wall_h * 0.22
		for n in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
			var nv: Vector3 = n
			LandmarkEahParts.arch_open(lm, "Shadow", nv * (wm * 0.5), nv, y + wy, ww, wh)
			var along := Vector3(absf(nv.z), 0, absf(nv.x))
			for s in [-1.0, 1.0]:
				var pc: Vector3 = nv * (wm * 0.5) + along * s * (ww * 0.5 + 0.9)
				var sz := Vector3(0.5 * along.x + 0.3 * absf(nv.x), wall_h, 0.5 * along.z + 0.3 * absf(nv.z))
				lm.box("Brick", Vector3(pc.x, y + wall_h * 0.5, pc.z), sz)
		y += h
	# Square stepped top under a gilt finial.
	lm.box("Brick", Vector3(0, y + 0.4, 0), Vector3(12.0, 0.8, 12.0))
	lm.spire("Brick", Vector3(0, y + 0.8, 0), 5.8, 3.1, 0.7)
	LandmarkAeParts.ball(lm, "Gold", Vector3(0, y + 4.15, 0), 0.5, 10, 6)
	lm.lathe("Gold", Vector3(0, y + 3.9, 0), PackedVector2Array([Vector2(0.28, 0), Vector2(0.12, 0.6),
		Vector2(0.03, GOOSE_M - (y + 3.9))]), 8)
	lm.commit(model)
