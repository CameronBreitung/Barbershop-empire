## ShopMenu.gd
## Displays local shops available to buy and already-owned shops.
extends Control

@onready var money_label:   Label         = $Header/MoneyLabel
@onready var rep_label:     Label         = $Header/RepLabel
@onready var back_btn:      Button        = $Header/BackBtn
@onready var shop_list:     VBoxContainer = $ScrollContainer/ShopList
@onready var info_panel:    Panel         = $InfoPanel
@onready var info_name:     Label         = $InfoPanel/VBox/NameLabel
@onready var info_desc:     Label         = $InfoPanel/VBox/DescLabel
@onready var info_income:   Label         = $InfoPanel/VBox/IncomeLabel
@onready var info_req:      Label         = $InfoPanel/VBox/ReqLabel
@onready var buy_btn:       Button        = $InfoPanel/VBox/BuyBtn
@onready var status_label:  Label         = $StatusLabel

var _selected_shop: Dictionary = {}
const HOME_SHOP_SCENE := "res://scenes/HomeShop.tscn"

func _ready() -> void:
	back_btn.pressed.connect(_go_back)
	buy_btn.pressed.connect(_on_buy_pressed)
	GameManager.money_changed.connect(_refresh_header)
	GameManager.shop_bought.connect(_on_shop_bought)

	info_panel.visible = false
	status_label.visible = false

	_build_shop_list()
	_refresh_header()

func _build_shop_list() -> void:
	for child in shop_list.get_children():
		child.queue_free()

	for shop_data in Economy.LOCAL_SHOPS:
		var row := _make_shop_row(shop_data)
		shop_list.add_child(row)

func _make_shop_row(data: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 64)

	var owned := GameManager.owns_shop(data["id"])

	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(10, 0)
	color_rect.color = Color.GREEN if owned else Color.GRAY

	var name_lbl := Label.new()
	name_lbl.text = ("✔  " if owned else "   ") + data["name"]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 17)

	var cost_lbl := Label.new()
	cost_lbl.text = "Owned" if owned else "$%.0f" % data["cost"]
	cost_lbl.custom_minimum_size = Vector2(110, 0)

	var select_btn := Button.new()
	select_btn.text = "Details"
	select_btn.pressed.connect(_select_shop.bind(data))
	if owned:
		select_btn.disabled = true
		select_btn.text = "Owned"

	row.add_child(color_rect)
	row.add_child(name_lbl)
	row.add_child(cost_lbl)
	row.add_child(select_btn)
	return row

func _select_shop(data: Dictionary) -> void:
	_selected_shop = data
	info_panel.visible = true

	info_name.text   = data["name"]
	info_desc.text   = data.get("description", "")
	info_income.text = "Income: $%.2f/sec" % data.get("income_per_sec", 0.0)
	info_req.text    = "Requires: $%.0f  |  Rep %d" % [data["cost"], data.get("rep_req", 0)]

	var can_buy: bool = (GameManager.money >= data["cost"]
	                    and GameManager.reputation >= data.get("rep_req", 0)
	                    and not GameManager.owns_shop(data["id"]))
	buy_btn.disabled = not can_buy
	if GameManager.owns_shop(data["id"]):
		buy_btn.text = "Already Owned"
	elif not GameManager.can_afford(data["cost"]):
		buy_btn.text = "Can't Afford"
	elif GameManager.reputation < data.get("rep_req", 0):
		buy_btn.text = "Rep Too Low"
	else:
		buy_btn.text = "BUY  ($%.0f)" % data["cost"]

func _on_buy_pressed() -> void:
	if _selected_shop.is_empty():
		return
	if GameManager.buy_shop(_selected_shop):
		_show_status("You bought %s!" % _selected_shop["name"])
		_build_shop_list()
		info_panel.visible = false
	else:
		_show_status("Can't afford this shop right now.")

func _on_shop_bought(_data: Dictionary) -> void:
	_build_shop_list()
	_refresh_header()

func _refresh_header(_val = null) -> void:
	money_label.text = "Cash: $%.2f" % GameManager.money
	rep_label.text   = "Rep: %d" % GameManager.reputation

func _show_status(msg: String) -> void:
	status_label.text    = msg
	status_label.visible = true
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(func(): status_label.visible = false)

func _go_back() -> void:
	get_tree().change_scene_to_file(HOME_SHOP_SCENE)
