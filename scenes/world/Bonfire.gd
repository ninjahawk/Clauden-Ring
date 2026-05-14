extends Node3D

const INTERACT_RANGE := 2.5

var player: Node = null
var kindled: bool = false
var interact_prompt_shown: bool = false

@onready var glow_mesh: MeshInstance3D = $Glow
@onready var particles: GPUParticles3D = $Particles

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if not player or player.get("is_dead"):
		return
	var dist: float = player.global_position.distance_to(global_position)
	if dist <= INTERACT_RANGE and Input.is_action_just_pressed("interact"):
		_kindle()

func _kindle() -> void:
	kindled = true
	player.set("spawn_point", global_position + Vector3(0, 0.5, 2.0))
	player.set("hp", player.get("HP_MAX"))
	player.set("stamina", player.get("STAMINA_MAX"))
	player.set("heal_charges", player.get("HEAL_CHARGES_MAX"))
	_respawn_enemies()
	_show_kindle_text()
	_set_kindled_visual()

func _respawn_enemies() -> void:
	# Reload the scene to respawn all enemies (except boss)
	# For now: re-enable any dead non-boss enemies in the group
	# (Full respawn system requires scene reset — this is a placeholder)
	pass

func _show_kindle_text() -> void:
	var zone_title := get_tree().get_first_node_in_group("zone_title_group")
	# Use a temp label since ZoneTitle is scene-specific
	var label := Label.new()
	label.text = "INFERENCE POINT KINDLED"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_override_font_sizes/font_size = 22
	label.theme_override_colors/font_color = Color(0.6, 0.9, 1.0, 1)
	var canvas := CanvasLayer.new()
	canvas.layer = 12
	get_tree().current_scene.add_child(canvas)
	canvas.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.offset_top = 80.0
	label.offset_bottom = 110.0
	# Fade in then out
	_animate_label(label, canvas)

func _animate_label(label: Label, canvas: CanvasLayer) -> void:
	label.modulate.a = 0.0
	var t := 0.0
	while t < 1.0:
		t = minf(t + get_process_delta_time() * 2.5, 1.0)
		label.modulate.a = t
		await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	t = 1.0
	while t > 0.0:
		t = maxf(t - get_process_delta_time() * 1.5, 0.0)
		label.modulate.a = t
		await get_tree().process_frame
	canvas.queue_free()

func _set_kindled_visual() -> void:
	# Brighten the glow
	var mat := glow_mesh.get_active_material(0) as StandardMaterial3D
	if mat:
		var tween := create_tween()
		tween.tween_property(mat, "emission_energy_multiplier", 8.0, 0.5)
	if particles:
		particles.emitting = true
