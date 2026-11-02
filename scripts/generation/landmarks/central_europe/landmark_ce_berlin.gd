class_name LandmarkCeBerlin
extends RefCounted

## Berlin icons in true metres: the Brandenburg Gate (sandstone Doric
## gate along X, quadriga facing east, 26 m), the Reichstag (stone block
## with the west portico, four corner towers and Foster's glass dome,
## 47 m) and the Fernsehturm (concrete shaft, steel-faceted sphere and
## red-white antenna, 368 m).

# --- Brandenburg Gate ---

const GATE_TOP := 26.0
## Langhans' gate (1788-91): 62.5 m wide with its two side buildings,
## 11 m deep, 20.3 m to the top of the attic. Twelve fluted Doric
## columns 13.5 m tall and 1.73 m across, six to a side, frame five
## passages: 5.65 m in the middle, 3.8 m for the others.
const GATE_HALF := 31.25
const GATE_CORE := 20.0
const COL_Y := 1.0
const COL_H := 13.5
const COL_X := 4.6
## Passages across the gate (centre z, width), north to south.
const PASSAGES := [[-14.925, 3.8], [-7.925, 3.8], [0.0, 5.65], [7.925, 3.8], [14.925, 3.8]]
## Column axes (z) on the six piers.
const COLS := [-18.425, -11.425, -4.425, 4.425, 11.425, 18.425]

static func gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C4B491", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#8E8672", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6FA08B", 2.0, 0.5, 0.35))
	# Three-step stylobate under the colonnades.
	for k in 3:
		var g := 0.6 * float(2 - k)
		lm.box("Dark", Vector3(0, 0.17 + 0.33 * k, 0), Vector3(11.6 + g * 2.0, 0.34, GATE_CORE * 2.0 + 1.6 + g * 2.0))
	# Pier walls between the passages, panelled on their passage faces.
	var edges: Array[float] = [-GATE_CORE]
	for p in PASSAGES:
		edges.append(float(p[0]) - float(p[1]) * 0.5)
		edges.append(float(p[0]) + float(p[1]) * 0.5)
	edges.append(GATE_CORE)
	var wall_h := COL_H
	for i in range(0, edges.size(), 2):
		var z0: float = edges[i]
		var z1: float = edges[i + 1]
		var zc := (z0 + z1) * 0.5
		lm.box("Stone", Vector3(0, COL_Y + wall_h * 0.5, zc), Vector3(7.6, wall_h, z1 - z0))
		lm.box("Stone", Vector3(0, COL_Y + 0.4, zc), Vector3(8.0, 0.8, z1 - z0 + 0.4))
		# Recessed relief panels on the faces that line the passages.
		for s in [-1.0, 1.0]:
			var zf: float = (z1 if s > 0.0 else z0) + 0.06 * s
			if absf(zf) > GATE_CORE - 0.5:
				continue
			for px in [-1.8, 1.8]:
				var c := Vector3(px, COL_Y + 6.0, zf)
				var b := Basis(Vector3.UP, PI * 0.5)
				lm.box("Dark", c, Vector3(2.4, 7.0, 0.12), b, 0.0)
				for e in [-1.0, 1.0]:
					lm.box("Stone", c + Vector3(e * 1.25, 0, s * 0.08), Vector3(0.18, 7.3, 0.2), Basis(), 0.0)
					lm.box("Stone", c + Vector3(0, e * 3.6, s * 0.08), Vector3(2.7, 0.18, 0.2), Basis(), 0.0)
				lm.box("Stone", c + Vector3(0, 0.6, s * 0.12), Vector3(1.2, 2.6, 0.25), Basis(), 0.0)
	# Fluted Doric columns, six to each front.
	for sx in [-1.0, 1.0]:
		for z in COLS:
			LandmarkDetail.column(lm, "Stone", Vector3(sx * COL_X, COL_Y, float(z)), 0.865, COL_H, "doric", 20)
	_gate_entablature(lm)
	# Guard houses: the side buildings with their Doric porticos.
	for sz in [-1.0, 1.0]:
		var gz: float = sz * (GATE_HALF - 4.75)
		lm.box("Stone", Vector3(-0.5, 4.2, gz), Vector3(9.0, 8.4, 9.5))
		lm.box("Dark", Vector3(0, 0.25, gz), Vector3(11.6, 0.5, 10.6))
		LandmarkDetail.cornice(lm, "Stone", Vector3(4.0, 8.4, gz - sz * 4.75), Vector3(4.0, 8.4, gz + sz * 4.75),
			Vector3.RIGHT, 0.6)
		lm.gable("Dark", Vector3(0, 9.0, gz), 11.0, 10.2, 2.2, Basis(Vector3.UP, PI * 0.5), 0.4, "Stone")
		lm.box("Stone", Vector3(4.6, 8.7, gz), Vector3(1.0, 0.6, 9.8))
		for i in 4:
			var z := gz + (float(i) - 1.5) * 2.6
			LandmarkDetail.column(lm, "Stone", Vector3(4.6, 0.5, z), 0.45, 7.9, "doric", 20)
		# Blind arched niches on the end wall facing out.
		for k in 2:
			var nz: float = gz + sz * 4.8
			var nx := -2.5 + 4.0 * float(k)
			lm.box("Dark", Vector3(nx, 3.2, nz), Vector3(1.6, 3.6, 0.1), Basis(), 0.0)
			LandmarkDetail.arch(lm, "Stone", Vector3(nx, 5.0, nz), Vector3(0, 0, sz), 1.6, 0.3, 0.2)
		# Low wall linking the guard house to the gate.
		lm.box("Stone", Vector3(-0.5, 3.0, sz * (GATE_CORE + 0.7)), Vector3(7.0, 6.0, 1.4))
	_quadriga(lm, Vector3(0, 20.3, 0))
	lm.commit(model)

