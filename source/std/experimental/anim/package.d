module std.experimental.anim;

public import std.experimental.anim.easing;

struct Animation(Start, End, Progress)
{
	Start start;

	End end;

	Progress progress;
}
