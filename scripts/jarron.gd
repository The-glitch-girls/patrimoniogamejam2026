@tool
extends StaticBody2D

enum Tipo { TIPO_1 = 1, TIPO_2 = 2 }

const TEXTURAS := {
	Tipo.TIPO_1: preload("res://assets/tiles/jarron1.png"),
	Tipo.TIPO_2: preload("res://assets/tiles/jarron2.png"),
}
const TIEMPOS_RECARGA := {Tipo.TIPO_1: 8.0, Tipo.TIPO_2: 15.0}
const PIEDRAS_POR_TIPO := {Tipo.TIPO_1: 1, Tipo.TIPO_2: 3}
const RADIO_RECARGA := 12.0
const GROSOR_RECARGA := 4.0
const COLOR_RECARGA := Color("#53ed78")
const COLOR_FONDO_RECARGA := Color(0.14, 0.29, 0.21, 0.85)

@export var tipo: Tipo = Tipo.TIPO_1:
	set(valor):
		tipo = valor
		_actualizar_sprite()

var recarga_restante := 0.0
var duracion_recarga := 0.0

@onready var indicador_recarga: Node2D = $IndicadorRecarga


func _ready() -> void:
	_actualizar_sprite()
	set_process(false)
	indicador_recarga.draw.connect(_dibujar_recarga)
	$DetectorInteraccion.body_entered.connect(_al_entrar_en_rango)
	$DetectorInteraccion.body_exited.connect(_al_salir_del_rango)


func _actualizar_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = TEXTURAS[tipo]


func _al_entrar_en_rango(body: Node2D) -> void:
	if body.is_in_group("cavillaca") and body.has_method("registrar_contacto_jarron"):
		body.call("registrar_contacto_jarron", self, true)


func _al_salir_del_rango(body: Node2D) -> void:
	if body.is_in_group("cavillaca") and body.has_method("registrar_contacto_jarron"):
		body.call("registrar_contacto_jarron", self, false)


func puede_recolectar_piedra() -> bool:
	return recarga_restante <= 0.0


func recolectar_piedra() -> int:
	if not puede_recolectar_piedra():
		return 0
	duracion_recarga = TIEMPOS_RECARGA[tipo]
	recarga_restante = duracion_recarga
	set_process(true)
	indicador_recarga.queue_redraw()
	return PIEDRAS_POR_TIPO[tipo]


func _process(delta: float) -> void:
	recarga_restante = maxf(0.0, recarga_restante - delta)
	indicador_recarga.queue_redraw()
	if puede_recolectar_piedra():
		set_process(false)


func _dibujar_recarga() -> void:
	if puede_recolectar_piedra():
		return

	var progreso := 1.0 - recarga_restante / duracion_recarga
	indicador_recarga.draw_arc(Vector2.ZERO, RADIO_RECARGA, 0.0, TAU, 48, COLOR_FONDO_RECARGA, GROSOR_RECARGA, true)
	if progreso > 0.0:
		var inicio := -PI * 0.5
		indicador_recarga.draw_arc(Vector2.ZERO, RADIO_RECARGA, inicio, inicio + TAU * progreso, 48, COLOR_RECARGA, GROSOR_RECARGA, true)
