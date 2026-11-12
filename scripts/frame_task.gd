class_name FrameTask
extends RefCounted

## Runs `work` on a worker thread and waits for it a frame at a time, so a
## long stretch of pure CPU work (encoding a full-size picture) never
## freezes the app. The task is joined once: when it finishes, when this
## owner is freed (an await dropped mid-wait), or when the tree quits
## while it still runs, so it never outlives the engine.

static var _running: Array[int] = []
static var _exit_hooked := false
var _task := -1

## Awaitable: returns once `work` has run. Pass results out through a
## captured Array or Dictionary.
static func run(work: Callable, label: String, tree: SceneTree) -> void:
	await FrameTask.new()._run(work, label, tree)

func _run(work: Callable, label: String, tree: SceneTree) -> void:
	_hook_exit(tree)
	_task = WorkerThreadPool.add_task(work, false, label)
	_running.append(_task)
	while not WorkerThreadPool.is_task_completed(_task):
		await tree.process_frame
	_join(_task)
	_task = -1

## Static, so the predelete join calls no method on the instance being freed.
static func _join(task: int) -> void:
	if task != -1 and task in _running:
		_running.erase(task)
		WorkerThreadPool.wait_for_task_completion(task)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		FrameTask._join(_task)

static func _hook_exit(tree: SceneTree) -> void:
	if _exit_hooked or tree == null or tree.root == null:
		return
	_exit_hooked = true
	tree.root.tree_exiting.connect(func() -> void:
		for t in _running:
			WorkerThreadPool.wait_for_task_completion(t)
		_running.clear())
