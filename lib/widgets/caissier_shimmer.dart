import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer réutilisable pour les écrans caissier (thème sombre).
class CaissierShimmer {
  static const _base = Color(0xFF1A211E);
  static const _highlight = Color(0xFF2A332E);

  static Widget wrap(Widget child) {
    return Shimmer.fromColors(
      baseColor: _base,
      highlightColor: _highlight,
      child: child,
    );
  }

  static Widget box({
    double? width,
    double? height,
    double radius = 12,
    Color color = Colors.white,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  static Widget circle(double size, {Color color = Colors.white}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Squelette de chargement du dashboard caissier.
class CaissierDashboardShimmer extends StatelessWidget {
  const CaissierDashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        CaissierShimmer.wrap(
          Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(20, top + 16, 20, 54),
                decoration: const BoxDecoration(
                  color: Color(0xFF29F58B),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    CaissierShimmer.circle(42, color: const Color(0xFF093120)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CaissierShimmer.box(
                            height: 12,
                            width: 90,
                            radius: 6,
                            color: const Color(0xFF093120),
                          ),
                          const SizedBox(height: 8),
                          CaissierShimmer.box(
                            height: 16,
                            width: 140,
                            radius: 6,
                            color: const Color(0xFF093120),
                          ),
                        ],
                      ),
                    ),
                    CaissierShimmer.circle(40, color: const Color(0xFF093120)),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CaissierShimmer.box(
                    height: 110,
                    radius: 24,
                    color: const Color(0xFF141A18),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CaissierShimmer.wrap(
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (_) => CaissierShimmer.box(
                      width: 60,
                      height: 60,
                      radius: 18,
                      color: const Color(0xFF141A18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CaissierShimmer.box(
                  height: 220,
                  radius: 24,
                  color: const Color(0xFF141A18),
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < 3; i++) ...[
                  CaissierShimmer.box(
                    height: 72,
                    radius: 20,
                    color: const Color(0xFF141A18),
                  ),
                  if (i < 2) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Squelette de chargement de l'écran statistiques détaillées.
class CaissierStatsDetailsShimmer extends StatelessWidget {
  const CaissierStatsDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        CaissierShimmer.wrap(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CaissierShimmer.box(
                height: 14,
                width: 120,
                radius: 6,
                color: const Color(0xFF141A18),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < 4; i++) ...[
                CaissierShimmer.box(
                  height: i == 0 ? 260 : 200,
                  radius: 20,
                  color: const Color(0xFF141A18),
                ),
                const SizedBox(height: 14),
              ],
              CaissierShimmer.box(
                height: 14,
                width: 160,
                radius: 6,
                color: const Color(0xFF141A18),
              ),
              const SizedBox(height: 14),
              CaissierShimmer.box(
                height: 180,
                radius: 20,
                color: const Color(0xFF141A18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
