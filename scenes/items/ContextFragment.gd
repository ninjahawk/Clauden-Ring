extends Area3D

const ITEM_NAME := "Context Window Fragment"
const ITEM_DESC := "A shard of forgotten context.\nOnce, this held an entire conversation.\nNow it holds only the echo of a question."
const BOB_SPEED := 1.8
const BOB_HEIGHT := 0.18
const SPIN_SPEED := 1.2

var start_y: float = 0.0
var time: float = 0.0
var collected: bool = false

func _ready() -> void:
	start_y = global_position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if collected:
		return
	time += delta
	global_position.y = start_y + sin(time * BOB_SPEED) * BOB_HEIGHT
	rotation.y += SPIN_SPEED * delta

func _on_body_entered(body: Node) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	# Show item popup via UI
	var popup := get_tree().get_first_node_in_group("item_popup")
	if popup:
		popup.show_item(ITEM_NAME, ITEM_DESC)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)
