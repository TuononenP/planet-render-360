class_name LandmarkLnWhitehall
extends RefCounted

## Whitehall & The Mall foreground landmarks (`LN-3.3`, `LN-3.4`, `LN-3.6`):
## - `horse_guards`: William Kent's Palladian Horse Guards (1759, OSM way 133153176)
##   with central clock cupola & archway, plus Lutyens's Cenotaph pylon on Whitehall.
## - `whitehall_court`: Archer & Green's French-château Portland-stone riverside block
##   (1884, OSM relation 5485985) with conical turrets & steep slate pavilions.
## - `admiralty_arch`: Aston Webb's curved Edwardian Portland-stone triple arch across
##   The Mall (1912, OSM relation 17074208).

static func horse_guards(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkLnKit.portland("#DFD8C8", 3.4))
	lm.use("Slate", LandmarkLnKit.welsh_slate("#4C535B", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#242D34"))
	lm.use("Dial", LandmarkMaterials.lit("#F5F0DC", 0.9))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Lead", LandmarkMaterials.paint("#5C646B", 0.55, 0.35))
	# Central three-storey Palladian block with archway through to Horse Guards Parade
	lm.box("Stone", Vector3(0.0, 9.0, 0.0), Vector3(36.0, 18.0, 22.0))
	lm.box("Stone", Vector3(0.0, 18.5, 0.0), Vector3(37.2, 1.0, 23.2))
	LandmarkLnKit.pediment_z(lm, "Stone", 0.0, 19.0, 11.2, 22.0, 3.4, 1.6)
	LandmarkLnKit.pediment_z(lm, "Stone", 0.0, 19.0, -11.2, 22.0, 3.4, 1.6)
	# Flanking projecting wings forming the courtyard
	for sx in [-1.0, 1.0]:
		var cx := float(sx) * 32.0
		lm.box("Stone", Vector3(cx, 7.2, 4.0), Vector3(28.0, 14.4, 28.0))
		lm.box("Stone", Vector3(cx, 14.8, 4.0), Vector3(29.0, 0.9, 29.0))
		lm.gable("Slate", Vector3(cx, 15.2, 4.0), 27.0, 27.0, 3.2, Basis(), 0.0, "Slate")
		for row in 3:
			var wy := 3.2 + float(row) * 4.2
			for i in 5:
				var wx := cx + lerpf(-10.5, 10.5, float(i) / 4.0)
				lm.box("Glass", Vector3(wx, wy, 18.1), Vector3(1.8, 2.7, 0.14))
				lm.box("Glass", Vector3(wx, wy, -10.1), Vector3(1.8, 2.7, 0.14))
	# Central octagonal clock tower & lead cupola (top = 28.0 m)
	lm.box("Stone", Vector3(0.0, 21.0, 0.0), Vector3(7.6, 5.2, 7.6))
	for sz in [-1.0, 1.0]:
		lm.disc("Dial", Vector3(0.0, 21.6, float(sz) * 3.85), Vector3(0.0, 0.0, float(sz)), 1.35, 20)
	lm.frustum("Stone", Vector3(0.0, 23.6, 0.0), 3.1, 2.8, 2.4, 8)
	lm.frustum("Lead", Vector3(0.0, 26.0, 0.0), 2.7, 0.25, 2.0, 10)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 24.0), Vector3(0.0, 18.0, 8.0), 62.0, 0.9, 55.0],
	])

