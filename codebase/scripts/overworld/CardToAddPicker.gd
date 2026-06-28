class_name CardToAddPicker
extends PanelContainer

@onready var card_container = $VBoxContainer/HBoxContainer as HBoxContainer
@onready var confirm_button = $VBoxContainer/Button as Button
@export var card_scene: PackedScene
var selected_cards: Array[Card] = []
var num_to_select := 0

signal on_confirm_selections(selected_card_stats)

func _ready() -> void:
	confirm_button.pressed.connect(confirm_selections)

func confirm_selections():
	var selected_card_stats = selected_cards.map(func (c): return c.card_stat)
	on_confirm_selections.emit(selected_card_stats)
	selected_cards = []

func show_cards_to_pick_from(card_stats: Array[CardStat]):
	for c in card_container.get_children():
		c.queue_free()
	for c in card_stats:
		var c_stat = c as CardStat
		var card = card_scene.instantiate() as Card
		var cb = Callable(self, "on_select_card").bind(card)
		card.card_stat = c_stat
		card_container.add_child(card)
		card.toggle_play_button(false)
		card.card_button.pressed.connect(cb)		

func on_select_card(card: Card):
	if selected_cards.has(card):
		card.dehighlight()
		selected_cards = selected_cards.filter(func (c): return c != card)
	else:
		if selected_cards.size() == num_to_select:
			selected_cards[0].dehighlight()
			selected_cards = selected_cards.slice(1)
		card.highlight()
		selected_cards.append(card)
	if selected_cards.size() > 0:
		confirm_button.text = "Confirm"
	else:
		confirm_button.text = "Skip"

func display_card_options(add_card_event: AddCardEvent):
	show()
	var all_cards_of_type: Array[CardStat] = []
	match add_card_event.card_type:
		AddCardEvent.CardType.OFFENSE:
			all_cards_of_type = GameVariables.get_all_offensive_cards() as Array[CardStat]
		AddCardEvent.CardType.DEFENSE:
			all_cards_of_type = GameVariables.get_all_defensive_cards() as Array[CardStat]
		AddCardEvent.CardType.SHOT:
			all_cards_of_type = GameVariables.get_all_shot_cards() as Array[CardStat]
	all_cards_of_type.shuffle()
	var cards_to_pick_from = all_cards_of_type.slice(0, add_card_event.num_total)
	num_to_select = add_card_event.num_to_select
	show_cards_to_pick_from(cards_to_pick_from)
