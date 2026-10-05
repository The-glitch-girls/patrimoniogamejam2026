extends Node

const RUTA_DICCIONARIO := "res://resources/dictionary/dictionary.json"

var idioma_actual := Global.idioma_actual
var textos: Dictionary = {}

func _ready() -> void:
	_cargar_diccionario()

func _cargar_diccionario() -> void:
	var archivo := FileAccess.open(RUTA_DICCIONARIO,FileAccess.READ)

	if archivo == null:
		push_error("No se pudo abrir el diccionario: " + RUTA_DICCIONARIO)
		return

	var contenido = JSON.parse_string(archivo.get_as_text())

	if contenido is Dictionary:
		textos = contenido
	else:
		push_error("El diccionario no contiene un JSON válido.")

func obtener(clave: String) -> String:
	if not textos.has(clave):
		push_warning("No existe la clave: " + clave)
		return clave

	var traducciones: Dictionary = textos[clave]

	if not traducciones.has(Global.idioma_actual):
		push_warning(
			"No existe el idioma '%s' para la clave '%s'"
			% [Global.idioma_actual, clave]
		)
		return clave

	return traducciones[Global.idioma_actual]
