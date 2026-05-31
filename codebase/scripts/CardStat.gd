class_name CardStat
extends Resource

enum CardType {
	OFFENSE,
	DEFENSE,
	SHOT
}

@export var card_type: CardType
@export var card_name := ""
@export var cost := 0
@export var power := 0
@export var bonuses := []