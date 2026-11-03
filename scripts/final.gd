extends Control

const IMAGEN_FINAL_MAR := preload("res://assets/cinematicas/final_mar.png")

func _ready() -> void:
	var es_final_cuniraya: bool = Global.resultado_final == "cuniraya"
	if not es_final_cuniraya:
		$ImagenFinal.texture = IMAGEN_FINAL_MAR
	$ImagenFinal.visible = true
	$ReiniciarBtn.visible = es_final_cuniraya
	$ReiniciarLbl.visible = es_final_cuniraya
	$AudioFinal.stop()
	if es_final_cuniraya:
		$ReiniciarLbl.text = Traducciones.obtener("restart")
		$ReiniciarLbl.add_theme_color_override("font_color", Color.WHITE)
		$ReiniciarLbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$ReiniciarBtn.pressed.connect(_reintentar_cuniraya)
		Traducciones.idioma_cambiado.connect(_actualizar_etiqueta_reiniciar)
		$AudioFinal.play()
	if OS.get_cmdline_user_args().has("--finalshot"):
		_capturar()


func _capturar() -> void:
	var arbol := get_tree()
	if arbol == null:
		return
	await arbol.process_frame
	await arbol.create_timer(0.45).timeout
	var imagen := arbol.root.get_viewport().get_texture().get_image()
	imagen.save_png("screenshot_final.png")
	arbol.quit()


func _reintentar_cuniraya() -> void:
	Global.resetear()
	Musica.tocar("juego")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _actualizar_etiqueta_reiniciar(_idioma: String = "") -> void:
	$ReiniciarLbl.text = Traducciones.obtener("restart")
