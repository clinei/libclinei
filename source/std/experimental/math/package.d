module std.experimental.math;

import std.experimental.math.rational : Rational;
/// PI as a fraction, accurate to 20 places
enum Rational!true PI = Rational!true(8958937768937, 2851718461558);
unittest
{
	import std.math : approxEqual;
	assert((cast(real)PI).approxEqual(3.141592653589793238));
}

Natural factorial(Natural)(Natural n)
{
	Natural ret = 1;
	bool sub;
	foreach (i; 1..n+1)
	{
		ret *= i;
	}
	return ret;
}
unittest
{
	assert(1.factorial == 1);
	assert(3.factorial == 6);
	assert(6.factorial == 720);
	assert(10.factorial == 3_628_800);
}
