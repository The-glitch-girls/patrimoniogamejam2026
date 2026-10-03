extends CanvasLayer

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const ICONO_ENERGIA := preload("res://assets/icons/energia.svg")
const ICONO_PRESENCIA := preload("res://assets/icons/presencia.svg")
const ICONO_AJUSTES := preload("res://assets/icons/ajustes.svg")
const CREMA := Color(0.99, 0.96, 0.9, 1)
const MORADO := Color(0.22, 0.2, 0.42, 0.92)
const VERDE := Color(0.49, 0.76, 0.29, 1)
const LILA := Color(0.67, 0.62, 0.93, 1)
const DORADO := Color(0.86, 0.7, 0.2, 1)
const BORDO := Color(0.62, 0.24, 0.36, 1)
const NARANJA_CUEVA := Color(1.0, 0.58, 0.24, 1)

var prompt_alpha := 0.0
var prompt_texto := ""
var material_oscuridad: ShaderMaterial
var icono_presencia: TextureRect
var marco_presencia: Panel
var barra_energia: ProgressBar
var barra_presencia: ProgressBar
var velo_ajustes: ColorRect
var panel_ajustes: Panel
var marcas_recuerdo: Array[Panel] = []
var guia_bebe: Control
var guia_fondo: Panel
var guia_flecha: FlechaGuia
var guia_metros: Label
var guia_alpha := 0.0
var guia_colocada := false
var guia_cueva: Control
var guia_flecha_cueva: FlechaGuia
var guia_metros_cueva: Label
var guia_alpha_cueva := 0.0
var guia_cueva_colocada := false

@onready var sonido_tension: AudioStreamPlayer2D = $SonidoTension
@onready var peak_tension: AudioStreamPlayer2D = $PeakTension
@onready var llanto_bebe: AudioStreamPlayer2D = $LlantoBebe
var volumen_normal_tension: float = -15.0
var volumen_normal_peak: float = 0.0
var volumen_normal_llanto: float = 0.0
var temporizador_peak: float = 0.0
var temporizador_llanto: float = 0.0


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_estilar_panel()
	_estilar_textos()
	_estilar_prompt()
	_estilar_pildora($AvisoFondo, VERDE)
	_poner_guia_bebe()
	_poner_guia_cueva()
	_poner_ajustes()
	if not Global.partida_terminada:
		Musica.tocar("juego")
	$Oscuridad.set_anchors_preset(Control.PRESET_FULL_RECT)
	material_oscuridad = $Oscuridad.material as ShaderMaterial
	if OS.get_cmdline_user_args().has("--hudshot"):
		_capturar()
	elif OS.get_cmdline_user_args().has("--flashshot"):
		_capturar_flashback()
	elif OS.get_cmdline_user_args().has("--guiashot"):
		_capturar_guia()


func _estilar_panel():
	$PanelEstado.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	$PanelEstado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for nodo in [
		$PanelEstado/Encabezado,
		$PanelEstado/Label,
		$PanelEstado/PresenciaLabel,
		$PanelEstado/TiempoLabel,
		$PanelEstado/BebeLabel,
		$PanelEstado/ZonaLabel,
		$PanelEstado/RecuerdosLabel,
	]:
		nodo.visible = false
	if has_node("PresenciaLabel"):
		$PresenciaLabel.visible = false
	_poner_icono(ICONO_ENERGIA, Vector2(16, 16), VERDE)
	barra_energia = $PanelEstado/EnergiaBar
	_envolver_barra(barra_energia, Vector2(60, 20), VERDE)
	icono_presencia = _poner_icono(ICONO_PRESENCIA, Vector2(16, 60), LILA)
	barra_presencia = $PanelEstado/PresenciaBar
	marco_presencia = _envolver_barra(barra_presencia, Vector2(60, 64), LILA)
	_mostrar_presencia(false)
	_poner_recuerdos()

func _poner_icono(textura: Texture2D, pos: Vector2, color: Color) -> TextureRect:
	var circulo := Panel.new()
	circulo.position = pos
	circulo.size = Vector2(36, 36)
	circulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circulo.add_theme_stylebox_override("panel", _circulo(color))
	$PanelEstado.add_child(circulo)
	var icono := TextureRect.new()
	icono.texture = textura
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icono.set_anchors_preset(Control.PRESET_CENTER)
	icono.offset_left = -11
	icono.offset_top = -11
	icono.offset_right = 11
	icono.offset_bottom = 11
	circulo.add_child(icono)
	return icono


