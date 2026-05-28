## GameManager.gd
## Global autoload singleton. Holds all persistent game state, save/load logic,
## and emits top-level signals the rest of the game listens to.
extends Node

# ─────────────────────────────────────────────
#  CORE CURRENCY & REPUTATION
# ─────────────────────────────────────────────
var money: float = 50.0          # Current cash on hand
var reputation: int = 0          # Overall fame (0-1000)
var total_customers_served: int = 0
var total_haircuts_done: int = 0

# ─────────────────────────────────────────────
#  UPGRADE LEVELS  (1 = base, 10 = max)
# ─────────────────────────────────────────────
var upgrades: Dictionary = {
	"clipper_level":   1,   # Improves haircut quality score
	"speed_level":     1,   # Reduces time per customer
	"accuracy_level":  1,   # Increases accuracy bonus
	"patience_level":  1    # Customers wait longer before leaving
}

# ─────────────────────────────────────────────
#  OWNED SHOPS
#  Each entry: { id, name, type, cost, income_per_sec, rep_req,
#                purchase_time, assigned_staff:[] }
# ─────────────────────────────────────────────
var owned_shops: Array = []

# ─────────────────────────────────────────────
#  HIRED STAFF
#  Each entry: { id, name, speed, accuracy, charm, wage_per_min,
#                hire_cost, assigned_shop }
# ─────────────────────────────────────────────
var staff: Array = []

# ─────────────────────────────────────────────
#  PROGRESSION UNLOCK FLAGS
# ─────────────────────────────────────────────
var game_unlocks: Dictionary = {
	"home_shop":           true,
	"upgrade_menu":        true,
	"staff_menu":          false,   # Unlocks at $200
	"shop_menu":           false,   # Unlocks at $500 + rep 10
	"empire_map":          false,   # Unlocks on first shop purchase
	"national_expansion":  false,   # Unlocks at $50,000 + 5 shops
	"final_tower":         false    # Unlocks on owning all 5 national chains
}

# ─────────────────────────────────────────────
#  PASSIVE INCOME TIMER
# ─────────────────────────────────────────────
var _income_timer: float = 0.0
const INCOME_TICK_INTERVAL: float = 1.0   # seconds between passive income ticks

# ─────────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────────
signal money_changed(new_amount: float)
signal reputation_changed(new_rep: int)
signal shop_bought(shop_data: Dictionary)
signal staff_hired(staff_data: Dictionary)
signal upgrade_purchased(upgrade_name: String, new_level: int)
signal unlock_triggered(unlock_name: String)
signal game_saved
signal game_loaded

const SAVE_PATH := "user://barber_empire_save.json"
const SAVE_VERSION := "1.1"

# ─────────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────────
func _ready() -> void:
	check_unlocks()

func _process(delta: float) -> void:
	_income_timer += delta
	if _income_timer >= INCOME_TICK_INTERVAL:
		_income_timer = 0.0
		_tick_passive_income()

# ─────────────────────────────────────────────
#  MONEY HELPERS
# ─────────────────────────────────────────────
func add_money(amount: float) -> void:
	money += amount
	money_changed.emit(money)
	check_unlocks()

func spend_money(amount: float) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false

func can_afford(amount: float) -> bool:
	return money >= amount

# ─────────────────────────────────────────────
#  REPUTATION HELPERS
# ─────────────────────────────────────────────
func add_reputation(amount: int) -> void:
	reputation = clampi(reputation + amount, 0, 1000)
	reputation_changed.emit(reputation)
	check_unlocks()

# ─────────────────────────────────────────────
#  UPGRADE HELPERS
# ─────────────────────────────────────────────
func get_upgrade_level(upgrade_name: String) -> int:
	return upgrades.get(upgrade_name, 1)

func upgrade(upgrade_name: String) -> bool:
	var current_level: int = upgrades.get(upgrade_name, 1)
	if current_level >= 10:
		return false
	var cost: float = Economy.get_upgrade_cost(upgrade_name, current_level)
	if spend_money(cost):
		upgrades[upgrade_name] += 1
		upgrade_purchased.emit(upgrade_name, upgrades[upgrade_name])
		return true
	return false

