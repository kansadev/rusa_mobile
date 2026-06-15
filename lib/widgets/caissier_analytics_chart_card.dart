import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rusa/widgets/caissier_trend_insight.dart';

/// Carte réutilisable : titre, indication de tendance et graphique enfant.
class CaissierAnalyticsChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final CaissierTrendInsight? insight;
  final Widget chart;

  const CaissierAnalyticsChartCard({
    super.key,
    required this.title,
    this.subtitle,
    this.insight,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141A18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
          if (insight != null) ...[
            const SizedBox(height: 12),
            _InsightBanner(insight: insight!),
          ],
          const SizedBox(height: 14),
          chart,
        ],
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  final CaissierTrendInsight insight;

  const _InsightBanner({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insight.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, color: insight.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight.message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          if (insight.badge != null) ...[
            const SizedBox(width: 8),
            Text(
              insight.badge!,
              style: TextStyle(
                color: insight.color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
