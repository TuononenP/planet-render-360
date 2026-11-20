class_name FtKupittaaStation
extends RefCounted

## Kupittaa Railway Station (Kupittaan rautatieasema, 1995) at Kupittaa Science
## Park in true metres (+X ENE perpendicular to railway / along concourse bridge,
## +Z/-Z along the dual-track Helsinki-Turku main railway line, turned by
## yaw_deg = -34.8°):
##   - Measured from OSM way:986922992 (60.450350, 22.297450, LoD2 height 15.3 m).
##   - Elevated 1995 steel-and-glass bridge-concourse hall (38 x 16 m, deck at
##     +6.4 m, roof ridge at 15.2 m) straddling the recessed dual-track railway
##     line between Joukahaisenkatu (-X) and Helsinginkatu (+X).
##   - Exposed white/silver tubular steel space-frame roof trusses & diagonal
##     bracing above panoramic curtain-wall concourse glazing with warm night
##     interior glow.
##   - Twin glazed escalator & lift shafts descending to two 92 m concrete
##     railway platforms protected by curved steel-and-glass platform canopies.
##   - Blue-grey structural steel V-piers and entrance plaza canopies at both
##     bridgeheads.
## Surfaces: 8 merged PBR parts (SteelWhite, SteelBlue, Concrete, Roof, Frame,
## Glass, Stone, Lamp).

const FOUND := -2.2
const TOP_M := 15.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_platforms_and_canopies(lm)
	_build_bridge_concourse(lm)
	_build_space_frame_roof(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("SteelWhite", LandmarkMaterials.paint("#E4E7EA", 0.38, 0.55))
	lm.use("SteelBlue", LandmarkMaterials.paint("#3E5B74", 0.42, 0.60))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C2BFB8", 2.8))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#565D64", 2.5, 0.50, 0.55))
	lm.use("Frame", LandmarkMaterials.paint("#272D34", 0.42, 0.62))
	lm.use("Glass", LandmarkMaterials.glass("#263D4E"))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7F7D79", 2.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BC", 1.5))

static func _build_platforms_and_canopies(lm: LandmarkMesh) -> void:
	# Twin concrete railway platforms straddling the dual tracks (x = -12..-6 and +6..+12, z = -44..44).
	for sx: float in [-1.0, 1.0]:
		var px := 9.2 * sx
		LandmarkFrKit.rect(lm, "Concrete", px - 3.0, px + 3.0, -44.0, 44.0, FOUND, 1.05)
		LandmarkFrKit.rect(lm, "Stone", px - 3.1, px + 3.1, -44.0, 44.0, 0.90, 1.10)
		# Steel-and-glass platform canopies extending north and south of the bridge concourse.
		for cz: float in [-24.0, 24.0]:
			LandmarkFrKit.rect(lm, "Roof", px - 2.6, px + 2.6, cz - 16.0, cz + 16.0, 4.65, 4.92)
			LandmarkFrKit.rect(lm, "Glass", px - 1.2, px + 1.2, cz - 15.0, cz + 15.0, 4.90, 5.10)
			LandmarkFrKit.rect(lm, "Lamp", px - 0.35, px + 0.35, cz - 15.0, cz + 15.0, 4.54, 4.66)
			for k in 5:
				var pz := lerpf(cz - 13.0, cz + 13.0, float(k) / 4.0)
				lm.beam("SteelBlue", Vector3(px, 1.05, pz), Vector3(px, 4.68, pz), 0.24, 0.24)
				lm.beam("SteelWhite", Vector3(px - 2.4, 4.45, pz), Vector3(px + 2.4, 4.65, pz), 0.14, 0.18)
		# Glazed escalator & lift shafts descending from bridge concourse to each platform.
		LandmarkFrKit.rect(lm, "Glass", px - 2.1, px + 2.1, 7.6, 17.0, 1.1, 6.6)
		LandmarkFrKit.rect(lm, "Lamp", px - 1.5, px + 1.5, 8.2, 16.2, 1.5, 6.2)
		lm.beam("SteelWhite", Vector3(px - 2.1, 1.2, 16.8), Vector3(px - 2.1, 6.6, 7.8), 0.20, 0.20)
		lm.beam("SteelWhite", Vector3(px + 2.1, 1.2, 16.8), Vector3(px + 2.1, 6.6, 7.8), 0.20, 0.20)
		# Glazed lift shaft beside the escalator.
		LandmarkFrKit.rect(lm, "Glass", px - 1.6, px + 1.6, -11.4, -7.8, 1.1, 11.4)
		LandmarkFrKit.rect(lm, "SteelBlue", px - 1.75, px + 1.75, -11.55, -7.65, 11.4, 12.1)
	# Track ballast & rail bed between platforms.
	LandmarkFrKit.rect(lm, "Stone", -6.2, 6.2, -46.0, 46.0, FOUND, 0.12)

