# game_state.gd
extends Node

var shift_number: int = 1
var total_earnings: float = 0.0
var total_tips: float = 0.0
var customers_served_all_time: int = 0

var unlocked_ingredients: Array[String] = [
	"bourbon", "vodka", "coffee_liqueur",
	"simple_syrup", "lime_juice", "lemon_juice",
	"sugar", "sugar_cube", "angostura_bitters",
	"water", "soda_water", "cola", "ginger_beer",
	"mint_leaves", "ice", "grenadine",
	"orange_juice", "ginger_ale"
]
var unlocked_equipment: Array[String] = [
	"shaker", "jigger", "muddler",
	"bar_spoon", "mixing_glass"
]
var unlocked_customers: Array[String] = [
	"regular", "casual"
]

signal shift_advanced(new_shift_number: int)
signal unlock_gained(type: String, key: String)
#signal game_completed

func add_earnings(amount: float) -> void:
	total_earnings += amount

func add_tip(amount: float) -> void:
	total_tips += amount
	add_earnings(amount)

func increment_customers_served() -> void:
	customers_served_all_time += 1

func has_ingredient(key: String) -> bool:
	return key in unlocked_ingredients

func has_equipment(key: String) -> bool:
	return key in unlocked_equipment

func is_customer_unlocked(key: String) -> bool:
	return key in unlocked_customers

func advance_shift() -> void:
	shift_number += 1
	emit_signal("shift_advanced", shift_number)

func unlock_ingredient(key: String) -> void:
	if key not in unlocked_ingredients:
		unlocked_ingredients.append(key)
		emit_signal("unlock_gained", "ingredient", key)

func unlock_equipment(key: String) -> void:
	if key not in unlocked_equipment:
		unlocked_equipment.append(key)
		emit_signal("unlock_gained", "equipment", key)

func unlock_customer(key: String) -> void:
	if key not in unlocked_customers:
		unlocked_customers.append(key)
		emit_signal("unlock_gained", "customer", key)

func is_final_shift() -> bool:
	return shift_number >= 10

func get_current_shift_summary() -> Dictionary:
	return {
		"shift": shift_number,
		"earnings": total_earnings,
		"tips": total_tips,
		"customers_served": customers_served_all_time,
	}
