import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/widgets/caissier_trend_insight.dart';

/// Courbe de métrique (billets, transactions…) — style dashboard caissier.
class CaissierMetricLineChart extends StatefulWidget {
  final List<MetricChartPoint> points;
  final double height;
  final Color lineColor;
  final String? valueSuffix;

  const CaissierMetricLineChart({
    super.key,
    required this.points,
    this.height = 110,
    this.lineColor = const Color(0xFF29F58B),
    this.valueSuffix,
  });

  @override
  State<CaissierMetricLineChart> createState() =>
      _CaissierMetricLineChartState();
}

class _CaissierMetricLineChartState extends State<CaissierMetricLineChart>
    with SingleTickerProviderStateMixin {
  static const _grid = Color(0x14FFFFFF);

  late final AnimationController _controller;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant CaissierMetricLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
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

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Aucune donnée sur la période',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      );
    }

    final maxValue = widget.points
        .map((p) => p.value)
        .fold<double>(0, (a, b) => math.max(a, b));
    final yMax = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
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
                    painter: _MetricLinePainter(
                      points: widget.points,
                      progress: Curves.easeOutCubic.transform(_controller.value),
                      yMax: yMax,
                      selectedIndex: _selectedIndex,
                      lineColor: widget.lineColor,
                      grid: _grid,
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < widget.points.length; i++)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _selectedIndex =
                                      _selectedIndex == i ? null : i;
                                });
                              },
                              child: const SizedBox.expand(),
                            ),
                          ),
                      ],
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
            for (var i = 0; i < widget.points.length; i++)
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
                          '${widget.points[i].value.toStringAsFixed(0)}${widget.valueSuffix ?? ''}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: widget.lineColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ] else if (widget.points[i].value > 0)
                        const SizedBox(height: 11)
                      else
                        const SizedBox(height: 11),
                      Text(
                        widget.points[i].label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _selectedIndex == i
                              ? widget.lineColor
                              : Colors.white38,
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

class _MetricLinePainter extends CustomPainter {
  final List<MetricChartPoint> points;
  final double progress;
  final double yMax;
  final int? selectedIndex;
  final Color lineColor;
  final Color grid;

  _MetricLinePainter({
    required this.points,
    required this.progress,
    required this.yMax,
    required this.selectedIndex,
    required this.lineColor,
    required this.grid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 8.0;
    const bottomPad = 8.0;
    final plotH = size.height - topPad - bottomPad;
    final count = points.length;
    if (count == 0 || plotH <= 0) return;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = topPad + plotH * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final coords = <Offset>[];
    for (var i = 0; i < count; i++) {
      final x = count == 1
          ? size.width / 2
          : (size.width / (count - 1)) * i;
      final ratio = (points[i].value / yMax).clamp(0.0, 1.0);
      final y = topPad + plotH * (1 - ratio * progress);
      coords.add(Offset(x, y));
    }

    if (coords.length > 1) {
      final path = Path()..moveTo(coords.first.dx, coords.first.dy);
      for (var i = 1; i < coords.length; i++) {
        final prev = coords[i - 1];
        final cur = coords[i];
        final cx = (prev.dx + cur.dx) / 2;
        path.cubicTo(cx, prev.dy, cx, cur.dy, cur.dx, cur.dy);
      }

      final fillPath = Path.from(path)
        ..lineTo(coords.last.dx, topPad + plotH)
        ..lineTo(coords.first.dx, topPad + plotH)
        ..close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lineColor.withValues(alpha: 0.22),
              lineColor.withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromLTWH(0, topPad, size.width, plotH)),
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (var i = 0; i < coords.length; i++) {
      final isSelected = selectedIndex == i;
      final active = points[i].value > 0 || isSelected;
      canvas.drawCircle(
        coords[i],
        isSelected ? 5.5 : (active ? 4.0 : 3.0),
        Paint()..color = active ? lineColor : Colors.white24,
      );
      if (isSelected) {
        canvas.drawCircle(
          coords[i],
          7.5,
          Paint()
            ..color = lineColor.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MetricLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.progress != progress ||
        oldDelegate.yMax != yMax ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
