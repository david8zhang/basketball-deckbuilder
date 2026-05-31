class_name Game
extends Node2D

enum EnemyScoreIntent {
	TWO_POINTER,
	THREE_POINTER
}

enum Phase {
	OFFENSE,
	DEFENSE
}

@export var card_scene: PackedScene

# Player stats
var player_score := 0
var draw_pile: Array[String] = []
var hand: Array[Card] = []
var discard_pile: Array[String] = []
var curr_skill_points := 0
var curr_stamina_points := 0
var curr_defense_score := 0
var curr_phase := Phase.OFFENSE
var curr_off_boost := 0
var curr_def_boost := 0
var curr_off_advantage := 0
static var BASE_SKILL_POINTS := 3
static var BASE_STAMINA_POINTS := 3
static var STARTING_DRAW_AMOUNT := 5
static var DRAW_PER_TURN := 2
static var STARTING_DECK_SIZE := 10

# Enemy stats
var enmey_score := 0
var curr_enemy_defense_score := 0
var curr_enemy_score_intent: EnemyScoreIntent
var curr_enemy_attack_power := 0

# Counters
var total_poss_rem := 0
var shot_clock := 0
static var NUM_TOTAL_POSS_IN_GAME := 20
static var SHOT_CLOCK_TICKS := 3

# UI stuff
@onready var tick_shot_clock_button = $CanvasLayer/Button as Button
@onready var player_hand = $CanvasLayer/PlayerHand/HBoxContainer as HBoxContainer
@onready var enemy_defense_container = $CanvasLayer/EnemyDefense as VBoxContainer
@onready var enemy_defense_label = $CanvasLayer/EnemyDefense/DefenseLabel as Label
@onready var enemy_defense_score_label = $CanvasLayer/EnemyDefense/DefenseScore as Label
@onready var player_defense_container = $CanvasLayer/PlayerDefense as VBoxContainer
@onready var player_defense_score_label = $CanvasLayer/PlayerDefense/DefenseScore as Label
@onready var skill_stamina_label = $CanvasLayer/StaminaSkill as Label
@onready var draw_amount_label = $CanvasLayer/HBoxContainer/DrawContainer/VBoxContainer/Amount as Label
@onready var discard_amount_label = $CanvasLayer/HBoxContainer/DiscardContainer/VBoxContainer/Amount as Label
@onready var shot_clock_label = $CanvasLayer/ShotClock/Value as Label
@onready var player_score_label = $CanvasLayer/Scoreboard/PlayerScore/Score as Label
@onready var cpu_score_label = $CanvasLayer/Scoreboard/EnemyScore/Score as Label

func _ready() -> void:
	init_shot_clock()
	init_resource_points()
	init_deck()
	init_enemy_defense_score()
	start_player_turn()

func init_shot_clock():
	shot_clock = SHOT_CLOCK_TICKS
	update_shot_clock(0)
	tick_shot_clock_button.pressed.connect(tick_shot_clock)

func init_resource_points():
	if curr_phase == Phase.OFFENSE:
		curr_skill_points = BASE_SKILL_POINTS
		skill_stamina_label.text = str(curr_skill_points) + "/" + str(BASE_SKILL_POINTS)
	elif curr_phase == Phase.DEFENSE:
		curr_stamina_points = BASE_STAMINA_POINTS
		skill_stamina_label.text = str(curr_stamina_points) + "/" + str(BASE_STAMINA_POINTS)

func init_enemy_defense_score():
	curr_enemy_defense_score = randi_range(10, 20)
	enemy_defense_label.text = "Defense"
	enemy_defense_score_label.text = str(curr_enemy_defense_score)

func init_player_defense_score():
	curr_defense_score = 0
	player_defense_score_label.text = str(curr_defense_score)

func init_deck():
	if GameVariables.player_off_deck.is_empty():
		GameVariables.generate_player_off_deck()
	if GameVariables.player_def_deck.is_empty():
		GameVariables.generate_player_def_deck()
	if curr_phase == Phase.OFFENSE:
		draw_pile = GameVariables.player_off_deck.duplicate()
		draw_pile.shuffle()
	elif curr_phase == Phase.DEFENSE:
		draw_pile = GameVariables.player_def_deck.duplicate()
		draw_pile.shuffle()
	discard_pile = []
	discard_amount_label.text = str(discard_pile.size())

func start_player_turn():
	draw_cards(STARTING_DRAW_AMOUNT)

func draw_cards(draw_amount: int):
	for i in range(0, draw_amount):
		var next_card_name = draw_pile.pop_front()
		if next_card_name != null:
			var card_stat = GameVariables.load_card_stat_from_name(next_card_name)
			assert(card_stat != null, "Card with name \"" + next_card_name + "\" does not exist!")
			var card = card_scene.instantiate() as Card
			card.card_stat = card_stat
			player_hand.add_child(card)
	draw_amount_label.text = str(draw_pile.size())

func tick_shot_clock():
	if shot_clock == 1:
		switch_phases()
	else:
		update_shot_clock(-1)
		var on_complete = func _on_complete():
			init_resource_points()
			draw_cards(DRAW_PER_TURN)
		handle_enemy_turn(on_complete)

