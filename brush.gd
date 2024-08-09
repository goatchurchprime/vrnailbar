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
	viewportbrush.brushpos(planeinv*brushtip, planeinv*brushtail)
