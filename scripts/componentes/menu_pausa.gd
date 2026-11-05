extends Control
## Menú de pausa (Continuar, Controles, Salir al menú).
## La lógica de pausa vive en global.gd (Global.pausado / pausa_cambiada / alternar_pausa).
## Este menú no guarda estado propio: se muestra solo si Global.pausado y el árbol
## está pausado, y nunca encima del overlay de ajustes.

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const CREMA := Color(0.99, 0.96, 0.9, 1)
const LILA := Color(0.82, 0.77, 1.0, 1)
const MORADO := Color(0.22, 0.2, 0.42, 1)
const VERDE_ARBOL := Color(0.16, 0.49, 0.49, 1)
const ESCENA_MENU := "res://scenes/MenuInicio.tscn"

var hud: CanvasLayer
var titulo: Label
var pista: Label
var controles: Label
var boton_continuar: Button
var boton_controles: Button
var boton_salir: Button


func _ready() -> void:
	hud = get_parent()
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 102
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construir()
	_traducir()
	Traducciones.idioma_cambiado.connect(_traducir)
	if Global.has_signal("pausa_cambiada"):
		Global.pausa_cambiada.connect(_al_cambiar_pausa)
	else:
		push_warning("menu_pausa: falta Global.pausa_cambiada; el menú no se mostrará.")


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.01, 0.06, 0.55)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	var panel := PanelContainer.new()
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(0.035, 0.03, 0.085, 0.9)
	caja.set_corner_radius_all(28)
	caja.set_border_width_all(3)
	caja.border_color = Color(0.9, 0.84, 1.0, 1)
	caja.content_margin_left = 40
	caja.content_margin_right = 40
	caja.content_margin_top = 24
	caja.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", caja)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	var columna := VBoxContainer.new()
	columna.custom_minimum_size.x = 320
	columna.add_theme_constant_override("separation", 12)
	panel.add_child(columna)
	titulo = _label(34, CREMA)
	columna.add_child(titulo)
	boton_continuar = _boton(VERDE_ARBOL, _continuar)
	boton_controles = _boton(MORADO, _alternar_controles)
	controles = _label(17, LILA)
	controles.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controles.visible = false
	boton_salir = _boton(MORADO, _salir)
	pista = _label(14, LILA)
	for nodo in [boton_continuar, boton_controles, controles, boton_salir, pista]:
		columna.add_child(nodo)


func _label(tamano: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FUENTE)
	label.add_theme_font_size_override("font_size", tamano)
	label.add_theme_color_override("font_color", color)
	return label


func _boton(color: Color, accion: Callable) -> Button:
	var boton := Button.new()
	boton.custom_minimum_size.y = 48
	boton.add_theme_font_override("font", FUENTE)
	boton.add_theme_font_size_override("font_size", 22)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		boton.add_theme_color_override(estado, CREMA)
	var estilos := {
		"normal": color,
		"hover": color.lightened(0.12),
		"pressed": color.darkened(0.15),
		"focus": color.lightened(0.12),
	}
	for estado in estilos:
		var caja := StyleBoxFlat.new()
		caja.bg_color = estilos[estado]
		caja.set_corner_radius_all(16)
		caja.set_border_width_all(3 if estado == "focus" else 2)
		caja.border_color = Color.WHITE if estado == "focus" else Color(0.9, 0.84, 1.0, 0.8)
		boton.add_theme_stylebox_override(estado, caja)
	boton.pressed.connect(accion)
	return boton


func _traducir(_idioma: String = "") -> void:
	titulo.text = Traducciones.obtener("pause")
	boton_continuar.text = Traducciones.obtener("continue")
	boton_controles.text = Traducciones.obtener("controls")
	boton_salir.text = Traducciones.obtener("quit_to_menu")
	controles.text = Traducciones.obtener("controls_hint").replace(" · ", "\n")
	pista.text = Traducciones.obtener("pause_hint")


func _debe_mostrarse() -> bool:
	var ajustes_abiertos: bool = is_instance_valid(hud.overlay_ajustes) and hud.overlay_ajustes.visible
	return bool(Global.get("pausado")) and get_tree().paused and not ajustes_abiertos


func _al_cambiar_pausa(_pausado: bool) -> void:
	_sincronizar()


func _process(_delta: float) -> void:
	_sincronizar()


func _sincronizar() -> void:
	var mostrar := _debe_mostrarse()
	if mostrar == visible:
		return
	visible = mostrar
	var engranaje := hud.get_node_or_null("BotonAjustes")
	if engranaje:
		engranaje.visible = not mostrar
	if mostrar:
		controles.visible = false
		boton_continuar.grab_focus()


func _continuar() -> void:
	Global.reproducir_clic()
	Global.alternar_pausa()
	_sincronizar()


func _alternar_controles() -> void:
	Global.reproducir_clic()
	controles.visible = not controles.visible


func _salir() -> void:
	Global.reproducir_clic()
	if Global.pausado:
		Global.alternar_pausa()
	get_tree().paused = false
	Global.resetear()
	Musica.detener()
	get_tree().change_scene_to_file(ESCENA_MENU)
