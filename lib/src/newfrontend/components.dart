import "package:rowsofb/src/newfrontend/screen.dart";
import "package:rowsofb/src/newfrontend/input.dart";

/// The building block of visible items on the [Screen].
abstract class Component {
  int _x, _y;

  void onActive(Component last, dynamic init);
  void onInput(Input input);
}