class_name RunSymbolizer
extends RefCounted

# Wordle-style emoji grid representing run outcomes per floor

const FLOOR_CLEAR := "🟩"
const FLOOR_DEATH := "🟥"
const FLOOR_SKIP := "⬛"
const FLOOR_VICTORY := "🟨"

const CLASS_ICONS := {
	"warrior": "⚔️",
	"rogue": "🗡️",
	"mage": "🔮",
}


static func symbolize(card: ShareCardData) -> String:
	var lines: Array[String] = []

	# Header
	lines.append("Snap Dungeon #%d" % _day_number(card.daily_seed))

	# Class + Score
	var icon: String = CLASS_ICONS.get(card.player_class, "⚔️")
	lines.append("%s Score: %d" % [icon, card.score])

	# Floor grid
	var floor_line := ""
	for i: int in range(Constants.MAX_FLOORS):
		if i < card.floor_reached - 1:
			floor_line += FLOOR_CLEAR
		elif i == card.floor_reached - 1:
			if card.victory:
				floor_line += FLOOR_VICTORY
			else:
				floor_line += FLOOR_DEATH
		else:
			floor_line += FLOOR_SKIP
	lines.append(floor_line)

	# Stats line
	lines.append("F%d | T%d | K%d" % [card.floor_reached, card.turns_taken, card.kills])

	# Streak
	if card.streak_days > 1:
		lines.append("🔥 %d day streak" % card.streak_days)

	return "\n".join(lines)


static func _day_number(seed_value: int) -> int:
	# Simple mapping from seed to a display number
	return absi(seed_value) % 10000
