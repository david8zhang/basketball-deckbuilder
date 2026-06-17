class_name Game
extends Node2D

enum EnemyScoreIntent {
	NONE,
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
var curr_hype_points := 0
var curr_skill_points := 0
var curr_stamina_points := 0
var curr_defense_score := 0
var curr_phase := Phase.OFFENSE
var is_takeover_mode := false
var takeover_turns_remaining := 0
static var BASE_SKILL_POINTS := 3
static var BASE_STAMINA_POINTS := 3
static var DRAW_PER_TURN := 5
static var STARTING_DECK_SIZE := 10
static var TAKEOVER_HYPE_THRESHOLD = 20
static var TAKEOVER_TURN_DURATION = 3

# Bonus trackers
var switch_phase_after_card := false
var card_type_to_cost_reduce_map = {}
var card_name_to_cost_reduce_map = {}
var curr_off_boost := 0
var curr_def_boost := 0
var future_skill_gain := 0
var future_stam_gain := 0
var future_off_boost := 0
var future_def_boost := 0
var future_shot_clock_gain := 0

# Penalty trackers
var future_skill_reduce := 0
var future_stam_reduce := 0
var future_draw_reduce := 0
var future_off_penalty := 0
var future_def_penalty := 0

# Counters
var total_poss_rem := 0
var shot_clock := 0
var game_clock := 0
static var GAME_CLOCK_TICKS := 20
static var SHOT_CLOCK_TICKS := 3

@onready var cpu_handler = $CPUHandler as CPUHandler

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
# Player labels
@onready var player_defense_container = $CanvasLayer/PlayerDefense as VBoxContainer
@onready var player_defense_score_label = $CanvasLayer/PlayerDefense/DefenseScore as Label
@onready var skill_stamina_label = $CanvasLayer/StaminaSkill as Label
@onready var draw_amount_label = $CanvasLayer/HBoxContainer/DrawContainer/VBoxContainer/Amount as Label
@onready var discard_amount_label = $CanvasLayer/HBoxContainer/DiscardContainer/VBoxContainer/Amount as Label
@onready var hype_meter_label = $CanvasLayer/HypeMeter as Label
# Game labels
@onready var shot_clock_label = $CanvasLayer/ShotClock/Value as Label
@onready var game_clock_label = $CanvasLayer/GameClock/Value as Label
@onready var scoreboard = $CanvasLayer/Scoreboard as Scoreboard
@onready var quarter_number_label = $CanvasLayer/Quarter/Value as Label

func _ready() -> void:
	init_shot_clock()
	init_game_clock()
	init_deck()
	cpu_handler.init_enemy_def_play_and_score()
	init_scoreboard()
	init_quarter_number()
	start_player_turn(true)
	print(GameVariables.takeover_bonuses)

func init_scoreboard():
	scoreboard.set_scores(GameVariables.curr_player_score, GameVariables.curr_cpu_score)

func init_shot_clock():
	shot_clock = SHOT_CLOCK_TICKS + future_shot_clock_gain
	future_shot_clock_gain = 0
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

func get_skill_points():
	var skill_points = BASE_SKILL_POINTS
	skill_points -= future_skill_reduce
	skill_points += future_skill_gain
	if is_takeover_mode:
		skill_points += GameVariables.takeover_bonuses[GameVariables.TakeoverBonusKey.SKILL_REGEN]
	return max(0, skill_points)

func get_stamina_points():
	var stamina_points = BASE_STAMINA_POINTS
	stamina_points -= future_stam_reduce
	stamina_points += future_stam_gain
	if is_takeover_mode:
		stamina_points += GameVariables.takeover_bonuses[GameVariables.TakeoverBonusKey.STAM_REGEN]
	return max(0, stamina_points)

func decrement_takeover_mode():
	takeover_turns_remaining = max(0, takeover_turns_remaining - 1)
	if takeover_turns_remaining == 0:
		is_takeover_mode = false
		hype_meter_label.text = "Hype: " + str(curr_hype_points) + " / " + str(TAKEOVER_HYPE_THRESHOLD)

func init_enemy_defense_score():
	cpu_handler.curr_enemy_defense_score = randi_range(5, 15)
	enemy_defense_label.text = "Defense"
	enemy_defense_score_label.text = str(cpu_handler.curr_enemy_defense_score)

func init_quarter_number():
	quarter_number_label.text = str(GameVariables.quarter_number)

func init_player_defense_score():
	curr_defense_score = 0
	player_defense_score_label.text = str(curr_defense_score)

func init_deck():
	if GameVariables.player_off_deck_card_names.is_empty():
		GameVariables.generate_player_off_deck()
	if GameVariables.player_def_deck_card_names.is_empty():
		GameVariables.generate_player_def_deck()
	if curr_phase == Phase.OFFENSE:
		draw_pile = GameVariables.player_off_deck_card_names.duplicate()
		draw_pile.shuffle()
	elif curr_phase == Phase.DEFENSE:
		draw_pile = GameVariables.player_def_deck_card_names.duplicate()
		draw_pile.shuffle()
	discard_pile = []
	discard_amount_label.text = str(discard_pile.size())

func start_player_turn(is_first_turn: bool):
	if !is_first_turn:
		discard_current_hand()
		cpu_handler.handle_cpu_debuffs()
	var draw_amount = max(0, DRAW_PER_TURN - future_draw_reduce)
	draw_cards(draw_amount)
	reset_resource_points()
	decrement_takeover_mode()
	if curr_phase == Phase.DEFENSE:
		cpu_handler.set_new_enemy_score_and_attack_intent()
	else:
		cpu_handler.set_new_enemy_defend_intent()

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
	card_name_to_cost_reduce_map = {}
	card_type_to_cost_reduce_map = {}
	curr_off_boost = future_off_boost
	curr_def_boost = future_def_boost
	if game_clock != 0:
		# Reset bonuses after ending current turn
		if shot_clock == 1:
			var on_complete = func _on_complete():
				switch_phases()
			cpu_handler.handle_enemy_turn(on_complete)
		else:
			update_shot_clock(-1)
			var on_complete = func _on_complete():
				start_player_turn(false)
			cpu_handler.handle_enemy_turn(on_complete)

func handle_end_of_quarter():
	get_tree().change_scene_to_file("res://scenes/QuarterEnd.tscn")

func update_shot_clock(amount: int):
	shot_clock = max(0, shot_clock + amount)
	shot_clock_label.text = str(shot_clock)

func update_game_clock(amount: int):
	game_clock = max(0, game_clock + amount)
	game_clock_label.text = str(game_clock)

func reset_debuffs():
	cpu_handler.cpu_debuffs = [] as Array[CardPenalty]
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
		cpu_handler.init_enemy_off_play()
	elif curr_phase == Phase.OFFENSE:
		enemy_defense_container.show()
		enemy_attack_container.hide()
		player_defense_container.hide()
		cpu_handler.init_enemy_def_play_and_score()
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
				if !satisfies_threshold(thres_req.comparator, thres_req.threshold, cpu_handler.curr_enemy_defense_score):
					return false
			CardRequirement.ReqType.OFF_ADV_AMOUNT:
				var thres_req = req as ThresholdCardRequirement
				var enemy_defense_score = cpu_handler.curr_enemy_defense_score
				if enemy_defense_score > 0 or !satisfies_threshold(thres_req.comparator, thres_req.threshold, abs(enemy_defense_score)):
					return false
			CardRequirement.ReqType.PLAYER_DEF_SCORE:
				var thres_req = req as ThresholdCardRequirement
				if !satisfies_threshold(thres_req.comparator, thres_req.threshold, curr_defense_score):
					return false
			CardRequirement.ReqType.ENEMY_SCORE_INTENT:
				var intent_req = req as ScoreIntentRequirement
				if intent_req.target_score_intent != cpu_handler.curr_enemy_score_intent:
					return false
			CardRequirement.ReqType.ENEMY_DEFEND_INTENT:
				var intent_req = req as DefIntentRequirement
				if intent_req.target_defend_intent != cpu_handler.curr_enemy_defend_intent:
					return false
			CardRequirement.ReqType.PLAYER_DEF_RELATIVE:
				var rel_req = req as RelativeDefenseCardRequirement
				if !satisfies_threshold(rel_req.comparator, cpu_handler.curr_enemy_attack_power, curr_defense_score):
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

func reset_off_modifiers():
	future_off_boost = 0
	future_off_penalty = 0

func reset_def_modifiers():
	future_def_boost = 0
	future_def_penalty = 0

func play_card(card: Card):
	var card_stat = card.card_stat as CardStat
	var resource = curr_skill_points if curr_phase == Phase.OFFENSE else curr_stamina_points
	var card_cost = get_card_cost(card_stat)
	if card_cost <= resource and meets_requirements(card_stat.requirements):
		match card_stat.card_type:
			CardStat.CardType.OFFENSE:
				var amount = get_card_off_power(card_stat)
				reset_off_modifiers()
				update_skill_points(-card_cost)
				cpu_handler.update_enemy_defense(-amount)
				if card_stat.bonus_after_penalty:
					handle_card_penalties(card_stat.penalties)
					handle_card_bonuses(card_stat.bonuses)
				else:
					handle_card_bonuses(card_stat.bonuses)
					handle_card_penalties(card_stat.penalties)
			CardStat.CardType.DEFENSE:
				var amount = get_card_def_power(card_stat)
				reset_def_modifiers()
				update_stamina_points(-card_cost)
				update_player_defense(amount)
				if card_stat.bonus_after_penalty:
					handle_card_penalties(card_stat.penalties)
					handle_card_bonuses(card_stat.bonuses)
				else:
					handle_card_bonuses(card_stat.bonuses)
					handle_card_penalties(card_stat.penalties)
			CardStat.CardType.SHOT:
				var shot_card_stat = card_stat as ShotCardStat
				if shot_card_stat.bonus_after_penalty:
					handle_card_penalties(shot_card_stat.penalties)
					handle_card_bonuses(shot_card_stat.bonuses)
				else:
					handle_card_bonuses(shot_card_stat.bonuses)
					handle_card_penalties(shot_card_stat.penalties)
				scoreboard.update_player_score(shot_card_stat.points)
				tick_game_clock()
		discard_pile.append(card_stat.card_name)
		card.queue_free()
		discard_amount_label.text = str(discard_pile.size())
		if game_clock != 0 and (switch_phase_after_card or card_stat.card_type == CardStat.CardType.SHOT or shot_clock == 0):
			switch_phase_after_card = false
			switch_phases()

func get_card_off_power(card_stat: CardStat):
	var final_power = card_stat.power
	final_power += curr_off_boost
	final_power += future_off_boost
	final_power -= future_off_penalty
	if is_takeover_mode:
		final_power += GameVariables.takeover_bonuses[GameVariables.TakeoverBonusKey.OFF_CARD_POWER]
	final_power = max(final_power, 0)
	return final_power

func get_card_def_power(card_stat: CardStat):
	var final_power = card_stat.power
	final_power += curr_def_boost
	final_power += future_def_boost
	final_power -= future_def_penalty
	if is_takeover_mode:
		final_power += GameVariables.takeover_bonuses[GameVariables.TakeoverBonusKey.DEF_CARD_POWER]
	final_power = max(final_power, 0)
	return final_power

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
				cpu_handler.update_enemy_defense(penalty.amount)
			CardPenalty.PenaltyType.INCR_ENEMY_ATK:
				cpu_handler.update_enemy_offense(penalty.amount)
			CardPenalty.PenaltyType.FUTURE_REDUCE_SKILL:
				future_skill_reduce += penalty.amount
			CardPenalty.PenaltyType.FUTURE_REDUCE_STAM:
				future_stam_reduce += penalty.amount
			CardPenalty.PenaltyType.CONCEDE_POINTS:
				scoreboard.update_cpu_score(penalty.amount)
				switch_phase_after_card = true
			CardPenalty.PenaltyType.FUTURE_REDUCE_OFF_POWER:
				future_off_penalty = penalty.amount
			CardPenalty.PenaltyType.FUTURE_REDUCE_DEF_POWER:
				future_def_penalty = penalty.amount
			CardPenalty.PenaltyType.INCR_SHOT_CLOCK:
				update_shot_clock(penalty.amount)

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
				CardStatBonus.BonusType.INCR_SHOT_CLOCK:
					update_shot_clock(bonus.bonus_amt)
				CardStatBonus.BonusType.REDUCE_SPEC_CARD_COST:
					var rsc_cost_bonus = bonus as ReduceSpecificCardCostBonus
					if !card_name_to_cost_reduce_map.has(rsc_cost_bonus.card_to_match.card_name):
						card_name_to_cost_reduce_map[rsc_cost_bonus.card_to_match.card_name] = bonus.bonus_amt
					else:
						card_name_to_cost_reduce_map[rsc_cost_bonus.card_to_match.card_name] += bonus.bonus_amt
					update_all_cards()
				CardStatBonus.BonusType.REDUCE_CARD_TYPE_COST:
					var rsc_cost_bonus = bonus as ReduceCardTypeCostBonus
					if !card_type_to_cost_reduce_map.has(rsc_cost_bonus.card_type):
						card_type_to_cost_reduce_map[rsc_cost_bonus.card_type] = bonus.bonus_amt
					else:
						card_type_to_cost_reduce_map[rsc_cost_bonus.card_type]= bonus.bonus_amt
					update_all_cards()
				CardStatBonus.BonusType.SWITCH_PHASE:
					switch_phase_after_card = true
				CardStatBonus.BonusType.REDUCE_ENEMY_OFF_POWER:
					cpu_handler.update_enemy_offense(-bonus.bonus_amt)
				CardStatBonus.BonusType.FUTURE_OFF_BOOST:
					future_off_boost = bonus.bonus_amt
				CardStatBonus.BonusType.FUTURE_DEF_BOOST:
					future_def_boost = bonus.bonus_amt
				CardStatBonus.BonusType.FUTURE_SKILL_GAIN:
					future_skill_gain = bonus.bonus_amt
				CardStatBonus.BonusType.FUTURE_STAMINA_GAIN:
					future_stam_gain = bonus.bonus_amt
				CardStatBonus.BonusType.FUTURE_INCR_SHOT_CLOCK:
					future_shot_clock_gain = bonus.bonus_amt
				CardStatBonus.BonusType.INCR_HYPE:
					update_hype_points(bonus.bonus_amt)

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
	curr_defense_score = curr_defense_score + amount
	player_defense_score_label.text = str(curr_defense_score)

func update_hype_points(amount: int):
	curr_hype_points = max(0, curr_hype_points + amount)
	if curr_hype_points >= TAKEOVER_HYPE_THRESHOLD:
		# Start takeover mode
		curr_hype_points = 0
		takeover_turns_remaining = TAKEOVER_TURN_DURATION
		is_takeover_mode = true
		hype_meter_label.text = "TAKEOVER! (" + str(takeover_turns_remaining) + " turns remaining)"
		update_all_cards()
	else:
		hype_meter_label.text = "Hype: " + str(curr_hype_points) + " / " + str(TAKEOVER_HYPE_THRESHOLD)
