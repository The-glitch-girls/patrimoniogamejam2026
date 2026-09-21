extends Node

# =========================
# INPUT MAP
# =========================
# "correr": Shift

# =========================
# ESTADO DEL JUEGO
# =========================
var energia: float = 100.0
var cordura: float = 100.0
var lleva_bebe: bool = false
var tiempo_juego: float = 0.0
var presencia_cuniraya: float = 0.0
var flashbacks_desbloqueados: Array[String] = []

# Temporizadores
var cordura_temporizador: float = 0.0

# =========================
# CONFIGURACIÓN
# =========================

const ENERGIA_MAX: float = 100.0
const CORDURA_MAX: float = 100.0
const PERDIDA_CORDURA_POR_SEGUNDO: float = 0.1 # TEST-MODE: pierde 1 de energia por segundo
const COSTO_CAMINAR: float = 0.5
const COSTO_CORRER: float = 2.0
const COSTO_CARGAR_BEBE: float = 2.0

# =========================
# PROCESO
# =========================

func _process(delta):
	tiempo_juego += delta
	cordura_temporizador += delta

	if cordura_temporizador >= 1.0:
		cordura_temporizador = 0
		perder_cordura(PERDIDA_CORDURA_POR_SEGUNDO)

# =========================
# ENERGÍA
# =========================

func perder_energia(cantidad: float):
	energia = max(energia - cantidad, 0)


func recuperar_energia(cantidad: float):
	energia = min(energia + cantidad, ENERGIA_MAX)


# =========================
# CORDURA
# =========================

func perder_cordura(cantidad: float):
	cordura = max(cordura - cantidad, 0)
