class_name GamePreview
extends Panel

@onready var team_name_label = $HBoxContainer/TeamNameLabel as Label
@onready var intel_container = $HBoxContainer/VBoxContainer/IntelContainer as VBoxContainer
@onready var rewards_container = $HBoxContainer/VBoxContainer/RewardsContainer as HBoxContainer
var team_config: TeamConfig

func show_team_and_selector_config(team_plus_selector: OverworldManager.TeamPlusSelectorConfig):
	team_config = team_plus_selector.team_config as TeamConfig
	team_name_label.text = team_config.team_name
	var play_selector = team_plus_selector.selector as PlaySelector
	for i in range(0, intel_container.get_children().size()):
		if i > 0:
			intel_container.get_child(i).queue_free()
	show_play_tendencies(play_selector.default_off_plays)
	show_play_tendencies(play_selector.default_def_plays)

func show_play_tendencies(plays: Array):
	for p in plays:
		var play = p as Play
		if !play.play_name.contains("Default"):
			var label = Label.new()
			label.text = play.play_name
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			intel_container.add_child(label)
