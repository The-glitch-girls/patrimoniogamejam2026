extends Node2D

const AREA_PRACTICA := Rect2(320, 128, 640, 512)
const DISTANCIA_PRACTICA := 256.0
const ESCENA_MAIN := "res://scenes/Main.tscn"
const ESCENA_BEBE := preload("res://scenes/Bebe.tscn")
const CARGAR := preload("res://assets/ui/botones/cargar_btn.png")
const CARGAR_PRESIONADO := preload("res://assets/ui/botones/cargar_btn_pressed.png")
const DEJAR := preload("res://assets/ui/botones/dejar_btn.png")
const DEJAR_PRESIONADO := preload("res://assets/ui/botones/dejar_btn_pressed.png")

enum Paso { MOVERSE, CARGAR, DEJAR, COMPLETO }

var distancia_recorrida := 0.0
var completado := false
var saliendo := false
var paso := Paso.MOVERSE

@onready var jugador: CharacterBody2D = $Cavillaca
@onready var instruccion: Label = $Interfaz/DialogoLoro/Texto
@onready var continuar: Button = $Interfaz/Continuar
@onready var omitir: Button = $Interfaz/Omitir
@onready var loro: StaticBody2D = $Interfaz/Loro
@onready var boton_bebe: TextureRect = $Interfaz/BotonBebe
@onready var accion_bebe: Label = $Interfaz/AccionBebe


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
	if paso != Paso.MOVERSE:
		return
	distancia_recorrida += distancia
	if distancia_recorrida >= DISTANCIA_PRACTICA:
		var bebe := ESCENA_BEBE.instantiate() as Node2D
		bebe.position = Vector2(640, 440)
		add_child(bebe)
		_cambiar_paso(Paso.CARGAR)


func _process(_delta: float) -> void:
	var puede_cargar: bool = paso == Paso.CARGAR and jugador.esta_cerca_del_bebe()
	var puede_dejar := paso == Paso.DEJAR
	boton_bebe.visible = puede_cargar or puede_dejar
	accion_bebe.visible = boton_bebe.visible
	var presionado := Input.is_action_pressed("interactuar_bebe")
	if puede_dejar:
		boton_bebe.texture = DEJAR_PRESIONADO if presionado else DEJAR
	else:
		boton_bebe.texture = CARGAR_PRESIONADO if presionado else CARGAR


func interactuar_bebe() -> void:
	match paso:
		Paso.CARGAR:
			jugador._recoger_bebe()
			if Global.lleva_bebe:
				Global.reproducir_clic()
				_cambiar_paso(Paso.DEJAR)
		Paso.DEJAR:
			jugador._dejar_bebe()
			if not Global.lleva_bebe:
				Global.reproducir_clic()
				completado = true
				continuar.show()
				_cambiar_paso(Paso.COMPLETO)
			else:
				instruccion.text = Traducciones.obtener("tutorial_drop_space")
				loro.acompanar_indicacion()


func _cambiar_paso(nuevo_paso: Paso) -> void:
	paso = nuevo_paso
	_traducir(Global.idioma_actual)
	loro.acompanar_indicacion()


func _traducir(_idioma: String) -> void:
	var mensajes := ["tutorial_move", "tutorial_pickup", "tutorial_drop", "tutorial_baby_complete"]
	instruccion.text = Traducciones.obtener(mensajes[paso])
	accion_bebe.text = Traducciones.obtener("leave_action" if paso == Paso.DEJAR else "pickup")
	continuar.text = Traducciones.obtener("tutorial_continue")
	omitir.text = Traducciones.obtener("tutorial_skip")


func _entrar_al_juego() -> void:
	if saliendo:
		return
	saliendo = true
	Global.reproducir_clic()
	Global.resetear()
	get_tree().change_scene_to_file.call_deferred(ESCENA_MAIN)
