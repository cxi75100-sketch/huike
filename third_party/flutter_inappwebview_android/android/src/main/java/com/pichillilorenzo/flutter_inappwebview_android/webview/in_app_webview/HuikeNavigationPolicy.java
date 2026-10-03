package com.pichillilorenzo.flutter_inappwebview_android.webview.in_app_webview;

import java.util.List;
import java.util.Locale;
import java.util.Map;

/** Interprets the Dart policy snapshot; no school-specific rules or URL logging. */
public final class HuikeNavigationPolicy {
  public enum Decision { CONTINUE, CANCEL, ASK_DART }

  private HuikeNavigationPolicy() {}

  public static Decision decide(Map<String, Object> policy, String scheme,
                                String host, boolean mainFrame) {
    if (policy == null) return Decision.ASK_DART;
    Object schemes = policy.get("schemes");
    Object hosts = policy.get("hosts");
    if (!(schemes instanceof List) || !(hosts instanceof List) || scheme == null ||
        !((List<?>) schemes).contains(scheme.toLowerCase(Locale.ROOT))) {
      return Decision.CANCEL;
    }
    if (host == null || host.isEmpty()) return Decision.CANCEL;
    if (!mainFrame || ((List<?>) hosts).contains(host.toLowerCase(Locale.ROOT))) {
      return Decision.CONTINUE;
    }
    return Decision.ASK_DART;
  }
}
