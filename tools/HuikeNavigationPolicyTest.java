import java.util.*;
import com.pichillilorenzo.flutter_inappwebview_android.webview.in_app_webview.HuikeNavigationPolicy;
import static com.pichillilorenzo.flutter_inappwebview_android.webview.in_app_webview.HuikeNavigationPolicy.Decision.*;

/** No Android SDK dependency: executes the actual shared native interpreter. */
public final class HuikeNavigationPolicyTest {
  private static int count;
  private static void check(Object actual, Object expected) {
    count++;
    if (actual != expected) throw new AssertionError("Case " + count);
  }
  public static void main(String[] args) {
    Map<String, Object> rules = new HashMap<>();
    List<String> hosts = new ArrayList<>(Arrays.asList("jw.example.edu.cn", "10.8.2.3"));
    rules.put("hosts", hosts);
    rules.put("schemes", Arrays.asList("http", "https"));
    check(HuikeNavigationPolicy.decide(rules, "https", "jw.example.edu.cn", true), CONTINUE);
    check(HuikeNavigationPolicy.decide(rules, "http", "10.8.2.3", true), CONTINUE);
    check(HuikeNavigationPolicy.decide(rules, "HTTPS", "JW.EXAMPLE.EDU.CN", true), CONTINUE);
    check(HuikeNavigationPolicy.decide(rules, "https", "cas.example.edu.cn", true), ASK_DART);
    check(HuikeNavigationPolicy.decide(rules, "https", "child.jw.example.edu.cn", true), ASK_DART);
    check(HuikeNavigationPolicy.decide(rules, "https", "cas.example.edu.cn", false), CONTINUE);
    for (String scheme : Arrays.asList("file", "intent", "javascript", "tel")) {
      check(HuikeNavigationPolicy.decide(rules, scheme, "jw.example.edu.cn", false), CANCEL);
    }
    check(HuikeNavigationPolicy.decide(rules, "https", "", true), CANCEL);
    check(HuikeNavigationPolicy.decide(null, "https", "jw.example.edu.cn", true), ASK_DART);
    check(HuikeNavigationPolicy.decide(new HashMap<>(), "https", "jw.example.edu.cn", true), CANCEL);
    hosts.add("cas.example.edu.cn");
    check(HuikeNavigationPolicy.decide(rules, "https", "cas.example.edu.cn", true), CONTINUE);
    System.out.println("PASS " + count + " native navigation policy cases");
  }
}
