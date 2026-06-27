class_name AddCardEvent
extends GoodEvent

enum CardType {
	OFFENSE,
	DEFENSE,
	SHOT
}

@export var card_type: CardType
@export var num_to_select := 0
@export var num_total := 0
