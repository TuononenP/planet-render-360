extends RefCounted

## Eclipse, Gröna Lund's 121 m swing tower (true metres; height from Gröna Lund,
## footprint OSM way 238784202). The towers, palaces and churches that used to
## share this file now live in their own files under towers/, palaces/ and
## churches/.

const GronaLund = preload("res://scripts/generation/landmarks/sweden_stockholm/landmark_ss_gronalund.gd")

static func _steel(lm: LandmarkMesh) -> void:
	lm.use("Steel", LandmarkMaterials.pbr("concrete", "#69727A", 2.0, 0.55, 0.45))
	lm.use("Glass", LandmarkMaterials.glass("#24303A"))
	lm.use("Accent", LandmarkMaterials.pbr("concrete", "#DBD0B9", 2.0))

static func eclipse(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_steel(lm)
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("TowerWhite", LandmarkMaterials.paint("#E4E7E5", 0.5, 0.3))
	# Eclipse, Gröna Lund's 121 m StarFlyer tower: a white steel lattice
	# (four legs, ring frames and gold X bracing, as in the reference)
	# with the swing carousel parked near the top, its star of arms
	# hanging chair chains; nearby rides remain OSM.
	var bays := 29
	for k in bays:
		var f0 := float(k) / float(bays)
		var f1 := float(k + 1) / float(bays)
		var y0 := 116.0 * f0
		var y1 := 116.0 * f1
		var h0 := lerpf(2.6, 1.9, f0)
		var h1 := lerpf(2.6, 1.9, f1)
		for q in 4:
			var a := PI * 0.5 * float(q) + PI * 0.25
			var b := PI * 0.5 * float(q + 1) + PI * 0.25
			var ca := Vector2(cos(a), sin(a)) * sqrt(2.0)
			var cb := Vector2(cos(b), sin(b)) * sqrt(2.0)
			var a0 := Vector3(ca.x * h0, y0, ca.y * h0)
			var a1 := Vector3(ca.x * h1, y1, ca.y * h1)
			var b0 := Vector3(cb.x * h0, y0, cb.y * h0)
			var b1 := Vector3(cb.x * h1, y1, cb.y * h1)
			lm.beam("TowerWhite", a0, a1, 0.5, 0.5)
			lm.beam("TowerWhite", a1, b1, 0.3, 0.3)
			lm.beam("Gilt", a0, b1, 0.1, 0.1)
			lm.beam("Gilt", b0, a1, 0.1, 0.1)
	lm.frustum("TowerWhite", Vector3(0, 107.0, 0), 3.4, 3.0, 2.4, 12)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x)
		lm.beam("TowerWhite", d * 3.0 + Vector3(0, 108.4, 0), d * 13.0 + Vector3(0, 107.0, 0), 0.4, 0.4)
		lm.beam("TowerWhite", d * 3.0 + Vector3(0, 107.2, 0), d * 13.0 + Vector3(0, 106.6, 0), 0.3, 0.3)
		lm.beam("TowerWhite", d * 9.0 + Vector3(0, 107.4, 0), d * 8.0 + Vector3(0, 106.8, 0), 0.2, 0.2)
		# Chair chains out and down, the seat at the end.
		for s: float in [-0.35, 0.35]:
			var tip := d * 13.0 + Vector3(0, 106.8, 0) + side * s
			var seat := d * 17.5 + Vector3(0, 96.0, 0) + side * s
			lm.beam("Steel", tip, seat, 0.05, 0.05)
		lm.box("Steel", d * 17.5 + Vector3(0, 95.7, 0), Vector3(0.9, 0.2, 1.1), Basis(Vector3.UP, -a), 0.0)
	lm.frustum("Gilt", Vector3(0, 116.0, 0), 2.0, 0.0, 5.0, 12)
	GronaLund.add(lm)
	lm.commit(model)

