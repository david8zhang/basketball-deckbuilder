class_name GamePreview
extends Panel

@onready var team_name_label = $HBoxContainer/TeamNameLabel as Label
@onready var intel_container = $HBoxContainer/VBoxContainer/IntelContainer as VBoxContainer
@onready var rewards_container = $HBoxContainer/VBoxContainer/RewardsContainer as HBoxContainer
var team_config: TeamConfig

func _ready() -> void:
	team_name_label.text = team_config.team_name
