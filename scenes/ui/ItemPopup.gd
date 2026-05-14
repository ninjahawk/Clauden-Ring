extends CanvasLayer

@onready var panel: Control = $Panel
@onready var name_label: Label = $Panel/VBox/ItemName
@onready var desc_label: Label = $Panel/VBox/ItemDesc

func _ready() -> void:
	add_to_group("item_popup")
	panel.modulate.a = 0.0

func show_item(item_name: String, description: String) -> void:
	name_label.text = item_name
	desc_label.text = description
	_animate()

func _animate() -> void:
	var t := 0.0
	while t < 1.0:
		t = minf(t + get_process_delta_time() * 3.0, 1.0)
		panel.modulate.a = t
		await get_tree().process_frame
	await get_tree().create_timer(3.5).timeout
	t = 1.0
	while t > 0.0:
		t = maxf(t - get_process_delta_time() * 1.5, 0.0)
		panel.modulate.a = t
		await get_tree().process_frame
