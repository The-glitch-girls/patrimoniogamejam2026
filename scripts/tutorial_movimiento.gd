extends Node2D

const AREA_PRACTICA := Rect2(320, 128, 640, 512)
const DISTANCIA_PRACTICA := 256.0
const ESCENA_MAIN := "res://scenes/Main.tscn"
const ESCENA_BEBE := preload("res://scenes/Bebe.tscn")
const ESCENA_JARRON := preload("res://scenes/componentes/Jarron.tscn")
const META_PIEDRAS := 10
const CARGAR := preload("res://assets/ui/botones/cargar_btn.png")
const CARGAR_PRESIONADO := preload("res://assets/ui/botones/cargar_btn_pressed.png")
const DEJAR := preload("res://assets/ui/botones/dejar_btn.png")
const DEJAR_PRESIONADO := preload("res://assets/ui/botones/dejar_btn_pressed.png")
const RECOLECTAR := preload("res://assets/ui/botones/recolectar_btn.png")
const RECOLECTAR_PRESIONADO := preload("res://assets/ui/botones/recolectar_btn_pressed.png")

enum Paso { MOVERSE, CARGAR, DEJAR, BEBE_COMPLETO, RECOLECTAR, COMPLETO }

var distancia_recorrida := 0.0
var completado := false
var saliendo := false
var paso := Paso.MOVERSE
var recarga_explicada := false

@onready var jugador: CharacterBody2D = $Cavillaca
@onready var instruccion: Label = $Interfaz/DialogoLoro/Texto
@onready var continuar: Button = $Interfaz/Continuar
@onready var omitir: Button = $Interfaz/Omitir
@onready var loro: StaticBody2D = $Interfaz/Loro
@onready var boton_bebe: TextureRect = $Interfaz/BotonBebe
@onready var accion_bebe: Label = $Interfaz/AccionBebe
@onready var boton_recolectar: TextureRect = $Interfaz/BotonRecolectar
@onready var accion_recolectar: Label = $Interfaz/AccionRecolectar
@onready var contador_piedras: Label = $Interfaz/ContadorPiedras


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
	continuar.pressed.connect(_continuar_tutorial)
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
	var practica_jarrones := paso == Paso.RECOLECTAR
	var puede_cargar: bool = (paso == Paso.CARGAR or practica_jarrones) and jugador.esta_cerca_del_bebe()
	var puede_dejar := paso == Paso.DEJAR or (practica_jarrones and Global.lleva_bebe)
	boton_bebe.visible = puede_cargar or puede_dejar
	accion_bebe.visible = boton_bebe.visible
	var presionado := Input.is_action_pressed("interactuar_bebe")
	if puede_dejar:
		boton_bebe.texture = DEJAR_PRESIONADO if presionado else DEJAR
	else:
		boton_bebe.texture = CARGAR_PRESIONADO if presionado else CARGAR
	accion_bebe.text = Traducciones.obtener("leave_action" if puede_dejar else "pickup")
	boton_recolectar.visible = practica_jarrones and jugador._jarron_mas_cercano() != null
	accion_recolectar.visible = boton_recolectar.visible
	boton_recolectar.texture = RECOLECTAR_PRESIONADO if Input.is_action_pressed("recolectar") else RECOLECTAR
	contador_piedras.visible = paso in [Paso.RECOLECTAR, Paso.COMPLETO]
	contador_piedras.text = Traducciones.obtener("tutorial_stone_count") % [Global.piedras, META_PIEDRAS]


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
				continuar.show()
				_cambiar_paso(Paso.BEBE_COMPLETO)
			else:
				instruccion.text = Traducciones.obtener("tutorial_drop_space")
				loro.acompanar_indicacion()
		Paso.RECOLECTAR:
			if Global.lleva_bebe:
				jugador._dejar_bebe()
			else:
				jugador._recoger_bebe()


func recolectar() -> void:
	if paso != Paso.RECOLECTAR:
		return
	var jarron: Node2D = jugador._jarron_mas_cercano()
	if jarron == null:
		return
	var cantidad: int = jarron.recolectar_piedra()
	if cantidad <= 0:
		return
	Global.piedras += cantidad
	Global.reproducir_clic()
	if Global.piedras >= META_PIEDRAS:
		completado = true
		continuar.show()
		_cambiar_paso(Paso.COMPLETO)
	elif not recarga_explicada:
		recarga_explicada = true
		_traducir(Global.idioma_actual)
		loro.acompanar_indicacion()


func _continuar_tutorial() -> void:
	if paso == Paso.BEBE_COMPLETO:
		continuar.hide()
		jugador.global_position = Vector2(640, 260)
		jugador.velocity = Vector2.ZERO
		jugador.facing = Vector2.DOWN
		var bebe := get_tree().get_first_node_in_group("bebe")
		bebe.recoger()
		bebe.get_node("AnimatedSprite2D").hide()
		jugador.cambiar_sprite_bebe(true)
		var posiciones := [Vector2(460, 460), Vector2(820, 460), Vector2(640, 520)]
		for indice in posiciones.size():
			var jarron := ESCENA_JARRON.instantiate() as Node2D
			jarron.tipo = 2 if indice < 2 else 1
			jarron.position = posiciones[indice]
			add_child(jarron)
		_cambiar_paso(Paso.RECOLECTAR)
	elif paso == Paso.COMPLETO:
		_entrar_al_juego()


func _cambiar_paso(nuevo_paso: Paso) -> void:
	paso = nuevo_paso
	_traducir(Global.idioma_actual)
	loro.acompanar_indicacion()


func _traducir(_idioma: String) -> void:
	var mensajes := ["tutorial_move", "tutorial_pickup", "tutorial_drop", "tutorial_baby_complete", "tutorial_collect", "tutorial_collect_complete"]
	var mensaje: String = mensajes[paso]
	if paso == Paso.RECOLECTAR and recarga_explicada:
		mensaje = "tutorial_jar_cooldown"
	instruccion.text = Traducciones.obtener(mensaje)
	accion_bebe.text = Traducciones.obtener("leave_action" if paso == Paso.DEJAR else "pickup")
	accion_recolectar.text = Traducciones.obtener("collect")
	continuar.text = Traducciones.obtener("tutorial_next" if paso == Paso.BEBE_COMPLETO else "tutorial_continue")
	omitir.text = Traducciones.obtener("tutorial_skip")


func _entrar_al_juego() -> void:
	if saliendo:
		return
	saliendo = true
	Global.reproducir_clic()
	Global.resetear()
	get_tree().change_scene_to_file.call_deferred(ESCENA_MAIN)
