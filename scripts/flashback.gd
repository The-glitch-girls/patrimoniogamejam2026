extends Control

signal terminado

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const CREMA := Color(0.99, 0.96, 0.9, 1)
const VERDE := Color(0.49, 0.76, 0.29, 1)
const TEXTURAS_CONTINUAR := {
	"es": preload("res://assets/ui/recuerdos/continuar_es.png"),
	"en": preload("res://assets/ui/recuerdos/continuar_en.png"),
	"fr": preload("res://assets/ui/recuerdos/continuar_fr.png"),
}
const TEXTURAS_CONTINUAR_PRESIONADO := {
	"es": preload("res://assets/ui/recuerdos/continuar_es_pressed.png"),
	"en": preload("res://assets/ui/recuerdos/continuar_en_pressed.png"),
	"fr": preload("res://assets/ui/recuerdos/continuar_fr_pressed.png"),
}

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
	_actualizar_texturas_continuar(Global.idioma_actual)
	Traducciones.idioma_cambiado.connect(_actualizar_texturas_continuar)

	$Continuar.visible = false
	$Continuar.pressed.connect(_continuar)
	await _animar_apertura()

func _aplicar_texto() -> void:
	var dato: Dictionary = Global.RECUERDOS[indice]
	$CajaRecuerdo/Titulo.text = Traducciones.obtener(dato.titulo)
	$CajaRecuerdo/Texto.text = Traducciones.obtener(dato.texto)


func _actualizar_texturas_continuar(idioma: String) -> void:
	var codigo := idioma if TEXTURAS_CONTINUAR.has(idioma) else "es"
	$Continuar.texture_normal = TEXTURAS_CONTINUAR[codigo]
	$Continuar.texture_pressed = TEXTURAS_CONTINUAR_PRESIONADO[codigo]

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
	$CajaRecuerdo.modulate.a = 0.0
	$CajaRecuerdo/Titulo.modulate.a = 0.0
	$CajaRecuerdo/Texto.modulate.a = 0.0
	$CajaRecuerdo/Texto.visible_ratio = 0.0
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

	tween.tween_interval(0.12)
	tween.tween_property($CajaRecuerdo, "modulate:a", 1.0, 0.35)
	$CajaRecuerdo/Titulo.offset_top += 14.0
	$CajaRecuerdo/Titulo.offset_bottom += 14.0
	tween.tween_interval(0.1)
	tween.tween_property($CajaRecuerdo/Titulo, "modulate:a", 1.0, 0.35)
	tween.parallel().tween_property($CajaRecuerdo/Titulo, "offset_top", 0.0, 0.35)
	tween.parallel().tween_property($CajaRecuerdo/Titulo, "offset_bottom", 0.0, 0.35)
	tween.tween_interval(0.1)
	tween.tween_property($CajaRecuerdo/Texto, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property($CajaRecuerdo/Texto, "visible_ratio", 1.0, 1.6)
	await tween.finished

	if $AssetRecuerdo.visible:
		$ColorRect.visible = false
	$Continuar.visible = true
	var boton_tween := create_tween()
	boton_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	boton_tween.tween_property($Continuar, "modulate:a", 1.0, 0.2)


func _estilar() -> void:
	$ColorRect.color = Color(0.12, 0.1, 0.28, 0.72)
	for label in [$CajaRecuerdo/Titulo, $CajaRecuerdo/Texto]:
		label.add_theme_font_override("font", FUENTE)
		label.add_theme_color_override("font_color", CREMA)
	$CajaRecuerdo/Titulo.add_theme_font_size_override("font_size", 36)
	var ajustes_texto: LabelSettings = $CajaRecuerdo/Texto.label_settings.duplicate()
	ajustes_texto.font_size = 25
	$CajaRecuerdo/Texto.label_settings = ajustes_texto
	$CajaRecuerdo/Titulo.anchor_left = 0.06
	$CajaRecuerdo/Titulo.anchor_right = 0.94
	$CajaRecuerdo/Titulo.anchor_top = 0.17
	$CajaRecuerdo/Titulo.anchor_bottom = 0.36
	$CajaRecuerdo/Titulo.offset_left = 0
	$CajaRecuerdo/Titulo.offset_right = 0
	$CajaRecuerdo/Titulo.offset_top = 0
	$CajaRecuerdo/Titulo.offset_bottom = 0
	$CajaRecuerdo/Titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	$CajaRecuerdo/Texto.anchor_left = 0.06
	$CajaRecuerdo/Texto.anchor_right = 0.94
	$CajaRecuerdo/Texto.anchor_top = 0.40
	$CajaRecuerdo/Texto.anchor_bottom = 0.91
	$CajaRecuerdo/Texto.offset_left = 0
	$CajaRecuerdo/Texto.offset_right = 0
	$CajaRecuerdo/Texto.offset_top = 0
	$CajaRecuerdo/Texto.offset_bottom = 0
	$CajaRecuerdo/Texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	$CajaRecuerdo/Texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var boton := StyleBoxFlat.new()
	boton.bg_color = VERDE
	boton.set_corner_radius_all(22)
	boton.set_border_width_all(5)
	boton.border_color = Color.WHITE


func _continuar() -> void:
	Global.reproducir_clic()
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
	tween_cierre.tween_property($CajaRecuerdo, "modulate:a", 0.0, 0.4)
	tween_cierre.tween_property($CajaRecuerdo/Titulo, "modulate:a", 0.0, 0.4)
	tween_cierre.tween_property($CajaRecuerdo/Texto, "modulate:a", 0.0, 0.4)
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
