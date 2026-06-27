class_name AddStatEvent
extends GoodEvent

enum StatToAdd {
	SKILL,
	STAMINA,
	HYPE,
	DRAW,
	OFF_POWER,
	DEF_POWER,
	NUM_CARD_REWARDS
}

@export var stat_to_add: StatToAdd
@export var amount := 0
@export var num_games := 0
