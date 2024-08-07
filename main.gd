extends Node3D


var xr_interface : OpenXRInterface

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.initialize():
		var vp = get_viewport()
		vp.use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		print("OpenXR initialize failed")

	await RenderingServer.frame_post_draw
	$SubViewport/Background.visible = false

	var camerahvec = Vector3($XROrigin3D/XRCamera3D.transform.basis.z.x, 0.0, $XROrigin3D/XRCamera3D.transform.basis.z.z).normalized()
	var camerahbasis = Basis(-camerahvec.cross(Vector3(0,1,0)), Vector3(0,1,0), camerahvec)
	var camerahtrans = Transform3D(camerahbasis, $XROrigin3D/XRCamera3D.transform.origin)
	print($XROrigin3D/XRCamera3D.transform.basis)

	$XROrigin3D.transform = $SpawnCamera.transform * camerahtrans.inverse()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_I:
			$SubViewport/Polygon2D.position += Vector2(10, 5)
			$SubViewport/Line2D.position += Vector2(10, 5)
			$SubViewport/Node2D.position += Vector2(10, 5)
			$SubViewport/Node2D.rotation_degrees += -10
			$SubViewport/Node2D.width *= 0.9
			$SubViewport/Node2D.queue_redraw()
			$SubViewport/Polygon2D2.position += Vector2(-10, 9)
			$SubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		if event.keycode == KEY_S:
			$SubViewport.get_texture().get_image().save_png("user://test.png")
			print(OS.get_user_data_dir())
		if event.keycode == KEY_W:
			$SubViewport/Background.visible = true
			$SubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw
			$SubViewport/Background.visible = false
