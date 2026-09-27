import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/timetable/services/weekly_location_formatter.dart';

void main() {
  test('Weekly strips campus and known training centre zone', () {
    for (final room in ['明志楼404', '致远楼A512', '明志楼223']) {
      expect(compactWeeklyLocation('九龙湖校区$room'), room);
    }
    expect(compactWeeklyLocation('九龙湖校区西区实训中心3-A010'), '实训中心3-A010');
  });
  test('Unknown addresses and campus-only values remain meaningful', () {
    for (final value in ['', '九龙湖校区', '西区A512', '实训中心3-A010', '在线课堂']) {
      expect(compactWeeklyLocation(value), value);
    }
    expect(compactWeeklyLocation('  九龙湖校区 明志楼404  '), '明志楼404');
    expect(compactWeeklyLocation('九龙湖校区西区A512'), '西区A512');
  });
}
