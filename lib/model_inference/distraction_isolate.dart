// lib/model_inference/distraction_isolate.dart

import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Carries one inference request into the isolate.
/// Fields:
///  - width, height: dimensions of the JPEG image
///  - jpegBytes: the encoded JPEG to decode & preprocess
///  - replyTo: the SendPort to send the result back on
class InferenceRequest {
  final int width, height;
  final Uint8List jpegBytes;
  final SendPort replyTo;
  InferenceRequest(this.width, this.height, this.jpegBytes, this.replyTo);
}

/// What we send back: top class index and confidence
class DistractionResult {
  final int classIndex;
  final double confidence;
  DistractionResult(this.classIndex, this.confidence);
}

/// Entrypoint for the distraction isolate.
/// args = [SendPort mainPort, Uint8List modelBytes]
void distractionIsolateEntry(List<dynamic> args) async {
  final SendPort mainPort = args[0] as SendPort;
  final Uint8List modelBytes = args[1] as Uint8List;

  // 1️⃣ Create a port for incoming requests
  final port = ReceivePort();
  // Tell main how to talk to us
  mainPort.send(port.sendPort);

  // 2️⃣ Load the TFLite model from buffer
  late final Interpreter interp;
  try {
    interp = Interpreter.fromBuffer(modelBytes,
        options: InterpreterOptions()..threads = 4);
    interp.allocateTensors();
  } catch (e, st) {
    mainPort.send('ERROR loading model in isolate: $e');
    return;
  }

  // Extract model shapes
  final inShape = interp.getInputTensor(0).shape;   // [1, H, W, C]
  print("🛠 [Isolate] model expects input H×W = ${inShape[1]}×${inShape[2]}");
  final outShape = interp.getOutputTensor(0).shape;  // [1, channels, numPreds]
  final inputSize = inShape[1];
  final channels  = outShape[1];
  final numPreds  = outShape[2];
  final classCount = channels - 5;

  // 3️⃣ Listen for inference requests
  await for (final message in port) {
    if (message is List && message[0] == 'getInputShape') {
      // reply with the shape
      mainPort.send({'inputSize': inShape[1]});
      continue;
    }
    if (message is InferenceRequest) {
      final SendPort replyTo = message.replyTo;
      final Uint8List jpeg = message.jpegBytes;

      try {
        // Decode JPEG → img.Image
        final frame = img.decodeImage(jpeg)!;

        // Preprocess: resize + nested normalization
        final resized = img.copyResize(frame,
            width: inputSize, height: inputSize);
        final nestedInput = List.generate(
          1,
              (_) => List.generate(
            inputSize,
                (_) => List.generate(
              inputSize,
                  (_) => List.filled(3, 0.0),
            ),
          ),
        );
        for (var y = 0; y < inputSize; y++) {
          for (var x = 0; x < inputSize; x++) {
            final px = resized.getPixel(x, y);
            nestedInput[0][y][x][0] =
                px.getChannel(img.Channel.red)   / 255.0;
            nestedInput[0][y][x][1] =
                px.getChannel(img.Channel.green) / 255.0;
            nestedInput[0][y][x][2] =
                px.getChannel(img.Channel.blue)  / 255.0;
          }
        }

        // Prepare output buffer [1][channels][numPreds]
        final outputBuffer = List.generate(
          1,
              (_) => List.generate(
            channels,
                (_) => List<double>.filled(numPreds, 0.0),
          ),
        );

        // Run inference
        interp.run(nestedInput, outputBuffer);
        final raw = outputBuffer[0]; // [channels][numPreds]
        final classCount = channels - 5;

// 1️⃣ Compute Raw Scores (no threshold) for inspection
        final rawScores = List<double>.filled(classCount, 0.0);
        for (var i = 0; i < numPreds; i++) {
          final objC = raw[4][i];
          for (var k = 0; k < classCount; k++) {
            final score = raw[5 + k][i] * objC;
            if (score > rawScores[k]) rawScores[k] = score;
          }
        }
        print("🍎 [Isolate] RAW distraction scores: "
            "[${rawScores.map((s) => s.toStringAsFixed(3)).join(', ')}]");

// 2️⃣ Now apply your objectness threshold for final decision
        const double objThreshold = 0.3;
        final classMax = List<double>.filled(classCount, 0.0);
        for (var i = 0; i < numPreds; i++) {
          final objC = raw[4][i];
          if (objC < objThreshold) continue;         // your original filter
          for (var k = 0; k < classCount; k++) {
            final score = raw[5 + k][i] * objC;
            if (score > classMax[k]) classMax[k] = score;
          }
        }
        print("🍎 [Isolate] FILTERED distraction scores: "
            "[${classMax.map((s) => s.toStringAsFixed(3)).join(', ')}]");

// 3️⃣ Find top class as before…
        int topIdx = -1;
        double topVal = 0.0;
        for (var k = 0; k < classCount; k++) {
          if (classMax[k] > topVal) {
            topVal = classMax[k];
            topIdx = k;
          }
        }
        if (topVal < objThreshold) {
          topIdx = -1;
          topVal = 0.0;
        }

        print("🏷 [Isolate] final idx=$topIdx conf=${topVal.toStringAsFixed(3)}");
        replyTo.send(DistractionResult(topIdx, topVal));
      } catch (e, st) {
        // On error, reply with safe
        message.replyTo.send(DistractionResult(-1, 0.0));
      }
    }
  }
}
