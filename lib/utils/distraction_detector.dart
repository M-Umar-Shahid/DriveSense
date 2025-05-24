import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Detection {
  final int classIndex;
  final double confidence;
  final Rect box;
  Detection({
    required this.classIndex,
    required this.confidence,
    required this.box,
  });
}

class DistractionDetector {
  late final Interpreter _interp;
  static const _modelPath = 'assets/models/distraction.tflite';
  late final int _inputSize;
  late final int _channels;
  late final int _numPreds;

  Future<void> loadModel() async {
    _interp = await Interpreter.fromAsset(
      _modelPath,
      options: InterpreterOptions()..threads = 4,
    );
    _interp.allocateTensors();
    final inputTensor = _interp.getInputTensor(0);
    final outputTensor = _interp.getOutputTensor(0);
    debugPrint("📐 INPUT shape: ${inputTensor.shape}  type: ${inputTensor.type}");
    debugPrint("📐 OUTPUT shape: ${outputTensor.shape} type: ${outputTensor.type}");
    final inShape = _interp.getInputTensor(0).shape;
    _inputSize = inShape[1];
    final outShape = _interp.getOutputTensor(0).shape;
    _channels = outShape[1];
    _numPreds = outShape[2];
  }

  List<List<List<List<double>>>> preprocessNested(img.Image frame) {
    final resized = img.copyResize(frame, width: _inputSize, height: _inputSize);
    debugPrint("🧾 Detected input size: $_inputSize");
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

  // Your usual object detection. Kept for compatibility.
  List<Detection> detect(img.Image frame, {double confThreshold = 0.3, double iouThreshold = 0.45}) {
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

  List<List<List<double>>> _runModelNested(List<List<List<List<double>>>> input) {
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

  /// ------------- NEW: Run for classification-style output -----------------
  /// Returns a List<double> of length 4 with the highest confidence per class (over all predictions).
  List<double> run(img.Image frame, {double objThreshold = 0.3}) {
    final nestedInput = preprocessNested(frame);
    final raw = _runModelNested(nestedInput)[0]; // [channels][numPreds]

    final classCount = _channels - 5;
    List<double> classMax = List.filled(classCount, 0.0);

    for (int i = 0; i < _numPreds; i++) {
      final objC = raw[4][i];
      if (objC < objThreshold) continue;  // ✅ skip low-confidence boxes

      for (int k = 0; k < classCount; k++) {
        final classScore = raw[5 + k][i] * objC; // YOLO = obj_conf * class_prob
        if (classScore > classMax[k]) {
          classMax[k] = classScore;
        }
      }
    }

    return classMax;
  }


  /// Helper: Get the top predicted class index and confidence.
  Map<String, dynamic> getTopClass(img.Image frame) {
    final scores = run(frame);  // uses new objectness-aware logic
    int topIdx = 0;
    double maxVal = scores[0];

    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxVal) {
        maxVal = scores[i];
        topIdx = i;
      }
    }

    if (maxVal < 0.3) {
      debugPrint("🟢 Safe driving detected (no class > 0.3)");
      return {
        'classIndex': -1,
        'confidence': 0.0,
        'scores': scores,
      };
    }

    debugPrint("🧠 Class scores: ${scores.map((s) => s.toStringAsFixed(2)).toList()}");
    debugPrint("🏷️ Predicted class index: $topIdx with confidence: ${maxVal.toStringAsFixed(2)}");

    return {
      'classIndex': topIdx,
      'confidence': maxVal,
      'scores': scores,
    };
  }




  void close() => _interp.close();
}
