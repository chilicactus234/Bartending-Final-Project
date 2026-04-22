extends Node

signal quest_assigned(quest: Resource)
signal quest_completed(quest: Resource)
signal quest_failed(quest: Resource)

var current_quest: Resource = null
var quest_complete: bool = false 
var quest_failed_flag: bool = false 

func assign_quest(quest: Resource) -> void:
	current_quest = quest
	quest_complete = false
	quest_failed_flag = false
	emit_signal("quest_assigned", quest)

func clear_quest() -> void:
	current_quest = null
	quest_complete = false 
	quest_failed_flag = false

func has_quest() -> bool:
	return current_quest != null

func evaluate_serve(
	customer_key: String,
	served_recipe: Resource,
	score: float
) -> void:
	if current_quest == null or quest_complete:
		return
	if current_quest.target_customer_key != "" \
	and current_quest.target_customer_key != customer_key:
		return
	if current_quest.required_ingredient != "":
		if current_quest.required_ingredient \
		not in served_recipe.ingredients.keys():
			return
	if current_quest.required_step != "":
		if current_quest.required_step != "":
			if current_quest.required_step \
			not in served_recipe.required_steps:
				return
	if current_quest.required_glass != "":
		if served_recipe.glass_type != current_quest.required_glass:
			return
	if current_quest.must_serve_correctly:
		if score < current_quest.score_threshold:
			return
	_complete_quest()

func _complete_quest() -> void:
	quest_complete = true
	emit_signal("quest_completed", current_quest)
	if current_quest.bonus_earnings > 0:
		GameState.add_earnings(current_quest.bonus_earnings)
	if current_quest.unlocks_ingredient != "":
		GameState.unlock_ingredient(current_quest.unlock_ingredient)
	if current_quest.unlock_customer != "":
		GameState.unlock_customer(current_quest.unlocks_customer)

func mark_failed() -> void:
	if quest_complete:
		return
	quest_failed_flag = true
	emit_signal("quest_failed", current_quest)
	
