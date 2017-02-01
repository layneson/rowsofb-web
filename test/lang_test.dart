import "package:test/test.dart";
import "package:rowsofb/src/lang/lex.dart";
import "package:rowsofb/src/lang/parse.dart";

main() {
  test("lex", () {
    expect(
        lex("234+1-3/56->A"),
        equals([
          new Token(TokenType.NUM, "234", 0),
          new Token(TokenType.PLUS, "+", 3),
          new Token(TokenType.NUM, "1", 4),
          new Token(TokenType.MINUS, "-", 5),
          new Token(TokenType.NUM, "3", 6),
          new Token(TokenType.DIV, "/", 7),
          new Token(TokenType.NUM, "56", 8),
          new Token(TokenType.ARROW, "->", 10),
          new Token(TokenType.MVAR, "A", 12),
          new Token(TokenType.EOF, "", 12)
        ]));

    expect(
        lex(r"M*m+$A$a$$blub(4,6/7)"),
        equals([
          new Token(TokenType.MVAR, "M", 0),
          new Token(TokenType.MULT, "*", 1),
          new Token(TokenType.SVAR, "m", 2),
          new Token(TokenType.PLUS, "+", 3),
          new Token(TokenType.DMVAR, r"$A", 4),
          new Token(TokenType.DSVAR, r"$a", 6),
          new Token(TokenType.DAMVAR, r"$$", 8),
          new Token(TokenType.FUNC, "blub", 10),
          new Token(TokenType.LPAREN, "(", 14),
          new Token(TokenType.NUM, "4", 15),
          new Token(TokenType.COMMA, ",", 16),
          new Token(TokenType.NUM, "6", 17),
          new Token(TokenType.DIV, "/", 18),
          new Token(TokenType.NUM, "7", 19),
          new Token(TokenType.RPAREN, ")", 20),
          new Token(TokenType.EOF, "", 20)
        ]));
  });

  test("parse", () {
    expect(parse([
       new Token(TokenType.NUM, "234", 0),
          new Token(TokenType.PLUS, "+", 3),
          new Token(TokenType.NUM, "1", 4),
          new Token(TokenType.MINUS, "-", 5),
          new Token(TokenType.NUM, "3", 6),
          new Token(TokenType.DIV, "/", 7),
          new Token(TokenType.NUM, "56", 8),
          new Token(TokenType.ARROW, "->", 10),
          new Token(TokenType.MVAR, "A", 12),
          new Token(TokenType.EOF, "", 12)
    ]).toString(), equals("""
      expr(
        term(
          numFactor(
            <NUM:"234"@0>
          )
        )
        <PLUS:"+"@3>
        term(
          numFactor(
            <NUM:"1"@4>
          )
        )
        <MINUS:"-"@5>
        term(
          numFactor(
            <NUM:"3"@6>
          )
          <DIV:"/"@7>
          numFactor(
            <NUM:"56"@8>
          )
        )
        <MVAR:"A"@12>
      )
    """.replaceAll(new RegExp(r"\s+"), "")));
  });
}
