class_name Overworld
extends Node2D

@onready var event_picker = $CanvasLayer/EventPicker as HBoxContainer
@onready var calendar = $CanvasLayer/DailyCalendar as HBoxContainer
@onready var continue_or_skip_button = $CanvasLayer/ContinueOrSkip as Button
@export var event_card_scene: PackedScene
@export var game_preview_scene: PackedScene
@export var event_calendar_texture: Texture2D
@export var game_calendar_texture: Texture2D
@export var boss_game_calendar_texture: Texture2D

var calendar_caret

func _ready() -> void:
	if GameVariables.get_overall_schedule().is_empty():
		GameVariables.generate_schedule()
	render_schedule_events()
	render_curr_day_event()

func render_schedule_events():
	var curr_week = GameVariables.get_curr_week_schedule()
	var calendar_days = calendar.get_children() as Array[CalendarDay]
	for i in range(0, curr_week.size()):
		var calendar_day = calendar_days[i]
		var day_event = curr_week[i] as OverworldManager.ScheduleDay
		match day_event:
			OverworldManager.ScheduleDay.REGULAR_GAME:
				calendar_day.texture_rect.texture = game_calendar_texture
			OverworldManager.ScheduleDay.BOSS_GAME:
				calendar_day.texture_rect.texture = boss_game_calendar_texture
			OverworldManager.ScheduleDay.GOOD_EVENT, OverworldManager.ScheduleDay.BAD_EVENT:
				calendar_day.texture_rect.texture = event_calendar_texture

func render_curr_day_event():
	var calendar_days = calendar.get_children() as Array[CalendarDay]
	for day in calendar_days:
		day.deselect()
	var curr_calendar_day = calendar_days[GameVariables.get_day_of_week()]
	curr_calendar_day.select()
	var curr_day_event = GameVariables.get_day_event()
	match curr_day_event:
		OverworldManager.ScheduleDay.REGULAR_GAME:
			var game_preview = game_preview_scene.instantiate() as GamePreview
			var rand_team_config = GameVariables.get_random_team_config()
			game_preview.team_config = rand_team_config
			event_picker.add_child(game_preview)
		OverworldManager.ScheduleDay.GOOD_EVENT:
			var random_good_events = GameVariables.get_random_good_events(3)
			for ec in random_good_events:
				var event_card = event_card_scene.instantiate() as EventCard
				event_card.on_pressed.connect(GameVariables.select_event)
				event_card.event_config = ec
				event_picker.add_child(event_card)
		OverworldManager.ScheduleDay.BAD_EVENT:
			var random_bad_events = GameVariables.get_random_bad_events(3)
			for ec in random_bad_events:
				var event_card = event_card_scene.instantiate() as EventCard
				event_card.on_pressed.connect(GameVariables.select_event)
				event_card.event_config = ec
				event_picker.add_child(event_card)
