class_name Overworld
extends Node2D

@onready var event_picker = $CanvasLayer/EventPicker as HBoxContainer
@onready var calendar = $CanvasLayer/DailyCalendar as HBoxContainer
@onready var continue_or_skip_button = $CanvasLayer/ContinueOrSkip as Button
@onready var card_to_add_picker = $CanvasLayer/CardToAddPicker as CardToAddPicker
@onready var card_to_lose_picker = $CanvasLayer/CardToLosePicker as CardToLosePicker
@onready var game_preview = $CanvasLayer/GamePreview as GamePreview

@export var event_card_scene: PackedScene
@export var event_calendar_texture: Texture2D
@export var game_calendar_texture: Texture2D
@export var boss_game_calendar_texture: Texture2D

func _ready() -> void:
	if GameVariables.get_overall_schedule().is_empty():
		GameVariables.generate_schedule()
	render_schedule_events()
	render_curr_day_event()
	card_to_add_picker.on_confirm_selections.connect(add_selected_cards_from_event)
	card_to_lose_picker.on_confirm_selections.connect(remove_selected_cards_from_event)

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
	for c in event_picker.get_children():
		c.queue_free()
	var curr_calendar_day = calendar_days[GameVariables.get_day_of_week()]
	curr_calendar_day.select()
	var curr_day_event = GameVariables.get_day_event()
	match curr_day_event:
		OverworldManager.ScheduleDay.REGULAR_GAME, OverworldManager.ScheduleDay.BOSS_GAME:
			render_team_config_preview()
			continue_or_skip_button.show()
			continue_or_skip_button.text = "Play Game"
			continue_or_skip_button.pressed.connect(start_game, CONNECT_ONE_SHOT)
		OverworldManager.ScheduleDay.GOOD_EVENT:
			var random_good_events = GameVariables.get_random_good_events(3)
			for ec in random_good_events:
				var event_card = event_card_scene.instantiate() as EventCard
				if ec is AddStatEvent:
					event_card.on_pressed.connect(select_add_stat_event)
				elif ec is AddCardEvent:
					event_card.on_pressed.connect(render_card_to_add_picker)
				event_card.event_config = ec
				event_picker.add_child(event_card)
			continue_or_skip_button.show()				
			continue_or_skip_button.text = "Skip"
			continue_or_skip_button.pressed.connect(skip_event, CONNECT_ONE_SHOT)
		OverworldManager.ScheduleDay.BAD_EVENT:
			var random_bad_events = GameVariables.get_random_bad_events(1)
			var ec = random_bad_events[0] as Event
			var event_card = event_card_scene.instantiate() as EventCard
			if ec is LoseStatEvent:
				event_card.on_pressed.connect(select_add_stat_event)
				continue_or_skip_button.show()
				continue_or_skip_button.text = "Continue"
				var callable = Callable(self, "select_add_stat_event").bind(ec)
				continue_or_skip_button.pressed.connect(callable, CONNECT_ONE_SHOT)				
			elif ec is LoseCardEvent:
				event_card.on_pressed.connect(render_card_to_lose_picker)
				continue_or_skip_button.hide()
			event_card.event_config = ec
			event_picker.add_child(event_card)

func select_add_stat_event(event_config: Event):
	GameVariables.select_modify_stat_event(event_config)
	GameVariables.increment_day_of_week()
	render_curr_day_event()

func render_card_to_add_picker(event_config: Event):
	var add_card_event = event_config as AddCardEvent
	card_to_add_picker.handle_add_card_event(add_card_event)

func render_card_to_lose_picker(event_config: Event):
	var lose_card_event = event_config as LoseCardEvent
	card_to_lose_picker.handle_lose_card_event(lose_card_event)

func render_team_config_preview():
	GameVariables.set_reg_team_config()
	game_preview.show_team_and_selector_config(GameVariables.get_curr_team_and_selector_config())
	game_preview.show()

func skip_event():
	GameVariables.increment_day_of_week()
	render_curr_day_event()

func start_game():
	GameVariables.increment_day_of_week()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func add_selected_cards_from_event(card_stats):
	card_to_add_picker.hide()
	for c in card_stats:
		GameVariables.add_card(c)
	GameVariables.increment_day_of_week()
	render_curr_day_event()

func remove_selected_cards_from_event(card_stats):
	card_to_lose_picker.hide()
	for c in card_stats:
		GameVariables.lose_card(c)
	GameVariables.increment_day_of_week()
	render_curr_day_event()
