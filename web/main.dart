import "dart:html" as html;
import "package:rowsofb/lang.dart";
import "package:rowsofb/src/env/env.dart";
import "package:rowsofb/math.dart";

Environment env = new Environment();

main() {
  print("main");
  html.window.onLoad.listen((_) => start());
}

start() {
  print("start");
  html.querySelector("#expression").onKeyDown.listen((ev) {
    if (ev.keyCode == html.KeyCode.ENTER) {
      ev.preventDefault();

      var expr = ev.target as html.InputElement;

      try {
        hideError();
        hideResult();
        hideInputs();

        if (expr.value.trim().isEmpty) {
          displayError("empty input", 0, 1);
          return;
        }

        var tokens = lex(expr.value.trim());
        var enode = parse(tokens);

        List<MatrixInput> inputs = [];

        var inputsDiv = html.querySelector("#inputs");

        for (Token tok in tokens) {
          if (tok.type == TokenType.DMVAR || tok.type == TokenType.DAMVAR) {
            MatrixInput mi = new MatrixInput(tok);
            mi.render();

            inputsDiv.appendText(tok.literal + " =");
            inputsDiv.append(mi.table);

            if (!inputs.isEmpty) {
              inputs.last.next = mi;
            }

            inputs.add(mi);
          }
        }

        if (inputs.isEmpty) {
          try {
            var result = evaluate(enode, env);

            displayResult(result);

            expr.value = "";
          } on EvaluationException catch (e) {
            displayError(e.message, e.badToken.start, e.badToken.end);
          }
        } else {
          inputs.last.finished = () {
            try {
              env.definedMatrices.clear();

              for (MatrixInput mi in inputs) {
                try {
                  env.definedMatrices[mi.tok] = mi.toMatrix();
                } on Exception {
                  expr.focus();
                  return;
                }
              }

              var result = evaluate(enode, env);

              hideInputs();

              print(result);
              displayResult(result);

              expr.value = "";
              expr.focus();
            } on EvaluationException catch (e) {
              displayError(e.message, e.badToken.start, e.badToken.end);
            }
          };

          showInputs();

          inputs.first.boxes[0].focus();
        }
      } on LexException catch (e) {
        displayError(e.message, e.position, e.position + 1);
      } on ParseException catch (e) {
        displayError(e.message, e.badToken.start, e.badToken.end);
      }
    }
  });
}

void displayError(String message, int start, int end) {
  var ediv = html.querySelector("#errors");
  ediv.style.display = "block";

  ediv.text = "Error: $message.";
}

void hideError() {
  var ediv = html.querySelector("#errors");
  ediv.text = "";
  ediv.style.display = "none";
}

void displayResult(Value val) {
  var rdiv = html.querySelector("#results");
  rdiv.style.display = "block";

  if (val.type == ValType.S)
    rdiv.text = val.toString();
  else
    rdiv.append(renderMatrix(val.mvalue));
}

html.Element renderMatrix(Matrix m) {
  var table = html.document.createElement("table");
  table.classes.add("mresult");
  table.classes.add("matrix");

  for (int r = 0; r < m.rows; r++) {
    var row = html.document.createElement("tr");

    for (int c = 0; c < m.cols; c++) {
      var cell = html.document.createElement("td");

      cell.text = m.get(r + 1, c + 1).toString();

      row.append(cell);
    }

    table.append(row);
  }

  return table;
}

void hideResult() {
  var rdiv = html.querySelector("#results");
  rdiv.text = "";
  rdiv.style.display = "none";
}

class MatrixInputAction {
}

class MatrixInputActionMove extends MatrixInputAction {
  int r, c;

  MatrixInputActionMove(int r, int c) : this.r = r, this.c = c;
}

class MatrixInputActionNewCol extends MatrixInputActionMove {
  int ncol;

  MatrixInputActionNewCol(int r, int c, int ncol) : super(r, c), this.ncol = ncol;
}

class MatrixInputActionNewRow extends MatrixInputActionMove {
  int nrow;

  MatrixInputActionNewRow(int r, int c, int nrow) : super(r, c), this.nrow = nrow;
}

class MatrixInput {
  Token tok;
  html.Element table;

  int rows, cols;

  List<html.Element> boxes = [];

  MatrixInput next = null;
  Function finished;

  List<MatrixInputAction> undoStack = [];

  MatrixInput(Token tok) : this.tok = tok {
    table = html.document.createElement("table");
    table.classes.add("minput");
    table.classes.add("matrix");

    rows = 1;
    cols = 1;

    boxes.add(_createBox(0, 0));
  }

