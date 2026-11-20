class_name FtForumMarinum
extends RefCounted

## Forum Marinum Maritime Centre (Linnankatu 72: Kruununmakasiini 1936 Crown
## Granary, Linnanpuomi 1930s red-brick Harbour Customs & Exhibition Hall,
## Daphne Glass Display Pavilion, and open maritime yard with naval mines &
## anchor monument) in true metres (+X ENE along Linnankatu, +Z SSE toward
## Aurajoki & Suomen Joutsen quay, turned by yaw_deg = -34.0°):
##   - Measured from Linnankatu 72 (60.436800, 22.236150, LoD2 height 15.8 m,
##     gabled 21°, 2,318 m²).
##   - Kruununmakasiini (-X wing): monumental 1936 grey-granite & pale-concrete
##     Crown Granary (46 x 20 m, ridge 15.8 m) with heavy granite ashlar base,
##     rhythmic deep-set arched/industrial multi-pane windows, pitched dark-metal
##     gable roof with dormers & brick chimney.
##   - Linnanpuomi (+X wing): 1930s red-brick Harbour Customs & exhibition
##     building (38 x 18 m, ridge 14.6 m) with stepped brick parapet, arched
##     ground-floor carriage portals, pale stone stringcourses, and warm museum
##     interior glow.
##   - Daphne Pavilion (central glazed exhibition hall bridging the maritime
##     yard, housing Göran Schildt's ketch Daphne): steel-and-glass box with
##     timber soffit & warm night illumination.
##   - Open cobbled maritime courtyard with spherical naval mines on cradles,
##     historic admiralty anchor monument, and night floodlighting.
## Surfaces: 10 merged PBR parts (Granite, Concrete, Brick, Trim, Roof, Steel,
## Wood, Glass, DarkMetal, Lamp).

