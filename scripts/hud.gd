extends CanvasLayer

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const FUENTE_PROMPT := preload("res://assets/fonts/chelsea-market/ChelseaMarket-Regular.ttf")
const MARCO_ENERGIA := preload("res://assets/ui/energy.png")
const REFERENCIA_ENERGIA := preload("res://assets/ui/energy reference.png")
const ICONO_PRESENCIA := preload("res://assets/icons/presencia.svg")
const ICONO_AJUSTES := preload("res://assets/icons/ajustes.svg")
const ESCENA_OVERLAY_AJUSTES: PackedScene = preload("res://scenes/componentes/OverlayAjustes.tscn")
const PROMPT_ATACAR := preload("res://assets/ui/botones/atacar_btn.png")
const PROMPT_ATACAR_PRESIONADO := preload("res://assets/ui/botones/atacar_btn_pressed.png")
const PROMPT_CARGAR := preload("res://assets/ui/botones/cargar_btn.png")
const PROMPT_CARGAR_PRESIONADO := preload("res://assets/ui/botones/cargar_btn_pressed.png")
const PROMPT_CONVERSAR := preload("res://assets/ui/botones/conversar_btn.png")
const PROMPT_CONVERSAR_PRESIONADO := preload("res://assets/ui/botones/conversar_btn_pressed.png")
const PROMPT_DEJAR := preload("res://assets/ui/botones/dejar_btn.png")
const PROMPT_DEJAR_PRESIONADO := preload("res://assets/ui/botones/dejar_btn_pressed.png")
const PROMPT_HABLAR := preload("res://assets/ui/botones/hablar_btn.png")
const PROMPT_HABLAR_PRESIONADO := preload("res://assets/ui/botones/hablar_btn_pressed.png")
const PROMPT_DESCANSAR := preload("res://assets/ui/botones/descansar_btn.png")
const PROMPT_DESCANSAR_PRESIONADO := preload("res://assets/ui/botones/descansar_btn_pressed.png")
const TEXTURA_CAJA_DIALOGO := preload("res://assets/ui/dialogo/dialogo_caja.png")
const MENSAJES_DIALOGO_ZORRO: Array[String] = [
	"Con un recuerdo, la cueva recarga tu energía",
	"El zorro parece reconocer el recuerdo que encontraste",
	"El zorro confía en ti y está dispuesto a cuidar al bebé",
	"El zorro aún no te ofrece descanso",
	"Necesitas el Recuerdo 2 para esto",
	"El zorro no está cerca",
	"No llevas al bebé",
	"Bebé dejado con el zorro",
	"Bebé recogido del zorro",
]
const CONSEJOS_LORO: Array[String] = [
	"¡Escucha al bebé si sientes que Cuniraya se acerca!",
	"Listen to the baby when you feel Cuniraya drawing near!",
	"Écoute le bébé si tu sens Cuniraya s'approcher !",
	"¡Cuniraya está cerca! Protege al bebé.",
	"Cuniraya is near! Protect the baby.",
	"Cuniraya est proche ! Protège le bébé.",
]
const CREMA := Color(0.99, 0.96, 0.9, 1)
const MORADO := Color(0.22, 0.2, 0.42, 0.92)
const VERDE := Color(0.49, 0.76, 0.29, 1)
const LILA := Color(0.67, 0.62, 0.93, 1)
const DORADO := Color(0.86, 0.7, 0.2, 1)
const BORDO := Color(0.62, 0.24, 0.36, 1)
const NARANJA_CUEVA := Color(1.0, 0.58, 0.24, 1)

var prompt_alpha := 0.0
var prompt_texto := ""
var prompt_idioma := ""
var prompt_icono: TextureRect
var prompt_titulo: Label
var dialogo_zorro_fondo: TextureRect
var dialogo_zorro_texto: Label
var material_oscuridad: ShaderMaterial
var icono_presencia: TextureRect
var marco_presencia: Panel
var barra_energia: TextureRect
var material_relleno_energia: ShaderMaterial
var barra_presencia: ProgressBar
var overlay_ajustes: Control
var pausa_previa_ajustes := false
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

