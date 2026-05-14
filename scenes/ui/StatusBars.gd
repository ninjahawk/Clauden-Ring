extends CanvasLayer

const HP_COLOR := Color(0.75, 0.1, 0.1)
const HP_BG_COLOR := Color(0.2, 0.05, 0.05)
const STAMINA_COLOR := Color(0.7, 0.6, 0.1)
const STAMINA_BG_COLOR := Color(0.18, 0.15, 0.03)
const STAMINA_DRAIN_COLOR := Color(0.5, 0.4, 0.05, 0.6)

@onready var hp_bar: ProgressBar = $Bars/HPBar
@onready var stamina_bar: ProgressBar = $Bars/StaminaBar
@onready var stamina_drain: ProgressBar = $Bars/StaminaDrain

var player: Node = null
var displayed_stamina: float = 100.0
var drain_stamina: float = 100.0
var drain_delay: float = 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	_style_bar(hp_bar, HP_COLOR, HP_BG_COLOR)
	_style_bar(stamina_bar, STAMINA_COLOR, STAMINA_BG_COLOR)
	_style_bar(stamina_drain, STAMINA_DRAIN_COLOR, Color.TRANSPARENT)

func _process(delta: float) -> void:
	if not player:
		return
	var hp_pct: float = float(player.get("hp")) / float(player.get("HP_MAX")) * 100.0
	hp_bar.value = hp_pct
	var target_stamina: float = float(player.get("stamina")) / float(player.get("STAMINA_MAX")) * 100.0
	if target_stamina < displayed_stamina:
		displayed_stamina = target_stamina
		drain_delay = 0.4
	elif target_stamina > displayed_stamina:
		displayed_stamina = minf(displayed_stamina + 80.0 * delta, target_stamina)
	stamina_bar.value = displayed_stamina
	if drain_delay > 0.0:
		drain_delay -= delta
	else:
		drain_stamina = maxf(drain_stamina - 60.0 * delta, displayed_stamina)
	stamina_drain.value = drain_stamina
	if displayed_stamina > drain_stamina:
		drain_stamina = displayed_stamina

func _style_bar(bar: ProgressBar, fill: Color, bg: Color) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = bg
	bar.add_theme_stylebox_override("fill", fill_style)
	bar.add_theme_stylebox_override("background", bg_style)
	bar.show_percentage = false
