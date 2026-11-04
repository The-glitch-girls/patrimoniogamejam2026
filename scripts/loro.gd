extends CharacterBody2D

const DURACION_HABLA := 2.2
const ESCALA_SPRITE := Vector2(0.12, 0.12)
const AUDIOS_MENSAJE: Array[AudioStream] = [
	preload("res://sfx/animales/loro/aa_loro1.ogg"),
	preload("res://sfx/animales/loro/aa_loro2.ogg"),
	preload("res://sfx/animales/loro/aa_loro3.ogg"),
]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var deteccion: Area2D = $Deteccion
@onready var sonido_mensaje: AudioStreamPlayer2D = $SonidoMensaje

var tiempo_hablando := 0.0
var ya_hablo := false


func _ready() -> void:
	add_to_group("loro")
	velocity = Vector2.ZERO
	sprite.scale = ESCALA_SPRITE
	sprite.position.y = 10.0
	sprite.play("idle")
	deteccion.body_entered.connect(_al_entrar_en_rango)
	deteccion.body_exited.connect(_al_salir_del_rango)


func _process(delta: float) -> void:
	if tiempo_hablando <= 0.0:
		return
	tiempo_hablando = maxf(tiempo_hablando - delta, 0.0)
	if tiempo_hablando == 0.0:
		sprite.play("idle")


func hablar() -> void:
	if tiempo_hablando > 0.0:
		return
	ya_hablo = true
	tiempo_hablando = DURACION_HABLA
	sprite.play("hablando")
	var frase := "parrot_baby_warning"
	if Global.presencia_cuniraya >= Global.PRESENCIA_CRITICA:
		frase = "parrot_cuniraya_near"
	Global.mostrar_aviso(Traducciones.obtener(frase))
	reproducir_sonido_mensaje()


func reproducir_sonido_mensaje() -> void:
	sonido_mensaje.stop()
	sonido_mensaje.stream = AUDIOS_MENSAJE.pick_random()
	sonido_mensaje.play()


func _al_entrar_en_rango(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("cavillaca"):
		Global.loro_cerca = true
		# La primera vez que Cavillaca se acerca, el loro da su consejo sin pulsar F.
		if not ya_hablo:
			hablar()


func _al_salir_del_rango(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("cavillaca"):
		Global.loro_cerca = false
