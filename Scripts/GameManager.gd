extends Control
class_name GameManager

static var cycleTimer: Timer
static var cycleLabel: Label

static var cycleTime: float = 0.5
static var cycleCount: int = 0

static var battleCount: int = 0
static var maxBattleCount: int = 25

static var battleResultLabel: Label

# Column 0 is the frontline
static var playerUnitMatrix
static var enemyUnitMatrix

static var playerUnitMatrixBackup
static var enemyUnitMatrixBackup

static var playerReserves = []
static var enemyReserves = []

static var playerDamageMatrix
static var enemyDamageMatrix

static var playerAttackTargetMatrix
static var enemyAttackTargetMatrix

static var playerEffectMatrix
static var enemyEffectMatrix

# temporary value for the size of the matrix
static var matrixWidth: int = 3
static var matrixHeight: int = 6

static var userInterface: UserInterface

static var captureStatusUI: CaptureStatusUI

static var totalSectorsCount: int = 10

static var playerCapturedSectorsCount: int = 5

# economy stuff
static var playerFunds: int = 0
static var enemyFunds: int = 0

static var interestRate: float = 0.1
static var maxInterest: int = 10

static var rerollCost: int = 1

static var playerTotalFunds: int = 0
static var enemyTotalFunds: int = 0

static var playerFundsHistory = []
static var enemyFundsHistory = []

static var playerTotalFundsHistory = []
static var enemyTotalFundsHistory = []

static var playerIncomeHistory = []
static var enemyIncomeHistory = []

static var baseIncomeAmount: int = 10

static var autoHealRatio: float = 0.25
static var autoHealAmount: int = 1

static var enemyAI
static var playerAI

static var reinforcementCount: int = 6

# -1 is player victory 0 is draw 1 is enemy victory
static var lastBattleResult: int = 0

static var playerPassed: bool = false
static var enemyPassed: bool = false

static var healCostPerStackCount: int = 2

static var refundRatio: float = 0.5

static var controlButtons

static var playerEffectiveDamage: int = 0

static var enemyEffectiveDamage: int = 0

static var effectiveDamageUI

static var playerAttackingUnitsCount

static var enemyAttackingUnitsCount

static var waitingForAttackAnimaionFinish: bool = false

static var playerGoesFirst: bool = true

static var playerAttacking: bool = true

static var isPlayerTurn: bool = false

static var initiativeUI

static var playerColor: Color
static var enemyColor: Color

@export var playerColorOverride: Color = Color.ROYAL_BLUE
@export var enemyColorOverride: Color = Color.DARK_RED

@export var turnTime: float = 30

static var fundsGraph


static func _static_init():
	InitializeMatrix()


func _ready():
	GameManager.playerColor = playerColorOverride
	GameManager.enemyColor = enemyColorOverride
	
	cycleTimer = $CycleTimer
	cycleLabel = $CycleCountLabel
	effectiveDamageUI = $EffectiveDamageUI
	
	GameManager.fundsGraph = $EconomyUI/Graph2D
	
	GameManager.cycleTimer.timeout.connect(_on_cycle_timer_timeout)
	
	userInterface = $UserInterface
	
	captureStatusUI = $UserInterface/Root/CaptureStatusUI
	
	battleResultLabel = $BattleResultLabel
	
	userInterface.GenerateGrid(GameManager.matrixWidth * 2 + 1, GameManager.matrixHeight)
	userInterface.SetSlotAvailability(0, 3)
	userInterface.SetSlotColor(isPlayerTurn, playerAttacking)
	
	playerIncomeHistory.append(0)
	playerFundsHistory.append(0)
	playerTotalFundsHistory.append(0)
	
	enemyIncomeHistory.append(0)
	enemyFundsHistory.append(0)
	enemyTotalFundsHistory.append(0)
	
	AddIncome(isPlayerTurn)
	
	userInterface.SetTurnLabel(GameManager.isPlayerTurn)
	# defender always go first set attack dir ui to left
	
	# start turn timer
	userInterface.turnTimer.start(turnTime)
	userInterface.turnTimer.timeout.connect(CommitButtonPressed)
	
	userInterface.GenerateReinforcementOptions(isPlayerTurn, GameManager.reinforcementCount)
	
	# link commit button
	userInterface.get_node("Root/MiddleScreen/MidLeftScreen/ReserveUI/UnitManagementButtons/CommitButton").pressed.connect(CommitButtonPressed)
	
	# link pass button
	userInterface.get_node("Root/MiddleScreen/MidLeftScreen/ReserveUI/UnitManagementButtons/PassButton").pressed.connect(PassButtonPressed)
	
	#enemyAI = EnemyAI_Randomizer.new()
	#enemyAI.editor = enemyEditor
	#enemyAI.unitMatrix = enemyUnitMatrix
	#enemyAI.reserve = enemyReserves
	
	#playerAI = EnemyAI_Randomizer.new()
	#playerAI.editor = playerEditor
	#playerAI.unitMatrix = playerUnitMatrix
	#playerAI.reserve = playerReserves
	

func _process(_delta):
	UpdateCTKLabel()
	
	if waitingForAttackAnimaionFinish:
		if GameManager.playerAttackingUnitsCount == 0 and GameManager.enemyAttackingUnitsCount == 0:
			# all units finished attack animations
			GameManager.ClearDeadUnits(GameManager.playerUnitMatrix)
			GameManager.ClearDeadUnits(GameManager.enemyUnitMatrix)
			GameManager.playerAttackingUnitsCount = 0
			GameManager.enemyAttackingUnitsCount = 0
			waitingForAttackAnimaionFinish = false
	
	
