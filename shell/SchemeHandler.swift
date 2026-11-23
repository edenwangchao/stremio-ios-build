import Foundation
import WebKit

/// 自定义协议处理器:把打包进 App 的 web 资源以 stremio://localhost/... 的形式提供给 WKWebView。
/// 这样 SPA 页面拥有稳定的源(origin),可以跨域 fetch https 接口(依赖远端返回 CORS 头,
/// 与 Capacitor 的 capacitor://localhost 同一套思路),也避免了 file:// 的各种限制。
final class SchemeHandler: NSObject, WKURLSchemeHandler {

    private let webDirectory: URL

    init(webDirectory: URL) {
        self.webDirectory = webDirectory
        super.init()
    }

    private static let mimeTypes: [String: String] = [
        "html": "text/html",
        "htm": "text/html",
        "js": "application/javascript",
        "mjs": "application/javascript",
        "css": "text/css",
        "json": "application/json",
        "map": "application/json",
        "txt": "text/plain",
        "xml": "application/xml",
        "webmanifest": "application/manifest+json",
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "gif": "image/gif",
        "svg": "image/svg+xml",
        "webp": "image/webp",
        "avif": "image/avif",
        "ico": "image/x-icon",
        "woff": "font/woff",
        "woff2": "font/woff2",
        "ttf": "font/ttf",
        "otf": "font/otf",
        "eot": "application/vnd.ms-fontobject",
        "mp4": "video/mp4",
        "webm": "video/webm",
        "m3u8": "application/vnd.apple.mpegurl",
        "mpd": "application/dash+xml",
        "ts": "video/mp2t",
        "wasm": "application/wasm"
    ]

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              url.host == "localhost" || url.host == "127.0.0.1" else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        var relativePath = url.path
        if relativePath.hasPrefix("/") { relativePath.removeFirst() }
        if relativePath.isEmpty { relativePath = "index.html" }

        let baseDir = webDirectory.standardizedFileURL.path
        let fileURL = webDirectory.appendingPathComponent(relativePath).standardizedFileURL
        guard fileURL.path == baseDir || fileURL.path.hasPrefix(baseDir + "/") else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        var payload: Data?
        if FileManager.default.fileExists(atPath: fileURL.path) {
            payload = try? Data(contentsOf: fileURL)
        }
        if payload == nil, !relativePath.contains(".") {
            // SPA 回退(本项目用 HashRouter,一般用不到,保险起见)
            payload = try? Data(contentsOf: webDirectory.appendingPathComponent("index.html"))
        }
        guard let data = payload else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let ext = fileURL.pathExtension.lowercased()
        let mime = SchemeHandler.mimeTypes[ext] ?? "application/octet-stream"
        let headers = [
            "Content-Type": mime,
            "Content-Length": String(data.count),
            "Cache-Control": "no-cache"
        ]
        let response = HTTPURLResponse(url: url,
                                       statusCode: 200,
                                       httpVersion: "HTTP/1.1",
                                       headerFields: headers)
            ?? URLResponse(url: url, mimeType: mime, expectedContentLength: data.count, textEncodingName: nil)
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // 文件读取是同步完成的,无需取消处理
    }
}
