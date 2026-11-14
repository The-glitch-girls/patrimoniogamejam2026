extends CharacterBody2D

const VIDA_MAX := 3
const RANGO_DETECCION := 300.0
const RANGO_CORTE := 400.0
const RADIO_REVOLOTEO := 72.0
const AMPLITUD_REVOLOTEO := 36.0
const RANGO_GOLPE := 52.0
const VELOCIDAD_REVOLOTEO := 110.0
const VELOCIDAD_PATRULLA := 36.0
const VELOCIDAD_RETIRADA := 110.0
const DESCANSO_PERSECUCION := 1.4
const LOCK_GOLPE := 1.1
const TIEMPO_RESPAWN := 8.0
const TIEMPO_EN_ZONA := 10.0
const PASO_MIN := 600.0
const PASO_MAX := 1400.0
const SEPARACION := 480.0
const EXCLUSION_TRONCO_OFFSET := Vector2(-760.0, -100.0)
const EXCLUSION_TRONCO_TAMANO := Vector2(900.0, 520.0)
var zona_aparicion_celdas := PackedVector2Array([
	Vector2(2.0, -15.0), Vector2(7.0, -15.0), Vector2(13.0, -14.5),
	Vector2(14.0, -13.5), Vector2(14.0, -7.0), Vector2(15.0, -6.0),
	Vector2(16.0, -5.5), Vector2(19.0, -8.0), Vector2(23.0, -11.0),
	Vector2(24.0, -12.0), Vector2(30.0, -12.0), Vector2(33.0, -11.0),
	Vector2(35.0, -9.0), Vector2(36.0, -6.0), Vector2(35.0, -1.0),
	Vector2(36.0, 1.0), Vector2(39.0, 4.0), Vector2(39.0, 8.0),
	Vector2(38.0, 10.0), Vector2(36.0, 10.5), Vector2(32.0, 11.0),
	Vector2(28.0, 12.0), Vector2(24.0, 13.0), Vector2(20.0, 13.0),
	Vector2(16.0, 13.0), Vector2(12.0, 13.0), Vector2(10.0, 13.0),
	Vector2(6.0, 13.0), Vector2(3.0, 13.0), Vector2(2.0, 13.0),
	Vector2(2.0, 7.0), Vector2(2.0, 0.0), Vector2(2.0, -8.0),
])

var vida := VIDA_MAX
var origen := Vector2.ZERO
var inicio := Vector2.ZERO
var profundidad := 0.0
var puntos_abiertos: Array[Vector2] = []
var patrol_dir := Vector2.RIGHT
var patrol_t := 0.0
var vuelo_t := 0.0
var lock_golpe := 0.0
var descanso_t := 0.0
var angulo := 0.0
var zona_t := 0.0
var flash_t := 0.0
var respawn_t := 0.0
var escala_original := Vector2.ONE


# estados
var rondando := false
var derrotado := false
var en_combate := false
var en_muerte := false

# posicion para combate
var padre_original: Node
var posicion_original := Vector2.ZERO
	
const RUTA_FLASHBACK_ESCENA := "res://scenes/Flashback.tscn"
const RUTA_TEXTURA_COMBATE := "res://assets/enemigos/halcon-pelea-idle.png"

var frames_vuelo: SpriteFrames
var frames_combate: SpriteFrames

func _ready():
	frames_vuelo = $AnimatedSprite2D.sprite_frames
	add_to_group("halcon")
	origen = global_position
	inicio = global_position
	escala_original = $AnimatedSprite2D.scale
	call_deferred("_armar_puntos")
	call_deferred("_ignorar_colision_con_cavillaca")
	$Detector.add_to_group("halcon")
	$Detector.body_entered.connect(_on_body_entered)

	$AnimatedSprite2D.play("lado")

func _ignorar_colision_con_cavillaca() -> void:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as CharacterBody2D
	if cavillaca != null:
		add_collision_exception_with(cavillaca)


