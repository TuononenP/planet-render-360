class_name LandmarkLnSomersetWestminster
extends RefCounted

## Additional Batch A Thames & Westminster foreground landmarks (`LN-3.9`, `LN-3.11`,
## `LN-3.12`, `LN-3.13`):
## - `somerset_house`: William Chambers's 180 m Neoclassical Portland-stone river front
##   above Victoria Embankment (OSM way 372841786 — fixes `lv=2` under-height bug).
## - `methodist_central_hall`: Beaux-Arts 67 m lead-clad ribbed dome beside Westminster Abbey.
## - `lambeth_palace`: Tudor red-brick Morton's Tower gatehouse & Great Hall.
## - `cleopatras_needle`: 21 m pink granite Egyptian obelisk & bronze sphinxes.

static func somerset_house(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkLnKit.portland("#E0D9C8", 3.5))
	lm.use("Granite", LandmarkLnKit.granite("#8C877F", 3.2))
	lm.use("Slate", LandmarkLnKit.welsh_slate("#4C545C", 2.4))
	lm.use("Lead", LandmarkMaterials.paint("#5A626A", 0.5, 0.35))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	var w := 176.0
	var d := 78.0
	# Rusticated river terrace & great water-gate arcade facing the Thames (+Z)
	lm.box("Granite", Vector3(0.0, 3.8, d * 0.5 - 6.0), Vector3(w, 7.6, 16.0))
	lm.box("Stone", Vector3(0.0, 7.8, d * 0.5 - 6.0), Vector3(w + 1.6, 0.8, 17.0))
	# South river range + east/west/north courtyard wings
	lm.box("Stone", Vector3(0.0, 15.0, d * 0.5 - 12.0), Vector3(w, 14.4, 18.0))
	lm.box("Stone", Vector3(0.0, 14.0, -d * 0.5 + 10.0), Vector3(w - 12.0, 16.0, 18.0))
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(float(sx) * (w * 0.5 - 10.0), 14.0, 0.0), Vector3(18.0, 16.0, d - 10.0))
	# Central pedimented pavilion & shallow Neoclassical lead dome (top = 28.0 m)
	LandmarkLnKit.colonnade_x(lm, "Stone", -14.0, 14.0, 8.2, d * 0.5 - 2.6, 8, 12.2, 0.55)
	LandmarkLnKit.pediment_z(lm, "Stone", 0.0, 21.6, d * 0.5 - 2.6, 30.0, 3.8, 2.0)
	lm.frustum("Stone", Vector3(0.0, 22.2, d * 0.5 - 11.0), 6.5, 6.2, 2.2, 16)
	lm.frustum("Lead", Vector3(0.0, 24.4, d * 0.5 - 11.0), 6.2, 0.5, 3.6, 16)
	# River-front windows
	for i in 22:
		var wx := lerpf(-w * 0.46, w * 0.46, float(i) / 21.0)
		for wy in [11.5, 17.5]:
			lm.box("Glass", Vector3(wx, float(wy), d * 0.5 - 2.9), Vector3(2.2, 3.4, 0.14))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-48.0, 4.0, d * 0.5 + 12.0), Vector3(-48.0, 18.0, d * 0.5 - 4.0), 64.0, 0.85, 60.0],
		[Vector3(0.0, 4.0, d * 0.5 + 12.0), Vector3(0.0, 20.0, d * 0.5 - 4.0), 66.0, 0.95, 60.0],
		[Vector3(48.0, 4.0, d * 0.5 + 12.0), Vector3(48.0, 18.0, d * 0.5 - 4.0), 64.0, 0.85, 60.0],
	])

