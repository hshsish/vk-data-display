import SwiftUI
import WebKit

// MARK: - WebView для авторизации

struct AuthWebView: UIViewRepresentable {
    let url: URL
    let onAuthSuccess: (String) -> Void
    let onAuthFailure: (Error) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        print("huhuhuhuuh")
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

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, url.absoluteString.starts(with: "https://oauth.vk.com/blank.html") {
                if let code = extractCode(from: url) {
                    exchangeCodeForToken(code: code)
                } else {
                    parent.onAuthFailure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить код авторизации"]))
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        private func extractCode(from url: URL) -> String? {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else { return nil }
            return queryItems.first(where: { $0.name == "code" })?.value
        }

        private func exchangeCodeForToken(code: String) {
            var request = URLRequest(url: URL(string: "https://oauth.vk.com/access_token")!)
      
            request.httpMethod = "POST"
            let params = [
                "client_id": "52954381",
                "client_secret": "3dkCoXcgcN22EFWl36db",
                "redirect_uri": "https://oauth.vk.com/blank.html",
                "code": code
            ]
            request.httpBody = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    self.parent.onAuthFailure(error)
                    return
                }
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let token = json["access_token"] as? String else {
                    self.parent.onAuthFailure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить токен доступа"]))
                    return
                }
                self.parent.onAuthSuccess(token)
            }
            task.resume()
        }
    }
}



//struct AuthWebView: UIViewRepresentable {
//    let url: URL // URL для веб-страницы авторизации
//    let onAuthSuccess: (String) -> Void // Замыкание, которое будет вызвано при успешной авторизации, передавая токен
//    
//    // Метод для создания WKWebView
//    func makeUIView(context: Context) -> WKWebView {
//        let config = WKWebViewConfiguration() // Создаем конфигурацию для WKWebView
//        let webView = WKWebView(frame: .zero, configuration: config) // Создаем WebView с заданной конфигурацией
//        webView.navigationDelegate = context.coordinator // Устанавливаем делегат для обработки навигации
//        webView.load(URLRequest(url: url)) // Загружаем URL в WebView
//        return webView
//    }
//    
//    // Метод для обновления WebView
//    func updateUIView(_ uiView: WKWebView, context: Context) {}
//    
//    // Метод для создания координатора, который будет отслеживать навигацию в WebView
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    // Координатор для обработки событий навигации в WebView
//    class Coordinator: NSObject, WKNavigationDelegate {
//        let parent: AuthWebView
//        
//        init(_ parent: AuthWebView) {
//            self.parent = parent
//        }
//        
//        // Обрабатываем решение о разрешении навигации
//        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
//            if let url = navigationResponse.response.url?.absoluteString, url.contains("access_token") {
//                parent.onAuthSuccess(url) // Если в URL есть токен, вызываем onAuthSuccess
//            }
//            decisionHandler(.allow) // Разрешаем навигацию
//        }
//        
//        // Обработка ошибок при навигации
//        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//            print("WebView error: \(error.localizedDescription)") // Печатаем ошибку в консоль
//        }
//        
//        // Когда страница завершила загрузку, выводим URL
//        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//            print("WebView did finish loading: \(webView.url?.absoluteString ?? "")")
//        }
//    }
//}


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

struct AuthView: View {
    @State private var isAuthenticated = false
    @State private var accessToken: String?
    @State private var authError: String?

    var body: some View {
        NavigationStack {
            if isAuthenticated, let token = accessToken {
                MainTabView(accessToken: token)
            } else {
                AuthWebView(url: URL(string: "https://oauth.vk.com/authorize?client_id=52954381&display=page&redirect_uri=https://oauth.vk.com/blank.html&scope=friends,groups,photos&response_type=code&v=5.131")!) { token in
                    // Когда токен успешно получен
                    self.accessToken = token
                    self.isAuthenticated = true
                } onAuthFailure: { error in
                    // В случае ошибки авторизации
                    self.authError = error.localizedDescription
                    print("Ошибка авторизации: \(self.authError ?? "Неизвестная ошибка")")
                }
            }
        }
        .onChange(of: accessToken) { oldValue, newValue in
            if let token = newValue {
                print("Получен токен: \(token)")
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

// MARK: - Экран друзей
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
struct PhotosView: View {
    let accessToken: String
    @State private var photos: [Photo] = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                ForEach(photos) { photo in
                    if let url = photo.url {
                        AsyncImage(url: URL(string: url)) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height: 100)
                    }
                }
            }
        }
        .navigationTitle("Фото")
        .onAppear { fetchPhotos() }
    }
    
