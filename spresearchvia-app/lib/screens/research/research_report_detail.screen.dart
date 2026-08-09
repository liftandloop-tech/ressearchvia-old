import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/research_report.dart';
import 'widgets/report_header_card.dart';
import 'widgets/key_highlight_item.dart';
import 'widgets/subscriber_badge.dart';
import '../../widgets/button.dart';
import 'widgets/youtube_video_player.dart';

class ResearchReportDetailScreen extends StatelessWidget {
  const ResearchReportDetailScreen({super.key, required this.report});

  final ResearchReport report;

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: ResearchReportDetailScreen building for report: ${report.id}');
    debugPrint('DEBUG: youtubeUrl: ${report.youtubeUrl}');
    return Scaffold(
      backgroundColor: const Color(0xffF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff163174)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Details',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xff163174),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ReportHeaderCard(
                title: report.title,
                publishedDate: report.publishedDate ?? 'Not available',
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Executive Summary',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff163174),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.executiveSummary ?? 'No summary available',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff374151),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            if (report.youtubeUrl != null && report.youtubeUrl!.trim().isNotEmpty) ...[
              () { 
                debugPrint('DEBUG: Calling YouTubeVideoPlayer with URL: "${report.youtubeUrl}"');
                return const SizedBox.shrink();
              }(),
              YouTubeVideoPlayer(videoUrl: report.youtubeUrl!.trim()),
            ],
            const SizedBox(height: 12),

            if (report.updates.isNotEmpty) ...[
              Container(
                color: const Color(0xffF9FAFB),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Updates',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff163174),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...report.updates.map((update) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xffFFFBEB),
                            border: Border.all(color: const Color(0xffFDE68A)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                update.text,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Color(0xff1F2937),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 14, color: Color(0xff6B7280)),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy hh:mm a')
                                        .format(update.timestamp),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Color(0xff6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            Container(
              color: const Color(0xffF9FAFB),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Key Highlights',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff163174),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...(report.keyHighlights ?? []).map((highlight) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: KeyHighlightItem(text: highlight),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SubscriberBadge(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Button(
                    title: 'View PDF Report',
                    buttonType: ButtonType.green,
                    icon: Icons.visibility,
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
