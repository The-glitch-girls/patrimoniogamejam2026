extends StaticBody2D

const CAPA_COLISION_SOLIDA := 4
const MASCARA_COLISION_SOLIDA := 1
# Anclas visuales, medidas desde el origen de cada personaje.
const OFFSET_PIES_BEBE_Y := 48.0
const ORDEN_VISUAL := preload("res://scripts/componentes/orden_visual.gd")

const SFX_RECOGER := preload("res://sfx/interaccion/bebe_recoger.ogg")
const SFX_DEJAR := preload("res://sfx/interaccion/bebe_dejar.ogg")
const OFFSET_CARGADO := Vector2(22, -52)
const SEGUIMIENTO := 14.0

var bob_t := 0.0
var llorando := false
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision_cuerpo: CollisionPolygon2D = $ColisionCuerpo
@onready var bloqueo_pies: CollisionShape2D = $BloqueoPies
@onready var sonido_accion: AudioStreamPlayer = $SonidoAccion

func _ready() -> void:
	add_to_group("bebe")
	z_index = 0
	# Usa la misma pareja de capa/máscara que el loro y el zorro.
	collision_layer = CAPA_COLISION_SOLIDA
	collision_mask = MASCARA_COLISION_SOLIDA
	colision_cuerpo.disabled = Global.lleva_bebe
	bloqueo_pies.disabled = Global.lleva_bebe
	sprite.play("normal")

func _process(delta: float) -> void:
	# Global.lleva_bebe también cambia desde Refugio y desde las transiciones.
	# Mantener ambos colliders sincronizados evita formas activas mientras lo cargan.
	_sincronizar_colisiones()

	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if Global.lleva_bebe:
		# Al cargarlo, el dibujo debe quedar delante de Cavillaca.
		sprite.z_index = 1
		_seguir_carga(cavillaca, delta)
		return

	bob_t += delta
	sprite.position = Vector2(
		0,
		-0.7 + sin(bob_t * 3.2) * 0.1
	)

	if cavillaca != null and cavillaca.esta_cerca_del_bebe():
		sprite.modulate = Color(1.18, 1.12, 0.95)
	else:
		sprite.modulate = Color.WHITE
	_actualizar_orden_visual()

func _actualizar_orden_visual() -> void:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	ORDEN_VISUAL.actualizar_sprite(sprite, self, cavillaca, OFFSET_PIES_BEBE_Y)

func recoger() -> void:
	_sonar_accion(SFX_RECOGER)
	Global.lleva_bebe = true
	_sincronizar_colisiones()
	llorando = false
	sprite.play("normal")


func dejar(_posicion: Vector2) -> bool:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	
	if cavillaca == null:
		return false

	# Usa la posición frontal solicitada por Cavillaca. Al dejarlo hacia abajo,
	# lo aleja un poco más para que su nueva colisión no aparezca dentro del jugador.
	var destino := _posicion
	if cavillaca.facing.y > 0.0:
		destino += Vector2.DOWN * 72.0
	if not _hay_suelo_suficiente(destino):
		return false

	_sonar_accion(SFX_DEJAR)
	global_position = destino

	Global.lleva_bebe = false
	sprite.position = Vector2(0, -14)
	sprite.modulate = Color.WHITE
	_sincronizar_colisiones()
	return true


func _hay_suelo_suficiente(posicion_bebe: Vector2) -> bool:
	var suelo := get_tree().current_scene.get_node_or_null("SueloTiles") as TileMapLayer
	if suelo == null:
		return false

	# Comprueba la huella de los pies, no solo el centro del bebé, para que no
	# pueda quedar parcialmente suspendido en el borde de un hueco.
	var centro_pies := posicion_bebe + Vector2(0.0, OFFSET_PIES_BEBE_Y)
	for desplazamiento_y in [-10.0, 0.0, 10.0]:
		for desplazamiento_x in [-48.0, -24.0, 0.0, 24.0, 48.0]:
			var punto_global := centro_pies + Vector2(desplazamiento_x, desplazamiento_y)
			var celda := suelo.local_to_map(suelo.to_local(punto_global))
			if suelo.get_cell_source_id(celda) == -1:
				return false
	return true


func _sincronizar_colisiones() -> void:
	var deshabilitar := Global.lleva_bebe
	if colision_cuerpo.disabled != deshabilitar:
		colision_cuerpo.set_deferred("disabled", deshabilitar)
	if bloqueo_pies.disabled != deshabilitar:
		bloqueo_pies.set_deferred("disabled", deshabilitar)


func reproducir_sonido_dejar() -> void:
	_sonar_accion(SFX_DEJAR)


func _sonar_accion(audio: AudioStream) -> void:
	sonido_accion.stop()
	sonido_accion.stream = audio
	sonido_accion.play()

func _seguir_carga(cavillaca: Node2D, delta: float):
	if cavillaca == null:
		return

	var lado := 1.0
	if "facing" in cavillaca and cavillaca.facing.x < 0.0:
		lado = -1.0

	var destino := cavillaca.global_position + Vector2(OFFSET_CARGADO.x * lado, OFFSET_CARGADO.y)
	global_position = global_position.lerp(destino, 1.0 - exp(-SEGUIMIENTO * delta))
	sprite.position = Vector2.ZERO
	sprite.modulate = Color(1.05, 0.98, 0.9)

func cambiar_llanto(valor: bool) -> void:
	llorando = valor

	if llorando:
		sprite.play("llorando")
	else:
		sprite.play("normal")
