extends Node

func evaluate(target: DrinkRecipe, served: DrinkRecipe) -> float:
	var score: float = 0.0
	var ing_accuracy = 1.0 - _ingredient_penalty(target.ingredients, served.ingredients)
	var step_accuracy = 1.0 - _step_penalty(target.required_steps, served.required_steps)
	var glass_accuracy = 1.0 if target.glass_type == served.glass_type else 0.0
	var garnish_accuracy = _garnish_accuracy(target.garnish, served.garnish)
	score += ing_accuracy * target.ingredient_weight * 100.0
	score += step_accuracy * target.step_weight * 100.0
	score += glass_accuracy * target.glass_weight * 100.0
	score += garnish_accuracy * target.garnish_weight * 100.0
	return clampf(score, 0.0, 100.0)

func _ingredient_penalty(target: Dictionary, served: Dictionary) -> float:
	var all_keys: Dictionary = {}
	for k in target: all_keys[k] = true
	for k in served: all_keys[k] = true
	var total_error: float = 0.0
	var max_possible: float = 0.0
	for ing in all_keys.keys():
		var expected: float = target.get(ing, 0.0)
		var actual: float = served.get(ing, 0.0)
		var error = maxf(0.0, abs(expected - actual) - 5.0)
		total_error += error
		max_possible += maxf(expected, actual)
	if max_possible == 0.0:
		return 0.0
	return clampf(total_error / max_possible, 0.0, 1.0)

func _step_penalty(target: Array, served: Array) -> float:
	if target.is_empty():
		return 0.0
	var penalty: float = 0.0
	for i in target. size():
		if i >= served.size():
			penalty += 1.0
		elif served[i] != target[i]:
			penalty += 0.5
	return penalty / float(target.size())

func _garnish_accuracy(target_garnish: String, served_garnish: String) -> float:
	if target_garnish == "":
		if served_garnish == "":
			return 1.0
		else:
			return 0.8
	if served_garnish == "":
		return 0.0
	if target_garnish == served_garnish:
		return 1.0
	return 0.0

func calculate_grade(score:float) -> String:
	if score >= 95: return "S"
	elif score >= 80: return "A"
	elif score >= 65: return "B"
	elif score >= 50: return "C"
	elif score >= 35: return "D"
	return "F"

func calculate_tip(base_tip: float, score: float, multiplier: float) -> float:
	var tip: float = 0.0
	if score >= 90: 
		tip = base_tip * 2.0 * multiplier
	elif score >= 70: 
		tip = base_tip * multiplier
	elif score >= 50: 
		tip = base_tip * 0.5 * multiplier
	return tip
