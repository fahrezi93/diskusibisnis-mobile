import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/question.dart';
import '../screens/question_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/avatar_helper.dart';

class QuestionCard extends StatelessWidget {
  final Question question;

  // Static formatter to avoid recreation on every build
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  const QuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates this widget's painting from the rest of the list
    return RepaintBoundary(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFCBD5E1)), // Slate 300
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      QuestionDetailScreen(questionId: question.id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    question.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A), // Slate 900
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Preview
                  Text(
                    question.plainContent,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569), // Slate 600
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Image (if any) - Optimized: removed ClipRRect, used imageBuilder
                  if (question.firstImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: CachedNetworkImage(
                        imageUrl: question.firstImage!,
                        height: 150,
                        width: double.infinity,
                        // Use imageBuilder to apply radius without expensive ClipRRect layer
                        imageBuilder: (context, imageProvider) => Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                        memCacheHeight: 450, // Cache smaller version
                        maxWidthDiskCache: 1000,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...question.tags.take(4).map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFECFDF5), // Emerald 50
                              borderRadius:
                                  BorderRadius.all(Radius.circular(999)),
                            ),
                            child: Text(
                              tag.name,
                              style: const TextStyle(
                                color: Color(0xFF047857), // Emerald 700
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )),
                      if (question.tags.length > 4)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9), // Slate 100
                            borderRadius:
                                BorderRadius.all(Radius.circular(999)),
                          ),
                          child: Text(
                            '+${question.tags.length - 4}',
                            style: const TextStyle(
                              color: Color(0xFF475569), // Slate 600
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFF1F5F9)), // Slate 100
                      ),
                    ),
                    child: Row(
                      children: [
                        // Upvotes
                        _buildStat(
                          LucideIcons.chevronUp,
                          '${question.upvotesCount}',
                          const Color(0xFF059669), // Emerald 600
                        ),
                        const SizedBox(width: 10),
                        // Answers
                        _buildStat(
                          LucideIcons.messageCircle,
                          '${question.answersCount}',
                          question.answersCount > 0
                              ? const Color(0xFF059669)
                              : const Color(0xFF94A3B8),
                          isActive: question.answersCount > 0,
                        ),
                        const SizedBox(width: 10),
                        // Views
                        _buildStat(
                          LucideIcons.eye,
                          '${question.viewsCount}',
                          const Color(0xFF94A3B8), // Slate 400
                          textColor: const Color(0xFF334155), // Slate 700
                        ),
                        const Spacer(),
                        // Time
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.clock,
                                size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 3),
                            Text(
                              _dateFormat.format(question.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Author Info
                  GestureDetector(
                    onTap: question.author.id != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfileScreen(userId: question.author.id!),
                              ),
                            );
                          }
                        : null,
                    child: Row(
                      children: [
                        AvatarHelper.buildAvatarWithBadge(
                          avatarUrl: question.author.avatar,
                          name: question.author.name,
                          reputation: question.author.reputation,
                          isVerified: question.author.isVerified,
                          radius: 10,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  question.author.name,
                                  style: const TextStyle(
                                    fontSize:
                                        13, // slightly smaller text matching visual hierarchy
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (question.author.isVerified)
                                AvatarHelper.getVerifiedBadge(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text, Color iconColor,
      {Color? textColor, bool isActive = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color:
                textColor ?? (isActive ? iconColor : const Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}
