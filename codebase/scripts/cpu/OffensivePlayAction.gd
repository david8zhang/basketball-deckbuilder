class_name OffensivePlayAction
extends PlayAction

enum PlayActionScoreIntent {
	THREE_POINTER,
	TWO_POINTER,
	NONE,
	RANDOM
}

@export var score_intent: PlayActionScoreIntent
