import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Tek sınav türü için net artışı gösteren çizgi grafik
/// Watermark yok, tüm fl_chart versiyonlarıyla uyumlu
class SingleExamProgressChart extends StatefulWidget {
  const SingleExamProgressChart({
    super.key,
    required this.examType,
    required this.netData,
    this.color = Colors.blue,
  });

  final String examType;
  final List<double> netData;
  final Color color;

  @override
  State<SingleExamProgressChart> createState() => _SingleExamProgressChartState();
}

class _SingleExamProgressChartState extends State<SingleExamProgressChart> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    if (widget.netData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz ${widget.examType} denemesi yok',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.netData.length == 1) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 48,
                  color: widget.color.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'İlk ${widget.examType} denemen: ${widget.netData.first.toStringAsFixed(2)} net',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'İlerlemeyi görmek için en az 1 deneme daha ekle',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Gösterilecek veriyi seç
    final displayData = _showAll 
        ? widget.netData 
        : widget.netData.length > 10
            ? widget.netData.sublist(widget.netData.length - 10)
            : widget.netData;

    final startIndex = _showAll ? 0 : (widget.netData.length > 10 ? widget.netData.length - 10 : 0);

    final maxValue = _calculateMaxValue(displayData);
    final minValue = _calculateMinValue(displayData);

    final improvement = widget.netData.length > 1
        ? ((widget.netData.last - widget.netData.first) / widget.netData.first * 100)
        : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve butonlar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.examType} Net Gelişimi',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _showAll 
                            ? '${widget.netData.length} deneme (tümü)'
                            : displayData.length < widget.netData.length
                                ? 'Son ${displayData.length} deneme'
                                : '${widget.netData.length} deneme',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // İlerleme badge
                _buildProgressBadge(improvement),
                
                // Toggle butonu
                if (widget.netData.length > 10) ...[
                  const SizedBox(width: 8),
                  _buildToggleButton(),
                ],
              ],
            ),
            
            const SizedBox(height: 20),

            // ✅ Grafik - swapAnimationDuration KALDIRILDI
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  minY: minValue,
                  maxY: maxValue,
                  minX: 0,
                  maxX: (displayData.length - 1).toDouble(),

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxValue - minValue) / 5,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),

                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade400, width: 1),
                      bottom: BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                  ),

                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: ((maxValue - minValue) / 5).ceilToDouble().clamp(1.0, double.infinity),
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= displayData.length) {
                            return const SizedBox.shrink();
                          }
                          final realExamNumber = startIndex + index + 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '$realExamNumber',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        displayData.length,
                        (i) => FlSpot(i.toDouble(), displayData[i]),
                      ),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: widget.color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isFirstOrLast = index == 0 || index == displayData.length - 1;
                          return FlDotCirclePainter(
                            radius: isFirstOrLast ? 5 : 4,
                            color: widget.color,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withOpacity(0.3),
                            widget.color.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],

                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final examNumber = startIndex + spot.x.toInt() + 1;
                          return LineTooltipItem(
                            '${widget.examType}\nDeneme $examNumber\n${spot.y.toStringAsFixed(2)} net',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                // ✅ swapAnimationDuration kaldırıldı - eski versiyonlarda yok
              ),
            ),

            const SizedBox(height: 18),

            // İstatistikler
            _buildQuickStats(displayData),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _showAll = !_showAll),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showAll ? Icons.unfold_less : Icons.unfold_more,
                size: 14,
                color: widget.color,
              ),
              const SizedBox(width: 4),
              Text(
                _showAll ? 'Son 10' : 'Tümü',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBadge(double percentage) {
    final isPositive = percentage >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List<double> data) {
    final avg = data.reduce((a, b) => a + b) / data.length;
    final max = data.reduce((a, b) => a > b ? a : b);
    final lastNet = data.last;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(
            label: 'Son Net',
            value: lastNet.toStringAsFixed(1),
            color: widget.color,
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _StatColumn(
            label: 'Ortalama',
            value: avg.toStringAsFixed(1),
            color: widget.color,
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _StatColumn(
            label: 'En Yüksek',
            value: max.toStringAsFixed(1),
            color: widget.color,
          ),
        ],
      ),
    );
  }

  double _calculateMaxValue(List<double> data) {
    if (data.isEmpty) return 100;
    final max = data.reduce((a, b) => a > b ? a : b);
    return (max * 1.1).ceilToDouble();
  }

  double _calculateMinValue(List<double> data) {
    if (data.isEmpty) return 0;
    final min = data.reduce((a, b) => a < b ? a : b);
    return (min * 0.9).clamp(0.0, double.infinity).floorToDouble();
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}