class_name WorldHandoff
extends RefCounted

## Endless walk & fly: moves a streamed world into the scene, and the old
## one out, a slice per frame instead of all in the swap frame. Adding a
## whole city world (thousands of meshes entering the tree) and freeing
## the old one in one frame was the visible hitch at every recentre.
##
## While the ready world waits (WorldStreamer READY), stage() parents it
## hidden under the view's world root and pump() re-adds its top-level
## subtrees within a time budget, so their meshes reach the renderer
## early. Hidden, it draws nothing and has no colliders to meet. At the
## swap, swap_in() finishes any rest, shows it and hides the old world,
## which pump() then frees subtree by subtree. The world keeps its frame
## (the new centre's): the camera is remapped into it at the swap.

## Main-thread microseconds a frame for adding or freeing subtrees; at
## least one subtree moves per pump either way.
const BUDGET_US := 1500

## A subtree with more children than this comes back child by child (a
## whole building layer entering the tree at once outlasted any budget).
const SPLIT_CHILDREN := 8

## The world being staged (hidden, in the tree) and the pieces still to
## add back, in their original order (names stay unique): [parent, node,
## top-level], a parent always before its children.
var staged: Node3D
var _pending: Array = []
## Old worlds leaving: hidden, freed a subtree at a time.
var _retiring: Array[Node3D] = []
## When the staged world got its last subtree back (msec; 0 = not yet).
var _staged_at := 0
## Called with a detached holder of each piece and whether it is a
## top-level subtree, before it comes back (ViewConditions.dress: wet
## roads and roof snow on top-level pieces, city lights on all), so the
## swap frame need not walk the whole world; `dressed`: it ran for all.
var dress := Callable()
var dressed := false
var _holder := Node.new()
## Pieces joining a world built before them (StreamDetail: a stretch's
## detail layer, made after its core): [world, node, dress], added like
## staged pieces, a slice a frame, each dressed by its own callable.
var _late: Array = []
## Deferred detail-layer waves revealed 1 wave/frame after swap_in so Metal /
## Forward+ spreads pipeline compilation, uploads and shadow passes across
## 3-4 frames instead of one swap+3 hitch: [[world, Array[Node3D]], ...].
var _revealing: Array = []

## Whether `world` is fully staged: in the tree with every subtree back.
func ready_for(world: Node3D) -> bool:
	return world != null and staged == world and _pending.is_empty()

## Starts staging detached `world` under `root`, hidden. Its subtrees
## are taken off while it is detached (cheap, owners kept) and come back
## in pump().
func stage(root: Node3D, world: Node3D) -> void:
	drop_staged()
	if root == null or world == null or world.is_inside_tree():
		return
	for c in world.get_children():
		# Unowned while off (re-adding an owned node warns), owned again
		# once back (pump), so the world packs and finds as before.
		c.owner = null
		world.remove_child(c)
		_pending.append([world, c, true])
		if c.get_child_count() > SPLIT_CHILDREN:
			for g in c.get_children():
				g.owner = null
				c.remove_child(g)
				_pending.append([c, g, false])
	world.visible = false
	staged = world
	dressed = dress.is_valid()
	_staged_at = Time.get_ticks_msec() if _pending.is_empty() else 0
	root.add_child(world)

