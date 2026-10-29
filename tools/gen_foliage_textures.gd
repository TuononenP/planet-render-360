extends SceneTree

## Paints the T5.1 foliage/bark/impostor sets at full resolution into
## assets/textures/foliage/ (own procedural work, CC0):
##   godot --headless --path . --script tools/gen_foliage_textures.gd
## Runtime loads these PNGs; without them FoliageTextures/TreeImpostor
## paint the same layouts at reduced resolution.

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FoliageTextures.DIR))
	for kind in FoliageTextures.LEAF_KINDS:
		var t := Time.get_ticks_msec()
		FoliageTextures.paint_leaf(kind, 1.0).save_png(FoliageTextures.DIR + "leaf_" + kind + ".png")
		print("leaf_%s %d ms" % [kind, Time.get_ticks_msec() - t])
	for kind in FoliageTextures.BARK_KINDS:
		var t := Time.get_ticks_msec()
		var set: Array = FoliageTextures.paint_bark(kind, 1.0)
		(set[0] as Image).save_png(FoliageTextures.DIR + "bark_" + kind + ".png")
		(set[1] as Image).save_png(FoliageTextures.DIR + "bark_" + kind + "_n.png")
		print("bark_%s %d ms" % [kind, Time.get_ticks_msec() - t])
	# Impostors rasterise the species meshes with the atlases above.
	for sp in TreeMeshLibrary.species_names():
		for bare in [false, true]:
			if bare and TreeMeshLibrary.is_evergreen(sp):
				continue
			var t := Time.get_ticks_msec()
			var img := TreeImpostor.paint(sp, bare, 1.0)
			img.save_png(FoliageTextures.DIR + TreeImpostor.file_name(sp, bare))
			print("impostor %s bare=%s %d ms" % [sp, bare, Time.get_ticks_msec() - t])
	quit()
