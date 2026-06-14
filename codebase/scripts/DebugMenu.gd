class_name DebugMenu
extends Control

@onready var game = get_node("/root/Game") as Game
@onready var text_edit = $TextEdit as TextEdit

func _ready() -> void:
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.keycode == KEY_QUOTELEFT and key_event.is_released():
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
		"add_player_card":
			if tokens.size() < 2:
				push_warning("Usage: \"add_player_card \" {card name}")
			else:
				var card_name_tokens = tokens.slice(1)
				var joined_card_name = " ".join(card_name_tokens)
				add_card(joined_card_name)

func add_card(card_name: String):
	var card_stat = GameVariables.load_card_stat_from_name(card_name)
	if card_stat == null:
		push_warning("Card with name: " + str(card_name) + " does not exist!")
	else:
		var card = game.card_scene.instantiate() as Card
		card.card_stat = card_stat
		game.player_hand.add_child(card)
		card.card_button.visible = false	
