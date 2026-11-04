extends Node
## Escucha la acción "pausar" aunque el árbol esté pausado.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausar") and get_tree().current_scene and get_tree().current_scene.scene_file_path == "res://scenes/Main.tscn":
		Global.alternar_pausa()
		get_viewport().set_input_as_handled()
