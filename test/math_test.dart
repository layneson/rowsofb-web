import "package:test/test.dart";
import "package:rowsofb/src/math/fraction.dart";
import "package:rowsofb/src/math/matrix.dart";

main() {
  group("fraction:", () {
    test("Fraction.reduce", () {
      expect(new Fraction(2, 2).reduce().numerator, equals(1));
      expect(new Fraction(2, 2).reduce().denominator, equals(1));

      expect(new Fraction(4, 2).reduce().numerator, equals(2));
      expect(new Fraction(4, 2).reduce().denominator, equals(1));

      expect(new Fraction(30, 55).reduce().numerator, equals(6));
      expect(new Fraction(30, 55).reduce().denominator, equals(11));
    });

    test("Fraction.parseFraction", () {
      expect(new Fraction.parseFraction("1"), equals(new Fraction(1, 1)));
      expect(new Fraction.parseFraction("1/1"), equals(new Fraction(1, 1)));
      expect(new Fraction.parseFraction("0/5629"), equals(new Fraction(0, 1)));
      expect(new Fraction.parseFraction("5/42"), equals(new Fraction(5, 42)));
      expect(new Fraction.parseFraction("458"), equals(new Fraction(458, 1)));
    });

    test("Fraction.*", () {
      expect(new Fraction(5, 4) * new Fraction(3, 7),
          equals(new Fraction(15, 28)));
      expect(new Fraction(157, 157) * new Fraction(17, 38),
          equals(new Fraction(17, 38)));
      expect(new Fraction(0, 569) * new Fraction(12, 13),
          equals(new Fraction(0, 1)));
      expect(new Fraction(3, 2) * new Fraction(-2, 1),
          equals(new Fraction(-3, 1)));
      expect(new Fraction(7, -3) * new Fraction(-1, 2),
          equals(new Fraction(7, 6)));
    });

    test("Fraction.+", () {
      expect(new Fraction(6, 5) + new Fraction(10, 7),
          equals(new Fraction(92, 35)));
      expect(new Fraction(0, 12345) + new Fraction(45, 67),
          equals(new Fraction(45, 67)));
      expect(new Fraction(456, 456) + new Fraction(3, 7),
          equals(new Fraction(10, 7)));
      expect(
          new Fraction(3, 2) + new Fraction(-3, 2), equals(new Fraction(0, 1)));
      expect(new Fraction(3, 1) + new Fraction(-2, -4),
          equals(new Fraction(7, 2)));
    });

    test("Fraction.isZero", () {
      expect(new Fraction(1, 45).isZero(), isFalse);
      expect(new Fraction(0, 134).isZero(), isTrue);
    });

    test("Fraction.isOne", () {
      expect(new Fraction(2, 2).isOne(), isTrue);
      expect(new Fraction(4, 2).isOne(), isFalse);
    });
  });

  group("matrix:", () {
    test("matrix.ref", () {
      expect(constructMatrix(3, 3, [3, 0, -5, 1, -5, 0, 1, 1, -2]).ref(),
          equals(constructMatrix(3, 3, [1, 0, "-5/3", 0, 1, "-1/3", 0, 0, 0])));
      expect(new Matrix(5, 5).ref(), equals(new Matrix(5, 5)));
    });

    test("matrix.rref", () {
      expect(
          constructMatrix(3, 3, [-12, 2, -6, 18, -3, 9, -2, "1/3", -1]).rref(),
          equals(constructMatrix(3, 3, [1, "-1/6", "1/2", 0, 0, 0, 0, 0, 0])));
      expect(constructMatrix(3, 3, [-1, 0, 1, -1, 3, 0, -4, 12, -1]).rref(),
          equals(constructMatrix(3, 3, [1, 0, 0, 0, 1, 0, 0, 0, 1])));
      expect(new Matrix(5, 5).rref(), equals(new Matrix(5, 5)));
    });

    test("matrix.segment", () {
      expect(constructMatrix(3, 3, [1, 2, 3, 4, 5, 6, 7, 8, 9]).segment(2, 2, 3, 3),
          equals(constructMatrix(2, 2, [5, 6, 8, 9])));
      expect(constructMatrix(5, 5, [
        1, 2, 3, 4, 5,
        6, 7, 8, 9, 10,
        11, 12, 13, 14, 15,
        16, 17, 18, 19, 20,
        21, 22, 23, 24, 25
      ]).segment(2, 2, 4, 4), equals(constructMatrix(3, 3, [
        7, 8, 9,
        12, 13, 14,
        17, 18, 19
      ])));
    });

    test("matrix.isIdentity", () {
      expect(constructMatrix(3, 3, [1, 0, 1, 0, 1, 0, 0, 0, 1]).isIdentity(), isFalse);
      expect(constructMatrix(3, 3, [1, 0, 0, 0, 1, 0, 0, 0, 1]).isIdentity(), isTrue);
    });

    test("matrix.inverse", () {
      expect(constructMatrix(3, 3, [2, 6, 8, 6, 18, 25, 6, 17, 32]).inverse(), 
        equals(constructMatrix(3, 3, ["151/2", -28, 3, -21, 8, -1, -3, 1, 0])));
    });

    test("matrix.*", () {
      expect(constructMatrix(3, 4, [
        1, 2, 1, 1,
        7, 1, 2, 0,
        3, -1, 1, 0
      ]) * constructMatrix(4, 3, [
        1, 0, 1,
        0, 2, 0,
        1, 7, 0,
        0, 0, -1
      ]), equals(constructMatrix(3, 3, [
        2, 11, 0,
        9, 16, 7,
        4, 5, 3
      ])));
    });
  });
}

Matrix constructMatrix(int r, int c, List mat) {
  List<Fraction> values = new List<Fraction>();

  mat.forEach((item) {
    if (item is int) {
      values.add(new Fraction.fromScalar(item));
    } else if (item is String) {
      values.add(new Fraction.parseFraction(item));
    }
  });

  return new Matrix.fromValues(r, c, values);
}
