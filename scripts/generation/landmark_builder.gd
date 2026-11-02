class_name LandmarkBuilder
extends RefCounted

## On-the-fly landmark models (no downloaded assets). Every registry
## type from LocationData.landmarks() and every OSM archetype is built
## in TRUE METRES under a "Model" child whose single uniform scale is
## WorldScale.metres_to_units() (0.25 under the T1.2 equivalence flag,
## 1.0 after the metre cutover), so the models need no change at the
## cutover and the placement code (TerrainBuilder._landmark, T5.2) can
## position/scale the root freely. Geometry is merged per material per
## part (LandmarkMesh) with calibrated photographic PBR materials
## (LandmarkMaterials); each complex landmark lives in its own class.
## Root sits at ground level (y=0).

const ARCHETYPES := ["church", "cathedral", "castle", "lighthouse", "stadium",
	"mosque", "temple", "windmill", "tower", "big_wheel"]

## Region batches of bespoke landmarks, tried in order for a type the
## core match above does not know (LandmarkSet*.build returns false for
## a type it does not own).
static func region_sets() -> Array[Callable]:
	return LandmarkRegistries.sets()

## Builds `type` from the first region set that owns it.
static func build_bespoke(model: Node3D, type: String) -> bool:
	for set_build in region_sets():
		if set_build.call(model, type):
			return true
	return false

## True when `type` has a hand-built model (not the archetype fallback).
static func is_bespoke(type: String) -> bool:
	var probe := Node3D.new()
	var ok := build_bespoke(probe, type)
	probe.free()
	return ok

## The metre-space child every landmark model is built under.
static func model_root(root: Node3D) -> Node3D:
	var model := Node3D.new()
	model.name = "Model"
	model.scale = Vector3.ONE * WorldScale.metres_to_units()
	root.add_child(model)
	return model

static func build(type: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Landmark_%s" % type
	var model := model_root(root)
	match type:
		"eiffel": LandmarkEiffel.build(model)
		"tokyo": LandmarkTokyo.build(model)
		"big_ben": LandmarkWestminster.build(model)
		"colosseum": LandmarkColosseum.build(model)
		"sagrada": LandmarkSagrada.build(model)
		"pyramid": LandmarkMonuments.giza(model)
		"statue_liberty": LandmarkMonuments.liberty(model)
		"sydney_opera": LandmarkOpera.build(model)
		"turku_cathedral": LandmarkCathedrals.turku(model)
		"helsinki_cathedral": LandmarkCathedrals.helsinki(model)
		"burj_khalifa": LandmarkBurj.build(model)
		"one_wtc": LandmarkNycTowers.one_wtc(model)
		"empire_state": LandmarkNycTowers.empire_state(model)
		"salute": LandmarkSalute.build(model)
		"monte_carlo_casino": LandmarkCasino.build(model)
		"gwanghwamun": LandmarkGwanghwamun.build(model)
		"banff_springs": LandmarkBanff.build(model)
		"stockholm_city_hall": LandmarkStockholm.build(model)
		"riddarholmen": LandmarkStockholm.riddarholmen(model)
		"golden_gate": LandmarkSuspensionBridges.golden_gate(model)
		"brooklyn_bridge": LandmarkSuspensionBridges.brooklyn(model)
		"tower_bridge": LandmarkTowerBridge.build(model)
		"sydney_harbour_bridge": LandmarkArchBridges.harbour(model)
		"bixby_creek_bridge": LandmarkArchBridges.bixby(model)
		_:
			if build_bespoke(model, type):
				pass
			elif type in ARCHETYPES:
				LandmarkArchetypes.build(model, type, 45.0, Vector2(120.0, 120.0))
			else:
				LandmarkArchetypes.build(model, "tower", 120.0, Vector2(24.0, 24.0))
	return root

## On-the-fly archetype for any OSM-tagged feature (OsmFetcher.
## archetype_for), built at the feature's real height and footprint
## (height in metres; footprint in current internal units, converted
## back to metres here — contract §7 V7/V19, true footprint_m in T5.2).
## `region` (ArchitectureStyle.region_for) dresses it in the regional
## wall set, stone/roof colours and tower style; "" keeps the neutral
## limestone/slate look. Height 20–184 m, footprint 24–240 m.
static func build_archetype(archetype: String, height_m: float, footprint: Vector2,
		region: String = "") -> Node3D:
	var root := Node3D.new()
	root.name = "Landmark_%s" % archetype
	var model := model_root(root)
	var to_m := 1.0 / WorldScale.metres_to_units()
	var size := Vector2(clampf(footprint.x * to_m, 24.0, 240.0),
		clampf(footprint.y * to_m, 24.0, 240.0))
	LandmarkArchetypes.build(model, archetype, clampf(height_m, 20.0, 184.0), size, region)
	return root

## All MeshInstance3D parts of a landmark (under its Model node).
static func parts(root: Node3D) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			out.append(n as MeshInstance3D)
		stack.append_array(n.get_children())
	return out
