extends Control

signal terminado

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const CREMA := Color(0.99, 0.96, 0.9, 1)
const VERDE := Color(0.49, 0.76, 0.29, 1)

var indice := 1
var cerrando := false

func configurar(n: int) -> void:
	indice = clampi(n, 1, Global.RECUERDOS_TOTALES)


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Global.flashback_abierto = true
	get_tree().paused = true
	$RecuerdoSFX.play()
	$RecuerdoMusica.stop()
	$RecuerdoMusica.play(0.0)
	
	_aplicar_texto()
	_aplicar_asset()
	_estilar()

	$Continuar.visible = false
	$Continuar.pressed.connect(_continuar)
	await _animar_apertura()

func _aplicar_texto() -> void:
	var dato: Dictionary = Global.RECUERDOS[indice]
	$Titulo.text = Traducciones.obtener(dato.titulo)
	$Texto.text = Traducciones.obtener(dato.texto)

func _aplicar_asset() -> void:
	var dato: Dictionary = Global.RECUERDOS[indice]

	if dato.has("asset"):
		$AssetRecuerdo.texture = load(dato.asset)
		$AssetRecuerdo.visible = true
		$ColorRect.visible = true
	else:
		$AssetRecuerdo.visible = false
		$ColorRect.visible = true
		

func _animar_apertura() -> void:
	$Titulo.modulate.a = 0.0
	$Texto.modulate.a = 0.0
	$Texto.visible_ratio = 0.0
	$Continuar.modulate.a = 0.0

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if $AssetRecuerdo.visible:
		$AssetRecuerdo.pivot_offset = $AssetRecuerdo.size * 0.5
		$AssetRecuerdo.scale = Vector2(1.035, 1.035)
		$ColorRect.color = Color(0.12, 0.1, 0.28, 1.0)
		$ColorRect.modulate.a = 1.0
		tween.tween_property($ColorRect, "color:a", 0.0, 0.75)
		tween.parallel().tween_property($AssetRecuerdo, "scale", Vector2.ONE, 0.9)
	else:
		tween.tween_interval(0.2)

	$Titulo.offset_top += 14.0
	$Titulo.offset_bottom += 14.0
	tween.tween_interval(0.1)
	tween.tween_property($Titulo, "modulate:a", 1.0, 0.35)
	tween.parallel().tween_property($Titulo, "offset_top", 0.0, 0.35)
	tween.parallel().tween_property($Titulo, "offset_bottom", 0.0, 0.35)
	tween.tween_interval(0.1)
	tween.tween_property($Texto, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property($Texto, "visible_ratio", 1.0, 1.6)
	await tween.finished

	if $AssetRecuerdo.visible:
		$ColorRect.visible = false
	$Continuar.visible = true
	var boton_tween := create_tween()
	boton_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	boton_tween.tween_property($Continuar, "modulate:a", 1.0, 0.2)


func _estilar() -> void:
	$ColorRect.color = Color(0.12, 0.1, 0.28, 0.72)
	for label in [$Titulo, $Texto]:
		label.add_theme_font_override("font", FUENTE)
		label.add_theme_color_override("font_color", CREMA)
	$Titulo.add_theme_font_size_override("font_size", 22)
	$Titulo.anchor_left = 0.05
	$Titulo.anchor_right = 0.53
	$Titulo.anchor_top = 0.74
	$Titulo.anchor_bottom = 0.82
	$Titulo.offset_left = 0
	$Titulo.offset_right = 0
	$Titulo.offset_top = 0
	$Titulo.offset_bottom = 0
	$Titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	$Texto.anchor_left = 0.05
	$Texto.anchor_right = 0.335
	$Texto.anchor_top = 0.82
	$Texto.anchor_bottom = 0.99
	$Texto.offset_left = 0
	$Texto.offset_right = 0
	$Texto.offset_top = 0
	$Texto.offset_bottom = 0
	$Texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	$Continuar.anchor_left = 1.0
	$Continuar.anchor_right = 1.0
	$Continuar.anchor_top = 1.0
	$Continuar.anchor_bottom = 1.0
	$Continuar.offset_left = -215
	$Continuar.offset_right = -40
	$Continuar.offset_top = -98
	$Continuar.offset_bottom = -40


func _continuar() -> void:
	if cerrando:
		return
	cerrando = true
	$Continuar.disabled = true
	$ColorRect.visible = true
	$ColorRect.color = Color(0.12, 0.1, 0.28, 0.0)

	var tween_cierre := create_tween()
	tween_cierre.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_cierre.set_parallel(true)
	tween_cierre.tween_property($ColorRect, "color:a", 1.0, 0.65)
	tween_cierre.tween_property($Titulo, "modulate:a", 0.0, 0.4)
	tween_cierre.tween_property($Texto, "modulate:a", 0.0, 0.4)
	tween_cierre.tween_property($Continuar, "modulate:a", 0.0, 0.3)
	tween_cierre.tween_property($RecuerdoMusica, "volume_db", -50.0, 0.65)
	if $AssetRecuerdo.visible:
		tween_cierre.tween_property($AssetRecuerdo, "scale", Vector2(1.035, 1.035), 0.65)
	await tween_cierre.finished
	$RecuerdoMusica.stop()

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
