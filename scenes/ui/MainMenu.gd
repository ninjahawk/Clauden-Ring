extends Control

signal start_game

@onready var title_label: Label = $VBox/Title
@onready var subtitle_label: Label = $VBox/Subtitle
@onready var prompt_label: Label = $VBox/Prompt
@onready var version_label: Label = $Version

var blink_timer: float = 0.0
var ready_to_start: bool = false
var fade_out: bool = false
var fade_alpha: float = 0.0

func _ready() -> void:
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	prompt_label.modulate.a = 0.0
	version_label.modulate.a = 0.0
	_animate_intro()

func _animate_intro() -> void:
	await get_tree().create_timer(0.4).timeout
	await _fade_label(title_label, 2.5)
	await get_tree().create_timer(0.3).timeout
	await _fade_label(subtitle_label, 1.5)
	await get_tree().create_timer(0.5).timeout
	await _fade_label(prompt_label, 1.0)
	await _fade_label(version_label, 0.8)
	ready_to_start = true

func _fade_label(label: Label, duration: float) -> void:
	var t := 0.0
	while t < 1.0:
		t = minf(t + get_process_delta_time() / duration, 1.0)
		label.modulate.a = t
		await get_tree().process_frame

func _process(delta: float) -> void:
	blink_timer += delta
	if ready_to_start and not fade_out:
		prompt_label.modulate.a = 0.5 + 0.5 * sin(blink_timer * 3.0)
	if fade_out:
		fade_alpha = minf(fade_alpha + delta * 2.5, 1.0)
		modulate.a = 1.0 - fade_alpha
		if fade_alpha >= 1.0:
			start_game.emit()
			queue_free()

func _input(event: InputEvent) -> void:
	if not ready_to_start or fade_out:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_begin_start()
	if event is InputEventMouseButton and event.pressed:
		_begin_start()

func _begin_start() -> void:
	fade_out = true
	prompt_label.modulate.a = 1.0
