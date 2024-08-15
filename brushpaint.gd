extends Node2D

var colorcycle = [ Color.RED, Color.CYAN, Color.DARK_BLUE, Color.WHITE_SMOKE, Color.LAWN_GREEN ]
var icolor = 0

@onready var sz = Vector2(get_parent().size.x, -get_parent().size.y)

var color = Color.RED
var p0 = Vector2()
var pm = Vector2()
var pv = Vector2()

func brushpos(lp0, lpm, lpv):
	p0 = Vector2(lp0.x, lp0.y)
	pm = Vector2(lpm.x, lpm.y)
	pv = lpv
	queue_redraw()
	get_parent().render_target_update_mode = SubViewport.UPDATE_ONCE

func _draw():
	draw_line(p0*sz, pm*sz, color, pv.length()*sz.x*0.025, true)