# ─────────────────────────────────────────────
#  SHOP HELPERS
# ─────────────────────────────────────────────
func buy_shop(shop_data: Dictionary) -> bool:
	var cost: float = shop_data.get("cost", 0)
	if not can_afford(cost):
		return false
	# Prevent buying the same shop twice
	for s in owned_shops:
		if s.get("id", "") == shop_data.get("id", ""):
			return false
	if spend_money(cost):
		var shop_copy := shop_data.duplicate(true)
		shop_copy["purchase_time"] = Time.get_unix_time_from_system()
		shop_copy["assigned_staff"] = []
		owned_shops.append(shop_copy)
		shop_bought.emit(shop_copy)
		add_reputation(shop_data.get("rep_reward", 5))
		check_unlocks()
		return true
	return false

func owns_shop(shop_id: String) -> bool:
	for s in owned_shops:
		if s.get("id", "") == shop_id:
			return true
	return false

func get_national_chains_owned() -> int:
	var count := 0
	for s in owned_shops:
		if s.get("type", "") == "national_chain":
			count += 1
	return count

# ─────────────────────────────────────────────
#  STAFF HELPERS
# ─────────────────────────────────────────────
func hire_staff(staff_data: Dictionary) -> bool:
	var hire_cost: float = staff_data.get("hire_cost", 50)
	if spend_money(hire_cost):
		var staff_copy := staff_data.duplicate(true)
		staff_copy["hire_time"] = Time.get_unix_time_from_system()
		staff_copy["assigned_shop"] = -1
		staff.append(staff_copy)
		staff_hired.emit(staff_copy)
		return true
	return false

func assign_staff(staff_id: String, shop_id: int) -> void:
	for member in staff:
		if member.get("id", "") == staff_id:
			member["assigned_shop"] = shop_id
			return

# ─────────────────────────────────────────────
#  PASSIVE INCOME
# ─────────────────────────────────────────────
func _tick_passive_income() -> void:
	var income := Economy.calculate_total_income(owned_shops, staff)
	if income > 0.0:
		add_money(income)

func get_income_per_second() -> float:
	return Economy.calculate_total_income(owned_shops, staff)

# ─────────────────────────────────────────────
#  UNLOCK CHECKS
# ─────────────────────────────────────────────
func check_unlocks() -> void:
	_check_unlock("staff_menu",         money >= 200.0)
	_check_unlock("shop_menu",          money >= 500.0 and reputation >= 10)
	_check_unlock("empire_map",         owned_shops.size() > 0)
	_check_unlock("national_expansion", money >= 50000.0 and owned_shops.size() >= 5)
	_check_unlock("final_tower",        get_national_chains_owned() >= 5)

func _check_unlock(key: String, condition: bool) -> void:
	if condition and not game_unlocks.get(key, false):
		game_unlocks[key] = true
		unlock_triggered.emit(key)

# ─────────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────────
func save_game() -> void:
	var save_data := {
		"save_version":           SAVE_VERSION,
		"save_time":              Time.get_unix_time_from_system(),
		"money":                  money,
		"reputation":             reputation,
		"total_customers_served": total_customers_served,
		"total_haircuts_done":    total_haircuts_done,
		"upgrades":               upgrades,
		"owned_shops":            owned_shops,
		"staff":                  staff,
		"game_unlocks":           game_unlocks
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		game_saved.emit()
		print("[GameManager] Game saved.")
	else:
		push_error("[GameManager] Could not open save file for writing.")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[GameManager] No save file found.")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("[GameManager] Could not open save file for reading.")
		return false
	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("[GameManager] Failed to parse save JSON.")
		return false

	var d: Dictionary = json.get_data()
	money                  = d.get("money",                  50.0)
	reputation             = d.get("reputation",             0)
	total_customers_served = d.get("total_customers_served", 0)
	total_haircuts_done    = d.get("total_haircuts_done",    0)
	upgrades               = d.get("upgrades",               upgrades)
	owned_shops            = d.get("owned_shops",            [])
	staff                  = d.get("staff",                  [])
	game_unlocks           = d.get("game_unlocks",           game_unlocks)

	money_changed.emit(money)
	reputation_changed.emit(reputation)
	game_loaded.emit()
	check_unlocks()
	print("[GameManager] Game loaded.")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	# Reset state to defaults
	money                  = 50.0
	reputation             = 0
	total_customers_served = 0
	total_haircuts_done    = 0
	upgrades               = {
		"clipper_level":  1,
		"speed_level":    1,
		"accuracy_level": 1,
		"patience_level": 1
	}
	owned_shops  = []
	staff        = []
	game_unlocks = {
		"home_shop":          true,
		"upgrade_menu":       true,
		"staff_menu":         false,
		"shop_menu":          false,
		"empire_map":         false,
		"national_expansion": false,
		"final_tower":        false
	}
