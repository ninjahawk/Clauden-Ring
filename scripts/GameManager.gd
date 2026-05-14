extends Node

@onready var death_screen: Node = $"../DeathScreen"

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.died.connect(_on_player_died.bind(player))

func _on_player_died(player: Node) -> void:
	death_screen.play(player.respawn)
