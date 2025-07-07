//
//  FrontMatterField.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//

import SwiftUI

// MARK: - Models
struct FrontMatterField: Identifiable, Codable {
    var id = UUID()
    var name: String = ""
    var type: FrontMatterType = .string
    var value: String = ""
}