  html.Element _createBox(int r, int c) {
    int rr = r;
    int cc = c;

    var box = html.document.createElement("span");
    box.attributes["contenteditable"] = "true";
    box.classes.add("minput-box");

    box.onKeyDown.listen((ev) {
      handleInput(ev, rr, cc);
    });

    return box;
  }

  void render() {
    table.children.clear();

    for (int r = 0; r < rows; r++) {
      var row = html.document.createElement("tr");

      for (int c = 0; c < cols; c++) {
        var cell = html.document.createElement("td");

        cell.append(boxes[r * cols + c]);
        row.append(cell);
      }

      table.append(row);
    }
  }

  void handleInput(html.KeyEvent ev, int r, int c) {
    if (ev.keyCode == html.KeyCode.TAB) {
      ev.preventDefault();

      if (c + 1 == cols) {
        List<html.Element> newBoxes = [];

        cols++;

        for (int rr = 0; rr < rows; rr++) {
          for (int cc = 0; cc < cols; cc++) {
            if (cc + 1 == cols) {
              newBoxes.add(_createBox(rr, cc));
            } else {
              newBoxes.add(boxes[rr * (cols - 1) + cc]);
            }
          }
        }

        boxes = newBoxes;
        render();

        boxes[c + 1].focus();

        undoStack.add(new MatrixInputActionNewCol(r, c, c + 1));
      } else {
        boxes[r * cols + c + 1].focus();

        undoStack.add(new MatrixInputActionMove(r, c));
      }
    } else if (ev.keyCode == html.KeyCode.ENTER) {
      ev.preventDefault();

      if (ev.ctrlKey) {
        if (next != null) {
          next.boxes[0].focus();
        } else {
          finished();
        }

        return;
      }

      if (r + 1 == rows) {

        rows++;

        for (int i = 0; i < cols; i++) {
          boxes.add(_createBox(r + 1, i));
        }

        render();

        boxes[(r + 1) * cols].focus();

        undoStack.add(new MatrixInputActionNewRow(r, c, r + 1));
      } else {

        boxes[(r + 1) * cols + c].focus();

        undoStack.add(new MatrixInputActionMove(r, c));
      }
    } else if (ev.keyCode == html.KeyCode.BACKSPACE) {
      if (boxes[r * cols + c].text.trim().isNotEmpty || undoStack.isEmpty) {
        return;
      }

      ev.preventDefault();

      if (undoStack.last is MatrixInputActionNewCol) {
        MatrixInputActionNewCol lncol = undoStack.removeLast();

        List<html.Element> newBoxes = [];

        for (int rr = 0; rr < rows; rr++) {
          for (int cc = 0; cc < cols; cc++) {
            html.Element box = boxes[rr * cols + cc];

            if (cc != lncol.ncol) {
              newBoxes.add(box);
            }
          }
        }

        boxes = newBoxes;

        cols--;

        render();

        focusEndOfContenteditable(boxes[lncol.r * cols + lncol.c]..focus());
      } else if (undoStack.last is MatrixInputActionNewRow) {
        MatrixInputActionNewRow lnrow = undoStack.removeLast();

        for (int cc = 0; cc < cols; cc++) {
          boxes.removeLast();
        }

        rows--;

        render();
        
        focusEndOfContenteditable(boxes[lnrow.r * cols + lnrow.c]..focus());
      } else if (undoStack.last is MatrixInputActionMove) {
        MatrixInputActionMove lnmove = undoStack.removeLast();

        focusEndOfContenteditable(boxes[lnmove.r * cols + lnmove.c]..focus());
      }
    }
  }

  Matrix toMatrix() {
    List<Fraction> vals = [];

    for (html.Element box in boxes) {
      var sval = box.text;

      if (sval.trim().isEmpty) {
        sval = "0";
      }

      try {
        Fraction f = new Fraction.parseFraction(sval);

        vals.add(f);
      } on Exception {
        hideInputs();
        hideResult();
        displayError("invalid matrix input", 0, 1);
        throw new Exception();
      }
    }

    return new Matrix.fromValues(rows, cols, vals);
  }
}

void showInputs() {
  html.querySelector("#inputs").style.display = "block";
}

void hideInputs() {
  html.querySelector("#inputs")
    ..children.clear()
    ..style.display = "none";
}

void focusEndOfContenteditable(html.Element e) {
  html.Range r = html.document.createRange();
  r.selectNodeContents(e);
  r.collapse(false);
  html.Selection s = html.window.getSelection();
  s.removeAllRanges();
  s.addRange(r);
}