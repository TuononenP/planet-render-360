class_name LandmarkRbBalkans
extends RefCounted

## Two Eastern European monuments in true metres: Saint Sophia Cathedral
## in Kyiv (the stepped five-aisle church under thirteen green and gilded
## Ukrainian-baroque domes, with the 76 m baroque bell tower beside it)
## and the Palace of the Parliament in Bucharest (the colossal marble
## block in tiers rising to the central dome, 84 m).

const SOPHIA_TOP := 76.0

## Pear-shaped Ukrainian-baroque dome of base radius r and height h.
static func _pear(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, seg: int = 16) -> void:
	var f := [[0.82, 0.0], [1.0, 0.1], [1.08, 0.26], [0.92, 0.42], [0.6, 0.58], [0.38, 0.7],
		[0.3, 0.76], [0.36, 0.8], [0.2, 0.88], [0.0, 1.0]]
	var p := PackedVector2Array()
	for q in f:
		p.append(Vector2(r * float(q[0]), h * float(q[1])))
	lm.lathe(key, base, p, seg)

## Drum, cornice ring, pear dome and cross on `base`; returns the cross tip y.
static func _dome(lm: LandmarkMesh, wall: String, dome: String, gilt: String, base: Vector3,
		r: float, drum_h: float, dome_h: float, cross_h: float) -> float:
	lm.frustum(wall, base, r, r, drum_h, 16)
	lm.frustum(wall, base + Vector3(0, drum_h, 0), r * 1.12, r * 1.12, r * 0.12, 16)
	var top := base + Vector3(0, drum_h + r * 0.12, 0)
	_pear(lm, dome, top, r * 1.05, dome_h)
	LandmarkRbParts.cross(lm, gilt, top + Vector3(0, dome_h, 0), cross_h)
	return top.y + dome_h + cross_h

