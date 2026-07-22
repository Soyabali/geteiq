import '../models/month_report.dart';
import 'demo_data.dart';

/// Source of the "Month guest Report" payload.
///
/// Today it returns static [DemoData]; tomorrow swap the body for a REST call.
/// The screen depends only on this interface, so going live changes nothing
/// else.
abstract interface class MonthReportRepository {
  Future<MonthReport> fetchReport();
}

class StaticMonthReportRepository implements MonthReportRepository {
  const StaticMonthReportRepository();

  @override
  Future<MonthReport> fetchReport() async {
    // TODO(api): replace with the real endpoint, e.g.
    //   final res = await dio.get('/reports/month');
    //   return MonthReport.fromJson(res.data as Map<String, dynamic>);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return DemoData.monthReport;
  }
}
