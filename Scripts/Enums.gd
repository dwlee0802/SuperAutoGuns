extends Node
class_name Enums

enum Nation {Germany, USSR, Generic}

static func NationToString(num: Nation):
	if num == Nation.Germany:
		return "Germany"
	if num == Nation.USSR:
		return "USSR"
	if num == Nation.Generic:
		return "Generic"


enum UnitType {Infantry, Armor, Support}
static var unitTypeCount: int = 3

static func UnitTypeToString(num: UnitType):
	if num == UnitType.Infantry:
		return "Infantry"
	if num == UnitType.Armor:
		return "Armor"
	if num == UnitType.Support:
		return "Support"
