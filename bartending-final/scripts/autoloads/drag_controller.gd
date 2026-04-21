extends Node

signal drag_started(ingredient_id: String, icon: Texture2D)
signal drag_ended

var is_dragging: bool = false
var dragged_ingredient_id: String = ""
var dragged_amount: float = 1.0
var dragged_icon: Texture2D = null

func start_drag(ingredient_id: String, amount: float, icon:Texture2D) -> void:
	is_dragging = true
	dragged_ingredient_id = ingredient_id
	dragged_amount = amount
	dragged_icon = icon
	emit_signal("drag_started", ingredient_id, icon)

func end_drag() -> void:
	is_dragging = false
	dragged_ingredient_id = ""
	dragged_amount = 1.0
	dragged_icon = null
	emit_signal("drag_ended")
