class_name PlayerManager
extends Node

var off_deck: Array[String] = [
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
]

var shot_deck: Array[String] = [
	"Layup",
	"Layup",
	"Mid Range Jumper",
	"Mid Range Jumper",
	"3-Point Jumper"
]

var def_deck: Array[String] = [
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

func add_card(c: CardStat):
	match c.card_type:
		CardStat.CardType.OFFENSE:
			off_deck.append(c.card_name)
		CardStat.CardType.SHOT:
			shot_deck.append(c.card_name)
		CardStat.CardType.DEFENSE:
			def_deck.append(c.card_name)

func lose_card(card_stat: CardStat):
	if off_deck.has(card_stat.card_name):
		off_deck.erase(card_stat.card_name)
	elif def_deck.has(card_stat.card_name):
		def_deck.erase(card_stat.card_name)
	elif shot_deck.has(card_stat.card_name):
		shot_deck.erase(card_stat.card_name)
