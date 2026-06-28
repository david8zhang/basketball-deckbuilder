class_name QuarterEnd
extends Node2D

@export var card_scene: PackedScene
@onready var card_reward_container = $CanvasLayer/HBoxContainer as HBoxContainer
@onready var scoreboard = $CanvasLayer/Scoreboard as Scoreboard
@onready var end_of_quarter_label = $CanvasLayer/EndOfQuarter as Label
@onready var score_breakdown = $CanvasLayer/ScoreBreakdown as ScoreBreakdown
@onready var skip_button = $CanvasLayer/Skip as Button

static var NUM_REWARDS_BASE = 3

func _ready() -> void:
	var quarter = GameVariables.quarter_number
	scoreboard.set_scores(GameVariables.curr_player_score, GameVariables.curr_cpu_score)
	if quarter >= 4:
		handle_end_of_game_result()
	else:
		end_of_quarter_label.text = "End of Q" + str(quarter)
		var player_quarter_score = GameVariables.player_score_breakdown[quarter - 1]
		var cpu_quarter_score = GameVariables.cpu_score_breakdown[quarter - 1]
		init_card_rewards(player_quarter_score, cpu_quarter_score)
	skip_button.pressed.connect(on_continue)
	score_breakdown.update_all_scores()

func handle_end_of_game_result():
	if GameVariables.curr_player_score == GameVariables.curr_cpu_score:
		var quarter_suffix = "OT " + str(GameVariables.num_overtimes) if GameVariables.num_overtimes > 0 else "Reg."
		end_of_quarter_label.text = "End of " + quarter_suffix
	else:
		end_of_quarter_label.text = "Final"
		# TODO: Grant special card rewards for winning game
		init_card_rewards(GameVariables.curr_player_score, GameVariables.curr_cpu_score)

func init_card_rewards(player_score: int, cpu_score: int):
	var num_rewards = NUM_REWARDS_BASE
	if player_score > cpu_score:
		num_rewards += 1
	var all_cards = GameVariables.get_all_card_names()
	all_cards.shuffle()
	for i in range(0, num_rewards):
		var c = card_scene.instantiate() as Card
		c.card_stat = GameVariables.load_card_stat_from_name(all_cards[i])
		var cb = Callable(self, "on_select_reward").bind(c)
		card_reward_container.add_child(c)
		c.toggle_play_button(false)
		c.card_button.pressed.connect(cb)
	
func on_select_reward(c: Card):
	GameVariables.add_card(c.card_stat)
	on_continue()

func on_continue():
	if GameVariables.quarter_number < 4:
		GameVariables.quarter_number += 1
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
	else:
		if GameVariables.curr_player_score == GameVariables.curr_cpu_score:
			GameVariables.num_overtimes += 1
			GameVariables.quarter_number = 4
			get_tree().change_scene_to_file("res://scenes/Game.tscn")
		else:
			GameVariables.quarter_number = 1
			GameVariables.reset_scores()
			get_tree().change_scene_to_file("res://scenes/Overworld.tscn")
