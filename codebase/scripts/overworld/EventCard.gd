class_name EventCard
extends Panel

@onready var title_label = $HBoxContainer/Title as Label
@onready var description_label = $HBoxContainer/Description as RichTextLabel
@onready var bonus_label = $HBoxContainer/Bonus as RichTextLabel
@onready var button = $Button as Button
@export var event_config: Event

signal on_pressed(config)

func _ready() -> void:
	button.pressed.connect(press_card)
	title_label.text = event_config.event_name
	description_label.text = "[i] " + event_config.event_description + "[/i]"
	if event_config is AddStatEvent:
		var add_stat_event = event_config as AddStatEvent
		bonus_label.text = "Add " + str(add_stat_event.amount) + " " + get_stat_to_add_name(add_stat_event.stat_to_add) + " on your first turn for the next " + str(add_stat_event.num_games) + " games"
	elif event_config is LoseStatEvent:
		var lose_stat_event = event_config as LoseStatEvent
		bonus_label.text = "Lose " + str(lose_stat_event.amount) + " " + get_stat_to_lose_name(lose_stat_event.stat_to_lose) + " on your first turn for the next " + str(lose_stat_event.num_games) + " games"
	elif event_config is AddCardEvent:
		var add_card_event = event_config as AddCardEvent
		var num_to_select = add_card_event.num_to_select
		var num_total = add_card_event.num_total
		var card_type = add_card_event.card_type
		bonus_label.text = "Add " + str(num_to_select) + " of " + str(num_total) + " " + get_card_type_name(card_type) + " cards to your deck"
	elif event_config is LoseCardEvent:
		var lose_card_event = event_config as LoseCardEvent
		var num_to_lose = lose_card_event.num_to_lose
		var card_type = lose_card_event.card_type
		bonus_label.text = "Lose " + str(num_to_lose) + " " + get_card_type_name(card_type) + " card(s)"

func press_card():
	on_pressed.emit(event_config)

func get_stat_to_add_name(stat_to_add: AddStatEvent.StatToAdd):
	match stat_to_add:
		AddStatEvent.StatToAdd.SKILL:
			return "skill points"
		AddStatEvent.StatToAdd.STAMINA:
			return "stamina points"
		AddStatEvent.StatToAdd.HYPE:
			return "hype"
		AddStatEvent.StatToAdd.DRAW:
			return "cards drawn"
		AddStatEvent.StatToAdd.OFF_POWER:
			return "offensive power"
		AddStatEvent.StatToAdd.DEF_POWER:
			return "defensive power"
		AddStatEvent.StatToAdd.NUM_CARD_REWARDS:
			return "card rewards"
	
func get_stat_to_lose_name(stat_to_lose: LoseStatEvent.StatToLose):
	match stat_to_lose:
		LoseStatEvent.StatToLose.SKILL:
			return "skill points"
		LoseStatEvent.StatToLose.STAMINA:
			return "stamina points"
		LoseStatEvent.StatToLose.DRAW:
			return "cards drawn"
		LoseStatEvent.StatToLose.OFF_POWER:
			return "offensive power"
		LoseStatEvent.StatToLose.DEF_POWER:
			return "defensive power"
		LoseStatEvent.StatToLose.NUM_CARD_REWARDS:
			return "card rewards"

func get_card_type_name(card_type):
	if card_type is AddCardEvent.CardType:
		match card_type:
			AddCardEvent.CardType.OFFENSE:
				return "Offensive"
			AddCardEvent.CardType.DEFENSE:
				return "Defensive"
			AddCardEvent.CardType.SHOT:
				return "Shot"
	elif card_type is LoseCardEvent.CardType:
		match card_type:
			LoseCardEvent.CardType.OFFENSE:
				return "Offensive"
			LoseCardEvent.CardType.DEFENSE:
				return "Defensive"
			LoseCardEvent.CardType.SHOT:
				return "Shot"		
