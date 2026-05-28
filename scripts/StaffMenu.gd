## StaffMenu.gd
## Browse randomly generated barber candidates, hire them, and assign them to shops.
extends Control

@onready var money_label:   Label       = $Header/HBox/MoneyLabel
@onready var back_btn:      Button      = $Header/HBox/BackBtn
@onready var refresh_btn:   Button      = $Header/HBox/RefreshBtn
@onready var candidates_list: VBoxContainer = $Split/Left/ScrollContainer/CandidateList
@onready var hired_list:    VBoxContainer   = $Split/Right/ScrollContainer/HiredList
@onready var chatter_label: Label           = $ChatterLabel

const HOME_SHOP_SCENE := "res://scenes/HomeShop.tscn"
const NUM_CANDIDATES  := 5
const REFRESH_COST    := 20.0   # cost to reroll candidates

var _candidates: Array = []

func _ready() -> void:
	back_btn.pressed.connect(_go_back)
	refresh_btn.pressed.connect(_refresh_candidates)
	GameManager.money_changed.connect(_update_money_label)
	GameManager.staff_hired.connect(_rebuild_hired_list)

	_generate_candidates()
	_rebuild_hired_list()
	_update_money_label(GameManager.money)
	_show_chatter()

func _generate_candidates() -> void:
	_candidates.clear()
	for i in NUM_CANDIDATES:
		_candidates.append(Economy.generate_staff_candidate(i))
	_rebuild_candidate_list()

func _refresh_candidates() -> void:
	if GameManager.spend_money(REFRESH_COST):
		_generate_candidates()
	else:
		chatter_label.text = "Not enough cash to refresh candidates! ($%.0f)" % REFRESH_COST

func _rebuild_candidate_list() -> void:
	for child in candidates_list.get_children():
		child.queue_free()
	for candidate in _candidates:
		var card := _make_candidate_card(candidate)
		candidates_list.add_child(card)

func _make_candidate_card(data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 100)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.add_theme_font_size_override("font_size", 17)

	var stats_lbl := Label.new()
	stats_lbl.text = "Speed: %d  Acc: %d  Charm: %d  |  Wage: $%.1f/min" % [
		data["speed"], data["accuracy"], data["charm"], data["wage_per_min"]
	]
	stats_lbl.add_theme_font_size_override("font_size", 13)

	var hire_btn := Button.new()
	hire_btn.text = "HIRE  ($%.0f)" % data["hire_cost"]
	hire_btn.disabled = not GameManager.can_afford(data["hire_cost"])
	hire_btn.pressed.connect(_on_hire_pressed.bind(data, hire_btn))

	vbox.add_child(name_lbl)
	vbox.add_child(stats_lbl)
	vbox.add_child(hire_btn)
	return panel

func _on_hire_pressed(data: Dictionary, btn: Button) -> void:
	if GameManager.hire_staff(data):
		btn.disabled = true
		btn.text = "HIRED"
		chatter_label.text = "%s just joined your team!" % data["name"]
		_show_chatter()
	else:
		chatter_label.text = "Not enough cash!"

func _rebuild_hired_list(_unused = null) -> void:
	for child in hired_list.get_children():
		child.queue_free()

	if GameManager.staff.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No staff hired yet."
		hired_list.add_child(empty_lbl)
		return

	for member in GameManager.staff:
		var row := _make_hired_row(member)
		hired_list.add_child(row)

func _make_hired_row(data: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 50)

	var lbl := Label.new()
	lbl.text = "%s  [Spd:%d Acc:%d Chr:%d]" % [
		data["name"], data["speed"], data["accuracy"], data["charm"]
	]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var shop_lbl := Label.new()
	var assigned := data.get("assigned_shop", -1)
	shop_lbl.text = "Shop: %s" % ("Home" if assigned == -1 else str(assigned))

	row.add_child(lbl)
	row.add_child(shop_lbl)
	return row

func _update_money_label(_val = null) -> void:
	money_label.text = "Cash: $%.2f" % GameManager.money
	# Refresh hire button states
	_rebuild_candidate_list()

func _show_chatter() -> void:
	chatter_label.text = DialogueGenerator.get_staff_chatter()

func _go_back() -> void:
	get_tree().change_scene_to_file(HOME_SHOP_SCENE)