func _circulo(color: Color, radio: int = 36) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = color
	caja.set_corner_radius_all(radio)
	caja.set_border_width_all(4)
	caja.border_color = Color.WHITE
	caja.shadow_color = Color(0, 0, 0, 0.22)
	caja.shadow_size = 8
	caja.shadow_offset = Vector2(0, 4)
	return caja


func _estilar_prompt() -> void:
	for nodo in [$PromptFondo, $PromptLabel]:
		nodo.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		nodo.offset_left = -76
		nodo.offset_top = -76
		nodo.offset_right = -20
		nodo.offset_bottom = -20
	$PromptFondo.add_theme_stylebox_override("panel", _circulo(VERDE, 56))
	_texto($PromptLabel, 22)
	$PromptLabel.text = "E"


func _envolver_barra(barra: ProgressBar, pos: Vector2, color: Color) -> Panel:
	var marco := Panel.new()
	marco.position = pos
	marco.size = Vector2(196, 28)
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.add_theme_stylebox_override("panel", _tarjeta(MORADO, 14))
	$PanelEstado.add_child(marco)
	barra.reparent(marco)
	barra.set_anchors_preset(Control.PRESET_FULL_RECT)
	barra.offset_left = 6
	barra.offset_top = 6
	barra.offset_right = -6
	barra.offset_bottom = -6
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(8)
	barra.add_theme_stylebox_override("fill", fill)
	barra.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	barra.show_percentage = false
	return marco


func _mostrar_presencia(es_visible: bool) -> void:
	icono_presencia.get_parent().visible = es_visible
	marco_presencia.visible = es_visible
	barra_presencia.visible = es_visible


func _poner_recuerdos() -> void:
	var recuerdos_container := $RecuerdosContainer
	recuerdos_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	var viewport_size := get_viewport().get_visible_rect().size

	recuerdos_container.position = Vector2(
		viewport_size.x - 280,
		20
	)

func _marca_recuerdo(lleno: bool) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = DORADO if lleno else MORADO
	caja.set_corner_radius_all(22)
	caja.set_border_width_all(3)
	caja.border_color = Color.WHITE
	caja.shadow_color = Color(0, 0, 0, 0.18)
	caja.shadow_size = 4
	caja.shadow_offset = Vector2(0, 2)
	return caja


func _actualizar_recuerdos() -> void:
	$RecuerdosContainer/RecuerdosContador.text = str(Global.recuerdos_obtenidos)
	$RecuerdosContainer/star_1.visible = Global.recuerdos_obtenidos >= 1
	$RecuerdosContainer/star_2.visible = Global.recuerdos_obtenidos >= 2
	$RecuerdosContainer/star_3.visible = Global.recuerdos_obtenidos >= 3


func _estilar_textos():
	_texto($PromptLabel, 16)
	_texto($AvisoLabel, 18)


func _texto(label: Label, tamano: int) -> void:
	label.add_theme_font_override("font", FUENTE)
	label.add_theme_font_size_override("font_size", tamano)
	label.add_theme_color_override("font_color", CREMA)


func _ajustar_banner_aviso() -> void:
	var label := $AvisoLabel as Label
	var fondo := $AvisoFondo as Panel
	var tamano_fuente := label.get_theme_font_size("font_size")
	var fuente := label.get_theme_font("font")
	var ancho_texto := fuente.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano_fuente).x
	var alto_texto := fuente.get_height(tamano_fuente)
	var ancho_banner := ancho_texto + 40.0
	var alto_banner := alto_texto + 20.0

	fondo.offset_left = -ancho_banner * 0.5
	fondo.offset_right = ancho_banner * 0.5
	fondo.offset_bottom = fondo.offset_top + alto_banner
	label.offset_left = -ancho_texto * 0.5
	label.offset_right = ancho_texto * 0.5
	label.offset_top = fondo.offset_top + 10.0
	label.offset_bottom = label.offset_top + alto_texto


func _tarjeta(color: Color, radio: int) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = color
	caja.set_corner_radius_all(radio)
	caja.set_border_width_all(4)
	caja.border_color = Color.WHITE
	caja.shadow_color = Color(0, 0, 0, 0.22)
	caja.shadow_size = 8
	caja.shadow_offset = Vector2(0, 4)
	return caja


func _estilar_pildora(panel: Panel, color: Color):
	panel.add_theme_stylebox_override("panel", _tarjeta(color, 22))

func _metros_hasta(pixeles: float) -> int:
	var metros := pixeles / 2.2
	if metros < 15.0:
		return maxi(int(round(metros)), 1)
	return int(round(metros / 10.0) * 10.0)


