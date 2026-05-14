extends Area3D

const SPEED := 8.0
const LIFETIME := 4.0
const DAMAGE := 12.0

var direction: Vector3 = Vector3.ZERO
var lifetime: float = LIFETIME
var owner_group: StringName = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func init(dir: Vector3, from_group: StringName) -> void:
	direction = dir.normalized()
	owner_group = from_group

func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if owner_group != "" and body.is_in_group(owner_group):
		return
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
	SoundManager.play_projectile_impact()
	_impact()

func _impact() -> void:
	# Brief flash before freeing
	var tween := create_tween()
	tween.tween_property($Mesh, "scale", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)
	set_physics_process(false)
