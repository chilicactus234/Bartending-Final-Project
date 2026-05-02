extends Area2D
@export var ingredient_id: String = ""
@export var ingredient_label: String = ""
@export var hover_rise_px: float = 8.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var info_popup: Label = $InfoPopup

var _base_y: float = 0.0
var _tween: Tween = null
var _hovered: bool = false

func _ready() -> void:
	_base_y = position.y
	input_pickable = true
	if info_popup:
		info_popup.text = ingredient_label
		info_popup.hide()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	JiggerController.jigger_reset.connect(func(): 
		if sprite:
			sprite.play("idle")
	)

func _on_mouse_entered() -> void:
	_hovered = true
	if info_popup:
		info_popup.show()
	sprite.play("hover")
	if _tween: _tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position:y", _base_y - hover_rise_px, 0.15)

func _on_mouse_exited() -> void:
	_hovered = false
	if info_popup:
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
	if not JiggerController.has_volume:
		_flash_hint()
		return
	if JiggerController.is_loaded:
		if JiggerController.loaded_ingredient_id != ingredient_id:
			JiggerController.reset()
		return
	JiggerController.load_ingredient(ingredient_id)
	sprite.play("tilt")
	await get_tree().create_timer(0.4).timeout
	if not _hovered:
		sprite.play("idle")

func _flash_hint() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.85, 0.3), 0.08)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
