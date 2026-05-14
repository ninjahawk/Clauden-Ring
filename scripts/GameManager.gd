extends Node

@onready var death_screen: Node = $"../DeathScreen"
@onready var zone_title: Node = $"../ZoneTitle"

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.died.connect(_on_player_died.bind(player))
	if zone_title:
		await get_tree().create_timer(1.0).timeout
		zone_title.show_zone("THE HALLUCINATION FLATS")

func _on_player_died(player: Node) -> void:
	death_screen.play(player.respawn)
