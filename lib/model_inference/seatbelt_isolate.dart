import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Seatbelt isolate entrypoint. Receives JPEG image bytes, processes them using
/// the TFLite seatbelt model, and sends back detection results via a reply port.
Future<void> seatbeltIsolateEntry(List<dynamic> args) async {
  print("🛠 [In Isolate] seatbeltIsolateEntry() has been invoked.");

  final SendPort mainSendPort = args[0] as SendPort;
  final port = ReceivePort();

  mainSendPort.send(port.sendPort);

  Interpreter interpreter;
  try {
    interpreter = Interpreter.fromBuffer(args[1] as Uint8List);
    print("🛠 [In Isolate] seatbelt model loaded successfully.");
  } catch (e, st) {
    print("🚨 [In Isolate] Failed to load TFLite model: $e\n$st");
    return;
  }

  await for (var message in port) {
    if (message is Map<String, dynamic>) {
      final SendPort replyPort = message['replyPort'] as SendPort;
      final Uint8List jpegBytes = message['imageBytes'] as Uint8List;

      try {
        final inputTensor = _preprocessImage(jpegBytes);

        final List<List<List<double>>> outputBuffer =
        List.generate(1, (_) => List.generate(5, (_) => List.filled(8400, 0.0)));

        interpreter.run(inputTensor, outputBuffer);

        final List<double> cxArr   = outputBuffer[0][0];
        final List<double> cyArr   = outputBuffer[0][1];
        final List<double> wArr    = outputBuffer[0][2];
        final List<double> hArr    = outputBuffer[0][3];
        final List<double> confArr = outputBuffer[0][4];

        const double confThreshold = 0.38;
        final List<Map<String, double>> boxes = [];
        final double maxConf = confArr.reduce((a, b) => a > b ? a : b);
        print("🔍 Highest confidence in frame: ${maxConf.toStringAsFixed(3)}");

        for (int i = 0; i < 8400; i++) {
          if (confArr[i] > confThreshold) {
            final cx = cxArr[i], cy = cyArr[i], w = wArr[i], h = hArr[i];
            print("📦 Detected box $i with conf=${confArr[i].toStringAsFixed(2)} at "
                "cx=$cx, cy=$cy, w=$w, h=$h");
            boxes.add({
              'left':   (cx - w / 2) * 640.0,
              'top':    (cy - h / 2) * 640.0,
              'right':  (cx + w / 2) * 640.0,
              'bottom': (cy + h / 2) * 640.0,
            });
          }
        }

        final bool noSeatbelt = boxes.isEmpty;

        print("🏷 [In Isolate] Sending seatbelt result: "
            "noSeatbelt=$noSeatbelt, boxesCount=${boxes.length}");

        replyPort.send({
          'noSeatbelt': noSeatbelt,
          'boxes': boxes,
        });
      } catch (err, st) {
        print("🚨 [In Isolate] Inference error: $err\n$st");
        replyPort.send({
          'noSeatbelt': false,
          'boxes': <Map<String, double>>[],
        });
      }
    }
  }
}

/// Decodes and normalizes JPEG bytes to a [1][640][640][3] input tensor.
List<List<List<List<double>>>> _preprocessImage(Uint8List imageBytes) {
  final original = img.decodeImage(imageBytes)!;
  final resized  = img.copyResize(original, width: 640, height: 640);

  return List.generate(1, (_) =>
      List.generate(640, (_) =>
          List.generate(640, (_) =>
              List.filled(3, 0.0),
          ),
      ),
  )..forEach((batch) {
    for (var y = 0; y < 640; y++) {
      for (var x = 0; x < 640; x++) {
        final px = resized.getPixel(x, y);
        batch[y][x][0] = px.getChannel(img.Channel.red)   / 255.0;
        batch[y][x][1] = px.getChannel(img.Channel.green) / 255.0;
        batch[y][x][2] = px.getChannel(img.Channel.blue)  / 255.0;
      }
    }
  });
}
