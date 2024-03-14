extends Control
class_name GameManager

@onready var cycleTimer: Timer = $CycleTimer

static var playerUnitMatrix
static var enemyUnitMatrix

static var playerDamageMatrix
static var enemyDamageMatrix

static var playerEffectMatrix
static var enemyEffectMatrix

# temporary value for the size of the matrix
var matrixWidth: int = 3
var matrixHeight: int = 4


# Called when the node enters the scene tree for the first time.
func _ready():
	cycleTimer.timeout.connect(CycleProcess)


func Make2DArray(h, w):
	var output = []
	output.resize(h)
	for i in range(h):
		var newlist = []
		newlist.resize(w)
		output[i] = newlist
	
	return output


func InitializeMatrix():
	playerUnitMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyUnitMatrix = Make2DArray(matrixHeight, matrixWidth)
	
	playerDamageMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyDamageMatrix = Make2DArray(matrixHeight, matrixWidth)
	
	playerEffectMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyEffectMatrix = Make2DArray(matrixHeight, matrixWidth)
	
	
# calculate one cycle of the battle
# 1. generate effect matrix
# 2. apply effect matrix
# 3. generate damage matrix
# 4. apply effect matrix
# 5. process movement
# stop cycle timer if one side wins
func CycleProcess():
	# 1. generate effect matrix
	
	# 2. apply effect matrix
	
	# 3. generate damage matrix
	
	# 4. apply effect matrix
	
	# 5. process movement
	
	# stop cycle timer if one side wins
	pass


# when inputted a position on the matrix
# returns a vector containing the row col position of an attack target
# returns null if no units are found
# checkCols means how many columns it can search away from itself
func FindAttackTarget(isPlayer: bool, curRow, curCol, checkCols: int = 1):
	# which direction to increase column index
	# right (positive) for player
	# left (negative) for enemy
	var h_dir: int = 1
	
	var checkingMatrix = enemyUnitMatrix
	if !isPlayer:
		checkingMatrix = playerUnitMatrix
		h_dir = -1
		
	for i in range(checkCols):
		if i + curCol < 0 or i + curCol > matrixWidth:
			# column index is out of bounds.
			break
			
		# add to row
		var v_offset: int = 0
		var dir: int = 1
		while true:
			if curRow + h_offset > 0 and curRow + h_offset < matrixHeight
			
			if dir < 0:
				# move onto next h offset if checked below
				h_offset += 1
				
			dir *= -1
	return
