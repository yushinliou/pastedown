//
//  ImageHandling.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//


enum ImageHandling: String, CaseIterable, Codable {
    case saveToFolder = "saveToFolder"
    case ignore = "ignore"
    case base64 = "base64"
    
    var displayName: String {
        switch self {
        case .saveToFolder: return "Save to File"
        case .ignore: return "Ignore Images"
        case .base64: return "Embed as Base64"
        }
    }
}
