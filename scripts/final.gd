extends Control

const IMAGEN_FINAL_MAR := preload("res://assets/cinematicas/final_mar.png")
const AUDIO_FINAL_MAR := preload("res://sfx/final/aa_final_mar.ogg")

func _ready() -> void:
	var es_final_cuniraya: bool = Global.resultado_final == "cuniraya"
	var es_final_mar: bool = Global.resultado_final == "mar"
	if es_final_mar:
		$ImagenFinal.texture = IMAGEN_FINAL_MAR
	$ImagenFinal.visible = true
	$ReiniciarBtn.visible = es_final_cuniraya
	$ReiniciarLbl.visible = es_final_cuniraya
	_centrar_etiqueta_reiniciar()
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
		Musica.detener()
		$AudioFinal.bus = "Musica"
		$AudioFinal.volume_db = -5.0
		$AudioFinal.play()
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid($ReiniciarBtn) and is_instance_valid($ReiniciarLbl):
			$ReiniciarBtn.visible = true
			$ReiniciarLbl.visible = true
	elif es_final_mar:
		Musica.tocar_stream("final_mar", AUDIO_FINAL_MAR)
		_transicionar_a_creditos_finales()


func _reintentar_cuniraya() -> void:
	Global.resetear()
	Musica.iniciar_juego_con_tension()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _actualizar_etiqueta_reiniciar(_idioma: String = "") -> void:
	$ReiniciarLbl.text = Traducciones.obtener("restart")
	_centrar_etiqueta_reiniciar()


func _centrar_etiqueta_reiniciar() -> void:
	$ReiniciarLbl.size.x = 260.0
	$ReiniciarLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var centro_boton_x: float = $ReiniciarBtn.position.x + $ReiniciarBtn.size.x * $ReiniciarBtn.scale.x * 0.5
	$ReiniciarLbl.position.x = centro_boton_x - $ReiniciarLbl.size.x * 0.5

func _transicionar_a_creditos_finales() -> void:
	await get_tree().create_timer(5.0).timeout
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/CreditosFinales.tscn")
