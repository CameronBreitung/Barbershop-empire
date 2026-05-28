## HomeShop.gd
## The main gameplay loop. Player cuts hair via a drag-based minigame,
## earns money and reputation, and navigates to other menus.
extends Control

# ── Node refs ────────────────────────────────────────────────────────────────
@onready var money_label:      Label      = $HUD/HBoxContainer/MoneyLabel
@onready var rep_label:        Label      = $HUD/HBoxContainer/RepLabel
@onready var income_label:     Label      = $HUD/HBoxContainer/IncomeLabel
@onready var dialogue_label:   Label      = $DialogueLabel
@onready var customer_rect:    ColorRect  = $CustomerArea/CustomerHead
@onready var score_bar:        ProgressBar = $ScoreBar
@onready var patience_bar:     ProgressBar = $PatienceBar
@onready var result_panel:     Panel      = $ResultPanel
@onready var result_label:     Label      = $ResultPanel/ResultLabel
@onready var review_label:     Label      = $ResultPanel/ReviewLabel
@onready var stars_label:      Label      = $ResultPanel/StarsLabel
@onready var next_customer_btn: Button    = $ResultPanel/NextBtn
@onready var btn_upgrade:      Button     = $HUD/HBoxContainer/BtnUpgrade
@onready var btn_staff:        Button     = $HUD/HBoxContainer/BtnStaff
@onready var btn_shop:         Button     = $HUD/HBoxContainer/BtnShop
@onready var btn_empire:       Button     = $HUD/HBoxContainer/BtnEmpire
@onready var btn_save:         Button     = $HUD/HBoxContainer/BtnSave
@onready var btn_menu:         Button     = $HUD/HBoxContainer/BtnMenu
@onready var clip_zone:        Control    = $CustomerArea/ClipZone
@onready var progress_fill:    ColorRect  = $CustomerArea/ClipZone/Fill
@onready var notification_label: Label   = $NotificationLabel

# ── Minigame state ────────────────────────────────────────────────────────────
var _is_cutting:    bool  = false
var _cut_progress:  float = 0.0   # 0.0 – 1.0
var _accuracy:      float = 1.0   # starts perfect, degrades on fast/sloppy moves
var _patience_left: float = 0.0
var _customer_waiting: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _total_drag_dist: float = 0.0
var _good_drag_dist:  float = 0.0   # within clipzone

const CUT_SPEED_BASE := 0.012    # fraction of bar filled per pixel dragged
const ACCURACY_DECAY := 0.001    # penalty per pixel outside zone

# ── Scenes ────────────────────────────────────────────────────────────────────
const UPGRADE_SCENE     := "res://scenes/UpgradeMenu.tscn"
const STAFF_SCENE       := "res://scenes/StaffMenu.tscn"
const SHOP_SCENE        := "res://scenes/ShopMenu.tscn"
const EMPIRE_SCENE      := "res://scenes/EmpireMap.tscn"
const START_SCENE       := "res://scenes/StartScreen.tscn"

