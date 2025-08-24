//
//  ImageHandling.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//


enum ImageHandling: String, CaseIterable, Codable {
    case ignore = "ignore"
    case base64 = "base64"
    case saveToFolder = "saveToFolder"
    
    var displayName: String {
        switch self {
        case .ignore: return "Ignore images"
        case .base64: return "Use base64 to represent image"
        case .saveToFolder: return "Save to folder"
        }
    }
}
