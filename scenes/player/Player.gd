extends CharacterBody3D

signal died

const SPEED := 5.0
const DODGE_SPEED := 14.0
const MOUSE_SENSITIVITY := 0.002
const GRAVITY := 20.0
const DODGE_DURATION := 0.45
const STAMINA_MAX := 100.0
const STAMINA_REGEN := 22.0
const DODGE_COST := 25.0
const HP_MAX := 100.0
const ATTACK_RANGE := 2.2
const ATTACK_DAMAGE := 20.0
const ATTACK_COOLDOWN := 0.6
const HEAVY_RANGE := 3.0
const HEAVY_DAMAGE := 35.0
const HEAVY_COOLDOWN := 1.0
const HEAVY_STAMINA_COST := 20.0
const LOCK_RANGE := 15.0
const LOCK_CAM_SPEED := 6.0
const HEAL_AMOUNT := 40.0
const HEAL_CHARGES_MAX := 3
const BLOCK_REDUCTION := 0.6
const BLOCK_STAMINA_COST := 8.0
const PARRY_WINDOW := 0.18
const PARRY_STAGGER_DURATION := 1.8

var stamina: float = STAMINA_MAX
var hp: float = HP_MAX
var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_dir: Vector3 = Vector3.ZERO
var is_invincible: bool = false
var is_dead: bool = false
var spawn_point: Vector3 = Vector3.ZERO
var attack_timer: float = 0.0
var lock_target: Node = null
var _prev_lock_target: Node = null
var heal_charges: int = HEAL_CHARGES_MAX
var is_blocking: bool = false
var block_raised_timer: float = 0.0  # how long block has been held

@onready var model: Node3D = $Model
@onready var cam_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D

func _ready() -> void:
	add_to_group("player")
	spawn_point = global_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if not lock_target:
			cam_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			spring_arm.rotation.x = clampf(spring_arm.rotation.x, -PI / 3.0, PI / 4.0)
	if event.is_action_pressed("dodge") and not is_dodging and is_on_floor() and stamina >= DODGE_COST:
		SoundManager.play_dodge()
		_start_dodge()
	if event.is_action_pressed("attack_light") and attack_timer <= 0.0 and not is_dodging:
		SoundManager.play_attack()
		_attack_light()
	if event.is_action_pressed("attack_heavy") and attack_timer <= 0.0 and not is_dodging and stamina >= HEAVY_STAMINA_COST:
		SoundManager.play_attack()
		_attack_heavy()
	if event.is_action_pressed("lock_on"):
		_toggle_lock()
	if event.is_action_pressed("use_item") and heal_charges > 0 and hp < HP_MAX and not is_dead:
		heal_charges -= 1
		hp = minf(hp + HEAL_AMOUNT, HP_MAX)
		CameraShake.add_trauma(0.1)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = maxf(velocity.y, -0.5)  # small downward keeps floor contact on ramps

	_regen_stamina(delta)
	attack_timer = maxf(attack_timer - delta, 0.0)
	_update_lock(delta)
	is_blocking = Input.is_action_pressed("block") and not is_dodging and stamina > 0.0
	if is_blocking:
		block_raised_timer += delta
		stamina = maxf(stamina - BLOCK_STAMINA_COST * delta, 0.0)
	else:
		block_raised_timer = 0.0

	if is_dodging:
		_tick_dodge(delta)
	else:
		_handle_movement(delta)

	move_and_slide()

func _regen_stamina(delta: float) -> void:
	if not is_dodging:
		stamina = minf(stamina + STAMINA_REGEN * delta, STAMINA_MAX)

func _toggle_lock() -> void:
	if lock_target:
		lock_target = null
		return
	lock_target = _find_best_lock_target()

