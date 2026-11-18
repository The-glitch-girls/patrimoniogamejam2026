extends Node2D

const AREA_PRACTICA := Rect2(320, 128, 640, 512)
const DISTANCIA_PRACTICA := 256.0
const ESCENA_MAIN := "res://scenes/Main.tscn"

var distancia_recorrida := 0.0
var completado := false
var saliendo := false

@onready var jugador: CharacterBody2D = $Cavillaca
@onready var instruccion: Label = $Interfaz/DialogoLoro/Texto
@onready var continuar: Button = $Interfaz/Continuar
@onready var omitir: Button = $Interfaz/Omitir
@onready var loro: StaticBody2D = $Interfaz/Loro


func _ready() -> void:
	Global.resetear()
	loro.collision_layer = 0
	loro.collision_mask = 0
	loro.get_node("AnimatedSprite2D").flip_h = true
	loro.get_node("RangoHablar").monitoring = false
	var suelo := $Capas/Suelo as TileMapLayer
	# Pintar mapa
	for y in range(4):
		for x in range(5):
			suelo.set_cell(Vector2i(x, y), 2, Vector2i.ZERO)
	continuar.hide()
	continuar.pressed.connect(_entrar_al_juego)
	omitir.pressed.connect(_entrar_al_juego)
	jugador.movido.connect(_al_moverse)
	Traducciones.idioma_cambiado.connect(_traducir)
	_traducir(Global.idioma_actual)
	loro.acompanar_indicacion()


func _al_moverse(distancia: float) -> void:
	if completado:
		return
	distancia_recorrida += distancia
	if distancia_recorrida >= DISTANCIA_PRACTICA:
		completado = true
		continuar.show()
		_traducir(Global.idioma_actual)
		loro.acompanar_indicacion()


func _traducir(_idioma: String) -> void:
	instruccion.text = Traducciones.obtener("tutorial_move_complete" if completado else "tutorial_move")
	continuar.text = Traducciones.obtener("tutorial_continue")
	omitir.text = Traducciones.obtener("tutorial_skip")


func _entrar_al_juego() -> void:
	if saliendo:
		return
	saliendo = true
	Global.reproducir_clic()
	Global.resetear()
	get_tree().change_scene_to_file.call_deferred(ESCENA_MAIN)
