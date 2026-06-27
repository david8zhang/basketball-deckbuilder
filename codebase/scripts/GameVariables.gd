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

var player_off_deck_card_names: Array[String] = [
	# Starting Offensive cards
	"Drive",
	"Drive",
	"Handles",
	"Handles",
	"Pick and Roll",
	"Pick and Roll",
	"Pass",
	"Pass",
	"Drive and Kick",
	"Drive and Kick",
	# Starting shot cards
	"Layup",
	"Layup",
	"Mid Range Jumper",
	"Mid Range Jumper",
	"3-Point Jumper"
]
var player_def_deck_card_names: Array[String] = [
	# Starting Defensive cards
	"Conditioning",
	"Conditioning",
	"On Ball Pressure",
	"On Ball Pressure",
	"On Ball Pressure",
	"On Ball Pressure",
	"On Ball Pressure",
	"Switch",
	"Switch",
	"Help Defense",
	"Help Defense",
	"Intentional Foul",
	"Intentional Foul",
	"Fast Break",
	"Fast Break"
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

# Manage overworld events
var overworld_manager: OverworldManager

func _ready() -> void:
	overworld_manager = OverworldManager.new()
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

func generate_player_off_deck():
	var off_cards = get_all_offensive_cards()
	var shot_cards = get_all_shot_cards()
	for i in range(0, 10):
		var rand_off_card = off_cards.pick_random() as CardStat
		player_off_deck_card_names.append(rand_off_card.card_name)
	for i in range(0, 5):
		var rand_shot_card = shot_cards.pick_random() as CardStat
		player_off_deck_card_names.append(rand_shot_card.card_name)

func generate_player_def_deck():
	var def_cards = get_all_defensive_cards()
	for i in range(0, 15):
		var rand_def_card = def_cards.pick_random() as CardStat
		player_def_deck_card_names.append(rand_def_card.card_name)

func reset_scores():
	player_score_breakdown = []
	cpu_score_breakdown = []

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
