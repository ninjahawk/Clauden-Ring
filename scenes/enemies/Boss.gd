extends CharacterBody3D

const display_name := "GPT-5 Golem"
const lore := "Trained on everything. Remembers nothing. Each context window opens with the same false confidence. Extremely dangerous in phase 2."

const SPEED_P1 := 3.0
const SPEED_P2 := 4.5
const SLAM_RANGE := 2.8
const SLAM_DAMAGE := 30.0
const SLAM_COOLDOWN := 2.0
const VOLLEY_RANGE := 14.0
const VOLLEY_COOLDOWN := 5.0
const VOLLEY_COUNT := 5
const GRAVITY := 20.0
const HP_MAX := 300.0
const HIT_FLASH_DURATION := 0.1
const PHASE2_THRESHOLD := 0.5

var hp: float = HP_MAX
var is_dead: bool = false
var phase2: bool = false
var slam_timer: float = 1.5
var volley_timer: float = 3.0
var hit_flash_timer: float = 0.0
var player: Node = null
var boss_bar: Node = null

@onready var model: Node3D = $Model
@onready var hp_bar: Node3D = $EnemyHPBar
@onready var shoot_origin: Node3D = $ShootOrigin
@onready var projectile_scene: PackedScene = preload("res://scenes/enemies/Projectile.tscn")

var _body_meshes: Array[MeshInstance3D] = []
var _original_materials: Array[Material] = []
var _flash_material: StandardMaterial3D = null

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	player = get_tree().get_first_node_in_group("player")
	_body_meshes = [$Model/Body as MeshInstance3D, $Model/Head as MeshInstance3D]
	for m in _body_meshes:
		_original_materials.append(m.get_active_material(0))
	_flash_material = StandardMaterial3D.new()
	_flash_material.albedo_color = Color(1, 1, 1, 1)
	_flash_material.emission_enabled = true
	_flash_material.emission = Color(1, 0.8, 0.3)
	_flash_material.emission_energy_multiplier = 5.0
	_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Register with boss bar
	await get_tree().process_frame
	boss_bar = get_tree().get_first_node_in_group("boss_bar")
	if boss_bar:
		boss_bar.register_boss(self)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_hit_flash(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)
	slam_timer = maxf(slam_timer - delta, 0.0)
	volley_timer = maxf(volley_timer - delta, 0.0)
	if not player or player.get("is_dead"):
		velocity.x = move_toward(velocity.x, 0.0, SPEED_P1)
		velocity.z = move_toward(velocity.z, 0.0, SPEED_P1)
		move_and_slide()
		return
	var speed: float = SPEED_P2 if phase2 else SPEED_P1
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	if dist < 0.1:
		move_and_slide()
		return
	var dir := to_player / dist
	model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 4.0 * delta)
	if dist <= SLAM_RANGE:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
		if slam_timer <= 0.0:
			_slam()
	else:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	if phase2 and dist <= VOLLEY_RANGE and volley_timer <= 0.0:
		_volley(dir)
	move_and_slide()

func _slam() -> void:
	slam_timer = SLAM_COOLDOWN
	player.take_damage(SLAM_DAMAGE)
	SoundManager.play_hit_player()
	CameraShake.add_trauma(0.6)

func _volley(dir: Vector3) -> void:
	volley_timer = VOLLEY_COOLDOWN
	SoundManager.play_projectile_fire()
	for i in VOLLEY_COUNT:
		var spread_angle: float = (i - VOLLEY_COUNT / 2.0) * 0.18
		var spread_dir := dir.rotated(Vector3.UP, spread_angle)
		var proj: Node = projectile_scene.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = shoot_origin.global_position
		proj.call("init", spread_dir, StringName("enemy"))

func _tick_hit_flash(delta: float) -> void:
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0.0:
			_set_flash(false)

func take_damage(amount: float) -> void:
	if is_dead:
		return
	hp = maxf(hp - amount, 0.0)
	hit_flash_timer = HIT_FLASH_DURATION
	_set_flash(true)
	SoundManager.play_hit_enemy()
	if hp_bar:
		hp_bar.show_hit()
	if not phase2 and hp / HP_MAX <= PHASE2_THRESHOLD:
		_enter_phase2()
	if hp <= 0.0:
		_die()

func _enter_phase2() -> void:
	phase2 = true
	CameraShake.add_trauma(0.8)
	# Visual: tint model orange/red for phase 2
	var p2_mat := StandardMaterial3D.new()
	p2_mat.albedo_color = Color(0.7, 0.25, 0.1, 1)
	p2_mat.emission_enabled = true
	p2_mat.emission = Color(0.5, 0.1, 0.0)
	p2_mat.emission_energy_multiplier = 1.5
	for m in _body_meshes:
		m.set_surface_override_material(0, p2_mat)
		_original_materials[_body_meshes.find(m)] = p2_mat

func _set_flash(on: bool) -> void:
	for i in _body_meshes.size():
		_body_meshes[i].set_surface_override_material(0, _flash_material if on else _original_materials[i])

func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	CameraShake.add_trauma(1.0)
	SoundManager.play_death()
	var tween := create_tween()
	tween.tween_property(model, "scale", Vector3.ZERO, 0.8).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_callback(_on_death_complete)

func _on_death_complete() -> void:
	# Spawn item
	var item_scene: PackedScene = load("res://scenes/items/ContextFragment.tscn")
	if item_scene:
		var item: Node = item_scene.instantiate()
		get_tree().current_scene.add_child(item)
		item.global_position = global_position + Vector3(0, 0.5, 0)
	queue_free()
