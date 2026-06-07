class_name Card
extends Control

@onready var game = get_node("/root/Game") as Game
@onready var cost_label = $Cost as Label
@onready var name_label = $PanelContainer/HBoxContainer/Name as Label
@onready var description_label = $PanelContainer/HBoxContainer/Description as RichTextLabel
@onready var play_button = $PanelContainer/Play as Button
@onready var card_button = $Button as Button
@export var card_stat: CardStat

func _ready() -> void:
	cost_label.text = str(card_stat.cost)
	name_label.text = card_stat.card_name
	description_label.text = card_stat.card_description.replace("{power}", str(card_stat.power))
	play_button.pressed.connect(play_card)

func toggle_play_button(should_show: bool):
	play_button.visible = should_show

func play_card():
	if game != null:
		game.play_card(self)

func update_card():
	apply_off_boost()
	apply_def_boost()
	apply_cost_reduce()

func apply_off_boost():
	if card_stat.card_type == CardStat.CardType.OFFENSE:
		if game.curr_off_boost != 0:
			var new_power = max(0, card_stat.power + game.curr_off_boost)
			var color = "red" if new_power < card_stat.power else "green"
			description_label.text = card_stat.card_description.replace("{power}", "[color=" + color + "]" + str(new_power) + "[/color]")
		else:
			description_label.text = card_stat.card_description.replace("{power}", str(card_stat.power))

func apply_def_boost():
	if card_stat.card_type == CardStat.CardType.DEFENSE:
		if game.curr_def_boost != 0:
			var new_power = max(0, card_stat.power + game.curr_def_boost)
			var color = "red" if new_power < card_stat.power else "green"
			description_label.text = card_stat.card_description.replace("{power}", "[color=" + color + "]" + str(new_power) + "[/color]")
		else:
			description_label.text = card_stat.card_description.replace("{power}", str(card_stat.power))

func apply_cost_reduce():
	cost_label.text = str(game.get_card_cost(card_stat))
