
import SwiftUI

struct ProfileView: View {
    let friendId: Int
    let accessToken: String
    @State private var user: User?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            if let user = user {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.title)
                    .padding()
                
                if let photoUrl = user.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .padding()
                }
            } else {
                ProgressView()
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    dismiss()
                }
            }) {
                Text("Назад")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("Профиль")
        .onAppear { fetchUserProfile() }
    }
}

extension ProfileView {
    func fetchUserProfile() {
        let urlString = "https://api.vk.com/method/users.get?user_ids=\(friendId)&fields=photo_200&access_token=\(accessToken)&v=5.131"
        
        NetworkService.shared.fetchData(urlString) { (response: [User]?) in
            if let user = response?.first {
                self.user = user
            } else {
                print("Ошибка при получении данных пользователя")
            }
        }
    }
}
