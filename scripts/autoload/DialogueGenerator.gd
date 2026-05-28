## DialogueGenerator.gd
## Autoload singleton. Generates randomised customer dialogue, reviews,
## and staff chatter using weighted phrase pools.
extends Node

# ─────────────────────────────────────────────
#  CUSTOMER GREETINGS  (shown when customer sits down)
# ─────────────────────────────────────────────
const GREETINGS: Array[String] = [
	"Hey, just a trim please.",
	"I want to look fresh for my date tonight!",
	"My boss said I need to clean up. Help me out.",
	"Give me the classic fade.",
	"I saw your shop on Instagram – let's see what you got!",
	"Just the sides. Don't touch the top.",
	"Surprise me, barber.",
	"I haven't cut my hair in six months. Do your best.",
	"My mom said I look like a mop. Fix it.",
	"I need to look sharp for a job interview tomorrow.",
	"Keep it simple – clean taper.",
	"Can you make me look like I run a Fortune 500 company?",
	"I'm a regular. You know what I like.",
	"Low fade, line it up in the back.",
	"Whatever's trending. I trust you.",
]

# ─────────────────────────────────────────────
#  DURING HAIRCUT COMMENTS  (shown mid-minigame)
# ─────────────────────────────────────────────
const MID_CUT_COMMENTS: Array[String] = [
	"Careful on the sides...",
	"Looking good so far!",
	"Easy on the top!",
	"You seem focused. I like that.",
	"Is it hot in here, or is that just the clippers?",
	"Don't mess up my edges!",
	"My neck is a bit ticklish, just a heads-up.",
	"I can't look. Tell me when it's done.",
	"This chair is super comfortable, actually.",
	"So... how long have you been cutting hair?",
]

# ─────────────────────────────────────────────
#  REVIEW PHRASES  (keyed by star rating 1-5)
# ─────────────────────────────────────────────
const REVIEW_PHRASES: Dictionary = {
	1: [
		"Absolutely terrible. Looked like my cat chewed my head.",
		"Never again. I had to wear a hat for two weeks.",
		"One star is too generous. My edges are uneven.",
		"I asked for a trim, got a disaster.",
		"This 'barber' should consider a career change.",
	],
	2: [
		"Could be better. The line-up was sloppy.",
		"Below average. I've had worse, I guess.",
		"Not great. The fade wasn't blended well.",
		"My expectations were low and still got disappointed.",
		"2 stars because at least my hair is shorter now.",
	],
	3: [
		"Decent cut. Nothing special.",
		"It's fine. Does the job.",
		"Average work. Would come back if prices stay low.",
		"Not bad, not amazing. Solid 3.",
		"Middle of the road. The barber needs more practice.",
	],
	4: [
		"Really good! Clean fade and sharp edges.",
		"Impressed! Will be back next month.",
		"Great cut. Just a tiny bit uneven on the left.",
		"Love the vibe of this place. Hair looks fresh.",
		"Solid 4 stars – one of the better shops I've tried.",
	],
	5: [
		"GOAT barber. Absolutely immaculate cut. 10/10.",
		"This is the best haircut I've ever gotten. Period.",
		"My edges are SHARP. I feel like a new man.",
		"Pure artistry. I tipped 50% and don't regret it.",
		"Called my mom to tell her about this haircut. Perfect.",
		"I drove 45 minutes for this. Worth every second.",
	],
}

# ─────────────────────────────────────────────
#  STAFF CHATTER  (shown in staff menu / idle bubbles)
# ─────────────────────────────────────────────
const STAFF_CHATTER: Array[String] = [
	"Anyone want some coffee?",
	"I had three fade requests in a row. My arm is tired.",
	"Did you see the game last night?",
	"The lineup on seat 2 is taking forever.",
	"I've been cutting hair for 8 years. This place is different.",
	"We should get a barber pole out front.",
	"My last shop didn't even have AC. This is luxury.",
	"I think we need more chairs in here.",
	"Customer asked me to do a design. I went for it.",
	"Tips are good today. Must be Friday energy.",
]

# ─────────────────────────────────────────────
#  UPGRADE FLAVOUR TEXT  (shown after buying an upgrade)
# ─────────────────────────────────────────────
const UPGRADE_FLAVOUR: Dictionary = {
	"clipper_level": [
		"New clippers? Slicing through hair like butter.",
		"Upgraded blades. Your cuts just got sharper.",
		"Premium clippers installed. The buzz never sounded better.",
	],
	"speed_level": [
		"You move faster now. Customers are impressed.",
		"Quicker hands, more customers. Time is money.",
		"Speed upgrade! You're practically a blur.",
	],
	"accuracy_level": [
		"Your lines are straighter. Artists would be jealous.",
		"Accuracy up. Not a single crooked edge.",
		"Precision mode unlocked. Every cut is a masterpiece.",
	],
	"patience_level": [
		"You've learned to keep customers comfortable. Less walkouts.",
		"Customers feel at ease. They'll wait for you.",
		"Better customer experience. Your patience is legendary.",
	],
}

# ─────────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────────

## Returns a random customer greeting.
func get_customer_greeting() -> String:
	return GREETINGS[randi() % GREETINGS.size()]

## Returns a random mid-cut comment.
func get_mid_cut_comment() -> String:
	return MID_CUT_COMMENTS[randi() % MID_CUT_COMMENTS.size()]

## Returns a review string based on a score 0.0-1.0.
## score >= 0.9 → 5 stars, >= 0.7 → 4, >= 0.5 → 3, >= 0.3 → 2, else → 1
func get_review(score: float) -> String:
	var stars := _score_to_stars(score)
	var pool: Array = REVIEW_PHRASES[stars]
	return pool[randi() % pool.size()]

## Returns a random star rating (int 1-5) for a score.
func get_star_rating(score: float) -> int:
	return _score_to_stars(score)

## Returns a random staff chatter line.
func get_staff_chatter() -> String:
	return STAFF_CHATTER[randi() % STAFF_CHATTER.size()]

## Returns upgrade flavour text for the given upgrade key.
func get_upgrade_flavour(upgrade_name: String) -> String:
	var pool: Array = UPGRADE_FLAVOUR.get(upgrade_name, ["Upgrade complete!"])
	return pool[randi() % pool.size()]

## Returns a random name for a generated staff member.
func get_random_staff_name() -> String:
	var first_names: Array[String] = [
		"Marcus", "DeShawn", "Tyrell", "Antoine", "Jerome",
		"Carlos", "Miguel", "Kevin", "Darnell", "Jamal",
		"Liam", "Andre", "Devon", "Rasheed", "Terrence",
		"Victor", "Elijah", "Malik", "Isaiah", "Calvin"
	]
	var last_names: Array[String] = [
		"Williams", "Johnson", "Davis", "Brown", "Wilson",
		"Moore", "Taylor", "Jackson", "Harris", "Martin",
		"Thompson", "Garcia", "Robinson", "Clark", "Lewis"
	]
	return first_names[randi() % first_names.size()] + " " + last_names[randi() % last_names.size()]

# ─────────────────────────────────────────────
#  PRIVATE
# ─────────────────────────────────────────────
func _score_to_stars(score: float) -> int:
	if score >= 0.90: return 5
	if score >= 0.70: return 4
	if score >= 0.50: return 3
	if score >= 0.30: return 2
	return 1
