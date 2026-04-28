extends Node2D

var _progress: float = 0.0
var _visible_indicator: bool = false
var _spoon_angle: float = 0.0
var _center: Vector2 = Vector2.ZERO

const RING_RADIUS: float = 28.0
const RING_WIDTH: float = 4.0
const RING_COLOR_BG: Color = Color(0.3, 0.3, 0.3, 0.5)
const RING_COLOR_FILL: Color = Color(0.4, 0.9, 0.5, 0.9)

func _ready() -> void:
	add_to_group("stir_indicator")

func _process(_delta: float) -> void:
	if not _visible_indicator:
		return
	var mouse_pos = get_viewport().get_mouse_position()
	var offset = mouse_pos - _center
	_spoon_angle = atan2(offset.y, offset.x)
	queue_redraw()

func _draw() -> void:
	if not _visible_indicator:
		return
	draw_arc(
		_center,
		RING_RADIUS,
		0.0,
		TAU,
		32,
		RING_COLOR_BG,
		RING_WIDTH
	)
	if _progress > 0.0:
		draw_arc(
			_center,
			RING_RADIUS,
			-PI / 2.0,
			-PI / 2.0 + (_progress * TAU),
			max(3, int(_progress * 32)),
			RING_COLOR_FILL,
			RING_WIDTH
		)
	var spoon_tip = _center + Vector2(
		cos(_spoon_angle),
		sin(_spoon_angle)
	) * RING_RADIUS
	var spoon_base = _center + Vector2(
		cos(_spoon_angle),
		sin(_spoon_angle)
	) * (RING_RADIUS - 22.0)
	draw_line(spoon_base, spoon_tip, Color.WHITE, 2.0)

func show_at(center: Vector2) -> void:
	_center = center
	_progress = 0.0
	_visible_indicator = true
	queue_redraw()

func update_progress(progress: float) -> void:
	_progress = progress
	queue_redraw()

func hide_indicator() -> void:
	_visible_indicator = false
	queue_redraw()
