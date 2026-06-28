class_name Card
extends Control

@onready var game = get_node("/root/Game") as Game
@onready var card_panel = $PanelContainer as PanelContainer
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
		var base_power = card_stat.power
		var power_with_modifiers = game.get_card_off_power(card_stat)
		if base_power != power_with_modifiers:
			var color = "red" if power_with_modifiers < base_power else "green"
			description_label.text = card_stat.card_description.replace("{power}", "[color=" + color + "]" + str(power_with_modifiers) + "[/color]")
		else:
			description_label.text = card_stat.card_description.replace("{power}", str(base_power))

func apply_def_boost():
	if card_stat.card_type == CardStat.CardType.DEFENSE:
		var base_power = card_stat.power
		var power_with_modifiers = game.get_card_def_power(card_stat)
		if power_with_modifiers != base_power:
			var color = "red" if power_with_modifiers < base_power else "green"
			description_label.text = card_stat.card_description.replace("{power}", "[color=" + color + "]" + str(power_with_modifiers) + "[/color]")
		else:
			description_label.text = card_stat.card_description.replace("{power}", str(base_power))

func apply_cost_reduce():
	cost_label.text = str(game.get_card_cost(card_stat))

func highlight():
	var stylebox = card_panel.get_theme_stylebox("panel") as StyleBoxFlat
	stylebox.border_color.a = 1

func dehighlight():
	var stylebox = card_panel.get_theme_stylebox("panel") as StyleBoxFlat
	stylebox.border_color.a = 0