func _borde_de(origen: Vector2, destino: Vector2, zona: Rect2) -> Vector2:
	var dir := destino - origen
	var mejor := INF
	var punto := zona.get_center()
	if absf(dir.x) > 0.001:
		var tx := (zona.position.x - origen.x) / dir.x if dir.x < 0.0 else (zona.end.x - origen.x) / dir.x
		if tx > 0.0:
			var y := origen.y + dir.y * tx
			if y >= zona.position.y and y <= zona.end.y and tx < mejor:
				mejor = tx
				punto = origen + dir * tx
	if absf(dir.y) > 0.001:
		var ty := (zona.position.y - origen.y) / dir.y if dir.y < 0.0 else (zona.end.y - origen.y) / dir.y
		if ty > 0.0 and ty < mejor:
			var x := origen.x + dir.x * ty
			if x >= zona.position.x and x <= zona.end.x:
				punto = origen + dir * ty
	return punto


func _poner_ajustes() -> void:
	var boton := BotonCirculo.new()
	boton.color_fondo = DORADO
	boton.icono = ICONO_AJUSTES
	boton.tamano = 52.0
	boton.pressed.connect(_alternar_ajustes)
	add_child(boton)
	boton.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	boton.offset_left = -72
	boton.offset_top = 16
	boton.offset_right = -20
	boton.offset_bottom = 68

	velo_ajustes = ColorRect.new()
	velo_ajustes.visible = false
	velo_ajustes.color = Color(0.08, 0.06, 0.16, 0.55)
	velo_ajustes.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo_ajustes.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo_ajustes)

	panel_ajustes = Panel.new()
	panel_ajustes.visible = false
	panel_ajustes.set_anchors_preset(Control.PRESET_CENTER)
	panel_ajustes.offset_left = -220
	panel_ajustes.offset_top = -210
	panel_ajustes.offset_right = 220
	panel_ajustes.offset_bottom = 210
	panel_ajustes.add_theme_stylebox_override("panel", _tarjeta(MORADO, 28))
	add_child(panel_ajustes)

	var titulo := Label.new()
	titulo.text = "Sonido"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(24, 20)
	titulo.size = Vector2(392, 36)
	_texto(titulo, 28)
	panel_ajustes.add_child(titulo)

	var filas := [
		["Master", Ajustes.volumen_master, Ajustes.set_volumen_master],
		["Musica", Ajustes.volumen_musica, Ajustes.set_volumen_musica],
		["Efectos", Ajustes.volumen_efectos, Ajustes.set_volumen_efectos],
		["Ambiente", Ajustes.volumen_ambiente, Ajustes.set_volumen_ambiente],
	]
	var y := 72.0
	for fila in filas:
		var etiqueta := Label.new()
		etiqueta.text = fila[0]
		etiqueta.position = Vector2(32, y)
		etiqueta.size = Vector2(376, 24)
		_texto(etiqueta, 16)
		panel_ajustes.add_child(etiqueta)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = fila[1]
		slider.position = Vector2(32, y + 28)
		slider.size = Vector2(376, 24)
		slider.value_changed.connect(fila[2])
		panel_ajustes.add_child(slider)
		y += 72
	move_child(boton, -1)


func _alternar_ajustes() -> void:
	if panel_ajustes.visible:
		_cerrar_ajustes()
	else:
		_abrir_ajustes()


func _abrir_ajustes() -> void:
	velo_ajustes.visible = true
	panel_ajustes.visible = true
	get_tree().paused = true


func _cerrar_ajustes() -> void:
	velo_ajustes.visible = false
	panel_ajustes.visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and panel_ajustes.visible:
		_cerrar_ajustes()
		get_viewport().set_input_as_handled()


func _capturar():
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var cavillaca := get_tree().get_first_node_in_group("cavillaca")
	if cavillaca:
		cavillaca._recoger_bebe()
	Global.recuerdos_obtenidos = 2
	_actualizar_recuerdos()
	await get_tree().create_timer(0.55).timeout
	var imagen := get_viewport().get_texture().get_image()
	imagen.save_png("screenshot_hud.png")
	get_tree().quit()


func _capturar_guia() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var imagen := get_viewport().get_texture().get_image()
	imagen.save_png("screenshot_guia.png")
	get_tree().quit()


func _capturar_flashback() -> void:
	var flashback := preload("res://scenes/Flashback.tscn").instantiate()
	flashback.configurar(1)
	add_child(flashback)
	await get_tree().create_timer(0.5).timeout
	var imagen := get_viewport().get_texture().get_image()
	imagen.save_png("screenshot_flashback.png")
	get_tree().quit()


