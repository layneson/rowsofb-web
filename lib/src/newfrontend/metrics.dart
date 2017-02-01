import "dart:html" as html;

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