import UIKit
import WebKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private static let scheme = "stremio"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .black

        let configuration = WKWebViewConfiguration()
        if let webDirectory = Bundle.main.resourceURL?.appendingPathComponent("web") {
            configuration.setURLSchemeHandler(SchemeHandler(webDirectory: webDirectory),
                                              forURLScheme: AppDelegate.scheme)
        }
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: window.bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self

        let root = UIViewController()
        root.view.backgroundColor = .black
        root.view.addSubview(webView)

        window.rootViewController = root
        self.window = window
        window.makeKeyAndVisible()

        loadApp(into: webView)
        return true
    }

    /// 可选配置:在打包时把一个 stremio-service 地址写进 web/server-url.txt(一行),
    /// 启动时会通过 ?streamingServerUrl= 参数自动添加并选中该服务器。
    private func loadApp(into webView: WKWebView) {
        var urlString = "stremio://localhost/index.html"
        if let fileURL = Bundle.main.resourceURL?.appendingPathComponent("web/server-url.txt"),
           let raw = try? String(contentsOf: fileURL, encoding: .utf8) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty,
               let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                urlString += "?streamingServerUrl=\(encoded)"
            }
        }
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
    }
}

extension AppDelegate: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        // 应用自身的资源
        if url.scheme == AppDelegate.scheme {
            decisionHandler(.allow)
            return
        }

        // 外部播放器等自定义 scheme(vlc://、outplayer:// 等):交给系统打开
        if let scheme = url.scheme,
           scheme != "http" && scheme != "https" && scheme != "about" {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        // 用户点击的站外 http(s) 链接交给 Safari,避免在 WebView 里迷路
        if navigationAction.navigationType == .linkActivated,
           let host = url.host,
           host != "localhost" && host != "127.0.0.1" {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}
