extends Node

# Card resource file names
var off_card_file_names = [
	"AnkleBreaker",
	"Crossover",
	"Drive",
	"DriveAndKick",
	"Handles",
	"OffensiveRebound",
	"Pass",
	"PickAndRoll",
	"PumpFake",
	"PumpUpTheCrowd",
	"TripleThreat"
]
var def_card_file_names = [
	"ActiveHands",
	"Block",
	"Conditioning",
	"Deflect",
	"FastBreak",
	"HelpDefense",
	"OnBallPressure",
	"PerimeterDefense",
	"RimProtector",
	"Steal",
	"Switch",
	"IntentionalFoul"
]
var shot_card_names = [
	"3PointJumper",
	"Dunk",
	"Floater",
	"Layup",
	"MidRangeJumper"
]
var all_card_resources: Array[CardStat] = []

# CPU PlaySelector file names
var cpu_play_selector_file_names = [
	"BasicOffensive",
	"BasicDefensive",
	"BasicBalanced"
]

var quarter_number := 1

var player_score_breakdown = [0, 0, 0, 0, 0]
var cpu_score_breakdown = [0, 0, 0, 0, 0]
var curr_player_score := 0
var curr_cpu_score := 0
var num_overtimes := 0

const TakeoverBonusKey = {
	SKILL_REGEN = "SKILL_REGEN",
	STAMINA_REGEN = "STAMINA_REGEN",
	OFF_CARD_POWER = "OFF_CARD_POWER",
	DEF_CARD_POWER = "DEF_CARD_POWER"
}

var takeover_bonuses = {
	TakeoverBonusKey.SKILL_REGEN: 1,
	TakeoverBonusKey.STAMINA_REGEN: 1,
	TakeoverBonusKey.OFF_CARD_POWER: 3,
	TakeoverBonusKey.DEF_CARD_POWER: 3
}

# Manager player state
var player_manager: PlayerManager

# Manage overworld events
var overworld_manager: OverworldManager

# Bonuses or Penalties from events
var event_bonus_penalty_manager: EventBonusPenaltyManager

func _ready() -> void:
	player_manager = PlayerManager.new()
	overworld_manager = OverworldManager.new()
	event_bonus_penalty_manager = EventBonusPenaltyManager.new()
	add_child(player_manager)
	add_child(overworld_manager)
	add_child(event_bonus_penalty_manager)
	load_all_card_resources()

func load_all_card_resources():
	for cname in off_card_file_names:
		var card = load("res://resources/cards/offense/" + cname + ".tres")
		all_card_resources.append(card)
	for cname in def_card_file_names:
		var card = load("res://resources/cards/defense/" + cname + ".tres")
		all_card_resources.append(card)
	for cname in shot_card_names:
		var card = load("res://resources/cards/shot/" + cname + ".tres")
		all_card_resources.append(card)

func load_card_stat_from_name(card_name: String):
	for cres in all_card_resources:
		var card_stat = cres as CardStat
		if card_stat.card_name == card_name:
			return card_stat
	return null

func load_random_cpu_play_selector():
	var random_selector_name = cpu_play_selector_file_names.pick_random()
	return load_cpu_play_selector(random_selector_name)

func load_cpu_play_selector(selector_name):
	var selector = load("res://resources/cpu/selectors/" + selector_name + ".tres") as PlaySelector
	return selector

func get_all_offensive_cards():
	return all_card_resources.filter(func (cr: CardStat): return cr.card_type == CardStat.CardType.OFFENSE)

func get_all_defensive_cards():
	return all_card_resources.filter(func (cr: CardStat): return cr.card_type == CardStat.CardType.DEFENSE)

func get_all_shot_cards():
	return all_card_resources.filter(func (cr: CardStat): return cr.card_type == CardStat.CardType.SHOT)

func reset_scores():
	player_score_breakdown = [0, 0, 0, 0, 0]
	cpu_score_breakdown = [0, 0, 0, 0, 0]
	curr_player_score = 0
	curr_cpu_score = 0

func get_all_card_names():
	return all_card_resources.map(func (cr: CardStat): return cr.card_name)

func generate_schedule():
	overworld_manager.generate_schedule()

func get_overall_schedule():
	return overworld_manager.schedule

func get_curr_week_schedule():
	var week_num = overworld_manager.week_num
	var schedule = overworld_manager.schedule
	assert(week_num < schedule.size(), "Week number exceeds scheduled weeks size!")
	return schedule[week_num]

func increment_day_of_week():
	var curr_week = get_curr_week_schedule()
	if overworld_manager.day_num == curr_week.size():
		if overworld_manager.week_num == overworld_manager.schedule.size():
			# Handle playoff progression here
			print("Reached end of regular season!")
			return
		else:
			overworld_manager.week_num += 1
	overworld_manager.day_num = (overworld_manager.day_num + 1) % 7

func get_day_of_week():
	return overworld_manager.day_num

func get_day_event() -> OverworldManager.ScheduleDay:
	var curr_week_schedule = get_curr_week_schedule()
	return curr_week_schedule[overworld_manager.day_num] as OverworldManager.ScheduleDay

func get_player_off_deck():
	var all_off_cards: Array[String] = []
	all_off_cards.append_array(player_manager.off_deck)
	all_off_cards.append_array(player_manager.shot_deck)
	return all_off_cards

func get_player_offense_cards():
	return player_manager.off_deck

func get_player_shot_cards():
	return player_manager.shot_deck

func get_player_def_deck():
	return player_manager.def_deck as Array[String]

func select_modify_stat_event(event_config: Event):
	event_bonus_penalty_manager.select_modify_stat_event(event_config)

func get_random_team_config():
	return overworld_manager.get_random_team_config()

func get_random_good_events(num_events: int):
	return overworld_manager.get_random_good_events(num_events)

func get_random_bad_events(num_events: int):
	return overworld_manager.get_random_bad_events(num_events)

func add_card(card_stat: CardStat):
	player_manager.add_card(card_stat)

func lose_card(card_stat: CardStat):
	player_manager.lose_card(card_stat)
