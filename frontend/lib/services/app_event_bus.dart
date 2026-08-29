import 'dart:async';

class AppEventBus {
  static final AppEventBus _instance = AppEventBus._internal();

  factory AppEventBus() => _instance;

  AppEventBus._internal();

  final StreamController<AppAppEvent> _controller = StreamController<AppAppEvent>.broadcast();

  Stream<AppAppEvent> get stream => _controller.stream;

  void emit(AppAppEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}

class AppAppEvent {
  final String type;
  final Map<String, dynamic>? payload;

  const AppAppEvent(this.type, {this.payload});
}