func _find_best_lock_target() -> Node:
	var best: Node = null
	var best_score: float = -INF
	var cam_fwd := -cam_pivot.global_transform.basis.z
	cam_fwd.y = 0.0
	if cam_fwd.length_squared() > 0.0:
		cam_fwd = cam_fwd.normalized()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.get("is_dead"):
			continue
		var to_enemy: Vector3 = enemy.global_position - global_position
		to_enemy.y = 0.0
		var dist: float = to_enemy.length()
		if dist > LOCK_RANGE or dist < 0.1:
			continue
		var dir := to_enemy / dist
		var dot: float = cam_fwd.dot(dir)
		if dot < 0.0:
			continue
		var score: float = dot - dist / LOCK_RANGE
		if score > best_score:
			best_score = score
			best = enemy
	return best

func _update_lock_outline() -> void:
	if lock_target != _prev_lock_target:
		if _prev_lock_target and is_instance_valid(_prev_lock_target):
			_set_outline(_prev_lock_target, false)
		if lock_target and is_instance_valid(lock_target):
			_set_outline(lock_target, true)
		_prev_lock_target = lock_target

func _set_outline(target: Node, on: bool) -> void:
	var model: Node = target.get_node_or_null("Model")
	if not model:
		return
	for child in model.get_children():
		var mi := child as MeshInstance3D
		if not mi:
			continue
		var mat := mi.get_active_material(0) as StandardMaterial3D
		if not mat:
			continue
		var new_mat := mat.duplicate() as StandardMaterial3D
		if on:
			new_mat.rim_enabled = true
			new_mat.rim = 0.8
			new_mat.rim_tint = 0.4
		else:
			new_mat.rim_enabled = false
		mi.set_surface_override_material(0, new_mat)

func _update_lock(delta: float) -> void:
	_update_lock_outline()
	if not lock_target:
		return
	if lock_target.get("is_dead"):
		lock_target = null
		return
	var to_enemy: Vector3 = lock_target.global_position - global_position
	if to_enemy.length() > LOCK_RANGE * 1.3:
		lock_target = null
		return
	to_enemy.y = 0.0
	if to_enemy.length_squared() < 0.01:
		return
	# Camera should orbit to keep player between it and enemy
	var enemy_dir := to_enemy.normalized()
	var target_cam_y := atan2(-enemy_dir.x, -enemy_dir.z)
	cam_pivot.rotation.y = lerp_angle(cam_pivot.rotation.y, target_cam_y, LOCK_CAM_SPEED * delta)
	# Tilt down slightly to frame both
	var dist: float = to_enemy.length()
	var tilt: float = clampf(-0.25 - dist * 0.01, -0.55, -0.15)
	spring_arm.rotation.x = lerpf(spring_arm.rotation.x, tilt, 4.0 * delta)
	# Face model toward enemy
	model.rotation.y = lerp_angle(model.rotation.y, atan2(enemy_dir.x, enemy_dir.z), 10.0 * delta)

func _start_dodge() -> void:
	stamina -= DODGE_COST
	is_dodging = true
	is_invincible = true
	dodge_timer = DODGE_DURATION
	var dir := _camera_relative_input()
	dodge_dir = dir if dir != Vector3.ZERO else -cam_pivot.global_transform.basis.z
	dodge_dir.y = 0.0
	if dodge_dir != Vector3.ZERO:
		dodge_dir = dodge_dir.normalized()
	else:
		dodge_dir = Vector3(0.0, 0.0, 1.0)
	model.rotation.y = atan2(dodge_dir.x, dodge_dir.z)

func _tick_dodge(delta: float) -> void:
	velocity.x = dodge_dir.x * DODGE_SPEED
	velocity.z = dodge_dir.z * DODGE_SPEED
	dodge_timer -= delta
	if dodge_timer <= 0.0:
		is_dodging = false
		is_invincible = false

