class_name EventBonusPenaltyManager
extends Node

class EventBonus:
	var bonus_stat: AddStatEvent.StatToAdd
	var amount := 0
	var num_games := 0
	func _init(_bonus_stat, _amount, _num_games) -> void:
		bonus_stat = _bonus_stat
		amount = _amount
		num_games = _num_games

class EventPenalty:
	var penalty_stat: LoseStatEvent.StatToLose
	var amount := 0
	var num_games := 0
	func _init(_penalty_stat, _amount, _num_games):
		penalty_stat = _penalty_stat
		amount = _amount
		num_games = _num_games

var event_bonuses := []
var event_penalties := []

func select_modify_stat_event(e):
	if e is AddStatEvent:
		var new_bonus = EventBonus.new(e.stat_to_add, e.amount, e.num_games)
		event_bonuses.append(new_bonus)
	elif e is LoseStatEvent:
		var new_penalty = EventPenalty.new(e.stat_to_lose, e.amount, e.num_games)
		event_penalties.append(new_penalty)