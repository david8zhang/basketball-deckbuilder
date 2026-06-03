class_name CardRequirement
extends Resource

enum ReqComparator {
	LESS,
	GREATER,
	EQUALS,
	LESS_EQUALS,
	GREATER_EQUALS
}

enum ReqType {
	ENEMY_DEF_SCORE,
	PLAYER_DEF_SCORE,
	OFF_ADV_AMOUNT,
	ENEMY_ATTACK_INTENT,
	ENEMY_DEFEND_INTENT,
	PLAYER_DEF_RELATIVE,
	SHOT_CLOCK
}

@export var requirement_type: ReqType