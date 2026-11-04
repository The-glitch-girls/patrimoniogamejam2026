extends Node

signal idioma_cambiado(idioma: String)

const RUTA_DICCIONARIO := "res://resources/dictionary/dictionary.json"
const FRASES := {
	"F Hablar  |  R Descansar": "prompt_talk_rest",
	"F Hablar": "prompt_talk",
	"R  Descansar": "prompt_rest",
	"F  Hablar con zorro": "prompt_talk_fox",
	"F  Hablar con loro": "prompt_talk_parrot",
	"E  Dejar con zorro": "prompt_leave_with_fox",
	"E  Recoger del zorro": "prompt_pickup_from_fox",
	"E  Dejar": "prompt_leave",
	"E  Recoger": "prompt_pickup",
	"E  Atacar": "prompt_attack",
	"Victoria": "victory",
	"Con un recuerdo, la cueva recarga tu energía": "cave_need_memory",
	"Acércate al tronco para descansar": "cave_approach",
	"El zorro aún no te ofrece descanso": "fox_no_rest_yet",
	"Acércate al zorro para descansar": "fox_approach_rest",
	"Tu energía ya está completa": "energy_full",
	"Descansando junto al tronco": "resting_trunk",
	"Necesitas el Recuerdo 2 para esto": "need_memory_2",
	"El zorro no está cerca": "fox_not_near",
	"No llevas al bebé": "not_carrying_baby",
	"Bebé dejado con el zorro": "baby_left_with_fox",
	"Bebé recogido del zorro": "baby_picked_up_from_fox",
	"El zorro parece reconocer el recuerdo que encontraste": "fox_recognizes_memory",
	"El zorro confía en ti y está dispuesto a cuidar al bebé": "fox_trusts_with_baby",
}

var idioma_actual := Global.idioma_actual
var textos: Dictionary = {}

func _ready() -> void:
	_cargar_diccionario()
	Global.idioma_actual = Ajustes.idioma
	idioma_actual = Ajustes.idioma

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


func cambiar_idioma(idioma: String) -> void:
	if not idioma in ["es", "en", "fr"] or idioma == Global.idioma_actual:
		return
	Global.idioma_actual = idioma
	Ajustes.set_idioma(idioma)
	idioma_cambiado.emit(idioma)


func obtener_frase(frase: String) -> String:
	if not FRASES.has(frase):
		return frase
	return obtener(FRASES[frase])
