import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceRecognitionModel {
  static FaceRecognitionModel? _instance;
  late Interpreter _interpreter;
  bool _isInitialized = false;

  static const int inputSize = 224;
  static const int numClasses = 3;
  static const double authorizedThreshold = 0.70;
  static const double professorThreshold = 0.60;

  static const List<String> labels = ['teammate1', 'teammate2', 'professor'];

  FaceRecognitionModel._internal();

  static Future<FaceRecognitionModel> getInstance() async {
    if (_instance == null) {
      _instance = FaceRecognitionModel._internal();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/face_model.tflite',
        options: options,
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  Future<Map<String, dynamic>> predict(img.Image image) async {
    if (!_isInitialized) {
      throw Exception('Model not initialized');
    }

    try {
      final resized = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      final inputBytes = Float32List(1 * inputSize * inputSize * 3);
      int idx = 0;
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resized.getPixel(x, y);
          inputBytes[idx++] = pixel.r.toDouble();
          inputBytes[idx++] = pixel.g.toDouble();
          inputBytes[idx++] = pixel.b.toDouble();
        }
      }

      final inputTensor = inputBytes.reshape([1, inputSize, inputSize, 3]);
      final outputTensor = Float32List(1 * numClasses).reshape([1, numClasses]);

      _interpreter.run(inputTensor, outputTensor);

      final predictions = List<double>.from(outputTensor[0]);

      int bestClass = 0;
      double bestConfidence = predictions[0];
      for (int i = 1; i < numClasses; i++) {
        if (predictions[i] > bestConfidence) {
          bestConfidence = predictions[i];
          bestClass = i;
        }
      }

      bool isAuthorized = false;
      bool isProfessor = false;

      if (bestClass == 0 || bestClass == 1) {
        isAuthorized = bestConfidence >= authorizedThreshold;
      } else if (bestClass == 2) {
        isProfessor = bestConfidence >= professorThreshold;
      }

      print('=== FACE MODEL OUTPUT ===');
      print('teammate1 : ${predictions[0].toStringAsFixed(4)}');
      print('teammate2 : ${predictions[1].toStringAsFixed(4)}');
      print('professor : ${predictions[2].toStringAsFixed(4)}');
      print('Best: ${labels[bestClass]} (${bestConfidence.toStringAsFixed(4)})');
      print('Decision: ${isAuthorized ? "AUTHORIZED" : isProfessor ? "PROFESSOR-DEPLOY" : "UNKNOWN-SCANNING"}');
      print('=========================');

      return {
        'isClassA': isAuthorized,
        'isProfessor': isProfessor,
        'confidence': bestConfidence,
        'bestClass': bestClass,
        'rawPredictions': predictions,
      };
    } catch (e) {
      throw Exception('Prediction failed: $e');
    }
  }

  void dispose() {
    _interpreter.close();
    _isInitialized = false;
  }
}