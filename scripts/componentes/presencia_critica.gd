extends Node
## Señales visuales de la presencia de Cuniraya:
## - muesca en la barra en Global.PRESENCIA_CRITICA,
## - aviso único al cruzarla,
## - la barra de energía parpadea mientras se drena (presencia crítica sin bebé),
## - flecha ▼ cuando la presencia baja (al cargar al bebé).

const LILA := Color(0.67, 0.62, 0.93, 1)
const ROJO := Color(0.9, 0.3, 0.38, 1)
const CREMA := Color(0.99, 0.96, 0.9, 1)

var hud: CanvasLayer
var relleno: StyleBoxFlat
var flecha: Polygon2D
var aviso_dado := false
var presencia_previa := 0.0
var tiempo := 0.0


func _ready() -> void:
	hud = get_parent()
	var marco: Panel = hud.marco_presencia
	relleno = hud.barra_presencia.get_theme_stylebox("fill") as StyleBoxFlat
	_poner_muesca(marco)
	flecha = Polygon2D.new()
	flecha.polygon = PackedVector2Array([Vector2(0, 0), Vector2(12, 0), Vector2(6, 9)])
	flecha.color = CREMA
	flecha.position = Vector2(marco.size.x + 8, 10)
	flecha.visible = false
	marco.add_child(flecha)
	presencia_previa = Global.presencia_cuniraya
	# No repetir el aviso si la partida empieza ya en zona crítica.
	aviso_dado = Global.presencia_cuniraya >= Global.PRESENCIA_CRITICA


func _poner_muesca(marco: Panel) -> void:
	# La barra ocupa el marco menos 6 px por lado (ver hud._envolver_barra).
	var ancho_util := marco.size.x - 12.0
	var x := 6.0 + ancho_util * Global.PRESENCIA_CRITICA / Global.PRESENCIA_MAX
	var muesca := ColorRect.new()
	muesca.color = CREMA
	muesca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	muesca.position = Vector2(x - 1.5, 2)
	muesca.size = Vector2(3, marco.size.y - 4)
	marco.add_child(muesca)


func _drenando() -> bool:
	return Global.presencia_cuniraya >= Global.PRESENCIA_CRITICA and not Global.lleva_bebe \
		and not (Global.hacia_el_mar or Global.flashback_abierto or Global.partida_terminada) \
		and not get_tree().paused


func _process(delta: float) -> void:
	tiempo += delta
	var presencia := Global.presencia_cuniraya
	var critica := presencia >= Global.PRESENCIA_CRITICA
	if relleno:
		relleno.bg_color = ROJO if critica else LILA
	if critica and not aviso_dado and not Global.partida_terminada:
		aviso_dado = true
		Global.mostrar_aviso(Traducciones.obtener("presence_critical_warning"))
	flecha.visible = presencia < presencia_previa - 0.0001 and hud.marco_presencia.visible
	presencia_previa = presencia

	var energia: Control = hud.barra_energia.get_parent()
	if _drenando():
		var pulso := 0.5 + 0.5 * sin(tiempo * 9.0)
		energia.modulate = Color(1, 0.45 + 0.55 * pulso, 0.5 + 0.5 * pulso, 0.55 + 0.45 * pulso)
	else:
		energia.modulate = Color.WHITE
