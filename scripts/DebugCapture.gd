extends Node

const ENABLED := false
const QUIT_AFTER := false
const SCREENSHOT_PATH := "user://debug_screenshot.png"

func _ready() -> void:
	if not ENABLED:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(SCREENSHOT_PATH)
	print("Screenshot saved to: ", ProjectSettings.globalize_path(SCREENSHOT_PATH))
	if QUIT_AFTER:
		get_tree().quit()








