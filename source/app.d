void main()
{
	import std.experimental.rational;
	auto start = rational(-2, 3);
	auto end = rational(2, 3);

	import core.time : MonoTime;
	auto prev = MonoTime.currTime.ticks;
	auto tps = MonoTime.ticksPerSecond;
	auto d = rational(2);
	auto fps = 60UL;
	auto targetDelta = tps / fps;
	long lag; // in ticks

	auto progress = Rational!(ulong, false)(0, tps);
	while (true)
	{
		auto curr = MonoTime.currTime.ticks;
		auto delta = curr - prev;
		lag += delta;

		while (lag > targetDelta)
		{
			import core.thread : Thread;
			import std.datetime : dur;
			Thread.sleep(dur!"msecs"(10));
			lag -= targetDelta;
			import std.algorithm : clamp;
			progress.num += targetDelta;
			if (progress < 1)
			{
				import std.experimental.easing : linear;
				auto terpd = linear(start, end, progress);
				import std.stdio : writeln;
				writeln(terpd.forcePrecision(90));
			}
			else if (progress > 1)
			{
				progress.num = progress.denom;
			}
		}

		prev = curr;
	}
}