## Adds staged subtrees and frees retiring ones within `budget_us`.
## Returns true while anything is left to do.
func pump(budget_us: int = BUDGET_US) -> bool:
	var t := Time.get_ticks_usec()
	var moved := false
	if not _revealing.is_empty():
		var wave: Array = _revealing.pop_front()
		var w: Variant = wave[0]
		if is_instance_valid(w) and not (w in _retiring):
			for node: Variant in (wave[1] as Array):
				if is_instance_valid(node):
					(node as Node3D).visible = true
		moved = true
	while not _pending.is_empty() and (not moved or Time.get_ticks_usec() - t < budget_us):
		_add_back(_pending.pop_front())
		moved = true
		if _pending.is_empty():
			_staged_at = Time.get_ticks_msec()
	while not _late.is_empty() and (not moved or Time.get_ticks_usec() - t < budget_us):
		_add_late(_late.pop_front())
		moved = true
	while not _retiring.is_empty() and (not moved or Time.get_ticks_usec() - t < budget_us):
		var old := _retiring[0]
		if not is_instance_valid(old):
			_retiring.pop_front()
			continue
		if old.get_child_count() > 0:
			# The last leaf: one big subtree freed whole outlasted the budget.
			var leaf: Node = old.get_child(old.get_child_count() - 1)
			while leaf.get_child_count() > 0:
				leaf = leaf.get_child(leaf.get_child_count() - 1)
			leaf.free()
		else:
			_retiring.pop_front()
			old.free()
		moved = true
	return busy()

func _add_back(piece: Array) -> void:
	var node: Node = piece[1]
	if dress.is_valid():
		_holder.add_child(node)
		dress.call(_holder, piece[2])
		_holder.remove_child(node)
	(piece[0] as Node).add_child(node)
	node.owner = staged  # every node's owner was the world (WorldCache.pack)

## Queues detached `node` to join `world` (in the tree: staged, parked
## or live) as its child, dressed by `dress_late` (as `dress`, or none).
func add_late(world: Node3D, node: Node, dress_late: Callable = Callable()) -> void:
	_late.append([world, node, dress_late])

## Whether pieces are still to join `world`.
func late_pending(world: Node3D) -> bool:
	return _late.any(func(piece: Array) -> bool: return is_same(piece[0], world))

## The pieces still to join `world`.
func late_nodes(world: Node3D) -> Array:
	var nodes: Array = []
	for piece: Array in _late:
		if is_same(piece[0], world):
			nodes.append(piece[1])
	return nodes

## Whether `world` is leaving (hidden, being freed a slice a frame).
func retiring(world: Node3D) -> bool:
	return world in _retiring

## A late piece joins its world, or is freed when that world has gone.
func _add_late(piece: Array) -> void:
	var node: Node = piece[1]
	if not is_instance_valid(piece[0]) or piece[0] in _retiring:
		node.free()
		return
	var world: Node3D = piece[0]
	var dress_late: Callable = piece[2]
	if dress_late.is_valid():
		_holder.add_child(node)
		dress_late.call(_holder, true)
		_holder.remove_child(node)
	world.add_child(node)
	node.owner = world
	if world == staged:
		_staged_at = Time.get_ticks_msec()  # settles again: its meshes are new to the renderer

## Milliseconds `world` has been fully staged (0 when it is not): the
## renderer finishes its first uploads meanwhile, which a swap right
## after staging pays in its first visible frames instead.
func staged_ms(world: Node3D) -> int:
	return Time.get_ticks_msec() - _staged_at if ready_for(world) and _staged_at > 0 else 0

func busy() -> bool:
	return not _pending.is_empty() or not _retiring.is_empty() or not _late.is_empty() \
		or not _revealing.is_empty()

## Assigns a top-level world child to a swap-reveal wave (0 = immediate on
## swap frame, 1 = Buildings/Landmarks, 2 = Vegetation/Canopy, 3 = Props/vehicles).
static func _reveal_wave(node: Node) -> int:
	if not (node is Node3D) or not (node as Node3D).visible:
		return 0
	var n := str(node.name)
	if n == "Buildings" or n.begins_with("Landmark"):
		return 1
	if n == "Vegetation" or n.begins_with("FarCanopy") or n.begins_with("VegTrees") \
			or n.begins_with("GroundCover") or n.begins_with("GrassCarpet"):
		return 2
	if n in ["Props", "Trams", "Trains", "Boats", "Cars", "Vessels", "Aircraft"]:
		return 3
	return 0

