import SwiftUI
import WebKit

// MARK: - WebView для авторизации
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

// MARK: - Модели данных
struct VKResponse<T: Codable>: Codable {
    let response: T
}

struct Friend: Codable, Identifiable {
    let id: Int
    let first_name: String
    let last_name: String
    let online: Int
    
    var onlineStatus: Bool { online == 1 }
}

struct Group: Codable, Identifiable {
    let id: Int
    let name: String
}

struct Photo: Codable, Identifiable {
    let id: Int
    let sizes: [PhotoSize]
    
    var url: String? { sizes.last?.url }
}

struct PhotoSize: Codable {
    let url: String
}

// MARK: - Функция загрузки данных
func fetchData<T: Codable>(_ urlString: String, completion: @escaping (T?) -> Void) {
    guard let url = URL(string: urlString) else { return }
    URLSession.shared.dataTask(with: url) { data, _, _ in
        if let data = data {
            let decodedData = try? JSONDecoder().decode(VKResponse<T>.self, from: data)
            DispatchQueue.main.async {
                completion(decodedData?.response)
            }
        }
    }.resume()
}

// MARK: - Экран авторизации
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

// MARK: - Основное меню
struct MainTabView: View {
    let accessToken: String
    
    var body: some View {
        TabView {
            FriendsView(accessToken: accessToken)
                .tabItem {
                    Label("Друзья", systemImage: "person.2")
                }
            GroupsView(accessToken: accessToken)
                .tabItem {
                    Label("Группы", systemImage: "person.3")
                }
            PhotosView(accessToken: accessToken)
                .tabItem {
                    Label("Фото", systemImage: "photo")
                }
        }
    }
}


struct FriendsView: View {
    let accessToken: String
    @State private var friends: [Friend] = []
    
    var body: some View {
        List(friends) { friend in
            HStack {
                Text("\(friend.first_name) \(friend.last_name)")
                Spacer()
                Text(friend.onlineStatus ? "🟢 Онлайн" : "⚫️ Офлайн")
            }
        }
        .navigationTitle("Друзья")
        .onAppear { fetchFriends() }
    }
    
    func fetchFriends() {
        let urlString = "https://api.vk.com/method/friends.get?fields=first_name,last_name,online&access_token=\(accessToken)&v=5.131"
        fetchData(urlString) { (response: [Friend]?) in
            friends = response ?? []
        }
    }
}

// MARK: - Экран групп
struct GroupsView: View {
    let accessToken: String
    @State private var groups: [Group] = []
    
    var body: some View {
        List(groups) { group in
            Text(group.name)
        }
        .navigationTitle("Группы")
        .onAppear { fetchGroups() }
    }
    
    func fetchGroups() {
        let urlString = "https://api.vk.com/method/groups.get?extended=1&access_token=\(accessToken)&v=5.131"
        fetchData(urlString) { (response: [Group]?) in
            groups = response ?? []
        }
    }
}

// MARK: - Экран фото
