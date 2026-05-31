class_name CardStatBonus
extends Resource

enum BonusType {
	SKILL_REGEN,
	DRAW,
	STAMINA_REGEN,
	OFF_POWER_BOOST,
	DEF_POWER_BOOST,
	STATIC_POWER
}

# TODO: currently, all bonuses last the duration of the phase. Add bonuses that only apply for current tick
@export var card_requirements: Array[CardRequirement] = []
@export var bonus_type: BonusType
@export var bonus_amt := 0
