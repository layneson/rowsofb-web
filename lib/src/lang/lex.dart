

enum TokenType {
  EOF,
  
  PLUS,
  MINUS,
  MULT,
  DIV,

  ARROW,
  COMMA,

  LPAREN,
  RPAREN,

  NUM,
  FUNC,

  MVAR,
  SVAR,
  DMVAR,
  DSVAR,
  DAMVAR
}

class Token {
  TokenType type;
  String literal;
  int start;
  int end;

  Token(this.type, this.literal, this.start, this.end);

  @override
  String toString() {
    String typeName = type.toString().split(".")[1];
    return "<${typeName}:\"$literal\"@$start>";
  }

  @override
  bool operator ==(Token t) {
    return toString() == t.toString();
  }
}

class _Lexer {
  List<int> data;
  int start = 0, current = 0;

  _Lexer(this.data);

  bool hasData() {
    return current < data.length;
  }

  int peek() {
    if (current >= data.length) {
      return 0;
    }

    return data[current];
  }

  int forward() {
    int r = peek();

    if (r == 0) {
      return r;
    }

    current++;
    return r;
  }

  void reset() {
    current = start;
  }

  Token match(TokenType type) {
    Token result = new Token(type, new String.fromCharCodes(data.getRange(start, current)), start, current);
    start = current;
    return result;
  }

  void consume() {
    start = current;
  }
}

class LexException implements Exception {
  String message;
  int position;

  LexException(this.message, this.position);
}

/// Takes a line of text and parses it into tokens.
/// 
/// Throws an Exception if the input is invalid.
List<Token> lex(String data) {
  List<Token> tokens = new List();

  _Lexer lex = new _Lexer(data.runes.toList());

  while (lex.hasData()) {
    if (_runeMatchesWhitespace(lex.peek())) {
      lex.forward();
      lex.consume();
      continue;
    }

    if (lex.peek() == _rune("+")) {
      lex.forward();
      tokens.add(lex.match(TokenType.PLUS));
      continue;
    }
    if (lex.peek() == _rune("-")) {
      lex.forward();
      if (lex.peek() == _rune(">")) {
        lex.forward();
        tokens.add(lex.match(TokenType.ARROW));
      } else {
        tokens.add(lex.match(TokenType.MINUS));
      }
      continue;
    }
    if (lex.peek() == _rune("*")) {
      lex.forward();
      tokens.add(lex.match(TokenType.MULT));
      continue;
    }
    if (lex.peek() == _rune("/")) {
      lex.forward();
      tokens.add(lex.match(TokenType.DIV));
      continue;
    }
    if (lex.peek() == _rune("(")) {
      lex.forward();
      tokens.add(lex.match(TokenType.LPAREN));
      continue;
    }
    if (lex.peek() == _rune(")")) {
      lex.forward();
      tokens.add(lex.match(TokenType.RPAREN));
      continue;
    }
    if (lex.peek() == _rune(",")) {
      lex.forward();
      tokens.add(lex.match(TokenType.COMMA));
      continue;
    }

    if (_matchesNumber(lex)) {
      tokens.add(lex.match(TokenType.NUM));
      continue;
    }

    if (_matchesFunction(lex)) {
      tokens.add(lex.match(TokenType.FUNC));
      continue;
    } else {
      lex.reset();
    }

    if (lex.peek() == _rune("\$")) {
      lex.forward();

      if (_runeMatchesUppercase(lex.peek())) {
        lex.forward();

        tokens.add(lex.match(TokenType.DMVAR));
        continue;
      }

      if (_runeMatchesLowercase(lex.peek())) {
        // lex.forward();

        // tokens.add(lex.match(TokenType.DSVAR));
        // continue;

        throw new LexException("scalar variables cannot be defined", lex.current);
      }

      if (lex.peek() == _rune("\$")) {
        lex.forward();

        tokens.add(lex.match(TokenType.DAMVAR));
        continue;
      }

      lex.reset();
    }

    if (_runeMatchesUppercase(lex.peek())) {
      lex.forward();

      tokens.add(lex.match(TokenType.MVAR));
      continue;
    }

    if (_runeMatchesLowercase(lex.peek())) {
      lex.forward();

      tokens.add(lex.match(TokenType.SVAR));
      continue;
    }

    throw new LexException("unrecognized token", lex.start);
  }

  tokens.add(new Token(TokenType.EOF, "", lex.start-1, lex.start));

  return tokens;
}

int _rune(String s) {
  return s.runes.first;
}

bool _runeMatchesWhitespace(int r) {
  return " \t\n\r".runes.contains(r);
}

bool _runeMatchesNumber(int r) {
  return r >= _rune("0") && r <= _rune("9");
}

bool _runeMatchesUppercase(int r) {
  return r >= _rune("A") && r <= _rune("Z");
}

bool _runeMatchesLowercase(int r) {
  return r >= _rune("a") && r <= _rune("z");
}

bool _runeMatchesLetter(int r) {
  return _runeMatchesUppercase(r) || _runeMatchesLowercase(r);
}


bool _matchesNumber(_Lexer lex) {
  if (!_runeMatchesNumber(lex.peek())) {
    return false;
  } 

  lex.forward();

  while (_runeMatchesNumber(lex.peek())) {
    lex.forward();
  }

  return true;
}

bool _matchesFunction(_Lexer lex) {
  if (!_runeMatchesLetter(lex.peek())) {
    return false;
  }

  lex.forward();

  if (!_runeMatchesLetter(lex.peek())) {
    return false;
  }

  lex.forward();

  while (_runeMatchesLetter(lex.peek())) {
    lex.forward();
  }

  return true;
}