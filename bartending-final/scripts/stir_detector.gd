extends Node

signal stir_completed(slot_index: int)
signal stir_progress_updated(progress: float)
signal stir_cancelled

@export var required_rotations: float = 2.0
@export var min_radius = 20.0

var _active: bool = false
var _slot_index: int = -1
var _glass_center: Vector2 = Vector2.ZERO
var _last_angle: float = 0.0
var _total_rotation: float = 0.0
var _mouse_held: bool = false

func _ready() -> void:
	add_to_group("stir_detector")

func _angle_difference(from: float, to: float) -> float:
	var diff = fmod(to - from + PI, TAU) - PI
	return diff

func _process(_delta: float) -> void:
	if not _active or not _mouse_held:
		return
	var mouse_pos = get_viewport().get_mouse_position()
	var offset = mouse_pos - _glass_center
	var distance = offset.length()
	if distance < min_radius:
		return
	var current_angle = atan2(offset.y, offset.x)
	var angle_delta = _angle_difference(_last_angle, current_angle)
	if abs (angle_delta) > 1.5:
		_last_angle = current_angle
		return
	_total_rotation += abs(angle_delta)
	_last_angle = current_angle
	var progress = clampf(_total_rotation / (required_rotations * TAU), 0.0, 1.0)
	emit_signal("stir_progress_updated", progress)
	if _total_rotation >= required_rotations * TAU:
		_complete()

func _angle_different(from: float, to: float) -> float:
	var diff = fmod(to - from + PI, TAU) - PI
	return diff

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_held = true
			var mouse_pos = get_viewport().get_mouse_position()
			_last_angle = atan2(
				(mouse_pos - _glass_center).y,
				(mouse_pos - _glass_center).x
			)
		else:
			_mouse_held = false
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_RIGHT \
	and event.pressed:
		_cancel()

func start(slot_index: int, glass_center_world: Vector2) -> void:
	_active = true
	_slot_index = slot_index
	_glass_center = glass_center_world
	_total_rotation = 0.0
	_mouse_held = false
	_last_angle = 0.0

func stop() -> void:
	_active = false
	_mouse_held = false
	_slot_index = -1
	_total_rotation = 0.0

func _complete() -> void:
	var completed_slot = _slot_index
	stop()
	emit_signal("stir_completed", completed_slot)

func _cancel() -> void:
	stop()
	emit_signal("stir_cancelled")

func is_active() -> bool:
	return _active
