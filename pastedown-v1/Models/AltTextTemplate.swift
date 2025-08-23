//
//  AltTextTemplate.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//


enum AltTextTemplate: String, CaseIterable, Codable {
    case imageOf = "Image of {objects}"
    case thisShows = "This picture shows {objects}"
    case objects = "{objects}"
    
    var displayName: String {
        return self.rawValue
    }
}
