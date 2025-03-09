//
//  ErrorResponse.swift
//  conch
//
//  Created by Karina Kazbekova on 09.03.2025.
//

import SwiftUI

struct ErrorResponse: Decodable {
    let error: ErrorDetails
}

struct ErrorDetails: Decodable {
    let errorCode: Int
    let errorMsg: String
}