const FOUND := -1.8
const TOP_M := 15.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_kruununmakasiini(lm)
	_build_linnanpuomi(lm)
	_build_daphne_pavilion_and_yard(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7C7974", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("render", "#C9C4B8", 2.8))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#954635", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E4DFD4", 2.4))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#3F454A", 2.6, 0.52, 0.48))
	lm.use("Steel", LandmarkMaterials.paint("#2F353B", 0.42, 0.62))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#8F6A44", 2.2))
	lm.use("Glass", LandmarkMaterials.glass("#223644"))
	lm.use("DarkMetal", LandmarkMaterials.paint("#23272B", 0.48, 0.58))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE6B2", 1.5))

static func _build_kruununmakasiini(lm: LandmarkMesh) -> void:
	# Kruununmakasiini (1936 Crown Granary) on -X side (x = -44..2, z = -18..2, H = 15.8 m).
	LandmarkFrKit.rect(lm, "Granite", -44.6, 2.6, -18.6, 2.6, FOUND, 2.8)
	LandmarkFrKit.rect(lm, "Concrete", -44.0, 2.0, -18.0, 2.0, 2.8, 11.2)
	LandmarkFrKit.rect(lm, "Trim", -44.3, 2.3, -18.3, 2.3, 10.9, 11.5)
	lm.gable("Roof", Vector3(-21.0, 11.5, -8.0), 20.0, 46.0, 4.3, Basis(Vector3.UP, PI * 0.5), 0.4, "Concrete")
	# Rhythmic 3-storey industrial granary windows on river (+Z) & Linnankatu (-Z) fronts.
	for fz: float in [2.06, -18.06]:
		var s := 1.0 if fz > 0.0 else -1.0
		for k in 9:
			var wx := lerpf(-40.5, -1.5, float(k) / 8.0)
			# Ground-floor granite-framed arched loading portals on bays 2 & 6.
			if (k == 2 or k == 6) and s > 0.0:
				lm.box("Glass", Vector3(wx, 2.5, fz), Vector3(3.2, 3.6, 0.22))
				lm.box("Lamp", Vector3(wx, 2.4, fz - 0.35), Vector3(2.8, 3.2, 0.14))
			else:
				lm.box("Glass", Vector3(wx, 4.5, fz), Vector3(2.2, 2.4, 0.18))
			lm.box("Glass", Vector3(wx, 8.2, fz), Vector3(2.2, 2.4, 0.18))
			lm.box("Trim", Vector3(wx, 6.9, fz + 0.06 * s), Vector3(2.5, 0.18, 0.22))
			lm.box("Steel", Vector3(wx, 8.2, fz + 0.08 * s), Vector3(0.12, 2.4, 0.16))
			if k % 2 == 0:
				lm.box("Lamp", Vector3(wx, 8.2, fz - 0.30 * s), Vector3(1.8, 2.0, 0.12))
	# Three pitched roof dormers facing Aurajoki (+Z).
	for dx: float in [-34.0, -21.0, -8.0]:
		LandmarkFrKit.rect(lm, "Concrete", dx - 1.6, dx + 1.6, -2.5, 0.8, 12.2, 14.1)
		lm.gable("Roof", Vector3(dx, 14.1, -0.8), 3.2, 3.4, 1.1, Basis(), 0.2, "Concrete")
		lm.box("Glass", Vector3(dx, 13.1, 0.86), Vector3(2.0, 1.3, 0.16))

static func _build_linnanpuomi(lm: LandmarkMesh) -> void:
	# Linnanpuomi (1930s red-brick Harbour Customs & exhibition hall) on +X side (x = 12..50, z = -16..4).
	LandmarkFrKit.rect(lm, "Granite", 11.5, 50.5, -16.5, 4.5, FOUND, 2.0)
	LandmarkFrKit.rect(lm, "Brick", 12.0, 50.0, -16.0, 4.0, 2.0, 10.8)
	LandmarkFrKit.rect(lm, "Trim", 11.8, 50.2, -16.2, 4.2, 5.8, 6.2)
	LandmarkFrKit.rect(lm, "Trim", 11.7, 50.3, -16.3, 4.3, 10.5, 11.1)
	lm.gable("Roof", Vector3(31.0, 11.1, -6.0), 20.0, 38.0, 3.6, Basis(Vector3.UP, PI * 0.5), 0.4, "Brick")
	# Tall brick-framed exhibition bays & museum entrance canopy on +Z (river side).
	for fz: float in [4.06, -16.06]:
		var s := 1.0 if fz > 0.0 else -1.0
		for k in 8:
			var wx := lerpf(15.2, 46.8, float(k) / 7.0)
			lm.box("Glass", Vector3(wx, 4.0, fz), Vector3(2.3, 2.8, 0.18))
			lm.box("Glass", Vector3(wx, 8.2, fz), Vector3(2.3, 2.5, 0.18))
			lm.box("Lamp", Vector3(wx, 4.0, fz - 0.30 * s), Vector3(1.9, 2.3, 0.12))
			lm.box("Steel", Vector3(wx, 4.0, fz + 0.08 * s), Vector3(0.12, 2.8, 0.16))
	# Steel-and-glass main Forum Marinum entrance canopy on +Z.
	LandmarkFrKit.rect(lm, "Steel", 24.0, 38.0, 4.0, 8.5, 4.6, 5.05)
	LandmarkFrKit.rect(lm, "Lamp", 25.5, 36.5, 5.5, 7.2, 4.48, 4.62)

static func _build_daphne_pavilion_and_yard(lm: LandmarkMesh) -> void:
	# Open cobbled maritime courtyard linking Kruununmakasiini & Linnanpuomi to the quay.
	LandmarkFrKit.rect(lm, "Granite", -46.0, 52.0, 2.0, 22.0, FOUND, 0.35)
	# Daphne Glass Display Pavilion (x = -4..14, z = 4..18, H = 7.4 m) housing Göran Schildt's ketch Daphne.
	LandmarkFrKit.rect(lm, "Concrete", -4.5, 14.5, 3.5, 18.5, FOUND, 0.65)
	LandmarkFrKit.rect(lm, "Glass", -4.0, 14.0, 4.0, 18.0, 0.65, 6.6)
	LandmarkFrKit.rect(lm, "Wood", -4.2, 14.2, 3.8, 18.2, 6.45, 6.80)
	LandmarkFrKit.rect(lm, "Roof", -4.6, 14.6, 3.4, 18.6, 6.80, 7.35)
	# Warm illuminated interior showcasing the wooden sailboat silhouette inside Daphne Pavilion.
	LandmarkFrKit.rect(lm, "Lamp", -2.8, 12.8, 5.5, 16.5, 5.8, 6.35)
	lm.box("Wood", Vector3(5.0, 2.1, 11.0), Vector3(10.5, 1.4, 2.6))
	lm.beam("Wood", Vector3(5.5, 2.8, 11.0), Vector3(5.5, 6.2, 11.0), 0.16, 0.16)
	# Perimeter steel mullions around Daphne Pavilion.
	for k in 6:
		var mx := lerpf(-3.8, 13.8, float(k) / 5.0)
		lm.box("Steel", Vector3(mx, 3.6, 18.08), Vector3(0.18, 6.0, 0.22))
		lm.box("Steel", Vector3(mx, 3.6, 3.92), Vector3(0.18, 6.0, 0.22))
	# Outdoor maritime exhibits in the yard: 3 spherical naval mines & historic admiralty anchor.
	for mx: float in [-26.0, -21.0, -16.0]:
		lm.frustum("Concrete", Vector3(mx, 0.35, 12.5), 0.9, 0.9, 0.45, 10)
		lm.lathe("DarkMetal", Vector3(mx, 0.80, 12.5), PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.65, 0.25), Vector2(0.75, 0.70), Vector2(0.55, 1.15), Vector2(0.0, 1.35)]), 12)
	# Historic giant black iron admiralty anchor on granite plinth (+X yard).
	lm.box("Granite", Vector3(31.0, 0.65, 14.5), Vector3(3.6, 0.7, 2.6))
	lm.beam("DarkMetal", Vector3(31.0, 1.0, 14.5), Vector3(31.0, 4.4, 14.5), 0.28, 0.28)
	lm.beam("DarkMetal", Vector3(29.4, 4.0, 14.5), Vector3(32.6, 4.0, 14.5), 0.22, 0.22)
	lm.beam("DarkMetal", Vector3(31.0, 1.2, 14.5), Vector3(29.3, 2.4, 14.5), 0.24, 0.24)
	lm.beam("DarkMetal", Vector3(31.0, 1.2, 14.5), Vector3(32.7, 2.4, 14.5), 0.24, 0.24)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-21.0, 2.0, 14.0), Vector3(-21.0, 8.5, 2.0), 60.0, 0.80, 38.0, Color(1.0, 0.88, 0.66)],
		[Vector3(31.0, 2.0, 16.0), Vector3(31.0, 8.0, 4.0), 58.0, 0.85, 38.0, Color(1.0, 0.84, 0.60)],
		[Vector3(5.0, 2.0, 24.0), Vector3(5.0, 4.0, 18.0), 56.0, 0.75, 30.0, Color(1.0, 0.90, 0.72)],
	])
