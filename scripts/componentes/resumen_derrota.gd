extends PanelContainer
## Resumen de la derrota: causa, recuerdos reunidos y un consejo.
## Lee el estado de Global al crearse (antes de reiniciar la partida).

const FUENTE := preload("res://assets/fonts/chelsea-market/ChelseaMarket-Regular.ttf")
const CREMA := Color("f4e9ff")
const LILA := Color(0.82, 0.77, 1.0, 1)

var causa := "energy"
var recuerdos := 0
var titulo: Label
var detalle: Label
var conteo: Label
var consejo: Label


func _init() -> void:
	recuerdos = Global.recuerdos_obtenidos
	if Global.presencia_cuniraya >= Global.PRESENCIA_CRITICA and not Global.lleva_bebe:
		causa = "presence"
	elif Global.lleva_bebe:
		causa = "baby"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(0.035, 0.03, 0.085, 0.82)
	caja.set_corner_radius_all(28)
	caja.content_margin_left = 36
	caja.content_margin_right = 36
	caja.content_margin_top = 20
	caja.content_margin_bottom = 20
	add_theme_stylebox_override("panel", caja)
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -330
	offset_right = 330
	offset_top = 300
	grow_vertical = Control.GROW_DIRECTION_END
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	add_child(columna)
	titulo = _label(30, CREMA)
	detalle = _label(20, CREMA)
	conteo = _label(20, LILA)
	consejo = _label(18, LILA)
	for nodo in [titulo, detalle, conteo, consejo]:
		columna.add_child(nodo)
	_traducir()
	Traducciones.idioma_cambiado.connect(_traducir)


func _label(tamano: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", FUENTE)
	label.add_theme_font_size_override("font_size", tamano)
	label.add_theme_color_override("font_color", color)
	return label


func _traducir(_idioma: String = "") -> void:
	titulo.text = Traducciones.obtener("defeat_title")
	detalle.text = Traducciones.obtener("defeat_cause_" + causa)
	conteo.text = Traducciones.obtener("defeat_memories") % [recuerdos, Global.RECUERDOS_TOTALES]
	consejo.text = Traducciones.obtener("defeat_tip_" + causa)
