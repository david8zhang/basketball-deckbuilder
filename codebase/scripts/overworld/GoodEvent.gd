class_name GoodEvent
extends Resource

enum EventBonusType {
	ADD_OFF_CARD,
	ADD_DEF_CARD,
	ADD_PLAY
}

@export var event_name := ""
@export var event_icon: Texture2D
@export var num_to_select := 0
@export var num_total := 0
