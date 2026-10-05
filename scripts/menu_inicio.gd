extends Control

const CREDITS := [
	"Melissa Huerta",
	"Shiara",
	"Malu",
	"Ariadna",
	"Selene",
	"Miko",
]

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const MORADO := Color(0.22, 0.2, 0.42, 1)
const CREMA := Color(0.99, 0.96, 0.9, 1)
const LILA := Color(0.72, 0.68, 0.95, 1)


func _ready() -> void:
	theme = Theme.new()
	_tipografia()
	_conectar()
	_mostrar_inicio()
	Musica.tocar("menu")
	if OS.get_cmdline_user_args().has("--shot"):
		_capturar()
	elif OS.get_cmdline_user_args().has("--finalshot"):
		Global.resultado_final = "mar"
		get_tree().change_scene_to_file.call_deferred("res://scenes/Final.tscn")


func _capturar() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.45).timeout
	var imagen := get_viewport().get_texture().get_image()
	imagen.save_png("screenshot_menu.png")
	get_tree().quit()


func _tipografia() -> void:
	$PanelAjustes/Titulo.add_theme_font_override("font", FUENTE)
	$PanelAjustes/Titulo.add_theme_font_size_override("font_size", 28)
	$PanelAjustes/Titulo.add_theme_color_override("font_color", CREMA)
	$PanelCreditos/Titulo.add_theme_font_override("font", FUENTE)
	$PanelCreditos/Titulo.add_theme_font_size_override("font_size", 28)
	$PanelCreditos/Titulo.add_theme_color_override("font_color", CREMA)
	$PanelCreditos/Lista.add_theme_font_override("font", FUENTE)
	$PanelCreditos/Lista.add_theme_font_size_override("font_size", 22)
	$PanelCreditos/Lista.add_theme_color_override("font_color", CREMA)
	$PanelCreditos/Lista.text = "\n".join(CREDITS)
	for label in [
		$PanelAjustes/MasterLabel,
		$PanelAjustes/MusicaLabel,
		$PanelAjustes/EfectosLabel,
		$PanelAjustes/AmbienteLabel,
	]:
		label.add_theme_font_override("font", FUENTE)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", CREMA)
	_tarjeta($PanelAjustes)
	_tarjeta($PanelCreditos)


func _tarjeta(panel: Panel) -> void:
	var caja := StyleBoxFlat.new()
	caja.bg_color = MORADO
	caja.set_corner_radius_all(28)
	caja.set_border_width_all(6)
	caja.border_color = Color.WHITE
	caja.shadow_color = Color(0, 0, 0, 0.28)
	caja.shadow_size = 12
	caja.shadow_offset = Vector2(0, 6)
	caja.content_margin_left = 28
	caja.content_margin_top = 24
	caja.content_margin_right = 28
	caja.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", caja)

func _conectar() -> void:
	$Fila/Jugar.pressed.connect(_jugar)
	$Fila/Ajustes.pressed.connect(_abrir_ajustes)
	$Fila/Creditos.pressed.connect(_abrir_creditos)
	$Fila/Salir.pressed.connect(_salir)
	$PanelAjustes/Volver.pressed.connect(_mostrar_inicio)
	$PanelCreditos/Volver.pressed.connect(_mostrar_inicio)
	$PanelAjustes/MasterSlider.value_changed.connect(Ajustes.set_volumen_master)
	$PanelAjustes/MusicaSlider.value_changed.connect(Ajustes.set_volumen_musica)
	$PanelAjustes/EfectosSlider.value_changed.connect(Ajustes.set_volumen_efectos)
	$PanelAjustes/AmbienteSlider.value_changed.connect(Ajustes.set_volumen_ambiente)
	$PanelAjustes/MasterSlider.value = Ajustes.volumen_master
	$PanelAjustes/MusicaSlider.value = Ajustes.volumen_musica
	$PanelAjustes/EfectosSlider.value = Ajustes.volumen_efectos
	$PanelAjustes/AmbienteSlider.value = Ajustes.volumen_ambiente

	#$Fila/Jugar.pressed.connect(_jugar)
	#$Fila/Ajustes.pressed.connect(_abrir_ajustes)
	#$Fila/Creditos.pressed.connect(_abrir_creditos)
	#$Fila/Salir.pressed.connect(_salir)

func _mostrar_inicio() -> void:
	$Fila.visible = true
	$PanelAjustes.visible = false
	$PanelCreditos.visible = false

func _abrir_ajustes() -> void:
	$Fila.visible = false
	$PanelAjustes.visible = true
	$PanelCreditos.visible = false
	$PanelAjustes/MasterSlider.grab_focus()


func _abrir_creditos() -> void:
	$Fila.visible = false
	$PanelAjustes.visible = false
	$PanelCreditos.visible = true
	$PanelCreditos/Volver.enfocar()


func _jugar() -> void:
	Global.resetear()
	Musica.tocar("juego")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _salir() -> void:
	get_tree().quit()
