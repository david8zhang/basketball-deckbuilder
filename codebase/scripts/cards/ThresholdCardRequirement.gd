class_name ThresholdCardRequirement
extends CardRequirement

enum ReqComparator {
	LESS,
	GREATER,
	EQUALS,
	LESS_EQUALS,
	GREATER_EQUALS
}

@export var comparator: ReqComparator
@export var threshold := 0