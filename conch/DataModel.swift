//
//  DataModel.swift
//  conch
//
//  Created by Karina Kazbekova on 09.03.2025.
//


struct Friend: Identifiable, Decodable {
    let id: Int
    let firstName: String
    let lastName: String
    let online: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case online
    }
}

struct User: Identifiable, Decodable {
    let id: Int
    let firstName: String
    let lastName: String
    let photoUrl: String?  // Фото профиля
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case photoUrl = "photo_200" // URL фото с VK API
    }
}

struct Group: Identifiable, Decodable {
    let id: Int
    let name: String
}

struct Photo: Identifiable, Decodable {
    let id: Int
    let sizes: [PhotoSize]
    
    var url: String? { sizes.last?.url }
}

struct PhotoSize: Decodable {
    let url: String
}
