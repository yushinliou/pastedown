//
//  ImageHandling.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//


enum ImageHandling: String, CaseIterable, Codable {
    case ignore = "ignore"
    case saveLocal = "saveLocal"
    case saveCustom = "saveCustom"
    
    var displayName: String {
        switch self {
        case .ignore: return "Ignore images"
        case .saveLocal: return "Save to local"
        case .saveCustom: return "Save to custom folder"
        }
    }
}