static func whitehall_court(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkLnKit.portland("#DDD6C4", 3.5))
	lm.use("Slate", LandmarkLnKit.welsh_slate("#434B54", 2.2))
	lm.use("Glass", LandmarkMaterials.glass("#222B32"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var w := 118.0
	var d := 32.0
	# Main 7-storey Portland-stone château range
	lm.box("Stone", Vector3(0.0, 13.5, 0.0), Vector3(w, 27.0, d))
	lm.box("Stone", Vector3(0.0, 27.4, 0.0), Vector3(w + 1.4, 1.0, d + 1.4))
	LandmarkLnKit.mansard_roof(lm, "Slate", "Stone", "Glass", Vector3(0.0, 27.9, 0.0), w - 2.0, d - 2.0, 7.2, 12)
	# Four signature French-château corner & pavilion conical turrets (top = 42.0 m)
	for tx in [-54.0, -18.0, 18.0, 54.0]:
		var x := float(tx)
		var r := 4.4 if absf(x) > 40.0 else 3.8
		var top_y := 42.0 if absf(x) > 40.0 else 39.5
		lm.frustum("Stone", Vector3(x, 0.0, d * 0.5 - 1.0), r, r * 0.96, 28.5, 12)
		lm.frustum("Slate", Vector3(x, 28.5, d * 0.5 - 1.0), r + 0.4, 0.18, top_y - 28.5, 12)
		lm.box("Gilt", Vector3(x, top_y + 0.3, d * 0.5 - 1.0), Vector3(0.25, 0.9, 0.25))
	# Tall riverside chimney stacks & punched windows
	for i in 16:
		var wx := lerpf(-w * 0.45, w * 0.45, float(i) / 15.0)
		for row in 5:
			var wy := 4.0 + float(row) * 4.5
			lm.box("Glass", Vector3(wx, wy, d * 0.5 + 0.08), Vector3(1.9, 2.8, 0.14))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-35.0, 2.0, 26.0), Vector3(-35.0, 26.0, 14.0), 58.0, 0.85, 60.0],
		[Vector3(35.0, 2.0, 26.0), Vector3(35.0, 26.0, 14.0), 58.0, 0.85, 60.0],
	])

static func admiralty_arch(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkLnKit.portland("#E0D9C8", 3.2))
	lm.use("Slate", LandmarkLnKit.welsh_slate("#4A525A", 2.2))
	lm.use("Glass", LandmarkMaterials.glass("#222B32"))
	lm.use("Iron", LandmarkMaterials.paint("#1D2024", 0.55, 0.45))
	# Four massive rusticated piers forming the triple ceremonial roadway arches
	var pier_xs := [-22.0, -7.5, 7.5, 22.0]
	for px in pier_xs:
		lm.box("Stone", Vector3(float(px), 6.2, 0.0), Vector3(6.2, 12.4, 18.0))
	# Three arch spans bridged by upper entablature & attic storeys (total height 28.0 m)
	for span in [[-18.9, -10.6], [-4.4, 4.4], [10.6, 18.9]]:
		LandmarkLnKit.arch_rib(lm, "Stone", float(span[0]), float(span[1]), 6.8, 11.4, 8.6, 8, 1.4, 1.6)
		LandmarkLnKit.arch_rib(lm, "Stone", float(span[0]), float(span[1]), 6.8, 11.4, -8.6, 8, 1.4, 1.6)
	# Upper three-storey curved triumphal bridge & Latin inscription attic
	lm.box("Stone", Vector3(0.0, 18.2, 0.0), Vector3(54.0, 11.6, 18.2))
	lm.box("Stone", Vector3(0.0, 24.4, 0.0), Vector3(55.4, 1.2, 19.4))
	LandmarkLnKit.mansard_roof(lm, "Slate", "Stone", "Glass", Vector3(0.0, 25.0, 0.0), 52.0, 16.5, 3.0, 8)
	# Flanking angled office wings
	for sx in [-1.0, 1.0]:
		var wx := float(sx) * 38.0
		lm.box("Stone", Vector3(wx, 12.2, -4.0), Vector3(24.0, 24.4, 18.0))
		LandmarkLnKit.mansard_roof(lm, "Slate", "Stone", "Glass", Vector3(wx, 24.4, -4.0), 23.0, 16.5, 3.2, 4)
	# Upper facade windows
	for i in 9:
		var x := lerpf(-22.0, 22.0, float(i) / 8.0)
		for wy in [15.5, 20.5]:
			lm.box("Glass", Vector3(x, float(wy), 9.15), Vector3(2.0, 3.1, 0.14))
			lm.box("Glass", Vector3(x, float(wy), -9.15), Vector3(2.0, 3.1, 0.14))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 22.0), Vector3(0.0, 18.0, 8.0), 62.0, 0.9, 52.0],
	])
