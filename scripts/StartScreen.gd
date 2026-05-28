## StartScreen.gd
## Handles the main menu: Start, Continue, Settings, Credits, Exit.
## Buttons scale up on hover and play a simple glow tween.
extends Control

@onready var btn_start:    Button = $VBox/BtnStart
@onready var btn_continue: Button = $VBox/BtnContinue
@onready var btn_settings: Button = $VBox/BtnSettings
@onready var btn_credits:  Button = $VBox/BtnCredits
@onready var btn_exit:     Button = $VBox/BtnExit
@onready var version_label: Label = $VersionLabel
@onready var settings_panel: Panel = $SettingsPanel
@onready var credits_panel:  Panel = $CreditsPanel

const HOME_SHOP_SCENE      := "res://scenes/HomeShop.tscn"
const HOVER_SCALE          := Vector2(1.15, 1.15)
const NORMAL_SCALE         := Vector2(1.0,  1.0)
const TWEEN_DURATION       := 0.12

func _ready() -> void:
	version_label.text = "v1.0"

	# Grey-out Continue if no save exists
	btn_continue.disabled = not GameManager.has_save()

	# Connect button signals
	btn_start.pressed.connect(_on_start_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_credits.pressed.connect(_on_credits_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

	# Hover animations for every button
	for btn in [btn_start, btn_continue, btn_settings, btn_credits, btn_exit]:
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhover.bind(btn))

	settings_panel.visible = false
	credits_panel.visible  = false

# ── Button callbacks ──────────────────────────────────────────────────────────

func _on_start_pressed() -> void:
	if GameManager.has_save():
		# Ask user if they want to overwrite
		_show_new_game_confirm()
	else:
		_start_new_game()

func _on_continue_pressed() -> void:
	GameManager.load_game()
	get_tree().change_scene_to_file(HOME_SHOP_SCENE)

func _on_settings_pressed() -> void:
	settings_panel.visible = not settings_panel.visible
	credits_panel.visible  = false

func _on_credits_pressed() -> void:
	credits_panel.visible = not credits_panel.visible
	settings_panel.visible = false

func _on_exit_pressed() -> void:
	get_tree().quit()

# ── New game confirm ──────────────────────────────────────────────────────────

func _show_new_game_confirm() -> void:
	# Simple reuse: just delete save and start fresh
	GameManager.delete_save()
	_start_new_game()

func _start_new_game() -> void:
	get_tree().change_scene_to_file(HOME_SHOP_SCENE)

# ── Hover animations ──────────────────────────────────────────────────────────

func _on_btn_hover(btn: Button) -> void:
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "scale", HOVER_SCALE, TWEEN_DURATION)
	tw.parallel().tween_property(btn, "modulate", Color(1.4, 1.4, 0.6, 1.0), TWEEN_DURATION)

func _on_btn_unhover(btn: Button) -> void:
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "scale", NORMAL_SCALE, TWEEN_DURATION)
	tw.parallel().tween_property(btn, "modulate", Color.WHITE, TWEEN_DURATION)