@onready var peak_tension: AudioStreamPlayer2D = $PeakTension
@onready var llanto_bebe: AudioStreamPlayer = $LlantoBebe
var volumen_normal_peak: float = 0.0
var volumen_normal_llanto: float = 3.0
var temporizador_peak: float = 0.0
var temporizador_llanto: float = 0.0
var aviso_visible_actual := ""
var ornamentos_aviso: Array[Line2D] = []


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_estilar_panel()
	_estilar_textos()
	_crear_prompt_icono()
	_crear_dialogo_zorro()
	_crear_ornamentos_aviso()
	_estilar_prompt()
	_estilar_pildora($AvisoFondo, VERDE)
	_poner_guia_bebe()
	_poner_guia_cueva()
	_poner_ajustes()
	if not Global.partida_terminada:
		Musica.iniciar_juego_con_tension()
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
	]:
		nodo.visible = false
	if has_node("PresenciaLabel"):
		$PresenciaLabel.visible = false
	$PanelEstado/EnergiaBar.hide()
	_configurar_barra_energia()
	icono_presencia = _poner_icono(ICONO_PRESENCIA, Vector2(16, 76), LILA)
	barra_presencia = $PanelEstado/PresenciaBar
	marco_presencia = _envolver_barra(barra_presencia, Vector2(60, 80), LILA)
	_mostrar_presencia(false)
	_poner_recuerdos()


func _configurar_barra_energia() -> void:
	var contenedor := Control.new()
	contenedor.position = Vector2(20, 8)
	contenedor.size = Vector2(246, 60)
	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$PanelEstado.add_child(contenedor)

	barra_energia = TextureRect.new()
	barra_energia.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	barra_energia.texture = REFERENCIA_ENERGIA
	barra_energia.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	barra_energia.stretch_mode = TextureRect.STRETCH_SCALE
	barra_energia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader_relleno := Shader.new()
	shader_relleno.code = """
	shader_type canvas_item;
	uniform float porcentaje = 1.0;
	void fragment() {
		vec4 color = texture(TEXTURE, UV);
		float diferencia_morada = min(color.r - color.g, color.b - color.g);
		color.a *= smoothstep(0.06, 0.2, diferencia_morada);
		if (UV.x > porcentaje) {
			color.a = 0.0;
		}
		COLOR = color;
	}
	"""
	material_relleno_energia = ShaderMaterial.new()
	material_relleno_energia.shader = shader_relleno
	barra_energia.material = material_relleno_energia
	contenedor.add_child(barra_energia)

	var marco := TextureRect.new()
	marco.texture = MARCO_ENERGIA
	marco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marco.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marco.stretch_mode = TextureRect.STRETCH_SCALE
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenedor.add_child(marco)

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
		nodo.offset_left = -260
		nodo.offset_top = -76
		nodo.offset_right = -20
		nodo.offset_bottom = -20
	
	$PromptFondo.add_theme_stylebox_override("panel", _circulo(VERDE, 56))
	_texto($PromptLabel, 22)
	$PromptLabel.text = Traducciones.obtener_frase(Global.prompt_interaccion)


func _crear_prompt_icono() -> void:
	prompt_icono = TextureRect.new()
	prompt_icono.name = "PromptAccionIcono"
	prompt_icono.z_index = 10
	prompt_icono.visible = false
	prompt_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prompt_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prompt_icono.scale = Vector2(1.5, 1.5)
	prompt_icono.pivot_offset = Vector2(42, 42)
	prompt_icono.anchor_left = 0.5
	prompt_icono.anchor_right = 0.5
	prompt_icono.anchor_top = 1.0
	prompt_icono.anchor_bottom = 1.0
	prompt_icono.offset_left = -42
	prompt_icono.offset_top = -176
	prompt_icono.offset_right = 42
	prompt_icono.offset_bottom = -92
	add_child(prompt_icono)

	prompt_titulo = Label.new()
	prompt_titulo.name = "PromptAccionTitulo"
	prompt_titulo.z_index = 10
	prompt_titulo.visible = false
	prompt_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_titulo.anchor_left = 0.5
	prompt_titulo.anchor_right = 0.5
	prompt_titulo.anchor_top = 1.0
	prompt_titulo.anchor_bottom = 1.0
	prompt_titulo.offset_left = -79
	prompt_titulo.offset_top = -56
	prompt_titulo.offset_right = 79
	prompt_titulo.offset_bottom = -28
	_texto(prompt_titulo, 18)
	prompt_titulo.add_theme_font_override("font", FUENTE_PROMPT)
	prompt_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(prompt_titulo)


