# abstract class for Enemy AI
class_name EnemyAI

var isPlayerAI: bool = false

var unitMatrix
var reserve
var editor


func _init(unitMat, res, edi):
	unitMatrix = unitMat
	reserve = res
	editor = edi
	
	
# returns a 2D array of units
func GenerateUnitMatrix():
	print("ERROR! Trying to generate unit matrix from abstract base class!")
	return null


func ChooseReinforcementOption():
	return
