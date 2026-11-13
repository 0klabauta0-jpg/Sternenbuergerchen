class_name DamageModel
extends RefCounted


func resolve_hit(hit_chance: float, roll_override: float = -1.0) -> bool:
	var clamped_hit_chance: float = clampf(hit_chance, 0.0, 1.0)
	var roll: float = roll_override
	# The simulation supplies every roll. This pure resolver never advances a
	# process-global generator when an owner or a valid normalized input is absent.
	if not is_finite(hit_chance) or not is_finite(roll) or roll < 0.0 or roll > 1.0:
		return false

	roll = clampf(roll, 0.0, 1.0)
	return clamped_hit_chance > 0.0 and (clamped_hit_chance >= 1.0 or roll < clamped_hit_chance)


func resolve_damage(base_damage: int, multiplier: float = 1.0) -> int:
	var scaled_damage: float = float(base_damage) * maxf(multiplier, 0.0)
	return maxi(int(round(scaled_damage)), 0)
