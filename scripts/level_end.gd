extends Area2D

@export var next_level: String = ""  # Nome do próximo nível, sem a extensão .tscn

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		call_deferred("load_next_scene")


func load_next_scene():
	# Troca para a próxima cena
	get_tree().change_scene_to_file("res://scene/" + next_level + ".tscn")
