module std.experimental.anim.easing.functions;

// Progress must be between 0 and 1
auto ref Progress linear(Progress)(auto ref Progress progress)
{
	return progress;
}

auto ref Progress reverse(Progress)(auto ref Progress progress)
{
	return 1 - progress;
}
template reverse(alias fn)
{
	auto ref Progress reverse(Progress)(auto ref Progress progress)
	{
		return 1 - fn(1 - progress);
	}
}

template power(ulong magnitude)
{
	auto ref Progress power(Progress)(auto ref Progress progress)
	{
		return progress ^^ magnitude;
	}
}

auto ref Progress circular(Progress)(auto ref Progress progress)
{
	import std.math : sqrt;
	import std.traits : isFloatingPoint;
	static if (isFloatingPoint!Progress)
	{
		return 1 - sqrt(1 - progress ^^ 2);
	}
	else
	{
		return 1 - Progress(sqrt(cast(real)(1 - progress ^^ 2)));
	}
}

import std.functional : partial;
alias elasticLite = partial!(partial!(elastic, 1.0f), 3.0f);

auto ref Progress elastic(Amplitude, Periods, Progress)(auto ref Amplitude amplitude, auto ref Periods periods, auto ref Progress progress)
{
	real weight = power!9(cast(real)progress);
	import std.math : PI;
	import std.math : sin;
	real s = sin(2 * PI * periods * cast(real)progress - PI) * amplitude;
	auto ret = s * weight;
	import std.stdio : writeln;
	writeln(ret);
	return ret;
}
