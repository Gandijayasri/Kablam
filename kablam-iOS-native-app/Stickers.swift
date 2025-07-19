//
//  Stickers.swift
//  kablam-iOS-native-app
//
//  Created by Vamsi Thiruveedula on 17/07/25.
//

import UIKit

struct Sticker: Codable {
    let id: Int
    let name: String
    let url: String
    let user_id: Int?
    let created_at: String
    let updated_at: String
}