static func methodist_central_hall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkLnKit.portland("#DDD6C4", 3.4))
	lm.use("Lead", LandmarkMaterials.paint("#525B63", 0.52, 0.35))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Grand Beaux-Arts square Portland-stone hall (52 m x 52 m x 28 m)
	lm.box("Stone", Vector3(0.0, 14.0, 0.0), Vector3(52.0, 28.0, 52.0))
	lm.box("Stone", Vector3(0.0, 28.6, 0.0), Vector3(53.4, 1.2, 53.4))
	LandmarkLnKit.colonnade_x(lm, "Stone", -16.0, 16.0, 6.0, 26.8, 6, 17.5, 0.72)
	# Twin front corner Baroque turrets
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(float(sx) * 23.0, 32.0, 23.0), Vector3(6.8, 8.0, 6.8))
		lm.frustum("Lead", Vector3(float(sx) * 23.0, 36.0, 23.0), 3.2, 0.3, 5.5, 8)
	# Massive 27 m diameter lead-clad ribbed dome & lantern (top = 67.0 m)
	lm.frustum("Stone", Vector3(0.0, 28.5, 0.0), 14.2, 13.8, 7.5, 16)
	var prof := PackedVector2Array()
	for i in 9:
		var a := float(i) / 8.0 * PI * 0.5
		prof.append(Vector2(cos(a) * 13.6, sin(a) * 18.5))
	lm.lathe("Lead", Vector3(0.0, 36.0, 0.0), prof, 16)
	lm.frustum("Stone", Vector3(0.0, 54.0, 0.0), 3.6, 3.2, 5.5, 12)
	lm.frustum("Lead", Vector3(0.0, 59.5, 0.0), 3.2, 0.25, 6.2, 10)
	lm.box("Gilt", Vector3(0.0, 66.3, 0.0), Vector3(0.35, 1.4, 0.35))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 38.0), Vector3(0.0, 42.0, 0.0), 60.0, 0.9, 68.0],
	])

static func lambeth_palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkLnKit.red_brick("#944634", 2.8))
	lm.use("Stone", LandmarkLnKit.portland("#D8D0BE", 3.2))
	lm.use("Slate", LandmarkLnKit.welsh_slate("#495159", 2.2))
	lm.use("Glass", LandmarkMaterials.glass("#222B32"))
	# Morton's Tower (1495 Tudor red-brick gatehouse with twin octagonal turrets, 24.0 m)
	lm.box("Brick", Vector3(-18.0, 9.5, 14.0), Vector3(14.0, 19.0, 11.0))
	for sx in [-1.0, 1.0]:
		var tx := -18.0 + float(sx) * 7.2
		lm.frustum("Brick", Vector3(tx, 0.0, 16.5), 3.4, 3.3, 22.8, 8)
		lm.frustum("Stone", Vector3(tx, 22.8, 16.5), 3.6, 3.6, 1.2, 8)
	# Great Hall & Chapel range behind courtyard
	lm.box("Brick", Vector3(6.0, 7.5, -4.0), Vector3(44.0, 15.0, 18.0))
	lm.gable("Slate", Vector3(6.0, 15.0, -4.0), 17.5, 43.0, 5.5, Basis(Vector3.UP, PI * 0.5), 0.0, "Slate")
	lm.frustum("Slate", Vector3(6.0, 19.5, -4.0), 1.4, 0.2, 4.5, 8)
	for i in 7:
		var wx := lerpf(-12.0, 24.0, float(i) / 6.0)
		lm.box("Glass", Vector3(wx, 8.5, 5.1), Vector3(2.2, 5.2, 0.14))
	lm.commit(model)

static func cleopatras_needle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("PinkGranite", LandmarkMaterials.pbr("stone", "#B88672", 2.4))
	lm.use("Granite", LandmarkLnKit.granite("#827E78", 2.8))
	lm.use("Bronze", LandmarkMaterials.paint("#2E342E", 0.45, 0.65))
	# Stepped Cornish granite pedestal (0..4.8 m)
	lm.box("Granite", Vector3(0.0, 0.8, 0.0), Vector3(8.5, 1.6, 8.5))
	lm.box("Granite", Vector3(0.0, 3.2, 0.0), Vector3(4.2, 3.2, 4.2))
	# 21 m pink Aswan granite obelisk shaft & pyramidion (4.8..21.0 m)
	lm.frustum("PinkGranite", Vector3(0.0, 4.8, 0.0), 1.35, 0.82, 14.0, 4)
	lm.frustum("PinkGranite", Vector3(0.0, 18.8, 0.0), 0.82, 0.02, 2.2, 4)
	# Two flanking bronze sphinxes on Embankment pedestals
	for sx in [-1.0, 1.0]:
		var x := float(sx) * 7.2
		lm.box("Granite", Vector3(x, 1.1, 0.0), Vector3(4.6, 2.2, 2.2))
		lm.box("Bronze", Vector3(x, 2.8, 0.0), Vector3(3.8, 1.2, 1.4))
		lm.box("Bronze", Vector3(x - float(sx) * 1.1, 3.7, 0.0), Vector3(1.1, 1.4, 1.1))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.5, 8.0), Vector3(0.0, 15.0, 0.0), 40.0, 0.85, 28.0],
	])
