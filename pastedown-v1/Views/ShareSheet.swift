//
//  ShareSheet.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//

import SwiftUI

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let suggestedFilename: String?
    
    init(items: [Any], suggestedFilename: String? = nil) {
        self.items = items
        self.suggestedFilename = suggestedFilename
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Set suggested filename if provided
        if let filename = suggestedFilename, let firstItem = items.first as? String {
            controller.setValue(filename, forKey: "subject")
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
