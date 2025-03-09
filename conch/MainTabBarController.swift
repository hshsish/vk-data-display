
import SwiftUI

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
