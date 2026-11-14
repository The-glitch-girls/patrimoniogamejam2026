extends StaticBody2D

const CAPA_COLISION_SOLIDA := 4
const MASCARA_COLISION_SOLIDA := 1
# Referencias desde el origen de cada personaje hasta sus pies; solo orden visual (Z), no colisión.
const OFFSET_PIES_LORO_Y := 49.0
const ORDEN_VISUAL := preload("res://scripts/componentes/orden_visual.gd")
const CONSEJOS: Array[String] = ["parrot_tip_danger", "parrot_tip_refuge", "parrot_tip_memories"]
const AUDIOS_MENSAJE: Array[AudioStream] = [
	preload("res://sfx/animales/loro/aa_loro1.ogg"),
	preload("res://sfx/animales/loro/aa_loro2.ogg"),
	preload("res://sfx/animales/loro/aa_loro3.ogg"),
]

var indice_audio_mensaje := 0
var indice_consejo := 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var rango_hablar: Area2D = $RangoHablar
@onready var sonido_mensaje: AudioStreamPlayer2D = $SonidoMensaje

var tiempo_hablando := 0.0

const DURACION_HABLA := 2.2
const ESCALA_SPRITE := Vector2(0.12, 0.12)

func _ready() -> void:
	add_to_group("loro")
	# Main ordena el loro respecto a Cavillaca por coordenada Y.
	z_index = 0
	# La forma y posición del polígono se editan en Loro.tscn; aquí solo se fijan las capas.
	collision_layer = CAPA_COLISION_SOLIDA
	collision_mask = MASCARA_COLISION_SOLIDA
	sprite.scale = ESCALA_SPRITE
	sprite.position.y = 10.0
	sprite.play("idle")
	rango_hablar.body_entered.connect(_al_entrar_en_rango)
	rango_hablar.body_exited.connect(_al_salir_del_rango)


func _process(delta: float) -> void:
	_actualizar_orden_visual()
	if tiempo_hablando <= 0.0:
		return
	tiempo_hablando = maxf(tiempo_hablando - delta, 0.0)
	if tiempo_hablando == 0.0:
		sprite.play("idle")


func _actualizar_orden_visual() -> void:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	ORDEN_VISUAL.actualizar_sprite(sprite, self, cavillaca, OFFSET_PIES_LORO_Y)


func hablar() -> void:
	if not Global.loro_cerca:
		return
	tiempo_hablando = DURACION_HABLA
	sprite.play("hablando")
	Global.mostrar_aviso(CONSEJOS[indice_consejo])
	indice_consejo = (indice_consejo + 1) % CONSEJOS.size()
	reproducir_sonido_mensaje()


func reproducir_sonido_mensaje() -> void:
	sonido_mensaje.stop()
	sonido_mensaje.stream = AUDIOS_MENSAJE.pick_random()
	sonido_mensaje.play()


func _al_entrar_en_rango(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("cavillaca"):
		Global.loro_cerca = true


func _al_salir_del_rango(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("cavillaca"):
		Global.loro_cerca = false
