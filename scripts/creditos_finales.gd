extends Control

const COLOR_CREDITOS := Color("#C1A4EA")
const ESTILO_TEXTO: LabelSettings = preload("res://resources/ajustes_textos.tres")
const VELOCIDAD_DESPLAZAMIENTO := 32.0
const CREDITOS := [
	{"nombre": "credit_ariadna_mestanza_name", "rol": "credit_role_ariadna"},
	{"nombre": "credit_selene_negron_name", "rol": "credit_role_selene"},
	{"nombre": "credit_andres_porras_name", "rol": "credit_role_andres"},
	{"nombre": "credit_malu_munayco_name", "rol": "credit_role_game_developer"},
	{"nombre": "credit_melissa_huerta_name", "rol": "credit_role_game_developer"},
	{"nombre": "credit_shiara_arauzo_name", "rol": "credit_role_game_developer"},
	{"nombre": "credit_adrian_gutierrez_name", "rol": "credit_role_music_composition"},
	{"nombre": "credit_sumiko_de_los_santos_name", "rol": "credit_role_ui_assets"},
]

var etiquetas: Array[Label] = []
@onready var area_creditos: Control = $AreaVisibleCreditos
@onready var columna: VBoxContainer = $AreaVisibleCreditos/ListaCreditos
@onready var mensaje_continuar: Label = $MensajeContinuar
var puede_continuar := false


func _ready() -> void:
	clip_contents = true
	columna.position.y = area_creditos.size.y
	mensaje_continuar.label_settings = _estilo_creditos(18)

	for credito in CREDITOS:
		var entrada := VBoxContainer.new()
		entrada.add_theme_constant_override("separation", 0)
		entrada.mouse_filter = Control.MOUSE_FILTER_IGNORE
		columna.add_child(entrada)
		etiquetas.append(_crear_etiqueta(credito.nombre, 26, entrada))
		etiquetas.append(_crear_etiqueta(credito.rol, 18, entrada))

	mensaje_continuar.visible = false
	Traducciones.idioma_cambiado.connect(_actualizar_textos)
	_actualizar_textos(Global.idioma_actual)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	columna.size.y = columna.get_combined_minimum_size().y
	var altura_area := area_creditos.size.y
	columna.position.y = altura_area
	var posicion_final_y := -columna.size.y
	var duracion := (altura_area + columna.size.y) / VELOCIDAD_DESPLAZAMIENTO
	var desplazamiento := create_tween()
	desplazamiento.set_trans(Tween.TRANS_LINEAR)
	desplazamiento.tween_property(columna, "position:y", posicion_final_y, duracion)
	await desplazamiento.finished
	if not is_inside_tree():
		return
	mensaje_continuar.modulate.a = 0.0
	mensaje_continuar.visible = true
	var aparecer := create_tween()
	aparecer.tween_property(mensaje_continuar, "modulate:a", 1.0, 0.8)
	await aparecer.finished
	puede_continuar = true


func _crear_etiqueta(clave: String, tamano: int, padre: Control) -> Label:
	var etiqueta := Label.new()
	etiqueta.label_settings = _estilo_creditos(tamano)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.set_meta("clave_traduccion", clave)
	padre.add_child(etiqueta)
	return etiqueta


func _estilo_creditos(tamano: int) -> LabelSettings:
	var estilo := ESTILO_TEXTO.duplicate() as LabelSettings
	estilo.font_size = tamano
	estilo.font_color = COLOR_CREDITOS
	return estilo


func _actualizar_textos(_idioma: String = "") -> void:
	for etiqueta in etiquetas:
		var clave: String = etiqueta.get_meta("clave_traduccion")
		etiqueta.text = Traducciones.obtener(clave)
	if is_instance_valid(mensaje_continuar):
		mensaje_continuar.text = Traducciones.obtener("credits_continue")


func _input(event: InputEvent) -> void:
	if not puede_continuar or not (event is InputEventKey):
		return
	var tecla := event as InputEventKey
	if tecla.pressed and not tecla.echo:
		Musica.detener()
		get_tree().change_scene_to_file("res://scenes/MenuInicio.tscn")
