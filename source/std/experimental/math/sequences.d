module std.experimental.math.sequences;

//TODO: implement a relative version of this
struct GeometricSequence(First, Ratio, Index = ulong)
{
	First first;

	Ratio ratio;

	Index index;

	this(First first, Ratio ratio, Index index = 0)
	{
		this.first = first;
		this.ratio = ratio;
		this.index = index;
	}

	@property
	{
		enum bool empty = false;

		auto front()
		{
			return first * (ratio ^^ index);
		}
	}

	void popFront()
	{
		index++;
	}
}
auto geometric(First, Ratio, Index = ulong)(First first, Ratio ratio, Index index = 0)
{
	return GeometricSequence!(First, Ratio, Index)(first, ratio, index);
}
unittest
{
	import std.range : take;
	import std.algorithm : equal;
	assert(geometric(3, 2).take(3).equal([3, 6, 12]));
	assert(geometric(4, 3).take(3).equal([4, 12, 36]));
}