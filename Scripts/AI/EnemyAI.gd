# abstract class for Enemy AI
class_name EnemyAI

var colCount: int = 0
var rowsCount: int = 0


func _init(cols, rows):
	colCount = cols
	rowsCount = rows
	
	
# returns a 2D array of units
func GenerateUnitMatrix():
	print("ERROR! Trying to generate unit matrix from abstract base class!")
	return null


func ChooseReinforcementOption():
	return
