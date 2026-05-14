extends CanvasLayer

@onready var label: Label = $Label

func _ready() -> void:
	label.modulate.a = 0.0

func show_zone(zone_name: String) -> void:
	label.text = zone_name
	_animate()

func _animate() -> void:
	var t := 0.0
	# Fade in
	while t < 1.0:
		t = minf(t + get_process_delta_time() * 1.2, 1.0)
		label.modulate.a = t
		await get_tree().process_frame
	await get_tree().create_timer(2.5).timeout
	# Fade out
	t = 1.0
	while t > 0.0:
		t = maxf(t - get_process_delta_time() * 0.6, 0.0)
		label.modulate.a = t
		await get_tree().process_frame
