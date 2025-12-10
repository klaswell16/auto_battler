extends Control
	

func _on_play_again_button_pressed() -> void:
	BattleContext.reset_run()
	get_tree().change_scene_to_file("res://scenes/shop.tscn")


func _on_title_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	pass # Replace with function body.
