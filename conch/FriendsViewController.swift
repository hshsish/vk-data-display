
import SwiftUI

struct FriendsView: View {
    let accessToken: String
    @State private var friends: [Friend] = []
    @State private var selectedFriend: Friend?
    
    var body: some View {
        NavigationStack {
            List(friends) { friend in
                Button {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        selectedFriend = friend
                    }
                } label: {
                    HStack {
                        Text("\(friend.firstName) \(friend.lastName)")
                        Spacer()
                        Text(friend.online == 1 ? "🟢 Онлайн" : "⚫️ Офлайн")
                    }
                }
            }
            .navigationTitle("Друзья")
            .onAppear { fetchFriends() }
            .fullScreenCover(item: $selectedFriend) { friend in
                ProfileView(friendId: friend.id, accessToken: accessToken)
                    .transition(.move(edge: .trailing))
            }
        }
    }
}

extension FriendsView {
    func fetchFriends() {
        let urlString = "https://api.vk.com/method/friends.get?fields=first_name,last_name,online&access_token=\(accessToken)&v=5.131"
        NetworkService.shared.fetchData(urlString) { (response: [Friend]?) in
            if let response = response {
                friends = response
            } else {
                print("Ошибка при получении данных друзей")
            }
        }
    }
}
