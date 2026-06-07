class_name Scoreboard
extends HBoxContainer

@onready var player_score_label = $PlayerScore/Score as Label
@onready var cpu_score_label = $EnemyScore/Score as Label

func update_player_score(score_amt: int):
	GameVariables.curr_player_score += score_amt
	GameVariables.player_score_breakdown[GameVariables.quarter_number - 1] += score_amt
	player_score_label.text = str(GameVariables.curr_player_score)

func update_cpu_score(score_amt: int):
	GameVariables.curr_cpu_score += score_amt
	GameVariables.cpu_score_breakdown[GameVariables.quarter_number - 1] += score_amt
	cpu_score_label.text = str(GameVariables.curr_cpu_score)

func set_player_score(score: int):
	GameVariables.curr_player_score = score
	player_score_label.text = str(GameVariables.curr_player_score)

func set_cpu_score(score: int):
	GameVariables.curr_cpu_score = score
	cpu_score_label.text = str(GameVariables.curr_cpu_score)

func set_scores(new_player_score: int, new_cpu_score: int):
	set_player_score(new_player_score)
	set_cpu_score(new_cpu_score)