func _process(delta):
	# Animacion de golpeado
	if not en_muerte:
		var escala_base := escala_original * (2.0 if en_combate else 1.0)
		if flash_t > 0.0:
			flash_t -= delta
			$AnimatedSprite2D.scale = escala_base * Vector2(1.35, 0.8)
		else:
			$AnimatedSprite2D.scale = escala_base
	
	if en_combate:
		return
	
	if Global.hacia_el_mar:
		Global.halcon_cerca = false
		return
	if derrotado:
		respawn_t -= delta
		Global.halcon_cerca = false
		if respawn_t <= 0.0 and Global.recuerdos_obtenidos < Global.RECUERDOS_TOTALES:
			_revivir()
		return

	vuelo_t += delta
	if lock_golpe > 0.0:
		lock_golpe = max(lock_golpe - delta, 0.0)

	if descanso_t > 0.0:
		descanso_t = max(descanso_t - delta, 0.0)
		_retirarse(delta)
		if descanso_t <= 0.0:
			_aparecer_en_otro_lado()
		Global.halcon_cerca = false
		return

	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	var cerca := false
	if cavillaca != null:
		var objetivo := _obtener_punto_objetivo(cavillaca)
		var distancia := global_position.distance_to(objetivo)
		
		if rondando and distancia > RANGO_CORTE:
			rondando = false
			_empezar_descanso()
		elif rondando or distancia <= RANGO_DETECCION:
			rondando = true
			zona_t = 0.0
			cerca = true
			_revolotear(delta, cavillaca)
		else:
			_patrullar(delta)

	Global.halcon_cerca = cerca

func _revivir():
	derrotado = false
	en_muerte = false
	vida = VIDA_MAX
	lock_golpe = 0.0
	_aparecer_en_otro_lado()
	descanso_t = 0.0
	$AnimatedSprite2D.play("lado")
	show()
	$Detector.monitoring = true
	$Detector.monitorable = true


func debug_aparecer_al_lado(posicion: Vector2) -> void:
	if not OS.is_debug_build() or en_combate:
		return
	if puntos_abiertos.is_empty():
		_armar_puntos()
	var posicion_segura := posicion
	if not _posicion_es_spawn_valido(posicion_segura):
		if puntos_abiertos.is_empty():
			return
		posicion_segura = puntos_abiertos[0]
		for punto in puntos_abiertos:
			if punto.distance_squared_to(posicion) < posicion_segura.distance_squared_to(posicion):
				posicion_segura = punto
	global_position = posicion_segura
	origen = posicion_segura
	vida = VIDA_MAX
	derrotado = false
	en_muerte = false
	descanso_t = 0.0
	lock_golpe = 0.0
	respawn_t = 0.0
	rondando = false
	Global.halcon_cerca = true
	$AnimatedSprite2D.scale = escala_original
	$AnimatedSprite2D.play("lado")
	$Detector.set_deferred("monitoring", true)
	$Detector.set_deferred("monitorable", true)
	show()


func _armar_puntos() -> void:
	puntos_abiertos.clear()
	var suelo := get_tree().current_scene.get_node_or_null("SueloTiles") as TileMapLayer
	if suelo == null:
		return
	var bordes := get_tree().current_scene.get_node_or_null("Bordes") as TileMapLayer
	var cueva := get_tree().get_first_node_in_group("zona_segura") as Node2D
	for celda in suelo.get_used_cells():
		if not Geometry2D.is_point_in_polygon(Vector2(celda), zona_aparicion_celdas):
			continue
		if bordes != null and bordes.get_cell_source_id(celda) != -1:
			continue
		var punto := suelo.to_global(suelo.map_to_local(celda))
		if _esta_en_exclusion_tronco(punto, cueva):
			continue
		puntos_abiertos.append(punto)


func _esta_en_exclusion_tronco(punto: Vector2, refugio: Node2D) -> bool:
	if refugio == null:
		return false
	var exclusion := Rect2(
		refugio.global_position + EXCLUSION_TRONCO_OFFSET,
		EXCLUSION_TRONCO_TAMANO
	)
	return exclusion.has_point(punto)


func _posicion_es_spawn_valido(punto: Vector2) -> bool:
	var suelo := get_tree().current_scene.get_node_or_null("SueloTiles") as TileMapLayer
	if suelo == null:
		return false
	var celda := suelo.local_to_map(suelo.to_local(punto))
	if suelo.get_cell_source_id(celda) == -1:
		return false
	var bordes := get_tree().current_scene.get_node_or_null("Bordes") as TileMapLayer
	if bordes != null and bordes.get_cell_source_id(celda) != -1:
		return false
	if not Geometry2D.is_point_in_polygon(Vector2(celda), zona_aparicion_celdas):
		return false
	var refugio := get_tree().get_first_node_in_group("zona_segura") as Node2D
	return not _esta_en_exclusion_tronco(punto, refugio)


func _aparecer_en_otro_lado() -> void:
	if puntos_abiertos.is_empty():
		_armar_puntos()
	var punto := _elegir_mas_adelante()
	origen = punto
	global_position = punto
	profundidad = inicio.distance_to(punto)
	patrol_t = 0.0
	zona_t = 0.0
	rondando = false
	$AnimatedSprite2D.play("lado")


