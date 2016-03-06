module std.experimental.anim.easing;

public import std.experimental.anim.easing.functions;

/++
TODO: pass Delta, not Delta
++/

auto lerp(Start, Delta, Progress)(auto ref Start start, auto ref Delta delta, auto ref Progress progress)
{
	return start + delta * progress;
}

template ease(alias fn)
{
	auto ref ease(Start, Delta, Progress)(auto ref Start start, auto ref Delta delta, auto ref Progress progress)
	    if (__traits(compiles, "Progress p = fn(progress);"))
	{
		return start + delta * ease(progress);
	}
	auto ref ease(Progress)(auto ref Progress progress)
	{
		return fn(progress);
	}
}

alias easeIn(alias fn) = ease!fn;

alias easeOut(alias fn) = ease!(reverse!fn);

alias easeInOut(alias fn) = easeInOut!(fn, fn);
template easeInOut(alias fnIn, alias fnOut)
{
	auto ref easeInOut(Start, Delta, Progress)(auto ref Start start, auto ref Delta delta, auto ref Progress progress)
	    if (isProgress!Progress && __traits(compiles, "Progress p = fn(1 - progress);"))
	{
		auto halfProgress = getHalfProgress!Progress;
		auto half = delta / 2;
		if (progress < halfProgress)
		{
			return easeIn!fnIn(start, half, progress * 2);
		}
		else
		{
			return easeOut!fnOut(start + half, half, (progress - halfProgress) * 2);
		}
	}
}

auto ref easeCombined(alias fn, Progress)(auto ref Progress progress)
	if (isProgress!Progress)
{
	return easeCombined!(fn, fn)(progress);
}
auto ref easeCombined(alias fn1, alias fn2, Progress)(auto ref Progress progress)
	if (isProgress!Progress)
{
	return progress.reverse * easeIn!fn1(progress) + progress * easeOut!fn2(progress);
}

import std.traits : isFloatingPoint;
import std.experimental.math.rational : isRational;
enum bool isProgress(T) = isRational!T || isFloatingPoint!T;
auto getHalfProgress(Progress)()
    if (isProgress!Progress)
{
	static if (isFloatingPoint!Progress)
	{
		return Progress(0.5);
	}
	else static if (isRational!Progress)
	{
		return Progress(1, 2);
	}
}
