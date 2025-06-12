extends Camera2D

var target: Node2D

func _ready() -> void:
	get_target()


func _process(_delta):
	if target:
		position.x = target.position.x  # segue só eixo X
		position.y = target.position.y  # ou customize para limitar movimento vertical



func get_target() -> void:
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Player not found in group")
		return
	
	target = nodes[0]
