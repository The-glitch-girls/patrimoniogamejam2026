extends CanvasLayer

const NARANJA := Color(0.98, 0.62, 0.14, 1)
const NARANJA_OSCURO := Color(0.9, 0.48, 0.08, 1)
const CREMA := Color(1, 0.97, 0.93, 1)
const VERDE := Color(0.42, 0.78, 0.38, 1)
const TEXTO := Color(0.42, 0.28, 0.14, 1)
const TEXTO_CLARO := Color(1, 0.98, 0.94, 1)

var prompt_alpha := 0.0
var prompt_texto := ""

func _ready():
	_estilar_panel()
	_estilar_barras()
	_estilar_textos()
	_estilar_pildora($PromptFondo, NARANJA)
	_estilar_pildora($AvisoFondo, VERDE)
	if OS.get_cmdline_user_args().has("--shot"):
		_capturar()

func _estilar_panel():
	var panel := StyleBoxFlat.new()
	panel.bg_color = CREMA
	panel.set_corner_radius_all(22)
	panel.set_border_width_all(4)
	panel.border_color = Color(1, 1, 1, 1)
	panel.shadow_color = Color(0, 0, 0, 0.18)
	panel.shadow_size = 8
	panel.shadow_offset = Vector2(0, 4)
	$PanelEstado.add_theme_stylebox_override("panel", panel)

	var encabezado := StyleBoxFlat.new()
	encabezado.bg_color = NARANJA
	encabezado.set_corner_radius_all(16)
	encabezado.corner_radius_bottom_left = 0
	encabezado.corner_radius_bottom_right = 0
	$PanelEstado/Encabezado.add_theme_stylebox_override("panel", encabezado)


func _estilar_barras():
	_pintar_barra($PanelEstado/EnergiaBar, NARANJA)


func _estilar_textos():
	for label in [
		$PanelEstado/Label,
		$PanelEstado/Label2,
		$PanelEstado/TiempoLabel,
		$PanelEstado/BebeLabel,
		$PanelEstado/ZonaLabel,
		$PanelEstado/RecuerdosLabel,
	]:
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", TEXTO)
	$PanelEstado/Encabezado/Titulo.add_theme_color_override("font_color", TEXTO_CLARO)
	$PanelEstado/Encabezado/Titulo.add_theme_font_size_override("font_size", 20)
	$PromptLabel.add_theme_font_size_override("font_size", 18)
	$PromptLabel.add_theme_color_override("font_color", TEXTO_CLARO)
	$AvisoLabel.add_theme_font_size_override("font_size", 20)
	$AvisoLabel.add_theme_color_override("font_color", TEXTO_CLARO)


func _estilar_pildora(panel: Panel, color: Color):
	var caja := StyleBoxFlat.new()
	caja.bg_color = color
	caja.set_corner_radius_all(20)
	caja.set_border_width_all(3)
	caja.border_color = Color(1, 1, 1, 1)
	caja.shadow_color = Color(0, 0, 0, 0.16)
	caja.shadow_size = 6
	caja.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", caja)


func _pintar_barra(barra: ProgressBar, color: Color):
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(10)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.93, 0.88, 0.8, 1)
	fondo.set_corner_radius_all(10)
	fondo.set_border_width_all(2)
	fondo.border_color = Color(1, 1, 1, 1)
	barra.add_theme_stylebox_override("fill", fill)
	barra.add_theme_stylebox_override("background", fondo)
	barra.show_percentage = false


func _capturar():
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var cavillaca := get_tree().get_first_node_in_group("cavillaca")
	if cavillaca:
		cavillaca._recoger_bebe()
	await get_tree().create_timer(0.55).timeout
	var imagen := get_viewport().get_texture().get_image()
	imagen.save_png("screenshot_sprint2.png")
	get_tree().quit()


func _process(delta):
	$PanelEstado/EnergiaBar.value = Global.energia
	$PanelEstado/TiempoLabel.text = "Tiempo  %.0f s" % Global.tiempo_juego
	$PanelEstado/BebeLabel.text = "Bebe  cargando" if Global.lleva_bebe else "Bebe  en el suelo"
	$PanelEstado/RecuerdosLabel.text = "Recuerdos  %d/%d" % [Global.recuerdos_obtenidos, Global.RECUERDOS_TOTALES]
	
	var texto_zona := Global.zona_actual
	if Global.descanso_con_zorro:
		texto_zona += " (Descansando)"
	$PanelEstado/ZonaLabel.text = texto_zona

	if Global.prompt_interaccion != "":
		if prompt_texto != Global.prompt_interaccion:
			var es_ataque := Global.prompt_interaccion.begins_with("ESPACIO")
			_estilar_pildora($PromptFondo, VERDE if es_ataque else NARANJA)
		prompt_texto = Global.prompt_interaccion

	var destino_alpha := 1.0 if Global.prompt_interaccion != "" else 0.0
	prompt_alpha = move_toward(prompt_alpha, destino_alpha, delta * 8.0)
	$PromptLabel.text = prompt_texto
	$PromptLabel.modulate.a = prompt_alpha
	$PromptFondo.modulate.a = prompt_alpha

	var hay_aviso := Global.aviso_combate != ""
	$AvisoLabel.text = Global.aviso_combate
	$AvisoFondo.visible = hay_aviso
	$AvisoLabel.visible = hay_aviso
	if hay_aviso:
		var color_aviso := VERDE if Global.aviso_combate == "Victoria" else NARANJA_OSCURO
		_estilar_pildora($AvisoFondo, color_aviso)
	
	# Presencia de Cuniraya
	var nivel_presencia := Global.presencia_cuniraya
	if nivel_presencia <= 0:
		$Oscuridad.color.a = 0.0
	elif nivel_presencia == 1:
		$Oscuridad.color.a = 0.25
	elif nivel_presencia == 2:
		$Oscuridad.color.a = 0.40
	else:
		$Oscuridad.color.a = 0.55
