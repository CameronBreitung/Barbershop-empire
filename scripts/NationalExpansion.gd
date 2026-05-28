## NationalExpansion.gd
## Displays the five national barber chains the player can acquire.
## Buying all five triggers the final tower scene.
extends Control

@onready var money_label:   Label         = $Header/MoneyLabel
@onready var rep_label:     Label         = $Header/RepLabel
@onready var back_btn:      Button        = $Header/BackBtn
@onready var chain_list:    VBoxContainer = $ScrollContainer/ChainList
@onready var info_panel:    Panel         = $InfoPanel
@onready var info_name:     Label         = $InfoPanel/VBox/NameLabel
@onready var info_desc:     Label         = $InfoPanel/VBox/DescLabel
@onready var info_stats:    Label         = $InfoPanel/VBox/StatsLabel
@onready var buy_btn:       Button        = $InfoPanel/VBox/BuyBtn
@onready var status_label:  Label         = $StatusLabel
@onready var empire_bar:    ProgressBar   = $Header/EmpireBar

const HOME_SHOP_SCENE   := "res://scenes/HomeShop.tscn"
const FINAL_SCENE       := "res://scenes/FinalTowerScene.tscn"

var _selected_chain: Dictionary = {}

func _ready() -> void:
	back_btn.pressed.connect(_go_back)
	buy_btn.pressed.connect(_on_buy_pressed)
	GameManager.money_changed.connect(_refresh_header)
	GameManager.shop_bought.connect(_on_chain_bought)
	GameManager.unlock_triggered.connect(_on_unlock)

	info_panel.visible   = false
	status_label.visible = false

	_build_chain_list()
	_refresh_header()
	_refresh_empire_bar()

func _build_chain_list() -> void:
	for child in chain_list.get_children():
		child.queue_free()

	for chain_data in Economy.NATIONAL_CHAINS:
		var row := _make_chain_row(chain_data)
		chain_list.add_child(row)

func _make_chain_row(data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 90)

	var hbox := HBoxContainer.new()
	panel.add_child(hbox)

	var owned := GameManager.owns_shop(data["id"])

	var status_dot := ColorRect.new()
	status_dot.custom_minimum_size = Vector2(12, 0)
	status_dot.color = Color.GREEN if owned else Color.DARK_RED

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = ("★  " if owned else "    ") + data["name"]
	name_lbl.add_theme_font_size_override("font_size", 19)

	var sub_lbl := Label.new()
	sub_lbl.text = "%d locations  |  $%.0f/s  |  Cost: $%s" % [
		data.get("locations", 0),
		data.get("income_per_sec", 0.0),
		_fmt_large(data.get("cost", 0.0))
	]
	sub_lbl.add_theme_font_size_override("font_size", 13)

	vbox.add_child(name_lbl)
	vbox.add_child(sub_lbl)

	var select_btn := Button.new()
	select_btn.custom_minimum_size = Vector2(110, 0)
	if owned:
		select_btn.text = "Acquired"
		select_btn.disabled = true
	else:
		select_btn.text = "View"
		select_btn.pressed.connect(_select_chain.bind(data))

	hbox.add_child(status_dot)
	hbox.add_child(vbox)
	hbox.add_child(select_btn)
	return panel

func _select_chain(data: Dictionary) -> void:
	_selected_chain = data
	info_panel.visible = true

	info_name.text  = data["name"]
	info_desc.text  = data.get("description", "")
	info_stats.text = (
		"Locations: %d\n" +
		"Income: $%.2f/sec\n" +
		"Rep Required: %d\n" +
		"Cost: $%s"
	) % [data.get("locations", 0), data.get("income_per_sec", 0.0),
	     data.get("rep_req", 0), _fmt_large(data.get("cost", 0.0))]

	var can_buy: bool = (GameManager.money >= data["cost"]
	                    and GameManager.reputation >= data.get("rep_req", 0)
	                    and not GameManager.owns_shop(data["id"]))
	buy_btn.disabled = not can_buy
	if GameManager.owns_shop(data["id"]):
		buy_btn.text = "Already Owned"
	elif not GameManager.can_afford(data["cost"]):
		buy_btn.text = "Need $%s" % _fmt_large(data["cost"])
	elif GameManager.reputation < data.get("rep_req", 0):
		buy_btn.text = "Rep Too Low (%d)" % data["rep_req"]
	else:
		buy_btn.text = "ACQUIRE  ($%s)" % _fmt_large(data["cost"])

func _on_buy_pressed() -> void:
	if _selected_chain.is_empty():
		return
	if GameManager.buy_shop(_selected_chain):
		_show_status("You acquired %s!" % _selected_chain["name"])
		_build_chain_list()
		info_panel.visible = false
		_refresh_empire_bar()
	else:
		_show_status("Transaction failed.")

func _on_chain_bought(_data: Dictionary) -> void:
	_build_chain_list()
	_refresh_empire_bar()

func _on_unlock(unlock_name: String) -> void:
	if unlock_name == "final_tower":
		_show_status("YOU OWN EVERY CHAIN IN AMERICA! Heading to the tower...")
		await get_tree().create_timer(2.5).timeout
		get_tree().change_scene_to_file(FINAL_SCENE)

func _refresh_empire_bar() -> void:
	var owned_chains := GameManager.get_national_chains_owned()
	empire_bar.value = (owned_chains / 5.0) * 100.0
	empire_bar.tooltip_text = "%d / 5 national chains acquired" % owned_chains

func _refresh_header(_val = null) -> void:
	money_label.text = "Cash: $%s" % _fmt_large(GameManager.money)
	rep_label.text   = "Rep: %d" % GameManager.reputation

func _show_status(msg: String) -> void:
	status_label.text    = msg
	status_label.visible = true
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func(): status_label.visible = false)

func _fmt_large(n: float) -> String:
	if n >= 1_000_000.0:
		return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000.0:
		return "%.1fK" % (n / 1_000.0)
	return "%.0f" % n

func _go_back() -> void:
	get_tree().change_scene_to_file(HOME_SHOP_SCENE)
