extends Area2D

const RECUPERACION_ENERGIA_POR_SEGUNDO := 8.0
const RANGO_INTERACCION := 40.0

var temporizador_recuperacion := 0.0
var bebe_con_zorro := false

func _ready():
	add_to_group("zona_segura")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta):
	var zorro := get_tree().get_first_node_in_group("zorro")
	var zorro_cerca := zorro != null and global_position.distance_to(zorro.global_position) < RANGO_INTERACCION
	
	if zorro_cerca and Global.cueva_zorro_desbloqueada:
		temporizador_recuperacion += delta
		if temporizador_recuperacion >= 1.0:
			temporizador_recuperacion = 0.0
			Global.recuperar_energia(RECUPERACION_ENERGIA_POR_SEGUNDO)
		Global.descanso_con_zorro = true
		
		if bebe_con_zorro:
			$Label.text = "CUEVA ✓ (Bebé seguro)"
		else:
			$Label.text = "CUEVA ✓"
	elif zorro_cerca and not Global.cueva_zorro_desbloqueada:
		Global.descanso_con_zorro = false
		temporizador_recuperacion = 0.0
		$Label.text = "CUEVA ?"
	else:
		Global.descanso_con_zorro = false
		temporizador_recuperacion = 0.0
		$Label.text = "CUEVA"


func dejar_bebe_con_zorro():
	if not Global.cuidado_bebe_desbloqueado:
		Global.mostrar_aviso("Necesitas el Recuerdo 2 para esto")
		return
	
	var zorro := get_tree().get_first_node_in_group("zorro")
	if zorro == null or global_position.distance_to(zorro.global_position) >= RANGO_INTERACCION:
		Global.mostrar_aviso("El zorro no está cerca")
		return
	
	if not Global.lleva_bebe:
		Global.mostrar_aviso("No llevas al bebé")
		return
	
	bebe_con_zorro = true
	Global.lleva_bebe = false
	Global.mostrar_aviso("Bebé dejado con el zorro")
	
	var bebe := get_tree().get_first_node_in_group("bebe")
	if bebe != null:
		bebe.global_position = global_position


func recoger_bebe_del_zorro():
	if not bebe_con_zorro:
		return
	
	bebe_con_zorro = false
	Global.lleva_bebe = true
	Global.mostrar_aviso("Bebé recogido del zorro")
	
	var bebe := get_tree().get_first_node_in_group("bebe")
	if bebe != null:
		bebe.recoger()


func _on_body_entered(body: Node):
	if body.is_in_group("cavillaca"):
		var zorro := get_tree().get_first_node_in_group("zorro")
		var zorro_cerca := zorro != null and global_position.distance_to(zorro.global_position) < RANGO_INTERACCION
		
		if zorro_cerca and Global.cueva_zorro_desbloqueada:
			Global.zona_actual = "Cueva del Zorro"
		elif zorro_cerca and not Global.cueva_zorro_desbloqueada:
			Global.zona_actual = "Cueva del Zorro (?)"
		else:
			Global.zona_actual = "Cueva del Zorro"


func _on_body_exited(body: Node):
	if body.is_in_group("cavillaca"):
		Global.zona_actual = "Plaza"
		Global.descanso_con_zorro = false