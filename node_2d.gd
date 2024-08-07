extends Node2D


var width = 12.0
func _draw():
	draw_line(Vector2(0,0), Vector2(0,50), Color.RED, width, true)
