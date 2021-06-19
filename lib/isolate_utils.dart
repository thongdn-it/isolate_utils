library isolate_utils;

import 'dart:async';
import 'dart:isolate';

typedef IsolateUtilsCallback<Q, R> = FutureOr<R> Function(Q message);

class _IsolateUtilsConfiguration<Q, R> {
  const _IsolateUtilsConfiguration(
    this.callback,
    this.message,
    this.resultPort,
    this.debugLabel,
  );
  final IsolateUtilsCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;
  final String debugLabel;

  FutureOr<R> apply() => callback(message);
}

class IsolateUtils {
  Isolate _isolate;
  // ReceivePort
  final ReceivePort _resultPort = ReceivePort();
  final ReceivePort _exitPort = ReceivePort();
  final ReceivePort _errorPort = ReceivePort();
  // Capability
  Capability _resumeCapability;

  static Future<void> _spawn<Q, R>(
      _IsolateUtilsConfiguration<Q, FutureOr<R>> configuration) async {
    final FutureOr<R> applicationResult = await configuration.apply();
    final result = await applicationResult;
    configuration.resultPort.send(result);
  }

  Future<R> start<Q, R>(IsolateUtilsCallback<Q, R> callback, Q message,
      {String debugLabel}) async {
    final Completer<R> result = Completer<R>();

    final _debugLabel = debugLabel ?? 'IsolateUtils_${this.hashCode}';

    _isolate = await Isolate.spawn(
      _spawn,
      _IsolateUtilsConfiguration<Q, FutureOr<R>>(
        callback,
        message,
        _resultPort.sendPort,
        _debugLabel,
      ),
      onError: _errorPort.sendPort,
      onExit: _exitPort.sendPort,
      debugName: _debugLabel,
      paused: true,
    );

    // listen
    _errorPort.listen((dynamic errorData) {
      if (!result.isCompleted) {
        result.completeError(errorData);
      }
    });

    _exitPort.listen((dynamic exitData) {
      if (!result.isCompleted) {
        result.completeError(Exception(
            'IsolateUtils -> Isolate exited without result or error.'));
      }
    });

    _resultPort.listen((dynamic resultData) {
      assert(resultData == null || resultData is R);
      if (!result.isCompleted) result.complete(resultData as R);
    });

    // Run and get result
    resume();
    final _result = await result.future;

    // Finish
    stop();

    return _result;
  }

  void pause() {
    _resumeCapability = _isolate.pause();
  }

  void resume() {
    _isolate.resume(_resumeCapability ?? _isolate.pauseCapability);
  }

  void stop() {
    _resultPort.close();
    _errorPort.close();
    _exitPort.close();
    _isolate.kill();
    _isolate = null;
  }
}
