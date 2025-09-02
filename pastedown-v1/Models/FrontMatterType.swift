//
//  FrontMatterType.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//

import SwiftUI

enum FrontMatterType: String, CaseIterable, Codable {
    case string = "string"
    case number = "number"
    case boolean = "boolean"
    case date = "date"
    case datetime = "datetime"
    case list = "list"
    case tag = "tag"
    case multiline = "multiline"
    case current_date = "current_date"
    case current_datetime = "current_datetime"
    
    var displayName: String {
        switch self {
        case .string: return "String"
        case .number: return "Number"
        case .boolean: return "Boolean"
        case .date: return "Date"
        case .datetime: return "DateTime"
        case .list: return "List"
        case .tag: return "Tag"
        case .multiline: return "Multiline"
        case .current_date: return "Current Date"
        case .current_datetime: return "Current DateTime"
        }
    }
    
    var needsUserInput: Bool {
        switch self {
        case .current_date, .current_datetime:
            return false
        default:
            return true
        }
    }
}
