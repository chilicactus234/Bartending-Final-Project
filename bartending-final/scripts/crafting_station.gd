extends Node2D

signal drink_completed(served_recipe: DrinkRecipe, slot_index: int)
signal action_added(action: Dictionary, slot_index: int)
signal slot_selected(slot_index: int)
signal slot_updated(slot_index: int)
signal transfer_started(from_slot: int)
signal no_container_selected
signal tool_picked_up(tool_id: String)
signal tool_dropped

const MAX_SLOTS: int = 5

var slots: Array[DrinkSlot] = []
var active_slot_index: int = -1
var held_tool: String = ""
var pending_transfer_slot: int = -1

var active_slot: DrinkSlot:
	get:
		if active_slot_index == -1:
			return null
		return slots[active_slot_index]

func _ready() -> void:
	add_to_group("crafting_station")
	for i in MAX_SLOTS:
		var slot = DrinkSlot.new()
		slot.slot_index = i
		slots.append(slot)

func place_glass(glass_id: String, slot_index: int) -> void:
	if slots[slot_index].is_occupied:
		return
	slots[slot_index].glass_type = glass_id
	slots[slot_index].container_type = DrinkSlot.ContainerType.GLASS
	slots[slot_index].is_occupied = true
	active_slot_index = slot_index
	emit_signal("slot_selected", slot_index)
	emit_signal("slot_updated", slot_index)

func place_shaker(slot_index: int) -> void:
	if slots[slot_index].is_occupied:
		return
	slots[slot_index].container_type = DrinkSlot.ContainerType.SHAKER
	slots[slot_index].is_occupied = true
	active_slot_index = slot_index
	emit_signal("slot_selected", slot_index)
	emit_signal("slot_updated", slot_index)

func place_mixing_glass(slot_index: int) -> void:
	if slots[slot_index].is_occupied:
		return
	slots[slot_index].container_type = DrinkSlot.ContainerType.MIXING_GLASS
	slots[slot_index].is_occupied = true
	active_slot_index = slot_index
	emit_signal("slot_selected", slot_index)
	emit_signal("slot_updated", slot_index)

func remove_container(slot_index: int) -> void:
	slots[slot_index].clear()
	if active_slot_index == slot_index:
		active_slot_index = -1
	emit_signal("slot_updated", slot_index)

func assign_recipe_to_slot(slot_index: int, recipe: DrinkRecipe) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	slots[slot_index].target_recipe = recipe
	emit_signal("slot_updated", slot_index)

func add_action(action: Dictionary, target_slot: int = -1) -> void:
	var index = target_slot if target_slot != -1 else active_slot_index
	if index == -1 or not slots[index].is_occupied:
		emit_signal("no_container_selected")
		return
	slots[index].add_action(action)
	emit_signal("action_added", action, index)
	emit_signal("slot_updated", index)

func add_garnish(garnish_id: String, target_slot: int = -1) -> void:
	var index = target_slot if target_slot != -1 else active_slot_index
	if index == -1 or not slots[index].is_occupied:
		emit_signal("no_container_selected")
		return
	if slots[index].container_type != DrinkSlot.ContainerType.GLASS:
		return
	slots[index].add_garnish(garnish_id)
	emit_signal("slot_updated", index)

func begin_transfer(from_slot: int) -> void:
	pending_transfer_slot = from_slot
	emit_signal("transfer_started", from_slot)

func complete_transfer(to_slot: int) -> void:
	if pending_transfer_slot == -1:
		return
	var from = slots[pending_transfer_slot]
	var to = slots[to_slot]
	if not to.is_occupied or to.container_type != DrinkSlot.ContainerType.GLASS:
		pending_transfer_slot = -1
		return
	from.transfer_contents_to(to)
	emit_signal("slot_updated", pending_transfer_slot)
	emit_signal("slot_updated", to_slot)
	active_slot_index = to_slot
	emit_signal("slot_selected", to_slot)
	pending_transfer_slot = -1

func is_awaiting_transfer() -> bool:
	return pending_transfer_slot != -1

func stir_slot(slot_index: int) -> void:
	var slot = slots[slot_index]
	if not slot.is_occupied:
		return
	slot.add_action({ "type": "step", "id": "stir" })
	emit_signal("slot_updated", slot_index)

func pick_up_tool(tool_id: String) -> void:
	held_tool = tool_id
	emit_signal("tool_picked_up", tool_id)

func apply_tool_to_slot(slot_index: int) -> void:
	if held_tool == "":
		return
	if held_tool == "bar_spoon":
		stir_slot(slot_index)
		drop_tool()
		return
	add_action({ "type": "step", "id": held_tool }, slot_index)
	drop_tool()

func drop_tool() -> void:
	held_tool = ""
	emit_signal("tool_dropped")

func serve_slot(slot_index: int) -> void:
	var slot = slots[slot_index]
	if not slot.is_occupied:
		return
	if slot.container_type != DrinkSlot.ContainerType.GLASS:
		return
	if slot.action_log.is_empty():
		return
	var served := DrinkRecipe.new()
	served.glass_type = slot.glass_type
	served.ingredients = slot.extract_ingredients()
	served.required_steps = slot.extract_steps()
	served.garnish = slot.extract_garnish()
	emit_signal("drink_completed", served, slot_index)
	slot.clear()
	if active_slot_index == slot_index:
		active_slot_index = -1
	emit_signal("slot_updated", slot_index)

func reset_all() -> void:
	for slot in slots:
		slot.clear()
	active_slot_index = -1
	held_tool = ""
	pending_transfer_slot = -1
	JiggerController.reset()
	DragController.end_drag()
