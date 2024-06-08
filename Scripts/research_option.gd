extends Control
class_name ResearchOption

var data

@onready var selectButton: Button = $SelectButton

var isPlayer: bool


func SetData(_data: UnitData, purchased: bool, _player):
	data = _data
	isPlayer = _player
	
	$SelectButton.disabled = purchased
	$Icon.self_modulate = data.color
	$NameLabel.text = data.name
	
	var stats = "HP: {hq} | ATK: {atk} | AS: {as} | MS: {ms}"
	stats = stats.format({
		"hq": data.maxHealthPoints,
		"atk": data.attackDamage,
		"as": data.attackCost,
		"ms": data.movementCost
		})
	
	$StatsLabel.text = stats
	$DescriptionLabel.text = data.description
	
	if purchased:
		$SelectButton.text = data.name + " Research Complete"
	else:
		$SelectButton.text = "Research " + data.name + "(" + str(data.researchCost) + ")"
		$SelectButton.pressed.connect(OnSelected)
		
		
func OnSelected():
	if GameManager.playerFunds >= data.researchCost:
		GameManager.ChangeFunds(-data.researchCost)
		DataManager.ResearchUnit(isPlayer, data)
