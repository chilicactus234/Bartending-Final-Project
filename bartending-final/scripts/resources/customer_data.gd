class_name CustomerData
extends Resource

# --- Identity Stuff ---

@export var customer_key: String = ""
# ex. "regular," "proceduralist"

@export var customer_name: String = ""

@export var portrait_key: String = ""

# --- Order ---

@export var possible_orders : Array[DrinkRecipe] = []
# all drinks this customer might order

@export_enum("explicit", "vague", "regular") var order_style: String = "explicit"
# explicit = says drink name
# vague = describes drink
# regular = clues "the usual"

@export var always_orders: String = ""

# --- Behavior Figures ---
@export var patience: float = 30.0
# Seconds before customer leaves unhappy
@export var tip_multiplier: float = 1.0
# higher number for more generous tippers
@export var tip_currency: String = "cash"
# cash for humans, crypto for robots
# earnings calculation is the same
@export var walk_speed: float = 80.0
# pixels per second
@export var unlock_shift: int = 1
# which shift this customer first appears
# ShiftManager will filter spawn pool by this number
@export var personality_notes: String = ""
# optional does not show in game
@export var accepts_multiple_attempts: bool = false
# --- Dialogue Stuff ---
@export var greeting_key: String = ""
# played when customer first sits down
# ex. "michael_greeting"
@export var satisfied_key: String = ""
# dialogue for good drink score
@export var disappointed_key: String = ""

@export var leaving_angry_key: String = ""

# --- Visuals --- 
@export var walk_animation: String = "walk"

@export var idle_animation: String = "idle"

@export var thought_bubble_icon: Texture2D = null

# --- Spawning ---
@export var spawn_weight: float = 1.0
# probability of customer being chosen by ShiftManager
# good for ensuring regulars appear more frequently
@export var can_spawn_multiple: bool = false

@export var required_quest_key: String = ""
# ex: "spike bobs drink" -> bob only shows up on that quest shift
