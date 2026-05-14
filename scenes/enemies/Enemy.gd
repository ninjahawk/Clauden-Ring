extends CharacterBody3D

const SPEED := 2.5
const AGGRO_RANGE := 12.0
const ATTACK_RANGE := 1.2
const ATTACK_DAMAGE := 15.0
const ATTACK_COOLDOWN := 1.2
const GRAVITY := 20.0
const HP_MAX := 40.0

var hp: float = HP_MAX
var attack_timer: float = 0.0
var player: Node = null
var is_dead: bool = false

@onready var model: Node3D = $Model

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
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

func take_damage(amount: float) -> void:
	if is_dead:
		return
	hp = maxf(hp - amount, 0.0)
	if hp <= 0.0:
		_die()

func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	# Fade out and queue_free after a moment
	var tween := create_tween()
	tween.tween_property(model, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)