func _crear_dialogo_zorro() -> void:
	dialogo_zorro_fondo = TextureRect.new()
	dialogo_zorro_fondo.name = "DialogoZorroFondo"
	dialogo_zorro_fondo.texture = TEXTURA_CAJA_DIALOGO
	dialogo_zorro_fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogo_zorro_fondo.stretch_mode = TextureRect.STRETCH_SCALE
	dialogo_zorro_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogo_zorro_fondo.visible = false
	dialogo_zorro_fondo.z_index = 20
	dialogo_zorro_fondo.anchor_left = 0.5
	dialogo_zorro_fondo.anchor_right = 0.5
	dialogo_zorro_fondo.offset_left = -463.0
	dialogo_zorro_fondo.offset_top = 164.0
	dialogo_zorro_fondo.offset_right = 463.0
	dialogo_zorro_fondo.offset_bottom = 298.0
	add_child(dialogo_zorro_fondo)

	dialogo_zorro_texto = Label.new()
	dialogo_zorro_texto.name = "DialogoZorroTexto"
	dialogo_zorro_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogo_zorro_texto.visible = false
	dialogo_zorro_texto.z_index = 21
	dialogo_zorro_texto.anchor_left = 0.5
	dialogo_zorro_texto.anchor_right = 0.5
	dialogo_zorro_texto.offset_left = -405.0
	dialogo_zorro_texto.offset_top = 188.0
	dialogo_zorro_texto.offset_right = 405.0
	dialogo_zorro_texto.offset_bottom = 274.0
	dialogo_zorro_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogo_zorro_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogo_zorro_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogo_zorro_texto.add_theme_font_override("font", FUENTE)
	dialogo_zorro_texto.add_theme_font_size_override("font_size", 23)
	dialogo_zorro_texto.add_theme_color_override("font_color", CREMA)
	add_child(dialogo_zorro_texto)

func _tipo_prompt_con_imagen() -> String:
	var texto := Global.prompt_interaccion.to_lower()
	if texto.contains("descansar"):
		return "rest" if texto.begins_with("r ") else ""
	if texto.contains("atacar"):
		return "attack"
	if texto.contains("recoger"):
		return "pickup"
	if texto.contains("dejar"):
		return "leave"
	if texto.contains("conversar"):
		return "converse"
	if texto.contains("hablar"):
		return "talk"
	return ""


