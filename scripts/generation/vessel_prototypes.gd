class_name VesselPrototypes
extends RefCounted

## Ten-metre prototype meshes for the Ultra MultiMeshes (marina fleets and
## quay-side steamers). Kinds: "motor" (sport cruiser), "yacht" (flybridge),
## "sail", "catamaran", "day" (runabout / console),
## "rib" (marina, origin at the stern) and "steam", "houseboat" (quay,
## origin amidships), each with a "_far" variant that drops the fittings
## (rails, mullions, rigging) for boats beyond MarinaBuilder.NEAR_M. +X bow.

const KINDS := ["motor", "yacht", "sail", "day", "rib", "steam", "houseboat", "catamaran"]
const LEN_M := 10.0
const STERN_ORIGIN := ["motor", "yacht", "sail", "day", "rib", "catamaran"]
static var _meshes := {}

static func base_kind(kind: String) -> String:
	return kind.trim_suffix("_far")

## The LandmarkMesh for a model at true size. `model` is one of liner,
## passenger, houseboat, tall_ship, motor_yacht, runabout, sail_yacht.
static func geometry(model: String, length: float, beam: float, h: float, hull: Material,
		detail: bool, maps: bool, seed_value: float = 0.0, variant: String = "") -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	var p := {"length": length, "beam": beam, "height": h, "hull": hull, "detail": detail,
		"maps": maps, "seed": seed_value, "ultra": detail and MaterialLibrary.hi_res}
	match model:
		"liner":
			p["ferry"] = variant == "ferry"
			CruiseLinerModel.build(lm, p)
		"houseboat", "tall_ship":
			p["variant"] = model
			PassengerVesselModel.build(lm, p)
		"motor_yacht", "runabout":
			p["variant"] = variant if variant != "" else MotorYachtModel.variant_for(
				length if model == "motor_yacht" else minf(length, 8.9), fposmod(seed_value, 1.0))
			MotorYachtModel.build(lm, p)
		"catamaran":
			CatamaranModel.build(lm, p)
		"sail_yacht":
			SailYachtModel.build(lm, p)
		_:
			PassengerVesselModel.build(lm, p)
	return lm

static func mesh(kind: String) -> ArrayMesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var base := base_kind(kind)
	var detail := not kind.ends_with("_far")
	var lm: LandmarkMesh
	match base:
		"motor":
			lm = geometry("motor_yacht", LEN_M, 0.0, 0.0, VesselMaterials.get_mat("hull_instance"), detail, true, 0.95, "sport")
		"yacht":
			lm = geometry("motor_yacht", LEN_M, 0.0, 0.0, VesselMaterials.get_mat("hull_instance"), detail, true, 0.95, "flybridge")
		"sail":
			lm = geometry("sail_yacht", LEN_M, 0.0, 0.0, VesselMaterials.get_mat("hull_instance"), detail, true)
		"day":
			lm = geometry("runabout", LEN_M, 0.0, 0.0, VesselMaterials.get_mat("hull_instance"), detail, true, 0.7)
		"rib":
			lm = geometry("runabout", LEN_M, 0.0, 0.0, VesselMaterials.get_mat("hull_instance"), detail, true, 0.1)
		"catamaran":
			lm = geometry("catamaran", LEN_M, 0.0, 0.0, VesselMaterials.get_mat("hull_instance"), detail, true)
		"houseboat":
			lm = geometry("houseboat", LEN_M, 3.0, 3.0, VesselMaterials.paint("#4a5a63"), detail, true)
		_:
			lm = geometry("passenger", LEN_M, 2.6, 3.4, VesselMaterials.paint("#2d3b4a"), detail, true)
	var holder := Node3D.new()
	var out := ArrayMesh.new()
	var shift := LEN_M * 0.5 if base in STERN_ORIGIN else 0.0
	var grouped := {}
	for part in lm.commit(holder):
		var arrays := part.mesh.surface_get_arrays(0)
		if shift != 0.0:
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for i in v.size():
				v[i] += Vector3(shift, 0, 0)
			arrays[Mesh.ARRAY_VERTEX] = v
		var material := part.mesh.surface_get_material(0)
		if not detail:
			# Distant fittings share a compact palette. Painted topsides keep
			# their own material so instance colour never tints glass or decks.
			if part.name in ["White", "Deck", "DeckSteel", "Sail", "Canvas", "Roof"]:
				material = VesselMaterials.get_mat("white")
			elif part.name not in ["Hull", "Glass"]:
				material = VesselMaterials.get_mat("glass")
		elif part.name in ["Bottom", "Black"]:
			material = VesselMaterials.get_mat("dark")
		elif base in ["day", "rib"] and part.name == "Deck":
			material = VesselMaterials.get_mat("white")
		if grouped.has(material):
			var target: Array = grouped[material]
			for slot in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_TEX_UV]:
				var values = target[slot]
				values.append_array(arrays[slot])
				target[slot] = values
		else:
			grouped[material] = arrays
	for source in grouped:
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, grouped[source])
		var material: Material = source
		if RoofVariety.is_roof(material):
			var snow := StreetSnow.material(material as StandardMaterial3D)
			snow.set_shader_parameter("use_vertex", false)
			material = snow
		out.surface_set_material(out.get_surface_count() - 1, material)
	holder.free()
	_meshes[kind] = out
	return out

## Wraps snow-receiving surfaces of committed `parts` (single-instance
## vessels outside the building pipeline) in the live snow shader.
static func snow_parts(parts: Array) -> void:
	for part in parts:
		var m := (part as MeshInstance3D).mesh
		var material := m.surface_get_material(0)
		if RoofVariety.is_roof(material):
			var snow := StreetSnow.material(material as StandardMaterial3D)
			snow.set_shader_parameter("use_vertex", false)
			m.surface_set_material(0, snow)
