class_name PlaySelectCondition
extends Resource

enum PlaySelectConditionType {
	SCORE_DIFF,
	GAME_CLOCK,
	PREV_PLAYER_ACTION,
	PREV_CPU_ACTION
}

enum ThresholdComparator {
	EQUALS,
	LESS_EQUALS,
	GREATER_EQUALS,
	GREATER,
	LESS
}
