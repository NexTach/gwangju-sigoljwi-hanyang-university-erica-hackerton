import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../ui/demo_report_state.dart';

abstract interface class ReportShareService {
  Future<void> share(WalkReport report);
}

class NativeReportShareService implements ReportShareService {
  @override
  Future<void> share(WalkReport report) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Road DNA 산책 리포트',
        text: report.shareText,
        title: '${report.date}의 산책 리포트',
      ),
    );
  }
}

final reportShareServiceProvider = Provider<ReportShareService>(
  (ref) => NativeReportShareService(),
);
