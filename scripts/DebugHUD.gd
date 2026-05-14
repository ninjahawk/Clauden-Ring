extends CanvasLayer

@onready var label: Label = $Label
var player: Node = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	visible = false  # toggle with F1

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_end"):  # F1 in Godot default map? use key directly
		pass
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F1:
		visible = not visible

func _process(_delta: float) -> void:
	if not player:
		label.text = "No player found"
		return
	var spd := Vector2(player.velocity.x, player.velocity.z).length()
	label.text = (
		"HP: %.0f / %.0f\n" +
		"Stamina: %.0f / %.0f\n" +
		"Dodging: %s  i-frames: %s\n" +
		"Speed XZ: %.2f\n" +
		"On floor: %s\n" +
		"Pos: %.2f, %.2f, %.2f"
	) % [
		player.hp, player.HP_MAX,
		player.stamina, player.STAMINA_MAX,
		str(player.is_dodging), str(player.is_invincible),
		spd,
		str(player.is_on_floor()),
		player.global_position.x, player.global_position.y, player.global_position.z
	]
