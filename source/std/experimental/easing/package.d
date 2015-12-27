module std.experimental.easing;

public import std.experimental.easing.functions;

import std.typetuple : allSatisfy;
import std.experimental.math.rational : isRational;
/++
`Start`, `End` and `Progress` must be instantiations of `std.experimental.rational : Rational`
++/
template easeIn(alias fn)
{
	auto easeIn(Start, End, Progress)(Start start, End end, Progress progress)
	    if (allSatisfy!(isRational, Start, End, Progress)
	        && __traits(compiles, "Progress p = fn(progress);"))
	{
		return start + (end - start) * fn(progress);
	}
}

template easeOut(alias fn)
{
	auto easeOut(Start, End, Progress)(Start start, End end, Progress progress)
	    if (allSatisfy!(isRational, Start, End, Progress)
	        && __traits(compiles, "Progress p = fn(1 - progress);"))
	{
		auto p = 1 - progress;
		return start + (end - start) * (1 - fn(p));
	}
}

template easeInOut(alias fn)
{
	auto easeInOut(Start, End, Progress)(Start start, End end, Progress progress)
	    if (allSatisfy!(isRational, Start, End, Progress)
	        && __traits(compiles, "Progress p = fn(1 - progress);"))
	{
		auto halfProgress = Progress(1, 2);
		auto half = (end - start) / 2;
		if (progress < halfProgress)
		{
			return easeIn!fn(start, start + half, progress * 2);
		}
		else
		{
			return easeOut!fn(start + half, end, (progress - halfProgress) * 2);
		}
	}
}