func _on_cycle_timer_timeout():
	# if battle is finished, stop timer
	if GameManager.CycleProcess():
		print("\n***End Battle Process***\n\n")
		cycleTimer.stop()
		
		userInterface.SetTurnLabel(GameManager.isPlayerTurn)	
		GameManager.HealUnits()
		
		# defending player goes first
		# set attack dir ui to left
		userInterface.SetAttackDirectionUI(true)
		
		if !playerAttacking:
			isPlayerTurn = true
			userInterface.ImportUnitMatrix(playerUnitMatrix, enemyUnitMatrix, 0)
			userInterface.ImportReserve(playerReserves)
		else:
			isPlayerTurn = false
			userInterface.ImportUnitMatrix(enemyUnitMatrix, playerUnitMatrix, 0)
			userInterface.ImportReserve(enemyReserves)
			
		userInterface.GenerateReinforcementOptions(isPlayerTurn, reinforcementCount)
		
		userInterface.SetSlotColor(isPlayerTurn, playerAttacking)
		
		cycleCount = 0
		
		# start next turn
		AddIncome(isPlayerTurn)
		userInterface.turnTimer.start(turnTime)
	else:
		if cycleTimer.is_stopped():
			# should wait til animations are done
			cycleTimer.start(BattleSpeedUI.cycleSpeed)
			
	GameManager.UpdateEffectiveDamageUI()
	UpdateCTKLabel()
	

# called when player ends preparation phase and presses process battle button
func _on_battle_process_button_pressed():
	userInterface.turnTimer.stop()
	
	GameManager.playerEffectiveDamage = 0
	GameManager.enemyEffectiveDamage = 0
	GameManager.UpdateEffectiveDamageUI()
	
	# back up unit matrix
	playerUnitMatrixBackup = playerUnitMatrix.duplicate(true)
	enemyUnitMatrixBackup = enemyUnitMatrix.duplicate(true)
	
	# deep copy units
	for col in range(matrixWidth):
		for row in range(matrixHeight):
			if playerUnitMatrixBackup[col][row] != null:
				playerUnitMatrixBackup[col][row] = playerUnitMatrixBackup[col][row].Duplicate()
			if enemyUnitMatrixBackup[col][row] != null:
				enemyUnitMatrixBackup[col][row] = enemyUnitMatrixBackup[col][row].Duplicate()
	
	# save initial coords inside unit matrix
	var SaveInitialCoords = func(unit):
		if unit is Unit:
			unit.SaveCoords()
		
	GameManager.ProcessUnitMatrix(playerUnitMatrix, SaveInitialCoords)
	GameManager.ProcessUnitMatrix(enemyUnitMatrix, SaveInitialCoords)
	
	# process static abilities
	print("***Starting Static Ability Process***\n")
	
	GameManager.ProcessStaticAbility(playerUnitMatrix)
	GameManager.ProcessStaticAbility(enemyUnitMatrix)
	
	print("***End Static Ability Process***\n\n")
	
	# add new column based on attack and defense
	var newPlayerUnitMatrix = GameManager.Make2DArray(GameManager.matrixHeight, GameManager.matrixWidth + 1)
	var newEnemyUnitMatrix = GameManager.Make2DArray(GameManager.matrixHeight, GameManager.matrixWidth + 1)
	
	for col in range(matrixWidth):
		for row in range(matrixHeight):
			if playerAttacking:
				newPlayerUnitMatrix[col+1][row] = playerUnitMatrix[col][row]
				
				if newPlayerUnitMatrix[col+1][row] != null:
					newPlayerUnitMatrix[col+1][row].coords = Vector2(col+1, row)
					
				newEnemyUnitMatrix[col][row] = enemyUnitMatrix[col][row]
			else:
				newEnemyUnitMatrix[col+1][row] = enemyUnitMatrix[col][row]
				
				if newEnemyUnitMatrix[col+1][row] != null:
					newEnemyUnitMatrix[col+1][row].coords = Vector2(col+1, row)
					
				newPlayerUnitMatrix[col][row] = playerUnitMatrix[col][row]
	
	playerUnitMatrix = newPlayerUnitMatrix
	enemyUnitMatrix = newEnemyUnitMatrix
	
	## TODO: update UI
	UnitCard.selected = null
	userInterface.UpdateHealButtonLabel()
	userInterface.UpdateSellButtonLabel()
	
	UpdateCTKLabel()
	
	if playerAttacking:
		userInterface.ImportUnitMatrix(playerUnitMatrix, enemyUnitMatrix, 1)
	else:
		userInterface.ImportUnitMatrix(playerUnitMatrix, enemyUnitMatrix, -1)
	
	# process first cycle
	print("***Starting Battle Process***\n")
	GameManager.battleCount+= 1
	$BattleCountLabel.text = "Battle: " + str(GameManager.battleCount)
	print("Battle #" + str(GameManager.battleCount))
	if cycleTimer.is_stopped():
		cycleTimer.start(BattleSpeedUI.cycleSpeed)
		userInterface.SetSlotColor(true, playerAttacking)
	
	