func _elegir_mas_adelante() -> Vector2:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	var banda: Array[Vector2] = []
	var mas_lejos: Array[Vector2] = []
	for punto in puntos_abiertos:
		if not _sirve(punto, cavillaca):
			continue
		var avance := inicio.distance_to(punto) - profundidad
		if avance >= PASO_MIN and avance <= PASO_MAX:
			banda.append(punto)
		elif avance > PASO_MAX:
			mas_lejos.append(punto)
	if not banda.is_empty():
		return banda.pick_random()
	if not mas_lejos.is_empty():
		return mas_lejos.pick_random()
	var fondo: Array[Vector2] = []
	for punto in puntos_abiertos:
		if not _sirve(punto, cavillaca):
			continue
		if inicio.distance_to(punto) > profundidad * 0.7:
			fondo.append(punto)
	if fondo.is_empty():
		return origen
	return fondo.pick_random()


func _sirve(punto: Vector2, cavillaca: Node2D) -> bool:
	if punto.distance_to(origen) < SEPARACION:
		return false
	if cavillaca != null:
		var objetivo := _obtener_punto_objetivo(cavillaca)

		if punto.distance_to(objetivo) < SEPARACION:
			return false

	return true


func _revolotear(delta: float, cavillaca: Node2D) -> void:
	angulo += delta * 2.4
	var objetivo := _obtener_punto_objetivo(cavillaca)
	var radio := RADIO_REVOLOTEO + sin(vuelo_t * 1.6) * AMPLITUD_REVOLOTEO
	var desplazamiento_orbita := Vector2(cos(angulo) * radio, sin(angulo) * radio * 0.35)
	var destino := objetivo + desplazamiento_orbita
	var antes := global_position
	var desplazamiento := (destino - global_position).limit_length(VELOCIDAD_REVOLOTEO * delta)
	_mover_con_colision(desplazamiento, delta)
	
	var hacia := global_position - antes
	if abs(hacia.x) > 0.2:
		$AnimatedSprite2D.flip_h = hacia.x < 0.0
	
	if lock_golpe <= 0.0 and $AnimatedSprite2D.animation != "lado":
		$AnimatedSprite2D.play("lado")


func _empezar_descanso() -> void:
	rondando = false
	descanso_t = DESCANSO_PERSECUCION
	$AnimatedSprite2D.play("lado")


func _retirarse(delta: float) -> void:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	var hacia := Vector2.RIGHT
	
	if cavillaca != null:
		hacia = global_position - cavillaca.global_position
	if hacia.length_squared() < 16.0:
		hacia = Vector2.RIGHT
		
	_mover_con_colision(hacia.normalized() * VELOCIDAD_RETIRADA * delta, delta)

func _patrullar(delta: float):
	zona_t += delta
	if zona_t >= TIEMPO_EN_ZONA:
		_aparecer_en_otro_lado()
		return

	patrol_t += delta
	if patrol_t > 1.6:
		patrol_t = 0.0
		patrol_dir *= -1.0
	_mover_con_colision(patrol_dir * VELOCIDAD_PATRULLA * delta, delta)
	if global_position.distance_to(origen) > 70.0:
		var desplazamiento := (origen - global_position).limit_length(40.0 * delta)
		_mover_con_colision(desplazamiento, delta)


func _mover_con_colision(desplazamiento: Vector2, delta: float) -> void:
	if delta <= 0.0:
		return
	velocity = desplazamiento / delta
	move_and_slide()


func _on_body_entered(body: Node):
	if derrotado or descanso_t > 0.0: #or lock_golpe > 0.0
		return
	if body.is_in_group("cavillaca"):
		Global.halcon_cerca = true

func _obtener_punto_objetivo(cavillaca: Node2D) -> Vector2:
	var punto := cavillaca.get_node_or_null("PuntoObjetivoHalcon") as Node2D
	
	if punto != null:
		return punto.global_position
	
	return cavillaca.global_position
	
# La hoja grande exclusiva del combate se carga solo al primer encuentro.
func _obtener_frames_combate() -> SpriteFrames:
	if frames_combate != null:
		return frames_combate

	var textura := load(RUTA_TEXTURA_COMBATE) as Texture2D
	if textura == null:
		push_error("No se pudo cargar la textura de combate del halcón")
		return null

	frames_combate = SpriteFrames.new()
	frames_combate.add_animation("frente_combate")
	frames_combate.set_animation_loop("frente_combate", true)
	frames_combate.set_animation_speed("frente_combate", 5.0)
	for indice in range(6):
		var atlas := AtlasTexture.new()
		atlas.atlas = textura
		atlas.region = Rect2(indice * 1024, 0, 1024, 1024)
		frames_combate.add_frame("frente_combate", atlas)
	return frames_combate


