class_name CardPenalty
extends Resource

enum PenaltyType {
	REDUCE_SKILL,
	REDUCE_STAM,
	REDUCE_DRAW,
	REDUCE_DEF,
	REDUCE_ATK,
	INCR_ENEMY_DEF,
	INCR_ENEMY_ATK,
	FUTURE_REDUCE_SKILL,
	FUTURE_REDUCE_STAM,
	CONCEDE_POINTS
}

@export var penalty_type: PenaltyType
@export var amount := 0
