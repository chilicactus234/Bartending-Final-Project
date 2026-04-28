extends Area2D
@export var slot_index: int = 0

@onready var container_sprite: Sprite2D = $ContainerSprite
@onready var highlight: Sprite2D = $Highlight
@onready var transfer_highlight: Sprite2D = $TransferHighlight
@onready var serve_btn: TextureButton = $ServeButton
@onready var step_list: VBoxContainer = $StepList
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

const SHAKER_TEXTURE = null
# Replace null with preload("res://assets/sprites/shaker.png")
# once you have the shaker sprite ready

var _station: Node = null
var _hovered: bool = false

func _ready() -> void:
	_station = get_parent().get_parent() as Node
	input_pickable = true
	container_sprite.hide()
	highlight.hide()
	transfer_highlight.hide()
	serve_btn.hide()
	serve_btn.pressed.connect(func(): _station.serve_slot(slot_index))
	_station.slot_selected.connect(_on_slot_selected)
	_station.slot_updated.connect(_on_slot_updated)
	_station.transfer_started.connect(_on_transfer_started)
	_station.tool_picked_up.connect(_on_tool_picked_up)
	_station.tool_dropped.connect(_on_tool_dropped)
	_station.no_container_selected.connect(_on_no_container_selected)
	mouse_entered.connect(func(): _hovered = true; _update_highlight())
	mouse_exited.connect(func(): _hovered = false; _update_highlight())

func _input_event(_viewport, event, _shape_idx) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.button_index == MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var slot = _station.slots[slot_index]

	# Case 1: jigger loaded — pour into this slot
	if JiggerController.is_loaded:
		if not slot.is_occupied:
			_flash_warning()
			return
		JiggerController.pour(slot_index)
		audio.play()
		_bounce()
		return

	# Case 2: tool held — apply to this slot
	if _station.held_tool != "":
		if not slot.is_occupied:
			_flash_warning()
			return
		if _station.held_tool == "bar_spoon":
			_start_stir_mode()
			return
		_station.apply_tool_to_slot(slot_index)
		audio.play()
		return

	# Case 3: awaiting shaker transfer
	if _station.is_awaiting_transfer():
		if slot_index == _station.pending_transfer_slot:
			_station.pending_transfer_slot = -1
			transfer_highlight.hide()
			return
		if not slot.is_occupied \
		or slot.container_type != DrinkSlot.ContainerType.GLASS:
			_flash_warning()
			return
		_station.complete_transfer(slot_index)
		_play_pour_animation()
		return

	# Case 4: shaker in this slot
	if slot.is_occupied \
	and slot.container_type == DrinkSlot.ContainerType.SHAKER:
		if not slot.is_shaken:
			_station.add_action(
				{ "type": "step", "id": "shake" }, slot_index
			)
			_play_shake_animation()
		else:
			_station.begin_transfer(slot_index)
		return

	# Case 5: mixing glass in this slot
	if slot.is_occupied \
	and slot.container_type == DrinkSlot.ContainerType.MIXING_GLASS:
		if not slot.is_stirred:
			_station.emit_signal("no_container_selected")
		else:
			_station.begin_transfer(slot_index)
		return

	# Case 6: completed glass — drag to customer
	if slot.is_occupied \
	and slot.container_type == DrinkSlot.ContainerType.GLASS \
	and not slot.action_log.is_empty() \
	and not _station.is_awaiting_transfer() \
	and not DragController.is_dragging:
		DragController.start_drag(
			"completed_drink_%d" % slot_index,
			1.0,
			container_sprite.texture
		)
		return

	# Case 7: plain select
	_station.select_slot(slot_index)

# ─── Signal handlers ──────────────────────────────────────────────────────────

func _on_slot_selected(index: int) -> void:
	highlight.visible = (index == slot_index)

func _on_slot_updated(index: int) -> void:
	if index != slot_index:
		return
	var slot = _station.slots[slot_index]
	container_sprite.visible = slot.is_occupied
	if slot.is_occupied:
		match slot.container_type:
			DrinkSlot.ContainerType.SHAKER:
				if SHAKER_TEXTURE:
					container_sprite.texture = SHAKER_TEXTURE
			DrinkSlot.ContainerType.GLASS:
				if slot.glass_type != "":
					var tex = load(
						"res://assets/glasses/%s.png" % slot.glass_type
					)
					if tex:
						container_sprite.texture = tex
	serve_btn.visible = (
		slot.is_occupied
		and slot.container_type == DrinkSlot.ContainerType.GLASS
		and not slot.action_log.is_empty()
	)
	_rebuild_step_list(slot)

