import AppKit
import SwiftUI
import WebKit

struct PreviewView: NSViewRepresentable {
    var html: String
    var baseURL: URL?
    var visibleLine: Int
    var selectRaw: String
    var selectVisible: String
    var selectToken: Int
    var followEditorScroll: Bool
    var onVisibleLineChange: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "previewScroll")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.underPageBackgroundColor = NSColor(Palette.paper)
        context.coordinator.onVisibleLineChange = onVisibleLineChange
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onVisibleLineChange = onVisibleLineChange
        context.coordinator.visibleLine = visibleLine
        context.coordinator.selectRaw = selectRaw
        context.coordinator.selectVisible = selectVisible
        context.coordinator.selectToken = selectToken

        if html != context.coordinator.loadedHTML {
            context.coordinator.loadedHTML = html
            context.coordinator.needsRestoreAfterLoad = true
            webView.loadHTMLString(html, baseURL: baseURL)
            return
        }

        if followEditorScroll, context.coordinator.lastScrolledLine != visibleLine {
            context.coordinator.applyScroll(on: webView, line: visibleLine)
        }

        if context.coordinator.lastSelectToken != selectToken {
            context.coordinator.applySelection(on: webView)
        }
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "previewScroll")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var loadedHTML: String?
        var visibleLine = 1
        var selectRaw = ""
        var selectVisible = ""
        var selectToken = 0
        var lastScrolledLine = 0
        var lastSelectToken = -1
        var needsRestoreAfterLoad = false
        var onVisibleLineChange: ((Int) -> Void)?

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard needsRestoreAfterLoad else { return }
            needsRestoreAfterLoad = false
            applyScroll(on: webView, line: visibleLine)
            applySelection(on: webView)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "previewScroll" else { return }
            let line: Int
            if let value = message.body as? Int {
                line = value
            } else if let value = message.body as? NSNumber {
                line = value.intValue
            } else {
                return
            }
            lastScrolledLine = line
            Task { @MainActor in
                self.onVisibleLineChange?(line)
            }
        }

        func applyScroll(on webView: WKWebView, line: Int) {
            lastScrolledLine = line
            webView.evaluateJavaScript("scrollToSourceLine(\(line))", completionHandler: nil)
        }

        func applySelection(on webView: WKWebView) {
            lastSelectToken = selectToken
            let raw = Self.jsQuote(selectRaw)
            let visible = Self.jsQuote(selectVisible)
            webView.evaluateJavaScript(
                "selectPlainText(\(raw), \(visible), \(visibleLine))",
                completionHandler: nil
            )
        }

        static func jsQuote(_ string: String) -> String {
            let data = (try? JSONEncoder().encode(string)) ?? Data("\"\"".utf8)
            return String(data: data, encoding: .utf8) ?? "\"\""
        }
    }
}
