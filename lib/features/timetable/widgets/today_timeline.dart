import 'package:flutter/material.dart';

import '../../../core/glass/glass_surface.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/course_colors.dart';
import '../../../models/bell_schedule.dart';
import '../../../models/course.dart';
import '../../../services/course_time_service.dart';
import 'course_hero.dart';

/// Content-sized course nodes on a continuous time rail. Minutes determine
/// order, status and gap category, never card height or a precise Y coordinate.
class TodayTimeline extends StatelessWidget {
  const TodayTimeline({
    super.key,
    required this.courses,
    required this.schedule,
    required this.now,
    required this.onCourseTap,
    this.showCurrentTime = true,
  });

  final List<Course> courses;
  final BellSchedule schedule;
  final DateTime now;
  final ValueChanged<Course> onCourseTap;
  final bool showCurrentTime;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final items = [for (final course in courses) _TimedCourse(course, schedule)]
      ..sort((a, b) {
        final time = (a.start ?? 1440).compareTo(b.start ?? 1440);
        if (time != 0) return time;
        final section = a.course.startSection.compareTo(b.course.startSection);
        return section != 0 ? section : a.course.id.compareTo(b.course.id);
      });
    final minute = now.hour * 60 + now.minute;
    final active = items.indexWhere((item) => item.contains(minute));
    // A single marker: prefer an ongoing course, otherwise the next known
    // start. Unknown times cannot be assigned a fabricated clock position.
    final next = items.indexWhere(
      (item) => item.start != null && minute < item.start!,
    );
    final known = items
        .where((item) => item.start != null && item.end != null)
        .toList();
    final hasMarker = showCurrentTime && known.isNotEmpty;
    final before = hasMarker && active < 0 && next == 0;
    final after = hasMarker && active < 0 && next < 0;
    final clock =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (items.isEmpty) {
      return Center(
        child: Text('今天没有课程', style: TextStyle(color: palette.inkSecondary)),
      );
    }
    return SingleChildScrollView(
      key: const ValueKey('today-timeline-scroll'),
      padding: const EdgeInsets.fromLTRB(10, 4, 14, 20),
      child: Stack(
        children: [
          Positioned(
            left: 53,
            top: 0,
            bottom: 0,
            width: 1,
            child: ColoredBox(color: palette.hairlineStrong),
          ),
          Column(
            children: [
              if (before)
                _NowBand(clock: clock, label: '尚未开始', location: 'before'),
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  _Gap(
                    previous: items.take(i).fold<int?>(null, (end, item) {
                      if (item.end == null) return end;
                      return end == null || item.end! > end ? item.end : end;
                    }),
                    next: items[i].start,
                    clock: hasMarker && active < 0 && next == i ? clock : null,
                  ),
                _CourseNode(
                  item: items[i],
                  nowMinute: minute,
                  clock: hasMarker && active == i ? clock : null,
                  onTap: () => onCourseTap(items[i].course),
                ),
              ],
              if (after)
                _NowBand(clock: clock, label: '今日课程已结束', location: 'after'),
            ],
          ),
        ],
      ),
    );
  }
}

int? _minute(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }
  return hour * 60 + minute;
}

class _TimedCourse {
  _TimedCourse(this.course, BellSchedule schedule) {
    range = const CourseTimeService().resolve(course, schedule);
    start = range == null ? null : _minute(range!.$1);
    end = range == null ? null : _minute(range!.$2);
    if (start == null || end == null || end! <= start!) {
      start = null;
      end = null;
    }
  }
  final Course course;
  late final (String, String)? range;
  int? start;
  int? end;
  bool contains(int minute) =>
      start != null && end != null && minute >= start! && minute < end!;
  String status(int minute) => start == null
      ? '时间未定'
      : contains(minute)
      ? '进行中'
      : minute < start!
      ? '尚未开始'
      : '已结束';
}

class _Gap extends StatelessWidget {
  const _Gap({required this.previous, required this.next, required this.clock});
  final int? previous;
  final int? next;
  final String? clock;