static func ImportUnitMatrixBackup():
	print("player attacking: " + str(playerAttacking))
	
	print("backup")
	PrintUnitMatrix(playerUnitMatrixBackup)
	print("player unit")
	PrintUnitMatrix(playerUnitMatrix)
	print("backup")
	PrintUnitMatrix(enemyUnitMatrixBackup)
	print("enemy unit")
	PrintUnitMatrix(enemyUnitMatrix)
	
	# update healths
	# look through current unit matrix and move their health to new unit matrix
	var leftPlayerUnits = GameManager.GetUnitsInMatrix(playerUnitMatrix)
	var leftEnemyUnits = GameManager.GetUnitsInMatrix(enemyUnitMatrix)
	
	print("left player count: " + str(leftPlayerUnits.size()))
	print("left enemy count: " + str(leftEnemyUnits.size()))
	
	# reset last received damage amount to zero
	var SetHealthToZero = func(unit):
		if unit is Unit:
			unit.currentHealthPoints = 0
		
	ProcessUnitMatrix(playerUnitMatrixBackup, SetHealthToZero)
	ProcessUnitMatrix(enemyUnitMatrixBackup, SetHealthToZero)
	
	for survivor: Unit in leftPlayerUnits:
		print("survivor coords: " + str(survivor.initialCoords))
		if playerUnitMatrixBackup[survivor.initialCoords.x][survivor.initialCoords.y] != null:
			playerUnitMatrixBackup[survivor.initialCoords.x][survivor.initialCoords.y].currentHealthPoints = survivor.currentHealthPoints
		
	for survivor: Unit in leftEnemyUnits:
		if enemyUnitMatrixBackup[survivor.initialCoords.x][survivor.initialCoords.y] != null:
			enemyUnitMatrixBackup[survivor.initialCoords.x][survivor.initialCoords.y].currentHealthPoints = survivor.currentHealthPoints
	
	# assign backup to unit matrix
	enemyUnitMatrix = enemyUnitMatrixBackup
	playerUnitMatrix = playerUnitMatrixBackup
	
	GameManager.ResetModifierArray(playerUnitMatrix)
	
	print("Imported backup unit matrix")
	
	
static func HealUnits():
	print("\nUnit Auto Heal\n")
	for col in range(matrixWidth):
		for row in range(matrixHeight):
			if enemyUnitMatrix[col][row] != null:
				enemyUnitMatrix[col][row].RatioHeal(autoHealRatio)
			if playerUnitMatrix[col][row] != null:
				playerUnitMatrix[col][row].RatioHeal(autoHealRatio)
	
	
# first index is the column, second index is the row
static func Make2DArray(h, w):
	var output = []
	output.resize(w)
	for i in range(w):
		var newlist = []
		newlist.resize(h)
		output[i] = newlist
	
	return output


static func InitializeMatrix():
	playerUnitMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyUnitMatrix = Make2DArray(matrixHeight, matrixWidth)
	
	playerEffectMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyEffectMatrix = Make2DArray(matrixHeight, matrixWidth)
	
	playerAttackTargetMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyAttackTargetMatrix = Make2DArray(matrixHeight, matrixWidth)
	

# returns true if battle is over
static func CycleProcess():
	# stop cycle timer if one side wins
	cycleCount += 1
	cycleLabel.text = "Cycle: " + str(cycleCount)
	
	# reset last received damage amount to zero
	var SetLastDMGZero = func(unit):
		if unit is Unit:
			unit.lastReceivedDamage = 0
		
	ProcessUnitMatrix(playerUnitMatrix, SetLastDMGZero)
	ProcessUnitMatrix(enemyUnitMatrix, SetLastDMGZero)
	
	# update unit attack and movement costs
	playerAttackingUnitsCount = UnitBehaviorProcess(playerUnitMatrix)
	enemyAttackingUnitsCount = UnitBehaviorProcess(enemyUnitMatrix)
	
	# modify grid according to unit movement
	ApplyUnitMovement(playerUnitMatrix)
	ApplyUnitMovement(enemyUnitMatrix)
	
	# generate damage matrix
	#playerDamageMatrix = GenerateDamageMatrix(enemyUnitMatrix)
	#enemyDamageMatrix = GenerateDamageMatrix(playerUnitMatrix)
	#
	## apply damage matrix
	#ApplyDamageMatrix(playerUnitMatrix, playerDamageMatrix)
	#ApplyDamageMatrix(enemyUnitMatrix, enemyDamageMatrix)
	
	
	print("\nCycle #" + str(cycleCount))
	
	# reload editor UI to apply unit movement
	# unit cards on instantiation play unit attack animations if appropriate
	# when units' attack animation ends, their attack function is called
	# need to disable player messing with the editor while animations are playing
	# units get removed themselves when they die
	
	if playerAttacking:
		userInterface.ImportUnitMatrix(playerUnitMatrix, enemyUnitMatrix, 1)
	else:
		userInterface.ImportUnitMatrix(playerUnitMatrix, enemyUnitMatrix, -1)
	
	waitingForAttackAnimaionFinish = true
	
	var playerCount = UnitCount(playerUnitMatrix)
	var enemyCount = UnitCount(enemyUnitMatrix)
	
	EnemyAI_Randomizer.lostLastBattle = false
				
	if enemyCount == 0 and playerCount == 0:
		GameManager.ImportUnitMatrixBackup()
		BattleResultProcess(false)
		print("\nSuccessful Defensive")
	elif playerAttacking and enemyCount == 0:
		GameManager.ImportUnitMatrixBackup()
		BattleResultProcess(true)
		print("\nSuccessful Player Offensive")
	elif !playerAttacking and playerCount == 0:
		GameManager.ImportUnitMatrixBackup()
		BattleResultProcess(true)
		print("\nSuccessful Enemy Offensive")
	elif !playerAttacking and enemyCount == 0:
		GameManager.ImportUnitMatrixBackup()
		BattleResultProcess(false)
		print("\nSuccessful Player Defensive")
	elif playerAttacking and playerCount == 0:
		GameManager.ImportUnitMatrixBackup()
		BattleResultProcess(false)
		print("\nSuccessful Enemy Defensive")
	
	if playerCount == 0 or enemyCount == 0:
		if playerCount == 0 and enemyCount == 0:
			# draw. defender victory
			lastBattleResult = 0
		if playerCount == 0 and enemyCount != 0:
			# enemy victory
			lastBattleResult = 1
		if playerCount != 0 and enemyCount == 0:
			EnemyAI_Randomizer.lostLastBattle = true
			# player victory
			lastBattleResult = -1
		
		return true
	
	return false