static func _build_bridge_concourse(lm: LandmarkMesh) -> void:
	# Elevated bridgehead abutments at -X (Science Park) and +X (Helsinginkatu).
	for sx: float in [-1.0, 1.0]:
		var bx := 19.5 * sx
		LandmarkFrKit.rect(lm, "Concrete", bx - 4.2, bx + 4.2, -8.8, 8.8, FOUND, 6.5)
		LandmarkFrKit.rect(lm, "Glass", bx - 3.6, bx + 3.6, -7.8, 7.8, 1.0, 6.3)
		LandmarkFrKit.rect(lm, "Lamp", bx - 2.8, bx + 2.8, -6.8, 6.8, 1.4, 5.8)
	# Bridge-concourse deck spanning x = -22..+22, z = -8.2..+8.2 at y = 6.2..7.0.
	LandmarkFrKit.rect(lm, "Concrete", -23.0, 23.0, -8.4, 8.4, 6.1, 7.0)
	LandmarkFrKit.rect(lm, "SteelBlue", -23.2, 23.2, -8.55, 8.55, 5.85, 6.25)
	# V-shaped structural steel piers supporting the bridge over the platform edges.
	for sx: float in [-1.0, 1.0]:
		var px := 12.2 * sx
		for pz: float in [-6.8, 6.8]:
			lm.beam("SteelBlue", Vector3(px, 1.05, pz), Vector3(px - 2.2 * sx, 6.0, pz), 0.42, 0.42)
			lm.beam("SteelBlue", Vector3(px, 1.05, pz), Vector3(px + 2.2 * sx, 6.0, pz), 0.42, 0.42)
	# Panoramic curtain-wall concourse hall above the deck (y = 7.0..12.8).
	LandmarkFrKit.rect(lm, "Glass", -21.5, 21.5, -7.8, 7.8, 7.0, 12.8)
	LandmarkFrKit.rect(lm, "Lamp", -19.5, 19.5, -6.4, 6.4, 7.4, 12.2)
	# Deep curtain-wall mullions around all 4 concourse faces.
	for fz: float in [-7.86, 7.86]:
		for k in 15:
			var mx := lerpf(-21.2, 21.2, float(k) / 14.0)
			lm.box("Frame", Vector3(mx, 9.9, fz), Vector3(0.18, 5.8, 0.24))
		lm.box("Frame", Vector3(0.0, 9.9, fz), Vector3(43.0, 0.18, 0.24))
	for fx: float in [-21.56, 21.56]:
		for k in 7:
			var mz := lerpf(-7.5, 7.5, float(k) / 6.0)
			lm.box("Frame", Vector3(fx, 9.9, mz), Vector3(0.24, 5.8, 0.18))

static func _build_space_frame_roof(lm: LandmarkMesh) -> void:
	# Signature 1995 pitched white-steel space-frame roof rising to 15.2 m (LoD2 15.3 m).
	LandmarkFrKit.rect(lm, "SteelWhite", -24.5, 24.5, -9.2, 9.2, 12.75, 13.25)
	lm.gable("Roof", Vector3(0.0, 13.25, 0.0), 18.4, 49.0, 1.95, Basis(Vector3.UP, PI * 0.5), 0.25, "SteelWhite")
	# Exposed tubular steel space-frame trusses flanking the bridgehead overhangs.
	for k in 11:
		var tx := lerpf(-23.5, 23.5, float(k) / 10.0)
		lm.beam("SteelWhite", Vector3(tx, 12.9, -9.2), Vector3(tx, TOP_M, 0.0), 0.22, 0.22)
		lm.beam("SteelWhite", Vector3(tx, 12.9, 9.2), Vector3(tx, TOP_M, 0.0), 0.22, 0.22)
		lm.beam("SteelWhite", Vector3(tx, 12.85, -9.2), Vector3(tx, 12.85, 9.2), 0.18, 0.18)
	# Longitudinal ridge & eave steel chords.
	lm.beam("SteelWhite", Vector3(-24.5, TOP_M, 0.0), Vector3(24.5, TOP_M, 0.0), 0.28, 0.28)
	lm.beam("SteelWhite", Vector3(-24.5, 12.9, -9.2), Vector3(24.5, 12.9, -9.2), 0.24, 0.24)
	lm.beam("SteelWhite", Vector3(-24.5, 12.9, 9.2), Vector3(24.5, 12.9, 9.2), 0.24, 0.24)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-28.0, 2.5, 0.0), Vector3(-21.5, 9.5, 0.0), 58.0, 0.80, 36.0, Color(0.95, 0.94, 0.92)],
		[Vector3(28.0, 2.5, 0.0), Vector3(21.5, 9.5, 0.0), 58.0, 0.80, 36.0, Color(0.95, 0.94, 0.92)],
		[Vector3(0.0, 2.0, 16.0), Vector3(0.0, 9.5, 7.8), 62.0, 0.85, 38.0, Color(1.0, 0.90, 0.74)],
	])
