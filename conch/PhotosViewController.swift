import SwiftUI
import WebKit

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

#Preview {
    AuthView()
}
