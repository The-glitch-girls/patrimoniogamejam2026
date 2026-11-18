extends "res://scripts/cavillaca.gd"

signal movido(distancia: float)


func _ready() -> void:
	super._ready()
	cam.enabled = false


func _physics_process(delta: float) -> void:
	lock_interaccion = maxf(0.0, lock_interaccion - delta)
	if Input.is_action_just_pressed("interactuar_bebe") and lock_interaccion <= 0.0:
		get_parent().interactuar_bebe()
	if Input.is_action_just_pressed("recolectar"):
		get_parent().recolectar()
	var direccion := _direccion_cuatro()
	if direccion != Vector2.ZERO:
		facing = direccion
	var aceleracion := FRENADO if direccion == Vector2.ZERO else ACELERACION
	var velocidad := VELOCIDAD_CON_BEBE if Global.lleva_bebe else VELOCIDAD_CAMINAR
	velocity = velocity.move_toward(direccion * velocidad, aceleracion * delta)
	var anterior := global_position
	move_and_slide()
	_animar_caminata(delta, velocity.length() > 0.01, false)
	var area: Rect2 = get_parent().AREA_PRACTICA
	var sprite := $Sprite as AnimatedSprite2D
	var textura := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var rectangulo := Rect2(sprite.offset - textura.get_size() * 0.5, textura.get_size())
	var cuerpo: Rect2 = sprite.transform * rectangulo
	var margen := Vector2(12, 12)
	global_position = global_position.clamp(
		area.position + margen - cuerpo.position,
		area.end - margen - cuerpo.end
	)
	var distancia := global_position.distance_to(anterior)
	_animar_caminata(delta, distancia > 0.01, false)
	if distancia > 0.01:
		movido.emit(distancia)


func _input(_evento: InputEvent) -> void:
	pass


func _unhandled_input(_evento: InputEvent) -> void:
	pass