## Architrave, triglyph frieze with metopes, mutuled cornice and the
## stepped attic with its relief panel.
static func _gate_entablature(lm: LandmarkMesh) -> void:
	var y := COL_Y + COL_H
	var run := GATE_CORE * 2.0 + 1.6
	lm.box("Stone", Vector3(0, y + 0.65, 0), Vector3(11.2, 1.3, run))
	lm.box("Stone", Vector3(0, y + 1.32, 0), Vector3(11.4, 0.14, run + 0.2), Basis(), 0.0)
	lm.box("Stone", Vector3(0, y + 2.0, 0), Vector3(10.9, 1.3, run - 0.3))
	# Triglyphs over every column and every intercolumniation midpoint.
	var tz: Array[float] = []
	for i in COLS.size():
		tz.append(float(COLS[i]))
		if i < COLS.size() - 1:
			var gap := float(COLS[i + 1]) - float(COLS[i])
			var n := 2 if gap > 8.0 else 1
			for k in n:
				tz.append(float(COLS[i]) + gap * (float(k) + 1.0) / float(n + 1))
	tz.append(-GATE_CORE - 0.4)
	tz.append(GATE_CORE + 0.4)
	for sx in [-1.0, 1.0]:
		for z in tz:
			var c := Vector3(sx * 5.5, y + 2.0, z)
			for g in 3:
				lm.box("Stone", c + Vector3(0, 0, (float(g) - 1.0) * 0.36), Vector3(0.22, 1.2, 0.26), Basis(), 0.0)
			lm.box("Dark", c + Vector3(-sx * 0.05, 0.66, 0), Vector3(0.2, 0.12, 1.1), Basis(), 0.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(5.45, y + 2.65, -run * 0.5), Vector3(5.45, y + 2.65, run * 0.5),
		Vector3.RIGHT, 0.75)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-5.45, y + 2.65, run * 0.5), Vector3(-5.45, y + 2.65, -run * 0.5),
		Vector3.LEFT, 0.75)
	for s in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Stone", Vector3(5.45 * s, y + 2.65, s * run * 0.5),
			Vector3(-5.45 * s, y + 2.65, s * run * 0.5), Vector3(0, 0, s), 0.75)
	# Stepped attic: a long socle, then the raised centre under the quadriga.
	var ay := y + 3.4
	lm.box("Stone", Vector3(0, ay + 0.55, 0), Vector3(9.4, 1.1, run - 2.0))
	lm.box("Stone", Vector3(0, ay + 1.15, 0), Vector3(9.6, 0.2, run - 1.8), Basis(), 0.0)
	lm.box("Stone", Vector3(0, ay + 1.75, 0), Vector3(8.0, 1.3, 25.0))
	for s in [-1.0, 1.0]:
		# Stepped shoulders down to the socle at each end of the attic.
		lm.box("Stone", Vector3(0, ay + 1.45, s * 14.0), Vector3(8.0, 0.7, 3.0))
		# Relief panel (the triumphal procession) on both long faces.
		var f := Vector3(s * 4.02, ay + 1.75, 0)
		lm.box("Dark", f, Vector3(0.06, 0.9, 17.0), Basis(), 0.0)
		for k in 14:
			lm.box("Stone", f + Vector3(s * 0.12, -0.05, -7.8 + 1.2 * k), Vector3(0.22, 0.65 + 0.15 * float(k % 3), 0.55),
				Basis(), 0.0)
		for e in [-1.0, 1.0]:
			lm.box("Stone", f + Vector3(s * 0.1, e * 0.5, 0), Vector3(0.2, 0.12, 17.4), Basis(), 0.0)
	lm.box("Stone", Vector3(0, ay + 2.5, 0), Vector3(8.3, 0.25, 25.3), Basis(), 0.0)

