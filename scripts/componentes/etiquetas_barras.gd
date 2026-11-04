extends Node
## Etiquetas de las barras del HUD (solo la primera vez que aparecen) y tooltips.
## Se añade como hijo de hud.gd y lee sus barras; no cambia la lógica del juego.

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const CREMA := Color(0.99, 0.96, 0.9, 1)
const DURACION := 6.0

# Una vez por sesión, para no repetirlas al reintentar.
static var vistas := {}

var hud: CanvasLayer
var etiqueta_energia: Label
var etiqueta_presencia: Label
var etiqueta_bebe: Label
var zona_energia: Control
var zona_presencia: Control
var tiempos := {}


func _ready() -> void:
	hud = get_parent()
	var panel: Control = hud.get_node("PanelEstado")
	etiqueta_energia = _etiqueta(panel, Vector2(272, 22))
	etiqueta_presencia = _etiqueta(panel, Vector2(266, 80))
	etiqueta_bebe = _etiqueta(panel, Vector2(8, 112))
	zona_energia = _zona(hud.barra_energia.get_parent())
	zona_presencia = _zona(hud.marco_presencia)
	_traducir()
	Traducciones.idioma_cambiado.connect(_traducir)
	if not Global.partida_terminada:
		_mostrar("energia")


func _multiplicador_bebe() -> int:
	return int(round(Global.COSTO_CARGAR_BEBE / Global.COSTO_CAMINAR))


func _etiqueta(panel: Control, pos: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate.a = 0.0
	label.add_theme_font_override("font", FUENTE)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", CREMA)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.2, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	panel.add_child(label)
	return label


class ZonaTooltip extends Control:
	## Área invisible encima de una barra: solo muestra un tooltip legible.
	func _make_custom_tooltip(texto: String) -> Object:
		var panel := PanelContainer.new()
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color(0.035, 0.03, 0.085, 0.9)
		caja.set_corner_radius_all(14)
		caja.set_content_margin_all(12)
		panel.add_theme_stylebox_override("panel", caja)
		var label := Label.new()
		label.text = texto
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 320
		label.add_theme_font_override("font", FUENTE)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", CREMA)
		panel.add_child(label)
		return panel


func _zona(barra: Control) -> Control:
	var zona := ZonaTooltip.new()
	zona.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	zona.mouse_filter = Control.MOUSE_FILTER_PASS
	barra.add_child(zona)
	return zona


func _traducir(_idioma: String = "") -> void:
	var veces := _multiplicador_bebe()
	etiqueta_energia.text = Traducciones.obtener("energy_label")
	etiqueta_bebe.text = Traducciones.obtener("energy_baby_label") % veces
	etiqueta_presencia.text = Traducciones.obtener("presence_label")
	zona_energia.tooltip_text = Traducciones.obtener("energy_tooltip") % veces
	zona_presencia.tooltip_text = Traducciones.obtener("presence_tooltip") % int(Global.PRESENCIA_CRITICA)


func _mostrar(clave: String) -> void:
	if vistas.has(clave):
		return
	vistas[clave] = true
	tiempos[clave] = DURACION


func _process(delta: float) -> void:
	if hud.marco_presencia.visible:
		_mostrar("presencia")
	if Global.lleva_bebe:
		_mostrar("bebe")
	for clave in tiempos.keys():
		tiempos[clave] -= delta
		if tiempos[clave] <= 0.0:
			tiempos.erase(clave)
	_fundir(etiqueta_energia, tiempos.has("energia"), delta)
	_fundir(etiqueta_bebe, tiempos.has("bebe"), delta)
	_fundir(etiqueta_presencia, tiempos.has("presencia") and hud.marco_presencia.visible, delta)


func _fundir(label: Label, activa: bool, delta: float) -> void:
	label.modulate.a = move_toward(label.modulate.a, 1.0 if activa else 0.0, delta * 3.0)
