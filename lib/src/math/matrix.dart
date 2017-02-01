import "package:rowsofb/src/math/fraction.dart";

/// A representation of a matrix.
class Matrix {
  int _r, _c;
  List<Fraction> _values;

  Matrix(int r, int c) {
    _r = r;
    _c = c;

    _values = new List<Fraction>(r * c);

    for (int i = 0; i < _values.length; i++) {
      _values[i] = new Fraction.fromScalar(0);
    }
  }

  Matrix.fromValues(int r, int c, List<Fraction> values)
      : _r = r,
        _c = c,
        _values = values;

  Matrix.identity(int size) {
    _r = size;
    _c = size;

    _values = new List<Fraction>(_r * _c);

    for (int r = 1; r <= rows; r++) {
      for (int c = 1; c <= cols; c++) {
        set(r, c, new Fraction.fromScalar(r == c ? 1 : 0));
      }
    }
  }

  @override
  bool operator ==(Matrix m) {
    if (m.cols != cols || m.rows != rows) {
      return false;
    }

    for (int r = 1; r <= rows; r++) {
      for (int c = 1; c <= cols; c++) {
        if (m.get(r, c) != get(r, c)) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  String toString() {
    return _values.toString();
  }

  int get rows => _r;
  int get cols => _c;

  Fraction get(int r, int c) {
    r = r - 1;
    c = c - 1;
    return _values[r * cols + c];
  }

  void set(int r, int c, Fraction v) {
    r = r - 1;
    c = c - 1;
    _values[r * cols + c] = v.reduce();
  }

  void switchRows(int r1, int r2) {
    r1 = r1 - 1;
    r2 = r2 - 1;

    for (int c = 0; c < cols; c++) {
      var tmp = _values[r1 * cols + c];
      _values[r1 * cols + c] = _values[r2 * cols + c];
      _values[r2 * cols + c] = tmp;
    }
  }

  void multiplyRow(int r, Fraction s) {
    r = r - 1;

    for (int c = 0; c < cols; c++) {
      _values[r * cols + c] = (_values[r * cols + c] * s).reduce();
    }
  }

  void multiplyAndAddRow(int r1, Fraction s, int r2) {
    r1 = r1 - 1;
    r2 = r2 - 1;

    for (int c = 0; c < cols; c++) {
      _values[r2 * cols + c] =
          (_values[r2 * cols + c] + (_values[r1 * cols + c] * s)).reduce();
    }
  }

  bool isIdentity() {
    if (rows != cols) return false;

    for (int r = 1; r <= rows; r++) {
      for (int c = 1; c <= cols; c++) {
        if (r == c) {
          if (!get(r, c).isOne()) {
            return false;
          }
        } else {
          if (!get(r, c).isZero()) {
            return false;
          }
        }
      }
    }

    return true;
  }

  /// Copies this [Matrix] into a new instance of [Matrix].
  Matrix copy() {
    List<Fraction> resultValues = new List<Fraction>();
    _values.forEach((f) => resultValues.add(f));

    return new Matrix.fromValues(rows, cols, resultValues);
  }

  /// Copies this [Matrix] and calculates its transpose.
  Matrix transpose() {
    Matrix result = copy();

    for (int r = 1; r <= rows; r++) {
      for (int c = 1; c <= cols; c++) {
        result.set(c, r, get(r, c));
      }
    }

    return result;
  }

  bool isLeadingEntry(int r, int c) {
    if (get(r, c).isZero()) return false;

    for (int cc = c - 1; cc > 0; cc--) {
      if (!get(r, cc).isZero()) {
        return false;
      }
    }

    return true;
  }

  /// Copies this [Matrix] and computes a row echelon form.
  Matrix ref() {
    Matrix m = copy();

    int startr = 1;
    for (int c = 1; c <= cols; c++) {
      bool found = false;
      for (int r = startr; r <= rows; r++) {
        if (m.isLeadingEntry(r, c)) {
          found = true;
          m.switchRows(startr, r);
          break;
        }
      }

      if (!found) continue;

      m.multiplyRow(startr, m.get(startr, c).reciprocal());

      for (int r = startr + 1; r <= rows; r++) {
        if (m.isLeadingEntry(r, c)) {
          m.multiplyAndAddRow(
              startr, m.get(startr, c).reciprocal() * m.get(r, c).negate(), r);
        }
      }

      startr++;
    }

    return m;
  }

  /// Copies this [Matrix] and computes its reduced row echelon form.
  Matrix rref() {
    Matrix m = copy();

    m = m.ref();

    for (int c = 1; c <= cols; c++) {
      for (int r = 1; r <= rows; r++) {
        if (m.isLeadingEntry(r, c)) {
          m.multiplyRow(r, m.get(r, c).reciprocal());
          for (int rr = r - 1; rr > 0; rr--) {
            if (!m.get(rr, c).isZero()) {
              m.multiplyAndAddRow(
                  r, m.get(rr, c).negate() * m.get(r, c).reciprocal(), rr);
            }
          }
        }
      }
    }

    return m;
  }

  /// Copies this [Matrix] and appends the given [Matrix] on the right, returning the result.
  ///
  /// Throws an [MatrixException] if the matrices do not have the same number of rows.
  Matrix augment(Matrix b) {
    Matrix a = this;

    if (a.rows != b.rows) {
      throw new MatrixException("augmented matrices must have equal numbers of rows");
    }

    Matrix result = new Matrix(a.rows, a.cols + b.cols);

    for (int r = 1; r <= a.rows; r++) {
      for (int c = 1; c <= a.cols; c++) {
        result.set(r, c, a.get(r, c));
      }
    }

    for (int r = 1; r <= a.rows; r++) {
      for (int c = 1; c <= b.cols; c++) {
        result.set(r, a.cols + c, b.get(r, c));
      }
    }

    return result;
  }

  /// Copies this [Matrix] and returns a section of it, from (r1, c1) to (r2, c2), inclusive.
  Matrix segment(int r1, int c1, int r2, int c2) {
    Matrix result = new Matrix(r2 - r1 + 1, c2 - c1 + 1);

    for (int r = 1; r <= result.rows; r++) {
      for (int c = 1; c <= result.cols; c++) {
        result.set(r, c, get(r1 + r - 1, c1 + c - 1));
      }
    }

    return result;
  }

  /// Copies this [Matrix] and computes its inverse.
  /// A [MatrixException] is thrown if the matrix has no inverse.
  Matrix inverse() {
    Matrix m = copy();

    if (m.rows != m.cols) {
      throw new MatrixException("non-square matrices have no inverse");
    }

    m = m.augment(new Matrix.identity(m.rows));

    m = m.rref();

    Matrix leftPart = m.segment(1, 1, m.rows, m.rows);

    if (!leftPart.isIdentity()) {
      throw new MatrixException("matrix has no inverse");
    }

    return m.segment(1, m.rows+1, m.rows, m.cols);
  }

  /// Adds this [Matrix] to [Matrix] m, returning the result as a new instance.
  Matrix operator +(Matrix m) {
    if (m.rows != rows || m.cols != cols) {
      throw new MatrixException("addition requires two indentically-sized matrices");
    }

    Matrix result = copy();

    for (int r = 1; r <= rows; r++) {
      for (int c = 1; c <= cols; c++) {
        result.set(r, c, get(r, c) + m.get(r, c));
      }
    }

    return result;
  }

  /// Scales a copy of this [Matrix] by the given [Fraction].
  Matrix scale(Fraction s) {
    Matrix result = copy();

    for (int r = 1; r <= rows; r++) {
      result.multiplyRow(r, s);
    }

    return result;
  }

  /// Multiplies this [Matrix] by [Matrix] m, returning the result as a new instance.
  Matrix operator *(Matrix m) {
    if (cols != m.rows) {
      throw new MatrixException("multiplication can only be done on matrices A and B if the number of columns of A equals the number of rows of B");
    }

    Matrix result = new Matrix(rows, m.cols);

    for (int r = 1; r <= result.rows; r++) {
      for (int c = 1; c <= result.cols; c++) {
        Fraction sum = new Fraction.fromScalar(0);

        for (int count = 1; count <= cols; count++) {
          Fraction fres = get(r, count) * m.get(count, c);
          sum += fres;
        }

        result.set(r, c, sum);
      }
    }

    return result;
  }
}

class MatrixException implements Exception {
  String message;

  MatrixException(this.message);
}