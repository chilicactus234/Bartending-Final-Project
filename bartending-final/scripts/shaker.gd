extends Area2D

@export var hover_rise_px: float = 6.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var info_popup: Label = $InfoPopup
#@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

var _station: Node = null
var _base_y: float = 0.0
var _tween: Tween = null
var _hovered: bool = false

func _ready() -> void:
	_station = get_tree().get_first_node_in_group("crafting_station")
	_base_y = position.y
	input_pickable = true
	info_popup.text = "Cocktail Shaker"
	info_popup.hide()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_hovered = true
	info_popup.show()
	sprite.play("hover")
	if _tween: _tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position:y", _base_y - hover_rise_px, 0.15)
	#audio.play()

func _on_mouse_exited() -> void:
	_hovered = false
	info_popup.hide()
	sprite.play("idle")
	if _tween: _tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position:y", _base_y, 0.12)

func _input_event(_viewport, event, _shape_idx) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.button_index == MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if DragController.is_dragging or JiggerController.is_loaded:
		return
	for i in _station.MAX_SLOTS:
		if not _station.slots[i].is_occupied:
			_station.place_shaker(i)
			#audio.play()
			_animate_place()
			return
	_flash_full()

func _animate_place() -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", _base_y - hover_rise_px * 1.5, 0.1)
	tween.tween_property(self, "position:y", _base_y, 0.2)

func _flash_full() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.08)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
