extends Node3D


@onready var paintplane = get_node("/root/Main/ViewportMesh")
@onready var viewportbrush = get_node("/root/Main/SubViewport/BrushPaint")


func _process(delta):
	var brushtip = $BrushActual.global_transform.origin
	var brushtail = $BrushActual.global_transform.origin + $BrushActual.global_transform.basis.z*0.1
	var planeinv = paintplane.global_transform.affine_inverse()
	viewportbrush.brushpos(planeinv*brushtip, planeinv*brushtail)
