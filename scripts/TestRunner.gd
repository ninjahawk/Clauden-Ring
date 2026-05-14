extends Node

const RUN_TESTS := true
const SCREENSHOT_BASE := "user://test_"
const SPAWN_POS := Vector3(0.0, 1.0, 0.0)

var player: Node = null
var results: Array[String] = []
var pass_count := 0
var fail_count := 0

func _ready() -> void:
	if not RUN_TESTS:
		return
	await get_tree().create_timer(0.4).timeout
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("TestRunner: no player in group 'player'")
		get_tree().quit()
		return
	await _run_all()

func _run_all() -> void:
	await _test_on_floor()
	await _test_dodge_direct()
	await _test_stamina_drain()
	await _test_iframes()
	await _test_input_move()
	await _test_input_dodge()
	await _test_death_and_respawn()
	_print_results()
	get_tree().quit()

func _reset() -> void:
	player.global_position = SPAWN_POS
	player.velocity = Vector3.ZERO
	player.stamina = player.STAMINA_MAX
	player.hp = player.HP_MAX
	player.is_dodging = false
	player.is_invincible = false
	player.dodge_timer = 0.0
	# Wait long enough to land: h=0.75, g=20 → t=sqrt(2h/g)≈0.27s, +0.1s buffer
	await get_tree().create_timer(0.4).timeout

# --- Direct mechanic tests ---

func _test_on_floor() -> void:
	_assert("player lands on floor", player.is_on_floor())

func _test_dodge_direct() -> void:
	await _reset()
	player.call("_start_dodge")
	_assert("_start_dodge sets is_dodging", player.is_dodging)
	_assert("_start_dodge sets is_invincible", player.is_invincible)
	_assert("stamina cost deducted", absf(player.stamina - (player.STAMINA_MAX - player.DODGE_COST)) < 0.01)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_assert("dodge velocity >= 12", Vector2(player.velocity.x, player.velocity.z).length() >= 12.0)
	await _screenshot("dodge_active")
	await get_tree().create_timer(player.DODGE_DURATION + 0.1).timeout
	_assert("is_dodging clears after duration", not player.is_dodging)
	_assert("is_invincible clears after duration", not player.is_invincible)

func _test_stamina_drain() -> void:
	await _reset()
	player.call("_start_dodge")
	_assert("DODGE_COST deducted from full stamina", player.stamina < player.STAMINA_MAX)
	await get_tree().create_timer(player.DODGE_DURATION + 0.1).timeout

func _test_iframes() -> void:
	await _reset()
	player.call("_start_dodge")
	var hp_before: float = player.hp
	player.take_damage(20.0)
	_assert("i-frames block damage mid-dodge", player.hp == hp_before)
	await get_tree().create_timer(player.DODGE_DURATION + 0.1).timeout
	player.take_damage(20.0)
	_assert("damage lands after i-frames end", player.hp < hp_before)

func _test_input_move() -> void:
	await _reset()
	Input.action_press("move_forward")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var spd := Vector2(player.velocity.x, player.velocity.z).length()
	_assert("action_press move_forward gives XZ speed > 3", spd > 3.0)
	await _screenshot("moving_forward")
	Input.action_release("move_forward")
	await get_tree().physics_frame

func _test_input_dodge() -> void:
	await _reset()
	Input.action_press("move_forward")
	await get_tree().physics_frame
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_SPACE
	ev.pressed = true
	player._input(ev)
	_assert("KEY_SPACE event triggers dodge via _input()", player.is_dodging)
	await _screenshot("input_dodge")
	Input.action_release("move_forward")
	await get_tree().create_timer(player.DODGE_DURATION + 0.1).timeout

func _test_death_and_respawn() -> void:
	await _reset()
	_assert("player starts alive", not player.is_dead)
	player.take_damage(player.HP_MAX)
	_assert("fatal damage sets is_dead", player.is_dead)
	_assert("HP is zero on death", player.hp <= 0.0)
	# Respawn directly (skip death screen animation in tests)
	player.call("respawn")
	await get_tree().physics_frame
	_assert("hp restored after respawn", player.hp == player.HP_MAX)
	_assert("is_dead cleared after respawn", not player.is_dead)
	_assert("position near spawn point after respawn",
		player.global_position.distance_to(player.spawn_point) < 1.0)

# --- Helpers ---

func _screenshot(tag: String) -> void:
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(SCREENSHOT_BASE + tag + ".png")

func _assert(desc: String, condition: bool) -> void:
	if condition:
		results.append("  PASS: " + desc)
		pass_count += 1
	else:
		results.append("  FAIL: " + desc)
		fail_count += 1

func _print_results() -> void:
	print("\n=== TEST RESULTS ===")
	for r in results:
		print(r)
	print("====================")
	print("Passed: %d  Failed: %d" % [pass_count, fail_count])
	print("====================\n")
