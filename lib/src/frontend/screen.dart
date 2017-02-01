import "dart:html" as html;

class ScreenCell {
  int value;
  String color;

  ScreenCell(this.value);
  ScreenCell.withColor(int value, String color) : this.value = value, this.color = color;

  @override
  String toString() {
    return new String.fromCharCode(value);
  }
}

class ScreenGrid {
  Map<int, List<ScreenCell>> grid = new Map();

  void setValue(int x, int y, int value) {
    
  }

  void setCell(int x, int y, ScreenCell cell) {
    List<ScreenCell> rowList = grid[y] ?? (grid[y] = new List());
    if (x > rowList.length) {
      for (int i = 0; i < x; i++) {
        rowList.add(new ScreenCell(" ".runes.first));
      }

      rowList.add(cell);
    } else if (x == rowList.length) {
      rowList.add(cell);
    } else {
      rowList[x] = cell;
    }
  }

  void insertCell(int x, int y, ScreenCell cell) {
    List<ScreenCell> rowList = grid[y] ?? (grid[y] = new List());
    if (x > rowList.length) {
      for (int i = 0; i < x; i++) {
        rowList.add(new ScreenCell(" ".runes.first));
      }

      rowList.add(cell);
    } else {
      rowList.insert(x, cell);
    }

    grid[y] = rowList;
  }

  void deleteCell(int x, int y) {
    List<ScreenCell> rowList = grid[y];
    if (rowList == null) {
      return;
    }

    rowList.removeAt(x);
  }

  void deleteLine(int y) {
    grid.remove(y);
  }

  ScreenCell getCell(int x, int y) {
    List<ScreenCell> rowList = grid[y];
    if (rowList == null || x >= rowList.length) {
      return null;
    }

    return rowList[x];
  }

  void clear() {
    grid.clear();
  }

  String getLine(int y) {
    String line = "";

    for(var x = 0; true; x++) {
      var cell = getCell(x, y);
      if (cell == null) {
        break;
      }

      line += new String.fromCharCode(cell.value);
    }

    return line;
  }
}

class Screen {
  ScreenGrid grid = new ScreenGrid();
  int offsetX = 0, offsetY = 0;
  
  Font font;
  FontMetrics metrics;

  int width, height;

  int cellWidth, cellHeight;

  Cursor cursor = new Cursor(0, 0);

  Screen(html.CanvasRenderingContext2D ctx) {
    font = new Font("monospace", 40);
    metrics = new FontMetrics(font);
    cellWidth = metrics.width;
    cellHeight = metrics.height;
  }

  void update(num delta) {    
    cursor.update(delta);
  }

  void render(html.CanvasRenderingContext2D ctx, int width, int height) {
    ctx.textBaseline = "top";
    ctx.font = font.toString();

    ctx.fillStyle = "#d8d8d8";
    ctx.fillRect(0, 0, width, height);

    var gWidth = width ~/ cellWidth, gHeight = height ~/ cellHeight;

    this.width = gWidth;
    this.height = gHeight;

    if (cursor.x >= offsetX + gWidth) {
      offsetX = cursor.x - gWidth + 1;
    }

    if (cursor.x <= offsetX) {
      offsetX = offsetX - gWidth > 0 ? offsetX - gWidth : 0;
    }

    if (cursor.y < offsetY) {
      offsetY = cursor.y - 1 > 0 ? cursor.y - 1 : 0;
    }

    if (cursor.y >= offsetY + gHeight) {
      offsetY = cursor.y - gHeight + 1;
    }

    ctx.save();

    ctx.translate(-offsetX*cellWidth, -offsetY*cellHeight);

    for (var x = offsetX; x < gWidth+offsetX; x++) {
      for (var y = offsetY; y < gHeight+offsetY; y++) {
        ctx.fillStyle = grid.getCell(x, y)?.color ?? "black";
        ctx.fillText(grid.getCell(x, y)?.toString() ?? " ", x*cellWidth, y*cellHeight);

        if (cursor.x == x && cursor.y == y && cursor.visible) {
          ctx.fillStyle = "rgba(0, 86, 226, ${cursor.alpha})";
          ctx.fillRect(x*cellWidth, y*cellHeight + metrics.baseline + 2, cellWidth, 4);
        }
      }
    }

    ctx.restore();
  }


}

class Cursor {
  int x, y;

  bool animated = false;
  bool visible = true;
  num alpha = 1;

  static final num TIME_TO_FULL = 250;
  static final num TIME_TO_HOLD = 300;
  static final num TIME_TO_FALL = 250;
  static final num TOTAL = TIME_TO_FULL + TIME_TO_HOLD + TIME_TO_FALL + TIME_TO_HOLD;


  void update(num delta) {
    if (!animated) {
      alpha = 1;
      return;  
    };

    num time = delta % TOTAL;

    if (time < TIME_TO_FULL) {
      alpha = 1.0 - (TIME_TO_FULL - time) / TIME_TO_FULL;
      return;
    } 
    
    if (time < TIME_TO_FULL + TIME_TO_HOLD) {
      alpha = 1;
      return;
    }
    
    if (time < TIME_TO_FULL + TIME_TO_HOLD + TIME_TO_FALL) {
      alpha = 1.0 - (time - TIME_TO_FULL - TIME_TO_HOLD) / TIME_TO_FALL;
      return;
    }

    if (time < TOTAL) {
      alpha = 0;
    }
  }

  Cursor(this.x, this.y);
}

class Font {
  String family;
  int size;

  Font(this.family, this.size);

  @override
  String toString() {
    return "${size}px '$family'";
  }
}

class FontMetrics {
  Font font;

  int width, height, baseline;

  FontMetrics(Font f) {
    font = f;

    var fakeLine = html.document.createElement("div");
    fakeLine.style
      ..position = "absolute"
      ..whiteSpace = "nowrap"
      ..font = f.toString();
    html.document.body.append(fakeLine);

    fakeLine.innerHtml = "m";
    width = fakeLine.offsetWidth;
    height = fakeLine.offsetHeight;

    var fakeSpan = html.document.createElement("span");
    fakeSpan.style
      ..display = "inline-block"
      ..overflow = "hidden"
      ..width = "1px"
      ..height = "1px";
    fakeLine.append(fakeSpan);

    baseline = fakeSpan.offsetTop + fakeSpan.offsetHeight;

    fakeLine.remove();
  }
}