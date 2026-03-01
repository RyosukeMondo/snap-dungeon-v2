class_name BattlePassData
extends Resource


const MAX_TIER := 30

@export var current_tier: int = 0
@export var xp: int = 0
@export var is_premium: bool = false
@export var month_id: String = ""  # "2026-03"

const XP_PER_TIER := 100


static func create_for_month(month_str: String) -> BattlePassData:
	var bp := BattlePassData.new()
	bp.month_id = month_str
	return bp


func add_xp(amount: int) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	xp += amount
	while xp >= XP_PER_TIER and current_tier < MAX_TIER:
		xp -= XP_PER_TIER
		current_tier += 1
		var reward := get_tier_reward(current_tier)
		if reward.size() > 0:
			rewards.append(reward)
	return rewards


func get_tier_reward(tier: int) -> Dictionary:
	# Free rewards every 3 tiers, premium every tier
	var reward: Dictionary = {}
	if tier % 3 == 0:
		reward["free"] = {"type": "gems", "amount": tier * 2}
	if is_premium:
		match tier % 5:
			0: reward["premium"] = {"type": "gems", "amount": tier * 5}
			1: reward["premium"] = {"type": "class_unlock", "class": "rogue"}
			2: reward["premium"] = {"type": "gems", "amount": tier * 3}
			3: reward["premium"] = {"type": "gear_crate", "rarity": "uncommon"}
			4: reward["premium"] = {"type": "gems", "amount": tier * 2}
	return reward
