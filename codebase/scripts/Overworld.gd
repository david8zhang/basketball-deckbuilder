class_name Overworld
extends Node2D

@onready var event_picker = $CanvasLayer/EventPicker as HBoxContainer
@onready var calendar = $CanvasLayer/DailyCalendar as HBoxContainer
@export var event_scene: PackedScene
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