static func UpdateBattleResultLabel(playerWon: bool, attackerVictory: bool):
	# update battle result
	battleResultLabel.visible = true
	if playerWon:
		if attackerVictory:
			battleResultLabel.text = "Player Offensive Victory"
		else:
			battleResultLabel.text = "Player Defensive Victory"
	else:
		if attackerVictory:
			battleResultLabel.text = "Enemy Offensive Victory"
		else:
			battleResultLabel.text = "Enemy Defensive Victory"
			
			
# go through all units and determine if unit is attacking or moving
# units prioritizing movement
# move forward if front slot exists and is empty
# if this is the case, reset attack cost
# if not, check for attack targets
# if attack target exists, start reducing attack cycle cost
# if none exists, do nothing this turn
static func UnitBehaviorProcess(unitMatrix):
	var attackingUnitsCount: int = 0
	
	for col in range(len(unitMatrix)):
		for row in range(len(unitMatrix[col])):
			# check movement
			if unitMatrix[col][row] != null:
				# dont move if: is front column or front slot is occupied
				# row based movement. cound down movement cycles left also if front unit is moving
				if col == 0 or (unitMatrix[col - 1][row] != null and !unitMatrix[col - 1][row].IsMoving()):
					# reset movement cost
					unitMatrix[col][row].movementCyclesLeft = unitMatrix[col][row].data.movementCost
					
					# check if able to attack
					var target = FindAttackTarget(unitMatrix[col][row], unitMatrix[col][row].data.attackFromBack)
					
					# valid attack target exists
					if target != null:
						unitMatrix[col][row].SetAttackTarget(target)
						unitMatrix[col][row].attackCyclesLeft -= 1
						if unitMatrix[col][row].attackCyclesLeft < 0:
							attackingUnitsCount += 1
					# no target. reset value
					else:
						unitMatrix[col][row].attackCyclesLeft = unitMatrix[col][row].data.attackCost
				# can move
				elif unitMatrix[col - 1][row] == null or (unitMatrix[col - 1][row] != null and unitMatrix[col - 1][row].IsMoving()):
					unitMatrix[col][row].movementCyclesLeft -= 1
					unitMatrix[col][row].attackCyclesLeft = unitMatrix[col][row].data.attackCost
	
	return attackingUnitsCount
	

# applies the effect of units' static abilties
static func ProcessStaticAbility(unitMatrix):
	for col in range(len(unitMatrix)):
		for row in range(len(unitMatrix[col])):
			var currentUnit: Unit = unitMatrix[col][row]
			if currentUnit != null and currentUnit.data.ability != null:
				if currentUnit.data.ability.isStatic:
					print(str(currentUnit) + "'s ability:")
					var abilityData = currentUnit.data.ability
					var abilityFunction = Callable(AbilityManager, abilityData.callableName)
					abilityFunction.call(unitMatrix, GetCoord(currentUnit), abilityData.dir_parameter, abilityData.int_parameter, abilityData.statType)
			

# TODO
# called at the start of every cycle
# connects appropriate signals to callable
static func ProcessDynamicAbilityConnections(_unitMatrix):
	pass
	
	
static func ResetModifierArray(unitMatrix):
	for col in range(len(unitMatrix)):
		for row in range(len(unitMatrix[col])):
			var currentUnit: Unit = unitMatrix[col][row]
			if currentUnit != null:
				currentUnit.ResetStatModifiers()
			

# process from the front lines
static func ApplyUnitMovement(unitMatrix):
	for col in range(len(unitMatrix)):
		for row in range(len(unitMatrix[col])):
			if unitMatrix[col][row] != null:
				if unitMatrix[col][row].movementCyclesLeft < 0:
					# make sure front slot is empty
					if col != 0 and unitMatrix[col - 1][row] == null:
						# move forward
						unitMatrix[col][row].coords -= Vector2.RIGHT
						unitMatrix[col - 1][row] = unitMatrix[col][row]
						unitMatrix[col][row] = null
						unitMatrix[col - 1][row].movementCyclesLeft = unitMatrix[col - 1][row].data.movementCost
						
					else:
						print("ERROR! Unit movement cycle is below zero even though it cannot move.")
				
				
static func GenerateDamageMatrix(unitMatrix):
	var output = Make2DArray(matrixHeight, matrixWidth)
	
	for col in range(len(unitMatrix)):
		for row in range(len(unitMatrix[col])):
			output[col][row] = -1
			if unitMatrix[col][row] != null:
				if unitMatrix[col][row].attackCyclesLeft < 0:
					# make sure
					var targetCoord = unitMatrix[col][row].attackTarget.coords
					output[targetCoord.x][targetCoord.y] = unitMatrix[col][row].GetAttackDamage()
	
	return output


static func ApplyDamageMatrix(targetUnitMatrix, damageMatrix):
	for col in range(len(targetUnitMatrix)):
		for row in range(len(targetUnitMatrix[col])):
			if targetUnitMatrix[col][row] != null:
				if damageMatrix[col][row] >= 0:
					targetUnitMatrix[col][row].ReceiveHit(damageMatrix[col][row])
	

