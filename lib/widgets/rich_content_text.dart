import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget untuk menampilkan konten dengan @mentions dan links yang clickable
class RichContentText extends StatelessWidget {
  final String content;
  final TextStyle? style;
  final void Function(String username)? onMentionTap;
  final int? maxLines;
  final TextOverflow? overflow;

  const RichContentText({
    super.key,
    required this.content,
    this.style,
    this.onMentionTap,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ??
        const TextStyle(
          fontSize: 15,
          color: Color(0xFF334155),
          height: 1.6,
        );

    // Parse content and build rich text spans
    final spans = _parseContent(content, defaultStyle, context);

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  List<TextSpan> _parseContent(
      String text, TextStyle defaultStyle, BuildContext context) {
    final List<TextSpan> spans = [];

    // Combined regex for @mentions and URLs
    // Match @username or URLs (http/https)
    final pattern = RegExp(
      r'(@[a-zA-Z0-9_]+)|(https?://[^\s<>\[\]{}|\\^]+)',
      caseSensitive: false,
    );

    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      final matchedText = match.group(0)!;

      if (matchedText.startsWith('@')) {
        // This is a mention
        final username = matchedText.substring(1); // Remove @
        spans.add(TextSpan(
          text: matchedText,
          style: defaultStyle.copyWith(
            color: const Color(0xFF059669),
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (onMentionTap != null) {
                onMentionTap!(username);
              }
            },
        ));
      } else {
        // This is a URL
        spans.add(TextSpan(
          text: matchedText,
          style: defaultStyle.copyWith(
            color: const Color(0xFF2563EB),
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFF2563EB),
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.tryParse(matchedText);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return spans;
  }
}
