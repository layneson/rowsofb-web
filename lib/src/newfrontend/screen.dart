import "dart:html" as html;

import "package:rowsofb/src/newfrontend/metrics.dart";
import "package:rowsofb/src/newfrontend/components.dart";

class Screen {
  html.CanvasRenderingContext2D _ctx;
  int _pwidth, _pheight;
  int _cwidth, _cheight;
  int _gwidth, _gheight;

  Font _font;
  FontMetrics _fontMetrics;

  List<Component> _components;
  Component _active;

  Screen(html.CanvasElement canvas) {
    _ctx = canvas.getContext("2d");

    _pwidth = canvas.width;
    _pheight = canvas.height;

    _font = new Font("monospace", 40);
    _fontMetrics = new FontMetrics(_font);

    _cwidth = _fontMetrics.width;
    _cheight = _fontMetrics.height;

    _gwidth = _pwidth ~/ _cwidth;
    _gheight = _pheight ~/ _cheight;
  }

  void addComponent(Component c) {
    _components.add(c);
  }

  void setActive(Component c) {
    _active = c;
  }

  void render() {
    _components.forEach((c) {
      
    });
  }

}