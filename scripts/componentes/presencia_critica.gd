extends Node
## Señales visuales de la presencia de Cuniraya:
## - muesca en la barra en Global.PRESENCIA_CRITICA,
## - aviso único al cruzarla,
## - la barra de energía parpadea mientras se drena (presencia crítica sin bebé),
## - flecha ▼ cuando la presencia baja (al cargar al bebé).

const TINTE_CRITICO := Color(1.0, 0.42, 0.5, 1)
const CREMA := Color(0.99, 0.96, 0.9, 1)
const CONTORNO := Color(0.1, 0.07, 0.2, 0.95)

var hud: CanvasLayer
var barra: TextureProgressBar
var flecha: Node2D
var aviso_dado := false
var presencia_previa := 0.0
var tiempo := 0.0


func _ready() -> void:
	hud = get_parent()
	barra = hud.barra_presencia_texture
	_poner_muesca.call_deferred()
	_poner_flecha.call_deferred()
	presencia_previa = Global.presencia_cuniraya
	# No repetir el aviso si la partida empieza ya en zona crítica.
	aviso_dado = Global.presencia_cuniraya >= Global.PRESENCIA_CRITICA


func _poner_muesca() -> void:
	# Hija de la barra: hereda su escala, así que el ancho se compensa.
	var x := barra.size.x * Global.PRESENCIA_CRITICA / Global.PRESENCIA_MAX
	var ancho := 3.0 / maxf(barra.scale.x, 0.01)
	var muesca := ColorRect.new()
	muesca.color = CREMA
	muesca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	muesca.position = Vector2(x - ancho * 0.5, barra.size.y * 0.1)
	muesca.size = Vector2(ancho, barra.size.y * 0.8)
	barra.add_child(muesca)


func _poner_flecha() -> void:
	# ▼ junto a la barra (sin escalar), con contorno para que se lea sobre el mapa.
	flecha = Node2D.new()
	var contorno := Polygon2D.new()
	contorno.polygon = PackedVector2Array([Vector2(-3, -2), Vector2(23, -2), Vector2(10, 17)])
	contorno.color = CONTORNO
	var relleno := Polygon2D.new()
	relleno.polygon = PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(10, 13)])
	relleno.color = CREMA
	flecha.add_child(contorno)
	flecha.add_child(relleno)
	var ancho_visible := barra.size.x * barra.scale.x
	var alto_visible := barra.size.y * barra.scale.y
	flecha.position = barra.position + Vector2(ancho_visible + 10, alto_visible * 0.5 - 7)
	flecha.visible = false
	barra.get_parent().add_child(flecha)


func _drenando() -> bool:
	return Global.presencia_cuniraya >= Global.PRESENCIA_CRITICA and not Global.lleva_bebe \
		and not (Global.hacia_el_mar or Global.flashback_abierto or Global.partida_terminada) \
		and not get_tree().paused


func _process(delta: float) -> void:
	tiempo += delta
	var presencia := Global.presencia_cuniraya
	var critica := presencia >= Global.PRESENCIA_CRITICA
	barra.tint_progress = TINTE_CRITICO if critica else Color.WHITE
	if critica and not aviso_dado and not Global.partida_terminada:
		aviso_dado = true
		Global.mostrar_aviso(Traducciones.obtener("presence_critical_warning"))
	if is_instance_valid(flecha):
		flecha.visible = presencia < presencia_previa - 0.0001 and barra.visible
	presencia_previa = presencia

	var energia: Control = hud.barra_energia.get_parent()
	if _drenando():
		var pulso := 0.5 + 0.5 * sin(tiempo * 9.0)
		energia.modulate = Color(1, 0.45 + 0.55 * pulso, 0.5 + 0.5 * pulso, 0.55 + 0.45 * pulso)
	else:
		energia.modulate = Color.WHITE
