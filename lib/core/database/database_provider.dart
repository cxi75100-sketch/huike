import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

/// 全局唯一数据库。测试里用 ProviderScope overrides 替换为内存库。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'huike_timetable.sqlite');
      return NativeDatabase.createInBackground(File(path));
    }),
  );
  ref.onDispose(db.close);
  return db;
});