func _actualizar_prompt_visual() -> void:
	# Mantiene el último prompt mientras se desvanece para evitar que aparezca
	# el botón de texto antiguo por un instante al salir del rango o del combate.
	if Global.prompt_interaccion.is_empty():
		return

	var tipo := _tipo_prompt_con_imagen()
	var usa_imagen := tipo != ""
	$PromptFondo.visible = not usa_imagen
	$PromptLabel.visible = not usa_imagen
	prompt_icono.visible = usa_imagen
	prompt_titulo.visible = usa_imagen
	if not usa_imagen:
		return

	var accion := "atacar" if tipo == "attack" else "descansar" if tipo == "rest" else "interactuar"
	if tipo == "talk" and Global.prompt_interaccion.to_lower().begins_with("f "):
		accion = "hablar_zorro"
	var presionado := Input.is_action_pressed(accion)
	if tipo == "rest" and Global.descanso_con_zorro:
		presionado = true
	match tipo:
		"attack":
			prompt_icono.texture = PROMPT_ATACAR_PRESIONADO if presionado else PROMPT_ATACAR
			prompt_titulo.text = Traducciones.obtener("attack")
		"pickup":
			prompt_icono.texture = PROMPT_CARGAR_PRESIONADO if presionado else PROMPT_CARGAR
			prompt_titulo.text = Traducciones.obtener("pickup")
		"converse":
			prompt_icono.texture = PROMPT_CONVERSAR_PRESIONADO if presionado else PROMPT_CONVERSAR
			prompt_titulo.text = Traducciones.obtener("converse_action")
		"leave":
			prompt_icono.texture = PROMPT_DEJAR_PRESIONADO if presionado else PROMPT_DEJAR
			var clave_titulo := "leave_with_fox_action" if Global.prompt_interaccion.to_lower().contains("con zorro") else "leave_action"
			prompt_titulo.text = Traducciones.obtener(clave_titulo)
		"talk":
			prompt_icono.texture = PROMPT_HABLAR_PRESIONADO if presionado else PROMPT_HABLAR
			prompt_titulo.text = Traducciones.obtener("talk_action")
		"rest":
			prompt_icono.texture = PROMPT_DESCANSAR_PRESIONADO if presionado else PROMPT_DESCANSAR
			prompt_titulo.text = Traducciones.obtener("rest_action")


func ocultar_prompt_interaccion() -> void:
	Global.prompt_interaccion = ""
	prompt_alpha = 0.0
	for nodo in [$PromptFondo, $PromptLabel, prompt_icono, prompt_titulo]:
		nodo.visible = false
		nodo.modulate.a = 0.0


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
		viewport_size.x - 320,
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


func _ajustar_banner_consejo() -> void:
	var label := $AvisoLabel as Label
	var fondo := $AvisoFondo as Panel
	label.add_theme_font_size_override("font_size", 22)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var tamano_fuente := label.get_theme_font_size("font_size")
	var fuente := label.get_theme_font("font")
	var ancho_texto := fuente.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano_fuente).x
	var ancho_vista := get_viewport().get_visible_rect().size.x
	var ancho_maximo := maxf(280.0, ancho_vista - 120.0)
	var ancho_banner := minf(maxf(ancho_texto + 320.0, 560.0), ancho_maximo)
	var ancho_label := ancho_banner - 112.0
	var alto_texto := fuente.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, ancho_label, tamano_fuente).y
	var alto_banner := maxf(alto_texto + 48.0, 96.0)

	fondo.anchor_left = 0.5
	fondo.anchor_right = 0.5
	fondo.anchor_top = 0.32
	fondo.anchor_bottom = 0.32
	fondo.offset_left = -ancho_banner * 0.5
	fondo.offset_right = ancho_banner * 0.5
	fondo.offset_top = -alto_banner * 0.5
	fondo.offset_bottom = alto_banner * 0.5
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 0.32
	label.anchor_bottom = 0.32
	label.offset_left = -ancho_label * 0.5
	label.offset_right = ancho_label * 0.5
	label.offset_top = -alto_banner * 0.5 + 16.0
	label.offset_bottom = alto_banner * 0.5 - 16.0
	_actualizar_ornamentos_aviso(ancho_banner, alto_banner)
	for linea in ornamentos_aviso:
		linea.visible = true


func _crear_ornamentos_aviso() -> void:
	for _indice in range(4):
		var linea := Line2D.new()
		linea.width = 2.5
		linea.default_color = Color(0.9, 0.89, 1.0, 0.92)
		linea.antialiased = true
		linea.begin_cap_mode = Line2D.LINE_CAP_ROUND
		linea.end_cap_mode = Line2D.LINE_CAP_ROUND
		linea.joint_mode = Line2D.LINE_JOINT_ROUND
		$AvisoFondo.add_child(linea)
		ornamentos_aviso.append(linea)


