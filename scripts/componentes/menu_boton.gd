extends Control

signal pressed

@onready var boton: TextureButton = $Boton
@onready var texto: Label = $Centro/Texto

@export var clave: String = "play"

const COLOR_NORMAL := Color("#493783")
const COLOR_PRESSED := Color("#E9D9FF")

var _mouse_dentro := false
var _presionando := false

var _label_settings: LabelSettings
var _textura_normal: Texture2D
var _textura_hover: Texture2D
var _textura_pressed: Texture2D

func _ready() -> void:
	# Focus del botón
	boton.focus_mode = Control.FOCUS_ALL
	
	$Centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Guardar las tres texturas
	_textura_normal = boton.texture_normal
	_textura_hover = boton.texture_hover
	_textura_pressed = boton.texture_pressed
	
	if texto.label_settings:
		_label_settings = texto.label_settings.duplicate()
		texto.label_settings = _label_settings

	# Controlar los estados visuales
	boton.texture_hover = null
	boton.texture_pressed = null
	boton.texture_focused = null
	
	# Eventos
	boton.mouse_entered.connect(_al_entrar)
	boton.mouse_exited.connect(_al_salir)
	boton.button_down.connect(_al_apretar)
	boton.button_up.connect(_al_soltar)
	boton.pressed.connect(_al_presionar)

	boton.focus_entered.connect(_al_enfocar)
	boton.focus_exited.connect(_al_desenfocar)
	
	_set_color_normal()
	_actualizar_textura()

func _al_entrar() -> void:
	_mouse_dentro = true
	_actualizar_textura()

func _al_salir() -> void:
	_mouse_dentro = false
	_actualizar_textura()

func _al_apretar() -> void:
	_presionando = true
	_actualizar_textura()
	_set_color_pressed()

func _al_soltar() -> void:
	_presionando = false
	_actualizar_textura()

func _al_presionar() -> void:
	pressed.emit()

func _al_enfocar() -> void:
	_actualizar_textura()
	_set_color_pressed()

func _al_desenfocar() -> void:
	_actualizar_textura()
	
func _actualizar_textura() -> void:
	if _presionando:
		boton.texture_normal = _textura_pressed
	elif boton.has_focus():
		boton.texture_normal = _textura_pressed
	elif _mouse_dentro:
		boton.texture_normal = _textura_hover
	else:
		boton.texture_normal = _textura_normal

func _set_color_normal() -> void:
	if _label_settings:
		_label_settings.font_color = COLOR_NORMAL

func _set_color_pressed() -> void:
	if _label_settings:
		_label_settings.font_color = COLOR_PRESSED

func _actualizar_texto() -> void:
	pass
