extends Node

var idioma_actual := "es"
var textos: Dictionary = {}

func _ready() -> void:
	_cargar()

func _cargar() -> void:
	var archivo := FileAccess.open(
		"res://resources/dictionary.json",
		FileAccess.READ
	)

	if archivo == null:
		push_error("No se pudo abrir el archivo de traducciones")
		return

	var contenido = JSON.parse_string(archivo.get_as_text())

	if contenido is Dictionary:
		textos = contenido
