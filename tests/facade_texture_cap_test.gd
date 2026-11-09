extends SceneTree

## Facade texture cache overflow: godot --headless --script tests/facade_texture_cap_test.gd
## Offline. A full cache holding no limestone (a brick city) still answers
## from the limestone fallback, composing it once instead of recursing
## without end (the Ultra London stack overflow), and later overflows reuse it.

func _init() -> void:
	var ok := true
	FacadeMaterials.begin_build()
	var placeholder := {"overflow": true}
	for i in FacadeMaterials.TEX_CAP:
		FacadeMaterials._facade_texs["brick|tiled%d|1||0" % i] = placeholder
	var texs := FacadeTextures.facade_texs("concrete", 6, 1)
	if texs.is_empty() or texs == placeholder:
		printerr("FAIL: overflow did not return the composed limestone fallback")
		ok = false
	var size := FacadeMaterials._facade_texs.size()
	if size != FacadeMaterials.TEX_CAP + 1:
		printerr("FAIL: fallback should add one entry over the cap, cache holds %d" % size)
		ok = false
	if FacadeTextures.facade_texs("metal", 6, 1) != texs:
		printerr("FAIL: a later overflow should reuse the fallback")
		ok = false
	FacadeMaterials.begin_build()
	print("FACADE TEXTURE CAP OK" if ok else "FACADE TEXTURE CAP FAILED")
	quit(0 if ok else 1)
