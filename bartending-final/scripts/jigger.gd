extends Area2D
@export var hover_rise_px: float = 6.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var info_popup: Label = $InfoPopup
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var volume_selector: CanvasLayer = $VolumeSelector

var _base_y: float = 0.0
var _tween: Tween = null
var _hovered: bool = false

func _ready() -> void:
	_base_y = position.y
	input_pickable = true
	info_popup.text = "Jigger"
	info_popup.hide()
	volume_selector.volume_chosen.connect(_on_volume_chosen)
	JiggerController.jigger_reset.connect(_on_jigger_reset)
	JiggerController.ingredient_loaded.connect(_on_ingredient_loaded)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_hovered = true
	info_popup.show()
	if not JiggerController.is_loaded:
		sprite.play("hover")
	if _tween: _tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position:y", _base_y - hover_rise_px, 0.15)
	audio.play()

func _on_mouse_exited() -> void:
	_hovered = false
	info_popup.hide()
	sprite.play("loaded" if JiggerController.is_loaded else "idle")
	if _tween: _tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position:y", _base_y, 0.12)

func _input_event(_viewport, event, _shape_idx) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.button_index == MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if volume_selector.visible:
		return
	if JiggerController.is_loaded:
		JiggerController.reset()
		return
	volume_selector.show()

func _on_volume_chosen(ml: float, display_label: String) -> void:
	JiggerController.set_volume(ml, display_label)
	sprite.play("loaded")
	info_popup.text = "%s — click ingredient" % display_label

func _on_ingredient_loaded(_id: String, _ml: float, display_label: String) -> void:
	info_popup.text = "%s — click glass" % display_label
	sprite.play("loaded")

func _on_jigger_reset() -> void:
	sprite.play("idle")
	info_popup.text = "Jigger"
