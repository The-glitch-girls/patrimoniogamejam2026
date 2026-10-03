class_name guia_navegacion
extends Control

var flecha: FlechaGuia
var texto: Label

func configurar(
	color: Color,
	texto_inicial: String,
	tamano: Vector2,
	fuente: Font,
	color_texto: Color
) -> void:
	size = tamano
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Fondo
	var fondo := Panel.new()
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_theme_stylebox_override("panel", _tarjeta(color, 22))
	add_child(fondo)

	# Flecha
	flecha = FlechaGuia.new()
	flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flecha.size = Vector2(22, 22)
	flecha.pivot_offset = flecha.size * 0.5
	add_child(flecha)

	# Texto
	texto = Label.new()
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.offset_left = 42
	texto.offset_right = -14
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.text = texto_inicial

	texto.add_theme_font_override("font", fuente)
	texto.add_theme_font_size_override("font_size", 18)
	texto.add_theme_color_override("font_color", color_texto)

	add_child(texto)

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