## Victoria driving four horses, facing east (+X); top at GATE_TOP.
static func _quadriga(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Stone", base + Vector3(0, 0.35, 0), Vector3(7.4, 0.7, 6.6))
	var b := base + Vector3(0, 0.7, 0)
	# Chariot: car body with a curved front and two wheels.
	lm.lathe("Copper", b + Vector3(-1.2, 0.5, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(1.3, 0.6),
		Vector2(1.45, 1.5), Vector2(1.3, 1.7)]), 12, 0.8, 1.0)
	for s in [-1.0, 1.0]:
		var wc := b + Vector3(-1.2, 0.95, s * 1.4)
		var prev := wc + Vector3(0.95, 0, 0)
		for k in 12:
			var a := TAU * float(k + 1) / 12.0
			var p := wc + Vector3(cos(a), sin(a), 0) * 0.95
			lm.beam("Copper", prev, p, 0.14, 0.14)
			prev = p
		for k in 4:
			var a := PI * 0.25 * float(k)
			lm.beam("Copper", wc - Vector3(cos(a), sin(a), 0) * 0.9, wc + Vector3(cos(a), sin(a), 0) * 0.9, 0.07, 0.07)
	lm.beam("Copper", b + Vector3(-0.2, 1.0, 0), b + Vector3(2.8, 1.6, 0), 0.18, 0.18)
	# Four horses abreast, rearing slightly, heads up.
	for k in 4:
		var z := (float(k) - 1.5) * 1.45
		var hp := b + Vector3(2.4, 0, z)
		# Barrel, chest, arched neck, head and ears, tail.
		lm.beam("Copper", hp + Vector3(-1.2, 1.9, 0), hp + Vector3(0.9, 2.15, 0), 0.95, 0.85)
		lm.lathe("Copper", hp + Vector3(0.75, 1.55, 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.5, 0.35),
			Vector2(0.5, 0.75), Vector2(0.25, 1.05)]), 10, 1.0, 0.8)
		lm.beam("Copper", hp + Vector3(0.7, 2.2, 0), hp + Vector3(1.35, 3.2, 0), 0.55, 0.45)
		lm.beam("Copper", hp + Vector3(1.35, 3.2, 0), hp + Vector3(1.95, 2.95, 0), 0.38, 0.32)
		lm.beam("Copper", hp + Vector3(1.0, 2.9, 0), hp + Vector3(1.25, 3.5, 0), 0.08, 0.3)
		lm.beam("Copper", hp + Vector3(-1.2, 2.0, 0), hp + Vector3(-1.6, 0.9, 0), 0.18, 0.25)
		for lx in [-1.0, 1.0]:
			for lz in [-0.22, 0.22]:
				var hip := hp + Vector3(lx * 0.8 + 0.05, 1.7, lz)
				if lx > 0.0 and k % 2 == 0 and lz > 0.0:
					var knee := hip + Vector3(0.5, -0.2, 0)
					lm.beam("Copper", hip, knee, 0.22, 0.22)
					lm.beam("Copper", knee, knee + Vector3(0.1, -0.7, 0), 0.16, 0.16)
				else:
					var knee := hip + Vector3(lx * 0.08, -0.85, 0)
					lm.beam("Copper", hip, knee, 0.24, 0.22)
					lm.beam("Copper", knee, hp + Vector3(lx * 0.95 + 0.15, 0.0, lz), 0.16, 0.16)
	LandmarkKits.statue_figure(lm, "Copper", b + Vector3(-1.2, 1.9, 0), 3.2, true)
	# Staff with the iron cross in the wreath and the eagle on top.
	var st := b + Vector3(-0.85, 4.1, 0)
	var tip := Vector3(st.x, GATE_TOP - 0.1, st.z)
	lm.beam("Copper", st, tip, 0.12, 0.12)
	var wr := tip - Vector3(0, 1.4, 0)
	for k in 10:
		var a0 := TAU * float(k) / 10.0
		var a1 := TAU * float(k + 1) / 10.0
		lm.beam("Copper", wr + Vector3(0, sin(a0), cos(a0)) * 0.45, wr + Vector3(0, sin(a1), cos(a1)) * 0.45, 0.12, 0.12)
	lm.box("Copper", wr, Vector3(0.08, 0.55, 0.15), Basis(), 0.0)
	lm.box("Copper", wr, Vector3(0.08, 0.15, 0.55), Basis(), 0.0)
	lm.box("Copper", tip - Vector3(0, 0.35, 0), Vector3(0.3, 0.3, 0.9), Basis(), 0.0)

