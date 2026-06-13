import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.chinese);

  /// Pick an image from gallery and extract text via ML Kit OCR.
  Future<OcrResult?> pickAndRecognize({bool fromCamera = false}) async {
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (image == null) return null;
    return _recognizeFile(image);
  }

  /// Recognize text from a file path.
  Future<OcrResult?> recognizeFile(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);
    return _process(inputImage);
  }

  Future<OcrResult?> _recognizeFile(XFile file) async {
    return recognizeFile(file.path);
  }

  Future<OcrResult?> recognizeBytes(Uint8List bytes, {int width = 0, int height = 0}) async {
    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: width * 4,
      ),
    );
    return _process(inputImage);
  }

  Future<OcrResult?> _process(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText =
          await _recognizer.processImage(inputImage);

      final blocks = recognizedText.blocks;
      if (blocks.isEmpty) {
        return OcrResult('', '', [], 0.0);
      }

      final allText = blocks.map((b) => b.text).join('\n');
      final totalConfidence = blocks.fold<double>(
        0,
        (sum, b) => sum + (b.confidence ?? 0.5),
      );
      final avgConfidence = totalConfidence / blocks.length;

      final detectedLang = _detectLanguage(allText);

      return OcrResult(
        allText,
        detectedLang,
        blocks.map((b) => OcrBlock(
          text: b.text,
          left: b.boundingBox.left.toInt(),
          top: b.boundingBox.top.toInt(),
          width: b.boundingBox.width.toInt(),
          height: b.boundingBox.height.toInt(),
          confidence: b.confidence ?? 0.0,
        )).toList(),
        avgConfidence,
      );
    } catch (e) {
      return OcrResult('', '', [], 0.0);
    }
  }

  String _detectLanguage(String text) {
    final chineseChars = text.codeUnits.where(
      (c) => (c >= 0x4E00 && c <= 0x9FFF) || (c >= 0x3000 && c <= 0x303F),
    ).length;
    final japaneseChars = text.codeUnits.where(
      (c) => (c >= 0x3040 && c <= 0x30FF),
    ).length;
    if (chineseChars > text.length * 0.1) return 'zh';
    if (japaneseChars > text.length * 0.1) return 'ja';
    return 'en';
  }

  void dispose() {
    _recognizer.close();
  }
}

class OcrResult {
  final String text;
  final String detectedLanguage;
  final List<OcrBlock> blocks;
  final double confidence;

  OcrResult(this.text, this.detectedLanguage, this.blocks, this.confidence);

  bool get isEmpty => text.trim().isEmpty;
  bool get isHighConfidence => confidence > 0.7;
}

class OcrBlock {
  final String text;
  final int left;
  final int top;
  final int width;
  final int height;
  final double confidence;

  OcrBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.confidence,
  });
}
