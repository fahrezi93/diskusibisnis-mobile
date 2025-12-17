import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class CommentSection extends StatefulWidget {
  final List<dynamic> comments;
  final String type; // 'question' or 'answer'
  final String parentId;
  final Function(String content, String type, String id) onPostComment;

  const CommentSection({
    super.key,
    required this.comments,
    required this.type,
    required this.parentId,
    required this.onPostComment,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  bool _isExpanded = false;
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no comments and not expanded, show "Add a comment"
    if (widget.comments.isEmpty && !_isExpanded) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: InkWell(
          onTap: () => setState(() => _isExpanded = true),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              'Tambah komentar...',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isExpanded)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Lihat ${widget.comments.length} komentar',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.comments.isNotEmpty) ...[
                  ...widget.comments
                      .map((comment) => _buildCommentItem(comment)),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Tulis komentar...',
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                          hintStyle:
                              TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: _isPosting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF059669),
                                ),
                              )
                            : const Icon(LucideIcons.send,
                                size: 16, color: Color(0xFF059669)),
                        onPressed: _isPosting ? null : _submitComment,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _isExpanded = false),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Sembunyikan',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    final date =
        DateTime.tryParse(comment['created_at'].toString()) ?? DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment['content'],
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '– ${comment['author_name'] ?? 'Unknown'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(date),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);
    await widget.onPostComment(content, widget.type, widget.parentId);
    if (mounted) {
      _controller.clear();
      setState(() => _isPosting = false);
    }
  }
}
