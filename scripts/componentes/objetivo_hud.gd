extends Control
## Tarjeta de objetivo al empezar y pista bajo el contador de recuerdos.
## Se añade desde hud.gd; no modifica el estado del juego.

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const CREMA := Color(0.99, 0.96, 0.9, 1)
const LILA_SUAVE := Color(0.9, 0.86, 1.0, 0.85)
const DURACION_TARJETA := 9.0

# Una vez por sesión: reintentar no vuelve a mostrar la tarjeta.
static var tarjeta_mostrada := false

var tarjeta: PanelContainer
var titulo: Label
var texto: Label
var cierre: Label
var pista: Label
var tiempo_tarjeta := 0.0
# Avisos que llegan mientras la tarjeta está abierta: se muestran después, de a uno.
var avisos_en_espera: Array = []
var espera_siguiente := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crear_pista()
	if not tarjeta_mostrada and not Global.partida_terminada:
		tarjeta_mostrada = true
		_crear_tarjeta()
	_traducir()
	Traducciones.idioma_cambiado.connect(_traducir)


func _crear_pista() -> void:
	pista = _label(17, LILA_SUAVE)
	pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pista.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pista.offset_left = -420
	pista.offset_right = -96
	pista.offset_top = 70
	pista.offset_bottom = 94
	add_child(pista)


func _crear_tarjeta() -> void:
	tarjeta = PanelContainer.new()
	tarjeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(0.035, 0.03, 0.085, 0.82)
	caja.set_corner_radius_all(28)
	caja.content_margin_left = 28
	caja.content_margin_right = 28
	caja.content_margin_top = 22
	caja.content_margin_bottom = 20
	caja.shadow_color = Color(0, 0, 0, 0.28)
	caja.shadow_size = 10
	tarjeta.add_theme_stylebox_override("panel", caja)
	# Arriba a la derecha, bajo el contador de recuerdos: no tapa a Cavillaca,
	# al bebé ni el prompt de interacción, y queda junto al 0/3 que explica.
	tarjeta.anchor_left = 1.0
	tarjeta.anchor_right = 1.0
	tarjeta.offset_left = -452
	tarjeta.offset_right = -32
	tarjeta.offset_top = 104
	tarjeta.grow_vertical = Control.GROW_DIRECTION_END
	add_child(tarjeta)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	tarjeta.add_child(columna)
	titulo = _label(26, CREMA)
	texto = _label(20, CREMA)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cierre = _label(14, LILA_SUAVE)
	for nodo in [titulo, texto, cierre]:
		nodo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		columna.add_child(nodo)


func _label(tamano: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FUENTE)
	label.add_theme_font_size_override("font_size", tamano)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _traducir(_idioma: String = "") -> void:
	pista.text = Traducciones.obtener("memories_hint")
	if is_instance_valid(tarjeta):
		titulo.text = Traducciones.obtener("objective_title")
		texto.text = Traducciones.obtener("objective_text")
		cierre.text = Traducciones.obtener("objective_dismiss")


func _process(delta: float) -> void:
	# La pista solo hace falta mientras faltan recuerdos y no hay combate.
	var combate := get_tree().current_scene.get_node_or_null("CombateHalcon") if get_tree().current_scene else null
	pista.visible = Global.recuerdos_obtenidos < Global.RECUERDOS_TOTALES \
		and not Global.partida_terminada and not (combate and combate.visible)
	if not is_instance_valid(tarjeta):
		_mostrar_avisos_en_espera(delta)
		return
	_retener_aviso()
	tiempo_tarjeta += delta
	if tiempo_tarjeta >= DURACION_TARJETA:
		_cerrar_tarjeta()


func _retener_aviso() -> void:
	# Solo la ayuda de controles espera a que se cierre la tarjeta. Lo urgente
	# (presencia crítica, consejo del loro) y la respuesta a lo que hace la
	# jugadora salen al momento: la tarjeta está arriba a la derecha y no los tapa.
	if Global.aviso_combate == "" or not _es_diferible(Global.aviso_combate):
		return
	var texto := Global.aviso_combate
	if not avisos_en_espera.any(func(a): return a[0] == texto):
		avisos_en_espera.append([texto, maxf(Global.aviso_temporizador, Global.DURACION_AVISO)])
	Global.aviso_combate = ""
	Global.aviso_temporizador = 0.0

func _es_diferible(texto: String) -> bool:
	return texto == Traducciones.obtener("controls_hint")

func _mostrar_avisos_en_espera(delta: float) -> void:
	if avisos_en_espera.is_empty():
		return
	espera_siguiente -= delta
	# No pisar un aviso que está en pantalla (p. ej. el loro o la presencia crítica).
	if espera_siguiente > 0.0 or Global.aviso_combate != "":
		return
	var aviso: Array = avisos_en_espera.pop_front()
	Global.mostrar_aviso(aviso[0])
	Global.aviso_temporizador = aviso[1]
	espera_siguiente = aviso[1]

func _input(event: InputEvent) -> void:
	# Solo Espacio/Enter o clic la cierran: moverse no la descarta sin leerla.
	if not is_instance_valid(tarjeta) or tiempo_tarjeta < 0.4:
		return
	if event.is_action_pressed("ui_accept") \
			or (event is InputEventMouseButton and event.is_pressed()):
		_cerrar_tarjeta()


func _cerrar_tarjeta() -> void:
	var nodo := tarjeta
	tarjeta = null
	var tween := create_tween()
	tween.tween_property(nodo, "modulate:a", 0.0, 0.3)
	tween.tween_callback(nodo.queue_free)
