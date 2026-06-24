class_name CalendarDay
extends VBoxContainer

@export var day_name := ""
@onready var label = $Label as Label

func _ready() -> void:
	label.text = day_name