    func fetchPhotos() {
        let urlString = "https://api.vk.com/method/photos.getAll?access_token=\(accessToken)&v=5.131"
        fetchData(urlString) { (response: [Photo]?) in
            photos = response ?? []
        }
    }
}

// MARK: - Preview
#Preview {
    AuthView()
}
//import SwiftUI
//import WebKit
//
//// MARK: - WebView для авторизации
//struct AuthWebView: UIViewRepresentable {
//    let url: URL
//    let onAuthSuccess: (String) -> Void
//    let onAuthFailure: (Error) -> Void
//
//    func makeUIView(context: Context) -> WKWebView {
//        let webViewConfig = WKWebViewConfiguration()
//        webViewConfig.allowsInlineMediaPlayback = true // Разрешить воспроизведение медиа в inline режиме
//        let webView = WKWebView(frame: .zero, configuration: webViewConfig)
//        webView.navigationDelegate = context.coordinator
//        webView.load(URLRequest(url: url))
//        return webView
//    }
//
//
//    func updateUIView(_ uiView: WKWebView, context: Context) {}
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, WKNavigationDelegate {
//        let parent: AuthWebView
//
//        init(_ parent: AuthWebView) {
//            self.parent = parent
//        }
//
//        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//            if let url = navigationAction.request.url, url.absoluteString.starts(with: "https://oauth.vk.com/blank.html") {
//                if let code = extractCode(from: url) {
//                    exchangeCodeForToken(code: code)
//                } else {
//                    parent.onAuthFailure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить код авторизации"]))
//                }
//                decisionHandler(.cancel)
//                return
//            }
//            decisionHandler(.allow)
//        }
//
//        private func extractCode(from url: URL) -> String? {
//            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//                  let queryItems = components.queryItems else { return nil }
//            return queryItems.first(where: { $0.name == "code" })?.value
//        }
//
//        private func exchangeCodeForToken(code: String) {
//            var request = URLRequest(url: URL(string: "https://oauth.vk.com/access_token")!)
//      
//            request.httpMethod = "POST"
//            let params = [
//                "client_id": "52954381",
//                "client_secret": "3dkCoXcgcN22EFWl36db",
//                "redirect_uri": "https://oauth.vk.com/blank.html",
//                "code": code
//            ]
//            request.httpBody = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
//
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    self.parent.onAuthFailure(error)
//                    return
//                }
//                guard let data = data,
//                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                      let token = json["access_token"] as? String else {
//                    self.parent.onAuthFailure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить токен доступа"]))
//                    return
//                }
//                self.parent.onAuthSuccess(token)
//            }
//            task.resume()
//        }
//    }
//}
//
//// MARK: - Экран авторизации
//// MARK: - Экран авторизации
//struct AuthView: View {
//    @State private var accessToken: String?
//    @State private var authError: String?
//
//    var body: some View {
//        NavigationStack {
//            if let token = accessToken {
//                Text("Авторизация прошла успешно. Токен: \(token)")
//            } else {
//                AuthWebView(url: URL(string:
//                                      "https://oauth.vk.com/authorize?client_id=52954381&display=mobile&redirect_uri=https://your-redirect-uri.com&scope=friends,groups,photos&response_type=token&v=5.131")!) { token in
//                    self.accessToken = token
//                } onAuthFailure: { error in
//                    self.authError = error.localizedDescription
//                    print("Ошибка авторизации: \(self.authError ?? "Неизвестная ошибка")")
//                }
//            }
//        }
//    }
//}
//
//
//// MARK: - Preview
//#Preview {
//    AuthView()
//}
