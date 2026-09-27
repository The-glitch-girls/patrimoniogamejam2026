extends Control

signal terminado

const ID_FLASHBACK := "insistencia"
const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const CREMA := Color(0.99, 0.96, 0.9, 1)
const MORADO := Color(0.22, 0.2, 0.42, 0.92)
const VERDE := Color(0.49, 0.76, 0.29, 1)

func _ready():
	_estilar()
	$Continuar.pressed.connect(_continuar)


func _estilar() -> void:
	$ColorRect.color = Color(0.12, 0.1, 0.28, 0.55)
	for label in [$Titulo, $Texto]:
		label.add_theme_font_override("font", FUENTE)
		label.add_theme_color_override("font_color", CREMA)
	$Titulo.add_theme_font_size_override("font_size", 28)
	$Texto.add_theme_font_size_override("font_size", 20)
	var boton := StyleBoxFlat.new()
	boton.bg_color = VERDE
	boton.set_corner_radius_all(22)
	boton.set_border_width_all(5)
	boton.border_color = Color.WHITE
	$Continuar.add_theme_stylebox_override("normal", boton)
	$Continuar.add_theme_stylebox_override("hover", boton)
	$Continuar.add_theme_stylebox_override("pressed", boton)
	$Continuar.add_theme_font_override("font", FUENTE)
	$Continuar.add_theme_font_size_override("font_size", 18)
	$Continuar.add_theme_color_override("font_color", CREMA)
	$Continuar.add_theme_color_override("font_hover_color", CREMA)
	$Continuar.text = "Continuar"

func _continuar():
	if not ID_FLASHBACK in Global.flashbacks_desbloqueados:
		Global.flashbacks_desbloqueados.append(ID_FLASHBACK)
	
	Global.presencia_cuniraya += 1.0
	
	terminado.emit()
	queue_free()
