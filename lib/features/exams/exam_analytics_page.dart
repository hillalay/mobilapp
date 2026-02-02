import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'exam_models.dart';
import 'exam_analytics_providers.dart';
import 'single_exam_progress_chart.dart';
import 'share_helper.dart';

class ExamAnalyticsPage extends ConsumerStatefulWidget {
  const ExamAnalyticsPage({super.key, required this.type});
  final ExamType type;

  @override
  ConsumerState<ExamAnalyticsPage> createState() => _ExamAnalyticsPageState();
}

class _ExamAnalyticsPageState extends ConsumerState<ExamAnalyticsPage> {
  // ✅ Screenshot controller burada tanımlanıyor
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _handleShare(
    String examType,
    int examCount,
    double latestNet,
  ) async {
    setState(() => _isSharing = true);

    try {
      await ShareHelper.shareChart(
        controller: _screenshotController,
        examType: examType,
        examCount: examCount,
        latestNet: latestNet,
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
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _showShareOptions(
    String examType,
    int examCount,
    double latestNet,
  ) {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Grafiği Paylaş',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      _handleShare(examType, examCount, latestNet);
                    },
            ),

            const SizedBox(height: 8),

            // Cihaza kaydet
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
                  : () async {
                      Navigator.pop(context);
                      setState(() => _isSharing = true);
                      try {
                        final path = await ShareHelper.saveChart(
                          controller: _screenshotController,
                          examType: examType,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Grafik kaydedildi!\n$path'),
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
                    },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.type == ExamType.tyt
        ? ref.watch(tytGeneralExamsProvider)
        : ref.watch(aytGeneralExamsProvider);

    if (list.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Analiz • ${widget.type.name.toUpperCase()}'),
        ),
        body: const Center(child: Text('Henüz bu türde genel deneme yok.')),
      );
    }

    final latest = list.last;
    final latestGeneral = latest.general!;
    final latestName = latest.name;

    // Ortalama netleri hesapla
    final avg = <String, double>{};
    final counts = <String, int>{};

    for (final e in list) {
      final nets = e.general!.netsBySection;
      for (final entry in nets.entries) {
        avg[entry.key] = (avg[entry.key] ?? 0) + entry.value;
        counts[entry.key] = (counts[entry.key] ?? 0) + 1;
      }
    }
    for (final k in avg.keys) {
      avg[k] = avg[k]! / (counts[k] ?? 1);
    }

    final computedMax = [
      ...latestGeneral.netsBySection.values,
      ...avg.values,
    ].fold<double>(0.0, (m, v) => v > m ? v : m);

    final maxNet = (computedMax < 1.0) ? 1.0 : computedMax;

    final labels = latestGeneral.netsBySection.keys.toList();
    final latestValues = latestGeneral.netsBySection.values.toList();
    final avgValues = labels.map((label) => avg[label] ?? 0.0).toList();

    // Çizgi grafik için toplam netleri hesapla
    final totalNets = list.map((e) {
      final nets = e.general!.netsBySection.values;
      return nets.fold(0.0, (sum, net) => sum + net);
    }).toList();

    final chartColor = widget.type == ExamType.tyt ? Colors.blue : Colors.orange;
    final latestTotalNet = totalNets.last;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analiz • ${widget.type.name.toUpperCase()}'),
        actions: [
          // ✅ TEMİZ PAYLAŞ BUTONU - APPBAR'DA
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share_rounded),
            tooltip: 'Grafiği Paylaş',
            onPressed: _isSharing
                ? null
                : () => _showShareOptions(
                      widget.type.name.toUpperCase(),
                      list.length,
                      latestTotalNet,
                    ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ TEMİZ GRAFİK - PAYLAŞ BUTONU YOK
          Screenshot(
            controller: _screenshotController,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SingleExamProgressChart(
                examType: widget.type.name.toUpperCase(),
                netData: totalNets,
                color: chartColor,
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          Text(
            'Son deneme: $latestName',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 24),
          const Text(
            'Son Deneme Branş Netleri',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),

          ...latestGeneral.netsBySection.entries.map((e) {
            return _NetBarRow(
              label: e.key,
              value: e.value,
              maxValue: maxNet,
            );
          }),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),

          const Text(
            'Ortalama Netler',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),

          ...avg.entries.map((e) {
            return _NetBarRow(
              label: e.key,
              value: e.value,
              maxValue: maxNet,
              suffix: ' ort.',
            );
          }),

          const SizedBox(height: 18),
          Card(
            child: ListTile(
              title: const Text('Toplam Deneme Sayısı'),
              trailing: Text(
                list.length.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetBarRow extends StatelessWidget {
  const _NetBarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    this.suffix = '',
  });

  final String label;
  final double value;
  final double maxValue;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final ratio = (value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${value.toStringAsFixed(2)}$suffix',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}