extends Node3D

const FADE_DELAY := 3.0
const AGGRO_SHOW_DIST := 14.0

@onready var fill_mesh: MeshInstance3D = $Fill

var enemy: Node = null
var fade_timer: float = 0.0
var visible_alpha: float = 0.0

func _ready() -> void:
	enemy = get_parent()
	_set_alpha(0.0)

func _process(delta: float) -> void:
	if not enemy:
		return

	var player := get_tree().get_first_node_in_group("player")
	var should_show := false
	if player:
		var dist: float = enemy.global_position.distance_to(player.global_position)
		should_show = dist <= AGGRO_SHOW_DIST and not enemy.get("is_dead")

	if should_show:
		fade_timer = FADE_DELAY
	else:
		fade_timer = maxf(fade_timer - delta, 0.0)

	var target_alpha: float = 1.0 if fade_timer > 0.0 else 0.0
	visible_alpha = move_toward(visible_alpha, target_alpha, delta * 5.0)
	_set_alpha(visible_alpha)

	var hp_pct: float = clampf(float(enemy.get("hp")) / float(enemy.get("HP_MAX")), 0.0, 1.0)
	fill_mesh.scale.x = hp_pct
	fill_mesh.position.x = (hp_pct - 1.0) * 0.5

func show_hit() -> void:
	fade_timer = FADE_DELAY
	visible_alpha = 1.0

func _set_alpha(a: float) -> void:
	for child in get_children():
		var mi := child as MeshInstance3D
		if not mi:
			continue
		var mat := mi.get_active_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color.a = a * (0.7 if mi.name == "Background" else 1.0)
