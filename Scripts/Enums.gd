extends Node
class_name Enums

enum Nation {Germany, USSR}

static func NationToString(num: Nation):
	if num == Nation.Germany:
		return "Germany"
	if num == Nation.USSR:
		return "USSR"
