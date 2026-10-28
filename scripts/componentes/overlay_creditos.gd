extends Control

signal cerrar

const TITULOS := {
	"es": preload("res://assets/ui/creditos/titulo_ES.png"),
	"en": preload("res://assets/ui/creditos/titulo_EN.png"),
	"fr": preload("res://assets/ui/creditos/titulo_FR.png"),
}

const CLAVES_ROLES := [
	"credit_role_ariadna",
	"credit_role_selene",
	"credit_role_andres",
	"credit_role_game_developer",
	"credit_role_game_developer",
	"credit_role_game_developer",
	"credit_role_music_composition",
	"credit_role_ui_assets",
]

var contenido_desplazable: Control = null

@onready var etiquetas_roles: Array[Label] = [
	$PanelCreditos/Rol1Label,
	$PanelCreditos/Rol2Label,
	$PanelCreditos/Rol3Label,
	$PanelCreditos/Rol4Label,
	$PanelCreditos/Rol5Label,
	$PanelCreditos/Rol6Label,
	$PanelCreditos/Rol7Label,
	$PanelVisual2/Rol8Label,
]
@onready var titulo: TextureRect = $PanelCreditos/HBoxContainer/Titulo
@onready var boton_cerrar: TextureButton = $PanelCreditos/Cerrar
@onready var panel_visual: TextureRect = $PanelVisual
@onready var panel_visual_agradecimientos: TextureRect = get_node_or_null("PanelVisual2") as TextureRect
@onready var titulo_agradecimientos: Label = get_node_or_null("AgradecimientosLabel") as Label
@onready var indicador_desplazamiento: Label = get_node_or_null("ScrollHint") as Label


func _ready() -> void:
	_asegurar_etiquetas_desplazamiento()
	_configurar_desplazamiento()
	indicador_desplazamiento.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	indicador_desplazamiento.offset_left = -220.0
	indicador_desplazamiento.offset_top = -140.0
	indicador_desplazamiento.offset_right = -24.0
	indicador_desplazamiento.offset_bottom = -16.0
	indicador_desplazamiento.add_theme_color_override("font_color", Color(0.99, 0.96, 0.9, 1.0))
	indicador_desplazamiento.add_theme_font_size_override("font_size", 16)
	for indice in range(etiquetas_roles.size()):
		var etiqueta: Label = etiquetas_roles[indice]
		var estilo: LabelSettings = etiqueta.label_settings.duplicate()
		estilo.font_size = 16 if indice < 3 else 18
		etiqueta.label_settings = estilo
		if indice < 3:
			etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			etiqueta.size.x = 460.0
			etiqueta.size.y = 48.0
			var ancho_visible := etiqueta.size.x * absf(etiqueta.scale.x)
			etiqueta.position.x = (
				get_viewport_rect().size.x * 0.5
				- contenido_desplazable.global_position.x
				- ancho_visible * 0.5
			)
	Traducciones.idioma_cambiado.connect(_actualizar_roles)
	boton_cerrar.pressed.connect(_al_cerrar)
	_actualizar_roles(Global.idioma_actual)


func _al_cerrar() -> void:
	cerrar.emit()


func _asegurar_etiquetas_desplazamiento() -> void:
	if not is_instance_valid(titulo_agradecimientos):
		titulo_agradecimientos = _crear_etiqueta(
			"AgradecimientosLabel",
			Vector2(532.0, 590.0),
			Vector2(216.0, 48.0),
			18,
			Color("c1a4ea")
		)
	if not is_instance_valid(indicador_desplazamiento):
		indicador_desplazamiento = _crear_etiqueta(
			"ScrollHint",
			Vector2(0.0, 0.0),
			Vector2(520.0, 32.0),
			17,
			Color(0.99, 0.96, 0.9, 1.0)
		)
		indicador_desplazamiento.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		indicador_desplazamiento.position.y -= 42.0


func _crear_etiqueta(nombre: String, posicion: Vector2, tamano: Vector2, tamanio_fuente: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.name = nombre
	etiqueta.position = posicion
	etiqueta.size = tamano
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := load("res://resources/ajustes_textos.tres") as LabelSettings
	etiqueta.label_settings = estilo.duplicate() as LabelSettings
	etiqueta.label_settings.font_size = tamanio_fuente
	etiqueta.label_settings.font_color = color
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(etiqueta)
	return etiqueta


func _actualizar_roles(_idioma: String) -> void:
	titulo.texture = TITULOS.get(Global.idioma_actual, TITULOS["es"])
	titulo_agradecimientos.text = Traducciones.obtener("special_thanks")
	indicador_desplazamiento.text = Traducciones.obtener("credits_scroll_hint")
	for indice in range(etiquetas_roles.size()):
		etiquetas_roles[indice].text = Traducciones.obtener(CLAVES_ROLES[indice])


func _configurar_desplazamiento() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "ScrollCreditos"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 170.0
	scroll.offset_bottom = -56.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scroll)
	move_child(scroll, $PanelCreditos.get_index())

	var contenido := Control.new()
	contenido.name = "ContenidoDesplazable"
	contenido_desplazable = contenido
	var tamano_vista := get_viewport_rect().size
	var alto_ventana_scroll := tamano_vista.y - scroll.offset_top + scroll.offset_bottom
	contenido.custom_minimum_size = Vector2(
		tamano_vista.x,
		alto_ventana_scroll + tamano_vista.y * 0.25
	)
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(contenido)

	_mover_control_al_scroll(panel_visual, contenido)
	# Rol8Label vive dentro de la tarjeta de agradecimientos para que conserve
	# su posición y escala debajo del nombre de Sumiko al desplazarla.
	for indice in range(etiquetas_roles.size() - 1):
		var etiqueta: Label = etiquetas_roles[indice]
		_mover_control_al_scroll(etiqueta, contenido)
	_mover_control_al_scroll(panel_visual_agradecimientos, contenido)
	_mover_control_al_scroll(titulo_agradecimientos, contenido)
	if indicador_desplazamiento.get_parent() != self:
		indicador_desplazamiento.reparent(self, true)
	move_child(indicador_desplazamiento, get_child_count() - 1)


func _mover_control_al_scroll(control: Control, contenido: Control) -> void:
	if not is_instance_valid(control):
		return

	var transformacion_global := control.get_global_transform()
	var posicion_global := transformacion_global.origin
	var escala_global := transformacion_global.get_scale()
	var tamano_original := control.size
	control.reparent(contenido)
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.position = posicion_global - contenido.get_global_position()
	control.size = tamano_original
	control.scale = escala_global
