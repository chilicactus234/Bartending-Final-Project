extends CanvasLayer

signal dialogue_started
signal dialogue_ended

var dialogue_db: Dictionary = {}
var current_lines: Array = []
var line_index: int = 0
var is_active: bool = false
var current_customer: Node = null

var dialogue_box: Node = null

func _ready() -> void:
	# layer = 10
	_load_dialogue()

func _load_dialogue() -> void:
	if not FileAccess.file_exists("res://data/dialogue.json"):
		push_warning("DialogueSystem: dialogue.json not found")
		return
	var file = FileAccess.open("res://data/dialogue.json", FileAccess.READ)
	if file == null:
		push_error("DialogueSystem: could not open dialogue.json")
		return
	var result = JSON.parse_string(file.get_as_text())
	if result == null:
		push_error("DialogueSystem: dialogue.json failed to parse")
		return
	dialogue_db = result

func set_dialogue_box(box:Node) -> void:
	dialogue_box = box
	if dialogue_box:
		dialogue_box.advance_requested.connect(_on_advance_requested)
		dialogue_box.choice_selected.connect(_on_choice_selected)

func start_dialogue(key: String) -> void:
	if is_active:
		return
	var lines = dialogue_db.get(key, [])
	if lines.is_empty():
		push_warning("DialogueSystem: no lines found for key '%s'" % key)
		return
	_begin(lines)

func start_order_dialogue(customer: Node) -> void:
	if is_active:
		return
	current_customer = customer
	var key = _pick_dialogue_key(customer)
	var lines = dialogue_db.get(key, _fallback_lines(customer))
	_begin(lines)

func end_dialogue() -> void:
	is_active = false
	if dialogue_box:
		dialogue_box.hide()
	if current_customer and current_customer.has_method("_set_state"):
		current_customer._set_state(
			current_customer.State.WAITING
		)
	current_customer = null
	emit_signal("dialogue_ended")

func _begin(lines: Array) -> void:
	current_lines = lines
	line_index = 0
	is_active = true
	if dialogue_box:
		dialogue_box.show()
	emit_signal("dialogue_started")
	_show_line()

func _show_line() -> void:
	if line_index >= current_lines.size():
		end_dialogue()
		return
	var line: Dictionary = current_lines[line_index]
	if line.has("goto") and not line.has("text"):
		line_index = _find_label(line.goto)
		_show_line()
		return
	if line.has("tag"):
		_run_tag(line.tag)
	if dialogue_box:
		dialogue_box.display(
			line.get("speaker", ""),
			line.get("text", ""),
			line.get("choices", []),
			line.get("portrait", "")
		)

func _on_advance_requested() -> void:
	line_index += 1
	_show_line()

func _on_choice_selected(choice: Dictionary) -> void:
	if choice.has("goto"):
		line_index = _find_label(choice.goto)
	else:
		line_index += 1
	_show_line()

func _find_label(label_name: String) -> int:
	for i in current_lines.size():
		if current_lines[i].get("label", "") == label_name:
			return i
	push_warning("DialogueSystem: label '%s' not found" % label_name)
	return current_lines.size()

func _pick_dialogue_key(customer: Node) -> String:
	var base = customer.assigned_recipe.dialogue_key
	match customer.data.order_style:
		"vague":
			var vague_key = base + "_vague"
			if dialogue_db.has(vague_key):
				return vague_key
		"regular":
			var regular_key = base + "_regular"
			if dialogue_db.has(regular_key):
				return regular_key
	return base + "_explicit"

func _fallback_lines(customer: Node) -> Array:
	return [{
		"speaker": customer.data.customer_name,
		"text": "I'll have a %s, please." % customer.assigned_recipe.drink_name
	}]

func _run_tag(tag: String) -> void:
	match tag:
		"order_placed":
			if current_customer and current_customer.has_method("play_anim"):
				current_customer.play_anim("order_gesture")
		"michael_remove_mask":
			if current_customer:
				current_customer.data.customer_name = "Michael"
		"michael_remove_mask_if_not_already":
			if current_customer:
				if current_customer.data.customer_name != "Michael":
					current_customer.data.customer_name = "Michael"
		"michael_put_mask_back_on":
			if current_customer:
				current_customer.data.customer_name = "M.I.C.H.A.E.L."
		"michael_second_order":
			if current_customer:
				var shirley = load("res://data/recipes/shirley_temple.tres")
				if shirley:
					current_customer.second_recipe = shirley
					current_customer.has_second_order = true
					current_customer.start_second_order()
		"michael_drink_animation":
			if current_customer and current_customer.has_method("play_anim"):
				current_customer.play_anim("drink")
		"michael_robot_callback":
			if current_customer and current_customer.has_method("play_anim"):
				current_customer.play_anim("robot_gesture")
