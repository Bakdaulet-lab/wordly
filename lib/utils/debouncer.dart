import 'dart:async';

/// Prevents rapid repeated calls by enforcing a cooldown period.
///
/// Usage:
/// ```dart
/// final debouncer = Debouncer(delay: Duration(milliseconds: 500));
/// debouncer.run(() => doExpensiveWork());
/// ```
///
/// For async operations that return a value, use [guard]:
/// ```dart
/// final result = await debouncer.guard(() => submitAnswer());
/// if (result == null) print('Debounced — skipped');
/// ```
class Debouncer {
  final Duration delay;
  Timer? _timer;
  bool _inCooldown = false;
  DateTime? _lastCallTime;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// Whether a call is currently being debounced / cooled down.
  bool get isDebouncing => _inCooldown;

  /// Cancel any pending debounced call and reset cooldown.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _inCooldown = false;
  }

  /// Run [action] after the debounce [delay], cancelling any prior pending call.
  ///
  /// This is the classic "trailing-edge" debounce: if [run] is called again
  /// before [delay] elapses, the previous call is cancelled and the timer
  /// restarts.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      action();
      _timer = null;
    });
  }

  /// Execute [action] immediately but prevent further calls for [delay].
  ///
  /// This is a "leading-edge" throttle: the first call goes through
  /// instantly, and subsequent calls within the cooldown window are ignored.
  /// Returns `true` if the action was executed, `false` if debounced.
  bool runImmediate(void Function() action) {
    if (_inCooldown) return false;

    _inCooldown = true;
    _lastCallTime = DateTime.now();
    action();

    _timer?.cancel();
    _timer = Timer(delay, () {
      _inCooldown = false;
      _timer = null;
    });

    return true;
  }

  /// Guard an async [action] with leading-edge throttle.
  ///
  /// Returns the result of [action] if it was allowed to execute,
  /// or `null` if the call was debounced away.
  Future<T?> guard<T>(Future<T> Function() action) async {
    if (_inCooldown) return null;

    _inCooldown = true;
    _lastCallTime = DateTime.now();

    try {
      return await action();
    } finally {
      _timer?.cancel();
      _timer = Timer(delay, () {
        _inCooldown = false;
        _timer = null;
      });
    }
  }

  /// Time elapsed since the last successful call, or `null` if never called.
  Duration? get timeSinceLastCall {
    if (_lastCallTime == null) return null;
    return DateTime.now().difference(_lastCallTime!);
  }

  /// Dispose the debouncer — cancel any pending timer.
  void dispose() {
    cancel();
  }
}
