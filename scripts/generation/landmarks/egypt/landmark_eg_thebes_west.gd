class_name LandmarkEgThebesWest
extends RefCounted

## Three monuments of the Theban west bank in true metres, entrance
## toward +Z and sanctuary toward -Z (registry yaw_deg turns them onto
## the real axis): Hatshepsut's terraced temple at Deir el-Bahari, the
## Colossi of Memnon and the Ramesseum.

# --- Mortuary Temple of Hatshepsut ---

## Three terraces rising 0 / 8.5 / 17 m out of a 106 m forecourt: the
## lower and middle porticoes of 16-sided pillars either side of the
## central ramps (Hathor and Anubis chapels at the ends of the middle
## terrace), the upper court with its 18 Osiride piers and the
## sanctuary block against the cliff (25 m at the top). Foundations
## reach below y = 0 for the sloping site.
static func hatshepsut(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#D9C9A2", 3.2))
	lm.use("Shade", LandmarkMaterials.pbr("stone", "#8A7658", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Ground", Vector3(0, -3.0, 5.0), Vector3(112.0, 6.0, 112.0))
	lm.box("Wall", Vector3(0, 4.25, 1.0), Vector3(104.0, 8.5, 22.0))
	lm.box("Wall", Vector3(0, 8.5, -24.0), Vector3(104.0, 17.0, 28.0))
	lm.box("Wall", Vector3(0, 21.0, -40.0), Vector3(72.0, 8.0, 12.0))
	lm.box("Dark", Vector3(0, 20.0, -33.8), Vector3(4.0, 6.0, 0.4))
	for s in [-1.0, 1.0]:
		# Lower portico (z = 18), roofed by the middle terrace.
		lm.box("Wall", Vector3(s * 28.75, 8.05, 15.75), Vector3(46.5, 0.9, 7.5))
		lm.box("Shade", Vector3(s * 28.75, 3.8, 12.15), Vector3(46.5, 7.6, 0.3))
		for k in 11:
			LandmarkEgParts.column(lm, "Wall", Vector3(s * (7.0 + 4.3 * k), 0, 18.2), 0.65, 7.6,
				LandmarkEgParts.PLAIN)
		# Middle portico (z = -3) under the upper terrace.
		lm.box("Wall", Vector3(s * 28.75, 16.55, -6.25), Vector3(46.5, 0.9, 7.5))
		lm.box("Shade", Vector3(s * 28.75, 12.3, -10.15), Vector3(46.5, 7.6, 0.3))
		for k in 11:
			LandmarkEgParts.column(lm, "Wall", Vector3(s * (7.0 + 3.9 * k), 8.5, -3.0), 0.65, 7.6,
				LandmarkEgParts.PLAIN)
		# Chapels of Hathor and Anubis closing the ends of the middle terrace.
		lm.box("Wall", Vector3(s * 49.5, 12.5, 2.0), Vector3(5.0, 8.0, 18.0))
		lm.box("Dark", Vector3(s * 46.9, 11.0, 2.0), Vector3(0.4, 4.0, 3.0))
		# Upper portico: Osiride piers, each a block with a crowned head.
		lm.box("Wall", Vector3(s * 26.0, 23.7, -33.5), Vector3(46.0, 1.0, 5.0))
		for k in 9:
			var x: float = s * (8.0 + 4.6 * k)
			lm.box("Wall", Vector3(x, 20.0, -32.5), Vector3(1.9, 6.0, 1.9))
			lm.box("Shade", Vector3(x, 22.9, -32.2), Vector3(1.2, 0.9, 1.2))
	_ramp(lm, 4.6, 56.0, 12.0, 0.0, 8.5)
	_ramp(lm, 4.6, 10.0, -10.0, 8.5, 17.0)
	lm.commit(model)

## Sloping ramp `w` half-wide climbing from (z_lo, y_lo) to (z_hi, y_hi)
## with solid flanks.
static func _ramp(lm: LandmarkMesh, w: float, z_lo: float, z_hi: float, y_lo: float,
		y_hi: float) -> void:
	var n := Vector3(0, z_lo - z_hi, y_hi - y_lo).normalized()
	lm.quad("Wall", Vector3(-w, y_lo, z_lo), Vector3(w, y_lo, z_lo), Vector3(w, y_hi, z_hi),
		Vector3(-w, y_hi, z_hi), n)
	for s in [-1.0, 1.0]:
		var sn := Vector3(s, 0, 0)
		lm.tri("Wall", Vector3(s * w, y_lo, z_lo), Vector3(s * w, y_hi, z_hi),
			Vector3(s * w, y_lo, z_hi), sn, sn, sn, Vector2(z_lo, y_lo), Vector2(z_hi, y_hi),
			Vector2(z_hi, y_lo))

# --- Colossi of Memnon ---

## Two seated 18 m statues of Amenhotep III (14.7 m of quartzite
## sandstone on 3.2 m plinths, crowns lost), 15 m apart, facing +Z.
static func memnon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Quartzite", LandmarkMaterials.pbr("stone", "#B08A5E", 7.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#9C7952", 4.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D2BA8A", 8.0))
	lm.box("Ground", Vector3(0, -0.4, 0), Vector3(34.0, 1.0, 26.0))
	for s in [-1.0, 1.0]:
		lm.box("Plinth", Vector3(s * 7.5, 1.6, 0), Vector3(8.6, 3.2, 12.4))
		LandmarkEgParts.colossus(lm, "Quartzite", Vector3(s * 7.5, 3.2, 1.2), 16.1, false)
		# The two small standing figures flanking the legs on the throne front.
		for k in [-1.0, 1.0]:
			lm.box("Quartzite", Vector3(s * 7.5 + k * 1.1, 5.5, 5.4), Vector3(0.9, 4.6, 0.8))
	lm.commit(model)

# --- Ramesseum ---

## Mortuary temple of Ramesses II: ruined first pylon (22 m), first court
## with the fallen granite colossus, second pylon, the Osiride court, the
## 48-column hypostyle hall (12 open-papyrus nave columns of 12.5 m), the
## rear halls and the brick storerooms either side.
static func ramesseum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#CDAE7E", 3.2))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8F5F50", 2.2))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Mud", LandmarkMaterials.pbr("brick", "#9C7B55", 3.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Ground", Vector3(0, -0.2, -4.0), Vector3(70.0, 0.6, 180.0))
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 82.0), 68.0, 22.0, 8.0, 8.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 43.0), 62.0, 19.0, 7.0, 7.0)
	# First court: bud-column side colonnades and the fallen colossus.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.wall(lm, "Sand", Vector2(s * 29.5, 78.0), Vector2(s * 29.5, 46.0), 8.0, 1.6)
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * 24.0, 0, 72.0), Vector3(s * 24.0, 0, 50.0),
			6, 0.8, 7.2)
		lm.box("Sand", Vector3(s * 26.0, 7.6, 61.0), Vector3(9.0, 0.8, 30.0))
	lm.box("Granite", Vector3(-9.0, 2.0, 54.0), Vector3(8.0, 4.0, 8.0))
	lm.box("Granite", Vector3(-12.2, 3.2, 58.8), Vector3(2.6, 6.4, 2.6))
	lm.box("Granite", Vector3(-5.8, 3.2, 58.8), Vector3(2.6, 6.4, 2.6))
	lm.box("Granite", Vector3(-1.0, 1.6, 66.0), Vector3(6.4, 3.2, 4.6), Basis(Vector3.UP, 0.5))
	lm.box("Granite", Vector3(3.5, 1.5, 71.0), Vector3(3.2, 3.0, 3.4), Basis(Vector3.UP, 0.9))
	# Osiride court: a pier row down each side and a double row across the rear.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.wall(lm, "Sand", Vector2(s * 28.0, 39.0), Vector2(s * 28.0, 12.0), 9.0, 1.8)
		for i in 6:
			lm.box("Sand", Vector3(s * 22.0, 3.7, 35.0 - 4.8 * i), Vector3(2.2, 7.4, 2.2))
			lm.box("Sand", Vector3(s * 22.0, 8.2, 35.0 - 4.8 * i), Vector3(1.3, 1.6, 1.3))
	# Hypostyle hall: 12 nave columns, 36 bud columns in 6 rows under aisle roofs.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.wall(lm, "Sand", Vector2(s * 27.0, 12.0), Vector2(s * 27.0, -24.0), 14.0, 2.0)
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * 5.2, 0, 7.0), Vector3(s * 5.2, 0, -19.0),
			6, 1.15, 12.5, LandmarkEgParts.OPEN, 10)
		lm.beam("Sand", Vector3(s * 5.2, 13.1, 10.0), Vector3(s * 5.2, 13.1, -22.0), 1.4, 2.6,
			Vector3.UP, true)
		lm.box("Sand", Vector3(s * 8.6, 11.0, -6.0), Vector3(0.9, 4.2, 34.0))
		for xr in [12.0, 17.0, 22.0]:
			LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * xr, 0, 7.0), Vector3(s * xr, 0, -19.0),
				6, 0.8, 8.6)
		lm.box("Sand", Vector3(s * 17.6, 9.4, -6.0), Vector3(18.0, 0.9, 34.0))
	lm.box("Sand", Vector3(0, 13.9, -6.0), Vector3(12.0, 0.9, 34.0))
	# Rear halls and sanctuary, stepping down; brick magazines either side.
	lm.box("Sand", Vector3(0, 4.0, -31.0), Vector3(44.0, 8.0, 14.0))
	lm.box("Sand", Vector3(0, 3.2, -44.0), Vector3(30.0, 6.4, 12.0))
	lm.box("Sand", Vector3(0, 2.7, -55.0), Vector3(20.0, 5.4, 10.0))
	lm.box("Dark", Vector3(0, 2.4, -23.9), Vector3(4.0, 4.8, 0.5))
	for s in [-1.0, 1.0]:
		lm.box("Mud", Vector3(s * 40.5, 2.4, -22.0), Vector3(8.0, 4.8, 78.0))
	lm.commit(model)
