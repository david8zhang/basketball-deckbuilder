class_name LoseCardEvent
extends BadEvent

enum CardType {
	OFFENSE,
	DEFENSE,
	SHOT
}

@export var card_type: CardType
@export var num_to_lose := 0