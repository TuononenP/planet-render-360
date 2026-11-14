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
const SPLIT_CHILDREN := 32

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
	while not _pending.is_empty() and (not moved or Time.get_ticks_usec() - t < budget_us):
		_add_back(_pending.pop_front())
		moved = true
		if _pending.is_empty():
			_staged_at = Time.get_ticks_msec()
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

## Milliseconds `world` has been fully staged (0 when it is not): the
## renderer finishes its first uploads meanwhile, which a swap right
## after staging pays in its first visible frames instead.
func staged_ms(world: Node3D) -> int:
	return Time.get_ticks_msec() - _staged_at if ready_for(world) and _staged_at > 0 else 0

func busy() -> bool:
	return not _pending.is_empty() or not _retiring.is_empty()

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
	v._generated = staged
	staged.visible = true
	staged = null
	return true

## Hides `old` and frees it over the next pumps.
func retire(old: Node3D) -> void:
	if old == null or not is_instance_valid(old) or old in _retiring:
		return
	old.visible = false
	_retiring.append(old)

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
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_holder):
		_holder.free()

## Pieces still off: each is freed itself (a child taken off its parent
## is no longer freed with it).
func _free_pending() -> void:
	for piece in _pending:
		if is_instance_valid(piece[1]):
			(piece[1] as Node).free()
	_pending.clear()

func clear() -> void:
	_free_pending()
	staged = null
	_retiring.clear()
