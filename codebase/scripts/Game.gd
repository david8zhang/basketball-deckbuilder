class_name Game
extends Node2D

enum EnemyScoreIntent {
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
var draw_pile: Array[String] = []
var discard_pile: Array[String] = []
var curr_skill_points := 0
var curr_stamina_points := 0
var curr_defense_score := 0
var curr_phase := Phase.OFFENSE
static var BASE_SKILL_POINTS := 3
static var BASE_STAMINA_POINTS := 3
static var DRAW_PER_TURN := 5
static var STARTING_DECK_SIZE := 10

# Bonus trackers
var persist_defense := false
var card_type_to_cost_reduce_map = {}
var card_name_to_cost_reduce_map = {}
var curr_off_boost := 0
var curr_def_boost := 0
var future_skill_gain := 0
var future_stam_gain := 0
var future_off_boost := 0
var future_def_boost := 0

# Penalty trackers
var cpu_debuffs: Array[CardPenalty] = []
var future_skill_reduce := 0
var future_stam_reduce := 0
var future_draw_reduce := 0
var future_off_penalty := 0
var future_def_penalty := 0

# Enemy stats
var curr_enemy_defense_score := 0
var curr_enemy_score_intent: EnemyScoreIntent
var curr_enemy_defend_intent: EnemyDefendIntent
var next_enemy_defense_boost := 0
var curr_enemy_attack_power := 0

# Counters
var total_poss_rem := 0
var shot_clock := 0
var game_clock := 0
static var GAME_CLOCK_TICKS := 30
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
@onready var enemy_attack_intent_label = $CanvasLayer/EnemyAttack/Intent as Label
# Player Defense
@onready var player_defense_container = $CanvasLayer/PlayerDefense as VBoxContainer
@onready var player_defense_score_label = $CanvasLayer/PlayerDefense/DefenseScore as Label
@onready var skill_stamina_label = $CanvasLayer/StaminaSkill as Label
@onready var draw_amount_label = $CanvasLayer/HBoxContainer/DrawContainer/VBoxContainer/Amount as Label
@onready var discard_amount_label = $CanvasLayer/HBoxContainer/DiscardContainer/VBoxContainer/Amount as Label
@onready var shot_clock_label = $CanvasLayer/ShotClock/Value as Label
@onready var game_clock_label = $CanvasLayer/GameClock/Value as Label
@onready var scoreboard = $CanvasLayer/Scoreboard as Scoreboard
@onready var quarter_number_label = $CanvasLayer/Quarter/Value as Label

func _ready() -> void:
	init_shot_clock()
	init_game_clock()
	init_deck()
	init_enemy_defense_score()
	init_scoreboard()
	init_quarter_number()
	start_player_turn(true)

func init_scoreboard():
	scoreboard.set_scores(GameVariables.curr_player_score, GameVariables.curr_cpu_score)

func init_shot_clock():
	shot_clock = SHOT_CLOCK_TICKS
	update_shot_clock(0)
	tick_shot_clock_button.pressed.connect(tick_shot_clock)

func init_game_clock():
	game_clock = GAME_CLOCK_TICKS
	update_game_clock(0)

func reset_resource_points():
	if curr_phase == Phase.OFFENSE:
		curr_skill_points = max(0, BASE_SKILL_POINTS - future_skill_reduce + future_skill_gain)
		future_skill_reduce = 0
		future_skill_gain = 0
		skill_stamina_label.text = str(curr_skill_points) + "/" + str(BASE_SKILL_POINTS)
	elif curr_phase == Phase.DEFENSE:
		curr_stamina_points = max(0, BASE_STAMINA_POINTS - future_stam_reduce + future_stam_gain)
		future_stam_reduce = 0
		future_stam_gain = 0
		skill_stamina_label.text = str(curr_stamina_points) + "/" + str(BASE_STAMINA_POINTS)

func set_new_enemy_score_and_attack_intent():
	var should_debuff = randi_range(1, 3) == 1
	curr_enemy_score_intent = EnemyScoreIntent.values().pick_random()
	match curr_enemy_score_intent:
		EnemyScoreIntent.THREE_POINTER:
			var max_range = 5 if should_debuff else 10
			curr_enemy_attack_power = randi_range(5, max_range)
			enemy_attack_label.text = "3-Pointer"
			enemy_attack_power_label.text = str(curr_enemy_attack_power)
		EnemyScoreIntent.TWO_POINTER:
			var max_range = 10 if should_debuff else 15
			curr_enemy_attack_power = randi_range(5, max_range)
			enemy_attack_label.text = "2-Pointer"
			enemy_attack_power_label.text = str(curr_enemy_attack_power)
	if should_debuff:
		var random_penalty = generate_random_off_penalty()
		show_penalty_preview(random_penalty, enemy_attack_intent_label)
		cpu_debuffs.append(random_penalty)
	else:
		enemy_attack_intent_label.hide()

func init_enemy_defense_score():
	curr_enemy_defense_score = randi_range(5, 15)
	enemy_defense_label.text = "Defense"
	enemy_defense_score_label.text = str(curr_enemy_defense_score)

func init_quarter_number():
	quarter_number_label.text = str(GameVariables.quarter_number)

func set_new_enemy_defend_intent():
	# var enemy_intent = EnemyDefendIntent.values().pick_random()
	var enemy_intent = EnemyDefendIntent.APPLY_DEBUFF
	match enemy_intent:
		EnemyDefendIntent.DEFENSE_BOOST:
			next_enemy_defense_boost = randi_range(1, 5)
			enemy_defense_intent_label.show()
			enemy_defense_intent_label.text = "(Next: +" + str(next_enemy_defense_boost) + " Defense)"
		EnemyDefendIntent.APPLY_DEBUFF:
			var random_penalty = generate_random_def_penalty()
			show_penalty_preview(random_penalty, enemy_defense_intent_label)
			cpu_debuffs.append(random_penalty)

func generate_random_off_penalty() -> CardPenalty:
	var penalty = CardPenalty.new()
	var offensive_penalty_types = [
		CardPenalty.PenaltyType.REDUCE_DEF,
		CardPenalty.PenaltyType.FUTURE_REDUCE_STAM,
		CardPenalty.PenaltyType.REDUCE_DRAW
	]
	var penalty_type = offensive_penalty_types.pick_random()
	penalty.penalty_type = penalty_type
	match penalty_type:
		CardPenalty.PenaltyType.REDUCE_DEF:
			var amount = randi_range(1, 3)
			penalty.amount = amount
		CardPenalty.PenaltyType.REDUCE_DRAW:
			penalty.amount = randi_range(1, 4)
		CardPenalty.PenaltyType.FUTURE_REDUCE_STAM:
			penalty.amount = randi_range(1, 2)
	return penalty	

func generate_random_def_penalty() -> CardPenalty:
	var penalty = CardPenalty.new()
	var defensive_penalty_types = [
		CardPenalty.PenaltyType.REDUCE_ATK,
		CardPenalty.PenaltyType.FUTURE_REDUCE_SKILL,
		CardPenalty.PenaltyType.REDUCE_DRAW
	]
	var penalty_type = defensive_penalty_types.pick_random()
	penalty.penalty_type = penalty_type
	match penalty_type:
		CardPenalty.PenaltyType.REDUCE_ATK:
			var amount = randi_range(1, 3)
			penalty.amount = amount
		CardPenalty.PenaltyType.REDUCE_DRAW:
			penalty.amount = randi_range(1, 4)
		CardPenalty.PenaltyType.FUTURE_REDUCE_SKILL:
			penalty.amount = randi_range(1, 2)
	return penalty

func show_penalty_preview(penalty: CardPenalty, label: Label):
	label.show()
	match penalty.penalty_type:
		CardPenalty.PenaltyType.REDUCE_ATK:
			label.text = "(Next: -" + str(penalty.amount) + " Offensive card power)"
		CardPenalty.PenaltyType.REDUCE_DEF:
			label.text = "(Next: -" + str(penalty.amount) + " Defensive card power)"
		CardPenalty.PenaltyType.REDUCE_DRAW:
			label.text = "(Next: -" + str(penalty.amount) + " cards drawn)"
		CardPenalty.PenaltyType.FUTURE_REDUCE_SKILL:
			label.text = "(Next: -" + str(penalty.amount) + " skill points)"
		CardPenalty.PenaltyType.FUTURE_REDUCE_STAM:
			label.text = "(Next: -" + str(penalty.amount) + " stamina points)"			

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
	if !is_first_turn:
		discard_current_hand()
		handle_cpu_debuffs()
	var draw_amount = max(0, DRAW_PER_TURN - future_draw_reduce)
	draw_cards(draw_amount)
	reset_resource_points()
	if curr_phase == Phase.DEFENSE:
		set_new_enemy_score_and_attack_intent()
		if !persist_defense:
			persist_defense = false
			init_player_defense_score()
	else:
		set_new_enemy_defend_intent()

# CPU Debuffs only last for 1 turn (may change in the future)
func handle_cpu_debuffs():
	handle_card_penalties(cpu_debuffs)
	cpu_debuffs = []

func discard_current_hand():
	for c in player_hand.get_children():
		if is_instance_valid(c):
			var card = c as Card
			discard_pile.append(card.card_stat.card_name)
			c.queue_free()
	discard_amount_label.text = str(discard_pile.size())

func shuffle_discard_into_draw_pile():
	draw_pile.append_array(discard_pile)
	discard_pile = []
	draw_pile.shuffle()
	discard_amount_label.text = str(discard_pile.size())
	draw_amount_label.text = str(draw_pile.size())

func draw_cards(draw_amount: int):
	for i in range(0, draw_amount):
		if draw_pile.is_empty():
			shuffle_discard_into_draw_pile()
		var next_card_name = draw_pile.pop_front()
		if next_card_name != null:
			var card_stat = GameVariables.load_card_stat_from_name(next_card_name)
			assert(card_stat != null, "Card with name \"" + next_card_name + "\" does not exist!")
			var card = card_scene.instantiate() as Card
			card.card_stat = card_stat
			player_hand.add_child(card)
			card.card_button.visible = false
	draw_amount_label.text = str(draw_pile.size())
	update_all_cards()

func tick_game_clock():
	update_game_clock(-1)
	if game_clock == 0:
		handle_end_of_quarter()

func tick_shot_clock():
	tick_game_clock()
	if game_clock != 0:
		# Reset bonuses after ending current turn
		card_name_to_cost_reduce_map = {}
		card_type_to_cost_reduce_map = {}
		curr_off_boost = future_off_boost
		curr_def_boost = future_def_boost
		if shot_clock == 1:
			var on_complete = func _on_complete():
				switch_phases()
			handle_enemy_turn(on_complete)
		else:
			update_shot_clock(-1)
			var on_complete = func _on_complete():
				start_player_turn(false)
			handle_enemy_turn(on_complete)

func handle_end_of_quarter():
	get_tree().change_scene_to_file("res://scenes/QuarterEnd.tscn")

func update_shot_clock(amount: int):
	shot_clock = max(0, shot_clock + amount)
	shot_clock_label.text = str(shot_clock)

func update_game_clock(amount: int):
	game_clock = max(0, game_clock + amount)
	game_clock_label.text = str(game_clock)

func handle_enemy_turn(on_complete: Callable):
	var is_enemy_on_offense = curr_phase == Phase.DEFENSE
	if is_enemy_on_offense:
		update_player_defense(-curr_enemy_attack_power)
		if curr_defense_score < 0:
			var score_amount = 2 if curr_enemy_score_intent == EnemyScoreIntent.TWO_POINTER else 3
			scoreboard.update_cpu_score(score_amount)
			switch_phases()
		else:
			on_complete.call()
	else:
		match curr_enemy_defend_intent:
			EnemyDefendIntent.DEFENSE_BOOST:
				update_enemy_defense(next_enemy_defense_boost)
		on_complete.call()

func reset_debuffs():
	cpu_debuffs = []
	future_off_penalty = 0
	future_def_penalty = 0
	future_skill_reduce = 0
	future_stam_reduce = 0
	future_draw_reduce = 0
	
func switch_phases():
	curr_phase = Phase.DEFENSE if curr_phase == Phase.OFFENSE else Phase.OFFENSE
	# Init scores based on defense vs. offense
	if curr_phase == Phase.DEFENSE:
		enemy_defense_container.hide()
		enemy_attack_container.show()
		player_defense_container.show()
		init_player_defense_score()
		set_new_enemy_score_and_attack_intent()
	elif curr_phase == Phase.OFFENSE:
		enemy_defense_container.show()
		enemy_attack_container.hide()
		player_defense_container.hide()
		init_enemy_defense_score()
		set_new_enemy_defend_intent()
	# Clear out hand and discard pile, draw new cards
	for c in player_hand.get_children():
		c.queue_free()
	reset_debuffs()
	init_deck()
	init_shot_clock()
	update_all_cards()	
	start_player_turn(true)

func meets_requirements(requirements: Array[CardRequirement]) -> bool:
	var result := true
	for r in requirements:
		var req = r as CardRequirement
		match req.requirement_type:
			CardRequirement.ReqType.ENEMY_DEF_SCORE:
				var thres_req = req as ThresholdCardRequirement
				if !satisfies_threshold(thres_req.comparator, thres_req.threshold, curr_enemy_defense_score):
					return false
			CardRequirement.ReqType.OFF_ADV_AMOUNT:
				var thres_req = req as ThresholdCardRequirement
				if curr_enemy_defense_score < 0 and !satisfies_threshold(thres_req.comparator, thres_req.threshold, abs(curr_enemy_defense_score)):
					return false
			CardRequirement.ReqType.PLAYER_DEF_SCORE:
				var thres_req = req as ThresholdCardRequirement
				if !satisfies_threshold(thres_req.comparator, thres_req.threshold, curr_defense_score):
					return false
			CardRequirement.ReqType.ENEMY_SCORE_INTENT:
				var intent_req = req as ScoreIntentRequirement
				if intent_req.target_score_intent != curr_enemy_score_intent:
					return false
			CardRequirement.ReqType.ENEMY_DEFEND_INTENT:
				var intent_req = req as DefIntentRequirement
				if intent_req.target_defend_intent != curr_enemy_defend_intent:
					return false
			CardRequirement.ReqType.PLAYER_DEF_RELATIVE:
				var rel_req = req as RelativeDefenseCardRequirement
				if !satisfies_threshold(rel_req.comparator, curr_enemy_attack_power, curr_defense_score):
					return false
			CardRequirement.ReqType.SHOT_CLOCK:
				var sc_req = req as ShotClockRequirement
				if !satisfies_threshold(sc_req.comparator, sc_req.shot_clock_value, shot_clock):
					return false
	return result

func satisfies_threshold(comparator: CardRequirement.ReqComparator, threshold: int, value: int):
	match comparator:
		CardRequirement.ReqComparator.LESS:
			return value < threshold
		CardRequirement.ReqComparator.GREATER:
			return value > threshold
		CardRequirement.ReqComparator.EQUALS:
			return value == threshold
		CardRequirement.ReqComparator.LESS_EQUALS:
			return value <= threshold
		CardRequirement.ReqComparator.GREATER_EQUALS:
			return value >= threshold

func play_card(card: Card):
	var card_stat = card.card_stat as CardStat
	var resource = curr_skill_points if curr_phase == Phase.OFFENSE else curr_stamina_points
	var card_cost = get_card_cost(card_stat)
	if card_cost <= resource and meets_requirements(card_stat.requirements):
		match card_stat.card_type:
			CardStat.CardType.OFFENSE:
				var amount = card_stat.power + curr_off_boost + future_off_boost - future_off_penalty
				future_off_boost = 0
				future_off_penalty = 0
				update_skill_points(-card_cost)
				update_enemy_defense(-amount)
				handle_card_bonuses(card_stat.bonuses)
				handle_card_penalties(card_stat.penalties)
			CardStat.CardType.DEFENSE:
				var amount = card_stat.power + curr_def_boost + future_def_boost - future_def_penalty
				future_off_boost = 0
				future_off_penalty = 0
				update_stamina_points(-card_cost)
				update_player_defense(amount)
				handle_card_bonuses(card_stat.bonuses)
				handle_card_penalties(card_stat.penalties)
			CardStat.CardType.SHOT:
				var shot_card_stat = card_stat as ShotCardStat
				scoreboard.update_player_score(shot_card_stat.points)
				tick_game_clock()
		discard_pile.append(card_stat.card_name)
		card.queue_free()		
		discard_amount_label.text = str(discard_pile.size())
		if game_clock != 0 and card_stat.card_type == CardStat.CardType.SHOT or shot_clock == 0:
			switch_phases()

func get_card_cost(card_stat: CardStat):
	var cost = card_stat.cost
	if card_type_to_cost_reduce_map.has(card_stat.card_type):
		cost -= card_type_to_cost_reduce_map[card_stat.card_type]
	if card_name_to_cost_reduce_map.has(card_stat.card_name):
		cost -= card_name_to_cost_reduce_map[card_stat.card_name]
	return max(0, cost)

func handle_card_penalties(penalties: Array[CardPenalty]):
	for penalty in penalties:
		match penalty.penalty_type:
			CardPenalty.PenaltyType.REDUCE_SKILL:
				update_skill_points(-penalty.amount)
			CardPenalty.PenaltyType.REDUCE_STAM:
				update_stamina_points(-penalty.amount)
			CardPenalty.PenaltyType.REDUCE_DRAW:
				future_draw_reduce = penalty.amount
			CardPenalty.PenaltyType.REDUCE_DEF:
				update_player_defense(-penalty.amount)
			CardPenalty.PenaltyType.REDUCE_ATK:
				curr_off_boost -= penalty.amount
				update_all_cards()
			CardPenalty.PenaltyType.INCR_ENEMY_DEF:
				update_enemy_defense(penalty.amount)
			CardPenalty.PenaltyType.INCR_ENEMY_ATK:
				update_enemy_offense(penalty.amount)
			CardPenalty.PenaltyType.FUTURE_REDUCE_SKILL:
				future_skill_reduce += penalty.amount
			CardPenalty.PenaltyType.FUTURE_REDUCE_STAM:
				future_stam_reduce += penalty.amount
			CardPenalty.PenaltyType.CONCEDE_POINTS:
				scoreboard.update_cpu_score(penalty.amount)
				switch_phases()
			CardPenalty.PenaltyType.FUTURE_REDUCE_OFF_POWER:
				future_off_penalty = penalty.amount
			CardPenalty.PenaltyType.FUTURE_REDUCE_DEF_POWER:
				future_def_penalty = penalty.amount

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
				CardStatBonus.BonusType.SWITCH_PHASE:
					switch_phases()
				CardStatBonus.BonusType.REDUCE_ENEMY_OFF_POWER:
					update_enemy_offense(-bonus.bonus_amt)
				CardStatBonus.BonusType.FUTURE_OFF_BOOST:
					future_off_boost = bonus.bonus_amt
				CardStatBonus.BonusType.FUTURE_DEF_BOOST:
					future_def_boost = bonus.bonus_amt

func update_all_cards():
	for c in player_hand.get_children():
		var card = c as Card
		card.update_card()

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

func update_enemy_offense(amount: int):
	curr_enemy_attack_power = max(0, curr_enemy_attack_power + amount)
	enemy_attack_power_label.text = str(curr_enemy_attack_power)
