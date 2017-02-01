import "package:rowsofb/src/env/env.dart";
import "package:rowsofb/src/math/matrix.dart";
import "package:rowsofb/src/lang/lex.dart";

class FunctionException implements Exception {
  String message;
  
  FunctionException(this.message);
}

class _Function {
  String name;
  String description;
  List<ValType> argTypes = [];
  List<String> argNames = [];
  List<String> argDescriptions = [];
  Function handler;

  Value handle(List<Value> args) {
    return handler(args);
  }

  String signature() {
    String s = "$name(";

    for (int i = 0; i < argTypes.length; i++) {
      if (argTypes[i] == ValType.M) {
        s += "Matrix ";
      } else {
        s += "Scalar ";
      }

      s += "<${argNames[i]}>, ";
    }

    s = s.substring(0, s.length - 2) + ")";

    return s;
  }
}

class _FunctionBuilder {
  _Function func = new _Function();

  set name(String n) => func.name = n;
  set description(String d) => func.description = d;

  set arg(_FunctionArgBuilder b) {
    func.argTypes.add(b.type);
    func.argNames.add(b.name);
    func.argDescriptions.add(b.description);
  }

  set handler(Function f) => func.handler = f;
}

class _FunctionArgBuilder {
  ValType type;
  String name;
  String description;
}

Map<String, _Function> _functions = {
  "ident": (new _FunctionBuilder()
    ..name = "ident"
    ..description = "creates an indentity matrix"
    ..arg = (new _FunctionArgBuilder()
      ..type = ValType.S
      ..name = "size"
      ..description = "The size of the identity matrix. An error occurs if <size> < 1 or <size> > 100. If <size> is not an integer, it is rounded down.")
    ..handler = (List<Value> args) {
      if (!args[0].svalue.isPositive() || args[0].svalue.isZero()) {
        throw new FunctionException("<size> must be greater than zero");
      }

      if (args[0].svalue.toInt() > 100 || args[0].svalue.toInt() > 100) {
        throw new FunctionException("<size> must be less 100");
      }

      return new Value.matrix(new Matrix.identity(args[0].svalue.toInt()));
  }).func,

  "ref": (new _FunctionBuilder()
    ..name = "ref"
    ..description = "reduces a matrix to row echelon form"
    ..arg = (new _FunctionArgBuilder()
      ..type = ValType.M
      ..name = "m"
      ..description = "The matrix to reduce.")
    ..handler = (List<Value> args) {
      return new Value.matrix(args[0].mvalue.ref());
  }).func,

  "rref": (new _FunctionBuilder()
    ..name = "rref"
    ..description = "reduces a matrix to reduced row echelon form"
    ..arg = (new _FunctionArgBuilder()
      ..type = ValType.M
      ..name = "m"
      ..description = "The matrix to reduce.")
    ..handler = (List<Value> args) {
      return new Value.matrix(args[0].mvalue.rref());
  }).func,
};

Value callFunction(Token ftoken, List<Value> args) {
  if (!_functions.containsKey(ftoken.literal.toLowerCase())) {
    throw new EvaluationException("unknown function", ftoken);
  }

  _Function func = _functions[ftoken.literal.toLowerCase()];

  for (int i = 0; i < func.argTypes.length; i++) {
    if (args[i].type != func.argTypes[i]) {
      throw new EvaluationException("function ${func.signature()} expected different arguments", ftoken);
    }
  }

  try {
    return func.handle(args);
  } on FunctionException catch (e) {
    throw new EvaluationException("function ${func.name} failed: ${e.message}", ftoken);
  }
}