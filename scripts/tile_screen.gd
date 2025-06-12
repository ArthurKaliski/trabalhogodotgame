extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/game.tscn")


func _on_credits_btn_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/credits.tscn")


func _on_commands_btn_4_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/commands_screen.tscn")
