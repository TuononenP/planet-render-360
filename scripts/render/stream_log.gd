class_name StreamLog
extends RefCounted

## The streamer's log lines (WorldStreamer._log): printed, and kept in
## LOG_PATH too. Godot keeps only its last few session logs, so a
## flight's timings were gone by the time anyone looked. The file starts
## over past LOG_MAX_BYTES.

const LOG_PATH := "user://logs/stream.log"
const LOG_MAX_BYTES := 1 << 20

static func line(text: String) -> void:
	print(text)
	if DisplayServer.get_name() == "headless":
		return  # tests and tools keep their own output
	DirAccess.make_dir_recursive_absolute(LOG_PATH.get_base_dir())
	var f := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE) if FileAccess.file_exists(LOG_PATH) \
		else FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f == null:
		return
	if f.get_length() > LOG_MAX_BYTES:
		f.close()
		f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
		if f == null:
			return
	f.seek_end()
	f.store_line("%s %s" % [Time.get_datetime_string_from_system(), text])
	f.close()
