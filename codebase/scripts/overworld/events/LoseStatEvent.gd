class_name LoseStatEvent
extends BadEvent

enum StatToLose {
	SKILL,
	STAMINA,
	DRAW,
	OFF_POWER,
	DEF_POWER,
	NUM_CARD_REWARDS
}

@export var stat_to_lose: StatToLose
@export var amount := 0
@export var num_games := 0
