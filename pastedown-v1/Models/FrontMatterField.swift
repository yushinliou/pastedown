//
//  FrontMatterField.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//

import SwiftUI

// MARK: - Models
struct FrontMatterField: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String = ""
    var type: FrontMatterType = .string
    var value: String = ""
    var isCommented: Bool = false
    var indentLevel: Int = 0 // 0-3
}
