class_name GoodEvent
extends Event

enum EventBonusType {
	ADD_CARD,
	ADD_PLAY,
	ADD_STAT
}

@export var event_bonus_type: EventBonusType
