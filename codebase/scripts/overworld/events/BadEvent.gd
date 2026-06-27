class_name BadEvent
extends Event

enum BadEventPenaltyType {
	LOSE_CARD,
	LOSE_PLAY,
	LOSE_STAT
}

@export var bad_event_penalty_type: BadEventPenaltyType
