class_name ButterworthFilter
extends Object

class ABfilter:
	var b
	var a
	var n
	var xybuff = [ ]
	var xybuffpos = 0
	static func instantiate(lb, la):
		var x = new()
		x.b = lb
		x.a = la
		x.n = len(x.b)
		assert (len(x.b) == len(x.a))
		return x

	func firstval(x):
		for i in range(n*2):
			if len(xybuff) <= i:
				xybuff.push_back(0)
			xybuff[i] = x
		xybuffpos = 0
		
	func addfiltvalue(x):
		if not xybuff:
			firstval(x)
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
#var BFb = [ 3.75683802e-06, 1.12705141e-05, 1.12705141e-05, 3.75683802e-06]
#var BFa = [ 1., -2.93717073,  2.87629972, -0.93909894]
# scipy.signal.butter(3, 0.02, 'low')
var BFb = [2.91464945e-05, 8.74394834e-05, 8.74394834e-05, 2.91464945e-05]
var BFa = [ 1.        , -2.87435689,  2.7564832 , -0.88189313]

# scipy.signal.butter(3, 0.1, 'low')
#var BFb = [0.00289819, 0.00869458, 0.00869458, 0.00289819]
#var BFa = [ 1.        , -2.37409474,  1.92935567, -0.53207537]

# scipy.signal.butter(3, 0.02, 'low')
var BFqb = [2.91464945e-05, 8.74394834e-05, 8.74394834e-05, 2.91464945e-05]
var BFqa = [ 1.        , -2.87435689,  2.7564832 , -0.88189313]

# scipy.signal.butter(3, 0.03, 'low')
var BFrb = [9.54425084e-05, 2.86327525e-04, 2.86327525e-04, 9.54425084e-05]
var BFra = [ 1.        , -2.81157368,  2.64048349, -0.82814628]


var BFtx = ABfilter.instantiate(BFb, BFa)
var BFty = ABfilter.instantiate(BFb, BFa)
var BFtz = ABfilter.instantiate(BFb, BFa)
var iifilterpos = null
var iifilterval = 0.0 # l0.03
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
func BFfiltOrientQ(b):
	var q = b.get_rotation_quaternion()
	if q.w < 0.0:
		q = -q
	var fqv = Vector3(BFqx.addfiltvalue(q.x), BFqy.addfiltvalue(q.y), BFqz.addfiltvalue(q.z))
	var fw = sqrt(clamp(1.0 - fqv.length_squared(), 0.0, 1.0))
	return Basis(Quaternion(fqv.x, fqv.y, fqv.z, fw))


var BFbx = ABfilter.instantiate(BFrb, BFra)
var BFby = ABfilter.instantiate(BFrb, BFra)
var BFbz = ABfilter.instantiate(BFrb, BFra)
var BFcx = ABfilter.instantiate(BFrb, BFra)
var BFcy = ABfilter.instantiate(BFrb, BFra)
var BFcz = ABfilter.instantiate(BFrb, BFra)
func BFfiltOrient(b):
	var bz = Vector3(BFbx.addfiltvalue(b.z.x), BFby.addfiltvalue(b.z.y), BFbz.addfiltvalue(b.z.z)).normalized()
	var by = Vector3(BFcx.addfiltvalue(b.y.x), BFcy.addfiltvalue(b.y.y), BFcz.addfiltvalue(b.y.z))
	var bx = by.cross(bz).normalized()
	return Basis(bx, bz.cross(bx), bz)

func BFfiltTrans(t):
	return Transform3D(BFfiltOrient(t.basis), BFfiltVec(t.origin))

func BFfiltTransSet(t):
	var v = t.origin
	BFtx.firstval(v.x)
	BFty.firstval(v.y)
	BFtz.firstval(v.z)

	var q = t.basis.get_rotation_quaternion()
	BFqx.firstval(q.x)
	BFqy.firstval(q.y)
	BFqz.firstval(q.z)
	
	var b = t.basis
	BFbx.firstval(b.z.x)
	BFby.firstval(b.z.y)
	BFbz.firstval(b.z.z)
	BFcx.firstval(b.y.x)
	BFcy.firstval(b.y.y)
	BFcz.firstval(b.y.z)
