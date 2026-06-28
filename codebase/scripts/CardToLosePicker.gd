class_name CardToLosePicker
extends PanelContainer

@onready var card_container = $VBoxContainer/ScrollContainer/HFlowContainer as HFlowContainer
@onready var confirm_button = $VBoxContainer/Button as Button
@export var card_scene: PackedScene

var selected_cards = []
var num_to_select := 0

signal on_confirm_selections(selected_card_stats)

func _ready() -> void:
	confirm_button.hide()
	confirm_button.pressed.connect(confirm_selections)

func confirm_selections():
	var selected_card_stats = selected_cards.map(func (c): return c.card_stat)
	on_confirm_selections.emit(selected_card_stats)
	selected_cards = []

func show_cards_to_pick_from(card_stats: Array):
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
		confirm_button.show()
		confirm_button.text = "Confirm"
	else:
		confirm_button.hide()	

func handle_lose_card_event(lose_card_event: LoseCardEvent):
	show()
	var all_card_names_of_type: Array[String] = []
	num_to_select = lose_card_event.num_to_lose
	match lose_card_event.card_type:
		LoseCardEvent.CardType.OFFENSE:
			all_card_names_of_type = GameVariables.get_player_offense_cards()
		LoseCardEvent.CardType.DEFENSE:
			all_card_names_of_type = GameVariables.get_player_def_deck()
		LoseCardEvent.CardType.SHOT:
			all_card_names_of_type = GameVariables.get_player_shot_cards()
	var all_cards_of_type = all_card_names_of_type.map(func (cname): return GameVariables.load_card_stat_from_name(cname))
	show_cards_to_pick_from(all_cards_of_type)
