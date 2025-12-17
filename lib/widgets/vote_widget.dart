import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VoteWidget extends StatelessWidget {
  final int upvotes;
  final int downvotes;
  final String? userVote; // 'upvote', 'downvote', or null
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final bool isCompact;

  const VoteWidget({
    super.key,
    required this.upvotes,
    required this.downvotes,
    this.userVote,
    required this.onUpvote,
    required this.onDownvote,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final score = upvotes - downvotes;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Upvote Button
        Material(
          color: userVote == 'upvote'
              ? const Color(0xFFECFDF5) // Green background if active
              : const Color(0xFFF8FAFC), // Grey background if inactive
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onUpvote,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: userVote == 'upvote'
                    ? Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3))
                    : null,
              ),
              child: Icon(
                LucideIcons.chevronUp,
                size: 20,
                color: userVote == 'upvote'
                    ? const Color(0xFF059669)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Score & Text
        Text(
          '$score',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: score > 0
                ? const Color(0xFF059669)
                : score < 0
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF0F172A),
          ),
        ),
        if (!isCompact) ...[
          const SizedBox(width: 4),
          const Text(
            'votes',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],

        const SizedBox(width: 8),

        // Downvote Button
        Material(
          color: userVote == 'downvote'
              ? const Color(0xFFFEF2F2) // Red background if active
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onDownvote,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: userVote == 'downvote'
                    ? Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.3))
                    : null,
              ),
              child: Icon(
                LucideIcons.chevronDown,
                size: 20,
                color: userVote == 'downvote'
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
