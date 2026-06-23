class_name BadEvent
extends Resource

enum BadEventPenalty {
	LOSE_CARD,
	LOSE_PLAY
}

@export var event_name := ""
@export var event_icon: Texture2D
@export var num_to_lose := 0
