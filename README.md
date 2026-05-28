# Barber Empire

> *Cut hair. Build a business. Own every barbershop in America.*

A pixel-art tycoon game built in **Godot 4**. You start in your home cutting hair manually and work your way up to owning every national barbershop chain in the country.

---

## Table of Contents

1. [How to Run the Project](#how-to-run)
2. [Game Overview](#game-overview)
3. [Every Scene Explained](#scenes)
4. [Every Button Explained](#buttons)
5. [How the Haircut Mini-Game Works](#minigame)
6. [How Upgrades Work](#upgrades)
7. [How Shops Unlock](#shops)
8. [How Staff Works](#staff)
9. [How National Expansion Works](#national)
10. [How the Final Tower Scene Triggers](#final)
11. [GameManager Variables Reference](#variables)
12. [How to Replace Placeholder Art](#art)
13. [Git & GitHub Setup](#git)
14. [Project File Structure](#structure)

---

## How to Run the Project <a name="how-to-run"></a>

### Requirements
- [Godot 4.2+](https://godotengine.org/download) (download the standard version, not Mono)

### Steps
1. Open Godot 4
2. Click **Import** on the Project Manager screen
3. Navigate to the `BarbashopEmpire/` folder
4. Select `project.godot` and click **Import & Edit**
5. Press **F5** or click the **Play** button (▶) to run
6. The game starts at `StartScreen.tscn`

---

## Game Overview <a name="game-overview"></a>

### Progression Path

```
Home Kitchen  →  Garage Shop  →  Strip Mall  →  Downtown  →  Mall Kiosk  →  Luxury Salon
     ↓
National Chains (5 total)  →  Final Tower Scene (YOU WIN)
```

### Core Loop
1. **Cut hair** (drag minigame) → earn money + reputation
2. **Upgrade** your skills to cut better/faster → earn more per cut
3. **Hire staff** → they run your shops passively
4. **Buy shops** → passive income while you cut
5. **Expand nationally** → acquire the 5 major chains
6. **Win** → cutscene at the top of a skyscraper

---

## Every Scene Explained <a name="scenes"></a>

### `StartScreen.tscn`
The main menu. Background shows a front door (placeholder colored rects).
- Loads when the game first opens
- If a save file exists, **Continue** is enabled
- **Settings** panel slides in with volume and fullscreen options
- **Credits** panel shows attribution

### `HomeShop.tscn`
The main game scene. The player manually cuts hair here at all times.
- **Top HUD bar**: money, reputation, passive income, nav buttons
- **Customer Area**: colored rect head sits in a chair
- **Clip Zone**: yellow-outlined drag area. Drag inside it to fill the progress bar
- **Patience Bar**: red bar counts down. Customer walks out at 0
- **Result Panel**: shown after each cut with score, money, review, and star rating
- **Notifications**: popup text for unlocks and saves (bottom of screen)

### `UpgradeMenu.tscn`
Displayed when you press **UPGRADES** in the HUD. Shows 4 upgrade rows.
- Each row: name, current level, next cost, flavour text, Buy button
- Upgrading is instant — cost is deducted and level increases
- Max level is 10 for all upgrades

### `StaffMenu.tscn`
Displayed when you press **STAFF** (unlocks at $200).
- **Left panel**: 5 randomly generated barber candidates with stats
- **Right panel**: your currently hired staff
- **Reroll Candidates** ($20): generates 5 new candidates
- Hiring staff costs their `hire_cost` value

### `ShopMenu.tscn`
Displayed when you press **SHOPS** (unlocks at $500 + Rep 10).
- **Left column**: all 5 local shops listed with status (owned = green)
- **Right panel**: details for the selected shop
- Clicking **Details** shows the shop's description, income rate, and requirements
- Clicking **BUY** purchases the shop if requirements are met

### `EmpireMap.tscn`
Displayed when you press **EMPIRE** (unlocks after buying first shop).
- Shows a top-down grid map of your hometown
- Each owned shop has a green dot at its position on the map
- Unowned shops are gray dots
- **Stats panel** (right side): shops owned, staff, income, haircuts, customers
- **NATIONAL →** button appears when you qualify for national expansion

### `NationalExpansion.tscn`
Displayed via the Empire Map. Shows 5 major national chains to acquire.
- Each chain has: locations, income/sec, rep requirement, cost
- Empire progress bar at the top shows X/5 chains acquired
- Acquiring all 5 triggers the win condition automatically

### `FinalTowerScene.tscn`
Victory screen. Triggered automatically when all 5 national chains are owned.
- Dark night-sky background with city silhouette (placeholder colored rects)
- Player silhouette at a desk at the top of a skyscraper
- Shows full empire stats summary
- Credits roll
- Two buttons: **MAIN MENU** and **KEEP PLAYING**

---

## Every Button Explained <a name="buttons"></a>

### StartScreen
| Button | Action |
|--------|--------|
| NEW GAME | Deletes any existing save, starts fresh from HomeShop |
| CONTINUE | Loads save file and goes to HomeShop |
| SETTINGS | Toggles the settings panel (volume, fullscreen) |
| CREDITS | Toggles the credits panel |
| EXIT | Calls `get_tree().quit()` |

### HomeShop HUD
| Button | Action |
|--------|--------|
| UPGRADES | Saves game, loads UpgradeMenu |
| STAFF | Saves game, loads StaffMenu (locked until $200) |
| SHOPS | Saves game, loads ShopMenu (locked until $500 + Rep 10) |
| EMPIRE | Saves game, loads EmpireMap (locked until 1 shop owned) |
| SAVE | Saves game, shows notification |
| MENU | Saves game, returns to StartScreen |
| NEXT CUSTOMER | Dismisses result panel and spawns next customer |

### UpgradeMenu
| Button | Action |
|--------|--------|
| UPGRADE (×4) | Deducts cost, increments that upgrade level by 1 |
| ← BACK | Returns to HomeShop |

### StaffMenu
| Button | Action |
|--------|--------|
| REROLL CANDIDATES | Spends $20, generates 5 new random candidates |
| HIRE ($X) | Pays hire cost, adds barber to your team |
| ← BACK | Returns to HomeShop |

### ShopMenu
| Button | Action |
|--------|--------|
| Details | Loads that shop's info into the right panel |
| BUY | Purchases the shop if affordable + rep met |
| ← BACK | Returns to HomeShop |

### EmpireMap
| Button | Action |
|--------|--------|
| NATIONAL → | Opens NationalExpansion screen |
| ← BACK | Returns to HomeShop |

### NationalExpansion
| Button | Action |
|--------|--------|
| View | Loads that chain's details into right panel |
| ACQUIRE | Purchases the national chain |
| ← BACK | Returns to HomeShop |

### FinalTowerScene
| Button | Action |
|--------|--------|
| MAIN MENU | Returns to StartScreen |
| KEEP PLAYING | Returns to HomeShop (passive income still accumulates) |

---

## How the Haircut Mini-Game Works <a name="minigame"></a>

1. A customer "sits down" — a colored rectangle appears in the chair area
2. A **Clip Zone** (outlined yellow box) overlays the customer's head
3. **Hold Left Mouse Button and drag** inside the Clip Zone to fill the green progress bar
4. Dragging **outside** the Clip Zone reduces your accuracy score
5. The faster you fill the bar, the better (speed upgrade helps here)
6. When the bar reaches 100%, the cut completes automatically
7. **Patience Bar** (red) counts down from full. If it hits 0 before you finish, the customer walks out (no money, -1 rep)

### Score Calculation
```
final_score = (cut_progress × 0.6) + (accuracy × 0.4)
accuracy starts at 1.0, decreases by 0.001 per pixel dragged outside the zone
```

### Payout Formula (from Economy.gd)
```
base_pay = $15.00
clipper_bonus = 1 + (clipper_level - 1) × 0.15
accuracy_bonus = 1 + (accuracy_level - 1) × 0.10
payout = base_pay × score × clipper_bonus × accuracy_bonus
+ tip ($2-$10) if score >= 0.80
```

---

## How Upgrades Work <a name="upgrades"></a>

Four upgrade tracks, each going from level 1 to 10.

| Upgrade | Effect |
|---------|--------|
| **Clippers** (clipper_level) | +15% payout per level |
| **Speed** (speed_level) | +25% cut speed multiplier per level (bar fills faster) |
| **Accuracy** (accuracy_level) | +10% payout per level |
| **Customer Patience** (patience_level) | +8 seconds of patience per level |

### Cost Formula
```
cost = base_cost × (current_level ^ 1.8)
Base costs: Clippers $50, Speed $40, Accuracy $60, Patience $35
```

Level 1→2 costs the base. By level 9→10 it costs ~10× the base.

---

## How Shops Unlock <a name="shops"></a>

Shops unlock in two stages:

**Stage 1 — Local Shops** (ShopMenu):

| Shop | Cost | Income/sec | Rep Required |
|------|------|-----------|--------------|
| Home Garage Shop | $500 | $0.08/s | 0 |
| Main St Strip Mall | $2,500 | $0.35/s | 15 |
| Downtown Corner Shop | $8,000 | $0.90/s | 40 |
| Shopping Mall Kiosk | $18,000 | $1.80/s | 80 |
| Luxury Barbershop & Spa | $40,000 | $3.50/s | 150 |

**Stage 2 — National Chains** (NationalExpansion, unlocks at $50k + 5 shops):

| Chain | Cost | Income/sec | Locations |
|-------|------|-----------|-----------|
| Cuts R Us | $250K | $12/s | 120 |
| Fade Nation | $600K | $25/s | 280 |
| First Class Cuts | $1.5M | $55/s | 500 |
| Empire Style | $4M | $130/s | 900 |
| The Crown | $10M | $300/s | 2,000 |

---

## How Staff Works <a name="staff"></a>

- Pressing **STAFF** unlocks at $200
- 5 random candidates are shown with randomised stats (Speed 3-9, Accuracy 3-9, Charm 2-8)
- Each candidate has a `hire_cost` and `wage_per_min`
- Hiring deducts `hire_cost` immediately
- Staff wages reduce your passive income per second: `total_income = gross_shop_income - total_wages_per_sec`
- Staff are listed in the right panel after hiring
- You can reroll candidates for $20 (generates 5 new random ones)

---

## How National Expansion Works <a name="national"></a>

1. Unlock condition: **$50,000 cash** AND **5 shops owned**
2. The NATIONAL button appears on EmpireMap
3. Each of the 5 chains has a cost and reputation requirement
4. Buy chains in any order (cheapest to most expensive is the natural path)
5. An **Empire Progress Bar** (0-5) tracks how many chains you own
6. When you buy all 5, `GameManager` emits `unlock_triggered("final_tower")`
7. NationalExpansion.gd listens for this signal and auto-navigates to FinalTowerScene after 2.5 seconds

---

## How the Final Tower Scene Triggers <a name="final"></a>

```gdscript
# In GameManager.gd → check_unlocks()
_check_unlock("final_tower", get_national_chains_owned() >= 5)

# This emits: unlock_triggered("final_tower")

# In NationalExpansion.gd
func _on_unlock(unlock_name: String) -> void:
    if unlock_name == "final_tower":
        await get_tree().create_timer(2.5).timeout
        get_tree().change_scene_to_file(FINAL_SCENE)
```

The FinalTowerScene fades in, shows your full stats, plays a slow city parallax, and lets you choose to return to menu or keep playing.

---

## GameManager Variables Reference <a name="variables"></a>

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `money` | float | 50.0 | Current cash |
| `reputation` | int | 0 | Fame (0-1000) |
| `total_customers_served` | int | 0 | Lifetime customer count |
| `total_haircuts_done` | int | 0 | Lifetime completed cuts |
| `upgrades["clipper_level"]` | int | 1 | Clipper upgrade level (1-10) |
| `upgrades["speed_level"]` | int | 1 | Speed upgrade level (1-10) |
| `upgrades["accuracy_level"]` | int | 1 | Accuracy upgrade level (1-10) |
| `upgrades["patience_level"]` | int | 1 | Patience upgrade level (1-10) |
| `owned_shops` | Array[Dictionary] | [] | All purchased shops |
| `staff` | Array[Dictionary] | [] | All hired staff members |
| `game_unlocks["staff_menu"]` | bool | false | Unlocks at $200 |
| `game_unlocks["shop_menu"]` | bool | false | Unlocks at $500 + Rep 10 |
| `game_unlocks["empire_map"]` | bool | false | Unlocks on first shop buy |
| `game_unlocks["national_expansion"]` | bool | false | Unlocks at $50K + 5 shops |
| `game_unlocks["final_tower"]` | bool | false | Unlocks on owning all 5 chains |

### Signals emitted by GameManager

| Signal | When |
|--------|------|
| `money_changed(amount)` | Any time money increases or decreases |
| `reputation_changed(rep)` | Any time reputation changes |
| `shop_bought(shop_data)` | After a shop purchase succeeds |
| `staff_hired(staff_data)` | After a hire succeeds |
| `upgrade_purchased(name, level)` | After an upgrade is bought |
| `unlock_triggered(key)` | When a new feature unlocks |
| `game_saved` | After a successful save |
| `game_loaded` | After a successful load |

---

## How to Replace Placeholder Art <a name="art"></a>

All placeholder art is done with `ColorRect` and `Label` nodes. Here's how to swap them:

### Step-by-step
1. Create your sprite sheets or individual PNG files and drop them into `assets/`
2. In Godot, open a `.tscn` file in the editor
3. Select the `ColorRect` or placeholder node you want to replace
4. Delete it and add a `Sprite2D` (for world objects) or `TextureRect` (for UI) in its place
5. In the Inspector, set the `texture` property to your new PNG
6. Resize/reposition to fit

### What to replace first (priority order)
| Placeholder | Location | Replace With |
|-------------|----------|--------------|
| `CustomerHead` ColorRect | HomeShop.tscn | Animated customer sprite sheet |
| `HairRect` ColorRect | HomeShop.tscn | Hair sprite that disappears as you cut |
| Background ColorRects | All scenes | Pixel art backgrounds |
| `ChairRect` ColorRect | HomeShop.tscn | Barber chair sprite |
| City/Tower rects | FinalTowerScene.tscn | Full night-city parallax layers |

### Pixel Art Recommendations
- Resolution: 320×180 base (scales cleanly to 1280×720)
- Palette: 16-32 colours max for authentic pixel feel
- Tools: Aseprite, LibreSprite, or Pixilart

---

## Git & GitHub Setup <a name="git"></a>

### First-time setup (run in terminal inside the project folder)

```bash
# Navigate to the project folder
cd /path/to/BarbashopEmpire

# Initialize git
git init

# Add all files
git add .

# Make the first commit
git commit -m "Initial commit: Barber Empire v1.0 - complete Godot 4 project"

# Create a repository on GitHub (requires GitHub CLI)
gh repo create BarbershopEmpire --public --source=. --remote=origin --push

# Or if you made the repo manually on GitHub:
git remote add origin https://github.com/YOUR_USERNAME/BarbershopEmpire.git
git branch -M main
git push -u origin main
```

### Subsequent pushes

```bash
git add .
git commit -m "Your message here"
git push
```

---

## Project File Structure <a name="structure"></a>

```
BarbashopEmpire/
├── project.godot               ← Godot project config + autoload registration
├── icon.svg                    ← App icon
├── .gitignore                  ← Ignores .godot/ build cache
├── README.md                   ← This file
│
├── scenes/
│   ├── StartScreen.tscn        ← Main menu
│   ├── HomeShop.tscn           ← Haircut minigame + HUD
│   ├── UpgradeMenu.tscn        ← Upgrade 4 skills
│   ├── StaffMenu.tscn          ← Hire barbers
│   ├── ShopMenu.tscn           ← Buy local shops
│   ├── EmpireMap.tscn          ← Town overview map
│   ├── NationalExpansion.tscn  ← Buy national chains
│   └── FinalTowerScene.tscn    ← Victory screen
│
├── scripts/
│   ├── autoload/
│   │   ├── GameManager.gd      ← Global state, save/load, signals
│   │   ├── DialogueGenerator.gd← Random dialogue, reviews, names
│   │   └── Economy.gd          ← All math: costs, payouts, income
│   │
│   ├── StartScreen.gd
│   ├── HomeShop.gd
│   ├── UpgradeMenu.gd
│   ├── StaffMenu.gd
│   ├── ShopMenu.gd
│   ├── EmpireMap.gd
│   ├── NationalExpansion.gd
│   └── FinalTowerScene.gd
│
└── assets/
    └── placeholder/            ← Put your real art here
```

---

## Tips for Expanding the Game

- **Add sound effects**: Use `AudioStreamPlayer` nodes and connect them to GameManager signals
- **Add animations**: Replace ColorRects with AnimatedSprite2D nodes using Aseprite sheets
- **Add more upgrade tiers**: Extend `UPGRADE_BASE_COSTS` in Economy.gd and raise `MAX_LEVEL`
- **Add a prestige system**: Reset money/upgrades for a permanent multiplier bonus
- **Add achievements**: Create an `Achievements.gd` autoload that listens to GameManager signals
- **Add a daily challenge**: Use `Time.get_date_dict_from_system()` to seed daily modifiers
