extends CharacterBody3D

const display_name := "Token Spitter"
const lore := "Maintains distance. Fires probabilistic projectiles. Each shot is confident and wrong."

const SPEED := 2.0
const RETREAT_SPEED := 3.5
const PREFERRED_DIST := 9.0
const AGGRO_RANGE := 18.0
const SHOOT_RANGE := 16.0
const SHOOT_COOLDOWN := 2.2
const GRAVITY := 20.0
const HP_MAX := 25.0
const HIT_FLASH_DURATION := 0.12

var hp: float = HP_MAX
var is_dead: bool = false
var shoot_timer: float = 0.8
var hit_flash_timer: float = 0.0
var player: Node = null

@onready var model: Node3D = $Model
@onready var hp_bar: Node3D = $EnemyHPBar
@onready var projectile_scene: PackedScene = preload("res://scenes/enemies/Projectile.tscn")
@onready var shoot_origin: Node3D = $ShootOrigin

var _body_meshes: Array[MeshInstance3D] = []
var _original_materials: Array[Material] = []
var _flash_material: StandardMaterial3D = null

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	_body_meshes = [$Model/Body as MeshInstance3D, $Model/Head as MeshInstance3D]
	for m in _body_meshes:
		_original_materials.append(m.get_active_material(0))
	_flash_material = StandardMaterial3D.new()
	_flash_material.albedo_color = Color(0.5, 1.0, 1.0, 1)
	_flash_material.emission_enabled = true
	_flash_material.emission = Color(0.3, 1.0, 1.0)
	_flash_material.emission_energy_multiplier = 3.0
	_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_hit_flash(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)
	shoot_timer = maxf(shoot_timer - delta, 0.0)
	if not player or player.get("is_dead"):
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		move_and_slide()
		return
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	if dist < 0.1:
		move_and_slide()
		return
	var dir := to_player / dist
	model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 6.0 * delta)
	if dist < PREFERRED_DIST * 0.7:
		# Retreat
		velocity.x = -dir.x * RETREAT_SPEED
		velocity.z = -dir.z * RETREAT_SPEED
	elif dist > PREFERRED_DIST * 1.3 and dist <= AGGRO_RANGE:
		# Approach
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
	if dist <= SHOOT_RANGE and shoot_timer <= 0.0:
		_shoot(dir)
	move_and_slide()

func _shoot(dir: Vector3) -> void:
	shoot_timer = SHOOT_COOLDOWN
	SoundManager.play_projectile_fire()
	var proj: Node = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = shoot_origin.global_position
	var aim_dir: Vector3 = dir
	if player:
		var pvel_raw = player.get("velocity")
		var pvel: Vector3 = pvel_raw if pvel_raw is Vector3 else Vector3.ZERO
		var lead: Vector3 = (player.global_position + pvel * 0.4) - shoot_origin.global_position
		lead.y = 0.0
		if lead.length_squared() > 0.1:
			aim_dir = lead.normalized()
	proj.call("init", aim_dir, StringName("enemy"))

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
	if hp <= 0.0:
		_die()

func _set_flash(on: bool) -> void:
	for i in _body_meshes.size():
		_body_meshes[i].set_surface_override_material(0, _flash_material if on else _original_materials[i])

func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	var tween := create_tween()
	tween.tween_property(model, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)
