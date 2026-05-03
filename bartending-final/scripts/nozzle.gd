extends Area2D

@export var ingredient_id: String = ""
@export var ingredient_label: String = ""
@export var amount: float = 15.0
@export var hover_animation: String = ""
# Set this in Inspector to match the animation name
# e.g. "ginger_beer_hover" for the ginger beer nozzle

@onready var info_popup: Label = $InfoPopup

var _gun: Node = null
var _tap_sprite: AnimatedSprite2D = null
var _hovered: bool = false
var _held: bool = false

func _ready() -> void:
	_gun = get_parent()
	_tap_sprite = _gun.get_node("TapSprite")
	input_pickable = true
	if info_popup:
		info_popup.text = ingredient_label
		info_popup.hide()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_gun.nozzle_released.connect(_on_nozzle_released)

func _on_mouse_entered() -> void:
	_hovered = true
	if info_popup:
		info_popup.show()
	if _tap_sprite and hover_animation != "":
		_tap_sprite.play(hover_animation)

func _on_mouse_exited() -> void:
	_hovered = false
	if info_popup:
		info_popup.hide()
	if not _held and _tap_sprite:
		_tap_sprite.play("idle")

func _input_event(_viewport, event, _shape_idx) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.button_index == MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if _gun.is_holding():
		if _gun.held_nozzle == ingredient_id:
			_gun.release_nozzle()
		return
	if JiggerController.is_loaded or DragController.is_dragging:
		return
	_held = true
	_gun.pick_up_nozzle(ingredient_id)

func _on_nozzle_released() -> void:
	_held = false
	if not _hovered and _tap_sprite:
		_tap_sprite.play("idle")
