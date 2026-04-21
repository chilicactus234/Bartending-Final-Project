extends Node

signal volume_selected(ml: float, display_label: String)
signal ingredient_loaded(ingredient_id: String, ml: float, display_label: String)
signal jigger_poured(ingredient_id: String, ml : float, display_label: String)
signal jigger_reset

enum State { EMPTY, VOLUME_SELECTED, INGREDIENT_LOADED }

var state: State = State.EMPTY
var selected_volume_ml: float = 0.0
var selected_display_label: String = ""
var loaded_ingredient_id: String = ""
var loaded_volume_ml: float = 0.0
var loaded_display_label: String = ""

var is_loaded: bool:
	get:
		return state == State.INGREDIENT_LOADED

var has_volume: bool:
	get:
		return state == State.VOLUME_SELECTED \
			or state == State.INGREDIENT_LOADED

func set_volume(ml: float, display_label: String) ->  void:
	selected_volume_ml = ml
	selected_display_label = display_label
	state = State.VOLUME_SELECTED
	emit_signal("volume_selected", ml, display_label)
	
func load_ingredient(ingredient_id: String) -> void:
	if state != State.VOLUME_SELECTED:
		return
	loaded_ingredient_id = ingredient_id
	loaded_volume_ml = selected_volume_ml
	loaded_display_label = selected_display_label
	state = State.INGREDIENT_LOADED
	emit_signal("ingredient_loaded", ingredient_id, loaded_volume_ml, loaded_display_label)

func pour(target_slot: int) -> void:
	if state != State.INGREDIENT_LOADED:
		return
	var station = get_tree().get_first_node_in_group("crafting_station")
	if station == null:
		push_error("JiggerController: could not find crafting_station group")
		return
	station.add_action({
		"type": "ingredient",
		"id": loaded_ingredient_id,
		"amount": loaded_volume_ml,
		"dislay": loaded_display_label,	
	}, target_slot)
	emit_signal("jigger_poured", loaded_ingredient_id, loaded_volume_ml, loaded_display_label)
	reset()

func reset() -> void:
	state = State.EMPTY
	selected_volume_ml = 0.0
	selected_display_label = ""
	loaded_ingredient_id = ""
	loaded_volume_ml = 0.0
	loaded_display_label = ""
	emit_signal("jigger_reset")
	
	
