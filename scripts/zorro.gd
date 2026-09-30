extends CharacterBody2D

const TEXTURA_ZORRO: Texture2D = preload("res://assets/tiles/Zorro.png")
const VELOCIDAD_PASEO := 40.0
const RADIO_PASEO := 8.0
const PAUSA_MINIMA := 0.3
const PAUSA_MAXIMA := 0.6

var posicion_cueva := Vector2.ZERO
var destino := Vector2.ZERO
var pausa := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var deteccion: Area2D = $Deteccion


func _ready() -> void:
	add_to_group("zorro")
	posicion_cueva = global_position
	destino = global_position
	deteccion.body_entered.connect(_on_body_entered)
	deteccion.body_exited.connect(_on_body_exited)
	_armar_animaciones()
	pausa = randf_range(PAUSA_MINIMA, PAUSA_MAXIMA)


func _physics_process(delta: float) -> void:
	if pausa > 0.0:
		velocity = Vector2.ZERO
		_poner_animacion(false)
		pausa = maxf(pausa - delta, 0.0)
		if pausa <= 0.0:
			_elegir_destino()
		return

	if absf(destino.x - global_position.x) <= 4.0:
		velocity = Vector2.ZERO
		destino = global_position
		pausa = randf_range(PAUSA_MINIMA, PAUSA_MAXIMA)
		_poner_animacion(false)
		return

	var direccion_x := signf(destino.x - global_position.x)
	velocity = Vector2(direccion_x * VELOCIDAD_PASEO, 0.0)
	if absf(velocity.x) > 0.1:
		sprite.flip_h = velocity.x < 0.0
	move_and_slide()

	if get_slide_collision_count() > 0:
		destino = global_position
		pausa = randf_range(PAUSA_MINIMA, PAUSA_MAXIMA)
		velocity = Vector2.ZERO
		_poner_animacion(false)
	elif global_position.distance_to(destino) <= 6.0:
		destino = global_position
		pausa = randf_range(PAUSA_MINIMA, PAUSA_MAXIMA)
		velocity = Vector2.ZERO
		_poner_animacion(false)
	else:
		_poner_animacion(true)


func _process(_delta: float) -> void:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if cavillaca == null:
		sprite.z_index = 0
		return

	var diferencia := cavillaca.global_position - global_position
	var se_solapa := absf(diferencia.x) < 64.0 and absf(diferencia.y) < 96.0
	var debe_quedar_detras := se_solapa and global_position.y < cavillaca.global_position.y
	sprite.z_index = -1 if debe_quedar_detras else 0


func _armar_animaciones() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("quieto")
	frames.set_animation_loop("quieto", true)
	frames.set_animation_speed("quieto", 1.0)
	frames.add_animation("caminar")
	frames.set_animation_loop("caminar", true)
	frames.set_animation_speed("caminar", 5.0)

	var regiones := [
		Rect2(256, 1450, 2200, 2200),
		Rect2(2600, 1450, 2400, 2200),
		Rect2(5000, 1450, 2800, 2200),
	]
	# El PNG incluye mucho margen vacío arriba y abajo; limitar el atlas a la
	# franja de cada pose evita incluir partes de la pose vecina.
	for region in regiones:
		var frame := AtlasTexture.new()
		frame.atlas = TEXTURA_ZORRO
		frame.region = region
		frame.filter_clip = true
		frames.add_frame("caminar", frame)
		if frames.get_frame_count("quieto") == 0:
			frames.add_frame("quieto", frame)

	sprite.sprite_frames = frames
	sprite.play("quieto")


func _elegir_destino() -> void:
	var direccion := -1.0 if randf() < 0.5 else 1.0
	var distancia := randf_range(RADIO_PASEO * 0.65, RADIO_PASEO)
	destino = posicion_cueva + Vector2(direccion * distancia, 0.0)
	pausa = 0.0


func hablar() -> void:
	Global.mostrar_aviso("El zorro te observa con calma")


func _poner_animacion(caminando: bool) -> void:
	var animacion := "caminar" if caminando else "quieto"
	if sprite.animation != animacion:
		sprite.play(animacion)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("cavillaca"):
		Global.zorro_cerca = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("cavillaca"):
		Global.zorro_cerca = false
