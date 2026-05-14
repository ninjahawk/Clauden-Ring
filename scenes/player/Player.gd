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

var stamina: float = STAMINA_MAX
var hp: float = HP_MAX
var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_dir: Vector3 = Vector3.ZERO
var is_invincible: bool = false
var is_dead: bool = false
var spawn_point: Vector3 = Vector3.ZERO
var attack_timer: float = 0.0

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
		cam_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		spring_arm.rotation.x = clampf(spring_arm.rotation.x, -PI / 3.0, PI / 4.0)
	if event.is_action_pressed("dodge") and not is_dodging and is_on_floor() and stamina >= DODGE_COST:
		_start_dodge()
	if event.is_action_pressed("attack_light") and attack_timer <= 0.0 and not is_dodging:
		_attack_light()
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)

	_regen_stamina(delta)
	attack_timer = maxf(attack_timer - delta, 0.0)

	if is_dodging:
		_tick_dodge(delta)
	else:
		_handle_movement(delta)

	move_and_slide()

func _regen_stamina(delta: float) -> void:
	if not is_dodging:
		stamina = minf(stamina + STAMINA_REGEN * delta, STAMINA_MAX)

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
	var attack_origin: Vector3 = global_position + Vector3(0, 1.0, 0)
	var attack_fwd: Vector3 = -model.global_transform.basis.z
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

func take_damage(amount: float) -> void:
	if is_invincible or is_dead:
		return
	hp = maxf(hp - amount, 0.0)
	if hp <= 0.0:
		_die()

func _die() -> void:
	is_dead = true
	is_dodging = false
	is_invincible = false
	velocity = Vector3.ZERO
	died.emit()

func respawn() -> void:
	global_position = spawn_point
	velocity = Vector3.ZERO
	hp = HP_MAX
	stamina = STAMINA_MAX
	is_dead = false
	is_dodging = false
	is_invincible = false
