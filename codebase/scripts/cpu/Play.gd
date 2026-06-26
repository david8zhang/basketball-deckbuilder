class_name Play
extends Resource

enum PlayType {
	OFFENSE,
	DEFENSE
}

@export var play_name := ""
@export var play_type: PlayType
@export var play_actions: Array[PlayAction] = []