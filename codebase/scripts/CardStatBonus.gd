class_name CardStatBonus
extends Resource

enum BonusType {
	SKILL_REGEN,
	DRAW,
	STAMINA_REGEN,
	OFF_POWER_BOOST,
	DEF_POWER_BOOST
}

@export var bonus_type: BonusType
@export var description := ""
@export var bonus_amt := 0
