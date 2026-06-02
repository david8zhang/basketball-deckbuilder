class_name CardRequirement
extends Resource

enum ReqType {
	ENEMY_DEF_SCORE,
	PLAYER_DEF_SCORE,
	OFF_ADV_AMOUNT,
	ENEMY_ATTACK_INTENT,
	ENEMY_DEFEND_INTENT
}

@export var requirement_type: ReqType