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

Input eventToInput(html.KeyboardEvent event) {
  if (controlKeys.contains(event.keyCode)) {
    return new ControlInput(event);
  }

  if (symbolCodes.runes.contains(event.charCode)) {
    return new SymbolInput(event);
  }

  return null;
}