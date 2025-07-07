//
//  SettingsStore.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//

import SwiftUI

// MARK: - Settings Store
class SettingsStore: ObservableObject {
    @Published var frontMatterFields: [FrontMatterField] = []
    @Published var imageHandling: ImageHandling = .ignore
    @Published var customImageFolder: String = "images"
    @Published var enableAutoAlt: Bool = true
    @Published var altTextTemplate: AltTextTemplate = .imageOf
    @Published var apiKey: String = ""
    @Published var useExternalAPI: Bool = false
    @Published var outputFilenameFormat: String = "note_{date}_{title}.md"
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "frontMatterFields"),
           let fields = try? JSONDecoder().decode([FrontMatterField].self, from: data) {
            frontMatterFields = fields
        }
        
        if let imageHandlingRaw = UserDefaults.standard.string(forKey: "imageHandling"),
           let handling = ImageHandling(rawValue: imageHandlingRaw) {
            imageHandling = handling
        }
        
        customImageFolder = UserDefaults.standard.string(forKey: "customImageFolder") ?? "images"
        enableAutoAlt = UserDefaults.standard.bool(forKey: "enableAutoAlt")
        
        if let templateRaw = UserDefaults.standard.string(forKey: "altTextTemplate"),
           let template = AltTextTemplate(rawValue: templateRaw) {
            altTextTemplate = template
        }
        
        apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        useExternalAPI = UserDefaults.standard.bool(forKey: "useExternalAPI")
        outputFilenameFormat = UserDefaults.standard.string(forKey: "outputFilenameFormat") ?? "note_{date}_{title}.md"
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(frontMatterFields) {
            UserDefaults.standard.set(data, forKey: "frontMatterFields")
        }
        
        UserDefaults.standard.set(imageHandling.rawValue, forKey: "imageHandling")
        UserDefaults.standard.set(customImageFolder, forKey: "customImageFolder")
        UserDefaults.standard.set(enableAutoAlt, forKey: "enableAutoAlt")
        UserDefaults.standard.set(altTextTemplate.rawValue, forKey: "altTextTemplate")
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        UserDefaults.standard.set(useExternalAPI, forKey: "useExternalAPI")
        UserDefaults.standard.set(outputFilenameFormat, forKey: "outputFilenameFormat")
    }
}
