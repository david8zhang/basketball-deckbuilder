class_name Card
extends Control

@onready var game = get_node("/root/Game") as Game
@onready var cost_label = $Cost as Label
@onready var name_label = $PanelContainer/HBoxContainer/Name as Label
@onready var description_label = $PanelContainer/HBoxContainer/Description as RichTextLabel
@onready var play_button = $PanelContainer/Play as Button
@export var card_stat: CardStat

func _ready() -> void:
	cost_label.text = str(card_stat.cost)
	name_label.text = card_stat.card_name
	description_label.text = card_stat.card_description.replace("{power}", str(card_stat.power))
	play_button.pressed.connect(play_card)

func play_card():
	if game != null:
		game.play_card(self)

func update_power(new_power: int):
	description_label.text.replace("{power}", str(new_power))
