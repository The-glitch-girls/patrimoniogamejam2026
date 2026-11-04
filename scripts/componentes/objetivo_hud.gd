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
	caja.content_margin_left = 36
	caja.content_margin_right = 36
	caja.content_margin_top = 22
	caja.content_margin_bottom = 20
	caja.shadow_color = Color(0, 0, 0, 0.28)
	caja.shadow_size = 10
	tarjeta.add_theme_stylebox_override("panel", caja)
	tarjeta.anchor_left = 0.5
	tarjeta.anchor_right = 0.5
	tarjeta.anchor_top = 0.68
	tarjeta.anchor_bottom = 0.68
	tarjeta.offset_left = -300
	tarjeta.offset_right = 300
	tarjeta.grow_vertical = Control.GROW_DIRECTION_BOTH
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
		return
	tiempo_tarjeta += delta
	if tiempo_tarjeta >= DURACION_TARJETA:
		_cerrar_tarjeta()


func _input(event: InputEvent) -> void:
	# Cualquier tecla o clic cierra la tarjeta sin consumir la entrada.
	if not is_instance_valid(tarjeta) or tiempo_tarjeta < 0.4:
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		_cerrar_tarjeta()


func _cerrar_tarjeta() -> void:
	var nodo := tarjeta
	tarjeta = null
	var tween := create_tween()
	tween.tween_property(nodo, "modulate:a", 0.0, 0.3)
	tween.tween_callback(nodo.queue_free)
