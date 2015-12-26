module std.experimental.easing.functions;

import std.experimental.rational : isRational;
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
