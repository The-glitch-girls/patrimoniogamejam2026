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
var flashbacks_desbloqueados: Array[String] = []
var prompt_interaccion: String = ""
var zona_actual: String = "Plaza"
var halcon_cerca: bool = false
var aviso_combate: String = ""

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
const DANIO_CORDURA_DERROTA: float = 12.0
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
# PRESENCIA DE CUNIYARA
# =========================
func aumentar_presencia(delta: float):
	presencia_cuniraya = min(
		presencia_cuniraya + VELOCIDAD_PRESENCIA * delta,
		PRESENCIA_MAX
	)
	
	print("Presencia: ", presencia_cuniraya)

# =========================
# AVISO DE COMBATE
# =========================
func mostrar_aviso(texto: String):
	aviso_combate = texto
	aviso_temporizador = 2.0
