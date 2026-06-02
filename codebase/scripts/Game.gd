class_name Game
extends Node2D

enum EnemyAttackIntent {
	TWO_POINTER,
	THREE_POINTER
}

enum EnemyDefendIntent {
	DEFENSE_BOOST,
	APPLY_DEBUFF
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
static var BASE_SKILL_POINTS := 3
static var BASE_STAMINA_POINTS := 3
static var STARTING_DRAW_AMOUNT := 5
static var DRAW_PER_TURN := 2
static var STARTING_DECK_SIZE := 10

# Bonus trackers
var persist_defense := false
var card_type_to_cost_reduce_map = {}
var card_name_to_cost_reduce_map = {}

# Enemy stats
var cpu_score := 0
var curr_enemy_defense_score := 0
var curr_enemy_attack_intent: EnemyAttackIntent
var curr_enemy_defend_intent: EnemyDefendIntent
var next_enemy_defense_boost := 0
var curr_enemy_attack_power := 0

# Counters
var total_poss_rem := 0
var shot_clock := 0
static var NUM_TOTAL_POSS_IN_GAME := 20
static var SHOT_CLOCK_TICKS := 3

# UI stuff
@onready var tick_shot_clock_button = $CanvasLayer/Button as Button
@onready var player_hand = $CanvasLayer/PlayerHand/HBoxContainer as HBoxContainer
# Enemy defense
@onready var enemy_defense_container = $CanvasLayer/EnemyDefense as VBoxContainer
@onready var enemy_defense_label = $CanvasLayer/EnemyDefense/Label as Label
@onready var enemy_defense_score_label = $CanvasLayer/EnemyDefense/Score as Label
@onready var enemy_defense_intent_label = $CanvasLayer/EnemyDefense/Intent as Label
# Enemy attack
@onready var enemy_attack_container = $CanvasLayer/EnemyAttack as VBoxContainer
@onready var enemy_attack_label = $CanvasLayer/EnemyAttack/Label as Label
@onready var enemy_attack_power_label = $CanvasLayer/EnemyAttack/Value as Label
# Player Defense
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
	init_deck()
	init_enemy_defense_score()
	start_player_turn(true)

func init_shot_clock():
	shot_clock = SHOT_CLOCK_TICKS
	update_shot_clock(0)
	tick_shot_clock_button.pressed.connect(tick_shot_clock)

func reset_resource_points():
	if curr_phase == Phase.OFFENSE:
		curr_skill_points = BASE_SKILL_POINTS
		skill_stamina_label.text = str(curr_skill_points) + "/" + str(BASE_SKILL_POINTS)
	elif curr_phase == Phase.DEFENSE:
		curr_stamina_points = BASE_STAMINA_POINTS
		skill_stamina_label.text = str(curr_stamina_points) + "/" + str(BASE_STAMINA_POINTS)

func set_enemy_attack_intent():
	curr_enemy_attack_power = randi_range(5, 15)
	curr_enemy_attack_intent = EnemyAttackIntent.TWO_POINTER if randi_range(0, 1) == 0 else EnemyAttackIntent.THREE_POINTER
	enemy_attack_label.text = "2-Pointer" if curr_enemy_attack_intent == EnemyAttackIntent.TWO_POINTER else "3-Pointer"
	enemy_attack_power_label.text = str(curr_enemy_attack_power)

func init_enemy_defense_score():
	curr_enemy_defense_score = randi_range(5, 15)
	enemy_defense_label.text = "Defense"
	enemy_defense_score_label.text = str(curr_enemy_defense_score)
	set_enemy_defend_intent()

func set_enemy_defend_intent():
	var will_boost = randi_range(0, 2) == 0
	if will_boost:
		next_enemy_defense_boost = randi_range(1, 5)
		enemy_defense_intent_label.show()
		enemy_defense_intent_label.text = "(Next: +" + str(next_enemy_defense_boost) + " Defense)"
	else:
		next_enemy_defense_boost = 0
		enemy_defense_intent_label.hide()

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

func start_player_turn(is_first_turn: bool):
	if is_first_turn:
		draw_cards(STARTING_DRAW_AMOUNT)
	else:
		draw_cards(DRAW_PER_TURN)
	reset_resource_points()
	if curr_phase == Phase.DEFENSE:
		if !persist_defense:
			persist_defense = false
			init_player_defense_score()

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
	# Reset bonuses after ending current turn
	card_name_to_cost_reduce_map = {}
	card_type_to_cost_reduce_map = {}
	curr_off_boost = 0
	curr_def_boost = 0
	update_all_cards()
	if shot_clock == 1:
		switch_phases()
	else:
		update_shot_clock(-1)
		var on_complete = func _on_complete():
			start_player_turn(false)
		handle_enemy_turn(on_complete)

func update_shot_clock(amount: int):
	shot_clock = max(0, shot_clock + amount)
	shot_clock_label.text = str(shot_clock)

func handle_enemy_turn(on_complete: Callable):
	var is_enemy_on_offense = curr_phase == Phase.DEFENSE
	if is_enemy_on_offense:
		update_player_defense(-curr_enemy_attack_power)
		if curr_defense_score < 0:
			var score_amount = 2 if curr_enemy_attack_intent == EnemyAttackIntent.TWO_POINTER else 3
			update_cpu_score(score_amount)
			switch_phases()
		else:
			set_enemy_attack_intent()
			on_complete.call()
	else:
		match curr_enemy_defend_intent:
			EnemyDefendIntent.DEFENSE_BOOST:
				update_enemy_defense(next_enemy_defense_boost)
		set_enemy_defend_intent()
		on_complete.call()
	
func switch_phases():
	curr_phase = Phase.DEFENSE if curr_phase == Phase.OFFENSE else Phase.OFFENSE
	# Init scores based on defense vs. offense
	if curr_phase == Phase.DEFENSE:
		enemy_defense_container.hide()
		enemy_attack_container.show()
		player_defense_container.show()
		init_player_defense_score()
		set_enemy_attack_intent()
	elif curr_phase == Phase.OFFENSE:
		enemy_defense_container.show()
		enemy_attack_container.hide()
		player_defense_container.hide()
		init_enemy_defense_score()
		set_enemy_defend_intent()
	# Clear out hand, draw new cards
	for c in player_hand.get_children():
		c.queue_free()
	init_deck()
	init_shot_clock()
	start_player_turn(true)

func meets_requirements(requirements: Array[CardRequirement]) -> bool:
	var result := true
	for r in requirements:
		var req = r as CardRequirement
		match req.requirement_type:
			CardRequirement.ReqType.ENEMY_DEF_SCORE:
				var thres_req = req as ThresholdCardRequirement
				if !satisfies_threshold(thres_req, curr_enemy_defense_score):
					return false
			CardRequirement.ReqType.OFF_ADV_AMOUNT:
				var thres_req = req as ThresholdCardRequirement
				if curr_enemy_defense_score < 0 and !satisfies_threshold(thres_req, abs(curr_enemy_defense_score)):
					return false
			CardRequirement.ReqType.PLAYER_DEF_SCORE:
				var thres_req = req as ThresholdCardRequirement
				if !satisfies_threshold(thres_req, curr_defense_score):
					return false
			CardRequirement.ReqType.ENEMY_ATTACK_INTENT:
				var intent_req = req as AtkIntentRequirement
				if intent_req.target_attack_intent != curr_enemy_attack_intent:
					return false
			CardRequirement.ReqType.ENEMY_DEFEND_INTENT:
				var intent_req = req as DefIntentRequirement
				if intent_req.target_defend_intent != curr_enemy_defend_intent:
					return false
	return result

func satisfies_threshold(req: ThresholdCardRequirement, value: int):
	match req.comparator:
		ThresholdCardRequirement.ReqComparator.LESS:
			return value < req.threshold
		ThresholdCardRequirement.ReqComparator.GREATER:
			return value > req.threshold
		ThresholdCardRequirement.ReqComparator.EQUALS:
			return value == req.threshold
		ThresholdCardRequirement.ReqComparator.LESS_EQUALS:
			return value <= req.threshold
		ThresholdCardRequirement.ReqComparator.GREATER_EQUALS:
			return value >= req.threshold

func play_card(card: Card):
	var card_stat = card.card_stat as CardStat
	var resource = curr_skill_points if curr_phase == Phase.OFFENSE else curr_stamina_points
	var card_cost = get_card_cost(card_stat)
	if card_cost <= resource and meets_requirements(card_stat.requirements):
		match card_stat.card_type:
			CardStat.CardType.OFFENSE:
				var amount = card_stat.power + curr_off_boost
				update_enemy_defense(-amount)
				handle_card_bonuses(card_stat.bonuses)
				update_skill_points(-card_cost)
			CardStat.CardType.DEFENSE:
				var amount = card_stat.power + curr_def_boost
				update_player_defense(amount)
				handle_card_bonuses(card_stat.bonuses)
				update_stamina_points(-card_cost)
			CardStat.CardType.SHOT:
				var shot_card_stat = card_stat as ShotCardStat
				update_player_score(shot_card_stat.points)
		discard_pile.append(card_stat.card_name)
		card.queue_free()		
		discard_amount_label.text = str(discard_pile.size())
		if card_stat.card_type == CardStat.CardType.SHOT:
			switch_phases()

func get_card_cost(card_stat: CardStat):
	var cost = card_stat.cost
	if card_type_to_cost_reduce_map.has(card_stat.card_type):
		cost -= card_type_to_cost_reduce_map[card_stat.card_type]
	if card_name_to_cost_reduce_map.has(card_stat.card_name):
		cost -= card_name_to_cost_reduce_map[card_stat.card_name]
	return max(0, cost)

func handle_card_bonuses(bonuses: Array[CardStatBonus]):
	for bonus in bonuses:
		if meets_requirements(bonus.card_requirements):
			match bonus.bonus_type:
				CardStatBonus.BonusType.SKILL_REGEN:
					update_skill_points(bonus.bonus_amt)
				CardStatBonus.BonusType.STAMINA_REGEN:
					update_stamina_points(bonus.bonus_amt)
				CardStatBonus.BonusType.OFF_POWER_BOOST:
					curr_off_boost += bonus.bonus_amt
					update_all_cards()
				CardStatBonus.BonusType.DEF_POWER_BOOST:
					curr_def_boost += bonus.bonus_amt
					update_all_cards()
				CardStatBonus.BonusType.DRAW:
					draw_cards(bonus.bonus_amt)
				CardStatBonus.BonusType.PERSIST_DEF:
					persist_defense = true
				CardStatBonus.BonusType.INCR_SHOT_CLOCK:
					update_shot_clock(bonus.bonus_amt)
				CardStatBonus.BonusType.REDUCE_SPEC_CARD_COST:
					var rsc_cost_bonus = bonus as ReduceSpecificCardCostBonus
					card_name_to_cost_reduce_map[rsc_cost_bonus.card_to_match.card_name] = bonus.bonus_amt
					update_all_cards()
				CardStatBonus.BonusType.REDUCE_CARD_TYPE_COST:
					var rsc_cost_bonus = bonus as ReduceCardTypeCostBonus
					card_type_to_cost_reduce_map[rsc_cost_bonus.card_type] = bonus.bonus_amt
					update_all_cards()

func update_all_cards():
	for c in player_hand.get_children():
		var card = c as Card
		card.update_card()

func update_player_score(amount: int):
	player_score += amount
	player_score_label.text = str(player_score)

func update_cpu_score(amount: int):
	cpu_score += amount
	cpu_score_label.text = str(cpu_score)	

func update_skill_points(amount: int):
	curr_skill_points = max(0, curr_skill_points + amount)
	skill_stamina_label.text = str(curr_skill_points) + "/" + str(BASE_SKILL_POINTS)

func update_stamina_points(amount: int):
	curr_stamina_points = max(0, curr_stamina_points + amount)
	skill_stamina_label.text = str(curr_stamina_points) + "/" + str(BASE_STAMINA_POINTS)

func update_player_defense(amount: int):
	curr_defense_score = max(-1, curr_defense_score + amount)
	player_defense_score_label.text = str(curr_defense_score)

func update_enemy_defense(amount: int):
	curr_enemy_defense_score = curr_enemy_defense_score + amount
	if curr_enemy_defense_score < 0:
		enemy_defense_label.text = "Off. Advantage"
		enemy_defense_score_label.text = str(abs(curr_enemy_defense_score))
	else:
		enemy_defense_label.text = "Defense"
		enemy_defense_score_label.text = str(curr_enemy_defense_score)