## The swap: the staged world (finished now if it was not yet) becomes
## the view's world and shows; the old one hides and leaves over the
## next frames. Returns false when nothing is staged.
## With `keep_old` the old world only hides (WorldStreamer parks it).
func swap_in(v: View360, keep_old := false) -> bool:
	if staged == null or not is_instance_valid(staged):
		return false
	while not _pending.is_empty():
		_add_back(_pending.pop_front())
	var old := v._generated
	if old != null and is_instance_valid(old) and old != staged:
		if keep_old:
			old.visible = false
		else:
			retire(old)
	var next := staged
	var adopted := _staged_at == 1  # parked world: already rendered & warm
	if not adopted:
		var waves: Array = [[], [], []]
		for c in next.get_children():
			var w := _reveal_wave(c)
			if w > 0:
				(c as Node3D).visible = false
				(waves[w - 1] as Array).append(c)
		for bucket: Array in waves:
			if not bucket.is_empty():
				_revealing.append([next, bucket])
	v._generated = next
	next.visible = true
	staged = null
	return true

## Hides `old` and frees it over the next pumps.
func retire(old: Node3D) -> void:
	if old == null or not is_instance_valid(old) or old in _retiring:
		return
	_drop_revealing(old)
	old.visible = false
	_retiring.append(old)

func _drop_revealing(world: Node3D) -> void:
	var kept: Array = []
	for wave: Array in _revealing:
		if is_same(wave[0], world):
			for node: Variant in (wave[1] as Array):
				if is_instance_valid(node):
					(node as Node3D).visible = true
		else:
			kept.append(wave)
	_revealing = kept

## Drops a staged world that will not swap in (turned back, cancelled):
## it leaves like an old world, a slice at a time.
func drop_staged() -> void:
	if staged != null and is_instance_valid(staged):
		_free_pending()
		retire(staged)
	_pending.clear()
	staged = null

## Lets go of the fully staged world without freeing it: it stays in the
## tree, hidden, for WorldStreamer to park. Returns it, or null when
## nothing is fully staged.
func release() -> Node3D:
	if not ready_for(staged):
		return null
	var world := staged
	staged = null
	return world

## Takes `world` back as the staged world: one parked earlier, still in
## the tree, hidden, every subtree in place and dressed.
func adopt(world: Node3D) -> void:
	drop_staged()
	staged = world
	world.visible = false
	dressed = true
	_staged_at = 1  # settled long ago

## The view is going away: its world root frees everything still in the
## tree; only detached subtrees are freed here.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# No method of its own here: the script is already going.
		for piece: Variant in _pending:
			if is_instance_valid(piece[1]) and not (piece[1] as Node).is_inside_tree():
				(piece[1] as Node).free()
		for piece: Variant in _late:
			if is_instance_valid(piece[1]) and not (piece[1] as Node).is_inside_tree():
				(piece[1] as Node).free()
		if staged != null and is_instance_valid(staged) and not staged.is_inside_tree():
			staged.free()
		for old: Variant in _retiring:
			if is_instance_valid(old) and not (old as Node).is_inside_tree():
				(old as Node).free()
		if is_instance_valid(_holder):
			_holder.free()

## Pieces still off: each is freed itself (a child taken off its parent
## is no longer freed with it).
func _free_pending() -> void:
	for piece in _pending:
		if is_instance_valid(piece[1]) and not (piece[1] as Node).is_inside_tree():
			(piece[1] as Node).free()
	_pending.clear()

## Late pieces still off are freed themselves, like pending ones.
func _free_late() -> void:
	for piece in _late:
		if is_instance_valid(piece[1]) and not (piece[1] as Node).is_inside_tree():
			(piece[1] as Node).free()
	_late.clear()

func clear() -> void:
	_revealing.clear()
	_free_pending()
	_free_late()
	if staged != null and is_instance_valid(staged) and not staged.is_inside_tree():
		staged.free()
	staged = null
	for old: Variant in _retiring:
		if is_instance_valid(old) and not (old as Node).is_inside_tree():
			(old as Node).free()
	_retiring.clear()