func _on_transfer_started(from_slot: int) -> void:
	var slot = _station.slots[slot_index]
	transfer_highlight.visible = (
		slot.is_occupied
		and slot.container_type == DrinkSlot.ContainerType.GLASS
		and slot_index != from_slot
	)

func _on_tool_picked_up(_tool_id: String) -> void:
	if _station.slots[slot_index].is_occupied:
		highlight.modulate = Color(1.0, 0.85, 0.2)
		highlight.show()

func _on_tool_dropped() -> void:
	highlight.modulate = Color.WHITE
	_update_highlight()

func _on_no_container_selected() -> void:
	if _hovered or _station.active_slot_index == slot_index:
		_flash_warning()

# ─── Stir mode ────────────────────────────────────────────────────────────────

func _start_stir_mode() -> void:
	var stir_detector = get_tree().get_first_node_in_group("stir_detector")
	var stir_indicator = get_tree().get_first_node_in_group("stir_indicator")
	if stir_detector == null or stir_indicator == null:
		return
	stir_detector.start(slot_index, global_position)
	stir_indicator.show_at(global_position)
	stir_detector.stir_completed.connect(
		_on_stir_completed, CONNECT_ONE_SHOT
	)
	stir_detector.stir_cancelled.connect(
		_on_stir_cancelled, CONNECT_ONE_SHOT
	)
	stir_detector.stir_progress_updated.connect(
		stir_indicator.update_progress
	)

func _on_stir_completed(completed_slot: int) -> void:
	if completed_slot != slot_index:
		return
	var stir_indicator = get_tree().get_first_node_in_group("stir_indicator")
	if stir_indicator:
		stir_indicator.hide_indicator()
	_disconnect_stir_signals()
	_station.stir_slot(slot_index)
	_station.drop_tool()
	audio.play()
	_play_stir_complete_flash()

func _on_stir_cancelled() -> void:
	var stir_indicator = get_tree().get_first_node_in_group("stir_indicator")
	if stir_indicator:
		stir_indicator.hide_indicator()
	_disconnect_stir_signals()

func _disconnect_stir_signals() -> void:
	var stir_detector = get_tree().get_first_node_in_group("stir_detector")
	var stir_indicator = get_tree().get_first_node_in_group("stir_indicator")
	if stir_detector and stir_indicator:
		if stir_detector.stir_progress_updated.is_connected(
			stir_indicator.update_progress
		):
			stir_detector.stir_progress_updated.disconnect(
				stir_indicator.update_progress
			)

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _rebuild_step_list(slot: DrinkSlot) -> void:
	for child in step_list.get_children():
		child.queue_free()
	for line in slot.get_readable_log():
		var lbl = Label.new()
		lbl.text = line
		step_list.add_child(lbl)

func _update_highlight() -> void:
	highlight.modulate = Color.WHITE
	highlight.visible = (_station.active_slot_index == slot_index)

func _bounce() -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(
		Tween.TRANS_BOUNCE
	)
	tween.tween_property(container_sprite, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(container_sprite, "scale", Vector2(1.0, 1.0), 0.15)

func _play_shake_animation() -> void:
	var tween = create_tween().set_ease(
		Tween.EASE_IN_OUT
	).set_trans(Tween.TRANS_SINE)
	tween.tween_property(
		container_sprite, "rotation_degrees", 15.0, 0.07
	)
	tween.tween_property(
		container_sprite, "rotation_degrees", -15.0, 0.07
	)
	tween.tween_property(
		container_sprite, "rotation_degrees", 15.0, 0.07
	)
	tween.tween_property(
		container_sprite, "rotation_degrees", -15.0, 0.07
	)
	tween.tween_property(
		container_sprite, "rotation_degrees", 0.0, 0.07
	)

func _play_pour_animation() -> void:
	var tween = create_tween().set_ease(
		Tween.EASE_OUT
	).set_trans(Tween.TRANS_SINE)
	tween.tween_property(
		container_sprite, "rotation_degrees", -45.0, 0.2
	)
	tween.tween_property(
		container_sprite, "rotation_degrees", 0.0, 0.3
	)

func _play_stir_complete_flash() -> void:
	var tween = create_tween()
	tween.tween_property(
		container_sprite, "modulate", Color(0.4, 0.9, 0.5), 0.1
	)
	tween.tween_property(
		container_sprite, "modulate", Color.WHITE, 0.3
	)

func _flash_warning() -> void:
	var tween = create_tween()
	tween.tween_property(
		container_sprite, "modulate", Color(1, 0.3, 0.3), 0.08
	)
	tween.tween_property(
		container_sprite, "modulate", Color.WHITE, 0.2
	)
