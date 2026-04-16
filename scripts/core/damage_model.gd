class_name DamageModel
extends RefCounted


func resolve_hit(hit_chance: float, roll_override: float = -1.0) -> bool:
	var clamped_hit_chance: float = clampf(hit_chance, 0.0, 1.0)
	var roll: float = roll_override
	if roll < 0.0:
		roll = randf()

	roll = clampf(roll, 0.0, 1.0)
	return roll <= clamped_hit_chance


func resolve_damage(base_damage: int, multiplier: float = 1.0) -> int:
	var scaled_damage: float = float(base_damage) * maxf(multiplier, 0.0)
	return maxi(int(round(scaled_damage)), 0)