func _ready() -> void:
	# Connect HUD signals
	btn_upgrade.pressed.connect(_open_scene.bind(UPGRADE_SCENE))
	btn_staff.pressed.connect(_open_scene.bind(STAFF_SCENE))
	btn_shop.pressed.connect(_open_scene.bind(SHOP_SCENE))
	btn_empire.pressed.connect(_open_scene.bind(EMPIRE_SCENE))
	btn_save.pressed.connect(_on_save_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	next_customer_btn.pressed.connect(_spawn_customer)

	# Connect GameManager signals
	GameManager.money_changed.connect(_update_hud)
	GameManager.reputation_changed.connect(_update_hud)
	GameManager.unlock_triggered.connect(_on_unlock)

	result_panel.visible  = false
	notification_label.visible = false

	_update_hud(GameManager.money)
	_update_nav_buttons()
	_spawn_customer()

func _process(delta: float) -> void:
	_update_hud_passive()
	if not _customer_waiting:
		return

	# Count down patience
	_patience_left -= delta
	patience_bar.value = (_patience_left / Economy.get_customer_patience()) * 100.0
	if _patience_left <= 0.0:
		_walkout()

func _input(event: InputEvent) -> void:
	if not _customer_waiting or result_panel.visible:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_is_cutting = mb.pressed
			if mb.pressed:
				_last_mouse_pos = mb.global_position
	elif event is InputEventMouseMotion and _is_cutting:
		_process_drag(event as InputEventMouseMotion)

# ── Minigame logic ────────────────────────────────────────────────────────────

func _process_drag(event: InputEventMouseMotion) -> void:
	var dist: float = event.relative.length()
	_total_drag_dist += dist

	var in_zone: bool = clip_zone.get_global_rect().has_point(event.global_position)
	if in_zone:
		_good_drag_dist += dist
		var speed_mult := Economy.get_cut_speed_multiplier()
		_cut_progress = minf(_cut_progress + dist * CUT_SPEED_BASE * speed_mult, 1.0)
	else:
		# Dragging outside zone hurts accuracy
		_accuracy = maxf(_accuracy - dist * ACCURACY_DECAY, 0.0)

	# Update visual fill
	progress_fill.size.x = clip_zone.size.x * _cut_progress
	score_bar.value = _cut_progress * 100.0

	# Auto-complete when bar is full
	if _cut_progress >= 1.0:
		_finish_cut()

func _finish_cut() -> void:
	_customer_waiting = false
	_is_cutting       = false

	# Score: blend progress (always 1.0 here) with accuracy
	var final_score := (_cut_progress * 0.6 + _accuracy * 0.4)
	final_score = clampf(final_score, 0.0, 1.0)

	var payout := Economy.calculate_haircut_payout(final_score)
	var rep    := Economy.calculate_rep_gain(final_score)
	GameManager.add_money(payout)
	GameManager.add_reputation(rep)
	GameManager.total_haircuts_done += 1
	GameManager.total_customers_served += 1

	# Show result panel
	var stars  := DialogueGenerator.get_star_rating(final_score)
	var review := DialogueGenerator.get_review(final_score)
	result_label.text  = "$%.2f earned  |  +%d rep" % [payout, rep]
	review_label.text  = "\"%s\"" % review
	stars_label.text   = "★".repeat(stars) + "☆".repeat(5 - stars)
	result_panel.visible = true

func _walkout() -> void:
	_customer_waiting = false
	dialogue_label.text = "Customer left! They got tired of waiting."
	GameManager.add_reputation(-1)
	result_panel.visible = true
	result_label.text  = "$0.00  |  -1 rep"
	review_label.text  = "\"I can't wait forever. I left.\""
	stars_label.text   = "☆☆☆☆☆"

func _spawn_customer() -> void:
	result_panel.visible = false
	_cut_progress   = 0.0
	_accuracy       = 1.0
	_total_drag_dist = 0.0
	_good_drag_dist  = 0.0
	_patience_left  = Economy.get_customer_patience()
	_customer_waiting = true
	progress_fill.size.x = 0.0
	score_bar.value      = 0.0
	patience_bar.value   = 100.0

	# Random head colour (placeholder art)
	customer_rect.color = Color(randf_range(0.6, 0.9),
	                            randf_range(0.4, 0.7),
	                            randf_range(0.3, 0.6), 1.0)
	dialogue_label.text = DialogueGenerator.get_customer_greeting()

# ── HUD updates ───────────────────────────────────────────────────────────────

func _update_hud(_val = null) -> void:
	money_label.text  = "$%.2f" % GameManager.money
	rep_label.text    = "Rep: %d" % GameManager.reputation

func _update_hud_passive() -> void:
	var ips := GameManager.get_income_per_second()
	income_label.text = "+$%.2f/s" % ips if ips > 0.0 else ""

func _update_nav_buttons() -> void:
	btn_staff.disabled  = not GameManager.game_unlocks.get("staff_menu", false)
	btn_shop.disabled   = not GameManager.game_unlocks.get("shop_menu", false)
	btn_empire.disabled = not GameManager.game_unlocks.get("empire_map", false)

# ── Notifications ─────────────────────────────────────────────────────────────

func _on_unlock(unlock_name: String) -> void:
	_update_nav_buttons()
	var msgs := {
		"staff_menu":         "UNLOCKED: You can now hire staff!",
		"shop_menu":          "UNLOCKED: First shop is available!",
		"empire_map":         "UNLOCKED: Empire Map is open!",
		"national_expansion": "UNLOCKED: National chains for sale!",
		"final_tower":        "You OWN IT ALL. Head to the Empire Map!",
	}
	if unlock_name in msgs:
		_show_notification(msgs[unlock_name])

func _show_notification(msg: String) -> void:
	notification_label.text = msg
	notification_label.visible = true
	notification_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(notification_label, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func(): notification_label.visible = false)

# ── Navigation ────────────────────────────────────────────────────────────────

func _open_scene(path: String) -> void:
	GameManager.save_game()
	get_tree().change_scene_to_file(path)

func _on_save_pressed() -> void:
	GameManager.save_game()
	_show_notification("Game saved!")

func _on_menu_pressed() -> void:
	GameManager.save_game()
	get_tree().change_scene_to_file(START_SCENE)
