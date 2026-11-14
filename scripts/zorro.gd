extends StaticBody2D

const CAPA_COLISION_SOLIDA := 4
const MASCARA_COLISION_SOLIDA := 1
const AUDIOS_MENSAJE: Array[AudioStream] = [
	preload("res://sfx/animales/zorro/aa_zorro1.ogg"),
	preload("res://sfx/animales/zorro/aa_zorro2.ogg"),
	preload("res://sfx/animales/zorro/aa_zorro3.ogg"),
]

var indice_audio_mensaje := 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var rango_hablar: Area2D = $RangoHablar
@onready var sonido_mensaje: AudioStreamPlayer2D = $SonidoMensaje

func _ready() -> void:
	add_to_group("zorro")
	z_index = 0
	# Igual que Loro: capa 3 para el animal y capa 1 en la máscara.
	collision_layer = CAPA_COLISION_SOLIDA
	collision_mask = MASCARA_COLISION_SOLIDA
	rango_hablar.body_entered.connect(_al_entrar_en_rango)
	rango_hablar.body_exited.connect(_al_salir_del_rango)
	sprite.flip_h = false
	sprite.animation_finished.connect(_al_terminar_animacion)
	sprite.play("idle")


func hablar() -> void:
	sprite.play("talk")
	if Global.recuerdos_obtenidos == 0:
		Global.mostrar_aviso("Con un recuerdo, la cueva recarga tu energía")
	elif Global.recuerdos_obtenidos == 1:
		Global.mostrar_aviso("El zorro parece reconocer el recuerdo que encontraste")
	else:
		Global.mostrar_aviso("El zorro confía en ti y está dispuesto a cuidar al bebé")
	reproducir_sonido_mensaje()


func reproducir_sonido_mensaje() -> void:
	sonido_mensaje.stop()
	sonido_mensaje.stream = AUDIOS_MENSAJE[indice_audio_mensaje]
	sonido_mensaje.play()
	indice_audio_mensaje = (indice_audio_mensaje + 1) % AUDIOS_MENSAJE.size()

func _al_terminar_animacion() -> void:
	if sprite.animation == "talk":
		sprite.play("idle")


func _al_entrar_en_rango(body: Node2D) -> void:
	if body.is_in_group("cavillaca"):
		Global.zorro_cerca = true


func _al_salir_del_rango(body: Node2D) -> void:
	if body.is_in_group("cavillaca"):
		Global.zorro_cerca = false
