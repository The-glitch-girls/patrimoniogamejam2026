extends Control

signal cerrar

const FUENTE := preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const ESTILO_ETIQUETA_AJUSTES: LabelSettings = preload("res://resources/ajustes_textos.tres")
const MORADO := Color("#493783")
const LILA := Color("#C5A3E8")
const TITULOS_AJUSTES := {
	"es": preload("res://assets/ui/ajustes/titulo_ES.png"),
	"en": preload("res://assets/ui/ajustes/titulo_EN.png"),
	"fr": preload("res://assets/ui/ajustes/titulo_FR.png"),
}

@onready var idioma_popup: PopupMenu = $PanelAjustes/IdiomaPopup
@onready var idioma_boton: TextureButton = $PanelAjustes/IdmaLabelContainer/IdiomaRow/IdiomaBoton
@onready var idioma_label: Label = $PanelAjustes/IdmaLabelContainer/IdiomaRow/IdiomaLabel
@onready var titulo_textura: TextureRect = $PanelAjustes/HBoxContainer/Titulo

func _ready() -> void:
	$PanelAjustes/Cerrar.pressed.connect(_cerrar)
	$PanelAjustes/MusicaSlider.value = Ajustes.volumen_musica
	$PanelAjustes/SFXSlider.value = Ajustes.volumen_efectos
	$PanelAjustes/MusicaSlider.value_changed.connect(Ajustes.set_volumen_musica)
	$PanelAjustes/SFXSlider.value_changed.connect(Ajustes.set_volumen_efectos)
	$PanelAjustes/MusicaSlider.value_changed.connect(_actualizar_porcentaje_musica)
	$PanelAjustes/SFXSlider.value_changed.connect(_actualizar_porcentaje_sfx)
	$PanelAjustes/MSXLabelContainer/MusicaLabel.add_theme_font_override("font", FUENTE)
	$PanelAjustes/SFXLabelContainer/SFXLabel.add_theme_font_override("font", FUENTE)
	# Comparte el mismo recurso que Música/SFX para conservar tipografía, tamaño y color.
	idioma_label.label_settings = ESTILO_ETIQUETA_AJUSTES
	for etiqueta: Label in [$PanelAjustes/MusicaPorcentaje, $PanelAjustes/SFXPorcentaje]:
		etiqueta.add_theme_font_override("font", FUENTE)
		etiqueta.add_theme_font_size_override("font_size", 20)
		etiqueta.add_theme_color_override("font_color", MORADO)
	$PanelAjustes/Cerrar.add_theme_font_override("font", FUENTE)
	$PanelAjustes/Cerrar.add_theme_font_size_override("font_size", 26)
	$PanelAjustes/Cerrar.tooltip_text = Traducciones.obtener("close")
	$PanelAjustes/Cerrar.add_theme_color_override("font_color", Color.WHITE)
	_actualizar_porcentaje_musica($PanelAjustes/MusicaSlider.value)
	_actualizar_porcentaje_sfx($PanelAjustes/SFXSlider.value)
	_estilar_barras()
	idioma_boton.pressed.connect(_abrir_popup_idioma)
	idioma_popup.id_pressed.connect(_seleccionar_idioma)
	_estilar_popup()
	call_deferred("_estilar_popup")
	_poblar_idiomas()
	Traducciones.idioma_cambiado.connect(_actualizar_textos)
	_actualizar_textos(Global.idioma_actual)


func _cerrar() -> void:
	cerrar.emit()


func _poblar_idiomas() -> void:
	idioma_popup.clear()
	idioma_popup.add_item("Español", 0)
	idioma_popup.add_item("English", 1)
	idioma_popup.add_item("Français", 2)
	idioma_label.text = _nombre_idioma(Global.idioma_actual)


func _abrir_popup_idioma() -> void:
	# Ancla el menú al bloque subrayado completo, no al botón de la flecha.
	var rect_idioma: Rect2 = $PanelAjustes/IdmaLabelContainer.get_global_rect()
	var posicion := Vector2i(roundi(rect_idioma.position.x), roundi(rect_idioma.end.y))
	var ancho := roundi(rect_idioma.size.x)
	var alto := 100
	idioma_popup.popup(Rect2i(posicion, Vector2i(ancho, alto)))


