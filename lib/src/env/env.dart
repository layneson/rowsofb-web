import "package:rowsofb/src/math/matrix.dart";
import "package:rowsofb/src/math/fraction.dart";
import "package:rowsofb/src/lang/parse.dart";
import "package:rowsofb/src/lang/lex.dart";

import "package:rowsofb/src/env/functions.dart";

import "dart:collection";

class InputCancellationException implements Exception {

}

enum ValType { M, S }

class Variable {
  int rune;

  Variable(this.rune);

  Variable.fromString(String s) {
    rune = s.runes.first;
  }

  ValType get type => rune >= "A".runes.first && rune <= "Z".runes.first
      ? ValType.M
      : rune >= "a".runes.first && rune <= "z".runes.first ? ValType.S : null;

  @override
  String toString() {
    return new String.fromCharCode(rune);
  }
}

/// An environment which contains 26 matrix variables (A-Z) and 26 scalar variables (a-z).
///
/// The variables Z and z are set to the result of matrix and scalar-resolving expressions, respectively.
class Environment {
  List<Matrix> _mvars = new List();
  List<Fraction> _svars = new List();

  Map<Token, Matrix> definedMatrices = new Map();
  Map<Token, Fraction> definedScalars = new Map();

  /// Initializes all matrix variables to 3x3 zero matrices and all scalar variables to 0.
  Environment() {
    for (int r = "A".runes.first; r <= "Z".runes.first; r++) {
      _mvars.add(new Matrix(3, 3));
    }

    for (int r = "a".runes.first; r <= "z".runes.first; r++) {
      _svars.add(new Fraction.fromScalar(0));
    }
  }

  Matrix getMVar(Variable v) {
    return _mvars[v.rune - "A".runes.first];
  }

  void setMVar(Variable v, Matrix m) {
    _mvars[v.rune - "A".runes.first] = m;
  }

  Fraction getSVar(Variable v) {
    return _svars[v.rune - "a".runes.first];
  }

  void setSVar(Variable v, Fraction f) {
    _svars[v.rune - "a".runes.first] = f.reduce();
  }
}

class Value {
  ValType type;

  Matrix mvalue;
  Fraction svalue;

  Value.matrix(Matrix mvalue) {
    type = ValType.M;
    this.mvalue = mvalue;
  }

  Value.scalar(Fraction svalue) {
    type = ValType.S;
    this.svalue = svalue;
  }

  @override
  String toString() {
    if (type == ValType.M) {
      return mvalue.toString();
    }

    return svalue.toString();
  }
}

class EvaluationException implements Exception {
  String message;
  Token badToken;

  EvaluationException(this.message, this.badToken);
}

/// Evaluates an [ExprNode] in the context of the given [Environment].
/// 
/// Returns a [Value] which contains the result.
/// 
/// Throws an [EvaluationException] if something goes wrong.
Value evaluate(ExprNode enode, Environment env) {
  Value val = _evalExpr(enode, env);

  if (enode.resultVar != null) {
    if (val.type == ValType.M && enode.resultVar.type == TokenType.SVAR) {
      throw new EvaluationException("cannot assign a matrix value to a scalar variable", enode.resultVar);
    }

    if (val.type == ValType.S && enode.resultVar.type == TokenType.MVAR) {
      throw new EvaluationException("cannot assign a scalar value to a matrix variable", enode.resultVar);
    }

    Variable v = new Variable(enode.resultVar.literal.runes.first);

    if (val.type == ValType.M) {
      env.setMVar(v, val.mvalue);
    } else {
      env.setSVar(v, val.svalue);
    }
  }

  if (val.type == ValType.M) {
    env.setMVar(new Variable("Z".runes.first), val.mvalue);
  } else {
    env.setSVar(new Variable("z".runes.first), val.svalue);
  }

  return val;
}

Value _evalExpr(ExprNode enode, Environment env) {
  Value first = _evalTerm(enode.first, env);

  for (int i = 0; i < enode.terms.length; i++) {
    Token op = enode.operators[i];
    TermNode tnode = enode.terms[i];

    Value tval = _evalTerm(tnode, env);

    if (op.type == TokenType.PLUS) {
      first = _evalAddition(first, tval, op);
    } else {
      first = _evalSubtraction(first, tval, op);
    }
  }

  return first;
}

Value _evalAddition(Value left, Value right, Token op) {
  if (left.type != right.type) {
    throw new EvaluationException("cannot perform addition with a scalar and a matrix", op);
  }

  if (left.type == ValType.S) {
    return new Value.scalar(left.svalue + right.svalue);
  }

  if (left.mvalue.cols != right.mvalue.cols || left.mvalue.rows != right.mvalue.rows) {
    throw new EvaluationException("cannot perform addition on matrices of different sizes!", op);
  }

  return new Value.matrix(left.mvalue + right.mvalue);
}

Value _evalSubtraction(Value left, Value right, Token op) {
  if (left.type != right.type) {
    throw new EvaluationException("cannot perform subtraction with a scalar and a matrix", op);
  }

  if (left.type == ValType.S) {
    return new Value.scalar(left.svalue + right.svalue.negate());
  }

  if (left.mvalue.cols != right.mvalue.cols || left.mvalue.rows != right.mvalue.rows) {
    throw new EvaluationException("cannot perform subtraction on matrices of different sizes!", op);
  }

  return new Value.matrix(left.mvalue + right.mvalue.scale(new Fraction.fromScalar(-1)));
}

