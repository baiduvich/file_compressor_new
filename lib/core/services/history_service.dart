import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../version_a/models/compression_history.dart';

class HistoryService extends ChangeNotifier {
  static const String _historyKey = 'compression_history';
  List<CompressionHistory> _history = [];
  
  List<CompressionHistory> get history => _history;
  
  // Load history from storage
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_historyKey);
      
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        _history = decoded.map((item) => CompressionHistory.fromJson(item)).toList();
        _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
  }
  
  // Save history to storage
  Future<void> saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = json.encode(
        _history.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      debugPrint('Failed to save history: $e');
    }
  }
  
  // Add new compression to history
  Future<void> addToHistory(CompressionHistory item) async {
    _history.insert(0, item);
    await saveHistory();
    notifyListeners();
  }
  
  // Remove item from history
  Future<void> removeFromHistory(String id) async {
    _history.removeWhere((item) => item.id == id);
    await saveHistory();
    notifyListeners();
  }
  
  // Clear all history
  Future<void> clearHistory() async {
    _history.clear();
    await saveHistory();
    notifyListeners();
  }
  
  // Get total statistics
  Map<String, dynamic> getTotalStatistics() {
    int totalFiles = 0;
    int totalOriginalSize = 0;
    int totalCompressedSize = 0;
    
    for (var item in _history) {
      totalFiles += item.files.length;
      totalOriginalSize += item.totalOriginalSize;
      totalCompressedSize += item.totalCompressedSize;
    }
    
    final totalSaved = totalOriginalSize - totalCompressedSize;
    final averageRatio = totalOriginalSize > 0 
        ? ((totalSaved / totalOriginalSize) * 100) 
        : 0.0;
    
    return {
      'totalCompressions': _history.length,
      'totalFiles': totalFiles,
      'totalSaved': totalSaved,
      'averageRatio': averageRatio,
    };
  }
}
