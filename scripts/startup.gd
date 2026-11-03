extends Control

# Keep this shader cached before the background loader compiles car models.
# Loading it for the first time on that thread fails with the Metal renderer.
const CAR_PAINT_SHADER = preload("res://scripts/generation/car_paint.gdshader")
const MAIN_SCENE := "res://scenes/main.tscn"

func _ready() -> void:
	var err := ResourceLoader.load_threaded_request(MAIN_SCENE, "PackedScene")
	if err != OK:
		push_error("Could not start loading the main scene: %s" % err)
		set_process(false)

func _process(_delta: float) -> void:
	match ResourceLoader.load_threaded_get_status(MAIN_SCENE):
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			var scene := ResourceLoader.load_threaded_get(MAIN_SCENE) as PackedScene
			get_tree().change_scene_to_packed(scene)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			set_process(false)
			push_error("Could not load the main scene")
