extends Resource
class_name DrinkRecipe

@export var recipe_key: String = ""
@export var drink_name: String = ""
@export var dialogue_key: String = ""
@export var ingredients: Dictionary = {}
# { "cognac": 30.0, "chocolate_liqueur": 30.0, "fresh_cream": 30.0 }
@export var required_steps: Array[String] = []
@export var garnish: String = ""
@export var glass_type: String = ""
@export var secondary_glass_type: String = ""
@export var ingredient_weight: float = 0.55
@export var step_weight: float = 0.25
@export var glass_weight: float = 0.10
@export var garnish_weight: float = 0.10
@export var base_tip: float = 5.0
@export var price:float = 8.0
@export var icon: Texture2D = null
@export var completed_texture: Texture2D = null
@export var description: String = ""

# --- Hint System ---
@export var flavor_hints: Array[String] = []
# Vague descriptors customer might use in dialogue
# e.g. ["creamy", "sweet", "indulgent"]

@export var mood_hints: Array[String] = []
# Emotional/situational descriptors
# e.g. ["celebrating", "after dinner", "something special"]

@export var explicit_name: bool = true
# If false, the customer never says the drink name directly
# Player has to figure it out from hints

func is_valid() -> bool:
	if recipe_key.is_empty():
		push_error("DrinkRecipe: recipe_key is empty on '%s'" % drink_name)
		return false
	if ingredients.is_empty():
		push_error("DrinkRecipe '%s': no ingredients defined" % recipe_key)
		return false
	if glass_type.is_empty():
		push_error("DrinkRecipe '%s': glass_type is empty" % recipe_key)
	var weight_sum = ingredient_weight + step_weight + glass_weight
	if not is_equal_approx(weight_sum, 1.0):
		push_error("DrinkRecipe '%s': weights sum to %.2f, must equal 1.0" % [recipe_key, weight_sum])
		return false
	return true

func get_ingredient_list() -> String:
	var parts: Array[String] = []
	for id in ingredients:
		var label = id.replace("_"," ")
		parts.append("%s %s" % [ingredients[id], label])
	return ",".join(parts)

func requires_secondary_glass() -> bool:
	return secondary_glass_type != ""
	
