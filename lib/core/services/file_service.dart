import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../version_a/models/file_info.dart';

class FileService {
  final ImagePicker _picker = ImagePicker();

  // Pick single or multiple files
  Future<List<FileInfo>> pickFiles({bool multiple = true}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: multiple,
        type: FileType.any,
      );
      
      if (result == null || result.files.isEmpty) {
        return [];
      }
      
      final fileInfoList = <FileInfo>[];
      for (var platformFile in result.files) {
        if (platformFile.path != null) {
          final file = File(platformFile.path!);
          final stat = await file.stat();
          
          fileInfoList.add(FileInfo(
            name: platformFile.name,
            path: platformFile.path!,
            sizeInBytes: stat.size,
            dateAdded: DateTime.now(),
          ));
        }
      }
      
      return fileInfoList;
    } catch (e) {
      throw Exception('Failed to pick files: $e');
    }
  }

  // Pick media (images/videos) from gallery
  Future<List<FileInfo>> pickMedia() async {
    try {
      final List<XFile> medias = await _picker.pickMultipleMedia();
      
      if (medias.isEmpty) {
        return [];
      }

      final fileInfoList = <FileInfo>[];
      for (var media in medias) {
        final file = File(media.path);
        final stat = await file.stat();

        fileInfoList.add(FileInfo(
          name: media.name,
          path: media.path,
          sizeInBytes: stat.size,
          dateAdded: DateTime.now(),
        ));
      }

      return fileInfoList;
    } catch (e) {
      throw Exception('Failed to pick media: $e');
    }
  }
  
  // Get app's documents directory for saving compressed files
  Future<String> getOutputDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final compressedDir = Directory('${directory.path}/Compressed');
      
      if (!await compressedDir.exists()) {
        await compressedDir.create(recursive: true);
      }
      
      return compressedDir.path;
    } catch (e) {
      throw Exception('Failed to get output directory: $e');
    }
  }
  
  // Generate unique filename for compressed file
  Future<String> generateOutputPath(String baseName) async {
    final directory = await getOutputDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${baseName}_$timestamp.zip';
    return '$directory/$fileName';
  }
  
  // Share compressed file
  Future<void> shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }
      
      final fileName = path.basename(filePath);
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: fileName,
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }
  
  // Open file with native iOS viewer
  Future<void> openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }
      
      final fileName = path.basename(filePath);
      // Use share sheet to "open with" - this is the iOS native way
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: fileName,
      );
    } catch (e) {
      throw Exception('Failed to open file: $e');
    }
  }
  
  // Check and request storage permissions (for iOS)
  Future<bool> checkPermissions() async {
    // For iOS, we primarily need photo library permission if dealing with photos
    if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
      return status.isGranted || status.isLimited;
    }
    return true;
  }
  
  // Get file icon based on extension
  String getFileIcon(String extension) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg'];
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv'];
    const documentExtensions = ['pdf', 'doc', 'docx', 'txt'];
    const archiveExtensions = ['zip', 'rar', '7z', 'tar'];
    
    if (imageExtensions.contains(extension)) {
      return 'assets/icons/file_document.png';
    } else if (videoExtensions.contains(extension)) {
      return 'assets/icons/file_document.png';
    } else if (documentExtensions.contains(extension)) {
      return 'assets/icons/file_document.png';
    } else if (archiveExtensions.contains(extension)) {
      return 'assets/icons/compress_icon.png';
    } else {
      return 'assets/icons/file_folder.png';
    }
  }
  
  // Format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
  
  // Delete file
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Check if file is video
  bool isHiddenVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') || ext.endsWith('.mov') || ext.endsWith('.avi') || ext.endsWith('.m4v');
  }
}
