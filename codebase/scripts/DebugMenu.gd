class_name DebugMenu
extends Control

@onready var game = get_node("/root/Game") as Game
@onready var overworld = get_node("/root/Overworld") as Overworld
@onready var text_edit = $TextEdit as TextEdit

const COMMAND_KEYWORDS = {
	ADD_PLAYER_CARD = "add_player_card",
	SET_CURRENT_EVENT = "set_curr_event"
}

func _ready() -> void:
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.keycode == KEY_QUOTELEFT and key_event.is_released():
			text_edit.text = ""
			toggle_menu_visible()
		if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
			handle_command(text_edit.text.rstrip("\n\r"))
			text_edit.text = ""

func toggle_menu_visible():
	visible = !visible
	if visible:
		text_edit.grab_focus()

func handle_command(command: String):
	var tokens = command.split(" ") as Array[String]
	if tokens.is_empty():
		push_warning("Command is invalid!")
		return
	var command_keyword = (tokens[0] as String).to_lower()
	match command_keyword:
		COMMAND_KEYWORDS.ADD_PLAYER_CARD:
			if tokens.size() < 2:
				push_warning("Usage: \"add_player_card \" {card name}")
			else:
				var card_name_tokens = tokens.slice(1)
				var joined_card_name = " ".join(card_name_tokens)
				add_card(joined_card_name)
		COMMAND_KEYWORDS.SET_CURRENT_EVENT:
			if tokens.size() < 2:
				push_warning("Usage: \"set_curr_event \" {event name}")
			else:
				var event_name_tokens = tokens.slice(1)
				var joined_event_name = " ".join(event_name_tokens)
				set_curr_event(joined_event_name)

func add_card(card_name: String):
	var card_stat = GameVariables.load_card_stat_from_name(card_name)
	if card_stat == null:
		push_warning("Card with name: " + str(card_name) + " does not exist!")
	else:
		if game != null:
			var card = game.card_scene.instantiate() as Card
			card.card_stat = card_stat
			game.player_hand.add_child(card)
			card.card_button.visible = false	

func set_curr_event(event_name: String):
	var event = GameVariables.overworld_manager.load_event_from_name(event_name)
	overworld.set_curr_event(event)