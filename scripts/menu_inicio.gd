extends Control

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const CREMA := Color(0.99, 0.96, 0.9, 1)
@onready var version_label := $Version
const ESCENA_MAIN := "res://scenes/Main.tscn"
const ESCENA_LEYENDA := "res://scenes/Leyenda.tscn"
var iniciando_juego := false

func _ready() -> void:
	theme = Theme.new()
	_tipografia()
	_conectar()
	_set_version()
	_mostrar_inicio()
	ResourceLoader.load_threaded_request("res://resources/cavillaca.tres")
	ResourceLoader.load_threaded_request(ESCENA_MAIN) # Cargar en segundo plano
	ResourceLoader.load_threaded_request(ESCENA_LEYENDA)
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
	# Panel Ajustes
	for label in [
		$OverlayAjustes/PanelAjustes/MSXLabelContainer/MusicaLabel,
		$OverlayAjustes/PanelAjustes/SFXLabelContainer/SFXLabel,
	]:
		label.add_theme_font_override("font", FUENTE)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", CREMA)

func _conectar() -> void:
	$Fila/Jugar.pressed.connect(_jugar)
	$Fila/Ajustes.pressed.connect(_abrir_ajustes)
	$Fila/Creditos.pressed.connect(_abrir_creditos)
	$Fila/Salir.pressed.connect(_salir)
	$OverlayAjustes.connect("cerrar", Callable(self, "_mostrar_inicio"))
	$OverlayCreditos.cerrar.connect(_mostrar_inicio)

func _mostrar_inicio() -> void:
	for nombre_boton in ["Jugar", "Ajustes", "Creditos"]:
		$Fila.get_node(nombre_boton).restaurar_estado_normal()
	$Fila.visible = true
	$Titulo.visible = true
	$Version.visible = true
	$OverlayAjustes.visible = false
	$OverlayCreditos.visible = false

func _abrir_ajustes() -> void:
	$Fila.visible = false
	$Titulo.visible = false
	$Version.visible = false
	$OverlayAjustes.visible = true
	$OverlayCreditos.visible = false

func _abrir_creditos() -> void:
	$Fila.visible = false
	$Titulo.visible = false
	$Version.visible = false
	$OverlayAjustes.visible = false
	$OverlayCreditos.visible = true

func _jugar() -> void:
	if iniciando_juego:
		return
	iniciando_juego = true
	Global.resetear()
	Musica.tocar("juego")
	$Fila/Jugar/Centro/Texto.text = Traducciones.obtener("loading")
	await get_tree().process_frame

	var estado := ResourceLoader.load_threaded_get_status(ESCENA_LEYENDA)
	if estado == ResourceLoader.THREAD_LOAD_FAILED:
		var solicitud := ResourceLoader.load_threaded_request(ESCENA_LEYENDA)
		if solicitud != OK:
			push_error("No se pudo iniciar la carga de Leyenda.tscn (código %d)" % solicitud)
			$Fila/Jugar/Centro/Texto.text = Traducciones.obtener("play")
			iniciando_juego = false
			return
		estado = ResourceLoader.load_threaded_get_status(ESCENA_LEYENDA)
	while estado == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		estado = ResourceLoader.load_threaded_get_status(ESCENA_LEYENDA)

	var escena: PackedScene
	if estado == ResourceLoader.THREAD_LOAD_LOADED:
		escena = ResourceLoader.load_threaded_get(ESCENA_LEYENDA) as PackedScene
	else:
		push_error("Falló la carga en segundo plano de Leyenda.tscn (estado %d)" % estado)
		$Fila/Jugar/Centro/Texto.text = Traducciones.obtener("play")
		iniciando_juego = false
		return
	if escena == null:
		push_error("No se pudo cargar Leyenda.tscn")
		$Fila/Jugar/Centro/Texto.text = Traducciones.obtener("play")
		iniciando_juego = false
		return

	get_tree().change_scene_to_packed(escena)

func _salir() -> void:
	get_tree().quit()

func _set_version() -> void:
	var project_version = ProjectSettings.get_setting("application/config/version", "0.0.0")
	version_label.text = "v " + project_version
