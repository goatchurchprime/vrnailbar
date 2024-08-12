extends Node3D


@onready var paintplane = get_node("/root/Main/ViewportMesh")
@onready var viewportbrush = get_node("/root/Main/SubViewport/BrushPaint")

func colorcycle():
	viewportbrush.icolor = (viewportbrush.icolor + 1) % len(viewportbrush.colorcycle)
	viewportbrush.color = viewportbrush.colorcycle[viewportbrush.icolor]
	$BrushAngle/BrushActual/MeshInstance3D.get_surface_override_material(0).albedo_color = viewportbrush.color

func _process(delta):
	var brushtip = $BrushAngle/BrushActual.global_transform.origin
	var brushtail = $BrushAngle/BrushActual.global_transform.origin + $BrushAngle/BrushActual.global_transform.basis.z*0.1
	var planeinv = paintplane.global_transform.affine_inverse()
	var ppsca = paintplane.transform.basis.get_scale()
	
	var bp0 = planeinv*brushtip
	var bp1 = planeinv*brushtail
	if bp0.z < 0 and bp1.z > 0:
		var lam = inverse_lerp(bp0.z, bp1.z, 0.0)
		var bpm = lerp(Vector2(bp0.x, bp0.y), Vector2(bp1.x, bp1.y), lam)
		var bby = -Vector3(bp0.x - bpm.x, bp0.y - bpm.y, 0.0)
		var bbb = Basis(-Vector3(bby.y, -bby.x, 0.0).normalized(), bby, Vector3(0,0,1))
		var bbm = Vector3((bp0.x + bpm.x)*0.5, (bp0.y + bpm.y)*0.5, 0.0)
		paintplane.get_node("brushtip").transform = Transform3D(bbb, bbm)
		paintplane.get_node("brushtip").visible = true
	else:
		paintplane.get_node("brushtip").visible = false
	
	viewportbrush.brushpos(bp0, bp1)
