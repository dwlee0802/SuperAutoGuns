extends Resource
class_name TerrainData

@export_group("Terrain Info")
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
