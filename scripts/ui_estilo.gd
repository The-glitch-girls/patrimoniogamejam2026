class_name UiEstilo
extends RefCounted

const NARANJA := Color(0.98, 0.62, 0.14, 1)
const NARANJA_OSCURO := Color(0.9, 0.48, 0.08, 1)
const CREMA := Color(1, 0.97, 0.93, 1)
const VERDE := Color(0.42, 0.78, 0.38, 1)
const TEXTO := Color(0.42, 0.28, 0.14, 1)
const TEXTO_CLARO := Color(1, 0.98, 0.94, 1)
const FONDO := Color(0.18, 0.12, 0.09, 1)


static func panel_crema() -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = CREMA
	panel.set_corner_radius_all(22)
	panel.set_border_width_all(4)
	panel.border_color = Color(1, 1, 1, 1)
	panel.shadow_color = Color(0, 0, 0, 0.18)
	panel.shadow_size = 8
	panel.shadow_offset = Vector2(0, 4)
	panel.content_margin_left = 28
	panel.content_margin_top = 24
	panel.content_margin_right = 28
	panel.content_margin_bottom = 24
	return panel


static func encabezado() -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = NARANJA
	caja.set_corner_radius_all(16)
	caja.corner_radius_bottom_left = 0
	caja.corner_radius_bottom_right = 0
	caja.content_margin_left = 16
	caja.content_margin_top = 10
	caja.content_margin_right = 16
	caja.content_margin_bottom = 10
	return caja


static func estilar_boton(boton: Button, relleno: Color = NARANJA) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = relleno
	normal.set_corner_radius_all(16)
	normal.set_border_width_all(3)
	normal.border_color = Color(1, 1, 1, 1)
	normal.content_margin_left = 20
	normal.content_margin_top = 12
	normal.content_margin_right = 20
	normal.content_margin_bottom = 12
	normal.shadow_color = Color(0, 0, 0, 0.16)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 2)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = relleno.lightened(0.08)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = relleno.darkened(0.12)
	pressed.shadow_size = 0

	boton.add_theme_stylebox_override("normal", normal)
	boton.add_theme_stylebox_override("hover", hover)
	boton.add_theme_stylebox_override("pressed", pressed)
	boton.add_theme_stylebox_override("focus", hover)
	boton.add_theme_color_override("font_color", TEXTO_CLARO)
	boton.add_theme_color_override("font_hover_color", TEXTO_CLARO)
	boton.add_theme_color_override("font_pressed_color", TEXTO_CLARO)
	boton.add_theme_color_override("font_focus_color", TEXTO_CLARO)
	boton.add_theme_font_size_override("font_size", 20)


static func estilar_boton_secundario(boton: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.93, 0.88, 0.8, 1)
	normal.set_corner_radius_all(16)
	normal.set_border_width_all(3)
	normal.border_color = Color(1, 1, 1, 1)
	normal.content_margin_left = 20
	normal.content_margin_top = 12
	normal.content_margin_right = 20
	normal.content_margin_bottom = 12

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.96, 0.92, 0.86, 1)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.86, 0.8, 0.7, 1)

	boton.add_theme_stylebox_override("normal", normal)
	boton.add_theme_stylebox_override("hover", hover)
	boton.add_theme_stylebox_override("pressed", pressed)
	boton.add_theme_stylebox_override("focus", hover)
	boton.add_theme_color_override("font_color", TEXTO)
	boton.add_theme_color_override("font_hover_color", TEXTO)
	boton.add_theme_color_override("font_pressed_color", TEXTO)
	boton.add_theme_color_override("font_focus_color", TEXTO)
	boton.add_theme_font_size_override("font_size", 18)


static func estilar_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.93, 0.88, 0.8, 1)
	track.set_corner_radius_all(8)
	track.set_border_width_all(2)
	track.border_color = Color(1, 1, 1, 1)
	track.content_margin_top = 6
	track.content_margin_bottom = 6

	var fill := StyleBoxFlat.new()
	fill.bg_color = NARANJA
	fill.set_corner_radius_all(8)

	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)


static func etiqueta(label: Label, claro: bool = false, tamano: int = 18) -> void:
	label.add_theme_font_size_override("font_size", tamano)
	label.add_theme_color_override("font_color", TEXTO_CLARO if claro else TEXTO)