# ---Depreciated---
# TODO This needs fixing! Returning value when there isnt anything!!
# when inputted a position on the matrix
# returns a vector containing the row col position of an attack target
# returns null if no units are found
# checkCols means how many columns it can search away from itself
static func FindAttackTargetCoord(isPlayer: bool, curRow, checkCols: int = 1):
	var checkingMatrix = enemyUnitMatrix
	if !isPlayer:
		checkingMatrix = playerUnitMatrix
	
	for col_offset in range(checkCols):
		var checkingColumn = checkingMatrix[col_offset]
		for i in range(matrixHeight):
			var upper: Unit = null
			var lower: Unit = null
			
			if curRow + i < matrixHeight:
				lower = checkingColumn[curRow + i]
			if curRow - i >= 0:
				upper = checkingColumn[curRow - i]
			
			# both exists return the one that has lower HP
			if upper != null and lower != null:
				if upper.currentHealthPoints < lower.currentHealthPoints:
					return Vector2(col_offset, curRow - i)
				elif upper.currentHealthPoints > lower.currentHealthPoints:
					return Vector2(col_offset, curRow + i)
				else:
					# return random one
					var rng = randi()
					if rng%2 == 0:
						return Vector2(col_offset, curRow + i)
					else:
						return Vector2(col_offset, curRow - i)
			else:
				if upper != null:
					return Vector2(col_offset, curRow - i)
				if lower != null:
					return Vector2(col_offset, curRow + i)
	
	return null


static func FindAttackTarget(attacker: Unit, fromBack: bool = false) -> Unit:
	if attacker == null:
		return null
	
	var checkingMatrix = enemyUnitMatrix
	if !attacker.isPlayer:
		checkingMatrix = playerUnitMatrix
	
	var curRow = attacker.coords.y
	var curCol = attacker.coords.x
	
	var checkColCount = attacker.data.attackRange - curCol
	if fromBack:
		checkColCount = checkingMatrix.size()
	
	for col_offset in range(checkColCount):
		if fromBack:
			col_offset = -1 - col_offset
			
		var checkingColumn = checkingMatrix[col_offset]
		for i in range(checkingColumn.size()):
			var upper: Unit = null
			var lower: Unit = null
			
			if curRow + i < matrixHeight:
				lower = checkingColumn[curRow + i]
			if curRow - i >= 0:
				upper = checkingColumn[curRow - i]
			
			# both exists return the one that has lower HP
			if upper != null and lower != null:
				if upper.currentHealthPoints < lower.currentHealthPoints:
					return upper
				elif upper.currentHealthPoints > lower.currentHealthPoints:
					return lower
				else:
					# return random one
					var rng = randi()
					if rng%2 == 0:
						return upper
					else:
						return lower
			else:
				if upper != null:
					return upper
				if lower != null:
					return lower
	
	return null
	

static func AddReserveUnit(data: UnitData, isPlayer: bool):
	var newUnit = Unit.new(isPlayer, data, null)
	if isPlayer:
		playerReserves.append(newUnit)
		userInterface.ImportReserve(playerReserves)
	else:
		enemyReserves.append(newUnit)
		userInterface.ImportReserve(enemyReserves)
	

static func UnitCount(unitMatrix):
	var output = 0
	for i in range(unitMatrix.size()):
		for j in range(unitMatrix[i].size()):
			if unitMatrix[i][j] != null:
				output += 1
	
	return output


# go through the unit matrix and unassign dead units
static func ClearDeadUnits(unitMatrix):
	for i in range(unitMatrix.size()):
		for j in range(unitMatrix[i].size()):
			if unitMatrix[i][j] != null:
				if unitMatrix[i][j].currentHealthPoints <= 0:
					unitMatrix[i][j].unit_died.emit()
					unitMatrix[i][j] = null


# remove unit from unit matrix
# returns true if unit was removed successfully
# false if unit was not found
static func RemoveUnit(unit: Unit):
	var mat = playerUnitMatrix
	if !unit.isPlayer:
		mat = enemyUnitMatrix
	
	for col in mat:
		for row in range(col.size()):
			if col[row] == unit:
				col[row] = null
				return true
	
	return false


static func RemoveUnitFromReserve(unit: Unit):
	var reserve = playerReserves
	if !unit.isPlayer:
		reserve = enemyReserves
	
	var loc = reserve.find(unit)
	if loc < 0:
		return false
	else:
		reserve.remove_at(loc)
		return true
		
		
static func ResetFunds():
	playerFunds = 0
	enemyFunds = 0
	
	
func AddIncome(toPlayer: bool):
	var _playerDist = playerCapturedSectorsCount
	var _enemyDist = totalSectorsCount - playerCapturedSectorsCount
	
	var amount: int = baseIncomeAmount + battleCount
	var battleCountBonus: int = battleCount
	
	# interest bonus
	var pastAmount = GameManager.playerFunds
	if !toPlayer:
		pastAmount = GameManager.enemyFunds
		
	var interest = int(pastAmount * GameManager.interestRate)
	interest = min(interest, GameManager.maxInterest)
	amount += interest
	
	# distance from capital bonus
	var captureBonus: int = 0
	var difference: int = _playerDist - _enemyDist
	if _playerDist > _enemyDist and toPlayer:
		captureBonus = _playerDist - _enemyDist
	if _playerDist < _enemyDist and !toPlayer:
		captureBonus = _enemyDist - _playerDist
		difference *= -1
		
	captureBonus/=2
	amount += captureBonus
	
	GameManager.ChangeFunds(baseIncomeAmount + battleCount + interest + captureBonus, toPlayer)
	
	# record stats
	if toPlayer:
		GameManager.playerTotalFunds += amount
	else:
		GameManager.enemyTotalFunds += amount
		
	userInterface.SetFundsLabel(toPlayer)
	var incomeBreakup = "Income: +{total}\nBase: +{base} | Battle Count({count}): +{countbonus} | Capture({capdiff}): +{cap} |  interest({intrpc}): +{intr}"
	incomeBreakup = incomeBreakup.format({
		"total":amount,
		"base":baseIncomeAmount, 
		"count":battleCount, "countbonus":battleCountBonus,
		"capdiff":difference/2, "cap":captureBonus,
		"intrpc":str(int(GameManager.interestRate * 100)) + "%", "intr":interest})
	userInterface.SetLastIncomeLabel(incomeBreakup)
	
	if toPlayer:
		GameManager.playerIncomeHistory.append(amount)
	else:
		GameManager.enemyIncomeHistory.append(amount)
	
	GameManager.RecordFundsHistory(toPlayer)
	GameManager.RecordTotalFundsHistory(toPlayer)
	
	UpdateFundsGraph()
	
	print(GameManager.playerIncomeHistory)
	print(GameManager.playerFundsHistory)
	print(GameManager.playerTotalFundsHistory)


