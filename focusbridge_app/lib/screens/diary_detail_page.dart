import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DiaryDetailPage extends StatelessWidget {
  final DateTime date;
  final Map<String, dynamic>? overview;

  const DiaryDetailPage({super.key, required this.date, this.overview});

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('yyyy/MM/dd (EEE)', 'zh_TW').format(date);
    final noDiaryFromOverview = (overview == null || !(overview?['hasDiary'] ?? false));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF9CAF88),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: FutureBuilder<Map<String, dynamic>?>(
            // 這裡應改成你的日記服務呼叫，例如 DiaryService.fetchDiaryByDate(date)
            future: Future.value(overview),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('讀取失敗：${snapshot.error}', style: const TextStyle(color: Colors.red)),
                );
              }

              final detail = snapshot.data;
              if (detail == null || noDiaryFromOverview) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('這天尚未留下日記。', style: TextStyle(fontSize: 14)),
                  ],
                );
              }

              final mood = detail['mood'] as String?;
              final content = detail['content'] as String? ?? '';
              final titleText = detail['title'] as String? ?? '';
              final aiText = detail['ai_analysis'] as String? ?? '（暫無 AI 分析）';

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 6),
                    if (mood != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(mood, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (titleText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(titleText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          Text(content.isEmpty ? '（無內容）' : content, style: const TextStyle(fontSize: 14, height: 1.6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AICard(title: 'AI 回饋', content: aiText),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AICard extends StatelessWidget {
  final String title;
  final String content;

  const _AICard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
