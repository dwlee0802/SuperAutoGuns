extends Control
class_name UnitCard

var unit: Unit


func SetUnit(_unit: Unit):
	unit = _unit
	$Name.text = unit.data.name
