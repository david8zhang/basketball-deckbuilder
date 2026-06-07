extends Node

var off_card_names = [
	"AnkleBreaker",
	"Crossover",
	"Drive",
	"DriveAndKick",
	"Handles",
	"OffensiveRebound",
	"Pass",
	"PickAndRoll",
	"PumpFake",
	"TripleThreat",
]
var def_card_names = [
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
	"Switch"
]
var shot_card_names = [
	"3PointJumper",
	"Dunk",
	"Floater",
	"Layup",
	"MidRangeJumper"
]
var all_card_resources: Array[CardStat] = []

var player_off_deck: Array[String] = []
var player_def_deck: Array[String] = []
var quarter_number := 1

var player_score_breakdown = [0, 0, 0, 0, 0]
var cpu_score_breakdown = [0, 0, 0, 0, 0]
var curr_player_score := 0
var curr_cpu_score := 0

func _ready() -> void:
	for cname in off_card_names:
		var card = load("res://resources/cards/offense/" + cname + ".tres")
		all_card_resources.append(card)
	for cname in def_card_names:
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
		player_off_deck.append(rand_off_card.card_name)
	for i in range(0, 5):
		var rand_shot_card = shot_cards.pick_random() as CardStat
		player_off_deck.append(rand_shot_card.card_name)

func generate_player_def_deck():
	var def_cards = get_all_defensive_cards()
	for i in range(0, 15):
		var rand_def_card = def_cards.pick_random() as CardStat
		player_def_deck.append(rand_def_card.card_name)

func reset_scores():
	player_score_breakdown = []
	cpu_score_breakdown = []

func get_all_card_names():
	return all_card_resources.map(func (cr: CardStat): return cr.card_name)
