import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Özel tasarlanmış paylaşım kartı
/// Instagram story formatında (1080x1920)
/// 
/// Kullanım:
/// ```dart
/// await showDialog(
///   context: context,
///   builder: (ctx) => ShareCardDialog(
///     examType: 'TYT',
///     examCount: 15,
///     latestNet: 85.5,
///     improvement: 12.3,
///     netData: [70, 75, 80, 85.5],
///   ),
/// );
/// ```
class ShareCardDialog extends StatefulWidget {
  const ShareCardDialog({
    super.key,
    required this.examType,
    required this.examCount,
    required this.latestNet,
    required this.improvement,
    required this.netData,
    this.userName,
  });

  final String examType;
  final int examCount;
  final double latestNet;
  final double improvement; // İlk denemeye göre artış yüzdesi
  final List<double> netData;
  final String? userName;

  @override
  State<ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<ShareCardDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _captureAndShare() async {
    setState(() => _isSharing = true);

    try {
      // Widget'ı resme çevir
      final RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Resim oluşturulamadı');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Geçici dosya oluştur
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/deneme-analizi-$timestamp.png');
      await file.writeAsBytes(pngBytes);

      // Paylaş
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.examType} Gelişimim 📊\n#YKS #DenemeAnalizi',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kart paylaşıldı! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kart önizlemesi
          RepaintBoundary(
            key: _cardKey,
            child: _ShareCard(
              examType: widget.examType,
              examCount: widget.examCount,
              latestNet: widget.latestNet,
              improvement: widget.improvement,
              netData: widget.netData,
              userName: widget.userName,
            ),
          ),

          const SizedBox(height: 20),

          // Butonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İptal
              TextButton.icon(
                onPressed: _isSharing ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text(
                  'İptal',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Paylaş
              ElevatedButton.icon(
                onPressed: _isSharing ? null : _captureAndShare,
                icon: _isSharing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share),
                label: Text(_isSharing ? 'Paylaşılıyor...' : 'Paylaş'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paylaşım kartı widget'ı
class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.examType,
    required this.examCount,
    required this.latestNet,
    required this.improvement,
    required this.netData,
    this.userName,
  });

  final String examType;
  final int examCount;
  final double latestNet;
  final double improvement;
  final List<double> netData;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final color = examType == 'TYT' ? Colors.blue : Colors.orange;
    final avgNet = netData.reduce((a, b) => a + b) / netData.length;
    final maxNet = netData.reduce((a, b) => a > b ? a : b);

    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.shade700,
            color.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          if (userName != null) ...[
            Text(
              userName!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$examType Gelişimim',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Ana istatistik
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Son Netim',
                  style: TextStyle(
                    color: color.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  latestNet.toStringAsFixed(2),
                  style: TextStyle(
                    color: color.shade900,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      improvement >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: improvement >= 0 ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: improvement >= 0 ? Colors.green : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Mini grafik
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ...List.generate(netData.length.clamp(0, 10), (i) {
                  final value = netData[i];
                  final ratio = value / maxNet;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 50 * ratio,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Diğer istatistikler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(
                label: 'Deneme',
                value: examCount.toString(),
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _StatColumn(
                label: 'Ortalama',
                value: avgNet.toStringAsFixed(1),
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _StatColumn(
                label: 'En Yüksek',
                value: maxNet.toStringAsFixed(1),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Tarih
          Text(
            DateTime.now().toString().split(' ')[0],
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}