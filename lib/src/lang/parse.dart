import "package:rowsofb/src/lang/lex.dart";

/*
   Parsing grammar:

       expr    -> term ((ttPlus | ttMinus) term)* (arrow (ttMVar | ttSVar))? EOF
       term    -> factor ((ttMult | ttDiv) factor)*
       factor  -> (ttMinus)? ttNum
               -> (ttMinus)? ttFunc ttLParen expr (ttComma expr)* ttRParen
               -> (ttMinus)? ttDMVar | ttDSVar | ttDAMVar | ttMVar | ttSVar
               -> (ttMinus)? ttLParen expr ttRParen
*/

class ExprNode {
  TermNode first;

  List<Token> operators = [];
  List<TermNode> terms = [];

  Token resultVar;

  @override
  String toString() {
    String s = "expr($first";
    for (int i = 0; i < operators.length; i++) {
      s += "${operators[i]}${terms[i]}";
    }
    
    if (resultVar != null) {
      s += "$resultVar";
    }

    return s + ")";
  }
}

class TermNode {
  FactorNode first;

  List<Token> operators = [];
  List<FactorNode> factors = [];

  @override
  String toString() {
    String s = "term($first";
    for (int i = 0; i < operators.length; i++) {
      s += "${operators[i]}${factors[i]}";
    }
    return s + ")";
  }
}

abstract class FactorNode {
  Token neg;

  FactorNode(this.neg);
}

class NumFactorNode extends FactorNode {
  Token number;

  NumFactorNode(Token neg) : super(neg);

  @override
  String toString() {
    return "numFactor" + (neg == null ? "" : "-") + "($number)";
  }
}

class FuncFactorNode extends FactorNode {
  Token function;
  List<ExprNode> args = [];

  FuncFactorNode(Token neg) : super(neg);

  @override
  String toString() {
    String s = "funcFactor" + (neg == null ? "" : "-") + "($function";

    s += args.map((arg) => arg.toString()).join(",");

    return s + ")";
  }
}

class VarFactorNode extends FactorNode {
  Token variable;

  VarFactorNode(Token neg) : super(neg);

  @override
  String toString() {
    return "varFactor" + (neg == null ? "" : "-") + "($variable)";
  }
}

class ParenFactorNode extends FactorNode {
  ExprNode expr;

  ParenFactorNode(Token neg) : super(neg);

  @override
  String toString() {
    return "parenFactor" + (neg == null ? "" : "-") + "($expr)";
  }
}

class ParseException implements Exception {
  String message;
  Token badToken;

  ParseException(this.message, this.badToken);
}

class _Parser {
  List<Token> tokens;
  int pos = 0;

  _Parser(this.tokens);

  Token peek() {
    return tokens[pos];
  }

  Token consume() {
    Token t = peek();
    pos++;
    return t;
  }
}

/// Takes a list of [Token]s and returns an [ExprNode] which represents the entire expression.
///
/// If a parsing error occurs, a [ParseException] will be thrown with information about the problem.
ExprNode parse(List<Token> tokens) {
  _Parser psr = new _Parser(tokens);

  ExprNode expr = _parseExpr(psr);

  if (psr.peek().type == TokenType.ARROW) {
    psr.consume();

    if (psr.peek().type != TokenType.MVAR &&
        psr.peek().type != TokenType.SVAR) {
      throw new ParseException("must be matrix or scalar variable", psr.peek());
    }

    expr.resultVar = psr.consume();
  }

  if (psr.peek().type != TokenType.EOF) {
    throw new ParseException("expected end of the line", psr.peek());
  }

  return expr;
}

ExprNode _parseExpr(_Parser psr) {
  ExprNode enode = new ExprNode();

  enode.first = _parseTerm(psr);

  while ([TokenType.PLUS, TokenType.MINUS].contains(psr.peek().type)) {
    enode.operators.add(psr.consume());
    enode.terms.add(_parseTerm(psr));
  }

  return enode;
}

TermNode _parseTerm(_Parser psr) {
  TermNode tnode = new TermNode();

  tnode.first = _parseFactor(psr);

  while ([TokenType.MULT, TokenType.DIV].contains(psr.peek().type)) {
    tnode.operators.add(psr.consume());
    tnode.factors.add(_parseFactor(psr));
  }

  return tnode;
}

FactorNode _parseFactor(_Parser psr) {
  Token neg;

  if (psr.peek().type == TokenType.MINUS) {
    neg = psr.consume();
  }

  if (psr.peek().type == TokenType.NUM) {
    return _parseNumFactor(psr, neg);
  }

  if (psr.peek().type == TokenType.FUNC) {
    return _parseFuncFactor(psr, neg);
  }

  if (psr.peek().type == TokenType.LPAREN) {
    return _parseParenFactor(psr, neg);
  }

  if (![
    TokenType.MVAR,
    TokenType.SVAR,
    TokenType.DMVAR,
    TokenType.DSVAR,
    TokenType.DAMVAR
  ].contains(psr.peek().type)) {
    throw new ParseException("expected value", psr.peek());
  }

  return _parseVarFactor(psr, neg);
}

NumFactorNode _parseNumFactor(_Parser psr, Token neg) {
  return new NumFactorNode(neg)..number = psr.consume();
}

FuncFactorNode _parseFuncFactor(_Parser psr, Token neg) {
  FuncFactorNode fnode = new FuncFactorNode(neg);

  fnode.function = psr.consume();

  if (psr.peek().type != TokenType.LPAREN) {
    throw new ParseException("expected left parenthesis", psr.peek());
  }

  psr.consume(); // Ignore the LPAREN.

  fnode.args.add(_parseExpr(psr));

  while (psr.peek().type == TokenType.COMMA) {
    psr.consume(); // Ignore the COMMA.

    fnode.args.add(_parseExpr(psr));
  }

  if (psr.peek().type != TokenType.RPAREN) {
    throw new ParseException("expected right parenthesis", psr.peek());
  }

  psr.consume(); // Ignore the RPAREN.

  return fnode;
}

ParenFactorNode _parseParenFactor(_Parser psr, Token neg) {
  ParenFactorNode fnode = new ParenFactorNode(neg);

  psr.consume(); // Ignore the LPAREN.

  fnode.expr = _parseExpr(psr);

  if (psr.peek().type != TokenType.RPAREN) {
    throw new ParseException("expected right parenthesis", psr.peek());
  }

  psr.consume(); // Ignore the RPAREN.

  return fnode;
}

VarFactorNode _parseVarFactor(_Parser psr, Token neg) {
  return new VarFactorNode(neg)..variable = psr.consume();
}