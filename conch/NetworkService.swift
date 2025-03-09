
import SwiftUI

class NetworkService {
    static let shared = NetworkService()
    private init() {}
    
    func fetchData<T: Decodable>(_ urlString: String, completion: @escaping ([T]?) -> Void) {
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                if let decodedData = try? JSONDecoder().decode(ResponseWrapper<ResponseContainer<[T]>>.self, from: data) {
                    DispatchQueue.main.async { completion(decodedData.response.items) }
                } else if let decodedArray = try? JSONDecoder().decode(ResponseWrapper<[T]>.self, from: data) {
                    DispatchQueue.main.async { completion(decodedArray.response) }
                } else {
                    throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Не удалось разобрать JSON"))
                }
            } catch {
                print("Decoding error: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
}

struct ResponseWrapper<T: Decodable>: Decodable {
    let response: T
}
struct ResponseContainer<T: Decodable>: Decodable {
    let items: T
}
struct ProfileResponse<T: Decodable>: Decodable {
    let response: [T]
}
