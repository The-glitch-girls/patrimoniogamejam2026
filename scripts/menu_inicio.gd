extends Control

const CREDITS := [
	"Melissa Huerta",
	"Shiara",
	"Malu",
	"Ariadna",
	"Selene",
	"Miko",
]


func _ready() -> void:
	_estilar()
	_conectar()
	_llenar_creditos()
	_mostrar_principal()
	$PanelPrincipal/Columna/Jugar.grab_focus()
	if OS.get_cmdline_user_args().has("--shot"):
		_capturar()


func _capturar() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	var imagen := get_viewport().get_texture().get_image()
	imagen.save_png("screenshot_menu.png")
	get_tree().quit()


func _conectar() -> void:
	$PanelPrincipal/Columna/Jugar.pressed.connect(_jugar)
	$PanelPrincipal/Columna/Ajustes.pressed.connect(_abrir_ajustes)
	$PanelPrincipal/Columna/Creditos.pressed.connect(_abrir_creditos)
	$PanelPrincipal/Columna/Salir.pressed.connect(_salir)
	$PanelAjustes/Columna/Volver.pressed.connect(_mostrar_principal)
	$PanelCreditos/Columna/Volver.pressed.connect(_mostrar_principal)
	$PanelAjustes/Columna/MasterSlider.value_changed.connect(_on_master)
	$PanelAjustes/Columna/MusicaSlider.value_changed.connect(_on_musica)
	$PanelAjustes/Columna/EfectosSlider.value_changed.connect(_on_efectos)
	$PanelAjustes/Columna/AmbienteSlider.value_changed.connect(_on_ambiente)


func _estilar() -> void:
	$Fondo.color = UiEstilo.FONDO
	for panel in [$PanelPrincipal, $PanelAjustes, $PanelCreditos]:
		panel.add_theme_stylebox_override("panel", UiEstilo.panel_crema())
	for encabezado in [
		$PanelPrincipal/Encabezado,
		$PanelAjustes/Encabezado,
		$PanelCreditos/Encabezado,
	]:
		encabezado.add_theme_stylebox_override("panel", UiEstilo.encabezado())

	UiEstilo.etiqueta($PanelPrincipal/Encabezado/Titulo, true, 28)
	UiEstilo.etiqueta($PanelPrincipal/Subtitulo, false, 16)
	UiEstilo.etiqueta($PanelAjustes/Encabezado/Titulo, true, 24)
	UiEstilo.etiqueta($PanelCreditos/Encabezado/Titulo, true, 24)
	UiEstilo.etiqueta($PanelAjustes/Columna/MasterLabel, false, 16)
	UiEstilo.etiqueta($PanelAjustes/Columna/MusicaLabel, false, 16)
	UiEstilo.etiqueta($PanelAjustes/Columna/EfectosLabel, false, 16)
	UiEstilo.etiqueta($PanelAjustes/Columna/AmbienteLabel, false, 16)
	UiEstilo.etiqueta($PanelCreditos/Columna/Lista, false, 22)

	UiEstilo.estilar_boton($PanelPrincipal/Columna/Jugar, UiEstilo.VERDE)
	UiEstilo.estilar_boton($PanelPrincipal/Columna/Ajustes)
	UiEstilo.estilar_boton($PanelPrincipal/Columna/Creditos)
	UiEstilo.estilar_boton_secundario($PanelPrincipal/Columna/Salir)
	UiEstilo.estilar_boton_secundario($PanelAjustes/Columna/Volver)
	UiEstilo.estilar_boton_secundario($PanelCreditos/Columna/Volver)

	UiEstilo.estilar_slider($PanelAjustes/Columna/MasterSlider)
	UiEstilo.estilar_slider($PanelAjustes/Columna/MusicaSlider)
	UiEstilo.estilar_slider($PanelAjustes/Columna/EfectosSlider)
	UiEstilo.estilar_slider($PanelAjustes/Columna/AmbienteSlider)

	$PanelAjustes/Columna/MasterSlider.value = Ajustes.volumen_master
	$PanelAjustes/Columna/MusicaSlider.value = Ajustes.volumen_musica
	$PanelAjustes/Columna/EfectosSlider.value = Ajustes.volumen_efectos
	$PanelAjustes/Columna/AmbienteSlider.value = Ajustes.volumen_ambiente


func _llenar_creditos() -> void:
	$PanelCreditos/Columna/Lista.text = "\n".join(CREDITS)


func _mostrar_principal() -> void:
	$PanelPrincipal.visible = true
	$PanelAjustes.visible = false
	$PanelCreditos.visible = false
	$PanelPrincipal/Columna/Jugar.grab_focus()


func _abrir_ajustes() -> void:
	$PanelPrincipal.visible = false
	$PanelAjustes.visible = true
	$PanelCreditos.visible = false
	$PanelAjustes/Columna/MasterSlider.grab_focus()


func _abrir_creditos() -> void:
	$PanelPrincipal.visible = false
	$PanelAjustes.visible = false
	$PanelCreditos.visible = true
	$PanelCreditos/Columna/Volver.grab_focus()


func _jugar() -> void:
	Global.resetear()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _salir() -> void:
	get_tree().quit()


func _on_master(valor: float) -> void:
	Ajustes.set_volumen_master(valor)


func _on_musica(valor: float) -> void:
	Ajustes.set_volumen_musica(valor)


func _on_efectos(valor: float) -> void:
	Ajustes.set_volumen_efectos(valor)


func _on_ambiente(valor: float) -> void:
	Ajustes.set_volumen_ambiente(valor)
