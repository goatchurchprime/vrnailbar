extends Node


@onready var xro = get_parent().get_parent()
@onready var htd = get_parent()
@onready var rt3 = get_node("/root/Main/XROrigin3D/XRController3DLeft/RemoteTransform3D")
@onready var vm = get_node("/root/Main/ViewportMesh")
@onready var bm = get_node("/root/Main/Brush")
@onready var poke = get_node("/root/Main/Poke")


var Nd = 1.0
var vmlocked = false
func _process(delta):
	if htd.autohandleft and htd.autohandleft.handtrackingactive:
		var wristringdistance = (htd.autohandleft.oxrktransRaw[OpenXRInterface.HAND_JOINT_RING_TIP].origin - htd.autohandleft.oxrktransRaw[OpenXRInterface.HAND_JOINT_WRIST].origin).length()
		if wristringdistance < 0.1 and not vmlocked:
			var thumbtip = xro.transform*htd.autohandleft.oxrktransRaw[OpenXRInterface.HAND_JOINT_THUMB_TIP].origin
			var indextip = xro.transform*htd.autohandleft.oxrktransRaw[OpenXRInterface.HAND_JOINT_INDEX_TIP].origin
			var middletip = xro.transform*htd.autohandleft.oxrktransRaw[OpenXRInterface.HAND_JOINT_MIDDLE_TIP].origin
			var vecindex = indextip - thumbtip
			var vecmiddle = middletip - thumbtip
			var bx = vecindex.normalized()
			var bz = vecindex.cross(vecmiddle).normalized()
			var by = bz.cross(bx)
			var midtip = (thumbtip + indextip + middletip)/3.0
			vm.transform = Transform3D(Basis(bx, -by, -bz)*(0.2), midtip)

	else:
		var pose = htd.autohandleft.xr_controllertracker.get_pose("aim") if htd.autohandleft.xr_controllertracker != null else null
		vm.transform = xro.transform*pose.transform if pose != null else htd.autohandleft.xr_controller_node.global_transform
		vm.transform.origin += vm.transform.basis.z*0.1
		vm.transform.basis = vm.transform.basis.rotated(Vector3(1,0,0), deg_to_rad(-45))
		vm.transform.basis = vm.transform.basis.scaled(Vector3(0.25,0.25,0.25))
	
	if htd.autohandright and htd.autohandright.handtrackingactive and htd.autohandright.handtrackingsource != htd.autohandright.HAND_TRACKED_SOURCE_CONTROLLER:
		var indextip = xro.transform*htd.autohandright.oxrktransRaw[OpenXRInterface.HAND_JOINT_INDEX_TIP].origin
		var backpos = xro.transform*htd.autohandright.oxrktransRaw[OpenXRInterface.HAND_JOINT_LITTLE_PROXIMAL].origin
		var vecwristtip = (indextip - backpos).normalized()
		bm.look_at_from_position(indextip + vecwristtip*0.1, indextip + vecwristtip*0.2)
		poke.transform.origin = indextip
		bm.transform = Transform3D((xro.transform*htd.autohandright.handnode.transform).basis, indextip)

	else:
		var pose = htd.autohandright.xr_controllertracker.get_pose("aim") if htd.autohandright.xr_controllertracker != null else null
		bm.transform = xro.transform*pose.transform if pose != null else htd.autohandright.xr_controller_node.global_transform
		bm.transform.origin += bm.transform.basis.z*(-0.2)
		poke.transform.origin = bm.transform.origin + bm.transform.basis.z*(0.05)

func letterbutton(t, pressed):
	var ba = bm.get_node("BrushAngle")
	if t == "G":
		ba.rotation_degrees.x += 5
	if t == "H":
		ba.rotation_degrees.x -= 5
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
		

const modalletters = [ "L" ]
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
