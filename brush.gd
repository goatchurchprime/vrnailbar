extends Node3D


@onready var paintplane = get_node("/root/Main/ViewportMesh")
@onready var viewportbrush = get_node("/root/Main/SubViewport/BrushPaint")

@onready var brushtip = get_node("/root/Main/ViewportMesh/brushtip")
@onready var brushlag = get_node("/root/Main/ViewportMesh/brushlag")

var bendybrush = true
var bendybrushlocallength = 0.1
var handheldtransform = null

func colorcycle():
	viewportbrush.icolor = (viewportbrush.icolor + 1) % len(viewportbrush.colorcycle)
	viewportbrush.color = viewportbrush.colorcycle[viewportbrush.icolor]
	$BrushAngle/BrushActual/MeshInstance3D.get_surface_override_material(0).albedo_color = viewportbrush.color

@onready var bfilt = ButterworthFilter.new()

var surfacecontact = false
# brushtip visible means surface contact

var nextfirstpos = false
var alwaysfilter = true
func _process(delta):
	if handheldtransform != null:
		if alwaysfilter:
			#bfilt.BFfiltTransSet(handheldtransform)
			transform = bfilt.BFfiltTrans(handheldtransform)
			#transform = handheldtransform

		elif brushlag.visible:
			transform = handheldtransform 
		else:
			if nextfirstpos:
				bfilt.BFfiltTransSet(handheldtransform)
				transform = bfilt.BFfiltTrans(handheldtransform)
				nextfirstpos = false
			else:
				transform = bfilt.BFfiltTrans(handheldtransform)
		handheldtransform = null


	var brushnose = $BrushAngle/BrushActual.global_transform.origin
	var brushtail = $BrushAngle/BrushActual.global_transform.origin + $BrushAngle/BrushActual.global_transform.basis.z*0.1
	var planeinv = paintplane.global_transform.affine_inverse()
	var bp0 = planeinv*brushnose
	var bp1 = planeinv*brushtail

	if bendybrush:
		bendybrushimplementation(bp0, bp1)
	else:
		pokeybrushimplementation(bp0, bp1)
		
func bendybrushimplementation(bp0, bp1):
	#pokeybrushimplementation(bp0, bp1)
	var bpB = paintplane.global_transform.affine_inverse().basis*$BrushAngle/BrushActual.global_transform.basis
	var bpZN = bpB.z.normalized()
	var bpbt = bp0 - bpZN*bendybrushlocallength
	if bpbt.z < 0 and bp0.z > 0:
		var hdist = sqrt(max(0.0, bendybrushlocallength*bendybrushlocallength - bp0.z*bp0.z))
		var bpBA = Vector3(bpZN.x, bpZN.y, 0.0).normalized()
		var bpcontact = Vector3(bp0.x, bp0.y, 0.0) - bpBA*hdist
		var bpBZ = bp0 - bpcontact 
		var bpBX = Vector3(bpBA.y, -bpBA.x, 0.0)
		assert (is_zero_approx(bpBX.dot(bpBZ)))
		assert (is_equal_approx(bpBZ.length(), bendybrushlocallength))
		var bpBY = (bpBZ/bendybrushlocallength).cross(bpBX)
		brushtip.transform = Transform3D(Basis(bpBY, bpBZ, bpBX), (bp0 + bpcontact)*0.5)
		var spotdiam = 	0.005
		viewportbrush.brushpos(bpcontact - bpBA*spotdiam, bpcontact + bpBA*spotdiam, Vector2(spotdiam*20,0))

	else:
		brushtip.transform = Transform3D(Basis(bpB.y.normalized(), bpZN*bendybrushlocallength, bpB.x.normalized()), bp0 - bpZN*(bendybrushlocallength*0.5))

func pokeybrushimplementation(bp0, bp1):
	if bp0.z < 0 and bp1.z > 0:
		var lam = inverse_lerp(bp0.z, bp1.z, 0.0)
		var lp0 = Vector2(bp0.x, bp0.y)
		var lp1 = Vector2(bp1.x, bp1.y)
		var bpm = lerp(lp0, lp1, lam)
		var bby = -Vector3(lp0.x - bpm.x, lp0.y - bpm.y, 0.0)
		var bbb = Basis(-Vector3(bby.y, -bby.x, 0.0).normalized(), bby, Vector3(0,0,1))
		var bbm = Vector3((lp0.x + bpm.x)*0.5, (lp0.y + bpm.y)*0.5, 0.0)
		brushtip.transform = Transform3D(bbb, bbm)
		brushtip.visible = true
		
		if not brushlag.visible:
			brushlag.transform = brushtip.transform
			brushlag.visible = true
		else:
			const alignmotiononly = true
			if alignmotiononly:
				var vl = brushtip.transform.basis.y
				# solve 0 = vl.dot(brushlag.transform.origin + vl*vlam - brushtip.transform.origin)
				var vlam = -vl.dot(brushlag.transform.origin - brushtip.transform.origin)/vl.dot(vl)
				brushlag.transform = Transform3D(brushtip.transform.basis, brushlag.transform.origin + vl*vlam)
			else:
				var ry = max(0.01, brushlag.transform.basis.y.length()*1.5)
				var vl = brushtip.transform.origin - brushlag.transform.origin
				var vllen = vl.length()
				var vlam = (vllen - ry)/vllen if vllen > ry else 0
				brushlag.transform = Transform3D(brushtip.transform.basis, brushlag.transform.origin + vl*vlam)
					
		#brushtip.transform.basis.y = bpm - lp0
		#brushtip.transform.origin*2 = bpm + lp0
		viewportbrush.brushpos(brushlag.transform.origin - brushlag.transform.basis.y*0.5, brushlag.transform.origin + brushlag.transform.basis.y*0.5, lp0 - lp1)
	else:
		brushtip.visible = false
		if bp0.z > 0.02:
			if brushlag.visible:
				brushlag.visible = false
				nextfirstpos = true
	
	
