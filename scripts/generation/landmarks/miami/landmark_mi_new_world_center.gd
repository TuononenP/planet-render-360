class_name LandmarkMiNewWorldCenter
extends RefCounted

## New World Center (Frank Gehry, 2011) - MI-4B.
## Site: way 277037894 (25.791678, -80.133445, yaw_deg 88.5), footprint 90.8 x 43.6 m,
## height_m = 31.0. Crisp white stucco rectilinear hall with a 31.0 m stage-house, a
## 30 x 21 m SoundScape projection wall on the east (park) face with a soft night
## WallLamp glow, a south / east slanted glass curtain atrium revealing tumbling white and
## titanium acoustic sails, a rooftop pergola garden and slender audio-light towers.

const HEIGHT_M := 31.0
const HW := 45.4
const HD := 21.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#F6F5F0", 4.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#CFCBC2", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#3A5666"))
	lm.use("Sail", LandmarkMaterials.paint("#EDEEF0", 0.35, 0.5))
	lm.use("Titanium", LandmarkMaterials.paint("#C9CED2", 0.3, 0.85))
	lm.use("Steel", LandmarkMaterials.paint("#8A9298", 0.45, 0.7))
	lm.use("Planter", LandmarkMaterials.paint("#5E8C3E", 0.9, 0.0))
	lm.use("WallWhite", LandmarkMaterials.paint("#FBFBF8", 0.6, 0.05))
	lm.use("WallLamp", LandmarkMaterials.lit("#7FB8FF", 0.35))
	_masses(lm)
	_atrium(lm)
	_sails(lm)
	_roof(lm)
	lm.commit(model)
	var cool := Color(0.70, 0.82, 1.0)
	var warm := Color(1.0, 0.82, 0.55)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(62.0, 2.0, -6.8), Vector3(45.4, 12.0, -6.8), 52.0, 1.0, 40.0, cool],
		[Vector3(30.0, 2.0, 40.0), Vector3(28.0, 10.0, 21.8), 60.0, 1.0, 36.0, warm],
		[Vector3(-26.0, 2.0, 36.0), Vector3(-26.0, 16.0, 21.8), 60.0, 0.8, 44.0, cool],
	])

static func _masses(lm: LandmarkMesh) -> void:
	lm.box("Concrete", Vector3(0.0, -0.15, 0.0), Vector3(2.0 * HW, 0.3, 2.0 * HD), Basis(), 0.0)
	# Main hall (west): x = -45.4..10, y = 0..22
	lm.box("Stucco", Vector3(-17.7, 11.0, 0.0), Vector3(55.4, 22.0, 2.0 * HD), Basis(), 0.05)
	# Stage-house screen rising to exactly 31.0 m
	lm.box("Stucco", Vector3(-26.0, 15.5, -4.0), Vector3(28.0, 31.0, 28.0), Basis(), 0.05)
	# East block carrying the SoundScape wall (x = 10..45.4, z = -21.8..8.2, y = 0..21)
	lm.box("Stucco", Vector3(27.7, 10.5, -6.8), Vector3(35.4, 21.0, 30.0), Basis(), 0.05)
	lm.box("Stucco", Vector3(45.55, 10.5, -6.8), Vector3(0.3, 21.0, 30.0), Basis(), 0.0)
	lm.box("WallWhite", Vector3(45.75, 10.5, -6.8), Vector3(0.1, 19.0, 28.0), Basis(), 0.0)
	lm.box("WallLamp", Vector3(45.82, 10.5, -6.8), Vector3(0.06, 18.6, 27.6), Basis(), 0.0)
	# Slot windows along the north face
	for k in 8:
		lm.box("Glass", Vector3(-40.0 + 11.0 * float(k), 8.0, -HD - 0.05), Vector3(1.2, 9.0, 0.12), Basis(), 0.0)

static func _atrium(lm: LandmarkMesh) -> void:
	# South slanted glass curtain wall (z = 21.8 at the floor leaning in to z = 14 at y = 20)
	lm.quad("Glass", Vector3(10.0, 0.0, 21.8), Vector3(45.4, 0.0, 21.8), Vector3(45.4, 20.0, 14.0),
		Vector3(10.0, 20.0, 14.0), Vector3(0.0, 0.37, 0.93))
	# East slanted glass curtain wall
	lm.quad("Glass", Vector3(45.4, 0.0, 21.8), Vector3(45.4, 0.0, 8.2), Vector3(38.5, 20.0, 8.2),
		Vector3(38.5, 20.0, 21.8), Vector3(0.94, 0.33, 0.0))
	lm.box("Stucco", Vector3(27.7, 20.2, 15.0), Vector3(35.4, 0.6, 13.6), Basis(), 0.0)
	for k in 9:
		var x: float = 10.0 + 4.4 * float(k)
		lm.beam("Steel", Vector3(x, 0.0, 21.8), Vector3(x, 20.0, 14.0), 0.16, 0.16)
	for y: float in [6.0, 12.0]:
		var zf: float = 21.8 - 7.8 * (y / 20.0)
		lm.beam("Steel", Vector3(10.0, y, zf), Vector3(45.4, y, zf), 0.14, 0.14)

static func _sails(lm: LandmarkMesh) -> void:
	# Gehry's tumbling acoustic sails visible through the glass: stretched lathe shells
	var defs: Array = [
		["Sail", Vector3(17.0, 2.0, 15.5), 10.0, 5.5, 3.0, 0.4],
		["Titanium", Vector3(24.0, 5.0, 13.5), 9.0, 4.5, 3.2, -0.5],
		["Sail", Vector3(30.0, 3.0, 16.5), 12.0, 5.0, 3.4, 0.9],
		["Titanium", Vector3(36.0, 6.5, 13.0), 8.0, 4.0, 2.8, -0.2],
		["Sail", Vector3(21.0, 9.5, 12.0), 7.0, 5.5, 2.6, 0.2],
	]
	for d: Array in defs:
		var h: float = d[2]
		var prof := PackedVector2Array()
		for j in 9:
			var th: float = PI * float(j) / 8.0
			prof.append(Vector2(sin(th), 0.5 * h * (1.0 - cos(th))))
		lm.lathe(d[0], d[1], prof, 12, d[3], d[4], d[5])

static func _roof(lm: LandmarkMesh) -> void:
	# Rooftop garden terrace pergola on the hall roof (y = 22)
	for px: float in [-8.0, 8.0]:
		for pz: float in [-14.0, 14.0]:
			lm.beam("Steel", Vector3(px, 22.0, pz), Vector3(px, 25.4, pz), 0.3, 0.3)
	for k in 7:
		lm.box("Steel", Vector3(0.0, 25.5, -14.0 + 4.67 * float(k)), Vector3(17.0, 0.2, 0.3), Basis(), 0.0)
	lm.box("Planter", Vector3(0.0, 22.2, 0.0), Vector3(14.0, 0.4, 8.0), Basis(), 0.0)
	# SoundScape audio-light towers on the east block roof
	for x: float in [16.0, 24.0, 32.0, 40.0]:
		lm.beam("Titanium", Vector3(x, 21.0, -1.0), Vector3(x, 30.6, -1.0), 0.3, 0.3)
		lm.box("Titanium", Vector3(x, 28.0, -1.0), Vector3(1.0, 1.4, 0.5), Basis(), 0.0)
	lm.frustum("WallLamp", Vector3(40.0, 30.6, -1.0), 0.25, 0.1, 0.4, 8)
