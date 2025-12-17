import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum ReputationTier {
  newbie,
  expert,
  master,
  legend,
}

class ReputationBadge extends StatelessWidget {
  final int reputationPoints;
  final bool showLabel;
  final bool compact; // For smaller versions like in lists

  const ReputationBadge({
    super.key,
    required this.reputationPoints,
    this.showLabel = true,
    this.compact = false,
  });

  ReputationTier get _tier {
    if (reputationPoints >= 1000) return ReputationTier.legend;
    if (reputationPoints >= 500) return ReputationTier.master;
    if (reputationPoints >= 100) return ReputationTier.expert;
    return ReputationTier.newbie;
  }

  @override
  Widget build(BuildContext context) {
    if (_tier == ReputationTier.newbie) return const SizedBox.shrink();

    final config = _getTierConfig(_tier);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: config.bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: config.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 10, color: config.textColor),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                config.label.toUpperCase(),
                style: TextStyle(
                  color: config.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.textColor),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              config.label,
              style: TextStyle(
                color: config.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _TierConfig _getTierConfig(ReputationTier tier) {
    switch (tier) {
      case ReputationTier.legend:
        return _TierConfig(
          label: 'Legend',
          textColor: const Color(0xFFD97706), // Amber 600
          bgColor: const Color(0xFFFFFBEB), // Amber 50
          borderColor: const Color(0xFFFCD34D), // Amber 300
          icon: LucideIcons.crown,
          gradientColors: [const Color(0xFFF59E0B), const Color(0xFFEAB308)],
        );
      case ReputationTier.master:
        return _TierConfig(
          label: 'Master',
          textColor: const Color(0xFF9333EA), // Purple 600
          bgColor: const Color(0xFFFAF5FF), // Purple 50
          borderColor: const Color(0xFFD8B4FE), // Purple 300
          icon: LucideIcons.trophy,
          gradientColors: [const Color(0xFFA855F7), const Color(0xFFEC4899)],
        );
      case ReputationTier.expert:
        return _TierConfig(
          label: 'Expert',
          textColor: const Color(0xFF059669), // Emerald 600
          bgColor: const Color(0xFFECFDF5), // Emerald 50
          borderColor: const Color(0xFF6EE7B7), // Emerald 300
          icon: LucideIcons.zap,
          gradientColors: [const Color(0xFF10B981), const Color(0xFF14B8A6)],
        );
      case ReputationTier.newbie:
        return _TierConfig(
          label: 'Newbie',
          textColor: const Color(0xFF64748B), // Slate 500
          bgColor: const Color(0xFFF8FAFC), // Slate 50
          borderColor: const Color(0xFFE2E8F0), // Slate 200
          icon: LucideIcons.award,
          gradientColors: [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)],
        );
    }
  }
}

class _TierConfig {
  final String label;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final List<Color> gradientColors;

  _TierConfig({
    required this.label,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.gradientColors,
  });
}

// Helper to get next level info
class NextLevelInfo {
  final String name;
  final int pointsNeeded;
  final double progress;

  NextLevelInfo({
    required this.name,
    required this.pointsNeeded,
    required this.progress,
  });
}

NextLevelInfo? getNextLevel(int points) {
  const levels = [100, 500, 1000];
  const levelNames = ['Expert', 'Master', 'Legend'];

  for (int i = 0; i < levels.length; i++) {
    if (points < levels[i]) {
      final prevLevel = i == 0 ? 0 : levels[i - 1];
      final progress = ((points - prevLevel) / (levels[i] - prevLevel)) * 100;
      return NextLevelInfo(
        name: levelNames[i],
        pointsNeeded: levels[i] - points,
        progress: progress.clamp(0, 100),
      );
    }
  }
  return null; // Already at max level (Legend)
}

// Level progress card for profile
class ReputationProgress extends StatelessWidget {
  final int reputationPoints;

  const ReputationProgress({super.key, required this.reputationPoints});

  ReputationTier get _tier {
    if (reputationPoints >= 1000) return ReputationTier.legend;
    if (reputationPoints >= 500) return ReputationTier.master;
    if (reputationPoints >= 100) return ReputationTier.expert;
    return ReputationTier.newbie;
  }

  _TierConfig _getTierConfig(ReputationTier tier) {
    switch (tier) {
      case ReputationTier.legend:
        return _TierConfig(
          label: 'Legend',
          textColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFCD34D),
          icon: LucideIcons.crown,
          gradientColors: [const Color(0xFFF59E0B), const Color(0xFFEAB308)],
        );
      case ReputationTier.master:
        return _TierConfig(
          label: 'Master',
          textColor: const Color(0xFF9333EA),
          bgColor: const Color(0xFFFAF5FF),
          borderColor: const Color(0xFFD8B4FE),
          icon: LucideIcons.trophy,
          gradientColors: [const Color(0xFFA855F7), const Color(0xFFEC4899)],
        );
      case ReputationTier.expert:
        return _TierConfig(
          label: 'Expert',
          textColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
          borderColor: const Color(0xFF6EE7B7),
          icon: LucideIcons.zap,
          gradientColors: [const Color(0xFF10B981), const Color(0xFF14B8A6)],
        );
      case ReputationTier.newbie:
        return _TierConfig(
          label: 'Newbie',
          textColor: const Color(0xFF64748B),
          bgColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          icon: LucideIcons.award,
          gradientColors: [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getTierConfig(_tier);
    final nextLevelInfo = getNextLevel(reputationPoints);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current level header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: config.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: config.gradientColors[0].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(config.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: config.textColor,
                    ),
                  ),
                  Text(
                    '$reputationPoints poin reputasi',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Progress to next level
          if (nextLevelInfo != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menuju ${nextLevelInfo.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${nextLevelInfo.pointsNeeded} poin lagi',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: nextLevelInfo.progress / 100,
                backgroundColor: Colors.white.withOpacity(0.5),
                valueColor:
                    AlwaysStoppedAnimation<Color>(config.gradientColors[0]),
                minHeight: 8,
              ),
            ),
          ],

          // Max level message
          if (nextLevelInfo == null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.sparkles, size: 14, color: config.textColor),
                const SizedBox(width: 4),
                Text(
                  'Level tertinggi tercapai!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: config.textColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
