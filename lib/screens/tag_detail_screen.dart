import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/tag.dart' as tag_model;
import '../models/question.dart';
import '../services/api_service.dart';
import '../widgets/question_card.dart';

class TagDetailScreen extends StatefulWidget {
  final tag_model.TopicTag tag;

  const TagDetailScreen({super.key, required this.tag});

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends State<TagDetailScreen> {
  final ApiService _apiService = ApiService();
  List<Question> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final questions = await _apiService.getQuestions(tag: widget.tag.name);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tag questions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF334155)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${widget.tag.name}',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _isLoading ? 'Memuat...' : '${_questions.length} pertanyaan',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFECFDF5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.hash,
                            size: 20, color: Color(0xFF059669)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tentang Komunitas ${widget.tag.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            if (widget.tag.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  widget.tag.description!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Questions List
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF059669)),
                ),
              )
            else if (_questions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.search,
                            size: 32, color: Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada pertanyaan dengan tag #${widget.tag.name}',
                        style: const TextStyle(color: Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return QuestionCard(question: _questions[index]);
                },
              ),
          ],
        ),
      ),
    );
  }
}
