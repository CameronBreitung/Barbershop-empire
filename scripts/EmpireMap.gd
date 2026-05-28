## EmpireMap.gd
## Bird's-eye view of the player's town. Shows shop pins on a grid map.
## Unlocks national expansion button when criteria are met.
extends Control

@onready var money_label:   Label  = $Header/HBox/MoneyLabel
@onready var rep_label:     Label  = $Header/HBox/RepLabel
@onready var income_label:  Label  = $Header/HBox/IncomeLabel
@onready var back_btn:      Button = $Header/HBox/BackBtn
@onready var national_btn:  Button = $Header/HBox/NationalBtn
@onready var map_container: Control = $MapContainer
@onready var stats_panel:   Panel  = $StatsPanel
@onready var stats_text:    Label  = $StatsPanel/StatsText

const HOME_SHOP_SCENE     := "res://scenes/HomeShop.tscn"
const NATIONAL_SCENE      := "res://scenes/NationalExpansion.tscn"

# Map layout: approximate positions for each local shop pin
const SHOP_POSITIONS: Dictionary = {
	"home_garage":     Vector2(160, 400),
	"strip_mall_1":    Vector2(350, 300),
	"downtown_corner": Vector2(550, 250),
	"mall_kiosk":      Vector2(750, 350),
	"luxury_salon":    Vector2(950, 200),
}

var _pins: Dictionary = {}

func _ready() -> void:
	back_btn.pressed.connect(_go_back)
	national_btn.pressed.connect(_go_national)
	GameManager.money_changed.connect(_refresh_header)
	GameManager.shop_bought.connect(_on_shop_bought)

	national_btn.visible = GameManager.game_unlocks.get("national_expansion", false)

	_build_map()
	_refresh_header()
	_refresh_stats()

func _process(_delta: float) -> void:
	income_label.text = "+$%.2f/s" % GameManager.get_income_per_second()

func _build_map() -> void:
	# Clear old pins
	for pin in _pins.values():
		pin.queue_free()
	_pins.clear()

	for shop_data in Economy.LOCAL_SHOPS:
		var pin := _make_pin(shop_data)
		map_container.add_child(pin)
		_pins[shop_data["id"]] = pin

func _make_pin(data: Dictionary) -> Control:
	var container := Control.new()
	var pos: Vector2 = SHOP_POSITIONS.get(data["id"], Vector2(100, 100))
	container.position = pos
	container.custom_minimum_size = Vector2(80, 80)

	var owned := GameManager.owns_shop(data["id"])

	# Dot marker
	var dot := ColorRect.new()
	dot.size = Vector2(28, 28)
	dot.position = Vector2(-14, -14)
	dot.color = Color.GREEN if owned else Color(0.5, 0.5, 0.5, 0.7)

	# Label
	var lbl := Label.new()
	lbl.text = data["name"]
	lbl.position = Vector2(-40, 18)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color.WHITE if owned else Color(0.6, 0.6, 0.6, 1.0)

	container.add_child(dot)
	container.add_child(lbl)
	return container

func _on_shop_bought(_data: Dictionary) -> void:
	_build_map()
	_refresh_stats()
	national_btn.visible = GameManager.game_unlocks.get("national_expansion", false)

func _refresh_header(_val = null) -> void:
	money_label.text = "Cash: $%.2f" % GameManager.money
	rep_label.text   = "Rep: %d / 1000" % GameManager.reputation

func _refresh_stats() -> void:
	var owned_count := GameManager.owned_shops.size()
	var staff_count := GameManager.staff.size()
	var ips         := GameManager.get_income_per_second()
	stats_text.text = (
		"Owned Shops: %d\n" +
		"Staff: %d\n" +
		"Passive Income: $%.2f/s\n" +
		"Total Haircuts: %d\n" +
		"Total Customers: %d"
	) % [owned_count, staff_count, ips,
	     GameManager.total_haircuts_done, GameManager.total_customers_served]

func _go_national() -> void:
	get_tree().change_scene_to_file(NATIONAL_SCENE)

func _go_back() -> void:
	get_tree().change_scene_to_file(HOME_SHOP_SCENE)
