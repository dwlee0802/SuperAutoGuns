extends Node
class_name DW_ToolBox


static func RemoveAllChildren(node: Node):
	if node == null:
		return
		
	var children = node.get_children()
	for item in children:
		item.queue_free()


## assumes that count is not larger than list if duplicates is true
static func PickRandomNumber(list, count: int, duplicates: bool = true):
	var output = []
	if duplicates:
		for i in range(count):
			output.append(list.pick_random())
	else:
		list.shuffle()
		return list.slice(0,count)
