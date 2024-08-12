extends Node3D


var endminuspos = Vector3()
var endpluspos = Vector3()
var endplusbasis = Basis()
@onready var brush = get_node("../Brush")

var brushfilter = 0.06

func _process(delta):
	if visible:
		var vecends = endpluspos - endminuspos
		var vecendsleng = vecends.length()
		if not is_zero_approx(vecendsleng):
			var bx = endplusbasis.y.cross(vecends).normalized()
			var by = vecends.cross(bx)/vecendsleng
			$Rod.transform = Transform3D(Basis(bx, by, vecends), (endpluspos + endminuspos)/2)
			var fpos = lerp(brush.transform.origin, $Rod/Marker.global_position, brushfilter)
			brush.transform = Transform3D(endplusbasis, fpos)
			
