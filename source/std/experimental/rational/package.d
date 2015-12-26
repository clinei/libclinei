module std.experimental.rational;

auto greatestCommonDivisor(A, B)(A a, B b)
{
	if (b == 0)
	{
		return a;
	}
	else
	{
		return (greatestCommonDivisor(b, a % b));
	}
}

auto leastCommonMultiple(A, B)(A a, B b)
{
	auto gcd = greatestCommonDivisor(a, b);
	return (a / gcd) * b;
}

template isRational(T)
{
	import std.traits : Unqual;
	static if (is(Unqual!T == Rational!(Type, autoReduce), Type, bool autoReduce))
	{
		enum bool isRational = true;
	}
	else
	{
		enum bool isRational = false;
	}
}

template RationalType(T)
{
	import std.traits : Unqual;
	static if (is(Unqual!T == Rational!(Type, autoReduce), Type, bool autoReduce))
	{
		alias RationalType = Type;
	}
	else
	{
		alias RationalType = void;
	}
}

import std.typetuple : templateOr;
import std.traits : isFloatingPoint, isIntegral;
alias isValidCastType = templateOr!(isFloatingPoint, isIntegral);

template Rational(Type, bool autoReduce = true)
{
	import std.traits : isFloatingPoint;
	static if (isFloatingPoint!Type)
	{
		static assert(false, "Use either floating point or Rational, not both.");
	}

	import std.traits : isSigned;
	static if (isSigned!Type)
	{
		static assert(false, "Only unsigned types are supported");
	}

	struct Rational
	{
		/// Numerator
		Type num;

		/// Denominator
		Type denom;

		/// If is negative (sign bit)
		bool neg;

		/++
		Construct from numerator
		++/
		import std.traits : isImplicitlyConvertible;
		this(Num)(Num num) if (isImplicitlyConvertible!(Num, Type))
		{
			opAssign(num);
		}

		/++
		Construct from numerator, denominator and sign bit
		++/
		import std.traits : isSigned, isIntegral;
		import std.typetuple : anySatisfy;
		this(Num, Denom)(Num num, Denom denom, bool neg = false)
			if ( (isIntegral!Type && !anySatisfy!(isSigned, Num, Denom))
				|| isImplicitlyConvertible!(Num, Type) && isImplicitlyConvertible!(Denom, Type))
		{
			this.num = num;
			this.denom = denom;
			this.neg = neg;

			static if (autoReduce)
				this.reduce();
		}
		this(Num, Denom)(Num num, Denom denom) if (anySatisfy!(isSigned, Num, Denom))
		{
			// Safely convert signed to unsigned
			import std.traits : isSigned;
			static if (isSigned!Num)
			{
				import std.traits : Unsigned;
				Unsigned!Num _num;
				if (num < 0)
				{
					neg = !neg;
					_num = -num;
				}
				else
				{
					_num = num;
				}
			}
			else
			{
				alias _num = num;
			}
			import std.traits : isSigned;
			static if (isSigned!Denom)
			{
				import std.traits : Unsigned;
				Unsigned!Denom _denom;
				if (denom < 0)
				{
					neg = !neg;
					_denom = -denom;
				}
				else
				{
					_denom = denom;
				}
			}
			else
			{
				alias _denom = denom;
			}

			this(_num, _denom, neg);
		}

		/++
		Construct from another Rational if the Types are compatible
		++/
		this(Other)(Other other)
		    if (is(Other == Rational!(_Type, _autoReduce), _Type, bool _autoReduce)
		        && isImplicitlyConvertible!(RationalType!Other, Type))
		{
			opAssign(other);
		}

		/++
		Returns: `this` with switched num and denom
		++/
		Rational inverse() const @property
		{
			return Rational(denom, num, neg);
		}

		/++
		Forces a specific precision, use only when rounding errors are insignificant or don't build up
		++/
		ref Rational forcePrecision(Denom = Type)(Denom denom)
		{
			num /= this.denom / denom;
			this.denom = denom;

			return this;
		}

		/++
		Same as `forcePrecision`, but doesn't change the original
		Bugs: Cannot infer type for template parameters from this
		++/
		Rational atPrecision(Denom = Type)(Denom denom)
		{
			Rational t = this;
			return t.forcePrecision(denom);
		}

		/++
		Reduces to the lowest possible terms
		++/
		ref Rational reduce()
		{
			Type gcd = greatestCommonDivisor(num, denom);

			num /= gcd;
			denom /= gcd;

			if (neg && num == 0)
			{
				neg = false;
			}

			return this;
		}

		import std.traits : isFloatingPoint;
		/++
		Cast to floating point
		Example:
		---
		auto r = Rational!ulong(1, 3);

		import std.conv : to;
		writeln(r.to!real); // prints 0.333333...
		---
		++/
		CastType opCast(CastType)() if (isValidCastType!CastType)
		{
			CastType ret = cast(CastType)num / cast(CastType)denom;

			if (neg)
				return -ret;
			else
				return ret;
		}

		/++
		Test equality with another Rational
		++/
		import std.traits : Unqual;
		bool opEquals(Other)(Other other) if (isRational!Other)
		{
			return num == other.num && denom == other.denom && neg == other.neg;
		}

		/++
		Test equality with non-rational integer
		++/
		import std.traits : isIntegral;
		bool opEquals(Other)(Other other) if (!isRational!Other && isIntegral!Other)
		{
			return this == Rational(other);
		}

		/++
		Compare with another Rational
		++/
		auto opCmp(Other)(Other other) if (isRational!Other)
		{
			auto lcm = leastCommonMultiple(denom, other.denom);
			auto tnum = (lcm / denom) * num;
			auto onum = (lcm / other.denom) * other.num;

			if (tnum > onum)
				return this.neg != other.neg ? -1 : 1;
			else if (tnum < onum)
				return this.neg != other.neg ? 1 : -1;
			else
				return 0;
		}

		/++
		Compare with a non-rational integer
		++/
		auto opCmp(Other)(Other other) if (!isRational!Other)
		{
			return opCmp(Rational(other));
		}

		/++
		Assign from a type compatible with Type
		+/
		ref Rational opAssign(Other)(Other other)
		    if (!isRational!Other && isImplicitlyConvertible!(Other, Type))
		{
			import std.traits : isSigned;
			static if (isSigned!Other)
			{
				neg = other < 0;
				if (neg)
				{
					other = -other;
				}
			}

			num = other;
			denom = 1;

			return this;
		}

		/++
		Assign from a compatible Rational
		++/
		ref Rational opAssign(Other)(Other other)
		    if (isRational!Other && isImplicitlyConvertible!(RationalType!Other, Type))
		{
			// Copy
			num = other.num;
			denom = other.denom;
			neg = other.neg;

			return this;
		}

		/++
		op= methods with a non-rational integer
		++/
		ref Rational opOpAssign(string op, Other)(Other other)
		    if (!isRational!Other && isImplicitlyConvertible!(Other, Type))
		{
			static if (op == "^^") // not tested
			{
				num ^^= other;
				denom ^^= other;
			}
			else
			{
				opOpAssign!op(Rational(other));
			}
			return this;
		}

		/++
		op= methods with another Rational
		++/
		ref Rational opOpAssign(string op, Other)(Other other)
		    if (isRational!Other && isImplicitlyConvertible!(RationalType!Other, Type)
		        && (op == "+" || op == "-" || op == "*" || op == "/"))
		{
			static if (op == "+")
			{
				Type ad = num * other.denom;

				Type bc = other.num * denom;

				denom = denom * other.denom;

				if (neg != other.neg)
				{
					if (ad < bc)
					{
						num = bc - ad;
						neg = !neg;
					}
					else
					{
						num = ad - bc;
					}
				}
				else
				{
					num = ad + bc;
				}

				static if (autoReduce)
					this.reduce();
			}
			else static if (op == "-")
			{
				opOpAssign!"+"(-other);
			}
			else static if (op == "*")
			{
				num = num * other.num;
				denom = denom * other.denom;

				neg = neg != other.neg;

				static if (autoReduce)
					this.reduce();
			}
			else static if (op == "/")
			{
				opOpAssign!"*"(other.inverse);
			}

			return this;
		}

		/++
		`-this` and `+this` operators
		++/
		Rational opUnary(string op)() const if (op == "-" || op == "+")
		{
			static if (op == "-")
			{
				Rational r = this;
				r.neg = !r.neg;
				return r;
			}
			else static if (op == "+")
			{
				return this;
			}
		}

		/++
		Increment and decrement operators
		++/
		ref Rational opUnary(string op)() if (op == "++" || op == "--")
		{
			static if (op == "++")
			{
				if (neg)
				{
					if (num < denom)
					{
						num = denom - num;
						neg = !neg;
					}
					else
					{
						num -= denom;
					}
				}
				else
				{
					num += denom;
				}
			}
			else static if (op == "--")
			{
				if (neg)
				{
					num += denom;
				}
				else
				{
					if (num < denom)
					{
						num = denom - num;
						neg = !neg;
					}
					else
					{
						num -= denom;
					}
				}
			}
			else
			{
				static assert(false, "Unary operation'" ~ op ~ "' not implemented.");
			}

			return this;
		}

		Rational opBinary(string op, Other)(Other other) const
		{
			Rational t = this;
			return t.opOpAssign!op(other);
		}
		Rational opBinaryRight(string op, Other)(Other other) const
		{
			auto o = Rational(other);
			return o.opBinary!op(this);
		}

		/// Converts to pretty string
		string toString()
		{
			import std.range : Appender;
			Appender!string res;

			if (this.neg)
				res ~= "-";

			import std.conv : to;
			res ~= num.to!string;
			res ~= "/";
			res ~= denom.to!string;

			return res.data;
		}
	}
}

/++
Convenience function to construct a Rational
++/
Rational!ulong rational(Num, Denom)(Num num, Denom denom)
{
	return Rational!ulong(num, denom);
}
/// ditto
Rational!ulong rational(Num)(Num num)
{
	return rational(num, 1);
}
static unittest
{
	auto r1 = rational(-2, 3);
	auto r2 = rational(4, -6);

	assert( r1 == r2 );
	assert( !(r1 > r2) );
	assert( !(r1 < r2) );
	assert( (r1 / r2) == 1 );
	assert( (r1 - r2) == 0 );
	assert( (1 - rational(1, 3)) == rational(2, 3));

	import std.math : approxEqual;
	assert( (cast(float)rational(1, -3) ).approxEqual(-0.33333));
	assert( cast(long)rational(256, 64) == 4 );

	assert( (r2 + rational(5, 2)) == rational(11, 6) );
	assert( (rational(123, 456) + rational(789, 123)) == rational(41657, 6232) );

	Rational!(ulong, false) r4 = r1;
	r1 = -2 * r4;
	assert( r1 == rational(cast(ulong)4, cast(uint)3) );
	assert( rational(1, 2) < 1 );
}