func _process(delta):
	barra_energia.value = Global.energia
	barra_presencia.value = Global.presencia_cuniraya
	_mostrar_presencia(Global.presencia_cuniraya > 0.5)
	_actualizar_recuerdos()
	_actualizar_guia_bebe(delta)
	_actualizar_guia_cueva(delta)

	if Global.prompt_interaccion != "":
		if prompt_texto != Global.prompt_interaccion:
			var es_ataque := Global.prompt_interaccion.begins_with("ESPACIO")
			$PromptFondo.add_theme_stylebox_override("panel", _circulo(BORDO if es_ataque else VERDE, 56))
			$PromptLabel.text = "E"
		prompt_texto = Global.prompt_interaccion

	var destino_alpha := 1.0 if Global.prompt_interaccion != "" else 0.0
	prompt_alpha = move_toward(prompt_alpha, destino_alpha, delta * 8.0)
	$PromptLabel.modulate.a = prompt_alpha
	$PromptFondo.modulate.a = prompt_alpha

	var hay_aviso := Global.aviso_combate != ""
	$AvisoLabel.text = Global.aviso_combate
	$AvisoFondo.visible = hay_aviso
	$AvisoLabel.visible = hay_aviso
	if hay_aviso:
		_ajustar_banner_aviso()
		var color_aviso := VERDE if Global.aviso_combate == "Victoria" else BORDO
		_estilar_pildora($AvisoFondo, color_aviso)

	var nivel_presencia : float = Global.presencia_cuniraya
	var volumen_tension : float = lerp(-10.0, 0.0, nivel_presencia / 100.0)
	material_oscuridad.set_shader_parameter("intensidad", nivel_presencia / 100.0)
	sonido_tension.volume_db = volumen_tension

	if Global.presencia_activa:
		if not sonido_tension.playing:
			sonido_tension.volume_db = volumen_normal_tension
			sonido_tension.play()
	else:
		fade_out_audio(sonido_tension, 2.5)

	if Global.presencia_activa:
		temporizador_peak -= delta
		if temporizador_peak <= 0.0 and not peak_tension.playing:
			peak_tension.volume_db = volumen_normal_peak
			peak_tension.play()
			temporizador_peak = 8.0
	else:
		fade_out_audio(peak_tension, 2.5)
		temporizador_peak = 0.0

	if Global.presencia_activa:
		temporizador_llanto -= delta
		if temporizador_llanto <= 0.0 and not llanto_bebe.playing:
			llanto_bebe.volume_db = volumen_normal_llanto
			llanto_bebe.play()
			temporizador_llanto = 45.0
	else:
		fade_out_audio(llanto_bebe, 2.5)
		temporizador_llanto = 0.0

func fade_out_audio(audio: AudioStreamPlayer2D, duracion: float) -> void:
	if not audio.playing:
		return
	var tween := create_tween()
	tween.tween_property(audio, "volume_db", -40.0, duracion)
	tween.tween_callback(func():
		audio.stop()
	)

# Guias de bebe y cueva utilizando la clase GuiaNavegacion
func _poner_guia_bebe() -> void:
	guia_bebe = GuiaNavegacion.new()

	guia_bebe.configurar(
		_tarjeta(VERDE, 22),
		"300 m",
		Vector2(132, 44),
		FUENTE,
		CREMA
	)
	
	guia_flecha = guia_bebe.flecha
	guia_metros = guia_bebe.texto
	
	$Guias.add_child(guia_bebe)

func _poner_guia_cueva() -> void:
	guia_cueva = GuiaNavegacion.new()

	guia_cueva.configurar(
		_tarjeta(NARANJA_CUEVA, 22),
		"Cueva",
		Vector2(150, 44),
		FUENTE,
		CREMA
	)
	
	guia_flecha_cueva = guia_cueva.flecha
	guia_metros_cueva = guia_cueva.texto

	$Guias.add_child(guia_cueva)

func _actualizar_guia_bebe(delta: float) -> void:
	var vista := get_viewport().get_visible_rect()

	if Global.lleva_bebe or Global.flashback_abierto or Global.partida_terminada:
		guia_bebe.actualizar(null, null, vista, delta)
		return

	var bebe := get_tree().get_first_node_in_group("bebe") as Node2D
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D

	guia_bebe.actualizar(bebe, cavillaca, vista, delta)

func _actualizar_guia_cueva(delta: float) -> void:
	var vista := get_viewport().get_visible_rect()

	if Global.flashback_abierto or Global.partida_terminada:
		guia_cueva.actualizar(null, null, vista, delta)
		return

	var cueva := get_tree().get_first_node_in_group("zona_segura") as Node2D
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D

	guia_cueva.actualizar(cueva, cavillaca, vista, delta, guia_bebe)
