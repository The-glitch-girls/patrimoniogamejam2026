extends Control

const IMAGEN_FINAL_MAR := preload("res://assets/cinematicas/final_mar.png")
const AUDIO_FINAL_MAR := preload("res://sfx/final/final_mar.ogg")

func _ready() -> void:
	var es_final_cuniraya: bool = Global.resultado_final == "cuniraya"
	var es_final_mar: bool = Global.resultado_final == "mar"
	if es_final_mar:
		$ImagenFinal.texture = IMAGEN_FINAL_MAR
	$ImagenFinal.visible = true
	$ReiniciarBtn.visible = es_final_cuniraya
	$ReiniciarLbl.visible = es_final_cuniraya
	if es_final_cuniraya:
		$ReiniciarBtn.visible = false
		$ReiniciarLbl.visible = false
	$AudioFinal.stop()
	if es_final_cuniraya:
		$ReiniciarLbl.text = Traducciones.obtener("restart")
		$ReiniciarLbl.add_theme_color_override("font_color", Color.WHITE)
		$ReiniciarLbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$ReiniciarBtn.pressed.connect(_reintentar_cuniraya)
		Traducciones.idioma_cambiado.connect(_actualizar_etiqueta_reiniciar)
		$AudioFinal.play()
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid($ReiniciarBtn) and is_instance_valid($ReiniciarLbl):
			$ReiniciarBtn.visible = true
			$ReiniciarLbl.visible = true
	elif es_final_mar:
		$AudioFinal.stream = AUDIO_FINAL_MAR
		$AudioFinal.play()
		_transicionar_a_creditos_finales()


func _reintentar_cuniraya() -> void:
	Global.resetear()
	Musica.tocar("juego")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _actualizar_etiqueta_reiniciar(_idioma: String = "") -> void:
	$ReiniciarLbl.text = Traducciones.obtener("restart")


func _transicionar_a_creditos_finales() -> void:
	await get_tree().create_timer(5.0).timeout
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/CreditosFinales.tscn")
