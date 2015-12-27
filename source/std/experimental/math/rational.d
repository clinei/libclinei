module std.experimental.math.rational;

auto greatestCommonDivisor(A, B)(A a, B b)
{
	if (b == 0)
	{
		if (a > 0)
			return a;
		else
			return A(1);
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
	static if (is(Unqual!T == Rational!(autoReduce, Numerator, Denominator, autoReduce), bool autoReduce, Numerator, Denominator))
	{
		enum bool isRational = true;
	}
	else
	{
		enum bool isRational = false;
	}
}

template isAutoReduced(T)
{
	import std.traits : Unqual;
	static if (is(Unqual!T == Rational!(autoReduce, Numerator, Denominator), bool autoReduce, Numerator, Denominator))
	{
		enum bool isAutoReduced = autoReduce;
	}
	else
	{
		enum bool isAutoReduced = autoReduce;
	}
}

template NumeratorType(T)
{
	import std.traits : Unqual;
	static if (is(Unqual!T == Rational!(autoReduce, Numerator, Denominator), bool autoReduce, Numerator, Denominator))
	{
		alias NumeratorType = Numerator;
	}
	else
	{
		alias NumeratorType = void;
	}
}

template DenominatorType(T)
{
	import std.traits : Unqual;
	static if (is(Unqual!T == Rational!(autoReduce, Numerator, Denominator), bool autoReduce, Numerator, Denominator))
	{
		alias DenominatorType = Denominator;
	}
	else
	{
		alias DenominatorType = void;
	}
}

template isCompatibleRational(This, Other)
{
	import std.typetuple : allSatisfy;
	import std.traits : isImplicitlyConvertible;
	static if (allSatisfy!(isRational, This, Other)
	           && isImplicitlyConvertible!(NumeratorType!Other, NumeratorType!This)
	           && isImplicitlyConvertible!(DenominatorType!Other, DenominatorType!This))
	{
		enum bool isCompatibleRational = true;
	}
	else
	{
		enum bool isCompatibleRational = false;
	}
}

template NumeratorDepth(T, size_t count = 0)
{
	static if (isRational!T)
	{
		enum size_t NumeratorDepth = NumeratorDepth!(NumeratorType!T, count + 1);
	}
	else
	{
		enum size_t NumeratorDepth = count;
	}
}

template DenominatorDepth(T, size_t count = 0)
{
	static if (isRational!T)
	{
		enum size_t DenominatorDepth = DenominatorDepth!(DenominatorType!T, count + 1);
	}
	else
	{
		enum size_t DenominatorDepth = count;
	}
}

template RationalDepth(T, size_t count = 0)
{
	static if (isRational!T)
	{
		import std.algorithm : min;
		enum size_t RationalDepth = min(RationalDepth!(NumeratorType!T, count + 1),
		                                RationalDepth!(DenominatorType!T, count + 1));
	}
	else
	{
		enum size_t RationalDepth = count;
	}
}

import std.typetuple : templateOr;
import std.traits : isFloatingPoint, isIntegral;
alias isValidCastType = templateOr!(isFloatingPoint, isIntegral);

template Rational(bool autoReduce = true, Numerator = ulong, Denominator = ulong)
{
	struct Rational
	{
		import std.typetuple : anySatisfy;
		import std.traits : isFloatingPoint;
		static if (anySatisfy!(isFloatingPoint, Numerator, Denominator))
		{
			static assert(false, "Floating point Numerator or Denominator types defeat the purpose of Rational. Use unsigned integral types.");
		}

		import std.typetuple : allSatisfy;
		import std.traits : isSigned;
		static if (anySatisfy!(isSigned, Numerator, Denominator))
		{
			static assert(false, "Only unsigned types are supported");
		}

		/// Numerator
		Numerator num;

		/// Denominator
		Denominator denom = 1;

		/// If is negative (sign bit)
		bool neg;

		/++
		Construct from numerator
		++/
		import std.traits : isImplicitlyConvertible;
		this(Num)(Num num) if (isImplicitlyConvertible!(Num, Numerator))
		{
			opAssign(num);
		}
		this(Num)(Num num)
		    if (!isImplicitlyConvertible!(Num, Numerator) && isRational!Numerator)
		{
			this.num = Numerator(num);
		}

		/++
		Construct from numerator, denominator and sign bit
		++/
		import std.traits : isSigned, isIntegral;
		import std.typetuple : anySatisfy;
		this(Num, Denom)(Num num, Denom denom, bool neg = false)
		    if (!anySatisfy!(isSigned, Num, Denom)
		        && isImplicitlyConvertible!(Num, Numerator) && isImplicitlyConvertible!(Denom, Denominator))
		{
			this.num = num;
			this.denom = denom;
			this.neg = neg;

			static if (autoReduce)
				this.reduce();
		}
		this(Num, Denom)(Num num, Denom denom)
		    if (anySatisfy!(isSigned, Num, Denom) && !anySatisfy!(isFloatingPoint, Num, Denom))
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
		Construct from another Rational if the types are compatible
		++/
		this(Other)(Other other) if (isRational!Other && isCompatibleRational!(typeof(this), Other))
		{
			opAssign(other);
		}

		/++
		Construct from an indirectly compatible Rational
		++/
		this(Num, Denom)(Num num, Denom denom, bool neg = false)
		    if (!isImplicitlyConvertible!(Num, Numerator) && isRational!Numerator
		        || !isImplicitlyConvertible!(Denom, Denominator) && isRational!Denominator)
		{
			this.num = Numerator(num);
			this.denom = Denominator(denom);
			this.neg = neg;
		}

		import std.traits : isFloatingPoint;
		this(Floating)(Floating floating, ulong precision = 10) if (isFloatingPoint!Floating)
		{
			import std.math : round;
			import std.conv : to;
			ulong exponent = 10UL ^^ precision;
			num = round(floating * exponent).to!ulong;
			denom = exponent;
		}

		static if (is(Numerator == Denominator))
		{
			/++
			Only available if Numerator and Denominator are the same type
			Returns: `this` with switched num and denom
			++/
			Rational inverse() const @property
			{
				return Rational(denom, num, neg);
			}
		}

		/++
		Forces a specific precision, use only when rounding errors are insignificant or don't build up
		++/
		ref Rational forcePrecision(Denom = Denominator)(Denom denom)
		{
			num /= this.denom / denom;
			this.denom = denom;

			return this;
		}

		/++
		Same as `forcePrecision`, but doesn't change the original
		Bugs: Cannot infer type for template parameters from this
		++/
		Rational atPrecision(Denom = Denominator)(Denom denom)
		{
			Rational t = this;
			return t.forcePrecision(denom);
		}

		/++
		Reduces to the lowest possible terms
		++/
		ref Rational reduce()
		{
			auto gcd = greatestCommonDivisor(num, denom);

			if (gcd > 0)
			{
				num /= gcd;
				denom /= gcd;
			}

			if (neg && num == 0)
			{
				neg = false;
			}

			return this;
		}

		static if (RationalDepth!(typeof(this)) > 1)
			auto depthReduced()
			{
				if (num.denom == denom.denom)
				{
					return Numerator(num.num, denom.num);
				}
				return Numerator(0, 0); //FIXME
			}

		import std.traits : isFloatingPoint;
		/++
		Cast to floating point
		Example:
		---
		auto r = rational(1, 3);

		import std.conv : to;
		writeln(r.to!real); // prints 0.33333
		---
		++/
		CastType opCast(CastType)()// if (isValidCastType!CastType)
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
			if (denom == 0) denom = 1;
			if (other.denom == 0) other.denom = 1;
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
		Assign from a type compatible with Numerator
		+/
		ref Rational opAssign(Num)(Num num)
			if (!isRational!Num && isImplicitlyConvertible!(Num, Numerator))
		{
			import std.traits : isSigned;
			static if (isSigned!Num)
			{
				neg = num < 0;
				if (neg)
				{
					num = -num;
				}
			}

			this.num = num;
			denom = 1;

			return this;
		}

		/+
		import std.traits : isFloatingPoint;
		ref Rational opAssign(Other)(Other other)
		    if (isFloatingPoint!Other)
		{
			;

			return this;
		}
		+/

		/++
		Assign from a compatible Rational
		++/
		ref Rational opAssign(Other)(Other other)
			if (isRational!Other && isCompatibleRational!(typeof(this), Other))
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
			if (!isRational!Other)
		{
			static if (op == "^^")
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
			if (isRational!Other && isCompatibleRational!(typeof(this), Other))
		{
			static if (op == "+")
			{
				auto ad = num * other.denom;

				auto bc = other.num * denom;

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
			else static if (op == "%")
			{
				auto lcm = leastCommonMultiple(denom, other.denom);

				num = (num * (lcm / denom)) % (other.num * (lcm / other.denom));
				denom = lcm;

				static if (autoReduce)
					this.reduce();
			}
			else
			{
				static assert("Operator '" ~ op ~ "' not defined for Rational.");
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

			static if (isRational!Numerator)
				res ~= "(";

			import std.conv : to;
			res ~= num.to!string;

			static if (isRational!Numerator)
				res ~= ")";

			res ~= "/";

			static if (isRational!Denominator)
				res ~= "(";

			res ~= denom.to!string;

			static if (isRational!Denominator)
				res ~= ")";

			return res.data;
		}
	}
}

import std.typetuple : allSatisfy;
import std.traits : isIntegral;
/++
Convenience function to construct a Rational from integers
++/
Rational!(autoReduce, ulong, ulong) rational(bool autoReduce = true, Num, Denom)(Num num, Denom denom)
    if (allSatisfy!(isIntegral, Num, Denom))
{
	return Rational!(autoReduce, ulong, ulong)(num, denom);
}
/// ditto
Rational!(autoReduce, ulong, ulong) rational(bool autoReduce = true, Num)(Num num)
    if (isIntegral!Num)
{
	return rational!autoReduce(num, 1);
}

Rational!(autoReduce, Num, Denom) rational(bool autoReduce = true, Num, Denom)(Num num, Denom denom)
    if (allSatisfy!(isRational, Num, Denom))
{
	return Rational!(autoReduce, Num, Denom)(num, denom);
}

import std.traits : isFloatingPoint;
/++
Convenience function to construct a Rational from floating point values
++/
Rational!(autoReduce, ulong, ulong) rational(bool autoReduce = true, Floating)(Floating floating, ulong precision = 10)
    if (isFloatingPoint!Floating)
{
	return Rational!(autoReduce, ulong, ulong)(floating, precision);
}

unittest
{
	auto r1 = rational(-2, 3);
	auto r2 = rational(4, -6);

	// Comparisons and a few math operators
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

	Rational!false r3 = r1;
	r1 = -2 * r3;
	assert( r1 == rational(cast(ulong)4, cast(uint)3) );
	assert( rational(1, 2) < 1 );

// 	assert(rational(rational(3, 2), rational(4, 5)).depthReduced() == rational(15, 8));

	// Modulo operator
	// 10/3 % 3/2 == 3 1/3 % 1 1/2 == 3.333 % 1.5 == 0.333 == 1/3
	assert( rational(10, 3) % rational(3, 2) == rational(1, 3) );

	// Initialize from float
	assert( ( cast(float)rational(3.141592) ).approxEqual(3.141592) );
}
