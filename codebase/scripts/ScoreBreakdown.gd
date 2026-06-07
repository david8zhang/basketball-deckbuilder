class_name ScoreBreakdown
extends GridContainer

# Player score label
@onready var player_q1_score_label = $Player_Q1Score as Label
@onready var player_q2_score_label = $Player_Q2Score as Label
@onready var player_q3_score_label = $Player_Q3Score as Label
@onready var player_q4_score_label = $Player_Q4Score as Label
@onready var player_ot_score_label = $Player_OTScore as Label

# CPU Score label
@onready var cpu_q1_score_label = $CPU_Q1Score as Label
@onready var cpu_q2_score_label = $CPU_Q2Score as Label
@onready var cpu_q3_score_label = $CPU_Q3Score as Label
@onready var cpu_q4_score_label = $CPU_Q4Score as Label
@onready var cpu_ot_score_label = $CPU_OTScore as Label

@onready var player_score_labels = [
	player_q1_score_label,
	player_q2_score_label,
	player_q3_score_label,
	player_q4_score_label,
	player_ot_score_label
]

@onready var cpu_score_labels = [
	cpu_q1_score_label,
	cpu_q2_score_label,
	cpu_q3_score_label,
	cpu_q4_score_label,
	cpu_ot_score_label
]

func update_all_scores():
	var player_score_breakdowns = GameVariables.player_score_breakdown
	var cpu_score_breakdowns = GameVariables.cpu_score_breakdown
	for i in range(0, player_score_breakdowns.size()):
		var player_score_label = player_score_labels[i]
		player_score_label.text = str(player_score_breakdowns[i])
	for i in range(0, cpu_score_breakdowns.size()):
		var cpu_score_label = cpu_score_labels[i]
		cpu_score_label.text = str(cpu_score_breakdowns[i])
