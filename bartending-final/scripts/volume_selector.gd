extends CanvasLayer
signal volume_chosen(ml: float, display_label: String)

const VOLUMES = [
	[15.0,  "PanelContainer/VBoxContainer/Btn15",      "15 mL"],
	[30.0,  "PanelContainer/VBoxContainer/Btn30",      "30 mL"],
	[45.0,  "PanelContainer/VBoxContainer/Btn45",      "45 mL"],
	[60.0,  "PanelContainer/VBoxContainer/Btn60",      "60 mL"],
	[0.6,   "PanelContainer/VBoxContainer/BtnDash",    "1 dash"],
	[1.2,   "PanelContainer/VBoxContainer/BtnTwoDash", "2 dashes"],
	[15.0,  "PanelContainer/VBoxContainer/BtnSplash",  "splash"],
]

func _ready() -> void:
	hide()
	for entry in VOLUMES:
		var ml: float = entry[0]
		var path: String = entry[1]
		var label: String = entry[2]
		get_node(path).pressed.connect(func(): _on_chosen(ml, label))

func _on_chosen(ml: float, display_label: String) -> void:
	hide()
	emit_signal("volume_chosen", ml, display_label)

func _unhandled_input(event: InputEvent) -> void:
	if visible \
	and event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_RIGHT \
	and event.pressed:
		hide()
		get_viewport().set_input_as_handled()
