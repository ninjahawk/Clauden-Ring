extends CanvasLayer

@onready var container: Control = $Container
@onready var name_label: Label = $Container/BossName
@onready var hp_fill: ColorRect = $Container/BarBG/Fill
@onready var hp_drain: ColorRect = $Container/BarBG/Drain

var boss: Node = null
var alpha: float = 0.0
var drain_pct: float = 1.0
var drain_timer: float = 0.0
var displayed_pct: float = 1.0

func _ready() -> void:
	add_to_group("boss_bar")
	container.modulate.a = 0.0

func register_boss(b: Node) -> void:
	boss = b
	name_label.text = str(b.get("display_name")) if b.get("display_name") else "BOSS"

func _process(delta: float) -> void:
	if not boss:
		alpha = move_toward(alpha, 0.0, delta * 2.0)
		container.modulate.a = alpha
		return
	if boss.get("is_dead"):
		alpha = move_toward(alpha, 0.0, delta * 1.5)
		container.modulate.a = alpha
		if alpha <= 0.0:
			boss = null
		return
	alpha = move_toward(alpha, 1.0, delta * 3.0)
	container.modulate.a = alpha
	var hp_pct: float = clampf(float(boss.get("hp")) / float(boss.get("HP_MAX")), 0.0, 1.0)
	if hp_pct < displayed_pct:
		displayed_pct = hp_pct
		drain_timer = 0.5
	hp_fill.size.x = _bar_width() * displayed_pct
	if drain_timer > 0.0:
		drain_timer -= delta
	else:
		drain_pct = move_toward(drain_pct, displayed_pct, delta * 0.4)
	hp_drain.size.x = _bar_width() * drain_pct

func _bar_width() -> float:
	return $Container/BarBG.size.x