static func ChangeFunds(amount, isPlayer: bool = true):
	if isPlayer:
		playerFunds += amount
		print("changed player funds by " + str(amount))
		print("New value: " + str(playerFunds) + "\n")
	else:
		enemyFunds += amount
		print("changed enemy funds by " + str(amount))
		print("New value: " + str(enemyFunds) + "\n")
	
	GameManager.userInterface.MakeFundsPopup(amount)
	userInterface.SetFundsLabel(isPlayer)
	

# returns the input unit's coordinates on the unit matrix
static func GetCoord(unit):
	var checkingMatrix = enemyUnitMatrix
	if unit.isPlayer:
		checkingMatrix = playerUnitMatrix
		
	for col in range(checkingMatrix.size()):
		for row in range(checkingMatrix[0].size()):
			if checkingMatrix[col][row] == unit:
				return Vector2(col, row)
	
	return null


static func CheckCoordInsideBounds(coord: Vector2) -> bool:
	if coord.x < matrixWidth and coord.y < matrixHeight:
		if coord.x >= 0 and coord.y >= 0:
			return true
			
	return false


static func UpdateEffectiveDamageUI():
	effectiveDamageUI.get_node("PlayerLabel").text = "Player Effective Damage Taken: " + str(GameManager.playerEffectiveDamage)
	effectiveDamageUI.get_node("EnemyLabel").text = "Enemy Effective Damage Taken: " + str(GameManager.enemyEffectiveDamage)


static func AddEffectiveDamage(isPlayer, amount):
	if isPlayer:
		GameManager.playerEffectiveDamage += amount
	else:
		GameManager.enemyEffectiveDamage += amount
		
	UpdateEffectiveDamageUI()


# does doStuff to all units inside unitMatrix
static func ProcessUnitMatrix(unitMatrix, doStuff: Callable):
	for col in unitMatrix:
		for unit in col:
			doStuff.call(unit)


# swap attack and defense based on battle result
static func BattleResultProcess(attackerVictory: bool):
	if attackerVictory == true and playerAttacking == true:
		UpdateBattleResultLabel(true, true)
	if attackerVictory == false and playerAttacking == true:
		UpdateBattleResultLabel(false, false)
	if attackerVictory == true and playerAttacking == false:
		UpdateBattleResultLabel(false, true)
	if attackerVictory == false and playerAttacking == false:
		UpdateBattleResultLabel(true, false)
	
	if attackerVictory:
		if playerAttacking:
			# capture territory
			# keep attacking
			playerCapturedSectorsCount += 1
			
			# defender starts
			isPlayerTurn = false
		else:
			playerCapturedSectorsCount -= 1
			
			# defender starts
			isPlayerTurn = true
		
		captureStatusUI.ReloadUI(playerCapturedSectorsCount)
		
		print("Capture status: " + str(playerCapturedSectorsCount) + " / " + str(totalSectorsCount - playerCapturedSectorsCount))
		if playerCapturedSectorsCount == totalSectorsCount:
			print("player wins game!")
		if playerCapturedSectorsCount == 0:
			print("enemy wins game!")
		if battleCount == maxBattleCount:
			if playerCapturedSectorsCount == totalSectorsCount - playerCapturedSectorsCount:
				print("Draw!")
			elif playerCapturedSectorsCount > totalSectorsCount - playerCapturedSectorsCount:
				print("player wins game!")
			else:
				print("Enemy wins game!")
						
	else:
		# switch initiatives
		playerAttacking = !playerAttacking
		if playerAttacking:
			isPlayerTurn = false
			# defender goes first
		else:
			isPlayerTurn = true


func CommitButtonPressed():
	UnitCard.selected = null
	userInterface.UpdateHealButtonLabel()
	userInterface.UpdateSellButtonLabel()
	
	SetBoughtThisTurn(isPlayerTurn)
	
	if !playerAttacking:
		if isPlayerTurn:
			# save reserve
			playerReserves = userInterface.ExportReserve()
			
			# start enemy offense turn
			userInterface.turnTimer.start(turnTime)
			# set attack dir to right
			userInterface.SetAttackDirectionUI(false)
			
			# read in unit matrix
			userInterface.ExportUnitMatrix(playerUnitMatrix, false)
			isPlayerTurn = false
			userInterface.GenerateReinforcementOptions(isPlayerTurn, GameManager.reinforcementCount)
			AddIncome(isPlayerTurn)
			userInterface.ImportUnitMatrix(enemyUnitMatrix, playerUnitMatrix, 0)
			userInterface.ImportReserve(enemyReserves)
			
			userInterface.SetSlotAvailability(0, matrixWidth)
			userInterface.SetSlotColor(isPlayerTurn, playerAttacking)
		else:
			# save reserve
			enemyReserves = userInterface.ExportReserve()
			
			# read in unit matrix
			userInterface.ExportUnitMatrix(enemyUnitMatrix, false)
			userInterface.SetSlotAvailability(0, matrixWidth)
			
			print("attacker finished turn. Start cycle process.")
			isPlayerTurn = true
			userInterface.SetTurnLabel(true)
			_on_battle_process_button_pressed()
	else:
		if !isPlayerTurn:
			# start player offense turn
			userInterface.turnTimer.start(turnTime)
			# set attack dir ui to right
			userInterface.SetAttackDirectionUI(false)
			
			# read in unit matrix
			userInterface.ExportUnitMatrix(enemyUnitMatrix, false)
			isPlayerTurn = true
			userInterface.GenerateReinforcementOptions(isPlayerTurn, GameManager.reinforcementCount)
			AddIncome(isPlayerTurn)
			userInterface.ImportUnitMatrix(playerUnitMatrix, enemyUnitMatrix, 0)
			userInterface.ImportReserve(playerReserves)
			
			userInterface.SetSlotAvailability(0, matrixWidth)
			userInterface.SetSlotColor(isPlayerTurn, playerAttacking)
		else:
			# read in unit matrix
			userInterface.ExportUnitMatrix(playerUnitMatrix, false)
			userInterface.SetSlotAvailability(0, matrixWidth)
			
			print("attacker finished turn. Start cycle process.")
			isPlayerTurn = true
			userInterface.SetTurnLabel(true)
			_on_battle_process_button_pressed()
	
	userInterface.SetTurnLabel(isPlayerTurn)
	userInterface.SetSlotColor(isPlayerTurn, playerAttacking)


