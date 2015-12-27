module std.experimental.easing.functions;

// TODO: require a RationalDepth of 1
import std.experimental.math.rational : isRational;
Progress linear(Progress)(ref Progress progress)
    if (isRational!Progress)
{
	return progress;
}

template power(ulong magnitude)
{
	Progress power(Progress)(ref Progress progress)
		if (isRational!Progress)
	{
		return progress ^^ magnitude;
	}
}

Progress circular(Progress)(ref Progress progress)
{
	import std.math : sqrt;
	auto p = Progress(1 - sqrt(cast(real)(1 - progress ^^ 2)));
	return p;
}
