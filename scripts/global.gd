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
var presencia_cuniraya: int = 0
var presencia_cuniraya: float = 0.0
var presencia_activa: bool = false
var flashbacks_desbloqueados: Array[String] = []
var prompt_interaccion: String = ""
var zona_actual: String = "Plaza"
var halcon_cerca: bool = false
var zorro_cerca: bool = false
var aviso_combate: String = ""
var descanso_con_zorro: bool = false
var cuidado_bebe_desbloqueado: bool = false

# Sistema de Recuerdos
var recuerdos_obtenidos: int = 0
const RECUERDOS_TOTALES: int = 3

# Temporizadores
# Temporizadores # EDITAR
var aviso_temporizador: float = 0.0

# =========================
# CONFIGURACIÓN
# =========================
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

# =========================
# ENERGÍA
# =========================

func perder_energia(cantidad: float):
	energia = max(energia - cantidad, 0)


func recuperar_energia(cantidad: float):
	energia = min(energia + cantidad, ENERGIA_MAX)

# =========================
# PRESENCIA DE CUNIRAYA
# =========================

func aumentar_presencia():
	presencia_cuniraya = min(presencia_cuniraya + 1, 3)


func reducir_presencia():
	presencia_cuniraya = max(presencia_cuniraya - 1, 0)


# =========================
# RECUERDOS
# PRESENCIA DE CUNIYARA
# =========================
func aumentar_presencia(delta: float):
	presencia_cuniraya = min(
		presencia_cuniraya + VELOCIDAD_PRESENCIA * delta,
		PRESENCIA_MAX
	)
	
	print("Presencia: ", presencia_cuniraya)

func obtener_recuerdo():
	recuerdos_obtenidos = min(recuerdos_obtenidos + 1, RECUERDOS_TOTALES)
	
	if recuerdos_obtenidos == 1:
		Global.mostrar_aviso("Recuerdo 1/3 - Descanso desbloqueado")
	elif recuerdos_obtenidos == 2:
		cuidado_bebe_desbloqueado = true
		Global.mostrar_aviso("Recuerdo 2/3 - Cuidado bebé desbloqueado")
	elif recuerdos_obtenidos == 3:
		Global.mostrar_aviso("Recuerdo 3/3 - Final desbloqueado")


# =========================
# AVISO DE COMBATE
# =========================
func mostrar_aviso(texto: String):
	aviso_combate = texto
	aviso_temporizador = 2.0
