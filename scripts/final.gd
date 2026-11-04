extends Control

const FUENTE_TEXTO := preload("res://assets/fonts/chelsea-market/ChelseaMarket-Regular.ttf")
const COLOR_TEXTO := Color("f4e9ff")
const IMAGEN_FINAL_MAR := preload("res://assets/cinematicas/final_mar.png")
const AUDIO_FINAL_MAR := preload("res://sfx/final/aa_final_mar.ogg")
const TEXTURAS_CONTINUAR := {
	"es": preload("res://assets/ui/recuerdos/continuar_es.png"),
	"en": preload("res://assets/ui/recuerdos/continuar_en.png"),
	"fr": preload("res://assets/ui/recuerdos/continuar_fr.png"),
}
const TEXTURAS_CONTINUAR_PRESIONADO := {
	"es": preload("res://assets/ui/recuerdos/continuar_es_pressed.png"),
	"en": preload("res://assets/ui/recuerdos/continuar_en_pressed.png"),
	"fr": preload("res://assets/ui/recuerdos/continuar_fr_pressed.png"),
}

var clave_texto_final := ""
var es_final_cuniraya := false
var es_final_mar := false
var continuando := false
var escribiendo_texto := false
var partes_texto: Array[String] = []
var indice_parte_texto := 0

func _ready() -> void:
	es_final_cuniraya = Global.resultado_final == "cuniraya"
	es_final_mar = Global.resultado_final == "mar"
	clave_texto_final = "final_cuniraya_text" if es_final_cuniraya else "final_sea_text"
	if es_final_mar:
		$ImagenFinal.texture = IMAGEN_FINAL_MAR
	$ImagenFinal.visible = true
	$CajaTexto.visible = es_final_cuniraya or es_final_mar
	_estilizar_texto_final()
	_actualizar_texto_final()
	Traducciones.idioma_cambiado.connect(_actualizar_texto_final)
	$Continuar.visible = false
	$Continuar.disabled = true
	$Continuar.pressed.connect(_continuar)
	$SgteTexto.visible = false
	$SgteTexto.disabled = true
	$SgteTexto.pressed.connect(_siguiente_texto)
	_actualizar_textura_continuar(Global.idioma_actual)
	Traducciones.idioma_cambiado.connect(_actualizar_textura_continuar)
	$ReiniciarBtn.visible = false
	$ReiniciarLbl.visible = false
	_centrar_etiqueta_reiniciar()
	$AudioFinal.stop()
	if es_final_cuniraya:
		$ReiniciarLbl.text = Traducciones.obtener("restart")
		$ReiniciarLbl.add_theme_font_override("font", FUENTE_TEXTO)
		$ReiniciarLbl.add_theme_font_size_override("font_size", 25)
		$ReiniciarLbl.add_theme_color_override("font_color", Color.WHITE)
		$ReiniciarLbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$ReiniciarBtn.pressed.connect(_reintentar_cuniraya)
		Traducciones.idioma_cambiado.connect(_actualizar_etiqueta_reiniciar)
		Musica.detener()
		$AudioFinal.bus = "Musica"
		$AudioFinal.volume_db = -5.0
		$AudioFinal.play()
	elif es_final_mar:
		Musica.tocar_stream("final_mar", AUDIO_FINAL_MAR)
	partes_texto = _separar_texto_en_partes($CajaTexto/Texto.text)
	_mostrar_parte_texto()


func _mostrar_resumen_derrota() -> void:
	var resumen: Control = preload("res://scripts/componentes/resumen_derrota.gd").new()
	resumen.modulate.a = 0.0
	add_child(resumen)
	create_tween().tween_property(resumen, "modulate:a", 1.0, 0.3)


func _reintentar_cuniraya() -> void:
	Global.reproducir_clic()
	Global.resetear()
	Musica.iniciar_juego_con_tension()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _actualizar_etiqueta_reiniciar(_idioma: String = "") -> void:
	$ReiniciarLbl.text = Traducciones.obtener("restart")
	_centrar_etiqueta_reiniciar()


func _actualizar_texto_final(_idioma: String = "") -> void:
	if not clave_texto_final.is_empty():
		$CajaTexto/Texto.text = Traducciones.obtener(clave_texto_final).replace("\n\n", "\n")


func _actualizar_textura_continuar(idioma: String) -> void:
	var codigo := idioma if TEXTURAS_CONTINUAR.has(idioma) else "es"
	$Continuar.texture_normal = TEXTURAS_CONTINUAR[codigo]
	$Continuar.texture_pressed = TEXTURAS_CONTINUAR_PRESIONADO[codigo]


