extends Node2D

var player: Node = null
var camera: Camera3D = null
var reticle_alpha: float = 0.0
var spin: float = 0.0
var screen_pos: Vector2 = Vector2.ZERO
var show_reticle: bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	camera = get_viewport().get_camera_3d()
	if not camera or not player:
		show_reticle = false
		reticle_alpha = move_toward(reticle_alpha, 0.0, delta * 6.0)
		queue_redraw()
		return

	var target: Node = player.get("lock_target")
	if not target or target.get("is_dead"):
		show_reticle = false
		reticle_alpha = move_toward(reticle_alpha, 0.0, delta * 6.0)
		queue_redraw()
		return

	show_reticle = true
	reticle_alpha = move_toward(reticle_alpha, 1.0, delta * 10.0)
	spin += delta * 1.2
	var world_pos: Vector3 = target.global_position + Vector3(0, 1.0, 0)
	screen_pos = camera.unproject_position(world_pos)
	queue_redraw()

func _draw() -> void:
	if reticle_alpha <= 0.01:
		return
	var a := reticle_alpha
	var r := 22.0
	var col_outer := Color(1.0, 0.9, 0.3, a)
	var col_inner := Color(1.0, 0.6, 0.1, a * 0.5)
	# Outer spinning arc segments
	for i in 4:
		var angle := spin + i * PI * 0.5
		var arc_start := angle
		var arc_end := angle + PI * 0.35
		draw_arc(screen_pos, r, arc_start, arc_end, 16, col_outer, 2.0)
	# Inner static circle
	draw_arc(screen_pos, r * 0.45, 0, TAU, 24, col_inner, 1.5)
	# Center dot
	draw_circle(screen_pos, 2.5, Color(1.0, 0.9, 0.3, a))
