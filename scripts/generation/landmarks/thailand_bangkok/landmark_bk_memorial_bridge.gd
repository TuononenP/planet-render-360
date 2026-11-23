class_name LandmarkBkMemorialBridge
extends RefCounted

## Memorial Bridge — Saphan Phut (`สะพานพระพุทธยอดฟ้า`) — Chao Phraya River, Bangkok BK-6.2
## Site: BridgeSpecsSoutheastAsiaAuNz `br_bangkok_memorial_bridge` (`13.73945, 100.49773`,
## `bearing: 18.8°`, `spans: [78.0, 78.0, 78.0] = 234.0 m`, `width: 16.68 m`, `clear: 8.7 m`, `rise: 7.0 m`).
## Builds Dorman Long's 1932 dark-emerald-green 3-span steel through-truss (`steel_hex: "#286B52"`)
## via `BridgeParam`, plus the signature Art Deco white concrete bascule machinery pylons on the
## central river piers and red-and-white navigation chevron pier fenders (`front.jpg`).

static func build(model: Node3D, row: Dictionary) -> void:
	BridgeParam.build(model, row)
	var lm := LandmarkMesh.new()
	lm.use("ArtDeco", LandmarkMaterials.pbr("render", "#EFECE2", 3.0))
	lm.use("RedWarn", LandmarkMaterials.pbr("terracotta", "#B43028", 2.0))
	lm.use("Dark", LandmarkMaterials.paint("#282C30", 0.85, 0.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A2", 1.6))

	var xs := BridgeParam.supports(row)
	var c := float(row["clear"])
	var w := float(row["width"])

	# Twin Art Deco white concrete bascule control pylons & red-striped navigation piers at xs[1] & xs[2] (`front.jpg`)
	for idx in [1, 2]:
		var px := xs[idx]
		lm.box("ArtDeco", Vector3(px, (c - 1.2) * 0.5, 0.0), Vector3(5.6, c - 1.2, w + 3.2))
		for ry in [1.8, 3.4]:
			lm.box("RedWarn", Vector3(px, ry, 0.0), Vector3(5.75, 0.65, w + 3.35), Basis(), 0.0)
		# Stepped Art Deco operator towers flanking the central span (`idx == 2` in `front.jpg`)
		if idx == 2:
			for sz in [-1.0, 1.0]:
				var tz := float(sz) * (w * 0.5 + 1.8)
				lm.box("ArtDeco", Vector3(px, (c + 6.4) * 0.5, tz), Vector3(2.8, c + 6.4, 2.8))
				lm.box("Dark", Vector3(px, c + 5.4, tz), Vector3(3.0, 0.65, 3.0), Basis(), 0.0)
				lm.box("ArtDeco", Vector3(px, c + 6.6, tz), Vector3(2.2, 0.55, 2.2))

	# Warm green/amber night floodlights illuminating the dark-green steel trusses (`BK-10`)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(xs[1], c + 1.5, w * 0.7), Vector3(0.0, c + 5.5, 0.0), 58.0, 1.25, 68.0, Color(0.75, 1.0, 0.82)],
		[Vector3(xs[2], c + 1.5, -w * 0.7), Vector3(0.0, c + 5.5, 0.0), 58.0, 1.25, 68.0, Color(0.75, 1.0, 0.82)],
	])
	BridgeCamber.apply(lm, BridgeParam.half_length(row), c, float(row.get("camber", 0.0)), float(row.get("tilt", 0.0)))
	lm.commit(model)
