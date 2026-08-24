import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ransomware_engine.dart';

class RansomNoteScreen extends StatefulWidget {
  const RansomNoteScreen({super.key});

  @override
  State<RansomNoteScreen> createState() => _RansomNoteScreenState();
}

class _RansomNoteScreenState extends State<RansomNoteScreen> {
  String _manifestContent = '';
  String _noteContent = '';
  bool _isLoading = true;
  int _fileCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRansomData();
  }

  Future<void> _loadRansomData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      
      final manifestFile = File('${appDir.path}/${RansomwareEngine.manifestFileName}');
      if (await manifestFile.exists()) {
        _manifestContent = await manifestFile.readAsString();
        
        final lines = _manifestContent.split('\n');
        for (var line in lines) {
          if (line.startsWith('Total Files Encrypted:')) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              _fileCount = int.tryParse(parts[1].trim()) ?? 0;
            }
          }
        }
      }

      final noteFile = File('${appDir.path}/${RansomwareEngine.ransomNoteFileName}');
      if (await noteFile.exists()) {
        _noteContent = await noteFile.readAsString();
      }
    } catch (e) {
      print('Error loading ransom data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red,
              Colors.redAccent,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SYSTEM COMPROMISED',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Files Encrypted: $_fileCount',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Text(
                              _noteContent.isNotEmpty 
                                  ? _noteContent 
                                  : 'Ransom note not found. System unavailable.',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.white24),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.list, color: Colors.white70),
                              SizedBox(width: 8),
                              Text(
                                'File Manifest',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    _manifestContent.isNotEmpty 
                                        ? _manifestContent 
                                        : 'Manifest file not found.',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _loadRansomData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Refresh'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('ransomware_active', false);
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Restart'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}