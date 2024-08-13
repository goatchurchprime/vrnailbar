extends Node3D

var fname = "res://stablehandtrans.txt"
var fin = null

var relvec = Vector3(0,0,0)
var relvecU = Vector3(0,0,0)

@onready var bfilt = ButterworthFilter.new()
	
func _process(delta):
	if fin != null:
		var x = fin.get_line()
		if x:
			var t = str_to_var(x)
			var fb = bfilt.BFfiltOrient(t.basis)
			$FilteredPos.transform = Transform3D(fb, bfilt.BFfiltVec(t.origin) + relvec)
			$UnfilteredPos.transform = Transform3D(t.basis, t.origin + relvecU)
		else:
			fin.close()
			fin = null

func _input(event):
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_L:
		fin = FileAccess.open(fname, FileAccess.READ)
		var t = str_to_var(fin.get_line())
		var cam = get_node("/root/Main/XROrigin3D/XRCamera3D")
		relvec = cam.global_transform.origin - cam.global_transform.basis.z*0.2 - t.origin
		relvecU = relvec + cam.global_transform.basis.z*0.03
		
