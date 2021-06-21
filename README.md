# IsolateUtils

IsolateUtils is a useful package for you who want to make and manage Isolate. It is based on `dart:isolate` so it only support iOS and Android.

It's like [compute()](https://api.flutter.dev/flutter/foundation/compute-constant.html): *Spawn an isolate, run callback on that isolate, passing it message, and (eventually) return the value returned by callback*. But it not `top-level constant` so you can create multiple Isolates at the same time.

## Usage

Create a IsolateUtils:

```dart
final IsolateUtils _isolateUtils = IsolateUtils();
```

### Start 

Create and start an isolate:

```dart
final _value = await IsolateUtils.createAndStart(_testFunction, 'Hello World');
print(_value);
```

OR

1. Create an isolate:

```dart
IsolateUtils _isolateUtils = await IsolateUtils.create(_testFunction, 'Hello World');
```

2. Start and get the value returned by _testFunction

```dart
final _value = await _isolateUtils.start();
print(_value);
```

Pause a running isolate
```dart
_isolateUtils.pause();
```

Resume a paused isolate
```dart
_isolateUtils.resume();
```

Stop and dispose a an isolate
```dart
_isolateUtils.stop();
```

Example test function

```dart
static Future<String> _testFunction(String message) async {
    Timer.periodic(Duration(seconds: 1), (timer) => print('$message - ${timer.tick}'));
    await Future.delayed(Duration(seconds: 30));
    return '_testFunction finish';
  }
```