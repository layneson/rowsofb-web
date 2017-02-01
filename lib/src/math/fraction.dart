/// A representation of a fraction, with an integer numerator and denominator.
class Fraction {
  int _n, _d;

  Fraction(int numerator, int denominator) {
    _n = numerator;
    _d = denominator;

    if (_d == 0) {
      throw new ArgumentError("zero denominator is not acceptable");
    }

    _normalizeSignage();
  }

  Fraction.fromScalar(int scalar) : this(scalar, 1);

  Fraction.parseFraction(String s) {
    var fields = s.split("/");

    if (fields.length == 1) {
      fields.add("1");
    }

    _n = int.parse(fields[0], onError: (_) => null);
    _d = int.parse(fields[1], onError: (_) => null);

    if (_n == null || _d == null) {
      throw new Exception("invalid fraction");
    }
  }

  int get numerator => _n;
  int get denominator => _d;

  /// Returns an [int] representation of this fraction, calculated via integer division.
  int toInt() {
    return _n ~/ _d;
  }

  /// Returns [true] if this fraction represents zero.
  bool isZero() {
    return _n == 0;
  }

  /// Returns [true] if this fraction represents one.
  bool isOne() {
    return _n == _d;
  }

  /// Returns [true] if this fraction represents a whole number.
  bool isWhole() {
    reduce();

    return _d == 1;
  }

  /// Returns [true] if this fraction represents a non-negative (>= 0) number.
  bool isPositive() {
    _normalizeSignage();
    return _n >= 0;
  }

  @override
  bool operator ==(Fraction other) {
    if (_n == 0 && other._n == 0) return true;

    other.reduce();
    this.reduce();

    return _n == other._n && _d == other._d;
  }

  @override
  String toString() {
    if (_d == 1) {
      return "$_n";
    }

    if (_n == 0) {
      return "0";
    }

    return "$_n/$_d";
  }

  /// Multiplies two [Fraction]s.
  ///
  /// Returns a new [Fraction] instance with the result.
  Fraction operator *(Fraction other) {
    Fraction result = new Fraction(_n * other._n, _d * other._d);
    result._normalizeSignage();

    return result;
  }

  /// Adds two [Fraction]s.
  ///
  /// Returns a new [Fraction] instance with the result.
  /// Does not compute the Lowest Common Denominator.
  Fraction operator +(Fraction other) {
    Fraction result =
        new Fraction(_n * other._d + other._n * _d, _d * other._d);
    result._normalizeSignage();

    return result;
  }

  /// Calculates the reciprocal (multiplicative inverse) of this [Fraction].
  ///
  /// Returns a new [Fraction] instance with the result.
  Fraction reciprocal() {
    Fraction result = new Fraction(_d, _n);
    result._normalizeSignage();

    return result;
  }

  /// Negates this [Fraction] (multiplies it by -1).
  ///
  /// Returns a new [Fraction] instance with the result.
  Fraction negate() {
    return new Fraction(_n * -1, _d);
  }

  /// Reduces this [Fraction].
  /// 
  /// Mutates this [Fraction] instance and returns itself for ease of chaining.
  Fraction reduce() {
    if (_n == 0) {
      return this;
    }

    int gcd = _gcd(_n, _d);

    _n = _n ~/ gcd;
    _d = _d ~/ gcd;

    _normalizeSignage();

    return this;
  }

  void _normalizeSignage() {
    // Switch signs if _n and _d are both negative, or if _d is negative but _n is not.
    // This ensures that if the fraction is negative, _n < 0 and _d > 0.
    if (_n < 0 && _d < 0 || _d < 0) {
      _n *= -1;
      _d *= -1;
    }
  }
}

int _gcd(int a, int b) {
  while (b != 0) {
    int t = b;
    b = a % b;
    a = t;
  }

  return a;
}
