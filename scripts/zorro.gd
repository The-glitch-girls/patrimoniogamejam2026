extends StaticBody2D

const CAPA_COLISION_SOLIDA := 4
const MASCARA_COLISION_SOLIDA := 1
# Referencias desde el origen de cada personaje hasta sus pies; solo orden visual (Z), no colisión.
const OFFSET_PIES_CAVILLACA_Y := 103.0
const OFFSET_PIES_ZORRO_Y := 49.0
const RANGO_ORDEN_X := 90.0
const RANGO_ORDEN_Y := 120.0
const AUDIOS_MENSAJE: Array[AudioStream] = [
	preload("res://sfx/animales/zorro/aa_zorro1.ogg"),
	preload("res://sfx/animales/zorro/aa_zorro2.ogg"),
	preload("res://sfx/animales/zorro/aa_zorro3.ogg"),
]

var indice_audio_mensaje := 0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var deteccion: Area2D = $RangoHablar
@onready var sonido_mensaje: AudioStreamPlayer2D = $SonidoMensaje

func _ready() -> void:
	add_to_group("zorro")
	z_index = 0
	# Igual que Loro: capa 3 para el animal y capa 1 en la máscara.
	collision_layer = CAPA_COLISION_SOLIDA
	collision_mask = MASCARA_COLISION_SOLIDA
	deteccion.body_entered.connect(_on_body_entered)
	deteccion.body_exited.connect(_on_body_exited)
	animated_sprite.flip_h = false
	animated_sprite.animation_finished.connect(_al_terminar_animacion)
	animated_sprite.play("idle")


func _process(_delta: float) -> void:
	_actualizar_orden_visual()


func _actualizar_orden_visual() -> void:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if cavillaca == null:
		animated_sprite.z_index = 0
		return

	var diferencia := cavillaca.global_position - global_position
	var se_solapan := (
		absf(diferencia.x) < RANGO_ORDEN_X
		and absf(diferencia.y) < RANGO_ORDEN_Y
	)
	if not se_solapan:
		animated_sprite.z_index = 0
		return

	var pies_cavillaca_y := cavillaca.global_position.y + OFFSET_PIES_CAVILLACA_Y
	var pies_zorro_y := global_position.y + OFFSET_PIES_ZORRO_Y
	# Godot dibuja un z_index mayor delante. Si Cavillaca está más abajo,
	# el zorro queda detrás; si está más arriba, el zorro queda delante.
	animated_sprite.z_index = 1 if pies_cavillaca_y < pies_zorro_y else -1


func hablar() -> void:
	animated_sprite.play("talk")
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
	if animated_sprite.animation == "talk":
		animated_sprite.play("idle")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("cavillaca"):
		Global.zorro_cerca = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("cavillaca"):
		Global.zorro_cerca = false