func SetBoughtThisTurn(player: bool):
	var targetList = playerReserves
	if !player:
		targetList = enemyReserves
		
	for unit: Unit in targetList:
		unit.boughtThisTurn = false
	
	# save initial coords inside unit matrix
	var MakeUsed = func(unit):
		if unit is Unit:
			unit.boughtThisTurn = false
	
	if player:
		GameManager.ProcessUnitMatrix(playerUnitMatrix, MakeUsed)
	else:
		GameManager.ProcessUnitMatrix(enemyUnitMatrix, MakeUsed)
	
	
func PassButtonPressed():
	UnitCard.selected = null
	userInterface.UpdateHealButtonLabel()
	userInterface.UpdateSellButtonLabel()
	
	SetBoughtThisTurn(isPlayerTurn)
	
	userInterface.turnTimer.stop()
	
	GameManager.playerEffectiveDamage = 0
	GameManager.enemyEffectiveDamage = 0
	GameManager.UpdateEffectiveDamageUI()
	
	GameManager.battleCount+= 1
	$BattleCountLabel.text = "Battle: " + str(GameManager.battleCount)
	print("Battle #" + str(GameManager.battleCount))
	
	# player attack pass
	if isPlayerTurn:
		lastBattleResult = 1	# update battle result
		var resultLabel = $BattleResultLabel
		resultLabel.visible = true
		# player victory
		if lastBattleResult == -1:
			if playerAttacking:
				resultLabel.text = "Player Offensive Victory"
			else:
				resultLabel.text = "Player Defensive Victory"
		elif lastBattleResult == 0:
			if playerAttacking:
				resultLabel.text = "Draw. Defensive Victory"
			else:
				resultLabel.text = "Draw. Defensive Victory"
		# enemy victory
		elif lastBattleResult == 1:
			if !playerAttacking:
				resultLabel.text = "Enemy Offensive Victory"
			else:
				resultLabel.text = "Enemy Defensive Victory"
				
		if playerAttacking:
			print("Player passed attacking.")
			# conclude this battle as enemy defensive win
			# switch offense defense
			GameManager.BattleResultProcess(false)
		else:
			print("Player passed defending.")
			# add income since we are skipping attacker's turn
			AddIncome(false)
			GameManager.BattleResultProcess(true)
	else:
		lastBattleResult = -1	# update battle result
		var resultLabel = $BattleResultLabel
		resultLabel.visible = true
		# player victory
		if lastBattleResult == -1:
			if playerAttacking:
				resultLabel.text = "Player Offensive Victory"
			else:
				resultLabel.text = "Player Defensive Victory"
		elif lastBattleResult == 0:
			if playerAttacking:
				resultLabel.text = "Draw. Defensive Victory"
			else:
				resultLabel.text = "Draw. Defensive Victory"
		# enemy victory
		elif lastBattleResult == 1:
			if !playerAttacking:
				resultLabel.text = "Enemy Offensive Victory"
			else:
				resultLabel.text = "Enemy Defensive Victory"
				
		# enemy attack pass
		if !playerAttacking:
			print("Enemy passed attacking.")
			GameManager.BattleResultProcess(false)
		else:
			print("Enemy passed defending.")
			# add income since we are skipping attacker's turn
			AddIncome(true)
			GameManager.BattleResultProcess(true)
			
	# start next battle preparation phase
	userInterface.SetTurnLabel(isPlayerTurn)
	userInterface.SetSlotColor(isPlayerTurn, playerAttacking)

	GameManager.HealUnits()
	# defending player goes first
	# set attack dir ui to left
	userInterface.SetAttackDirectionUI(true)
	
	if !playerAttacking:
		isPlayerTurn = true
		userInterface.ImportUnitMatrix(playerUnitMatrix, enemyUnitMatrix, 0)
		userInterface.ImportReserve(playerReserves)
	else:
		isPlayerTurn = false
		userInterface.ImportUnitMatrix(enemyUnitMatrix, playerUnitMatrix, 0)
		userInterface.ImportReserve(enemyReserves)
		
	userInterface.GenerateReinforcementOptions(isPlayerTurn, reinforcementCount)
	
	userInterface.SetSlotColor(isPlayerTurn, playerAttacking)
	
	cycleCount = 0
	
	# start next turn
	AddIncome(isPlayerTurn)
	userInterface.turnTimer.start(turnTime)
	
	
static func PrintUnitMatrix(unitMatrix):
	var output = ""
	var count = 0
	
	for col in unitMatrix:
		count += 1
		var line = str(count)
		for item in col:
			if item != null:
				line += "o"
			else:
				line += "x"
		output += line + "\n"
	
	print(output)


