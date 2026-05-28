## UpgradeMenu.gd
## Shows four upgrade tracks (clippers, speed, accuracy, patience).
## Each row displays current level, next cost, and a Buy button.
extends Control

@onready var money_label:   Label  = $Header/MoneyLabel
@onready var back_btn:      Button = $Header/BackBtn
@onready var rows: Dictionary = {}   # populated in _ready

const UPGRADE_KEYS := ["clipper_level", "speed_level", "accuracy_level", "patience_level"]
const UPGRADE_LABELS := {
	"clipper_level":  "Clippers",
	"speed_level":    "Speed",
	"accuracy_level": "Accuracy",
	"patience_level": "Customer Patience",
}
const MAX_LEVEL := 10
const HOME_SHOP_SCENE := "res://scenes/HomeShop.tscn"

func _ready() -> void:
	back_btn.pressed.connect(_go_back)
	GameManager.money_changed.connect(_refresh_ui)
	GameManager.upgrade_purchased.connect(_on_upgrade_purchased)

	_build_rows()
	_refresh_ui(GameManager.money)

func _build_rows() -> void:
	var container: VBoxContainer = $ScrollContainer/UpgradeList
	for key in UPGRADE_KEYS:
		var row := _make_upgrade_row(key)
		container.add_child(row)
		rows[key] = row

func _make_upgrade_row(key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Row_" + key
	row.custom_minimum_size = Vector2(0, 60)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = UPGRADE_LABELS[key]
	name_lbl.custom_minimum_size = Vector2(220, 0)
	name_lbl.add_theme_font_size_override("font_size", 18)

	var level_lbl := Label.new()
	level_lbl.name = "LevelLabel"
	level_lbl.custom_minimum_size = Vector2(100, 0)
	level_lbl.add_theme_font_size_override("font_size", 18)

	var cost_lbl := Label.new()
	cost_lbl.name = "CostLabel"
	cost_lbl.custom_minimum_size = Vector2(160, 0)
	cost_lbl.add_theme_font_size_override("font_size", 18)

	var flavour_lbl := Label.new()
	flavour_lbl.name = "FlavourLabel"
	flavour_lbl.custom_minimum_size = Vector2(300, 0)
	flavour_lbl.add_theme_font_size_override("font_size", 14)
	flavour_lbl.modulate = Color(0.8, 0.9, 0.7, 1.0)
	flavour_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var btn := Button.new()
	btn.name = "BuyBtn"
	btn.text = "UPGRADE"
	btn.custom_minimum_size = Vector2(120, 44)
	btn.pressed.connect(_on_upgrade_pressed.bind(key))

	row.add_child(name_lbl)
	row.add_child(level_lbl)
	row.add_child(cost_lbl)
	row.add_child(flavour_lbl)
	row.add_child(btn)
	return row

func _refresh_ui(_money_val = null) -> void:
	money_label.text = "Cash: $%.2f" % GameManager.money
	for key in UPGRADE_KEYS:
		var row: HBoxContainer = rows[key]
		var level: int = GameManager.get_upgrade_level(key)
		var cost: float = Economy.get_upgrade_cost(key, level)

		row.get_node("LevelLabel").text = "Lv %d/%d" % [level, MAX_LEVEL]

		var buy_btn: Button = row.get_node("BuyBtn")
		if level >= MAX_LEVEL:
			row.get_node("CostLabel").text = "MAXED"
			buy_btn.disabled = true
		else:
			row.get_node("CostLabel").text = "$%.0f" % cost
			buy_btn.disabled = not GameManager.can_afford(cost)

func _on_upgrade_pressed(key: String) -> void:
	if GameManager.upgrade(key):
		var flavour := DialogueGenerator.get_upgrade_flavour(key)
		rows[key].get_node("FlavourLabel").text = flavour

func _on_upgrade_purchased(_key: String, _level: int) -> void:
	_refresh_ui()

func _go_back() -> void:
	get_tree().change_scene_to_file(HOME_SHOP_SCENE)
