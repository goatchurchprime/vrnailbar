extends Node


@onready var xro = get_parent().get_parent()
@onready var htd = get_parent()
@onready var rt3 = get_node("/root/Main/XROrigin3D/XRController3DLeft/RemoteTransform3D")
@onready var vm = get_node("/root/Main/ViewportMesh")
@onready var bm = get_node("/root/Main/Brush")
@onready var poke = get_node("/root/Main/Poke")
@onready var elasticwire = get_node("/root/Main/ElasticWire")
var brushfilter = 0.12

var Nd = 1.0
var vmlocked = false
func _process(delta):
	if htd.autohandleft and htd.autohandleft.handtrackingactive:
		var wristringdistance = (htd.autohandleft.oxrktransRaw[OpenXRInterface.HAND_JOINT_RING_TIP].origin - htd.autohandleft.oxrktransRaw[OpenXRInterface.HAND_JOINT_WRIST].origin).length()
		if wristringdistance < 0.1:
			var thumbtip = xro.transform*htd.autohandleft.oxrktransRaw[OpenXRInterface.HAND_JOINT_THUMB_TIP].origin
			var indextip = xro.transform*htd.autohandleft.oxrktransRaw[OpenXRInterface.HAND_JOINT_INDEX_TIP].origin
			var middletip = xro.transform*htd.autohandleft.oxrktransRaw[OpenXRInterface.HAND_JOINT_MIDDLE_TIP].origin
			var vecindex = indextip - thumbtip
			if not vmlocked:
				var vecmiddle = middletip - thumbtip
				var bx = vecindex.normalized()
				var bz = vecindex.cross(vecmiddle).normalized()
				var by = bz.cross(bx)
				var midtip = (thumbtip + indextip + middletip)/3.0
				vm.transform = Transform3D(Basis(bx, -by, -bz)*(0.2), midtip)
			elif vecindex.length() < 0.05:
				elasticwire.endminuspos = (indextip + thumbtip)*0.5

	else:
		var pose = htd.autohandleft.xr_controllertracker.get_pose("aim") if htd.autohandleft.xr_controllertracker != null else null
		var vmtransform = xro.transform*pose.transform if pose != null else htd.autohandleft.xr_controller_node.global_transform
		vmtransform.origin += vmtransform.basis.z*0.1
		vmtransform.basis = vmtransform.basis.rotated(Vector3(1,0,0), deg_to_rad(-45))
		vmtransform.basis = vmtransform.basis.scaled(Vector3(0.25,0.25,0.25))
		if not vmlocked:
			vm.transform = vmtransform
		else:
			elasticwire.endminuspos = vmtransform.origin
		
	if htd.autohandright and htd.autohandright.handtrackingactive and htd.autohandright.handtrackingsource != htd.autohandright.HAND_TRACKED_SOURCE_CONTROLLER:
		var indextip = xro.transform*htd.autohandright.oxrktransRaw[OpenXRInterface.HAND_JOINT_INDEX_TIP].origin
		var thumbtip = xro.transform*htd.autohandright.oxrktransRaw[OpenXRInterface.HAND_JOINT_THUMB_TIP].origin
		var backpos = xro.transform*htd.autohandright.oxrktransRaw[OpenXRInterface.HAND_JOINT_LITTLE_PROXIMAL].origin
		var vecwristtip = (indextip - backpos).normalized()
		poke.transform.origin = indextip
		var rahbasis = (xro.transform*htd.autohandright.handnode.transform).basis
		if not elasticwire.visible:
			bm.transform = Transform3D(rahbasis, lerp(bm.transform.origin, indextip, brushfilter))
		else:
			var vecindex = indextip - thumbtip
			if vecindex.length() < 0.05:
				elasticwire.endpluspos = (indextip + thumbtip)*0.5
				elasticwire.endplusbasis = rahbasis
				
	else:
		var pose = htd.autohandright.xr_controllertracker.get_pose("aim") if htd.autohandright.xr_controllertracker != null else null
		var bmtransform = xro.transform*pose.transform if pose != null else htd.autohandright.xr_controller_node.global_transform
		bmtransform.origin += bmtransform.basis.z*(-0.2)
		poke.transform.origin = bmtransform.origin + bmtransform.basis.z*(0.05)
		if not elasticwire.visible:
			bm.transform = bmtransform
		else:
			elasticwire.endpluspos = bmtransform.origin
			elasticwire.endplusbasis = bmtransform.basis
			

func letterbutton(t, pressed):
	var ba = bm.get_node("BrushAngle")
	if t == "G":
		if not elasticwire.visible:
			ba.rotation_degrees.x += 5
		else:
			elasticwire.get_node("Rod/Marker").position.z -= 0.05
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
	if t == "Z":
		get_node("/root/Main/SubViewport").render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
		get_node("/root/Main/SubViewport/Background").visible = true
		get_node("/root/Main/SubViewport").render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		get_node("/root/Main/SubViewport/Background").visible = false
		


const modalletters = [ "L", "E" ]
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