# --- Reichstag ---

## Wallot's Reichstag (1894): 137 m along the west front by 97 m deep,
## roof terrace at 24 m, four corner towers with sandstone figures on
## their attics, the west portico of six Corinthian columns under the
## "Dem deutschen Volke" pediment, and Foster's 1999 glass dome (40 m
## across, 23.5 m high, 24 ribs, two spiral ramps round the mirror
## cone) reaching 47 m.
const RS_HALF := Vector2(48.5, 68.5)
const RS_EAVE := 21.0
const RS_ROOF := 24.0
const RS_TOWER := 40.0

static func reichstag(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B8A98B", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#7E7565", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#59605F", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Glass", LandmarkMaterials.glass("#7C98A6"))
	lm.use("Steel", LandmarkMaterials.paint("#B9BEC0", 0.3, 0.7))
	var core := Vector3((RS_HALF.x - 0.4) * 2.0, RS_EAVE, (RS_HALF.y - 0.4) * 2.0)
	lm.box("Stone", Vector3(0, RS_EAVE * 0.5, 0), core)
	lm.box("Dark", Vector3(0, 0.6, 0), Vector3(core.x + 1.6, 1.2, core.z + 1.6))
	# Attic storey and the flat roof terrace.
	lm.box("Stone", Vector3(0, RS_EAVE + 1.5, 0), Vector3(core.x - 1.0, 3.0, core.z - 1.0))
	lm.box("Roof", Vector3(0, RS_ROOF + 0.1, 0), Vector3(core.x - 2.0, 0.2, core.z - 2.0))
	# Four fronts between the towers: rusticated ground floor, pierced
	# windows on three storeys, pilasters, cornice and attic balustrade.
	for f in 4:
		var n := [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK][f] as Vector3
		var half := RS_HALF.y if f < 2 else RS_HALF.x
		var depth := RS_HALF.x if f < 2 else RS_HALF.y
		var r := Vector3.UP.cross(n).normalized()
		var run := (half - 17.0) * 2.0
		var c0 := n * (depth - 0.4) - r * run * 0.5
		var cols := int(run / 5.6)
		LandmarkDetail.pierced_face(lm, "Stone", "Windows", c0 + Vector3(0, 1.2, 0), r, n, run, RS_EAVE - 2.4,
			cols, 3, Vector2(2.2, 3.6), 1.6, 6.4, 0.45)
		var pitch := run / float(cols)
		for k in 6:
			lm.box("Dark", c0 + n * 0.5 + r * run * 0.5 + Vector3(0, 1.4 + 0.9 * k, 0), Vector3(run, 0.12, 0.12),
				Basis(r, Vector3.UP, n), 0.0)
		for i in cols + 1:
			var p := c0 + n * 0.45 + r * pitch * float(i)
			lm.box("Stone", p + Vector3(0, 13.2, 0), Vector3(0.9, 11.2, 0.5), Basis(r, Vector3.UP, n))
			lm.box("Stone", p + Vector3(0, 19.1, 0), Vector3(1.3, 0.8, 0.7), Basis(r, Vector3.UP, n))
		# Main-floor window heads and sills.
		for i in cols:
			var w := c0 + n * 0.45 + r * pitch * (float(i) + 0.5)
			lm.box("Stone", w + Vector3(0, 7.85, 0), Vector3(3.0, 0.3, 0.5), Basis(r, Vector3.UP, n), 0.0)
			LandmarkDetail.cornice(lm, "Stone", w + Vector3(0, 12.0, 0) - r * 1.5, w + Vector3(0, 12.0, 0) + r * 1.5,
				n, 0.45, false)
		LandmarkDetail.cornice(lm, "Stone", c0 + n * 0.45 + Vector3(0, RS_EAVE - 0.2, 0),
			c0 + n * 0.45 + r * run + Vector3(0, RS_EAVE - 0.2, 0), n, 1.2)
		# Attic: a panel over every bay between the pilaster dies.
		for i in cols:
			var w := c0 + n * 0.1 + r * pitch * (float(i) + 0.5) + Vector3(0, RS_EAVE + 1.7, 0)
			lm.box("Dark", w, Vector3(pitch - 1.6, 1.4, 0.06), Basis(r, Vector3.UP, n), 0.0)
			lm.box("Stone", w - r * pitch * 0.5 + n * 0.1, Vector3(1.0, 2.6, 0.3), Basis(r, Vector3.UP, n), 0.0)
		lm.box("Stone", c0 + n * 0.2 + r * run * 0.5 + Vector3(0, RS_ROOF - 0.15, 0), Vector3(run, 0.3, 0.6),
			Basis(r, Vector3.UP, n), 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_rs_tower(lm, Vector3(sx * (RS_HALF.x - 8.0), 0, sz * (RS_HALF.y - 8.0)), Vector2(sx, sz))
	_rs_portico(lm)
	_rs_dome(lm)
	lm.commit(model)

## Corner tower, 17 m square, to RS_TOWER: a big arched window over two
## storeys on each outer face between paired pilasters, cornice, attic
## and four sandstone figures at the corners.
static func _rs_tower(lm: LandmarkMesh, c: Vector3, out: Vector2) -> void:
	lm.box("Stone", c + Vector3(0, RS_TOWER * 0.5 - 1.0, 0), Vector3(17.0, RS_TOWER - 2.0, 17.0))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b * Vector3(0, 0, 1)
		var p := c + n * 8.5
		var r := Vector3.UP.cross(n).normalized()
		var bb := Basis(r, Vector3.UP, n)
		var outer := n.x * out.x > 0.1 or n.z * out.y > 0.1
		if outer:
			lm.box("Windows", p + Vector3(0, 13.0, 0) + n * 0.02, Vector3(4.2, 10.0, 0.05), bb, 0.0)
			LandmarkDetail.arch(lm, "Stone", p + Vector3(0, 18.0, 0), n, 4.2, 0.7, 0.5)
			for s in [-1.0, 1.0]:
				lm.box("Stone", p + r * 2.45 * s + Vector3(0, 13.0, 0) + n * 0.25, Vector3(0.7, 10.0, 0.5), bb, 0.0)
				for e in [-1.0, 1.0]:
					var q: Vector3 = p + r * (s * (5.5 + e * 1.0)) + n * 0.35
					lm.box("Stone", q + Vector3(0, 17.0, 0), Vector3(1.1, 26.0, 0.7), bb)
					lm.box("Stone", q + Vector3(0, 30.5, 0), Vector3(1.5, 1.0, 1.0), bb)
			lm.box("Dark", p + Vector3(0, 25.5, 0) + n * 0.02, Vector3(3.2, 3.6, 0.05), bb, 0.0)
			for s in [-1.0, 1.0]:
				lm.box("Stone", p + r * 1.8 * s + Vector3(0, 25.5, 0) + n * 0.2, Vector3(0.4, 4.0, 0.4), bb, 0.0)
			lm.box("Stone", p + Vector3(0, 27.7, 0) + n * 0.2, Vector3(4.2, 0.4, 0.5), bb, 0.0)
		LandmarkDetail.cornice(lm, "Stone", p + Vector3(0, 32.0, 0) - r * 8.5, p + Vector3(0, 32.0, 0) + r * 8.5, n, 1.3)
		for k in 5:
			lm.box("Dark", p + Vector3(0, 1.4 + 0.9 * k, 0) + n * 0.05, Vector3(17.0, 0.12, 0.12), bb, 0.0)
	# Attic stage and figures.
	lm.box("Stone", c + Vector3(0, RS_TOWER - 1.0, 0), Vector3(15.6, 2.0, 15.6))
	lm.box("Dark", c + Vector3(0, RS_TOWER - 0.05, 0), Vector3(16.0, 0.1, 16.0), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var q := c + Vector3(sx * 6.6, 33.4, sz * 6.6)
			lm.box("Stone", q + Vector3(0, 0.8, 0), Vector3(1.8, 1.6, 1.8))
			LandmarkKits.statue_figure(lm, "Stone", q + Vector3(0, 1.6, 0), 3.4, false)

## West portico: steps, six Corinthian columns, entablature with the
## inscription band, and the pediment.
static func _rs_portico(lm: LandmarkMesh) -> void:
	var px := -RS_HALF.x - 4.5
	for k in 4:
		lm.box("Dark", Vector3(px - 2.0 + 0.7 * k, 0.35 * k + 0.18, 0), Vector3(13.0 - 1.4 * k, 0.36, 40.0 - 1.0 * k))
	lm.box("Stone", Vector3(px + 1.5, 1.6, 0), Vector3(9.0, 0.4, 35.0))
	var ch := 16.5
	for i in 6:
		var z := -15.0 + 6.0 * i
		LandmarkDetail.column(lm, "Stone", Vector3(px - 1.5, 1.8, z), 0.95, ch, "corinthian", 24)
		if i == 0 or i == 5:
			LandmarkDetail.column(lm, "Stone", Vector3(px + 3.0, 1.8, z), 0.95, ch, "corinthian", 24)
	var ey := 1.8 + ch
	lm.box("Stone", Vector3(px + 0.8, ey + 0.8, 0), Vector3(8.6, 1.6, 34.0))
	lm.box("Dark", Vector3(px - 3.52, ey + 2.3, 0), Vector3(0.1, 1.0, 20.0), Basis(), 0.0)
	lm.box("Stone", Vector3(px + 0.8, ey + 2.3, 0), Vector3(8.4, 1.4, 33.6))
	LandmarkDetail.cornice(lm, "Stone", Vector3(px - 3.4, ey + 3.0, 17.0), Vector3(px - 3.4, ey + 3.0, -17.0),
		Vector3.LEFT, 1.0)
	lm.gable("Roof", Vector3(px + 0.8, ey + 4.0, 0), 34.0, 8.8, 4.6, Basis(Vector3.UP, PI * 0.5), 0.5, "Stone")
	# Raking cornices and the tympanum's coat of arms.
	for s in [-1.0, 1.0]:
		lm.beam("Stone", Vector3(px - 3.6, ey + 4.0, s * 17.3), Vector3(px - 3.6, ey + 8.6, 0), 0.7, 0.8)
	lm.box("Dark", Vector3(px - 3.4, ey + 5.6, 0), Vector3(0.3, 2.0, 2.4))

## Foster's dome: glass shell on 24 steel ribs with 17 rings, the two
## interleaved spiral ramps and the mirrored cone, on a stone base.
static func _rs_dome(lm: LandmarkMesh) -> void:
	var y0 := RS_ROOF + 1.2
	lm.box("Stone", Vector3(0, RS_ROOF + 0.6, 0), Vector3(46.0, 1.2, 46.0))
	var dome := PackedVector2Array()
	for i in 13:
		var a := PI * 0.5 * float(i) / 12.0
		dome.append(Vector2(20.0 * cos(a), 21.0 * sin(a)))
	lm.lathe("Glass", Vector3(0, y0, 0), dome, 48)
	for k in 24:
		var a := TAU * k / 24.0
		var prev := Vector3(cos(a) * 20.2, y0, sin(a) * 20.2)
		for i in range(1, 13):
			var t := PI * 0.5 * float(i) / 12.0
			var p := Vector3(cos(a) * 20.2 * cos(t), y0 + 21.0 * sin(t), sin(a) * 20.2 * cos(t))
			lm.beam("Steel", prev, p, 0.35, 0.5)
			prev = p
	for j in range(1, 17):
		var t := PI * 0.5 * float(j) / 17.5
		lm.frustum("Steel", Vector3(0, y0 + 21.0 * sin(t) - 0.08, 0), 20.25 * cos(t), 20.25 * cos(t), 0.16, 48)
	# Viewing platform ring and the open crown with its vent.
	lm.frustum("Steel", Vector3(0, y0 + 20.4, 0), 6.4, 6.4, 0.5, 32)
	lm.lathe("Steel", Vector3(0, y0 + 20.9, 0), PackedVector2Array([Vector2(4.2, 0), Vector2(4.6, 0.4)]), 32)
	# Two spiral ramps, each 230 m long, climbing 1.5 turns.
	for s in 2:
		var prev_in := Vector3.ZERO
		var prev_out := Vector3.ZERO
		for i in 61:
			var t := float(i) / 60.0
			var a := PI * float(s) + t * TAU * 1.5
			var rr := lerpf(18.6, 9.5, t)
			var y := y0 + 1.0 + t * 17.5
			var d := Vector3(cos(a), 0, sin(a))
			var pin := d * (rr - 1.8) + Vector3(0, y, 0)
			var pout := d * rr + Vector3(0, y, 0)
			if i > 0:
				lm.quad("Stone", prev_in, prev_out, pout, pin, Vector3.UP)
				lm.beam("Steel", prev_out + Vector3(0, 1.1, 0), pout + Vector3(0, 1.1, 0), 0.08, 0.08)
				lm.beam("Glass", prev_out + Vector3(0, 0.55, 0), pout + Vector3(0, 0.55, 0), 0.04, 1.1)
			prev_in = pin
			prev_out = pout
	# Mirror cone: faceted funnel from the chamber up to the crown.
	lm.lathe("Steel", Vector3(0, y0 - 1.0, 0), PackedVector2Array([Vector2(1.2, 0), Vector2(2.4, 5.0),
		Vector2(4.2, 10.0), Vector2(6.6, 15.0), Vector2(7.8, 17.5)]), 30, 1.0, 1.0, 0.0, false)
	for k in 30:
		var a := TAU * k / 30.0
		lm.beam("Dark", Vector3(cos(a) * 2.5, y0 + 4.0, sin(a) * 2.5), Vector3(cos(a) * 7.9, y0 + 16.5, sin(a) * 7.9),
			0.12, 0.12)

# --- Fernsehturm ---

## Fernsehturm (1969): concrete shaft 32 m across at its foot tapering
## to 9 m, the 32 m steel-clad sphere centred at 208 m with the viewing
## floor (203.8 m) and the turning restaurant (207.5 m) behind two glass
## bands, the shaft head to 250 m and the red-white antenna to 368 m.
## At the foot, the pavilion with its folded-plate concrete roof.
const TV_TOP := 368.0
const TV_SPHERE := 208.0

static func tv_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B2AEA6", 6.0))
	lm.use("Sphere", LandmarkMaterials.paint("#C7CDD1", 0.22, 0.85))
	lm.use("Glass", LandmarkMaterials.glass("#34454E"))
	lm.use("Red", LandmarkMaterials.paint("#C23B2E", 0.5, 0.2))
	lm.use("White", LandmarkMaterials.paint("#ECECE8", 0.5, 0.2))
	lm.use("Podium", LandmarkMaterials.pbr("pavement", "#9C978D", 4.0))
	_tv_pavilion(lm)
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(16.0, 0), Vector2(12.0, 8.0),
		Vector2(9.0, 26.0), Vector2(8.0, 70.0), Vector2(7.2, 130.0), Vector2(6.2, 175.0),
		Vector2(5.4, 192.0), Vector2(5.0, 225.0), Vector2(4.2, 240.0), Vector2(3.4, 250.0)]), 32)
	# Vertical service slits and the emergency-stair windows up the shaft.
	for k in 3:
		var a := TAU * float(k) / 3.0 + 0.3
		var d := Vector3(cos(a), 0, sin(a))
		for j in 26:
			var y := 30.0 + 6.0 * j
			var rr := lerpf(8.0, 6.0, (y - 70.0) / 105.0) if y > 70.0 else 8.2
			lm.box("Glass", d * (rr + 0.02) + Vector3(0, y, 0), Vector3(0.6, 2.4, 0.6), Basis(Vector3.UP, PI * 0.5 - a), 0.0)
	_tv_sphere(lm)
	# Antenna: steel cylinder in red-white bands with three work platforms
	# and the beacon cage at the tip.
	lm.lathe("Concrete", Vector3(0, 250.0, 0), PackedVector2Array([Vector2(3.4, 0), Vector2(2.6, 6.0),
		Vector2(1.9, 12.0)]), 16)
	var y0 := 262.0
	var bands := 12
	for k in bands:
		var h := (TV_TOP - y0) / bands
		var r0 := lerpf(1.8, 0.25, float(k) / bands)
		var r1 := lerpf(1.8, 0.25, float(k + 1) / bands)
		lm.frustum("Red" if k % 2 == 0 else "White", Vector3(0, y0 + h * k, 0), r0, r1, h, 12)
	for py in [276.0, 302.0, 328.0, 350.0]:
		var rr := lerpf(1.8, 0.25, (py - y0) / (TV_TOP - y0))
		lm.frustum("White", Vector3(0, py, 0), rr + 1.2, rr + 1.2, 0.3, 16)
		for k in 12:
			var a := TAU * float(k) / 12.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Red", d * (rr + 1.15) + Vector3(0, py + 0.3, 0), d * (rr + 1.15) + Vector3(0, py + 1.3, 0), 0.06, 0.06)
			lm.beam("Red", d * rr + Vector3(0, py - 1.2, 0), d * (rr + 1.1) + Vector3(0, py, 0), 0.1, 0.1)
		lm.frustum("Red", Vector3(0, py + 1.25, 0), rr + 1.18, rr + 1.18, 0.08, 16)
	lm.commit(model)

