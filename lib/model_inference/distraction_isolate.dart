// lib/model_inference/distraction_isolate.dart

import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math' as math;

/// Carries a single inference request into the isolate.
class InferenceRequest {
  final int width, height;
  final Uint8List jpegBytes;
  final SendPort replyTo;
  InferenceRequest(this.width, this.height, this.jpegBytes, this.replyTo);
}

/// What we send back.
class DistractionResult {
  final int classIndex;
  final double confidence;
  final List<double> scores;    // per-class confidences after threshold
  final List<double> rawScores; // per-class confidences before threshold
  DistractionResult(this.classIndex, this.confidence, this.scores, this.rawScores);
}

/// Entrypoint for the distraction isolate.
/// Entrypoint for the distraction isolate.
void distractionIsolateEntry(List<dynamic> args) async {
  final SendPort mainPort = args[0] as SendPort;
  final Uint8List modelBytes = args[1] as Uint8List;

  // 1) Create a port for incoming requests
  final port = ReceivePort();
  mainPort.send(port.sendPort);

  // 2) Load the TFLite model
  print('[ISOLATE] Creating interpreter...');
  final interp = Interpreter.fromBuffer(
    modelBytes,
    options: InterpreterOptions()..threads = 4,
  );
  print('[ISOLATE] Allocating tensors...');
  interp.allocateTensors();
  print('[ISOLATE] Alloc done.');

  final inShape  = interp.getInputTensor(0).shape;
  final outShape = interp.getOutputTensor(0).shape;

  final inputSize = inShape[1];
  final channels  = outShape[1];
  final numPreds  = outShape[2];
  final classCount = channels - 4;

  // ✅ Send debug shape info immediately
  mainPort.send({'debug': 'InputShape: $inShape OutputShape: $outShape Channels: $channels NumPreds: $numPreds ClassCount: $classCount'});

  await for (final message in port) {
    if (message is InferenceRequest) {
      final replyTo = message.replyTo;

      try {
        final frame   = img.decodeImage(message.jpegBytes)!;
        final resized = img.copyResize(frame, width: inputSize, height: inputSize);

        final input = List.generate(
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
            input[0][y][x][0] = px.getChannel(img.Channel.red) / 255.0;
            input[0][y][x][1] = px.getChannel(img.Channel.green) / 255.0;
            input[0][y][x][2] = px.getChannel(img.Channel.blue) / 255.0;
          }
        }

        final output = List.generate(
          1,
              (_) => List.generate(
            channels,
                (_) => List<double>.filled(numPreds, 0.0),
          ),
        );

        interp.run(input, output);

        final raw = output[0];

        // ✅ Send sample raw element back for debug
        replyTo.send({'debug': 'Example raw[0][0]=${raw[0][0]}, raw[1][0]=${raw[1][0]}, raw[4][0]=${raw[4][0]}'});



        final rawScores = List<double>.filled(classCount, 0.0);
        for (int i = 0; i < numPreds; i++) {
          for (int k = 0; k < classCount; k++) {
            final sc = sigmoid(raw[4 + k][i]);
            if (sc > rawScores[k]) {
              rawScores[k] = sc;
            }
          }
        }

        final scores = List<double>.filled(classCount, 0.0);
        const looseThreshold = 0.05;

        for (int i = 0; i < numPreds; i++) {
          // Check if box size is reasonable
          final w = raw[2][i];
          final h = raw[3][i];
          final boxValid = w > 0.05 && h > 0.05; // example

          for (int k = 0; k < classCount; k++) {
            final sc = sigmoid(raw[4 + k][i]);
            if (boxValid && sc > looseThreshold && sc > scores[k]) {
              scores[k] = sc;
            }
          }
        }

        int topIdx = -1;
        double topVal = 0.0;
        for (int k = 0; k < classCount; k++) {
          if (scores[k] > topVal) {
            topVal = scores[k];
            topIdx = k;
          }
        }

        replyTo.send(DistractionResult(topIdx, topVal, scores, rawScores));

      } catch (e) {
        replyTo.send({'debug': 'Error in isolate: $e'});
        replyTo.send(DistractionResult(
            -1, 0.0, List.filled(classCount, 0.0), List.filled(classCount, 0.0)
        ));
      }
    }
  }
}
double sigmoid(double x) => 1 / (1 + math.exp(-x));
