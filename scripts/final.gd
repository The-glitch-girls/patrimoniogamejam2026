extends Control

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const ICONO_JUGAR := preload("res://assets/icons/play.svg")
const FONDO := preload("res://assets/menu_principal.png")
const CREMA := Color(0.99, 0.96, 0.9, 1)
const LILA := Color(0.72, 0.68, 0.95, 1)
const VERDE := Color(0.49, 0.76, 0.29, 1)
const MORADO := Color(0.22, 0.2, 0.42, 1)

const TEXTOS := {
	"mar": {
		"titulo": "El mar",
		"texto": "Cavillaca se sumerge junto al bebé.",
	},
	"cuniraya": {
		"titulo": "Cuniraya",
		"texto": "La energía se apagó. Él la alcanzó.",
	},
}


func _ready() -> void:
	_armar()
	if OS.get_cmdline_user_args().has("--finalshot"):
		_capturar()


func _capturar() -> void:
	var arbol := get_tree()
	if arbol == null:
		return
	await arbol.process_frame
	await arbol.create_timer(0.45).timeout
	var imagen := arbol.root.get_viewport().get_texture().get_image()
	imagen.save_png("screenshot_final.png")
	arbol.quit()


func _armar() -> void:
	var tipo := Global.resultado_final
	if tipo == "":
		tipo = "mar"
	var dato: Dictionary = TEXTOS[tipo]

	var fondo := TextureRect.new()
	fondo.texture = FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	var degradado := TextureRect.new()
	degradado.set_anchors_preset(Control.PRESET_FULL_RECT)
	degradado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	degradado.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var gradiente := Gradient.new()
	gradiente.colors = PackedColorArray([
		Color(0.18, 0.12, 0.36, 0.55),
		Color(0.12, 0.1, 0.28, 0.78),
	])
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill_from = Vector2(0.5, 0.0)
	textura.fill_to = Vector2(0.5, 1.0)
	textura.width = 8
	textura.height = 256
	degradado.texture = textura
	add_child(degradado)

	var titulo := Label.new()
	titulo.text = dato.titulo
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.set_anchors_preset(Control.PRESET_CENTER)
	titulo.offset_left = -280
	titulo.offset_top = -160
	titulo.offset_right = 280
	titulo.offset_bottom = -70
	titulo.add_theme_font_override("font", FUENTE)
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.add_theme_color_override("font_color", CREMA)
	titulo.add_theme_color_override("font_outline_color", Color(0.12, 0.1, 0.18, 1))
	titulo.add_theme_constant_override("outline_size", 10)
	add_child(titulo)

	var texto := Label.new()
	texto.text = dato.texto
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(Control.PRESET_CENTER)
	texto.offset_left = -320
	texto.offset_top = -62
	texto.offset_right = 320
	texto.offset_bottom = -20
	texto.add_theme_font_override("font", FUENTE)
	texto.add_theme_font_size_override("font_size", 22)
	texto.add_theme_color_override("font_color", LILA)
	add_child(texto)

	var boton := BotonCirculo.new()
	boton.color_fondo = VERDE
	boton.icono = ICONO_JUGAR
	boton.tamano = 88.0
	boton.set_anchors_preset(Control.PRESET_CENTER)
	boton.offset_left = -44
	boton.offset_top = 24
	boton.offset_right = 44
	boton.offset_bottom = 112
	boton.pressed.connect(_volver)
	add_child(boton)

	var leyenda := Label.new()
	leyenda.text = "Volver a jugar"
	leyenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leyenda.set_anchors_preset(Control.PRESET_CENTER)
	leyenda.offset_left = -140
	leyenda.offset_top = 122
	leyenda.offset_right = 140
	leyenda.offset_bottom = 150
	leyenda.add_theme_font_override("font", FUENTE)
	leyenda.add_theme_font_size_override("font_size", 18)
	leyenda.add_theme_color_override("font_color", CREMA)
	add_child(leyenda)

	boton.enfocar()


func _volver() -> void:
	Global.resetear()
	Musica.tocar("menu")
	get_tree().change_scene_to_file("res://scenes/MenuInicio.tscn")
