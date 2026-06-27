class_name OverworldManager
extends Node

# Calendar of events. 3 weeks of 7 days. Each week has 4 games (3 regular games, 1 boss). 
# In between games are events, which can be good or bad
# If the player manages to make it far enough, a 4th week will be added, representing the playoffs
enum ScheduleDay {
	REGULAR_GAME,
	BOSS_GAME,
	PO_FIRST_ROUND_GAME,
	PO_SEMIFINALS_GAME,
	PO_CONF_FINALS_GAME,
	PO_FINALS_GAME,
	GOOD_EVENT,
	BAD_EVENT
}

var schedule = []
var week_num := 0
var day_num := 0

func _ready() -> void:
	pass

func generate_schedule():
	for _i in range(0, 3):
		var week = []		
		for _j in range(0, 3):
			week.append(ScheduleDay.REGULAR_GAME)
		for _j in range(0, 3):
			var rand_event = ScheduleDay.BAD_EVENT if randi_range(0, 2) == 0 else ScheduleDay.GOOD_EVENT
			week.append(rand_event)
		week.shuffle()
		week.append(ScheduleDay.BOSS_GAME)
		schedule.append(week)