library isolate_utils;

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

/// _IsolateUtilsConfiguration
class _IsolateUtilsConfiguration<Q, R> {
  final ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;
  final String debugLabel;

  _IsolateUtilsConfiguration(
    this.callback,
    this.message,
    this.resultPort,
    this.debugLabel,
  );

  FutureOr<R> apply() => callback(message);
}

Future<void> _spawn<Q, R>(
    _IsolateUtilsConfiguration<Q, FutureOr<R>> configuration) async {
  final FutureOr<R> applicationResult =
      await (configuration.apply() as FutureOr<R>);
  final result = await applicationResult;
  configuration.resultPort.send(result);
}

/// IsolateUtilsStatus
///
/// define status for isolate: [Running], [Stopped]
enum IsolateUtilsStatus { Running, Paused, Stopped }

/// An Isolate Utils.
///
/// You can create multiple isolate and manager it like start, pause, resume, stop.
class IsolateUtils {
  IsolateUtilsStatus? _status;

  Isolate? _isolate;

  ReceivePort? _resultPort, _exitPort, _errorPort;

  late Completer _completer;

  IsolateUtils._();

  /// Create an isolate. The isolate will start up in a paused state. To start and get the return value, call `isolateUtils.start()`.
  ///
  /// Return the created isolate.
  ///
  /// Run `callback` on that isolate, passing it `message`, and (eventually) return the value returned by `callback`.
  ///
  /// The `callback` argument must be a top-level function, not a closure or an instance or static method of a class.
  ///
  /// `Q` is the type of the message that kicks off the computation.
  ///
  /// `R` is the type of the value returned.
  ///
  /// The `debugLabel` argument can be specified to provide a name to add to the [Timeline].
  /// This is useful when in debuggers and logging.
  static Future<IsolateUtils?> create<Q, R>(
      ComputeCallback<Q, R> callback, Q message,
      {String? debugLabel}) async {
    final _isolateUtils = IsolateUtils._();

    if (_isolateUtils._status != null) {
      // _isolateUtils has been created
      return null;
    }

    final _debugLabel = debugLabel ?? 'IsolateUtils_${_isolateUtils.hashCode}';

    // Create ReceivePort
    _isolateUtils._resultPort = ReceivePort();
    _isolateUtils._exitPort = ReceivePort();
    _isolateUtils._errorPort = ReceivePort();

    // Create Completer
    _isolateUtils._completer = Completer<R>();

    // Swap an isolate
    _isolateUtils._isolate = await Isolate.spawn(
      _spawn,
      _IsolateUtilsConfiguration<Q, FutureOr<R>>(
        callback,
        message,
        _isolateUtils._resultPort!.sendPort,
        _debugLabel,
      ),
      onError: _isolateUtils._errorPort!.sendPort,
      onExit: _isolateUtils._exitPort!.sendPort,
      debugName: _debugLabel,
      paused: true,
    );

    // create listen
    _isolateUtils._errorPort!.listen((dynamic errorData) {
      if (!_isolateUtils._completer.isCompleted) {
        _isolateUtils._completer.completeError(errorData);
        _isolateUtils.stop();
      }
    });

    _isolateUtils._exitPort!.listen((dynamic exitData) {
      if (!_isolateUtils._completer.isCompleted) {
        _isolateUtils._completer.completeError(Exception(
            'IsolateUtils -> Isolate exited without result or error.'));
        _isolateUtils.stop();
      }
    });

    _isolateUtils._resultPort!.listen((dynamic resultData) {
      assert(resultData == null || resultData is R);
      if (!_isolateUtils._completer.isCompleted) {
        _isolateUtils._completer.complete(resultData as R?);
        _isolateUtils.stop();
      }
    });

    _isolateUtils._status = IsolateUtilsStatus.Paused;

    return _isolateUtils;
  }

  /// Create and start an isolate.
  ///
  /// Return the value returned by `callback`.
  ///
  /// Run `callback` on that isolate, passing it `message`, and (eventually) return the value returned by `callback`.
  ///
  /// The `callback` argument must be a top-level function, not a closure or an instance or static method of a class.
  ///
  /// `Q` is the type of the message that kicks off the computation.
  ///
  /// `R` is the type of the value returned.
  ///
  /// The `debugLabel` argument can be specified to provide a name to add to the [Timeline].
  /// This is useful when in debuggers and logging.
  static Future<R?> createAndStart<Q, R>(
      ComputeCallback<Q, R> callback, Q message,
      {String? debugLabel}) async {
    final _isolateUtils =
        await IsolateUtils.create(callback, message, debugLabel: debugLabel);
    if (_isolateUtils != null) {
      return _isolateUtils.start();
    } else {
      return null;
    }
  }

  /// Start the isolate and return the value returned by `callback`.
  Future<R?> start<R>() async {
    // Run and get result
    resume();
    final _result = await _completer.future;

    return _result;
  }

  /// Pause the current isolate
  void pause() {
    _status = IsolateUtilsStatus.Paused;
    _isolate?.pause(_isolate?.pauseCapability);
  }

  /// Resume the current isolate
  void resume() {
    if (_isolate?.pauseCapability != null) {
      _status = IsolateUtilsStatus.Running;
      _isolate?.resume(_isolate!.pauseCapability!);
    }
  }

  /// Stop and dispose the current isolate
  void stop() {
    _isolate?.kill();

    _resultPort?.close();
    _errorPort?.close();
    _exitPort?.close();

    _resultPort = null;
    _errorPort = null;
    _exitPort = null;
    _isolate = null;
    _status = IsolateUtilsStatus.Stopped;
  }

  bool get isRunning => _status == IsolateUtilsStatus.Running;
  bool get isPaused => _status == IsolateUtilsStatus.Paused;
  bool get isStopped =>
      _status == null || _status == IsolateUtilsStatus.Stopped;
}
