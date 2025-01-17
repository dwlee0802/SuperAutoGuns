extends Resource
class_name TerrainData

@export_group("Terrain Info")
@export var slotTexture: Texture = null
@export var name: String = "Null"

@export_multiline var description: String = ""

# if true does not get added to data manager
@export var disabled: bool = false

@export var color = Color.WHITE


@export_group("Stat Changes")
# how much attack range is added to unit on this slot
@export var attackRange: int = 0

# extra movement cost required to enter this slot
@export var entryCost: int = 0

# extra movement cost required when leaving this slot
@export var exitCost: int = 0


func _to_string():
	return name
