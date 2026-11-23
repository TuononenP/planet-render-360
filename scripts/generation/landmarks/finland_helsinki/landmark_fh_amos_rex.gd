extends RefCounted

## Amos Rex (JKMM Architects, 2018), the five asymmetric paver-clad concrete
## light-scoop cones on Lasipalatsi Square that light the underground galleries.
##
## Each scoop rises asymmetrically from the plaza paver grid and tilts forward
## toward an inclined circular steel-and-glass oculus skylight with warm
## interior gallery glow at night. Height 6.35 m, within clear_m 43.0 m.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "amos_rex", "name": "Amos Rex", "lat": 60.17008, "lon": 24.93604,
	"radius_m": 1500.0, "wiki_title": "Amos Rex", "height_m": 6.35, "clear_m": 43.0,
	"yaw_deg": -3.0, "kind": "Museum", "aliases": ["amos rex", "amos rex museum", "amos rex museo"]}

## [cx, cz, base_r, h, oculus_r, tilt_dir_x, tilt_dir_z, lean_m, oculus_tilt_deg]
const SCOOPS := [
	[-18.0, -11.0, 10.2, 4.85, 1.85, 0.85, 0.52, 3.2, 22.0],
	[5.5, -13.0, 9.2, 4.15, 1.75, -0.55, 0.83, 2.8, 20.0],
	[20.0, 5.5, 7.2, 3.10, 1.50, -0.90, -0.44, 2.1, 18.0],
	[-1.5, 10.5, 11.4, 5.12, 2.10, 0.72, -0.69, 3.6, 24.0],
	[-23.0, 13.0, 6.4, 2.75, 1.35, 0.92, -0.39, 1.8, 17.0],
]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", "#B8B7B2", 0.85))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9E9D98", 1.1))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", "#D8D6CE", 1.2, 0.4, 0.45))
	lm.use("Glass", LandmarkMaterials.glass("#3B5560"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 0.65))
	_plaza_grid(lm)
	for s in SCOOPS:
		_build_scoop(lm, s)
	lm.commit(model)
	var warm := Color(1.0, 0.89, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-28.0, 0.8, -20.0), Vector3(-16.0, 4.0, -10.0), 55.0, 0.8, 35.0, warm],
		[Vector3(18.0, 0.8, -22.0), Vector3(5.0, 3.8, -12.0), 55.0, 0.8, 35.0, warm],
		[Vector3(28.0, 0.8, 16.0), Vector3(18.0, 3.0, 5.0), 50.0, 0.7, 30.0, warm],
		[Vector3(-12.0, 0.8, 23.0), Vector3(-1.0, 5.2, 10.0), 55.0, 1.0, 38.0, warm],
		[Vector3(-30.0, 0.8, 22.0), Vector3(-22.0, 2.6, 13.0), 50.0, 0.7, 28.0, warm],
	])

static func _plaza_grid(lm: LandmarkMesh) -> void:
	U.blk(lm, "Stone", 0.0, 0.0, 0.0, 67.0, 0.16, 53.0)
	# Concrete paver expansion-joint grid across Lasipalatsi Square.
	for ix in range(-30, 31, 6):
		lm.box("Trim", Vector3(float(ix), 0.165, 0.0), Vector3(0.08, 0.02, 52.6), Basis(), 0.0)
	for iz in range(-24, 25, 6):
		lm.box("Trim", Vector3(0.0, 0.165, float(iz)), Vector3(66.6, 0.02, 0.08), Basis(), 0.0)
	# Perimeter granite seating kerbs along the square edges.
	for sz in [-25.6, 25.6]:
		U.blk(lm, "Trim", 0.0, 0.16, sz, 64.0, 0.28, 0.8)

static func _build_scoop(lm: LandmarkMesh, s: Array) -> void:
	var cx: float = s[0]
	var cz: float = s[1]
	var r0: float = s[2]
	var h: float = s[3]
	var r_oc: float = s[4]
	var dir := Vector2(float(s[5]), float(s[6])).normalized()
	var lean: float = s[7]
	var tilt := deg_to_rad(float(s[8]))
	var base := Vector3(cx, 0.16, cz)
	var axis := Vector3(dir.x * sin(tilt), cos(tilt), dir.y * sin(tilt)).normalized()
	var u_ax := axis.cross(Vector3.UP if absf(axis.y) < 0.99 else Vector3.RIGHT).normalized()
	var v_ax := axis.cross(u_ax).normalized()
	var seg_r := 18
	var seg_a := 48
	var rings: Array = []
	for j in seg_r + 1:
		var t := float(j) / float(seg_r)
		var ring := PackedVector3Array()
		var rad := lerpf(r0, r_oc, pow(t, 0.82))
		var off := dir * (lean * pow(t, 0.9))
		var yc := h * sin(t * PI * 0.5)
		var tilt_blend := pow(t, 1.4) * tilt
		var ring_ax := Vector3(dir.x * sin(tilt_blend), cos(tilt_blend), dir.y * sin(tilt_blend)).normalized()
		var ru := ring_ax.cross(Vector3.FORWARD if absf(ring_ax.z) < 0.9 else Vector3.RIGHT).normalized()
		var rv := ring_ax.cross(ru).normalized()
		var c := base + Vector3(off.x, yc, off.y)
		for k in seg_a + 1:
			var a := TAU * float(k) / float(seg_a)
			var pt := c + (ru * cos(a) + rv * sin(a)) * rad
			pt.y = maxf(pt.y, 0.16)
			ring.append(pt)
		rings.append(ring)
	lm.grid("Wall", rings, base + Vector3(0, -1.5, 0), true)
	# Inclined circular steel-and-glass oculus collar + recessed gallery glow.
	var top_c := base + Vector3(dir.x * lean, h, dir.y * lean)
	var oc_basis := Basis(u_ax, axis, v_ax)
	var collar := LandmarkMesh.new()
	collar.use("Trim", null)
	collar.use("Glass", null)
	collar.use("Lamp", null)
	collar.lathe("Trim", Vector3.ZERO, PackedVector2Array([
		Vector2(r_oc + 0.12, -0.05), Vector2(r_oc + 0.16, 0.16),
		Vector2(r_oc - 0.12, 0.22), Vector2(r_oc - 0.16, 0.02)]), seg_a, 1.0, 1.0, 0.0, true, false)
	collar.disc("Glass", Vector3(0, 0.14, 0), Vector3.UP, r_oc - 0.12, seg_a)
	collar.disc("Lamp", Vector3(0, 0.04, 0), Vector3.UP, r_oc - 0.22, seg_a)
	lm.merge(collar, Transform3D(oc_basis, top_c))
