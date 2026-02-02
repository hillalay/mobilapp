import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Grafik paylaşma yardımcı sınıfı
/// 
/// Kullanım:
/// ```dart
/// final controller = ScreenshotController();
/// 
/// Screenshot(
///   controller: controller,
///   child: SingleExamProgressChart(...),
/// )
/// 
/// // Paylaş butonuna basınca:
/// await ShareHelper.shareChart(
///   controller: controller,
///   examType: 'TYT',
///   examCount: 15,
///   latestNet: 85.5,
/// );
/// ```
class ShareHelper {
  /// Grafiği screenshot alıp paylaşır
  static Future<void> shareChart({
    required ScreenshotController controller,
    required String examType,
    required int examCount,
    required double latestNet,
  }) async {
    try {
      // Screenshot al
      final Uint8List? imageBytes = await controller.capture(
        pixelRatio: 3.0, // Yüksek kalite için
      );

      if (imageBytes == null) {
        throw Exception('Screenshot alınamadı');
      }

      // Geçici dosya oluştur
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/$examType-grafik-$timestamp.png');
      
      // Dosyaya yaz
      await file.writeAsBytes(imageBytes);

      // Paylaş
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$examType Gelişimim 📊\n'
              'Toplam $examCount deneme\n'
              'Son netim: ${latestNet.toStringAsFixed(2)}\n'
              '#YKS #TYT #AYT #DenemeAnalizi',
      );
    } catch (e) {
      print('Paylaşma hatası: $e');
      rethrow;
    }
  }

  /// Sadece kaydet (paylaşma olmadan)
  static Future<String> saveChart({
    required ScreenshotController controller,
    required String examType,
  }) async {
    try {
      // Screenshot al
      final Uint8List? imageBytes = await controller.capture(
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        throw Exception('Screenshot alınamadı');
      }

      // Dosya sistemi dizini al (kalıcı kayıt için)
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/$examType-grafik-$timestamp.png');
      
      await file.writeAsBytes(imageBytes);
      
      return file.path;
    } catch (e) {
      print('Kaydetme hatası: $e');
      rethrow;
    }
  }
}

/// Paylaşma butonlu grafik wrapper'ı
/// 
/// Kullanım:
/// ```dart
/// ShareableChart(
///   examType: 'TYT',
///   examCount: 15,
///   latestNet: 85.5,
///   child: SingleExamProgressChart(...),
/// )
/// ```
class ShareableChart extends StatefulWidget {
  const ShareableChart({
    super.key,
    required this.examType,
    required this.examCount,
    required this.latestNet,
    required this.child,
  });

  final String examType;
  final int examCount;
  final double latestNet;
  final Widget child;

  @override
  State<ShareableChart> createState() => _ShareableChartState();
}

class _ShareableChartState extends State<ShareableChart> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);

    try {
      await ShareHelper.shareChart(
        controller: _screenshotController,
        examType: widget.examType,
        examCount: widget.examCount,
        latestNet: widget.latestNet,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grafik paylaşıldı! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşma hatası: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSharing = true);

    try {
      final path = await ShareHelper.saveChart(
        controller: _screenshotController,
        examType: widget.examType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grafik kaydedildi!\n$path'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydetme hatası: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Grafiği Paylaş',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Sosyal medyada paylaş
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.share, color: Colors.blue.shade700),
              ),
              title: const Text('Sosyal Medyada Paylaş'),
              subtitle: const Text('Instagram, WhatsApp, Twitter...'),
              trailing: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isSharing
                  ? null
                  : () {
                      Navigator.pop(context);
                      _handleShare();
                    },
            ),

            const SizedBox(height: 8),

            // Galeriye kaydet
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.save_alt, color: Colors.green.shade700),
              ),
              title: const Text('Cihaza Kaydet'),
              subtitle: const Text('Grafik PNG olarak kaydedilecek'),
              trailing: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isSharing
                  ? null
                  : () {
                      Navigator.pop(context);
                      _handleSave();
                    },
            ),

            const SizedBox(height: 8),

            // İptal
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                child: Icon(Icons.close, color: Colors.grey.shade700),
              ),
              title: const Text('İptal'),
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grafik (Screenshot alınacak alan)
        Screenshot(
          controller: _screenshotController,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: widget.child,
          ),
        ),

        // Paylaş butonu (sağ üstte)
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSharing ? null : _showShareOptions,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.share_rounded,
                      size: 18,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Paylaş',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}