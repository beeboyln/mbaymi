// Web implementation: listens to window messages posted from index.html shim.
import 'dart:html' as html;

void addVisualViewportListener(void Function(double height, double offsetTop) callback) {
  html.window.onMessage.listen((html.MessageEvent e) {
    try {
      final data = e.data;
      if (data is Map) {
        if (data['type'] == 'visualViewport') {
          final h = (data['height'] is num) ? (data['height'] as num).toDouble() : double.tryParse(data['height'].toString()) ?? 0.0;
          final off = (data['offsetTop'] is num) ? (data['offsetTop'] as num).toDouble() : double.tryParse(data['offsetTop'].toString()) ?? 0.0;
          callback(h, off);
        }
      }
    } catch (err) {
      // ignore parse errors
    }
  });
}
