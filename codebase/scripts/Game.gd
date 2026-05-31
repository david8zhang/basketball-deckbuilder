class_name Game
extends Node2D

enum EnemyScoreIntent {
	TWO_POINTER,
	THREE_POINTER
}

# Current player hand
var draw_pile = []
var hand = []
var discard_pile = []

# Counters
var total_poss_rem := 0
var shot_clock := 0
static var NUM_TOTAL_POSS_IN_GAME := 20
static var SHOT_CLOCK_TICKS := 3

# UI stuff
@onready var tick_shot_clock_button = $CanvasLayer/Button as Button
@onready var player_hand = $CanvasLayer/PlayerHand as HBoxContainer
@onready var enemy_defense_score = $CanvasLayer/EnemyDefense/DefenseLabel as Label
@onready var player_defense_score = $CanvasLayer/PlayerDefense/DefenseLabel as Label

# Enemy stats
var defense_score := 0
var curr_enemy_score_intent: EnemyScoreIntent
var curr_enemy_attack_power := 0

func _ready() -> void:
	init_deck()
	start_player_turn()
	tick_shot_clock_button.pressed.connect(end_player_turn)

func init_deck():
	pass

func start_player_turn():
	draw_cards()

func draw_cards():
	pass

func end_player_turn():
	pass
