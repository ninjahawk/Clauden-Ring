extends CharacterBody3D

const SPEED := 2.5
const AGGRO_RANGE := 12.0
const ATTACK_RANGE := 1.2
const ATTACK_DAMAGE := 15.0
const ATTACK_COOLDOWN := 1.2
const GRAVITY := 20.0
const HP_MAX := 40.0
const HIT_FLASH_DURATION := 0.12

var hp: float = HP_MAX
var attack_timer: float = 0.0
var player: Node = null
var is_dead: bool = false
var hit_flash_timer: float = 0.0

@onready var model: Node3D = $Model
@onready var hp_bar: Node3D = $EnemyHPBar
var _body_meshes: Array[MeshInstance3D] = []
var _original_materials: Array[Material] = []
var _flash_material: StandardMaterial3D = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	_body_meshes = [
		$Model/Body as MeshInstance3D,
		$Model/Head as MeshInstance3D,
	]
	for m in _body_meshes:
		_original_materials.append(m.get_active_material(0))
	_flash_material = StandardMaterial3D.new()
	_flash_material.albedo_color = Color(1, 1, 1, 1)
	_flash_material.emission_enabled = true
	_flash_material.emission = Color(1, 1, 1)
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

	attack_timer = maxf(attack_timer - delta, 0.0)

	if not player or player.get("is_dead"):
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		move_and_slide()
		return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()

	if dist <= ATTACK_RANGE:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		if attack_timer <= 0.0:
			player.take_damage(ATTACK_DAMAGE)
			attack_timer = ATTACK_COOLDOWN
	elif dist <= AGGRO_RANGE:
		var dir := to_player.normalized()
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()

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
	if hp_bar:
		hp_bar.show_hit()
	if hp <= 0.0:
		_die()

func _set_flash(on: bool) -> void:
	for i in _body_meshes.size():
		var mat: Material = _flash_material if on else _original_materials[i]
		_body_meshes[i].set_surface_override_material(0, mat)

func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	var tween := create_tween()
	tween.tween_property(model, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)