func _estilizar_texto_final() -> void:
	var label: Label = $CajaTexto/Texto
	var estilo: LabelSettings = label.label_settings.duplicate() as LabelSettings
	estilo.font_size = 25
	label.label_settings = estilo
	label.add_theme_font_override("font", FUENTE_TEXTO)
	label.add_theme_color_override("font_color", COLOR_TEXTO)
	label.anchor_left = 0.06
	label.anchor_right = 0.94
	label.anchor_top = 0.24
	label.anchor_bottom = 0.74
	label.offset_left = 0.0
	label.offset_right = 0.0
	label.offset_top = 0.0
	label.offset_bottom = 0.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _separar_texto_en_partes(texto_completo: String) -> Array[String]:
	const MAX_CARACTERES_POR_PARTE := 180
	var parrafos: PackedStringArray = texto_completo.split("\n", false)
	var partes: Array[String] = []
	var parte_actual := ""
	for parrafo in parrafos:
		var palabras := parrafo.split(" ", false)
		var fragmento := ""
		for palabra in palabras:
			if fragmento.is_empty():
				fragmento = palabra
			elif fragmento.length() + palabra.length() + 1 <= MAX_CARACTERES_POR_PARTE:
				fragmento += " " + palabra
			else:
				parte_actual = _agregar_parrafo_a_parte(parte_actual, fragmento, MAX_CARACTERES_POR_PARTE, partes)
				fragmento = palabra
		if not fragmento.is_empty():
			parte_actual = _agregar_parrafo_a_parte(parte_actual, fragmento, MAX_CARACTERES_POR_PARTE, partes)
	if not parte_actual.is_empty():
		partes.append(parte_actual)
	return partes


func _agregar_parrafo_a_parte(parte_actual: String, fragmento: String, limite: int, partes: Array[String]) -> String:
	if parte_actual.is_empty():
		return fragmento
	if parte_actual.length() + fragmento.length() + 1 <= limite:
		return parte_actual + "\n" + fragmento
	partes.append(parte_actual)
	return fragmento


func _mostrar_parte_texto() -> void:
	if indice_parte_texto >= partes_texto.size():
		return
	escribiendo_texto = true
	$SgteTexto.visible = false
	$SgteTexto.disabled = true
	$Continuar.visible = false
	$Continuar.disabled = true
	var texto: Label = $CajaTexto/Texto
	texto.text = partes_texto[indice_parte_texto]
	texto.visible_ratio = 0.0
	var duracion := maxf(float(texto.text.length()) / 60.0, 1.0)
	var tween := create_tween()
	tween.tween_property(texto, "visible_ratio", 1.0, duracion)
	await tween.finished
	if not is_inside_tree():
		return
	escribiendo_texto = false
	if indice_parte_texto < partes_texto.size() - 1:
		$SgteTexto.disabled = false
		$SgteTexto.visible = true
		$SgteTexto.modulate.a = 0.0
		create_tween().tween_property($SgteTexto, "modulate:a", 1.0, 0.25)
		return
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	$Continuar.disabled = false
	$Continuar.modulate.a = 0.0
	$Continuar.visible = true
	create_tween().tween_property($Continuar, "modulate:a", 1.0, 0.25)


func _siguiente_texto() -> void:
	if escribiendo_texto or indice_parte_texto >= partes_texto.size() - 1:
		return
	Global.reproducir_clic()
	$SgteTexto.disabled = true
	$SgteTexto.visible = false
	indice_parte_texto += 1
	_mostrar_parte_texto()


func _continuar() -> void:
	if continuando:
		return
	continuando = true
	Global.reproducir_clic()
	$Continuar.disabled = true
	if es_final_mar:
		get_tree().change_scene_to_file("res://scenes/CreditosFinales.tscn")
		return
	$Continuar.visible = false
	var tween := create_tween()
	tween.tween_property($CajaTexto, "modulate:a", 0.0, 0.25)
	await tween.finished
	$CajaTexto.visible = false
	_centrar_etiqueta_reiniciar()
	$ReiniciarBtn.visible = true
	$ReiniciarLbl.visible = true
	if es_final_cuniraya:
		_mostrar_resumen_derrota()


func _centrar_etiqueta_reiniciar() -> void:
	$ReiniciarLbl.size.x = 260.0
	$ReiniciarLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var boton: TextureButton = $ReiniciarBtn
	var ancho_boton := boton.size.x
	var centro_x := get_viewport_rect().size.x * 0.5
	var escala_x := absf(boton.scale.x)
	boton.offset_left = centro_x - ancho_boton * escala_x * 0.5
	boton.offset_right = boton.offset_left + ancho_boton
	$ReiniciarLbl.position.x = centro_x - $ReiniciarLbl.size.x * 0.5
