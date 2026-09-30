extends Node

# =========================
# INPUT MAP
# =========================
# "correr": Shift
# "interactuar": E
# "atacar": Espacio
# "mover_*": flechas o WASD

# =========================
# ESTADO DEL JUEGO
# =========================
var energia: float = 100.0
var lleva_bebe: bool = false
var tiempo_juego: float = 0.0
var presencia_cuniraya: float = 0.0
var presencia_activa: bool = false
var flashbacks_desbloqueados: Array[String] = []
var prompt_interaccion: String = ""
var zona_actual: String = "Plaza"
var halcon_cerca: bool = false
var zorro_cerca: bool = false
var aviso_combate: String = ""
var partida_terminada: bool = false
var descanso_con_zorro: bool = false
var cuidado_bebe_desbloqueado: bool = false
var hacia_el_mar: bool = false
var flashback_abierto: bool = false
var resultado_final: String = ""

# Sistema de Recuerdos
var recuerdos_obtenidos: int = 0
const RECUERDOS_TOTALES: int = 3
const RECUERDOS := {
	1: {
		"id": "acoso",
		"titulo": "El que observaba",
		"texto": "Cuniraya tomaba la forma de distintos animales para acercarse sin ser visto.
				Él lo llamaba amor. Cavillaca nunca lo pidió.",
		"asset": "res://assets/cinematicas/recuerdo_1.png"
	},
	2: {
		"id": "lucuma",
		"titulo": "La semilla del engaño",
		"texto": "Cuniraya dejó una lúcuma entre las ramas.\nCavillaca la comió sin saber lo que llevaba dentro.",
		#,
		#"asset": "res://assets/cinematicas/recuerdo_2.png"
	},
	3: {
		"id": "gateo",
		"titulo": "Ya no había duda",
		"texto": "El bebé gateó hacia él.\nCavillaca comprendió quién era su padre.",
		"asset": "res://assets/cinematicas/recuerdo_3.png"
	},
}
const DESTINO_MAR := Vector2(620, 880)
const ESCENA_FINAL := "res://scenes/Final.tscn"

# Temporizadores
# Temporizadores # EDITAR
var aviso_temporizador: float = 0.0

# =========================
# CONFIGURACIÓN
# =========================
const LIMITE_MAPA := Rect2(0, 0, 4096, 3072)
const ENERGIA_MAX: float = 100.0
# PRESENCIA CUNIRAYA
const PRESENCIA_MAX := 100.0
const VELOCIDAD_PRESENCIA := 5.0
# COSTOS Y DAÑOS
const COSTO_CAMINAR: float = 0.5
const COSTO_CORRER: float = 2.0
const COSTO_CARGAR_BEBE: float = 2.0
const COSTO_ARROJAR: float = 1.0
const DANIO_ENERGIA_DERROTA: float = 15.0
const DANIO_PRESENCIA_DERROTA: float = 1
const PRESENCIA_CRITICA: float = 75.0
const DRENAJE_CRITICO: float = 4.0
# RECOMPENSA
const RECOMPENSA_VICTORIA: float = 12.0

# =========================
# PROCESO
# =========================

func _process(delta):
	tiempo_juego += delta

	if aviso_temporizador > 0.0:
		aviso_temporizador = max(aviso_temporizador - delta, 0.0)
		if aviso_temporizador <= 0.0:
			aviso_combate = ""

	if hacia_el_mar or flashback_abierto or partida_terminada:
		return
	if presencia_cuniraya >= PRESENCIA_CRITICA and not lleva_bebe:
		perder_energia(DRENAJE_CRITICO * delta)

# =========================
# ENERGÍA
# =========================

func perder_energia(cantidad: float):
	var antes := energia
	energia = max(energia - cantidad, 0)
	if antes > 0.0 and energia <= 0.0:
		terminar("perder")


func recuperar_energia(cantidad: float):
	energia = min(energia + cantidad, ENERGIA_MAX)

# =========================
# PRESENCIA DE CUNIRAYA
# =========================

func aumentar_presencia(cantidad: float = 1.0):
	presencia_cuniraya = min(presencia_cuniraya + cantidad, PRESENCIA_MAX)


func reducir_presencia():
	presencia_cuniraya = max(presencia_cuniraya - 1, 0)


func aumentar_presencia_por_tiempo(delta: float):
	presencia_cuniraya = min(
		presencia_cuniraya + VELOCIDAD_PRESENCIA * delta,
		PRESENCIA_MAX
	)


func obtener_recuerdo() -> int:
	if recuerdos_obtenidos >= RECUERDOS_TOTALES:
		return recuerdos_obtenidos
	recuerdos_obtenidos += 1
	if recuerdos_obtenidos == 1:
		descanso_con_zorro = true
	elif recuerdos_obtenidos == 2:
		cuidado_bebe_desbloqueado = true
	return recuerdos_obtenidos


# =========================
# AVISO DE COMBATE
# =========================
func mostrar_aviso(texto: String):
	aviso_combate = texto
	aviso_temporizador = 2.0


func terminar(resultado: String) -> void:
	if resultado == "ganar":
		iniciar_hacia_el_mar()
		return
	if partida_terminada:
		return
	partida_terminada = true
	abrir_final("cuniraya")


func iniciar_hacia_el_mar() -> void:
	if hacia_el_mar:
		return
	hacia_el_mar = true
	partida_terminada = true
	prompt_interaccion = ""


func abrir_final(tipo: String) -> void:
	if resultado_final != "":
		return
	resultado_final = tipo
	partida_terminada = true
	if tipo == "mar":
		Musica.tocar("ganar")
	else:
		Musica.tocar("perder")
	get_tree().change_scene_to_file(ESCENA_FINAL)


func resetear():
	energia = ENERGIA_MAX
	lleva_bebe = false
	tiempo_juego = 0.0
	presencia_cuniraya = 0.0
	presencia_activa = false
	flashbacks_desbloqueados.clear()
	prompt_interaccion = ""
	zona_actual = "Plaza"
	halcon_cerca = false
	zorro_cerca = false
	aviso_combate = ""
	descanso_con_zorro = false
	cuidado_bebe_desbloqueado = false
	recuerdos_obtenidos = 0
	aviso_temporizador = 0.0
	partida_terminada = false
	hacia_el_mar = false
	flashback_abierto = false
	resultado_final = ""