## Origin at the cathedral centre; the apses face +X, the long walls
## face +/-Z, the bell tower stands 71 m off to the +X, -Z side.
static func kyiv_sophia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EFEADB", 4.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#F7F4EA", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#9A9486", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6E7F74", 3.0, 0.6, 0.2))
	lm.use("Green", LandmarkMaterials.pbr("concrete", "#4F8A6C", 2.5, 0.4, 0.45))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Three stepped masses: outer galleries (9.5 m), the five-aisle body
	# (17 m) and the cross under the central dome (24.5 m).
	lm.box("Plinth", Vector3(0, 0.4, 0), Vector3(59.6, 0.8, 40.2))
	lm.box("Wall", Vector3(0, 4.75, 0), Vector3(58.5, 9.5, 39.0))
	lm.box("White", Vector3(0, 9.7, 0), Vector3(59.3, 0.5, 39.8))
	lm.box("Wall", Vector3(0, 8.5, 0), Vector3(50.0, 17.0, 29.5))
	lm.box("White", Vector3(0, 17.2, 0), Vector3(50.8, 0.5, 30.3))
	lm.box("Wall", Vector3(0, 12.25, 0), Vector3(32.0, 24.5, 17.0))
	lm.box("Wall", Vector3(0, 12.25, 0), Vector3(17.0, 24.5, 28.0))
	lm.box("White", Vector3(0, 24.7, 0), Vector3(32.8, 0.5, 17.8))
	lm.box("White", Vector3(0, 24.7, 0), Vector3(17.8, 0.5, 28.8))
	lm.box("Roof", Vector3(0, 9.95, 0), Vector3(58.0, 0.2, 38.0))
	# Five apses on the east end.
	for z in [-16.5, -11.5, 0.0, 11.5, 16.5]:
		var big := absf(z) < 1.0
		var r := 6.5 if big else (4.0 if absf(z) < 12.0 else 2.6)
		var h := 13.0 if big else (10.5 if absf(z) < 12.0 else 8.0)
		lm.frustum("Wall", Vector3(29.0, 0, z), r, r, h, 16)
		lm.frustum("White", Vector3(29.0, h, z), r + 0.4, r + 0.4, 0.5, 16)
		lm.lathe("Roof", Vector3(29.0, h + 0.5, z), LandmarkRbParts.dome_profile(r + 0.2, r * 0.6, 5), 16)
	# Window rows and pilaster strips on the long walls and the west end.
	for sz in [-1.0, 1.0]:
		var out := Vector3(0, 0, sz)
		LandmarkRbParts.windows(lm, "Windows", Vector3(0, 0, sz * 19.55), Vector3.RIGHT, out, 2.8, 11, 5.0, 1.6, 4.6)
		LandmarkRbParts.windows(lm, "Windows", Vector3(0, 0, sz * 14.8), Vector3.RIGHT, out, 11.0, 9, 5.2, 1.6, 4.4)
		LandmarkRbParts.windows(lm, "Windows", Vector3(0, 0, sz * 8.55), Vector3.RIGHT, out, 19.0, 2, 24.0, 1.8, 4.0)
		LandmarkRbParts.windows(lm, "Windows", Vector3(0, 0, sz * 14.05), Vector3.RIGHT, out, 19.0, 3, 5.0, 1.8, 4.0)
		for i in 12:
			lm.box("White", Vector3((float(i) - 5.5) * 5.0, 4.7, sz * 19.55), Vector3(0.8, 9.0, 0.4))
	LandmarkRbParts.windows(lm, "Windows", Vector3(-29.3, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), 2.8, 7, 5.2, 1.8, 5.0)
	# Thirteen domes: the crossing, four on the body, four outer, three
	# over the central apses and one over the west porch.
	_dome(lm, "Wall", "Gilt", "Gilt", Vector3(0, 24.95, 0), 4.7, 7.5, 6.8, 4.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_dome(lm, "Wall", "Green", "Gilt", Vector3(sx * 12.5, 17.4, sz * 11.0), 3.2, 6.0, 5.2, 3.0)
			_dome(lm, "Wall", "Gilt", "Gilt", Vector3(sx * 20.5, 17.4, sz * 11.0), 2.6, 5.0, 4.4, 2.6)
	for z in [-11.5, 0.0, 11.5]:
		_dome(lm, "Wall", "Green", "Gilt", Vector3(29.0, 17.4 if z == 0.0 else 13.4, z), 2.4, 3.0, 4.0, 2.2)
	_dome(lm, "Wall", "Gilt", "Gilt", Vector3(-24.0, 17.4, 0), 2.6, 5.0, 4.4, 2.6)
	_sophia_tower(lm, Vector3(43.1, 0, -56.4))
	lm.commit(model)

## The four-tier baroque bell tower (square tiers, octagon, gilded dome).
static func _sophia_tower(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Plinth", c + Vector3(0, 0.5, 0), Vector3(19.0, 1.0, 19.0))
	lm.box("Wall", c + Vector3(0, 11.5, 0), Vector3(17.0, 21.0, 17.0))
	lm.box("White", c + Vector3(0, 22.0, 0), Vector3(18.4, 2.0, 18.4))
	lm.box("Wall", c + Vector3(0, 32.0, 0), Vector3(14.0, 18.0, 14.0))
	lm.box("White", c + Vector3(0, 41.5, 0), Vector3(15.4, 1.5, 15.4))
	lm.box("Wall", c + Vector3(0, 49.5, 0), Vector3(11.0, 14.0, 11.0))
	lm.box("White", c + Vector3(0, 57.0, 0), Vector3(12.4, 1.4, 12.4))
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		var right := Vector3.UP.cross(out)
		SEuUtil.opening(lm, "Windows", c + out * 8.55 + Vector3(0, 1.0, 0), right, Vector3.UP, 5.0, 11.0)
		for sgn in [-1.0, 1.0]:
			SEuUtil.opening(lm, "Windows", c + out * 7.05 + right * sgn * 2.8 + Vector3(0, 28.0, 0), right, Vector3.UP, 2.2, 8.0)
			SEuUtil.opening(lm, "Windows", c + out * 5.55 + right * sgn * 2.2 + Vector3(0, 45.0, 0), right, Vector3.UP, 1.8, 8.5)
	# Corner pilasters on the lowest tier, small gilded domes on the second.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("White", c + Vector3(sx * 8.0, 11.5, sz * 8.0), Vector3(1.2, 21.0, 1.2))
			lm.lathe("Gilt", c + Vector3(sx * 6.2, 42.4, sz * 6.2), LandmarkRbParts.dome_profile(1.1, 2.6, 4), 8)
	lm.frustum("Wall", c + Vector3(0, 57.7, 0), 4.6, 4.2, 5.5, 8, PI / 8.0)
	lm.frustum("White", c + Vector3(0, 63.2, 0), 4.9, 4.9, 0.6, 8, PI / 8.0)
	_pear(lm, "Gilt", c + Vector3(0, 63.8, 0), 4.6, 8.7)
	LandmarkRbParts.cross(lm, "Gilt", c + Vector3(0, 72.5, 0), SOPHIA_TOP - 72.5)

# --- Palace of the Parliament ---

## `n` plain window panes at height `y` along a wall face centred at `o`
## (ground), `out` the face normal.
static func _pane_row(lm: LandmarkMesh, o: Vector3, out: Vector3, y: float, n: int, pitch: float,
		w: float, h: float) -> void:
	var right := LandmarkRbParts.facing(out).x
	for i in n:
		var s := (float(i) - float(n - 1) * 0.5) * pitch
		LandmarkRbParts.pane(lm, "Windows", o + right * s + Vector3(0, y, 0), right, out, w, h)

const PARL_TOP := 84.0

## Origin at the footprint centre, the balcony front facing +Z (the real
## front looks east). Tiers of 38, 52, 66 and 68 m, four hipped corner
## pavilions and the 84 m dome over the central hall.
static func parliament(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DAD3C2", 5.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E9E4D6", 4.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8E8A80", 4.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#56626A", 4.0, 0.55, 0.25))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#7A8A94", 4.0, 0.3, 0.5))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	# Four stepped tiers round the central hall.
	var tiers := [[216.0, 168.0, 38.0], [172.0, 128.0, 52.0], [100.0, 84.0, 66.0], [52.0, 36.0, 68.0]]
	var low := 0.0
	for t in tiers:
		var h: float = float(t[2]) - low
		lm.box("Stone", Vector3(0, low + h * 0.5, 2.0), Vector3(float(t[0]), h, float(t[1])))
		lm.box("Trim", Vector3(0, float(t[2]) + 0.4, 2.0), Vector3(float(t[0]) + 2.0, 1.2, float(t[1]) + 2.0))
		low = float(t[2])
	lm.box("Roof", Vector3(0, 38.9, 2.0), Vector3(212.0, 0.4, 164.0))
	lm.box("Roof", Vector3(0, 52.9, 2.0), Vector3(168.0, 0.4, 124.0))
	lm.box("Roof", Vector3(0, 66.9, 2.0), Vector3(96.0, 0.4, 80.0))
	# Four corner pavilions with hipped roofs, joined to the main block.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(sx * 123.0, 0, sz * 100.0)
			lm.box("Stone", c + Vector3(0, 25.0, 0), Vector3(29.0, 50.0, 29.0))
			lm.box("Trim", c + Vector3(0, 50.4, 0), Vector3(31.0, 1.2, 31.0))
			LandmarkCeParts.hip(lm, "Roof", c + Vector3(0, 51.0, 0), 29.0, 29.0, 9.0)
			lm.box("Stone", Vector3(sx * 111.0, 18.9, sz * 93.0), Vector3(20.0, 37.8, 20.0))
			for k in 4:
				var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
				for y in [4.0, 17.0, 30.0]:
					SEuUtil.opening(lm, "Windows", c + out * 14.55 + Vector3(0, y, 0), Vector3.UP.cross(out), Vector3.UP, 3.0, 9.0)
	# Window rows on the three plain fronts of the lowest tier.
	for y in [3.0, 14.0, 25.0]:
		_pane_row(lm, Vector3(-77.0, 0, 86.05), Vector3(0, 0, 1), y, 14, 4.2, 2.6, 8.0)
		_pane_row(lm, Vector3(77.0, 0, 86.05), Vector3(0, 0, 1), y, 14, 4.2, 2.6, 8.0)
		_pane_row(lm, Vector3(0, 0, -82.05), Vector3(0, 0, -1), y, 50, 4.2, 2.6, 8.0)
		for sx in [-1.0, 1.0]:
			_pane_row(lm, Vector3(sx * 108.05, 0, 2.0), Vector3(sx, 0, 0), y, 38, 4.2, 2.6, 8.0)
	_pane_row(lm, Vector3(0, 0, 66.05), Vector3(0, 0, 1), 41.0, 36, 4.2, 2.6, 8.0)
	_pane_row(lm, Vector3(0, 0, 44.05), Vector3(0, 0, 1), 55.0, 20, 4.2, 2.6, 8.0)
	_pane_row(lm, Vector3(0, 0, -40.05), Vector3(0, 0, -1), 55.0, 20, 4.2, 2.6, 8.0)
	# Central front block: arcaded base, balcony loggia of square pillars.
	lm.box("Stone", Vector3(0, 13.0, 93.0), Vector3(92.0, 26.0, 14.0))
	lm.box("Trim", Vector3(0, 26.4, 93.0), Vector3(94.0, 1.0, 16.0))
	for i in 11:
		SEuUtil.opening(lm, "Windows", Vector3((float(i) - 5.0) * 7.6, 1.0, 100.05), Vector3.RIGHT, Vector3.UP, 4.6, 16.0)
	for i in 12:
		lm.box("Trim", Vector3((float(i) - 5.5) * 7.6, 34.0, 98.5), Vector3(2.2, 14.0, 2.2))
	lm.box("Trim", Vector3(0, 41.5, 93.0), Vector3(94.0, 3.0, 16.0))
	LandmarkRbParts.steps(lm, "Plinth", Vector3(0, 0, 101.0), Vector3(0, 0, 1), 104.0, 1.2, 0.3, 6)
	# Dome over the central hall.
	lm.frustum("Stone", Vector3(0, 68.0, 2.0), 22.0, 22.0, 4.0, 32)
	lm.frustum("Trim", Vector3(0, 72.0, 2.0), 22.8, 22.8, 0.6, 32)
	lm.lathe("Dome", Vector3(0, 72.6, 2.0), LandmarkRbParts.dome_profile(21.0, PARL_TOP - 72.6, 8), 32)
	lm.commit(model)
