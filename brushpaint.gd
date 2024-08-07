extends Node2D

var colorcycle = [ Color.RED, Color.CYAN, Color.DARK_BLUE, Color.WHITE_SMOKE, Color.LAWN_GREEN ]
var icolor = 0

var width = 0.0
var color = Color.RED
var p0 = Vector2()
var p1 = Vector2()
var sz = Vector2()

func _ready():
	sz = Vector2(get_parent().size.x, -get_parent().size.y)

var bcornertouch = false
func brushpos(bp0, bp1):
	if bp0.z < 0 and bp1.z > 0:
		var lam = inverse_lerp(bp0.z, bp1.z, 0.0)
		var bpm = lerp(Vector2(bp0.x, bp0.y), Vector2(bp1.x, bp1.y), lam)
		
		var lbcornertouch = bpm.x < -0.45 and bpm.y < -0.45
		if lbcornertouch and not bcornertouch:
			icolor = (icolor + 1) % len(colorcycle)
			color = colorcycle[icolor]
		bcornertouch = lbcornertouch
		
		#prints(lam)
		p0 = Vector2(bp0.x, bp0.y)*sz
		p1 = Vector2(bpm.x, bpm.y)*sz
		width = (Vector2(bp1.x, bp1.y) - Vector2(bp0.x, bp0.y)).length()*sz.x*0.025
		queue_redraw()
		get_parent().render_target_update_mode = SubViewport.UPDATE_ONCE

func _draw():
	draw_line(p0, p1, color, width, true)
