extends Node2D

var player: Node = null
var camera: Camera3D = null
var reticle_alpha: float = 0.0
var spin: float = 0.0
var screen_pos: Vector2 = Vector2.ZERO
var current_target: Node = null

@onready var name_label: Label = $CanvasLayer/NameLabel
@onready var hp_fill: ColorRect = $CanvasLayer/TargetBar/Fill

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	name_label.modulate.a = 0.0
	hp_fill.modulate.a = 0.0

func _process(delta: float) -> void:
	camera = get_viewport().get_camera_3d()
	if not camera or not player:
		_fade_out(delta)
		return
	var target: Node = player.get("lock_target")
	if not target or target.get("is_dead"):
		_fade_out(delta)
		return
	reticle_alpha = move_toward(reticle_alpha, 1.0, delta * 10.0)
	name_label.modulate.a = reticle_alpha
	hp_fill.modulate.a = reticle_alpha
	spin += delta * 1.2
	var world_pos: Vector3 = target.global_position + Vector3(0, 1.0, 0)
	screen_pos = camera.unproject_position(world_pos)
	# Update name if target changed
	if target != current_target:
		current_target = target
		var dname = target.get("display_name")
		name_label.text = str(dname) if dname else "???"
	# Update target HP bar
	var hp_pct: float = clampf(float(target.get("hp")) / float(target.get("HP_MAX")), 0.0, 1.0)
	hp_fill.size.x = 200.0 * hp_pct
	queue_redraw()

func _fade_out(delta: float) -> void:
	reticle_alpha = move_toward(reticle_alpha, 0.0, delta * 6.0)
	name_label.modulate.a = reticle_alpha
	hp_fill.modulate.a = reticle_alpha
	current_target = null
	queue_redraw()

func _draw() -> void:
	if reticle_alpha <= 0.01:
		return
	var a := reticle_alpha
	var r := 22.0
	var col := Color(1.0, 0.9, 0.3, a)
	var col_dim := Color(1.0, 0.6, 0.1, a * 0.5)
	for i in 4:
		var angle := spin + i * PI * 0.5
		draw_arc(screen_pos, r, angle, angle + PI * 0.35, 16, col, 2.0)
	draw_arc(screen_pos, r * 0.45, 0, TAU, 24, col_dim, 1.5)
	draw_circle(screen_pos, 2.5, Color(1.0, 0.9, 0.3, a))