## The sphere: 32 m, its stainless cladding split into tapering panels
## by meridian and latitude ribs, two glass bands with mullions.
static func _tv_sphere(lm: LandmarkMesh) -> void:
	var c := Vector3(0, TV_SPHERE, 0)
	var sph := PackedVector2Array()
	for i in 25:
		var a := PI * float(i) / 24.0
		sph.append(Vector2(16.0 * sin(a), TV_SPHERE - 16.0 * cos(a)))
	lm.lathe("Sphere", Vector3.ZERO, sph, 40)
	var band := func(y: float) -> float:
		return sqrt(maxf(256.0 - (y - TV_SPHERE) * (y - TV_SPHERE), 0.0))
	for g in [[203.0, 205.6], [206.8, 209.4]]:
		var ya: float = g[0]
		var yb: float = g[1]
		var ra: float = band.call(ya) + 0.12
		var rb: float = band.call(yb) + 0.12
		lm.lathe("Glass", Vector3.ZERO, PackedVector2Array([Vector2(ra, ya), Vector2(rb, yb)]), 48, 1.0, 1.0, 0.0, true, false)
		for k in 48:
			var a := TAU * float(k) / 48.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Sphere", d * (ra + 0.1) + Vector3(0, ya, 0), d * (rb + 0.1) + Vector3(0, yb, 0), 0.14, 0.2)
		lm.frustum("Sphere", Vector3(0, yb, 0), rb + 0.25, rb + 0.25, 0.35, 48)
	# Panel joints: 24 meridians and nine latitude rings.
	for k in 24:
		var a := TAU * float(k) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		var prev := Vector3.ZERO
		for i in 15:
			var t := PI * (0.06 + 0.88 * float(i) / 14.0)
			var p := c + d * 16.06 * sin(t) - Vector3(0, 16.06 * cos(t), 0)
			if i > 0 and absf(p.y - 206.0) > 4.2 and absf(prev.y - 206.0) > 4.2:
				lm.beam("White", prev, p, 0.12, 0.08, d.cross(Vector3.UP))
			prev = p
	for j in 9:
		var y := TV_SPHERE - 13.5 + 3.0 * j
		if absf(y - 206.0) < 4.2:
			continue
		var rr: float = band.call(y) + 0.06
		lm.frustum("White", Vector3(0, y, 0), rr, rr, 0.12, 40)

