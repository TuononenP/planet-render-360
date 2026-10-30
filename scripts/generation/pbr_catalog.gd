class_name PbrCatalog
extends RefCounted

## Bundled photographic PBR sets: set name → Poly Haven asset id,
## linear-space mean albedo (measured at 64²), scalar roughness for the
## albedo-only path, and metallic. Paths are
## assets/textures/<set>_{diff,nor,rough}.jpg (1k, CC0 — see the
## data-source register). Glass is absent upstream (0 catalog hits for
## "glass"), so it is the one procedural set — see StoreyComposer.compose_glass.
## New textures change only this table, never the resolution code.
static var SETS := {
	"limestone": {"asset": "beige_wall_001", "mean": Color(0.3404, 0.2623, 0.1878), "rough": 0.88, "metal": 0.0},
	"stone": {"asset": "old_sandstone_02", "mean": Color(0.2498, 0.1399, 0.0489), "rough": 0.93, "metal": 0.0},
	"render": {"asset": "white_stucco", "mean": Color(0.6796, 0.6514, 0.6305), "rough": 0.94, "metal": 0.0},
	"brick": {"asset": "brick_wall_001", "mean": Color(0.1358, 0.0737, 0.0484), "rough": 0.90, "metal": 0.0},
	"concrete": {"asset": "concrete", "mean": Color(0.1715, 0.1470, 0.1060), "rough": 0.92, "metal": 0.0},
	"wood": {"asset": "brown_planks_03", "mean": Color(0.1521, 0.1309, 0.1047), "rough": 0.85, "metal": 0.0},
	"slate": {"asset": "grey_roof_tiles_02", "mean": Color(0.1897, 0.1964, 0.1927), "rough": 0.62, "metal": 0.08},
	"terracotta": {"asset": "clay_roof_tiles", "mean": Color(0.3325, 0.1070, 0.0513), "rough": 0.80, "metal": 0.0},
	"membrane": {"asset": "bitumen", "mean": Color(0.0433, 0.0375, 0.0347), "rough": 0.95, "metal": 0.0},
	"asphalt": {"asset": "asphalt_01", "mean": Color(0.1002, 0.0798, 0.0619), "rough": 0.97, "metal": 0.0},
	"pavement": {"asset": "concrete_pavement", "mean": Color(0.2140, 0.1761, 0.1342), "rough": 0.95, "metal": 0.0},
	"grass": {"asset": "grass_ground", "mean": Color(0.1562, 0.1180, 0.0482), "rough": 0.97, "metal": 0.0},
	"rock": {"asset": "brown_mud_rocks_01", "mean": Color(0.0854, 0.0639, 0.0380), "rough": 0.97, "metal": 0.0},
	# Terrain sets (ground and far-ring shaders): cliff faces, forest
	# floor, mown lawn, gravel/scree, beach sand, snow.
	"cliff": {"asset": "rock_face_03", "mean": Color(0.2296, 0.1433, 0.0823), "rough": 0.92, "metal": 0.0},
	"forest": {"asset": "forest_leaves_02", "mean": Color(0.2789, 0.1666, 0.0465), "rough": 0.97, "metal": 0.0},
	"lawn": {"asset": "leafy_grass", "mean": Color(0.3113, 0.2295, 0.1011), "rough": 0.96, "metal": 0.0},
	"gravel": {"asset": "gravel_floor", "mean": Color(0.3627, 0.2382, 0.1302), "rough": 0.95, "metal": 0.0},
	"sand": {"asset": "coast_sand_01", "mean": Color(0.2236, 0.1706, 0.1067), "rough": 0.96, "metal": 0.0},
	"snow": {"asset": "snow_02", "mean": Color(0.3786, 0.3782, 0.3883), "rough": 0.7, "metal": 0.0},
}
