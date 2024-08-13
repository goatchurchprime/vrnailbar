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
func BFfiltOrient(b):
	var q = b.get_rotation_quaternion()
	var fqv = Vector3(BFqx.addfiltvalue(q.x), BFqy.addfiltvalue(q.y), BFqz.addfiltvalue(q.z))
	var fw = sqrt(clamp(1.0 - fqv.length_squared(), 0.0, 1.0))
	return Basis(Quaternion(fqv.x, fqv.y, fqv.z, fw))
