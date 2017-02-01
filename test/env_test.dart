import "package:test/test.dart";
import "package:rowsofb/lang.dart";
import "package:rowsofb/math.dart";
import "package:rowsofb/src/env/env.dart";

main() {
  test("evaluate", () {
    expect(eval("5+5", null).svalue, equals(new Fraction.fromScalar(10)));
    expect(eval("5*25/7", null).svalue, equals(new Fraction(125, 7)));
    
    Environment e = new Environment(null);
    e.setSVar(new Variable("a".runes.first), new Fraction(5, 2));

    expect(eval("5*a/2 -> b", e).svalue, equals(new Fraction(25, 4)));
    expect(e.getSVar(new Variable("b".runes.first)), equals(new Fraction(25, 4)));

    expect(eval("5*ident(3)", null).mvalue, equals(constructMatrix(3, 3, [5, 0, 0, 0, 5, 0, 0, 0, 5])));
  });
}

Value eval(String s, Environment env) {
  return evaluate(parse(lex(s)), env);
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