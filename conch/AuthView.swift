
import SwiftUI

struct AuthView: View {
    @State private var isAuthenticated = false
    @State private var accessToken: String?
    
    var body: some View {
        NavigationStack {
            if isAuthenticated, let token = accessToken {
                MainTabView(accessToken: token)
            } else {
                AuthWebView(url: URL(string: "https://oauth.vk.com/authorize?client_id=52954381&display=mobile&redirect_uri=https://oauth.vk.com/blank.html&scope=friends,groups,photos&response_type=token&v=5.131")!) { url in
                    if let token = extractToken(from: url) {
                        accessToken = token
                        isAuthenticated = true
                    }
                }
            }
        }
    }
    
    private func extractToken(from url: String) -> String? {
        if let fragment = URL(string: url)?.fragment {
            let params = fragment.split(separator: "&").reduce(into: [String: String]()) {
                let pair = $1.split(separator: "=")
                if pair.count == 2 { $0[String(pair[0])] = String(pair[1]) }
            }
            return params["access_token"]
        }
        return nil
    }
}

#Preview {
    AuthView()
}