func _handle_movement(delta: float) -> void:
	var dir := _camera_relative_input()
	if dir != Vector3.ZERO:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		if not lock_target:
			var target_y := atan2(dir.x, dir.z)
			model.rotation.y = lerp_angle(model.rotation.y, target_y, 12.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

func _camera_relative_input() -> Vector3:
	var raw := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)
	if raw == Vector2.ZERO:
		return Vector3.ZERO
	var fwd := -cam_pivot.global_transform.basis.z
	var right := cam_pivot.global_transform.basis.x
	fwd.y = 0.0
	right.y = 0.0
	return (fwd * -raw.y + right * raw.x).normalized()

func _attack_light() -> void:
	attack_timer = ATTACK_COOLDOWN
	# When locked on, attack toward the lock target
	var attack_fwd: Vector3
	if lock_target:
		var to_target: Vector3 = lock_target.global_position - global_position
		to_target.y = 0.0
		attack_fwd = to_target.normalized() if to_target.length() > 0.1 else -model.global_transform.basis.z
	else:
		attack_fwd = -model.global_transform.basis.z
	var attack_origin: Vector3 = global_position + Vector3(0, 1.0, 0)
	var hit_pos: Vector3 = attack_origin + attack_fwd * (ATTACK_RANGE * 0.5)
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = ATTACK_RANGE * 0.5
	query.shape = sphere
	query.transform = Transform3D(Basis(), hit_pos)
	query.exclude = [self]
	var hits := space_state.intersect_shape(query, 8)
	for hit in hits:
		var body: Object = hit.get("collider")
		if body and body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)

func _attack_heavy() -> void:
	stamina -= HEAVY_STAMINA_COST
	attack_timer = HEAVY_COOLDOWN
	var attack_fwd: Vector3
	if lock_target:
		var to_target: Vector3 = lock_target.global_position - global_position
		to_target.y = 0.0
		attack_fwd = to_target.normalized() if to_target.length() > 0.1 else -model.global_transform.basis.z
	else:
		attack_fwd = -model.global_transform.basis.z
	var hit_pos: Vector3 = global_position + Vector3(0, 1.0, 0) + attack_fwd * (HEAVY_RANGE * 0.5)
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = HEAVY_RANGE * 0.5
	query.shape = sphere
	query.transform = Transform3D(Basis(), hit_pos)
	query.exclude = [self]
	for hit in space_state.intersect_shape(query, 8):
		var body: Object = hit.get("collider")
		if body and body.has_method("take_damage"):
			body.take_damage(HEAVY_DAMAGE)
	CameraShake.add_trauma(0.25)

func take_damage(amount: float) -> void:
	if is_invincible or is_dead:
		return
	if is_blocking:
		if block_raised_timer <= PARRY_WINDOW:
			# Perfect parry
			_do_parry()
			return
		# Regular block — reduce damage
		amount *= (1.0 - BLOCK_REDUCTION)
		CameraShake.add_trauma(0.1)
	hp = maxf(hp - amount, 0.0)
	SoundManager.play_hit_player()
	CameraShake.add_trauma(clampf(amount / HP_MAX * 1.5, 0.15, 0.8))
	if hp <= 0.0:
		_die()

func _do_parry() -> void:
	CameraShake.add_trauma(0.2)
	# Stagger nearest attacker
	var best: Node = null
	var best_dist: float = 3.5
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.get("is_dead"):
			continue
		var d: float = enemy.global_position.distance_to(global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	if best and best.has_method("_tick_stagger"):
		best.set("is_staggered", true)
		best.set("stagger_timer", PARRY_STAGGER_DURATION)
		best.set("poise", best.get("POISE_MAX"))

func _die() -> void:
	is_dead = true
	is_dodging = false
	is_invincible = false
	lock_target = null
	velocity = Vector3.ZERO
	SoundManager.play_death()
	CameraShake.add_trauma(1.0)
	died.emit()

func respawn() -> void:
	global_position = spawn_point
	velocity = Vector3.ZERO
	hp = HP_MAX
	stamina = STAMINA_MAX
	heal_charges = HEAL_CHARGES_MAX
	is_dead = false
	is_dodging = false
	is_invincible = false
	lock_target = null
