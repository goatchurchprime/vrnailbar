extends Node


@onready var xro = get_parent().get_parent()
@onready var htd = get_parent()
@onready var rt3 = get_node("/root/Main/XROrigin3D/XRController3DLeft/RemoteTransform3D")
@onready var vm = get_node("/root/Main/ViewportMesh")
@onready var bm = get_node("/root/Main/Brush")
@onready var poke = get_node("/root/Main/Poke")
@onready var elasticwire = get_node("/root/Main/ElasticWire")
var leftie = true

var brokerurl = null # "mosquitto.doesliverpool.xyz"
var mqttpublish = false

func _ready():
	if leftie:
		var ba = bm.get_node("BrushAngle")
		ba.rotation_degrees = Vector3(-25, -50, 0)

	if brokerurl:
		$MQTT.connect_to_broker(brokerurl)

var Nd = 1.0
var vmlocked = false
func _process(delta):
	var autohanddominant = htd.autohandleft if leftie else htd.autohandright
	var autohandsecondary = htd.autohandright if leftie else htd.autohandleft
	
	if autohandsecondary and autohandsecondary.handtrackingactive:
		var wristringdistance = (autohandsecondary.oxrktransRaw[OpenXRInterface.HAND_JOINT_RING_TIP].origin - autohandsecondary.oxrktransRaw[OpenXRInterface.HAND_JOINT_WRIST].origin).length()
		if wristringdistance < 0.1:
			var thumbtip = xro.transform*autohandsecondary.oxrktransRaw[OpenXRInterface.HAND_JOINT_THUMB_TIP].origin
			var indextip = xro.transform*autohandsecondary.oxrktransRaw[OpenXRInterface.HAND_JOINT_INDEX_TIP].origin
			var middletip = xro.transform*autohandsecondary.oxrktransRaw[OpenXRInterface.HAND_JOINT_MIDDLE_TIP].origin
			var vecindex = (indextip - thumbtip)
			if not vmlocked:
				var midtip = (thumbtip + indextip + middletip)/3.0
				var vecmiddle = (middletip - thumbtip)
				var bx = vecindex.normalized()
				if leftie:
					var bz = -vecindex.cross(vecmiddle).normalized()
					var by = bz.cross(bx)
					vm.transform = Transform3D(Basis(bx, -by, bz)*(-0.2), midtip)
				else:
					var bz = vecindex.cross(vecmiddle).normalized()
					var by = bz.cross(bx)
					vm.transform = Transform3D(Basis(bx, -by, -bz)*(0.2), midtip)
					
			elif vecindex.length() < 0.05:
				elasticwire.endminuspos = (indextip + thumbtip)*0.5

	else:
		var pose = autohandsecondary.xr_controllertracker.get_pose("aim") if autohandsecondary.xr_controllertracker != null else null
		var vmtransform = xro.transform*pose.transform if pose != null else autohandsecondary.xr_controller_node.global_transform
		vmtransform.origin += vmtransform.basis.z*0.1
		vmtransform.basis = vmtransform.basis.rotated(Vector3(1,0,0), deg_to_rad(-45))
		vmtransform.basis = vmtransform.basis.scaled(Vector3(0.25,0.25,0.25))
		if not vmlocked:
			vm.transform = vmtransform
		else:
			elasticwire.endminuspos = vmtransform.origin
		
	if autohanddominant and autohanddominant.handtrackingactive and autohanddominant.handtrackingsource != autohanddominant.HAND_TRACKED_SOURCE_CONTROLLER:
		var indextip = xro.transform*autohanddominant.oxrktransRaw[OpenXRInterface.HAND_JOINT_INDEX_TIP].origin
		var thumbtip = xro.transform*autohanddominant.oxrktransRaw[OpenXRInterface.HAND_JOINT_THUMB_TIP].origin
		var backpos = xro.transform*autohanddominant.oxrktransRaw[OpenXRInterface.HAND_JOINT_LITTLE_PROXIMAL].origin
		var vecwristtip = (indextip - backpos).normalized()
		var rahbasis = (autohanddominant.handnode.transform).basis
		var xrt = xro.global_transform
		poke.transform = xrt*autohanddominant.oxrktransRaw[OpenXRInterface.HAND_JOINT_INDEX_TIP]
		if not elasticwire.visible:
			#bm.handheldtransform = Transform3D(rahbasis, indextip)
			bm.handheldtransform = poke.transform
			if mqttpublish:
				$MQTT.publish("handtrans", var_to_str(bm.handheldtransform))
			
		else:
			var vecindex = indextip - thumbtip
			if vecindex.length() < 0.05:
				elasticwire.endpluspos = (indextip + thumbtip)*0.5
				elasticwire.endplusbasis = rahbasis
				
	else:
		var pose = autohanddominant.xr_controllertracker.get_pose("aim") if autohanddominant.xr_controllertracker != null else null
		var bmtransform = xro.transform*pose.transform if pose != null else autohanddominant.xr_controller_node.global_transform
		bmtransform.origin += bmtransform.basis.z*(-0.2)
		poke.transform.origin = bmtransform.origin + bmtransform.basis.z*(0.05)
		if not elasticwire.visible:
			bm.handheldtransform = bmtransform
			if mqttpublish:
				$MQTT.publish("handtrans", var_to_str(bm.handheldtransform))
		else:
			elasticwire.endpluspos = bmtransform.origin
			elasticwire.endplusbasis = bmtransform.basis
			

func letterbutton(t, pressed):
	var ba = bm.get_node("BrushAngle")
	if t == "G":
		if not elasticwire.visible:
			ba.rotation_degrees.x += 5
		else:
			elasticwire.get_nodeleftie("Rod/Marker").position.z -= 0.05
	if t == "H":
		if not elasticwire.visible:
			ba.rotation_degrees.x -= 5
		else:
			elasticwire.get_node("Rod/Marker").position.z += 0.05
	if t == "C":
		ba.rotation_degrees.y += 5
	if t == "D":
		ba.rotation_degrees.y -= 5
		print("ba.rotation_degrees ", ba.rotation_degrees)
	if t == "L":
		vmlocked = pressed
	if t == "I":
		ba.get_node("BrushActual").transform.origin.z -= 0.01
	if t == "O":
		ba.get_node("BrushActual").transform.origin.z += 0.01
	if t == "P":
		bm.colorcycle()
	if t == "E":
		elasticwire.visible = pressed
	if t == "R":
		leftie = not pressed

	if t == "Z":
		get_node("/root/Main/SubViewport").render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
		get_node("/root/Main/SubViewport/Background").visible = true
		get_node("/root/Main/SubViewport").render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		get_node("/root/Main/SubViewport/Background").visible = false
		


const modalletters = [ "L", "E", "R" ]
func _on_poke_area_entered(area):
	print("_on_poke_area_entered ", area)
	var lab = area.get_node_or_null("Label3D")
	if lab != null:
		print(lab.text, "  PRESSED")
		lab.modulate = Color.RED if lab.modulate == Color.WHITE else Color.WHITE
		letterbutton(lab.text, lab.modulate == Color.RED)

func _on_poke_area_exited(area):
	var lab = area.get_node_or_null("Label3D")
	if lab != null and not(lab.text in modalletters):
		lab.modulate = Color.WHITE


func _on_mqtt_broker_connected():
	print("broker connected")
	$MQTT.publish("handtrans", "connected")
	mqttpublish = true

func _on_mqtt_broker_connection_failed():
	print("broker failed")
