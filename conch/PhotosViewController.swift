
import SwiftUI

struct PhotosView: View {
    let accessToken: String
    @State var photos: [Photo] = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                ForEach(photos) { photo in
                    if let urlString = photo.url, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
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
}

extension PhotosView {
    func fetchPhotos() {
        let urlString = "https://api.vk.com/method/photos.getAll?access_token=\(accessToken)&v=5.131"
        NetworkService.shared.fetchData(urlString) { (response: [Photo]?) in
            photos = response?.compactMap { $0.url != nil ? $0 : nil } ?? []
        }
    }
}
