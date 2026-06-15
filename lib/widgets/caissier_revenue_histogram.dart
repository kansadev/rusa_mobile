import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Point de données pour l'histogramme des recettes.
class RevenueHistogramBar {
  final String label;
  final double value;

  const RevenueHistogramBar({
    required this.label,
    required this.value,
  });
}

/// Histogramme des recettes journalières (style dashboard caissier).
class CaissierRevenueHistogram extends StatefulWidget {
  final List<RevenueHistogramBar> bars;
  final String devise;
  final double height;

  const CaissierRevenueHistogram({
    super.key,
    required this.bars,
    this.devise = 'FC',
    this.height = 118,
  });

  /// Construit les barres à partir de `recettesJournalieres` (API dashboard).
  static List<RevenueHistogramBar> fromRecettesJournalieres(
    List<dynamic> recettes, {
    int maxDays = 7,
  }) {
    if (recettes.isEmpty) return [];

    final items = recettes
        .map(
          (e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
        )
        .where((m) => m.isNotEmpty)
        .toList();

    final slice = items.length > maxDays ? items.sublist(items.length - maxDays) : items;

    return slice.map((r) {
      final m = r['montantTotal'];
      final v = m is num ? m.toDouble() : double.tryParse('$m') ?? 0;
      final dt = DateTime.tryParse(r['date']?.toString() ?? '');
      final label = dt != null
          ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}'
          : '';
      return RevenueHistogramBar(label: label, value: v);
    }).toList();
  }

  @override
  State<CaissierRevenueHistogram> createState() =>
      _CaissierRevenueHistogramState();
}

class _CaissierRevenueHistogramState extends State<CaissierRevenueHistogram>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF29F58B);
  static const _inactive = Color(0x3DFFFFFF); // white24
  static const _grid = Color(0x14FFFFFF);

  late final AnimationController _controller;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant CaissierRevenueHistogram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bars != widget.bars) {
      _selectedIndex = null;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _compactAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      final k = value / 1000;
      return k >= 10 ? '${k.toStringAsFixed(0)}k' : '${k.toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  String _fullAmount(double value) {
    return '${value.toStringAsFixed(0)} ${widget.devise}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bars.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = widget.bars
        .map((b) => b.value)
        .fold<double>(0, (a, b) => math.max(a, b));
    final yMax = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, widget.height),
                    painter: _RevenueHistogramPainter(
                      bars: widget.bars,
                      progress: Curves.easeOutCubic.transform(_controller.value),
                      yMax: yMax,
                      selectedIndex: _selectedIndex,
                      accent: _accent,
                      inactive: _inactive,
                      grid: _grid,
                    ),
                    child: _HistogramTouchLayer(
                      bars: widget.bars,
                      progress: _controller.value,
                      yMax: yMax,
                      chartHeight: widget.height,
                      selectedIndex: _selectedIndex,
                      onSelect: (index) {
                        setState(() {
                          _selectedIndex = _selectedIndex == index ? null : index;
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < widget.bars.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = _selectedIndex == i ? null : i;
                    });
                  },
                  child: Column(
                    children: [
                      if (_selectedIndex == i) ...[
                        Text(
                          _fullAmount(widget.bars[i].value),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: _accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ] else if (widget.bars[i].value > 0) ...[
                        Text(
                          _compactAmount(widget.bars[i].value),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ] else
                        const SizedBox(height: 11),
                      Text(
                        widget.bars[i].label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _selectedIndex == i ? _accent : Colors.white38,
                          fontSize: 9,
                          fontWeight: _selectedIndex == i
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HistogramTouchLayer extends StatelessWidget {
  final List<RevenueHistogramBar> bars;
  final double progress;
  final double yMax;
  final double chartHeight;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const _HistogramTouchLayer({
    required this.bars,
    required this.progress,
    required this.yMax,
    required this.chartHeight,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < bars.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(i),
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }
}

class _RevenueHistogramPainter extends CustomPainter {
  final List<RevenueHistogramBar> bars;
  final double progress;
  final double yMax;
  final int? selectedIndex;
  final Color accent;
  final Color inactive;
  final Color grid;

  _RevenueHistogramPainter({
    required this.bars,
    required this.progress,
    required this.yMax,
    required this.selectedIndex,
    required this.accent,
    required this.inactive,
    required this.grid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 0.0;
    const rightPad = 0.0;
    const topPad = 6.0;
    const bottomPad = 4.0;

    final plotW = size.width - leftPad - rightPad;
    final plotH = size.height - topPad - bottomPad;
    final count = bars.length;
    if (count == 0 || plotW <= 0 || plotH <= 0) return;

    final gap = plotW * 0.04 / count;
    final barW = (plotW - gap * (count + 1)) / count;

    // Grille horizontale
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = topPad + plotH * (1 - i / 4);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );
    }

    // Axe bas
    canvas.drawLine(
      Offset(leftPad, topPad + plotH),
      Offset(size.width - rightPad, topPad + plotH),
      Paint()
        ..color = grid
        ..strokeWidth = 1,
    );

    for (var i = 0; i < count; i++) {
      final bar = bars[i];
      final x = leftPad + gap + i * (barW + gap);
      final ratio = (bar.value / yMax).clamp(0.0, 1.0);
      final targetH = bar.value > 0 ? math.max(ratio * plotH, 6.0) : 4.0;
      final barH = targetH * progress;
      final y = topPad + plotH - barH;

      final isSelected = selectedIndex == i;
      final isActive = bar.value > 0;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barW, barH),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );

      if (isActive) {
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: isSelected
                ? [accent.withValues(alpha: 0.75), accent]
                : [accent.withValues(alpha: 0.45), accent.withValues(alpha: 0.9)],
          ).createShader(rect.outerRect);
        canvas.drawRRect(rect, paint);

        if (isSelected) {
          canvas.drawRRect(
            rect,
            Paint()
              ..color = accent.withValues(alpha: 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      } else {
        canvas.drawRRect(
          rect,
          Paint()..color = inactive,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueHistogramPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.progress != progress ||
        oldDelegate.yMax != yMax ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
