extends Control

signal terminado

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const CREMA := Color(0.99, 0.96, 0.9, 1)
const MORADO := Color(0.22, 0.2, 0.42, 0.92)
const VERDE := Color(0.49, 0.76, 0.29, 1)
const TIEMPO_CONTINUAR := 2.0

var indice := 1

func configurar(n: int) -> void:
	indice = clampi(n, 1, Global.RECUERDOS_TOTALES)


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Global.flashback_abierto = true
	get_tree().paused = true
	
	_aplicar_texto()
	_aplicar_asset()
	_estilar()

	$Continuar.visible = false
	$Continuar.pressed.connect(_continuar)

	_mostrar_continuar()

func _aplicar_texto() -> void:
	var dato: Dictionary = Global.RECUERDOS[indice]
	$Titulo.text = dato.titulo
	$Texto.text = dato.texto

func _aplicar_asset() -> void:
	var dato: Dictionary = Global.RECUERDOS[indice]

	if dato.has("asset"):
		$AssetRecuerdo.texture = load(dato.asset)
		$AssetRecuerdo.visible = true
		$ColorRect.visible = false
	else:
		$AssetRecuerdo.visible = false
		$ColorRect.visible = true
		

func _mostrar_continuar() -> void:
	await get_tree().create_timer(TIEMPO_CONTINUAR, true).timeout

	if is_instance_valid($Continuar):
		$Continuar.visible = true


func _estilar() -> void:
	$ColorRect.color = Color(0.12, 0.1, 0.28, 0.72)
	for label in [$Titulo, $Texto]:
		label.add_theme_font_override("font", FUENTE)
		label.add_theme_color_override("font_color", CREMA)
	$Titulo.add_theme_font_size_override("font_size", 36)
	$Texto.add_theme_font_size_override("font_size", 22)
	$Titulo.offset_left = -280
	$Titulo.offset_right = 280
	$Texto.offset_left = -280
	$Texto.offset_right = 280
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
	$Continuar.offset_left = -90
	$Continuar.offset_right = 90
	$Continuar.offset_top = -120
	$Continuar.offset_bottom = -72


func _continuar():
	var dato: Dictionary = Global.RECUERDOS[indice]
	var id: String = dato.id
	if not id in Global.flashbacks_desbloqueados:
		Global.flashbacks_desbloqueados.append(id)
	Global.flashback_abierto = false
	get_tree().paused = false
	if indice >= Global.RECUERDOS_TOTALES:
		Global.iniciar_hacia_el_mar()
	terminado.emit()
	queue_free()
