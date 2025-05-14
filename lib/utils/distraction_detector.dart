import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// A single detection result.
class Detection {
  final int classIndex;
  final double confidence;
  final Rect box; // screen-space rectangle

  Detection({
    required this.classIndex,
    required this.confidence,
    required this.box,
  });
}

/// Distraction detector using a YOLO-style TFLite model.
class DistractionDetector {
  late final Interpreter _interp;
  static const _modelPath = 'assets/models/distraction.tflite';

  // Populated in loadModel():
  late final int _inputSize; // model input height/width
  late final int _channels;  // e.g. 8 (xywh + obj conf + classes)
  late final int _numPreds;  // number of grid predictions (e.g. 8400)

  /// Load the TFLite model and read input/output shapes.
  Future<void> loadModel() async {
    _interp = await Interpreter.fromAsset(
      _modelPath,
      options: InterpreterOptions()..threads = 4,
    );
    _interp.allocateTensors();

    // Input shape: [1, H, W, 3]
    final inShape = _interp.getInputTensor(0).shape;
    _inputSize = inShape[1];

    // Output shape: [1, channels, numPreds]
    final outShape = _interp.getOutputTensor(0).shape;
    _channels = outShape[1];
    _numPreds = outShape[2];
  }

  /// Preprocess the image into a nested List [1][H][W][3] using getChannel.
  List<List<List<List<double>>>> preprocessNested(img.Image frame) {
    // Resize to model expected input
    final resized = img.copyResize(frame,
        width: _inputSize, height: _inputSize);

    // Allocate nested list: 1 x H x W x 3
    final nested = List.generate(
      1,
          (_) => List.generate(
        _inputSize,
            (_) => List.generate(
          _inputSize,
              (_) => List.filled(3, 0.0),
        ),
      ),
    );

    // Fill normalized RGB channels
    final batch = nested[0];
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final px = resized.getPixel(x, y);
        batch[y][x][0] = px.getChannel(img.Channel.red) / 255.0;
        batch[y][x][1] = px.getChannel(img.Channel.green) / 255.0;
        batch[y][x][2] = px.getChannel(img.Channel.blue) / 255.0;
      }
    }

    return nested;
  }

  /// Run inference on nested List input, producing [1][channels][numPreds].
  List<List<List<double>>> _runModelNested(
      List<List<List<List<double>>>> input) {
    final output = List.generate(
      1,
          (_) => List.generate(
        _channels,
            (_) => List<double>.filled(_numPreds, 0.0),
      ),
    );
    _interp.run(input, output);
    return output;
  }

  /// Decode YOLO-style outputs, apply NMS, and return detections.
  List<Detection> detect(img.Image frame,
      {double confThreshold = 0.3, double iouThreshold = 0.45}) {
    final nestedInput = preprocessNested(frame);
    final raw = _runModelNested(nestedInput)[0]; // shape: [channels][numPreds]

    final dets = <Detection>[];
    for (int i = 0; i < _numPreds; i++) {
      final x = raw[0][i];
      final y = raw[1][i];
      final w = raw[2][i];
      final h = raw[3][i];
      final objC = raw[4][i];
      if (objC < confThreshold) continue;

      // Find best class score
      final classCount = _channels - 5;
      double bestC = 0;
      int bestK = -1;
      for (int k = 0; k < classCount; k++) {
        final c = raw[5 + k][i];
        if (c > bestC) {
          bestC = c;
          bestK = k;
        }
      }
      final score = objC * bestC;
      if (score < confThreshold) continue;

      // Convert center-xy wh to bounding box
      final cx = x * _inputSize;
      final cy = y * _inputSize;
      final bw = w * _inputSize;
      final bh = h * _inputSize;
      final left = cx - bw / 2;
      final top = cy - bh / 2;

      dets.add(Detection(
        classIndex: bestK,
        confidence: score,
        box: Rect.fromLTWH(left, top, bw, bh),
      ));
    }

    return _nms(dets, iouThreshold);
  }

  /// Class-aware Non-Maximum Suppression.
  List<Detection> _nms(List<Detection> dets, double iouThresh) {
    dets.sort((a, b) => b.confidence.compareTo(a.confidence));
    final keep = <Detection>[];
    final removed = List<bool>.filled(dets.length, false);

    for (int i = 0; i < dets.length; i++) {
      if (removed[i]) continue;
      final a = dets[i];
      keep.add(a);
      for (int j = i + 1; j < dets.length; j++) {
        if (removed[j]) continue;
        final b = dets[j];
        if (a.classIndex != b.classIndex) continue;
        if (_iou(a.box, b.box) > iouThresh) removed[j] = true;
      }
    }
    return keep;
  }

  /// Intersection-over-Union calculation.
  double _iou(Rect a, Rect b) {
    final interLeft = max(a.left, b.left);
    final interTop = max(a.top, b.top);
    final interRight = min(a.right, b.right);
    final interBottom = min(a.bottom, b.bottom);
    final interWidth = max(0.0, interRight - interLeft);
    final interHeight = max(0.0, interBottom - interTop);
    final interArea = interWidth * interHeight;
    final unionArea = a.width * a.height + b.width * b.height - interArea;
    return unionArea <= 0 ? 0 : interArea / unionArea;
  }

  /// Release interpreter resources.
  void close() => _interp.close();
}
