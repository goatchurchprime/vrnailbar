extends Node3D

class ABfilter:
	var b
	var a
	var xybuff = null
	var xybuffpos = 0
	static func instantiate(lb, la):
		var x = new()
		x.b = lb
		x.a = la
		assert (len(x.b) == len(x.a))
		return x

	func addfiltvalue(x):
		var n = len(b)
		if xybuff == null:
			xybuff = [ ]
			for i in range(n*2):
				xybuff.push_back(x)
		xybuff[xybuffpos] = x 
		var j = xybuffpos 
		var y = 0 
		for i in range(n):
			y += xybuff[j]*b[i] 
			if i != 0:
				y -= xybuff[j+n]*a[i] 
			j = j-1 if j!=0 else n-1
		if a[0] != 1:
			y /= a[0]
		xybuff[xybuffpos+n] = y 
		xybuffpos = xybuffpos+1 if xybuffpos!=n-1 else 0
		var Dj = (n-1 if (xybuffpos == 0) else xybuffpos-1)
		assert (xybuff[Dj+n] == y)
		return y

# scipy.signal.butter(3, 0.01, 'low')
var BFb = [ 3.75683802e-06, 1.12705141e-05, 1.12705141e-05, 3.75683802e-06]
var BFa = [ 1., -2.93717073,  2.87629972, -0.93909894]

# scipy.signal.butter(3, 0.1, 'low')
#var BFb = [0.00289819, 0.00869458, 0.00869458, 0.00289819]
#var BFa = [ 1.        , -2.37409474,  1.92935567, -0.53207537]

# scipy.signal.butter(3, 0.02, 'low')
var BFqb = [2.91464945e-05, 8.74394834e-05, 8.74394834e-05, 2.91464945e-05]
var BFqa = [ 1.        , -2.87435689,  2.7564832 , -0.88189313]


var BFtx = ABfilter.instantiate(BFb, BFa)
var BFty = ABfilter.instantiate(BFb, BFa)
var BFtz = ABfilter.instantiate(BFb, BFa)
var iifilterpos = null
var iifilterval = 0.0 # 0.03
func BFfiltVec(v):
	if iifilterval != 0:
		if iifilterpos == null:
			iifilterpos = v
		iifilterpos = lerp(iifilterpos, v, iifilterval)
		return iifilterpos
	return Vector3(BFtx.addfiltvalue(v.x), BFty.addfiltvalue(v.y), BFtz.addfiltvalue(v.z))

var BFqx = ABfilter.instantiate(BFqb, BFqa)
var BFqy = ABfilter.instantiate(BFqb, BFqa)
var BFqz = ABfilter.instantiate(BFqb, BFqa)
func BFfiltOrient(b):
	var q = b.get_rotation_quaternion()
	var fqv = Vector3(BFqx.addfiltvalue(q.x), BFqy.addfiltvalue(q.y), BFqz.addfiltvalue(q.z))
	var fw = sqrt(clamp(1.0 - fqv.length_squared(), 0.0, 1.0))
	return Basis(Quaternion(fqv.x, fqv.y, fqv.z, fw))

var fname = "res://stablehandtrans.txt"
var fin = null

var relvec = Vector3(0,0,0)
var relvecU = Vector3(0,0,0)

func _process(delta):
	if fin != null:
		var x = fin.get_line()
		if x:
			var t = str_to_var(x)
			var fb = BFfiltOrient(t.basis)
			$FilteredPos.transform = Transform3D(fb, BFfiltVec(t.origin) + relvec)
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
		
			
