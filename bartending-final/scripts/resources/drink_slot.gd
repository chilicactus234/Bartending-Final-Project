class_name DrinkSlot
extends RefCounted

enum ContainerType { EMPTY, GLASS, SHAKER, MIXING_GLASS }

var slot_index: int = 0
var container_type: ContainerType = ContainerType.EMPTY
var glass_type: String = ""
var action_log: Array[Dictionary] = []
var is_occupied: bool = false
var is_shaken: bool = false
var is_stirred: bool = false
var is_ready_to_serve: bool = false
var target_recipe: Resource = null
var linked_slot_index: int = -1

func add_action(action: Dictionary) -> void:
	action_log.append(action)
	if action.type == "step":
		match action.id:
			"shake": is_shaken = true
			"stir":  is_stirred = true

func accumulate_ingredient(ingredient_id: String, amount: float, display: String = "") -> void:
	for action in action_log:
		if action.type == "ingredient" and action.id == ingredient_id:
			action.amount += amount
			return
	action_log.append({
		"type": "ingredient",
		"id": ingredient_id,
		"amount": amount,
		"display": display
	})

func transfer_contents_to(target: DrinkSlot) -> void:
	for action in action_log:
		if action.type == "ingredient":
			target.accumulate_ingredient(
				action.id,
				action.amount,
				action.get("display", "")
			)
	if container_type == ContainerType.SHAKER and is_shaken:
		target.action_log.append({ "type": "step", "id": "shake" })
		target.action_log.append({ "type": "step", "id": "strain" })
		target.is_shaken = true
	elif container_type == ContainerType.MIXING_GLASS and is_stirred:
		target.action_log.append({ "type": "step", "id": "stir" })
		target.action_log.append({ "type": "step", "id": "strain" })
		target.is_stirred = true
	action_log.clear()
	is_shaken = false
	is_stirred = false

func add_garnish(garnish_id: String) -> void:
	action_log.append({
		"type": "garnish",
		"id": garnish_id
	})

func extract_ingredients() -> Dictionary:
	var result: Dictionary = {}
	for action in action_log:
		if action.type == "ingredient":
			result[action.id] = result.get(action.id, 0.0) + action.amount
	return result

func extract_steps() -> Array[String]:
	var result: Array[String] = []
	for action in action_log:
		if action.type == "step" and action.id not in result:
			result.append(action.id)
	return result

func extract_garnish() -> String:
	for action in action_log:
		if action.type == "garnish":
			return action.id
	return ""

func get_readable_log() -> Array[String]:
	var lines: Array[String] = []
	for action in action_log:
		match action.type:
			"ingredient":
				var ing = action.id.replace("_", " ")
				var measure = action.get("display", "")
				if measure == "":
					measure = "%.0f mL" % action.amount
				lines.append("%s %s" % [measure, ing])
			"step":
				lines.append(action.id.replace("_", " ").capitalize())
			"garnish":
				lines.append("Garnish: %s" % action.id.replace("_", " "))
	return lines

func clear() -> void:
	container_type = ContainerType.EMPTY
	glass_type = ""
	action_log.clear()
	is_occupied = false
	is_shaken = false
	is_stirred = false
	is_ready_to_serve = false
	target_recipe = null
	linked_slot_index = -1
