## FinalTowerScene.gd
## Victory screen. Player views their empire stats, credits roll, then they
## can return to the main menu or keep playing.
extends Control

@onready var title_label:   Label  = $CenterContainer/VBox/TitleLabel
@onready var stats_label:   Label  = $CenterContainer/VBox/StatsLabel
@onready var quote_label:   Label  = $CenterContainer/VBox/QuoteLabel
@onready var credits_label: Label  = $CenterContainer/VBox/CreditsLabel
@onready var menu_btn:      Button = $CenterContainer/VBox/MenuBtn
@onready var keep_btn:      Button = $CenterContainer/VBox/KeepPlayingBtn
@onready var bg_rect:       ColorRect = $Background
@onready var city_rect:     ColorRect = $CityRect
@onready var desk_rect:     ColorRect = $DeskRect

const START_SCENE   := "res://scenes/StartScreen.tscn"
const HOME_SHOP_SCENE := "res://scenes/HomeShop.tscn"

const CREDITS_TEXT := """
[center][b]BARBER EMPIRE[/b][/center]

[center]A game about scissors, strategy, and supremacy.[/center]

─────────────────────────
Developed with Godot 4
─────────────────────────

[center]Design & Code[/center]
[center]You[/center]

[center]Art Placeholders[/center]
[center]Colored rectangles (upgrade when ready)[/center]

[center]Special Thanks[/center]
[center]Every customer who sat in your chair[/center]
[center]at the beginning[/center]

─────────────────────────
[center]"From a kitchen chair to a glass tower."[/center]
─────────────────────────
"""

func _ready() -> void:
	menu_btn.pressed.connect(_on_menu_pressed)
	keep_btn.pressed.connect(_on_keep_playing_pressed)

	_setup_placeholder_art()
	_populate_stats()
	_animate_entrance()

func _setup_placeholder_art() -> void:
	# Sky gradient (placeholder for skyscraper background)
	bg_rect.color        = Color(0.05, 0.08, 0.18, 1.0)
	# City silhouette strip
	city_rect.color      = Color(0.08, 0.08, 0.15, 1.0)
	# Desk / luxury office floor
	desk_rect.color      = Color(0.25, 0.18, 0.10, 1.0)

func _populate_stats() -> void:
	var total_income := Economy.calculate_total_income(GameManager.owned_shops, GameManager.staff)
	var chains := GameManager.get_national_chains_owned()

	title_label.text = "YOU OWN IT ALL."

	stats_label.text = (
		"Empire Summary\n\n" +
		"Total Money:         $%s\n" +
		"Reputation:          %d / 1000\n" +
		"Shops Owned:         %d\n" +
		"National Chains:     %d / 5\n" +
		"Staff Employed:      %d\n" +
		"Passive Income:      $%.2f / sec\n" +
		"Haircuts Performed:  %d\n" +
		"Customers Served:    %d"
	) % [
		_fmt_large(GameManager.money),
		GameManager.reputation,
		GameManager.owned_shops.size(),
		chains,
		GameManager.staff.size(),
		total_income,
		GameManager.total_haircuts_done,
		GameManager.total_customers_served
	]

	quote_label.text = "\"From a pair of clippers at home\nto every barbershop in America.\nNot bad for a barber.\""

	credits_label.text = CREDITS_TEXT

func _animate_entrance() -> void:
	# Fade in from black
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 2.0)

	# Slowly pan the city rect upward (parallax effect)
	var city_tw := create_tween().set_loops()
	city_tw.tween_property(city_rect, "position:y", -20.0, 8.0)
	city_tw.tween_property(city_rect, "position:y", 0.0, 8.0)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(START_SCENE)

func _on_keep_playing_pressed() -> void:
	get_tree().change_scene_to_file(HOME_SHOP_SCENE)

func _fmt_large(n: float) -> String:
	if n >= 1_000_000_000.0:
		return "%.2fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000.0:
		return "%.2fM" % (n / 1_000_000.0)
	if n >= 1_000.0:
		return "%.1fK" % (n / 1_000.0)
	return "%.0f" % n
