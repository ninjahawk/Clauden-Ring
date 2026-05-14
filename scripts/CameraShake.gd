extends Node

# Attach to any node. Call CameraShake.add_trauma(amount) from anywhere.
# Reads/writes the spring_arm on the player's camera pivot.

const DECAY := 2.8
const MAX_OFFSET := 0.06
const MAX_ROLL := 0.04

var trauma: float = 0.0
var noise_y: float = 0.0
var noise_x: float = 0.0
var _time: float = 0.0

func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)

func _process(delta: float) -> void:
	if trauma <= 0.0:
		return
	_time += delta * 8.0
	trauma = maxf(trauma - DECAY * delta, 0.0)
	var shake := trauma * trauma
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	var spring_arm: Node = player.get_node_or_null("CameraPivot/SpringArm3D")
	if not spring_arm:
		return
	var camera: Node = spring_arm.get_node_or_null("Camera3D")
	if not camera:
		return
	var ox: float = (sin(_time * 1.3) * 2.0 - 1.0) * MAX_OFFSET * shake
	var oy: float = (sin(_time * 1.7 + 1.0) * 2.0 - 1.0) * MAX_OFFSET * shake
	var roll: float = (sin(_time * 0.9 + 2.0) * 2.0 - 1.0) * MAX_ROLL * shake
	camera.set("h_offset", ox)
	camera.set("v_offset", oy)
	camera.rotation.z = roll
