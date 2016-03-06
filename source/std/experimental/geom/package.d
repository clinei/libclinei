module std.experimental.geom;

Point bezier(size_t degree, Point, Progress)(Point[degree] points, Progress progress)
    if (degree >= 2)
{
	Point[degree - 1] newPoints;

	mixin(bezierCommon);
}

private immutable string bezierCommon = q{
	foreach (i; 0..newPoints.length)
	{
		import std.experimental.anim.easing : lerp;
		auto curr = points[i];
		auto next = points[i + 1];
		auto delta = next - curr;
		newPoints[i] = lerp(curr, delta, progress);
	}

	if (newPoints.length >= 2)
	{
		return bezier(newPoints, progress);
	}
	else
	{
		return newPoints[0];
	}
};

/++
Bézier curve using a dynamic array
++/
Point bezier(Point, Progress)(Point[] points, Progress progress)
{
	Point[] newPoints;
	newPoints.length = points.length - 1;

	mixin(bezierCommon);
}
