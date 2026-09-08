import 'dart:async';

/// A value that can be read now and watched for changes.
///
/// Every `watch*` method in `package:on_go_shared` is a Stream that has to
/// replay its current value to a new listener — a screen that subscribes after
/// the data changed must not sit empty waiting for the next change. This is
/// that behaviour, in one place, so the local services do not each reinvent it.
///
/// It also matches how the networked implementations will behave: fetch once,
/// then apply pushes.
class LiveValue<T> {
  LiveValue(this._value);

  T _value;
  final StreamController<T> _controller = StreamController<T>.broadcast();

  T get value => _value;

  /// Publishes [next] to every listener.
  void set(T next) {
    _value = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  /// Recomputes and publishes — for state held elsewhere, where the value is
  /// derived rather than assigned.
  void refresh(T Function() compute) => set(compute());

  /// The current value, then every change.
  Stream<T> get stream async* {
    yield _value;
    yield* _controller.stream;
  }

  Future<void> dispose() => _controller.close();
}