# Funciones utilizadas en combate
func entrar_en_combate():
	var animaciones_combate := _obtener_frames_combate()
	if animaciones_combate == null:
		return
	var combate := get_tree().current_scene.get_node("CombateHalcon")
	var punto := combate.get_node("PuntoHalcon") as Node2D
	#var punto_izquierda := combate.get_node("PuntoHalconIzquierda") as Node2D
	#var punto_derecha := combate.get_node("PuntoHalconDerecha") as Node2D

	padre_original = get_parent()
	posicion_original = global_position
	vida = VIDA_MAX
	en_combate = true
	Global.halcon_cerca = false
	Global.prompt_interaccion = "E  Atacar"
	combate.get_node("VidasHalcon").show()
	_actualizar_vidas()
	Musica.iniciar_combate()
	reparent(combate)
	position = punto.position
	$AnimatedSprite2D.scale = escala_original * 2.0
	collision_mask = 0
	$Detector.monitoring = false # desactiva detecciones durante el combate.
	$Detector.monitorable = true # permite que piedra detecte al halcón.
	
	$AnimatedSprite2D.flip_h = false
	$AnimatedSprite2D.sprite_frames = animaciones_combate
	$AnimatedSprite2D.play("frente_combate")
	
func salir_de_combate():
	en_combate = false
	Musica.detener_pista_combate()
	Global.halcon_cerca = false
	Global.prompt_interaccion = ""
	$AnimatedSprite2D.scale = escala_original
	if frames_vuelo != null:
		$AnimatedSprite2D.sprite_frames = frames_vuelo
	collision_mask = 5
	
	if padre_original != null:
		reparent(padre_original)
		global_position = posicion_original
	frames_combate = null
	
	$AnimatedSprite2D.play("lado")

func _actualizar_vidas():
	var combate := get_tree().current_scene.get_node_or_null("CombateHalcon")
	
	if combate == null:
		return
	
	combate.get_node("VidasHalcon/Vida1").visible = vida >= 1
	combate.get_node("VidasHalcon/Vida2").visible = vida >= 2
	combate.get_node("VidasHalcon/Vida3").visible = vida >= 3

func recibir_golpe(direccion: Vector2):
	if derrotado:
		return

	vida -= 1
	_actualizar_vidas()
	flash_t = 0.12
	

	global_position += direccion.normalized() * 5.0

	if vida <= 0:
		_victoria()
	else:
		$AtaqueSFX.play()

func esquivar_hacia(punto: Node2D):
	var tween := create_tween()
	tween.tween_property(
		self,
		"global_position",
		punto.global_position,
		0.2
	)
	
	await tween.finished
	
	var combate := get_tree().current_scene.get_node("CombateHalcon")
	var centro := combate.get_node("PuntoHalcon") as Node2D

	var tween_vuelta := create_tween()
	tween_vuelta.tween_property(
		self,
		"global_position",
		centro.global_position,
		0.4
	)

func _victoria():
	derrotado = true
	en_muerte = true
	Global.halcon_cerca = false
	Global.prompt_interaccion = ""
	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if hud != null and hud.has_method("ocultar_prompt_interaccion"):
		hud.ocultar_prompt_interaccion()
	
	$MuerteSFX.play()
	
	var tween := create_tween()
	tween.tween_property(
		$AnimatedSprite2D,
		"scale",
		escala_original * 1.2,
		0.1
	)
	tween.tween_property(
		$AnimatedSprite2D,
		"scale",
		escala_original * 0.0,
		0.8
	)

	await get_tree().create_timer(2.0).timeout
	$MuerteSFX.stop()
	
	var combate := get_tree().current_scene.get_node_or_null("CombateHalcon")
	if combate != null:
		combate.hide()
	
	salir_de_combate()
	if is_instance_valid(padre_original) and padre_original.has_method("liberar_combate_halcon"):
		padre_original.call("liberar_combate_halcon", combate)
	elif is_instance_valid(combate):
		combate.queue_free()
	
	hide()
	$Detector.set_deferred("monitoring", false)
	$Detector.set_deferred("monitorable", false)

	if Global.recuerdos_obtenidos >= Global.RECUERDOS_TOTALES:
		Musica.terminar_combate()
		respawn_t = TIEMPO_RESPAWN
		return
	var indice := Global.obtener_recuerdo()
	respawn_t = 99999.0 if indice >= Global.RECUERDOS_TOTALES else TIEMPO_RESPAWN
	var escena_flashback := load(RUTA_FLASHBACK_ESCENA) as PackedScene
	if escena_flashback == null:
		push_error("No se pudo cargar Flashback.tscn")
		return
	var flashback := escena_flashback.instantiate()
	flashback.configurar(indice)
	flashback.connect("terminado", Callable(Musica, "terminar_combate"))
	hud.add_child(flashback)
