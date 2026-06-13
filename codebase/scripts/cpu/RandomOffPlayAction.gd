class_name RandomOffPlayAction
extends OffensivePlayAction

enum RandomType {
	RANDOM_SCORE_INTENT,
	RANDOM_DEBUFF
}

@export var random_type: RandomType
@export var three_point_chance := 0
@export var two_point_chance := 0
