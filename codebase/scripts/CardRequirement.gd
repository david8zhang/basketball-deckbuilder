class_name CardRequirement
extends Resource

enum ReqType {
	ENEMY_DEF_SCORE,
	PLAYER_DEF_SCORE,
	OFF_ADV_AMOUNT,
}

enum ReqComparator {
	LESS,
	GREATER,
	EQUALS,
	LESS_EQUALS,
	GREATER_EQUALS
}

@export var requirement_type: ReqType
@export var comparator: ReqComparator
@export var threshold := 0