func _actualizar_ornamentos_aviso(ancho: float, alto: float) -> void:
	ornamentos_aviso[0].points = PackedVector2Array([
		Vector2(4.0, alto - 10.0), Vector2(-14.0, alto - 18.0),
		Vector2(-23.0, alto - 31.0), Vector2(-20.0, alto - 41.0),
		Vector2(-8.0, alto - 43.0), Vector2(-2.0, alto - 34.0),
	])
	ornamentos_aviso[1].points = PackedVector2Array([
		Vector2(0.0, alto - 2.0), Vector2(-20.0, alto - 14.0),
		Vector2(-28.0, alto - 26.0), Vector2(-26.0, alto - 35.0),
	])
	ornamentos_aviso[2].points = PackedVector2Array([
		Vector2(ancho - 4.0, 10.0), Vector2(ancho + 14.0, 18.0),
		Vector2(ancho + 23.0, 30.0), Vector2(ancho + 20.0, 40.0),
		Vector2(ancho + 9.0, 43.0), Vector2(ancho + 2.0, 35.0),
	])
	ornamentos_aviso[3].points = PackedVector2Array([
		Vector2(ancho, 2.0), Vector2(ancho + 20.0, 13.0),
		Vector2(ancho + 28.0, 25.0), Vector2(ancho + 26.0, 34.0),
	])


func _estilar_banner_consejo() -> void:
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(0.035, 0.03, 0.085, 0.78)
	caja.set_corner_radius_all(48)
	caja.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	caja.shadow_size = 10
	caja.shadow_offset = Vector2(0, 4)
	$AvisoFondo.add_theme_stylebox_override("panel", caja)


func _posicionar_aviso_descanso(es_descanso: bool) -> void:
	var fondo := $AvisoFondo as Panel
	var label := $AvisoLabel as Label
	var ancla_vertical := 1.0 if es_descanso else 0.0
	fondo.anchor_top = ancla_vertical
	fondo.anchor_bottom = ancla_vertical
	label.anchor_top = ancla_vertical
	label.anchor_bottom = ancla_vertical
	# El estado de descanso aparece sobre el botón R, sin tapar la escena.
	fondo.offset_top = -246.0 if es_descanso else 28.0


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
	boton.name = "BotonAjustes"
	boton.color_fondo = DORADO
	boton.icono = ICONO_AJUSTES
	boton.tamano = 52.0
	boton.z_index = 100
	boton.pressed.connect(_alternar_ajustes)
	add_child(boton)
	boton.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	boton.offset_left = -72
	boton.offset_top = 16
	boton.offset_right = -20
	boton.offset_bottom = 68

	overlay_ajustes = ESCENA_OVERLAY_AJUSTES.instantiate() as Control
	overlay_ajustes.visible = false
	overlay_ajustes.set("desde_juego", true)
	overlay_ajustes.z_index = 101
	overlay_ajustes.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay_ajustes.connect("cerrar", Callable(self, "_cerrar_ajustes"))
	add_child(overlay_ajustes)


func _alternar_ajustes() -> void:
	if overlay_ajustes.visible:
		_cerrar_ajustes()
	else:
		_abrir_ajustes()


func _abrir_ajustes() -> void:
	pausa_previa_ajustes = get_tree().paused
	get_node("BotonAjustes").visible = false
	overlay_ajustes.visible = true
	get_tree().paused = true


