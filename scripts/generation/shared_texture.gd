class_name SharedTexture
extends RefCounted

## Full-size textures made from the bundled PBR photos, kept as files
## under user:// like TerrainTextures' arrays. A built world then names
## them as external resources instead of embedding them: a cached Ultra
## world of Paris held ~970 MB of them (raw) out of 2.3 GB, again in
## every world. A file is read back instead of being remade, and a world
## whose file is gone fails to load and is rebuilt (WorldCache).

const DIR := "user://textures"
const VERSION := 1
## What the textures are made by: a debug build renames them when any of
## these change, a release when its version does.
const SOURCES: Array[String] = ["res://scripts/generation/pbr_textures.gd",
	"res://scripts/generation/pbr_catalog.gd", "res://scripts/generation/roof_metal_maps.gd",
	"res://scripts/generation/facade_shader.gd", "res://scripts/generation/road_surface.gd"]

static var _tag := ""
## [texture, path] made this session and not written yet.
static var _pending: Array = []
static var _mutex := Mutex.new()

## The texture `name` (unique per content: kind, set, map, size): the
## file's when it exists, else `make`'s, written by the next flush().
static func keep(name: String, make: Callable) -> Texture2D:
	# The headless dummy renderer keeps no texture data to write or read.
	if DisplayServer.get_name() == "headless":
		return make.call()
	var path := "%s/%s_%s.res" % [DIR, name, _current_tag()]
	if FileAccess.file_exists(path):
		var held := ResourceLoader.load(path) as Texture2D
		if held != null and held.get_width() > 0:
			return held
	var tex: Texture2D = make.call()
	_mutex.lock()
	_pending.append([tex, path])
	_mutex.unlock()
	return tex

## Writes the textures made since the last call and gives each its path.
## Reading a texture back waits on the main thread, so WorldCache calls
## this on its save thread, before the scene that names them is written.
static func flush() -> void:
	_mutex.lock()
	var todo := _pending
	_pending = []
	_mutex.unlock()
	if todo.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(DIR)
	for entry in todo:
		var tex: Texture2D = entry[0]
		var path: String = entry[1]
		if FileAccess.file_exists(path):
			continue  # another thread made the same one: it stays embedded
		# Saved under a temporary name so a reader never sees half a file.
		var tmp := path + ".tmp.res"
		if ResourceSaver.save(tex, tmp, ResourceSaver.FLAG_COMPRESS) == OK \
				and DirAccess.rename_absolute(tmp, path) == OK:
			tex.take_over_path(path)

static func _current_tag() -> String:
	_mutex.lock()
	if _tag == "":
		var acc := "%d|%s" % [VERSION, str(ProjectSettings.get_setting("application/config/version", ""))]
		if OS.is_debug_build():
			for f in SOURCES:
				acc += "|" + str(hash(FileAccess.get_file_as_string(f)))
		_tag = "%08x" % (hash(acc) & 0xffffffff)
		_drop_stale(_tag)
	var tag := _tag
	_mutex.unlock()
	return tag

## Files of another version are never read again.
static func _drop_stale(tag: String) -> void:
	if not DirAccess.dir_exists_absolute(DIR):
		return
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with("_%s.res" % tag):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR.path_join(f)))
