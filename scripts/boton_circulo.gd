class_name BotonCirculo
extends Control

signal pressed

@export var color_fondo := Color(0.49, 0.76, 0.29, 1)
@export var icono: Texture2D
@export var tamano := 88.0

var _boton: Button
var _panel: Panel
var _icono: TextureRect
var _idle := 0.0
var _fase := 0.0
var _sobre := false


func _ready() -> void:
	custom_minimum_size = Vector2(tamano, tamano)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pivot_offset = Vector2(tamano * 0.5, tamano * 0.5)
	_fase = randf() * TAU
	_armar()


func _armar() -> void:
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", _circulo(color_fondo))
	add_child(_panel)

	_icono = TextureRect.new()
	_icono.texture = icono
	_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icono.set_anchors_preset(Control.PRESET_CENTER)
	_icono.offset_left = -20
	_icono.offset_top = -20
	_icono.offset_right = 20
	_icono.offset_bottom = 20
	add_child(_icono)

	_boton = Button.new()
	_boton.flat = true
	_boton.theme = Theme.new()
	_boton.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var vacio := StyleBoxEmpty.new()
	for nombre in ["normal", "hover", "pressed", "focus", "disabled"]:
		_boton.add_theme_stylebox_override(nombre, vacio)
	_boton.pressed.connect(func(): pressed.emit())
	_boton.mouse_entered.connect(_al_entrar)
	_boton.mouse_exited.connect(_al_salir)
	_boton.button_down.connect(_al_apretar)
	_boton.button_up.connect(_al_soltar)
	add_child(_boton)


func _process(delta: float) -> void:
	_idle += delta
	if _sobre:
		return
	rotation = sin(_idle * 1.3 + _fase) * 0.04
	scale = Vector2.ONE * (1.0 + sin(_idle * 2.4 + _fase) * 0.02)


func _circulo(color: Color) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = color
	caja.set_corner_radius_all(int(tamano))
	caja.set_border_width_all(6)
	caja.border_color = Color.WHITE
	caja.shadow_color = Color(0, 0, 0, 0.22)
	caja.shadow_size = 8
	caja.shadow_offset = Vector2(0, 4)
	return caja


func _al_entrar() -> void:
	_sobre = true
	_tween_escala(1.1)


func _al_salir() -> void:
	_sobre = false
	_tween_escala(1.0)


func _al_apretar() -> void:
	_tween_escala(0.92)


func _al_soltar() -> void:
	_tween_escala(1.1 if _sobre else 1.0)


func _tween_escala(destino: float) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE * destino, 0.18)


func enfocar() -> void:
	if _boton:
		_boton.grab_focus()
