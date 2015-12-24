module std.experimental.easing;

/++
`Start`, `End` and `Progress` must be instantiations of `std.experimental.rational : Rational`
++/
import std.experimental.rational : Rational;
auto linear(Start, End, Progress)(Start start, ref End end, ref Progress progress)
	if (is(Start == Rational!TS, TS) && is(End == Rational!TE, TE) && is(Progress == Rational!TP, TP))
{
	return start + (end - start) * progress;
}
