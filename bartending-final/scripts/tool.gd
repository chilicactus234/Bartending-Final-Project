extends Area2D

@export var tool_id: String = ""
@export var tool_label: String = ""
@export var hover_rise_px: float = 6.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var info_popup: Label = $InfoPopup

var _station: Node = null
var _base_y: float = 0.0
var _tween: Tween = null
var _held: bool = false
var _hovered: bool = false

func _ready() -> void:
	_station = get_tree().get_first_node_in_group("crafting_station")
	_base_y = position.y
	input_pickable = true
	if info_popup:
		info_popup.text = tool_label
		info_popup.hide()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_station.tool_dropped.connect(_on_tool_dropped)

func _on_mouse_entered() -> void:
	_hovered = true
	if info_popup:
		info_popup.show()
	if not _held:
		sprite.play("hover")
		if _tween: _tween.kill()
		_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		_tween.tween_property(self, "position:y", _base_y - hover_rise_px, 0.15)

func _on_mouse_exited() -> void:
	_hovered = false
	if info_popup:
		info_popup.hide()
	if not _held:
		sprite.play("idle")
		if _tween: _tween.kill()
		_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		_tween.tween_property(self, "position:y", _base_y, 0.12)

func _input_event(_viewport, event, _shape_idx) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.button_index == MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if _held:
		_station.drop_tool()
		return
	_held = true
	sprite.play("hover")
	if _tween: _tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position:y", _base_y - hover_rise_px, 0.1)
	_station.pick_up_tool(tool_id)

func _on_tool_dropped() -> void:
	_held = false
	sprite.play("idle")
	if _tween: _tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position:y", _base_y, 0.12)
