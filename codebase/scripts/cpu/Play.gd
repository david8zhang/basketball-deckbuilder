class_name Play
extends Resource

enum PlayType {
	OFFENSE,
	DEFENSE
}

@export var play_actions: Array[PlayAction] = []