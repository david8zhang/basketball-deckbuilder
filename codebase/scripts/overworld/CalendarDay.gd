class_name CalendarDay
extends VBoxContainer

@export var day_name := ""
@onready var label = $Label as Label
@onready var texture_rect = $TextureRect as TextureRect
@onready var caret = $Caret as TextureRect

func _ready() -> void:
	label.text = day_name

func select():
	caret.self_modulate.a = 1

func deselect():
	caret.self_modulate.a = 0