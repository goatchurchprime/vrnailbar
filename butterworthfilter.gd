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
		var y = null 
		for i in range(n):
			var ym = xybuff[j]*b[i]
			y = ym if i == 0 else y + ym
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
var BF002 = [ [2.91464945e-05, 8.74394834e-05, 8.74394834e-05, 2.91464945e-05], [ 1.        , -2.87435689,  2.7564832 , -0.88189313] ]
var BF0025 = [ [5.60701149e-05, 1.68210345e-04, 1.68210345e-04, 5.60701149e-05], [ 1.        , -2.84296052,  2.69801053, -0.85460144] ]
var BF003 = [ [9.54425084e-05, 2.86327525e-04, 2.86327525e-04, 9.54425084e-05], [ 1.        , -2.81157368,  2.64048349, -0.82814628] ]
var BF01 = [ [0.00289819, 0.00869458, 0.00869458, 0.00289819], [ 1.        , -2.37409474,  1.92935567, -0.53207537] ]

var BFt = ABfilter.instantiate(BF0025[0], BF0025[1])
var iifilterpos = null
var iifilterval = 0.0 # l0.03
func BFfiltVec(v):
	if iifilterval != 0:
		if iifilterpos == null:
			iifilterpos = v
		iifilterpos = lerp(iifilterpos, v, iifilterval)
		return iifilterpos
	return BFt.addfiltvalue(v)


var BFb = ABfilter.instantiate(BF003[0], BF003[1])
var BFc = ABfilter.instantiate(BF003[0], BF003[1])
func BFfiltOrient(b):
	var bz = BFb.addfiltvalue(b.z)
	var by = BFc.addfiltvalue(b.y)
	var bx = by.cross(bz).normalized()
	return Basis(bx, bz.cross(bx), bz)

func BFfiltTrans(t):
	return Transform3D(BFfiltOrient(t.basis), BFfiltVec(t.origin))

func BFfiltTransSet(t):
	var v = t.origin
	BFt.firstval(v)
	var b = t.basis
	BFb.firstval(b.z)
	BFc.firstval(b.y)
