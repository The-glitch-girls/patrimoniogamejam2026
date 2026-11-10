extends StaticBody2D

const CAPA_COLISION_SOLIDA := 4
const MASCARA_COLISION_SOLIDA := 1
# Referencias desde el origen de cada personaje hasta sus pies; solo orden visual (Z), no colisión.
const OFFSET_PIES_CAVILLACA_Y := 103.0
const OFFSET_PIES_LORO_Y := 49.0
const RANGO_ORDEN_X := 90.0
const RANGO_ORDEN_Y := 120.0
const AUDIOS_MENSAJE: Array[AudioStream] = [
	preload("res://sfx/animales/loro/aa_loro1.ogg"),
	preload("res://sfx/animales/loro/aa_loro2.ogg"),
	preload("res://sfx/animales/loro/aa_loro3.ogg"),
]

var indice_audio_mensaje := 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var deteccion: Area2D = $RangoHablar
@onready var sonido_mensaje: AudioStreamPlayer2D = $SonidoMensaje

# diff
var tiempo_hablando := 0.0
var ya_hablo := false

const DURACION_HABLA := 2.2
const ESCALA_SPRITE := Vector2(0.12, 0.12)
# end diff 

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
	deteccion.body_entered.connect(_al_entrar_en_rango)
	deteccion.body_exited.connect(_al_salir_del_rango)


func _process(delta: float) -> void:
	_actualizar_orden_visual()
	if tiempo_hablando <= 0.0:
		return
	tiempo_hablando = maxf(tiempo_hablando - delta, 0.0)
	if tiempo_hablando == 0.0:
		sprite.play("idle")


func _actualizar_orden_visual() -> void:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if cavillaca == null:
		sprite.z_index = 0
		return

	var diferencia := cavillaca.global_position - global_position
	var se_solapan := (
		absf(diferencia.x) < RANGO_ORDEN_X
		and absf(diferencia.y) < RANGO_ORDEN_Y
	)
	if not se_solapan:
		sprite.z_index = 0
		return

	var pies_cavillaca_y := cavillaca.global_position.y + OFFSET_PIES_CAVILLACA_Y
	var pies_loro_y := global_position.y + OFFSET_PIES_LORO_Y
	# Godot dibuja un z_index mayor delante: si Cavillaca está arriba, el loro va delante.
	sprite.z_index = 1 if pies_cavillaca_y < pies_loro_y else -1


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
