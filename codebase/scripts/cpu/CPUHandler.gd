class_name CPUHandler
extends Node

@onready var game = get_node("/root/Game") as Game

var play_selector: PlaySelector
var cpu_debuffs: Array[CardPenalty] = []

# Enemy stats
var curr_enemy_defense_score := 0
var curr_enemy_score_intent: Game.EnemyScoreIntent
var curr_enemy_defend_intent: Game.EnemyDefendIntent
var next_enemy_defense_boost := 0
var curr_enemy_attack_power := 0

var curr_play: Play
var play_action_index := 0

func _ready() -> void:
	play_selector = GameVariables.load_random_cpu_play_selector()

func handle_cpu_debuffs():
	game.handle_card_penalties(cpu_debuffs)
	cpu_debuffs = []

func init_enemy_off_play():
	play_action_index = 0
	curr_play = play_selector.default_off_plays.pick_random() as Play
	print(curr_play.resource_path)

func set_new_enemy_score_and_attack_intent():
	play_action_index = play_action_index % curr_play.play_actions.size()
	var play_action = curr_play.play_actions[play_action_index] as OffensivePlayAction
	play_action_index += 1
	curr_enemy_attack_power = randi_range(play_action.base_power_low, play_action.base_power_high)
	if play_action is RandomOffPlayAction:
		var rand_pa = play_action as RandomOffPlayAction
		match rand_pa.random_type:
			RandomOffPlayAction.RandomType.RANDOM_SCORE_INTENT:
				var is_three = randi_range(1, 100) < rand_pa.three_point_chance
				curr_enemy_score_intent = Game.EnemyScoreIntent.THREE_POINTER if is_three else Game.EnemyScoreIntent.TWO_POINTER
				game.enemy_attack_intent_label.hide()
			RandomOffPlayAction.RandomType.RANDOM_DEBUFF:
				var random_debuff = play_action.debuffs.pick_random() as CardPenalty
				show_penalty_preview(random_debuff, game.enemy_attack_intent_label)
				curr_enemy_score_intent = Game.EnemyScoreIntent.NONE
				cpu_debuffs.append(random_debuff)
	else:
		curr_enemy_score_intent = play_action.score_intent
		if !play_action.debuffs.is_empty():
			var debuff = play_action.debuffs[0]
			show_penalty_preview(debuff, game.enemy_attack_intent_label)
			cpu_debuffs.append(debuff)
		else:
			game.enemy_attack_intent_label.hide()
	update_enemy_attack_label()
	update_enemy_attack_power_label()

func update_enemy_attack_label():
	match curr_enemy_score_intent:
		Game.EnemyScoreIntent.THREE_POINTER:
			game.enemy_attack_label.show()
			game.enemy_attack_label.text = "3-Pointer"
		Game.EnemyScoreIntent.TWO_POINTER:
			game.enemy_attack_label.show()
			game.enemy_attack_label.text = "2-Pointer"
		Game.EnemyScoreIntent.NONE:
			game.enemy_attack_label.hide()

func update_enemy_attack_power_label():
	game.enemy_attack_power_label.text = str(curr_enemy_attack_power)

func init_enemy_def_play_and_score():
	play_action_index = 0
	curr_play = play_selector.default_def_plays.pick_random() as DefensivePlay
	curr_enemy_defense_score = randi_range(curr_play.starting_def_low, curr_play.starting_def_high)	
	update_enemy_defense_score()
	print(curr_play.resource_path)

func set_new_enemy_defend_intent():
	play_action_index = play_action_index % curr_play.play_actions.size()	
	var play_action = curr_play.play_actions[play_action_index] as DefensivePlayAction
	play_action_index += 1
	if play_action is BoostDefensePlayAction:
		var boost_action = play_action as BoostDefensePlayAction
		next_enemy_defense_boost = randi_range(boost_action.boost_amount_low, boost_action.boost_amount_high)
		game.enemy_defense_intent_label.show()
		game.enemy_defense_intent_label.text = "(Next: +" + str(next_enemy_defense_boost) + " Defense)"
	elif play_action is ApplyDebuffDefensePlayAction:
		var debuff_action = play_action as ApplyDebuffDefensePlayAction
		var debuff: CardPenalty
		if debuff_action.random_select:
			debuff = play_action.debuffs.pick_random()
		else:
			debuff = play_action.debuffs[0]
		show_penalty_preview(debuff, game.enemy_defense_intent_label)
		cpu_debuffs.append(debuff)
	update_enemy_defense_score()

func update_enemy_defense_score():
	game.enemy_defense_label.text = "Defense"
	game.enemy_defense_score_label.text = str(curr_enemy_defense_score)

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

func update_enemy_defense(amount: int):
	curr_enemy_defense_score = curr_enemy_defense_score + amount
	if curr_enemy_defense_score < 0:
		game.enemy_defense_label.text = "Off. Advantage"
		game.enemy_defense_score_label.text = str(abs(curr_enemy_defense_score))
	else:
		game.enemy_defense_label.text = "Defense"
		game.enemy_defense_score_label.text = str(curr_enemy_defense_score)

func update_enemy_offense(amount: int):
	curr_enemy_attack_power = max(0, curr_enemy_attack_power + amount)
	game.enemy_attack_power_label.text = str(curr_enemy_attack_power)

func handle_enemy_defend_intent(cb: Callable):
	if curr_enemy_defend_intent == Game.EnemyDefendIntent.DEFENSE_BOOST:
		update_enemy_defense(next_enemy_defense_boost)
		next_enemy_defense_boost = 0
	cb.call()

func handle_enemy_score_intent(cb: Callable):
	match curr_enemy_score_intent:
		Game.EnemyScoreIntent.TWO_POINTER:
			game.scoreboard.update_cpu_score(2)
			game.switch_phases()
		Game.EnemyScoreIntent.THREE_POINTER:
			game.scoreboard.update_cpu_score(3)
			game.switch_phases()
		Game.EnemyScoreIntent.NONE:
			cb.call()

func handle_enemy_turn(on_complete: Callable):
	var is_enemy_on_offense = game.curr_phase == Game.Phase.DEFENSE
	if is_enemy_on_offense:
		game.update_player_defense(-curr_enemy_attack_power)
		if game.curr_defense_score < 0:
			handle_enemy_score_intent(on_complete)
		else:
			on_complete.call()
	else:
		handle_enemy_defend_intent(on_complete)
