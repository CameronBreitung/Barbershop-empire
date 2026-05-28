## Economy.gd
## Autoload singleton. All financial calculations live here so they
## can be tuned from one place without touching scene scripts.
extends Node

# ─────────────────────────────────────────────
#  UPGRADE COSTS
#  cost = BASE_COST * (LEVEL ^ EXPONENT)
# ─────────────────────────────────────────────
const UPGRADE_BASE_COSTS: Dictionary = {
	"clipper_level":  50.0,
	"speed_level":    40.0,
	"accuracy_level": 60.0,
	"patience_level": 35.0,
}
const UPGRADE_EXPONENT := 1.8

func get_upgrade_cost(upgrade_name: String, current_level: int) -> float:
	var base: float = UPGRADE_BASE_COSTS.get(upgrade_name, 50.0)
	return snappedf(base * pow(current_level, UPGRADE_EXPONENT), 1.0)

# ─────────────────────────────────────────────
#  HAIRCUT PAYOUT
#  Base pay * accuracy multiplier * clipper bonus
# ─────────────────────────────────────────────
const BASE_HAIRCUT_PAY := 15.0
const TIP_THRESHOLD   := 0.80   # Score must beat this to get a tip

func calculate_haircut_payout(score: float) -> float:
	var clipper_bonus := 1.0 + (GameManager.get_upgrade_level("clipper_level") - 1) * 0.15
	var accuracy_bonus := 1.0 + (GameManager.get_upgrade_level("accuracy_level") - 1) * 0.10
	var pay := BASE_HAIRCUT_PAY * score * clipper_bonus * accuracy_bonus
	# Tip for excellent work
	if score >= TIP_THRESHOLD:
		pay += randf_range(2.0, 10.0)
	return snappedf(pay, 0.01)

## Returns the reputation points earned for a given score.
func calculate_rep_gain(score: float) -> int:
	if score >= 0.90: return 5
	if score >= 0.70: return 3
	if score >= 0.50: return 1
	return 0

# ─────────────────────────────────────────────
#  CUSTOMER PATIENCE (seconds before walkout)
# ─────────────────────────────────────────────
const BASE_PATIENCE := 30.0

func get_customer_patience() -> float:
	var level := GameManager.get_upgrade_level("patience_level")
	return BASE_PATIENCE + (level - 1) * 8.0

# ─────────────────────────────────────────────
#  CUT SPEED  (higher = fewer seconds per cut)
# ─────────────────────────────────────────────
const BASE_CUT_SPEED := 1.0   # multiplier

func get_cut_speed_multiplier() -> float:
	var level := GameManager.get_upgrade_level("speed_level")
	return BASE_CUT_SPEED + (level - 1) * 0.25

# ─────────────────────────────────────────────
#  SHOP PASSIVE INCOME
# ─────────────────────────────────────────────

## Returns total passive income per second from all owned shops,
## reduced by staff wages.
func calculate_total_income(owned_shops: Array, hired_staff: Array) -> float:
	var gross := 0.0
	for shop in owned_shops:
		gross += shop.get("income_per_sec", 0.0)

	var wage_cost_per_sec := 0.0
	for member in hired_staff:
		# wage_per_min → per_sec
		wage_cost_per_sec += member.get("wage_per_min", 0.0) / 60.0

	return maxf(gross - wage_cost_per_sec, 0.0)

## Returns the total weekly wage bill (display only).
func get_weekly_wage_bill(hired_staff: Array) -> float:
	var total := 0.0
	for member in hired_staff:
		total += member.get("wage_per_min", 0.0) * 60.0 * 24.0 * 7.0
	return snappedf(total, 0.01)

# ─────────────────────────────────────────────
#  STAFF GENERATION HELPERS
# ─────────────────────────────────────────────
const HIRE_COST_BASE := 50.0