Value _evalTerm(TermNode tnode, Environment env) {
  Queue<Value> fstack = new Queue();
  
  Queue<Value> divqueue = new Queue();
  Queue<Token> divtokens = new Queue();

  fstack.addLast(_evalFactor(tnode.first, env));

  for (FactorNode fnode in tnode.factors) {
    fstack.addLast(_evalFactor(fnode, env));
  }

  for (Token op in tnode.operators) {
    if (op.type == TokenType.DIV) {
      divqueue.addLast(fstack.removeFirst());
      divtokens.add(op);
      continue;
    }

    Value left = fstack.removeFirst();
    Value right = fstack.removeFirst();

    fstack.addFirst(_evalMultiplication(left, right, op));
  }

  divqueue.add(fstack.removeFirst());

  Value divaccum = divqueue.removeFirst();

  for (int i = 0; i < divqueue.length; i++) {
    divaccum = _evalDivision(divaccum, divqueue.elementAt(i), divtokens.elementAt(i));
  }

  return divaccum;
}

Value _evalMultiplication(Value left, Value right, Token op) {
  if (left.type == ValType.S && right.type == ValType.S) {
    return new Value.scalar((left.svalue * right.svalue).reduce());
  }

  if (left.type == ValType.S && right.type == ValType.M) {
    return new Value.matrix(right.mvalue.scale(left.svalue));
  }

  if (left.type == ValType.M && right.type == ValType.S) {
    return new Value.matrix(left.mvalue.scale(right.svalue));
  }

  if (left.mvalue.cols != right.mvalue.rows) {
    throw new EvaluationException("cannot multiply a ${left.mvalue.rows}x${left.mvalue.cols} matrix by a ${right.mvalue.rows}x${right.mvalue.cols} matrix", op);
  }

  return new Value.matrix(left.mvalue * right.mvalue);
}

Value _evalDivision(Value left, Value right, Token op) {
  if (left.type == ValType.S && right.type == ValType.S) {
    return new Value.scalar((left.svalue * right.svalue.reciprocal()).reduce());
  }

  if (left.type == ValType.S && right.type == ValType.M) {
    throw new EvaluationException("cannot divide a scalar by a matrix", op);
  }

  if (left.type == ValType.M && right.type == ValType.S) {
    return new Value.matrix(left.mvalue.scale(right.svalue.reciprocal()));
  }

  throw new EvaluationException("cannod divide two matrices", op);
}

Value _evalFactor(FactorNode fnode, Environment env) {
  Value val = _evalFactorIgnoreNeg(fnode, env);

  if (fnode.neg != null) {
    if (val.type == ValType.M) {
      val.mvalue = val.mvalue.scale(new Fraction.fromScalar(-1));
    } else {
      val.svalue = val.svalue.negate();
    }
  }

  return val;
}

Value _evalFactorIgnoreNeg(FactorNode fnode, Environment env) {
  if (fnode is NumFactorNode) {
    return _evalNumFactor(fnode, env);
  }

  if (fnode is ParenFactorNode) {
    return _evalParenFactor(fnode, env);
  }

  if (fnode is FuncFactorNode) {
    return _evalFuncFactor(fnode, env);
  }

  if (fnode is VarFactorNode) {
    return _evalVarFactor(fnode, env);
  }

  throw new StateError("SHOULDN'T BE ANOTHER TYPE OF FACTORNODE");
}

Value _evalNumFactor(NumFactorNode fnode, Environment env) {
  return new Value.scalar(new Fraction.fromScalar(int.parse(fnode.number.literal)));
}

Value _evalParenFactor(ParenFactorNode fnode, Environment env) {
  return _evalExpr(fnode.expr, env);
}

Value _evalVarFactor(VarFactorNode fnode, Environment env) {
  if (fnode.variable.type == TokenType.MVAR) {
    int v = fnode.variable.literal.runes.first;
    return new Value.matrix(env.getMVar(new Variable(v)));
  }

  if (fnode.variable.type == TokenType.SVAR) {
    int v = fnode.variable.literal.runes.first;
    return new Value.scalar(env.getSVar(new Variable(v)));
  }

  if (fnode.variable.type == TokenType.DSVAR) {
    int v = fnode.variable.literal.runes.elementAt(1);

    Fraction s = env.definedScalars[fnode.variable];
    env.setSVar(new Variable(v), s);

    return new Value.scalar(s);
  }

  if (fnode.variable.type == TokenType.DMVAR) {
      int v = fnode.variable.literal.runes.elementAt(1);

      Matrix m = env.definedMatrices[fnode.variable];
      env.setMVar(new Variable(v), m);

      return new Value.matrix(m);
  }

  return new Value.matrix(env.definedMatrices[fnode.variable]);
}

Value _evalFuncFactor(FuncFactorNode fnode, Environment env) {
  List<Value> args = fnode.args.map((arg) => _evalExpr(arg, env)).toList();
  return callFunction(fnode.function, args);
}