# IsolateUtils

[![Pub][pub_v_image_url]][pub_url]

IsolateUtils is a useful package for you who want to make and manage Isolate. It is based on `dart:isolate` so it only support iOS and Android.

It's like [compute()](https://api.flutter.dev/flutter/foundation/compute-constant.html): *Spawn an isolate, run callback on that isolate, passing it message, and (eventually) return the value returned by callback*. But it not `top-level constant` so you can create multiple Isolates at the same time.

## Usage

### Create and start an isolate

```dart
final _value = await IsolateUtils.createAndStart(_testFunction, 'Hello World');
print(_value);
```

### Create and manager an isolate (not run immediately)

1. Create an isolate:

    ```dart
    IsolateUtils _isolateUtils = await IsolateUtils.create(_testFunction, 'Hello World');
    ```

2. Start and get the value returned by _testFunction

    ```dart
    final _value = await _isolateUtils.start();
    print(_value);
    ```

3. Pause a running isolate

    ```dart
    _isolateUtils.pause();
    ```

4. Resume a paused isolate

    ```dart
    _isolateUtils.resume();
    ```

5. Stop and dispose a an isolate

    ```dart
    _isolateUtils.stop();
    ```

### Example test function

```dart
static Future<String> _testFunction(String message) async {
    Timer.periodic(Duration(seconds: 1), (timer) => print('$message - ${timer.tick}'));
    await Future.delayed(Duration(seconds: 30));
    return '_testFunction finish';
  }
```

## License

[![license_image_url]][license_url]

If you like my project, you can support me [![Buy Me A Coffee][buy_me_a_coffee_image_url]][buy_me_a_coffee_url] or star (like) for it.

Thank you! ❤️

[//]: # (reference links)

[pub_url]: https://pub.dev/packages/isolate_utils
[pub_v_image_url]: https://img.shields.io/pub/v/isolate_utils.svg
[license_url]: https://github.com/thongdn-it/isolate_utils/blob/master/LICENSE
[license_image_url]: https://img.shields.io/github/license/thongdn-it/isolate_utils
[buy_me_a_coffee_image_url]: https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png
[buy_me_a_coffee_url]: https://www.buymeacoffee.com/thongdn.it