func update_shot_clock(amount: int):
	shot_clock = max(0, shot_clock + amount)
	shot_clock_label.text = str(shot_clock)

func handle_enemy_turn(on_complete: Callable):
	print("Handle enemy turn here!")
	on_complete.call()
	
func switch_phases():
	curr_phase = Phase.DEFENSE if curr_phase == Phase.OFFENSE else Phase.OFFENSE
	# Init scores based on defense vs. offense
	if curr_phase == Phase.DEFENSE:
		enemy_defense_container.hide()
		player_defense_container.show()
		init_player_defense_score()
	elif curr_phase == Phase.OFFENSE:
		player_defense_container.hide()
		enemy_defense_container.show()
		init_enemy_defense_score()
	# Clear out hand, draw new cards
	for c in player_hand.get_children():
		c.queue_free()
	init_deck()
	init_shot_clock()
	init_resource_points()
	draw_cards(STARTING_DRAW_AMOUNT)

func meets_requirements(requirements: Array[CardRequirement]) -> bool:
	var result := true
	for r in requirements:
		var req = r as CardRequirement
		match req.requirement_type:
			CardRequirement.ReqType.ENEMY_DEF_SCORE:
				if !satisfies_threshold(req, curr_enemy_defense_score):
					return false
			CardRequirement.ReqType.OFF_ADV_AMOUNT:
				if !satisfies_threshold(req, curr_off_advantage):
					return false
			CardRequirement.ReqType.PLAYER_DEF_SCORE:
				if !satisfies_threshold(req, curr_defense_score):
					return false
	return result

func satisfies_threshold(req: CardRequirement, value: int):
	match req.comparator:
		CardRequirement.ReqComparator.LESS:
			return value < req.threshold
		CardRequirement.ReqComparator.GREATER:
			return value > req.threshold
		CardRequirement.ReqComparator.EQUALS:
			return value == req.threshold
		CardRequirement.ReqComparator.LESS_EQUALS:
			return value <= req.threshold
		CardRequirement.ReqComparator.GREATER_EQUALS:
			return value >= req.threshold

func play_card(card: Card):
	var card_stat = card.card_stat as CardStat
	var resource = curr_skill_points if curr_phase == Phase.OFFENSE else curr_stamina_points
	if card_stat.cost <= resource and meets_requirements(card_stat.requirements):
		match card_stat.card_type:
			CardStat.CardType.OFFENSE:
				var amount = card_stat.power + curr_off_boost
				update_enemy_defense(-amount)
				handle_card_bonuses(card_stat.bonuses)
				update_skill_points(-card_stat.cost)
			CardStat.CardType.DEFENSE:
				var amount = card_stat.power + curr_def_boost
				update_player_defense(amount)
				handle_card_bonuses(card_stat.bonuses)
				update_stamina_points(-card_stat.cost)
			CardStat.CardType.SHOT:
				var shot_card_stat = card_stat as ShotCardStat
				update_player_score(shot_card_stat.points)
		discard_pile.append(card_stat.card_name)
		card.queue_free()		
		discard_amount_label.text = str(discard_pile.size())
		if card_stat.card_type == CardStat.CardType.SHOT:
			switch_phases()

func handle_card_bonuses(bonuses: Array[CardStatBonus]):
	for bonus in bonuses:
		if meets_requirements(bonus.card_requirements):
			match bonus.bonus_type:
				CardStatBonus.BonusType.SKILL_REGEN:
					update_skill_points(bonus.bonus_amt)
				CardStatBonus.BonusType.STAMINA_REGEN:
					update_stamina_points(bonus.bonus_amount)
				CardStatBonus.BonusType.OFF_POWER_BOOST:
					curr_off_boost += bonus.bonus_amount
				CardStatBonus.BonusType.DEF_POWER_BOOST:
					curr_def_boost += bonus.bonus_amount
				CardStatBonus.BonusType.DRAW:
					draw_cards(bonus.bonus_amt)

func update_player_score(amount: int):
	player_score += amount
	player_score_label.text = str(player_score)

func update_skill_points(amount: int):
	curr_skill_points = max(0, curr_skill_points + amount)
	skill_stamina_label.text = str(curr_skill_points) + "/" + str(BASE_SKILL_POINTS)

func update_stamina_points(amount: int):
	curr_stamina_points = max(0, curr_stamina_points + amount)
	skill_stamina_label.text = str(curr_stamina_points) + "/" + str(BASE_STAMINA_POINTS)

func update_off_advantage(amount: int):
	if enemy_defense_label.text == "Defense":
		enemy_defense_label.text = "Off. Advantage"
	curr_off_advantage = max(0, curr_off_advantage + amount)
	enemy_defense_score_label.text = str(curr_off_advantage)

func update_player_defense(amount: int):
	curr_defense_score = max(0, curr_defense_score + amount)
	player_defense_score_label.text = str(curr_defense_score)

func update_enemy_defense(amount: int):
	if curr_enemy_defense_score + amount < 0:
		var off_adv_amount = abs(curr_enemy_defense_score + amount)
		curr_enemy_defense_score = 0
		update_off_advantage(off_adv_amount)
	else:
		curr_enemy_defense_score = max(0, curr_enemy_defense_score + amount)
		enemy_defense_score_label.text = str(curr_enemy_defense_score)
