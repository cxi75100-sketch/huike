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
    final after =
        hasMarker && known.length == items.length && active < 0 && next < 0;

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
                _StatusNote(
                  label: '下一节还有${_duration(items[next].start! - minute)}',
                  location: 'before',
                ),
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  _Gap(
                    previous: items.take(i).fold<int?>(null, (end, item) {
                      if (item.end == null) return end;
                      return end == null || item.end! > end ? item.end : end;
                    }),
                    next: items[i].start,
                    remaining: hasMarker && active < 0 && next == i
                        ? items[i].start! - minute
                        : null,
                  ),
                _CourseNode(
                  item: items[i],
                  nowMinute: minute,
                  highlighted: hasMarker && active == i,
                  onTap: () => onCourseTap(items[i].course),
                ),
              ],
              if (after) const _StatusNote(label: '今日课程已结束', location: 'after'),
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
  const _Gap({
    required this.previous,
    required this.next,
    required this.remaining,
  });
  final int? previous;
  final int? next;
  final int? remaining;

  @override
  Widget build(BuildContext context) {
    if (remaining != null) {
      return _StatusNote(
        label: '下一节还有${_duration(remaining!)}',
        location: 'between',
      );
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

String _duration(int minutes) => minutes < 60
    ? '$minutes分钟'
    : '${minutes ~/ 60}小时${minutes % 60 == 0 ? '' : '${minutes % 60}分钟'}';

class _StatusNote extends StatelessWidget {
  const _StatusNote({required this.label, required this.location});
  final String label;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('today-now-$location'),
      padding: const EdgeInsets.fromLTRB(66, 12, 0, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: AppTheme.paletteOf(context).inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _CourseNode extends StatelessWidget {
  const _CourseNode({
    required this.item,
    required this.nowMinute,
    required this.highlighted,
    required this.onTap,
  });
  final _TimedCourse item;
  final int nowMinute;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final course = item.course;
    final tint = courseTint(course.colorKey, Theme.of(context).brightness);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 66,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
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
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                      if (item.end != null)
                        Text(
                          item.range!.$2,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.2,
                            color: palette.inkTertiary,
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
                    backgroundColor: highlighted
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
            constraints: const BoxConstraints(minHeight: 134 * 0.75),
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
                tint: tint.onChip,
                solidColor: tint.card,
                radius: 16,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (highlighted)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          key: ValueKey('today-now-course-${course.id}'),
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: palette.accentSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '进行中 · ${item.range!.$2}结束',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: palette.ink,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      course.name,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: tint.onCard,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _Info(
                          item.range == null
                              ? '时间未定'
                              : '${item.range!.$1} - ${item.range!.$2}',
                          color: tint.onCard,
                        ),
                        _Info(sectionRangeLabel(course), color: tint.onCard),
                        if (!highlighted)
                          _Info(item.status(nowMinute), color: tint.onCard),
                      ],
                    ),
                    if (course.classroom.isNotEmpty ||
                        course.teacher.isNotEmpty)
                      Wrap(
                        spacing: 10,
                        children: [
                          if (course.classroom.isNotEmpty)
                            _Info(course.classroom, color: tint.onCard),
                          if (course.teacher.isNotEmpty)
                            _Info(course.teacher, color: tint.onCard),
                        ],
                      ),
                    _Info('第 ${course.weeks.join('、')} 周', color: tint.onCard),
                    if (course.note.isNotEmpty)
                      _Info(course.note, color: tint.onCard),
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
  const _Info(this.text, {required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: 12, height: 1.25, color: color));
}
