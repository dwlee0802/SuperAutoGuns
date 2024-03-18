extends Control
class_name GameManager

@onready var cycleTimer: Timer = $CycleTimer

# Column 0 is the frontline
static var playerUnitMatrix
static var enemyUnitMatrix

static var playerReserves = []

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


# first index is the column, second index is the row
func Make2DArray(h, w):
	var output = []
	output.resize(w)
	for i in range(w):
		var newlist = []
		newlist.resize(h)
		output[i] = newlist
	
	return output


func InitializeMatrix():
	playerUnitMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyUnitMatrix = Make2DArray(matrixHeight, matrixWidth)
	
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
	playerDamageMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyDamageMatrix = Make2DArray(matrixHeight, matrixWidth)
	
	# go through all units and set damage matrix
	for col in range(matrixWidth):
		for row in range(matrixWidth):
			if playerUnitMatrix[col][row] != null:
				var targetCoord = FindAttackTarget(true, row, playerUnitMatrix[col][row].data.attackRange)
				if targetCoord != null:
					enemyDamageMatrix[targetCoord.x][targetCoord.y] += playerUnitMatrix[col][row].data.attackDamage
			
			if enemyUnitMatrix[col][row] != null:
				var targetCoord = FindAttackTarget(false, row, enemyUnitMatrix[col][row].data.attackRange)
				if targetCoord != null:
					playerDamageMatrix[targetCoord.x][targetCoord.y] += enemyUnitMatrix[col][row].data.attackDamage
				
	# 4. apply damage matrix
	for col in range(matrixWidth):
		for row in range(matrixWidth):
			if playerUnitMatrix[col][row] != null:
				playerUnitMatrix[col][row].ReceiveHit(playerDamageMatrix[col][row])
			if enemyUnitMatrix[col][row] != null:
				enemyUnitMatrix[col][row].ReceiveHit(enemyDamageMatrix[col][row])
	
	# 5. process movement
	
	# stop cycle timer if one side wins
	pass


# when inputted a position on the matrix
# returns a vector containing the row col position of an attack target
# returns null if no units are found
# checkCols means how many columns it can search away from itself
func FindAttackTarget(isPlayer: bool, curRow, checkCols: int = 1):
	var checkingMatrix = enemyUnitMatrix
	if !isPlayer:
		checkingMatrix = playerUnitMatrix
		
	for col_offset in range(checkCols):
		var checkingColumn = checkingMatrix[col_offset]
		for i in range(len(checkingColumn)):
			var upper: Unit = null
			var lower: Unit = null
			
			if curRow + i < len(checkingColumn):
				upper = checkingColumn[curRow + i]
			if curRow - i >= 0:
				lower = checkingColumn[curRow - i]
			
			# both exists return the one that has lower HP
			if upper != null and lower != null:
				if upper.currentHealthPoints < lower.currentHealthPoints:
					return Vector2(col_offset, curRow + i)
				elif upper.currentHealthPoints > lower.currentHealthPoints:
					return Vector2(col_offset, curRow - i)
				else:
					var rng = randi()
					if rng%2 == 0:
						return Vector2(col_offset, curRow + i)
					else:
						return Vector2(col_offset, curRow - i)
			else:
				if upper != null:
					return Vector2(col_offset, curRow + i)
				if lower != null:
					return Vector2(col_offset, curRow - i)
		
	return null


static func AddReserveUnit(data: UnitData):
	playerReserves.append(Unit.new(data))