func _seleccionar_idioma(indice: int) -> void:
	var codigos := ["es", "en", "fr"]
	if indice < 0 or indice >= codigos.size():
		return
	Traducciones.cambiar_idioma(codigos[indice])
	idioma_label.text = _nombre_idioma(codigos[indice])


func _nombre_idioma(codigo: String) -> String:
	match codigo:
		"en":
			return "English"
		"fr":
			return "Français"
		_:
			return "Español"


func _actualizar_textos(_idioma: String) -> void:
	idioma_label.text = _nombre_idioma(Global.idioma_actual)
	$PanelAjustes/MSXLabelContainer/MusicaLabel.text = Traducciones.obtener("music")
	$PanelAjustes/SFXLabelContainer/SFXLabel.text = Traducciones.obtener("sfx")
	$PanelAjustes/Cerrar.tooltip_text = Traducciones.obtener("close")
	titulo_textura.texture = TITULOS_AJUSTES.get(Global.idioma_actual, TITULOS_AJUSTES["es"])
	call_deferred("_centrar_titulo")


func _centrar_titulo() -> void:
	var contenedor: HBoxContainer = $PanelAjustes/HBoxContainer
	var ancho := contenedor.get_combined_minimum_size().x
	contenedor.offset_left = -ancho / 2.0
	contenedor.offset_right = ancho / 2.0


func _actualizar_porcentaje_musica(valor: float) -> void:
	$PanelAjustes/MusicaPorcentaje.text = "%d%%" % roundi(valor * 100.0)


func _actualizar_porcentaje_sfx(valor: float) -> void:
	$PanelAjustes/SFXPorcentaje.text = "%d%%" % roundi(valor * 100.0)


func _estilar_barras() -> void:
	for barra: HSlider in [$PanelAjustes/MusicaSlider, $PanelAjustes/SFXSlider]:
		var transparente := StyleBoxEmpty.new()
		barra.add_theme_stylebox_override("slider", transparente)
		barra.add_theme_stylebox_override("grabber_area", transparente)
		barra.add_theme_stylebox_override("grabber_area_highlight", transparente)
		barra.add_theme_icon_override("grabber", preload("res://assets/ui/ajustes/grabber.png"))
		barra.add_theme_icon_override("grabber_highlight", preload("res://assets/ui/ajustes/grabber.png"))
		barra.add_theme_icon_override("grabber_disabled", preload("res://assets/ui/ajustes/grabber.png"))


func _estilar_popup() -> void:
	var tema_popup := Theme.new()
	tema_popup.set_default_font(ESTILO_ETIQUETA_AJUSTES.font)
	tema_popup.set_default_font_size(ESTILO_ETIQUETA_AJUSTES.font_size)
	tema_popup.set_font("font", "PopupMenu", ESTILO_ETIQUETA_AJUSTES.font)
	tema_popup.set_font_size("font_size", "PopupMenu", ESTILO_ETIQUETA_AJUSTES.font_size)
	tema_popup.set_color("font_color", "PopupMenu", MORADO)
	tema_popup.set_color("font_hover_color", "PopupMenu", MORADO)
	idioma_popup.theme = tema_popup
	var fondo_popup := StyleBoxFlat.new()
	fondo_popup.bg_color = LILA
	fondo_popup.set_corner_radius_all(6)
	idioma_popup.add_theme_stylebox_override("panel", fondo_popup)
	idioma_popup.add_theme_color_override("font_color", MORADO)
	idioma_popup.add_theme_color_override("font_hover_color", Color.WHITE)
	idioma_popup.add_theme_color_override("font_pressed_color", MORADO)
	idioma_popup.add_theme_color_override("font_focus_color", MORADO)
	idioma_popup.add_theme_color_override("font_disabled_color", MORADO)
	idioma_popup.add_theme_font_override("font", ESTILO_ETIQUETA_AJUSTES.font)
	idioma_popup.add_theme_font_size_override("font_size", ESTILO_ETIQUETA_AJUSTES.font_size - 7)
