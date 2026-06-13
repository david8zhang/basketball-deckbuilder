class_name OffensivePlayAction
extends PlayAction

# Power levels are randomly generated numbers between a range
# For non-random power levels, set low = high
@export var base_power_low := 0
@export var base_power_high := 0
@export var score_intent: Game.EnemyScoreIntent
