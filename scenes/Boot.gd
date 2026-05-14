extends Node

const GAME_SCENE := "res://scenes/world/Main.tscn"
const MENU_SCENE := "res://scenes/ui/MainMenu.tscn"

var menu: Node = null

func _ready() -> void:
	var menu_packed: PackedScene = load(MENU_SCENE)
	menu = menu_packed.instantiate()
	add_child(menu)
	menu.start_game.connect(_on_start_game)

func _on_start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
