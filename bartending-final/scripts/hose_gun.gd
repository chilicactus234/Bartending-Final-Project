extends Node2D

signal nozzle_picked_up(ingredient_id: String)
signal nozzle_released

var held_nozzle: String = ""

func _ready() -> void:
	add_to_group("hose_gun")

func pick_up_nozzle(ingredient_id: String) -> void:
	held_nozzle = ingredient_id
	emit_signal("nozzle_picked_up", ingredient_id)

func release_nozzle() -> void:
	held_nozzle = ""
	emit_signal("nozzle_released")

func is_holding() -> bool:
	return held_nozzle != ""

func nozzle_color_for(ingredient_id: String) -> Color:
	match ingredient_id:
		"soda_water":  return Color(0.8, 0.95, 1.0)
		"cola":        return Color(0.25, 0.1, 0.05)
		"water":       return Color(0.9, 0.97, 1.0)
		"ginger_beer": return Color(0.9, 0.8, 0.5)
		"ginger_ale":  return Color(0.95, 0.9, 0.6)
		_:             return Color.WHITE
