
import SwiftUI
import WebKit

struct AuthWebView: UIViewRepresentable {
    let url: URL
    let onAuthSuccess: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: AuthWebView
        
        init(_ parent: AuthWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let url = navigationResponse.response.url?.absoluteString, url.contains("access_token") {
                parent.onAuthSuccess(url)
            }
            decisionHandler(.allow)
        }
    }
}