  @override
  Widget build(BuildContext context) {
    if (clock != null) {
      return _NowBand(clock: clock!, label: '课间', location: 'between');
    }
    final gap = previous == null || next == null ? 0 : next! - previous!;
    final height = gap <= 10
        ? 16.0
        : gap <= 60
        ? 24.0
        : 40.0;
    return SizedBox(
      height: height,
      child: gap > 60
          ? Row(
              children: [
                const SizedBox(width: 66),
                Text(
                  '间隔 ${gap ~/ 60}小时${gap % 60 == 0 ? '' : '${gap % 60}分'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.paletteOf(context).inkTertiary,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

class _NowBand extends StatelessWidget {
  const _NowBand({
    required this.clock,
    required this.label,
    required this.location,
  });
  final String clock;
  final String label;
  final String location;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.paletteOf(context).accent;
    return Semantics(
      label: '现在 $clock，$label',
      child: SizedBox(
        key: ValueKey('today-now-$location'),
        height: 40,
        child: Row(
          children: [
            SizedBox(
              width: 49,
              child: Text(
                clock,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, color: accent),
              ),
            ),
            const SizedBox(width: 1),
            CircleAvatar(radius: 3, backgroundColor: accent),
            Expanded(child: Container(height: 1, color: accent)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, color: accent)),
          ],
        ),
      ),
    );
  }
}

class _CourseNode extends StatelessWidget {
  const _CourseNode({
    required this.item,
    required this.nowMinute,
    required this.clock,
    required this.onTap,
  });
  final _TimedCourse item;
  final int nowMinute;
  final String? clock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final course = item.course;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 66,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.start == null ? '待定' : item.range!.$1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                      if (item.end != null)
                        Text(
                          item.range!.$2,
                          style: TextStyle(
                            fontSize: 10,
                            color: palette.inkTertiary,
                          ),
                        ),
                      if (clock != null)
                        Semantics(
                          label: '现在 $clock，${course.name}进行中',
                          child: Padding(
                            key: ValueKey('today-now-course-${course.id}'),
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '现在\n$clock',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10,
                                color: palette.accent,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CircleAvatar(
                    radius: 3,
                    backgroundColor: clock != null
                        ? palette.accent
                        : palette.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ConstrainedBox(
            key: ValueKey('today-course-${course.id}'),
            constraints: const BoxConstraints(minHeight: 134),
            child: CourseHero(
              tag: CourseHeroTag.forDetails(
                course,
                CourseHeroSourceContext.today,
              ),
              child: GlassSurface(
                interactive: true,
                onTap: onTap,
                semanticLabel: [
                  course.name,
                  if (item.range != null) '${item.range!.$1}至${item.range!.$2}',
                  sectionRangeLabel(course),
                  item.status(nowMinute),
                  course.classroom,
                  course.teacher,
                  '第 ${course.weeks.join('、')} 周',
                  course.note,
                ].where((value) => value.isNotEmpty).join('，'),
                blurSigma: 0,
                tint: courseTint(
                  course.colorKey,
                  Theme.of(context).brightness,
                ).onChip,
                radius: 16,
                padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _Info(
                      '${item.range == null ? '时间未定' : '${item.range!.$1} - ${item.range!.$2}'} · ${sectionRangeLabel(course)}',
                      color: palette.inkSecondary,
                    ),
                    _Info(item.status(nowMinute), color: palette.accent),
                    if (course.classroom.isNotEmpty)
                      _Info(course.classroom, color: palette.inkSecondary),
                    if (course.teacher.isNotEmpty)
                      _Info(course.teacher, color: palette.inkSecondary),
                    _Info(
                      '第 ${course.weeks.join('、')} 周',
                      color: palette.inkTertiary,
                      maxLines: 1,
                    ),
                    if (course.note.isNotEmpty)
                      _Info(course.note, color: palette.inkTertiary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.text, {required this.color, this.maxLines = 2});
  final String text;
  final Color color;
  final int maxLines;
  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(fontSize: 12, height: 1.25, color: color),
  );
}