static func EditorCoordsToMatrixCoords(editorCoords: Vector2, includeMiddle: bool = false):
	if includeMiddle == false:
		var colCount = matrixWidth * 2 + 1
		return Vector2(-(editorCoords.x - (int(colCount / 2) - 1)), editorCoords.y)


static func GetUnitsInMatrix(matrix):
	var output = []
	for col in range(matrix.size()):
		for row in range(matrix[col].size()):
			if matrix[col][row] != null:
				print("added unit")
				output.append(matrix[col][row])
	
	return output


func UpdateCTKLabel():
	var label = $CTKLabel
	label.text = "player: " + str(EnemyAI_MinMax.CalculateWholeCTK(playerUnitMatrix, enemyUnitMatrix))
	label.text += "\nenemy: " + str(EnemyAI_MinMax.CalculateWholeCTK(enemyUnitMatrix, playerUnitMatrix))


# take a snap shot of current funds n record it
static func RecordFundsHistory(player):
	if player:
		GameManager.playerFundsHistory.append(GameManager.playerFunds)
	else:
		GameManager.enemyFundsHistory.append(GameManager.enemyFunds)


static func RecordTotalFundsHistory(player):
	if player:
		GameManager.playerTotalFundsHistory.append(GameManager.playerTotalFunds)
	else:
		GameManager.enemyTotalFundsHistory.append(GameManager.enemyTotalFunds)


# load the current data onto the graph
func UpdateFundsGraph():
	var fundsButton: Button = $EconomyUI/FundsButton
	fundsButton = fundsButton.button_group.get_pressed_button()
	if fundsButton != null:
		_on_economy_ui_buttton_pressed(fundsButton.num)
		

func _on_economy_ui_buttton_pressed(extra_arg_0):
	GameManager.fundsGraph.remove_all()
	
	match extra_arg_0:
		# funds
		0:
			if !isPlayerTurn:
				var fundsPlot: PlotItem = GameManager.fundsGraph.add_plot_item("Player Funds", playerColor)
				for i in playerFundsHistory.size():
					fundsPlot.add_point(Vector2(i, playerFundsHistory[i]))
				fundsPlot = GameManager.fundsGraph.add_plot_item("Enemy Funds", enemyColor)
				for i in enemyFundsHistory.size():
					fundsPlot.add_point(Vector2(i, enemyFundsHistory[i]))
				FitGraph(GameManager.fundsGraph, enemyFundsHistory)
			else:				
				var fundsPlot: PlotItem = GameManager.fundsGraph.add_plot_item("Enemy Funds", enemyColor)
				for i in enemyFundsHistory.size():
					fundsPlot.add_point(Vector2(i, enemyFundsHistory[i]))
				fundsPlot = GameManager.fundsGraph.add_plot_item("Player Funds", playerColor)
				for i in playerFundsHistory.size():
					fundsPlot.add_point(Vector2(i, playerFundsHistory[i]))
				FitGraph(GameManager.fundsGraph, playerFundsHistory)
				
		# income
		1:
			if !isPlayerTurn:
				var fundsPlot: PlotItem = GameManager.fundsGraph.add_plot_item("Player Income", playerColor)
				for i in playerIncomeHistory.size():
					fundsPlot.add_point(Vector2(i, playerIncomeHistory[i]))
				fundsPlot = GameManager.fundsGraph.add_plot_item("Enemy Income", enemyColor)
				for i in enemyIncomeHistory.size():
					fundsPlot.add_point(Vector2(i, enemyIncomeHistory[i]))
				
				FitGraph(GameManager.fundsGraph, enemyIncomeHistory)
			else:
				var fundsPlot: PlotItem = GameManager.fundsGraph.add_plot_item("Enemy Income", enemyColor)
				for i in enemyIncomeHistory.size():
					fundsPlot.add_point(Vector2(i, enemyIncomeHistory[i]))
				fundsPlot = GameManager.fundsGraph.add_plot_item("Player Income", playerColor)
				for i in playerIncomeHistory.size():
					fundsPlot.add_point(Vector2(i, playerIncomeHistory[i]))
				
				FitGraph(GameManager.fundsGraph, playerIncomeHistory)
		# total funds
		2:
			# add current turn side later so it shows up top
			if !isPlayerTurn:
				var fundsPlot: PlotItem = GameManager.fundsGraph.add_plot_item("Player Total Funds", playerColor)
				for i in playerTotalFundsHistory.size():
					fundsPlot.add_point(Vector2(i, playerTotalFundsHistory[i]))
				fundsPlot = GameManager.fundsGraph.add_plot_item("Enemy Total Funds", enemyColor)
				for i in enemyTotalFundsHistory.size():
					fundsPlot.add_point(Vector2(i, enemyTotalFundsHistory[i]))
				FitGraph(GameManager.fundsGraph, enemyTotalFundsHistory)
			else:
				var fundsPlot: PlotItem = GameManager.fundsGraph.add_plot_item("Enemy Total Funds", enemyColor)
				for i in enemyTotalFundsHistory.size():
					fundsPlot.add_point(Vector2(i, enemyTotalFundsHistory[i]))
				fundsPlot = GameManager.fundsGraph.add_plot_item("Player Total Funds", playerColor)
				for i in playerTotalFundsHistory.size():
					fundsPlot.add_point(Vector2(i, playerTotalFundsHistory[i]))
				FitGraph(GameManager.fundsGraph, playerTotalFundsHistory)


func FitGraph(graph: Graph2D, data):
	graph.x_max = data.size() + 1
	graph.x_min = 0
	
	var ymax = -1
	for i in data.size():
		if data[i] + 5 > ymax:
			ymax = data[i] + 5
			
	graph.y_max = ymax
