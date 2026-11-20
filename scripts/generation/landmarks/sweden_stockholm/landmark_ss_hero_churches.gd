extends RefCounted

## Klara and Sofia churches: see churches/sto_church_klara.gd and
## churches/sto_church_sofia.gd for the facade specs and sources.

static func klara(model: Node3D) -> void:
	StoChurchKlara.build(model)

static func sofia(model: Node3D) -> void:
	StoChurchSofia.build(model)