## Generates random stat block for a new hire candidate.
func generate_staff_candidate(candidate_index: int) -> Dictionary:
	var spd   := randi_range(3, 9)
	var acc   := randi_range(3, 9)
	var charm := randi_range(2, 8)
	# Wage scales with quality
	var quality := (spd + acc + charm) / 3.0
	var wage    := snappedf(quality * 0.8 + randf_range(1.0, 3.0), 0.1)
	var hire    := snappedf(HIRE_COST_BASE * (quality / 5.0) * randf_range(0.8, 1.3), 1.0)
	return {
		"id":          "staff_%d_%d" % [candidate_index, randi()],
		"name":        DialogueGenerator.get_random_staff_name(),
		"speed":       spd,
		"accuracy":    acc,
		"charm":       charm,
		"wage_per_min": wage,
		"hire_cost":   hire,
		"assigned_shop": -1,
	}

# ─────────────────────────────────────────────
#  LOCAL SHOP DATA
# ─────────────────────────────────────────────
const LOCAL_SHOPS: Array[Dictionary] = [
	{
		"id": "home_garage",
		"name": "Home Garage Shop",
		"type": "local",
		"cost": 500.0,
		"income_per_sec": 0.08,
		"rep_req": 0,
		"rep_reward": 5,
		"description": "Convert your garage into a proper barbershop."
	},
	{
		"id": "strip_mall_1",
		"name": "Main St Strip Mall",
		"type": "local",
		"cost": 2500.0,
		"income_per_sec": 0.35,
		"rep_req": 15,
		"rep_reward": 10,
		"description": "A busy strip mall spot with solid foot traffic."
	},
	{
		"id": "downtown_corner",
		"name": "Downtown Corner Shop",
		"type": "local",
		"cost": 8000.0,
		"income_per_sec": 0.90,
		"rep_req": 40,
		"rep_reward": 20,
		"description": "Prime downtown real estate. High volume."
	},
	{
		"id": "mall_kiosk",
		"name": "Shopping Mall Kiosk",
		"type": "local",
		"cost": 18000.0,
		"income_per_sec": 1.80,
		"rep_req": 80,
		"rep_reward": 30,
		"description": "Inside the busiest mall in town. Constant traffic."
	},
	{
		"id": "luxury_salon",
		"name": "Luxury Barbershop & Spa",
		"type": "local",
		"cost": 40000.0,
		"income_per_sec": 3.50,
		"rep_req": 150,
		"rep_reward": 50,
		"description": "High-end barbershop. Premium prices, premium clients."
	},
]

# ─────────────────────────────────────────────
#  NATIONAL CHAIN DATA
# ─────────────────────────────────────────────
const NATIONAL_CHAINS: Array[Dictionary] = [
	{
		"id": "chain_cuts_r_us",
		"name": "Cuts R Us",
		"type": "national_chain",
		"cost": 250000.0,
		"income_per_sec": 12.0,
		"rep_req": 300,
		"rep_reward": 100,
		"locations": 120,
		"description": "The budget chain. Franchise buyout."
	},
	{
		"id": "chain_fade_nation",
		"name": "Fade Nation",
		"type": "national_chain",
		"cost": 600000.0,
		"income_per_sec": 25.0,
		"rep_req": 450,
		"rep_reward": 150,
		"locations": 280,
		"description": "Urban-focused chain with 280 locations."
	},
	{
		"id": "chain_first_class_cuts",
		"name": "First Class Cuts",
		"type": "national_chain",
		"cost": 1500000.0,
		"income_per_sec": 55.0,
		"rep_req": 600,
		"rep_reward": 200,
		"locations": 500,
		"description": "Mid-tier chain dominant in the Midwest."
	},
	{
		"id": "chain_empire_style",
		"name": "Empire Style",
		"type": "national_chain",
		"cost": 4000000.0,
		"income_per_sec": 130.0,
		"rep_req": 750,
		"rep_reward": 300,
		"locations": 900,
		"description": "Major premium chain. Acquiring this changes everything."
	},
	{
		"id": "chain_the_crown",
		"name": "The Crown",
		"type": "national_chain",
		"cost": 10000000.0,
		"income_per_sec": 300.0,
		"rep_req": 900,
		"rep_reward": 500,
		"locations": 2000,
		"description": "The largest barbershop chain in America. Own this and you own everything."
	},
]
