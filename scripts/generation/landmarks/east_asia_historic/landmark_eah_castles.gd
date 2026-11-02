class_name LandmarkEahCastles
extends RefCounted

## Japanese castle keeps in true metres: Osaka Castle (55 m: the white
## five-storey keep with a black top storey, verdigris copper roofs and
## gilt tigers and ridge ornaments on a 14.7 m stone base) and Matsumoto
## Castle (29.4 m: the black-and-white five-roof keep, its small keep and
## the open moon-viewing turret with red railings, the red bridge beside
## it). Fronts face south (+Z).

# --- Osaka Castle ---

const OSAKA_M := 55.0
const OSAKA_PLANS := [Vector2(28.0, 24.0), Vector2(24.8, 21.2), Vector2(21.6, 18.4),
	Vector2(18.4, 15.6), Vector2(15.2, 12.8)]
const OSAKA_WALLS := [6.0, 5.2, 4.8, 4.4, 4.8]
const OSAKA_RISES := [2.2, 2.0, 1.9, 1.8]

static func osaka(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F897D", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#F0ECE2", 3.0))
	lm.use("Black", LandmarkMaterials.paint("#1B1A19", 0.5, 0.0))
	lm.use("Copper", LandmarkMaterials.pbr("slate", "#4F8B72", 1.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	LandmarkEahParts.stone_base(lm, "Stone", Vector2.ZERO, Vector2(36.0, 31.0), -2.0, 14.7, Vector2(11.0, 9.0))
	var y := 14.7
	for i in 5:
		var w: Vector2 = OSAKA_PLANS[i]
		var h: float = OSAKA_WALLS[i]
		var top := i == 4
		lm.box("Black" if top else "Plaster", Vector3(0, y + h * 0.5, 0), Vector3(w.x, h, w.y))
		for s in [-1.0, 1.0]:
			for q in 3:
				lm.box("Shadow", Vector3((q - 1) * w.x * 0.3, y + h * 0.55, s * w.y * 0.5), Vector3(1.5, h * 0.5, 0.14))
			for q in 2:
				lm.box("Shadow", Vector3(s * w.x * 0.5, y + h * 0.55, (q - 0.5) * w.y * 0.4), Vector3(0.14, h * 0.5, 1.5))
			if top:
				# Gilt tigers and cranes on the black top storey.
				for q in [-1.0, 1.0]:
					lm.box("Gold", Vector3(q * w.x * 0.25, y + h * 0.5, s * (w.y * 0.5 + 0.08)), Vector3(3.0, 2.1, 0.16))
		y += h
		if not top:
			# Hip roof with crossed gables, as on Himeji's tiers.
			var c := Vector3(0, y, 0)
			LandmarkAeParts.hip_roof(lm, "Copper", c, w + Vector2(6.0, 5.0), w - Vector2(2.0, 1.8),
				OSAKA_RISES[i], 0.6)
			lm.gable("Copper", c, 8.0, w.y + 5.0, 2.4, Basis(), 0.8, "Plaster")
			lm.gable("Copper", c, 6.0, w.x + 6.0, 2.0, Basis(Vector3.UP, PI * 0.5), 0.8, "Plaster")
			y += OSAKA_RISES[i]
	# Great top roof (hip below, gable above), ridge roll, gilt shachi.
	var w4: Vector2 = OSAKA_PLANS[4]
	LandmarkEahParts.irimoya(lm, "Copper", "Plaster", Vector3(0, y, 0), w4 + Vector2(7.0, 6.0),
		Vector2(13.0, 9.0), 2.2, 3.0, 0.6)
	var ridge := y + 5.2
	LandmarkEahParts.slab(lm, "Copper", Vector3(-6.5, ridge, -0.5), Vector3(6.5, ridge + 0.4, 0.5))
	for s in [-1.0, 1.0]:
		LandmarkEahParts.horn(lm, "Gold", Vector3(s * 6.4, ridge + 0.2, 0), OSAKA_M - ridge - 0.2, -s, 0.45)
	lm.commit(model)

# --- Matsumoto Castle ---

const MATSUMOTO_M := 29.4

static func matsumoto(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#85807A", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EFEBE1", 3.0))
	lm.use("Black", LandmarkMaterials.paint("#1D1A18", 0.55, 0.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#3E4246", 1.5))
	lm.use("Red", LandmarkMaterials.paint("#B3261E", 0.55, 0.0))
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#5A4636", 2.0))
	# Main keep: five roofs, six floors, 29.4 m.
	var top := _keep(lm, Vector2.ZERO, Vector2(19.0, 16.5), 4.2,
		[Vector2(15.4, 12.8), Vector2(13.4, 11.0), Vector2(11.6, 9.8), Vector2(9.6, 8.4), Vector2(7.8, 6.8)],
		[4.0, 3.5, 2.5, 3.0, 3.2], [1.4, 1.4, 1.4, 1.3], 3.5, [0, 1, 3, 0, 0])
	lm.box("Tile", Vector3(0, top - 0.1, 0), Vector3(3.6, 0.4, 0.5))
	# Inui small keep to the north, joined by a covered passage.
	_keep(lm, Vector2(-3.0, -17.0), Vector2(12.0, 10.4), 4.0,
		[Vector2(9.0, 7.6), Vector2(7.2, 6.2), Vector2(5.8, 5.0)], [3.6, 3.2, 3.0], [1.3, 1.2], 2.8, [1, 2, 0])
	LandmarkEahParts.slab(lm, "Black", Vector3(-6.5, 4.2, -12.6), Vector3(0.5, 6.4, -7.2))
	LandmarkEahParts.slab(lm, "Plaster", Vector3(-6.6, 6.0, -12.7), Vector3(0.6, 6.4, -7.1))
	LandmarkAeParts.hip_roof(lm, "Tile", Vector3(-3.0, 6.4, -9.9), Vector2(10.0, 8.0), Vector2(5.0, 1.2), 1.7, 0.4)
	# Tatsumi turret and the open Tsukimi (moon-viewing) pavilion to the east.
	LandmarkEahParts.stone_base(lm, "Stone", Vector2(11.4, 3.0), Vector2(9.4, 7.8), -2.0, 3.4, Vector2(2.6, 2.4))
	lm.box("Black", Vector3(11.4, 5.0, 3.0), Vector3(8.2, 3.2, 6.6))
	lm.box("Plaster", Vector3(11.4, 6.45, 3.0), Vector3(8.3, 0.4, 6.7))
	LandmarkAeParts.hip_roof(lm, "Tile", Vector3(11.4, 6.6, 3.0), Vector2(11.6, 9.6), Vector2(3.0, 1.6), 2.4, 0.5)
	LandmarkEahParts.stone_base(lm, "Stone", Vector2(19.6, 3.0), Vector2(8.6, 7.2), -2.0, 3.0, Vector2(2.4, 2.2))
	LandmarkEahParts.colonnade(lm, "Black", Vector2(19.6, 3.0), Vector2(7.6, 6.2), 3.0, 2.8, 3, 2, 0.14, 6)
	lm.box("Plaster", Vector3(19.6, 4.4, 3.0), Vector3(6.4, 2.3, 5.0))
	for s in [-1.0, 1.0]:
		lm.box("Red", Vector3(19.6, 3.9, 3.0 + s * 3.25), Vector3(8.0, 0.16, 0.14))
		lm.box("Red", Vector3(19.6 + s * 4.05, 3.9, 3.0), Vector3(0.14, 0.16, 6.5))
		lm.box("Red", Vector3(19.6, 3.45, 3.0 + s * 3.25), Vector3(8.0, 0.12, 0.12))
		lm.box("Red", Vector3(19.6 + s * 4.05, 3.45, 3.0), Vector3(0.12, 0.12, 6.5))
	LandmarkAeParts.hip_roof(lm, "Tile", Vector3(19.6, 5.8, 3.0), Vector2(10.6, 9.0), Vector2(3.0, 1.6), 2.3, 0.5)
	_red_bridge(lm, Vector3(36.0, 0.0, 9.0))
	lm.commit(model)

## A black-and-white keep centred at c on its stone base: stacked storeys
## (wall heights, plans) under hipped roofs, a white band at each wall
## head, dark windows, gables per roof (0 none, 1 north-south, 2 east-west,
## 3 both). Returns the ridge height.
static func _keep(lm: LandmarkMesh, c: Vector2, base: Vector2, base_h: float, plans: Array,
		walls: Array, rises: Array, top_rise: float, gables: Array) -> float:
	LandmarkEahParts.stone_base(lm, "Stone", c, base, -2.0, base_h, Vector2(5.0, 4.0))
	var y := base_h
	for i in plans.size():
		var w: Vector2 = plans[i]
		var h: float = walls[i]
		lm.box("Black", Vector3(c.x, y + h * 0.5, c.y), Vector3(w.x, h, w.y))
		lm.box("Plaster", Vector3(c.x, y + h - 0.35, c.y), Vector3(w.x + 0.1, 0.7, w.y + 0.1))
		for s in [-1.0, 1.0]:
			for q in 2:
				var wx := c.x + (q - 0.5) * w.x * 0.45
				lm.box("Plaster", Vector3(wx, y + h * 0.5, c.y + s * w.y * 0.5), Vector3(1.9, h * 0.6, 0.1))
				lm.box("Shadow", Vector3(wx, y + h * 0.5, c.y + s * w.y * 0.5), Vector3(1.1, h * 0.45, 0.16))
			lm.box("Plaster", Vector3(c.x + s * w.x * 0.5, y + h * 0.5, c.y), Vector3(0.1, h * 0.6, 1.9))
			lm.box("Shadow", Vector3(c.x + s * w.x * 0.5, y + h * 0.5, c.y), Vector3(0.16, h * 0.45, 1.1))
		y += h
		var eave := w + Vector2(3.6, 3.2)
		if i == plans.size() - 1:
			LandmarkAeParts.hip_roof(lm, "Tile", Vector3(c.x, y, c.y), eave, Vector2(w.x * 0.35, 1.0), top_rise, 0.5)
			y += top_rise
		else:
			var nxt: Vector2 = plans[i + 1]
			LandmarkAeParts.hip_roof(lm, "Tile", Vector3(c.x, y, c.y), eave, nxt + Vector2(0.6, 0.6), rises[i], 0.4)
			var g: int = gables[i]
			if g == 1 or g == 3:
				lm.gable("Tile", Vector3(c.x, y, c.y), 4.8, w.y + 3.2, 1.6, Basis(), 0.5, "Plaster")
			if g == 2 or g == 3:
				lm.gable("Tile", Vector3(c.x, y, c.y), 4.4, w.x + 3.6, 1.5, Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
			y += rises[i]
	return y

## The vermilion Uzume bridge over the moat, deck along X centred at c.
static func _red_bridge(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Red", Vector3(c.x, 0.15, c.z), Vector3(14.0, 0.5, 3.6))
	for s in [-1.0, 1.0]:
		lm.box("Red", Vector3(c.x, 1.0, c.z + s * 1.75), Vector3(14.0, 0.14, 0.14))
		lm.box("Red", Vector3(c.x, 1.55, c.z + s * 1.75), Vector3(14.0, 0.18, 0.18))
		for k in 11:
			lm.box("Red", Vector3(c.x - 6.5 + 1.3 * k, 0.9, c.z + s * 1.75), Vector3(0.2, 1.4, 0.2))
		for e in [-1.0, 1.0]:
			lm.box("Wood", Vector3(c.x + e * 6.4, -2.0, c.z + s * 1.4), Vector3(0.5, 4.2, 0.5))
			lm.box("Red", Vector3(c.x + e * 7.0, 1.0, c.z + s * 1.75), Vector3(0.3, 2.0, 0.3))
	lm.box("Stone", Vector3(c.x - 8.2, -1.2, c.z), Vector3(2.4, 3.0, 5.0))
	lm.box("Stone", Vector3(c.x + 8.2, -1.2, c.z), Vector3(2.4, 3.0, 5.0))
