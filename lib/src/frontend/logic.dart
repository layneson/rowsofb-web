import "package:rowsofb/src/frontend/screen.dart";
import "package:rowsofb/src/frontend/colors.dart";
import "package:rowsofb/lang.dart";
import "package:rowsofb/src/env/env.dart";
import "package:rowsofb/math.dart";

import "dart:html" as html;

class Input {
  html.KeyboardEvent event;

  Input(this.event);
}

class ControlInput extends Input {
  ControlInput(html.KeyboardEvent event) : super(event);

  int get keyCode => event.keyCode;
  bool get shiftKey => event.shiftKey;
}

class SymbolInput extends Input {
  SymbolInput(html.KeyboardEvent event) : super(event);

  int get charCode => event.charCode;
}

final List<int> controlKeys = const [
  html.KeyCode.ENTER,
  html.KeyCode.BACKSPACE,
  html.KeyCode.DELETE,
  html.KeyCode.LEFT,
  html.KeyCode.RIGHT,
  html.KeyCode.TAB
];

final String symbolCodes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 +-/*()\$>";

Input eventToItem(html.KeyboardEvent event) {
  if (controlKeys.contains(event.keyCode)) {
    return new ControlInput(event);
  }

  if (symbolCodes.runes.contains(event.charCode)) {
    return new SymbolInput(event);
  }

  return null;
}

// enum CalculatorState {
//   INPUT,
//   ERROR,
//   OUTPUT,
//   DEFINE_SCALAR,
//   DEFINE_MATRIX,
// }

/// The backend to the [Screen].
class Calculator {
  State _state;

  Environment env;

  Screen screen;

  Calculator(this.screen) {
    _state = new InputState(this);

    _state.enter(null, null);

    env = new Environment();
  }

  void handleInput(Input input) {
    _state.handleInput(input);
  }

  void switchState(State newState, dynamic inheritance) {
    newState.enter(_state, inheritance);
    _state = newState;
  }
}

abstract class State {
  Calculator calc;

  State(this.calc);

  void enter(State lastState, dynamic inheritance);
  void handleInput(Input input);
}

class InputState extends State {
  Screen screen;

  InputState(Calculator calc) : super(calc) {
    screen = calc.screen;
  }

  void enter(State lastState, dynamic inheritance) {
    screen.cursor
      ..visible = true
      ..animated = true
      ..x = 0;
  }

  void handleInput(Input input) {
    if (input is SymbolInput) {
      screen.grid.insertCell(screen.cursor.x, screen.cursor.y, new ScreenCell(input.charCode));
      screen.cursor.x++;
      return;
    }

    var cinput = input as ControlInput;

    if (cinput.keyCode == html.KeyCode.BACKSPACE) {
      if (screen.cursor.x == 0) {
        return;
      }

      screen.grid.deleteCell(screen.cursor.x-1, screen.cursor.y);
      screen.cursor.x--;
      return;
    }

    if (cinput.keyCode == html.KeyCode.DELETE) {
      if (screen.grid.getCell(screen.cursor.x, screen.cursor.y) == null) {
        return;
      }

      screen.grid.deleteCell(screen.cursor.x, screen.cursor.y);
      return;
    }

    if (cinput.keyCode == html.KeyCode.LEFT) {
      if (screen.cursor.x == 0) {
        return;
      }

      screen.cursor.x--;
      return;
    }

    if (cinput.keyCode == html.KeyCode.RIGHT) {
      if (screen.grid.getCell(screen.cursor.x, screen.cursor.y) != null) {
        screen.cursor.x++;
        return;
      }
    }

    if (cinput.keyCode == html.KeyCode.ENTER) {
      String line = screen.grid.getLine(screen.cursor.y).trim();
      if (line.isEmpty) {
        return;
      }

      try {
        var tokens = lex(line);
        var reqs = _parseRequests(tokens);

        calc.switchState(new DefinitionState(calc, tokens, reqs), null);
        return;
      } on Exception catch (e) {
        screen.cursor.y++;
        screen.cursor.x = 0;
        calc.switchState(new ErrorState(calc), e);
        return;
      }
    }
  }
}

List<_DefinitionRequest> _parseRequests(List<Token> tokens) {
  List<_DefinitionRequest> reqs = [];

  for (Token tok in tokens) {
    if (tok.type == TokenType.DSVAR) {
      reqs.add(new _ScalarDefinitionRequest(tok.literal.runes.elementAt(1)));
    } else if (tok.type == TokenType.DMVAR) {
      reqs.add(new _MatrixDefinitionRequest(tok.literal.runes.elementAt(1)));
    } else if (tok.type == TokenType.DAMVAR) {
      reqs.add(new _AnonMatrixDefinitionRequest());
    }
  }

  return reqs;
}

class ErrorState extends State {
  Screen screen;
  int _lines;

  ErrorState(Calculator calc) : super(calc), screen = calc.screen;

  /// Expects the cursor to be pre-positioned.
  void enter(State lastState, dynamic inheritance) {
    calc.screen.cursor.animated = false;

    String message;
    int start, end;

    if (inheritance is LexException) {
      message = inheritance.message;
      start = inheritance.position;
      end = start + 1;
    } else if (inheritance is ParseException || inheritance is EvaluationException) {
      message = inheritance.message;
      start = inheritance.badToken.start;
      end = inheritance.badToken.end;
    }

    for (int i = start; i < end; i++) {
      screen.grid.getCell(i, screen.cursor.y - 1).color = INPUT_RED;
    }

    _lines = 1;

    for (int w = 0; w < message.split(" ").length; w++) {
      String word = message.split(" ")[w];

      if (screen.cursor.x + word.runes.length > screen.width) {
        screen.cursor.y++;
        _lines++;
        screen.cursor.x = 0;
      }

      for (int i = 0; i < word.runes.length; i++) {
        screen.grid.setCell(screen.cursor.x++, screen.cursor.y, new ScreenCell.withColor(word.runes.elementAt(i), INPUT_RED));
      }

      if (w + 1 != message.split(" ").length) {
        if (screen.cursor.x + 1 > screen.width) {
          screen.cursor.y++;
        }

        screen.grid.setCell(screen.cursor.x++, screen.cursor.y, new ScreenCell(" ".runes.first));
      }
    }

    screen.cursor.y -= _lines - 1;
    screen.cursor.x = 0;
  }

  void handleInput(Input input) {
    if (input is ControlInput && input.keyCode == html.KeyCode.ENTER) {
      screen.cursor.y += _lines;
      calc.switchState(new InputState(calc), null);
    }
  }
}

class _DefinitionRequest {

}

class _MatrixDefinitionRequest extends _DefinitionRequest {
  int variable;

  int r, c;
  List<Fraction> values;

  _MatrixDefinitionRequest(this.variable);
}

class _AnonMatrixDefinitionRequest extends _DefinitionRequest {
  int r, c;
  List<Fraction> values;
}

class _ScalarDefinitionRequest extends _DefinitionRequest {
  int variable;

  _ScalarDefinitionRequest(this.variable);
}

class DefinitionState extends State {
  Screen screen;
  List<Token> tokens;
  List<_DefinitionRequest> reqs;

  DefinitionState(Calculator calc, List<Token> tokens, List<_DefinitionRequest> reqs) : super(calc) {
    this.tokens = tokens;
    this.reqs = reqs;

    this.screen = calc.screen;
  }

  void enter(State lastState, dynamic inheritance) {
    screen.cursor
      ..visible = true
      ..animated = true;

    if (reqs[0] is _ScalarDefinitionRequest) {
      _setUpScalar();
    } else {
      _setUpMatrix();
    }
  }

  void handleInput(Input input) {
    if (input is SymbolInput) {
      if (reqs[0] is _ScalarDefinitionRequest) {
        screen.grid.insertCell(screen.cursor.x++, screen.cursor.y, new ScreenCell(input.charCode));
      }

      return;
    }

    var cinput = input as ControlInput;

    if (cinput.keyCode == html.KeyCode.LEFT) {
      if (reqs[0] is _ScalarDefinitionRequest) {
        screen.cursor.x -= screen.cursor.x != 4 ? 1 : 0;
      }

      return;
    }

    if (cinput.keyCode == html.KeyCode.RIGHT) {
      if (reqs[0] is _ScalarDefinitionRequest) {
        screen.cursor.x += screen.grid.getCell(screen.cursor.x, screen.cursor.y) != null ? 1 : 0;
      }

      return;
    }

    if (cinput.keyCode == html.KeyCode.ENTER) {
      if (reqs[0] is _ScalarDefinitionRequest) {
        
      }
    }
  }

  void _setUpScalar() {
    var req = reqs.removeAt(0) as _ScalarDefinitionRequest;

    screen.cursor.x = 0;
    _printAtCursor(screen, new String.fromCharCode(req.variable) + " = ", true);
  }

  void _setUpMatrix() {

  }
}

void _printAtCursor(Screen screen, String message, [bool advanceCursor = false, String color = INPUT_RED]) {
  for (int i = 0; i < message.runes.length; i++) {
    screen.grid.setCell(screen.cursor.x, screen.cursor.y, new ScreenCell.withColor(message.runes.elementAt(i), color));
    screen.cursor.x++;
  }

  if (!advanceCursor) {
    screen.cursor.x -= message.runes.length;
  }
}