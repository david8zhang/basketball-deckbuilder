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

# Team configs
var team_config_file_names = [
	"SampleTeam"
]
var all_team_config_resources = []

# Event configs
var event_file_names = [
	# Good events
	"CoachAdjustment",
	"DefensiveDrills",
	"DiscountedTickets",
	"OffensiveDrills",
	"PlayersMeeting",
	"RestDay",
	"Shootaround",
	"ViralMoment",
	# Bad events
	"PreGamePressure",
	"RedEyeFlight",
	"ShootingSlump",
	"HeroBall"
]
var all_event_resources = []

var schedule = []
var week_num := 0
var day_num := 0

func _ready() -> void:
	load_all_team_config_resources()
	load_all_event_resources()

func load_all_team_config_resources():
	for fn in team_config_file_names:
		var res = load("res://resources/overworld/team_configs/" + fn + ".tres")
		all_team_config_resources.append(res)

func load_all_event_resources():
	for fn in event_file_names:
		var res = load("res://resources/overworld/events/" + fn + ".tres")
		all_event_resources.append(res)

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

func get_random_team_config():
	return all_team_config_resources.pick_random()

func get_random_good_events(num_events: int):
	var all_good_events = []
	for e in all_event_resources:
		if e is GoodEvent:
			all_good_events.append(e)
	all_good_events.shuffle()
	print("Num good events: " + str(all_good_events.size()))
	return all_good_events.slice(0, num_events)

func get_random_bad_events(num_events: int):
	var all_bad_events = []
	for e in all_event_resources:
		if e is BadEvent:
			all_bad_events.append(e)
	all_bad_events.shuffle()
	print("Num bad events: " + str(all_bad_events.size()))
	return all_bad_events.slice(0, num_events)

