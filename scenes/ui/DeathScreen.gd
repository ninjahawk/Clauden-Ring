extends CanvasLayer

signal respawn_ready

@onready var overlay: ColorRect = $Overlay
@onready var label: Label = $Label

func _ready() -> void:
	overlay.color = Color(0, 0, 0, 0)
	label.modulate.a = 0.0
	visible = false

func play(respawn_callback: Callable) -> void:
	visible = true
	await _fade_in()
	await get_tree().create_timer(1.5).timeout
	respawn_callback.call()
	await get_tree().create_timer(0.5).timeout
	await _fade_out()
	visible = false

func _fade_in() -> void:
	var t := 0.0
	while t < 1.0:
		t = minf(t + get_process_delta_time() * 2.5, 1.0)
		overlay.color.a = t
		label.modulate.a = maxf(0.0, (t - 0.4) / 0.6)
		await get_tree().process_frame

func _fade_out() -> void:
	var t := 1.0
	while t > 0.0:
		t = maxf(t - get_process_delta_time() * 2.0, 0.0)
		overlay.color.a = t
		label.modulate.a = t
		await get_tree().process_frame