## Pavilion round the foot: six folded-plate roof wings and the glazed
## halls below them.
static func _tv_pavilion(lm: LandmarkMesh) -> void:
	lm.box("Podium", Vector3(0, 0.3, 0), Vector3(90.0, 0.6, 70.0))
	for w in 6:
		var a := TAU * float(w) / 6.0 + PI / 6.0
		var b := Basis(Vector3.UP, -a)
		var d := b * Vector3(1, 0, 0)
		var r := b * Vector3(0, 0, 1)
		var c := d * 25.0
		lm.box("Glass", c + Vector3(0, 3.0, 0), Vector3(22.0, 5.4, 13.0), b, 0.0)
		# Folded plates: alternating ridges and valleys across the wing.
		var folds := 8
		for k in folds:
			var t0 := -11.0 + 22.0 * float(k) / folds
			var t1 := -11.0 + 22.0 * float(k + 1) / folds
			var hi0 := 9.5 if k % 2 == 0 else 6.0
			var hi1 := 6.0 if k % 2 == 0 else 9.5
			var p0 := c + d * t0
			var p1 := c + d * t1
			lm.quad("Concrete", p0 - r * 7.5 + Vector3(0, hi0, 0), p1 - r * 7.5 + Vector3(0, hi1, 0),
				p1 + r * 7.5 + Vector3(0, hi1, 0), p0 + r * 7.5 + Vector3(0, hi0, 0), Vector3.UP)
			lm.quad("Concrete", p0 - r * 7.5 + Vector3(0, hi0, 0), p1 - r * 7.5 + Vector3(0, hi1, 0),
				p1 - r * 7.5 + Vector3(0, 5.7, 0), p0 - r * 7.5 + Vector3(0, 5.7, 0), -r)
			lm.quad("Concrete", p0 + r * 7.5 + Vector3(0, hi0, 0), p1 + r * 7.5 + Vector3(0, hi1, 0),
				p1 + r * 7.5 + Vector3(0, 5.7, 0), p0 + r * 7.5 + Vector3(0, 5.7, 0), r)
		for k in 5:
			lm.box("Concrete", c + d * (-9.0 + 4.5 * k) + r * 6.6 + Vector3(0, 2.9, 0), Vector3(0.5, 5.8, 0.5), b, 0.0)
			lm.box("Concrete", c + d * (-9.0 + 4.5 * k) - r * 6.6 + Vector3(0, 2.9, 0), Vector3(0.5, 5.8, 0.5), b, 0.0)
