import 'package:flutter_test/flutter_test.dart';
import 'package:huike_timetable/features/import/services/adapter_bridge.dart';

void main() {
  test('桥包含契约全部八个处理器', () {
    expect(AdapterBridge.handlerNames, hasLength(8));
    for (final name in AdapterBridge.handlerNames) {
      expect(AdapterBridge.bootstrapJs, contains(name));
    }
  });

  test('桥对外保持社区契约名', () {
    expect(AdapterBridge.bootstrapJs, contains('window.shiguangBridge'));
    expect(AdapterBridge.bootstrapJs, contains('window.shiguangBridgePromise'));
    expect(AdapterBridge.bootstrapJs, contains('notifyTaskCompletion'));
    expect(AdapterBridge.bootstrapJs, contains('showSingleSelection'));
    expect(AdapterBridge.bootstrapJs, contains('saveImportedCourses'));
    expect(AdapterBridge.bootstrapJs, contains('savePresetTimeSlots'));
    expect(AdapterBridge.bootstrapJs, contains('saveCourseConfig'));
    expect(AdapterBridge.bootstrapJs, contains('showPrompt'));
    expect(AdapterBridge.bootstrapJs, contains('showAlert'));
  });

  test('桥幂等：重复注入只安装一次', () {
    expect(AdapterBridge.bootstrapJs, contains('__huikeBridgeInstalled'));
    expect(AdapterBridge.bootstrapJs.indexOf('__huikeBridgeInstalled'), greaterThan(0));
  });

  test('契约要求的三类保存都不直接写库，只经处理器', () {
    // 保存调用都转发到 huike_* 处理器，而不是任何存储 API。
    expect(AdapterBridge.bootstrapJs, isNot(contains('localStorage')));
    expect(AdapterBridge.bootstrapJs, isNot(contains('document.')));
  });
}