func _cerrar_ajustes() -> void:
	if is_instance_valid(overlay_ajustes):
		overlay_ajustes.visible = false
	get_node("BotonAjustes").visible = true
	get_tree().paused = pausa_previa_ajustes


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_instance_valid(overlay_ajustes) and overlay_ajustes.visible:
		Global.reproducir_clic()
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
	var porcentaje_energia := clampf(Global.energia / Global.ENERGIA_MAX, 0.0, 1.0)
	material_relleno_energia.set_shader_parameter("porcentaje", porcentaje_energia)
	barra_presencia.value = Global.presencia_cuniraya
	_mostrar_presencia(Global.presencia_cuniraya > 0.5)
	_actualizar_recuerdos()
	_actualizar_guia_bebe(delta)
	_actualizar_guia_cueva(delta)

	if Global.prompt_interaccion != "":
		if prompt_texto != Global.prompt_interaccion:
			var es_ataque := Global.prompt_interaccion.to_lower().contains("atacar")
			$PromptFondo.add_theme_stylebox_override("panel", _circulo(BORDO if es_ataque else VERDE, 56))
			$PromptLabel.text = Traducciones.obtener_frase(Global.prompt_interaccion)
		prompt_texto = Global.prompt_interaccion
	if prompt_idioma != Global.idioma_actual:
		prompt_idioma = Global.idioma_actual
		prompt_texto = ""
	_actualizar_prompt_visual()

	var destino_alpha := 1.0 if Global.prompt_interaccion != "" else 0.0
	prompt_alpha = move_toward(prompt_alpha, destino_alpha, delta * 8.0)
	$PromptLabel.modulate.a = prompt_alpha
	$PromptFondo.modulate.a = prompt_alpha
	prompt_icono.modulate.a = prompt_alpha
	prompt_titulo.modulate.a = prompt_alpha
	if destino_alpha == 0.0 and prompt_alpha <= 0.0:
		$PromptFondo.visible = false
		$PromptLabel.visible = false
		prompt_icono.visible = false
		prompt_titulo.visible = false

	var hay_aviso := Global.aviso_combate != ""
	var es_dialogo_zorro := MENSAJES_DIALOGO_ZORRO.has(Global.aviso_combate)
	var es_consejo_loro := CONSEJOS_LORO.has(Global.aviso_combate)
	var es_aviso_descanso := Global.aviso_combate == "Descansando junto al tronco"
	var mostrar_aviso_normal := hay_aviso and not es_dialogo_zorro
	var texto_aviso := Traducciones.obtener_frase(Global.aviso_combate)
	$AvisoLabel.text = texto_aviso
	$AvisoFondo.visible = mostrar_aviso_normal
	$AvisoLabel.visible = mostrar_aviso_normal
	dialogo_zorro_fondo.visible = hay_aviso and es_dialogo_zorro
	dialogo_zorro_texto.visible = hay_aviso and es_dialogo_zorro
	if es_dialogo_zorro:
		dialogo_zorro_texto.text = texto_aviso
		aviso_visible_actual = ""
	if mostrar_aviso_normal:
		if es_consejo_loro:
			if texto_aviso != aviso_visible_actual:
				aviso_visible_actual = texto_aviso
				_ajustar_banner_consejo()
				_estilar_banner_consejo()
		else:
			aviso_visible_actual = texto_aviso
			$AvisoLabel.add_theme_font_size_override("font_size", 18)
			for linea in ornamentos_aviso:
				linea.visible = false
			_posicionar_aviso_descanso(es_aviso_descanso)
			_ajustar_banner_aviso()
			var color_aviso := VERDE if Global.aviso_combate == "Victoria" else Color(0.34, 0.25, 0.52, 0.96) if es_aviso_descanso else BORDO
			_estilar_pildora($AvisoFondo, color_aviso)
	else:
		aviso_visible_actual = ""

	var nivel_presencia : float = Global.presencia_cuniraya
	Musica.actualizar_tension(Global.presencia_activa)
	material_oscuridad.set_shader_parameter("intensidad", nivel_presencia / 100.0)

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
		
	# Ocultar guias si esta en combate
	var combate := get_tree().current_scene.get_node_or_null("CombateHalcon")

	if combate != null and combate.visible:
		$Guias.visible = false
	else:
		$Guias.visible = true

func fade_out_audio(audio: Node, duracion: float) -> void:
	if not audio.get("playing"):
		return
	var tween := create_tween()
	tween.tween_property(audio, "volume_db", -40.0, duracion)
	tween.tween_callback(Callable(audio, "stop"))

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
		Traducciones.obtener("cave"),
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
