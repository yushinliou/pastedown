//
//  ImageAnalyzer.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/6/30.
//
import SwiftUI
import Vision
import Foundation

// MARK: - Image Analyzer
class ImageAnalyzer: ObservableObject {
    private let settings: SettingsStore
    
    init(settings: SettingsStore) {
        self.settings = settings
    }
    
    func generateAltText(for image: UIImage) async -> String {
        guard settings.enableAutoAlt else { return "Image" }
        
        if settings.useExternalAPI && !settings.apiKey.isEmpty {
            // Placeholder for external API call
            return await generateAltTextWithAPI(image)
        } else {
            return await generateAltTextWithVision(image)
        }
    }
    
    private func generateAltTextWithVision(_ image: UIImage) async -> String {
        guard let ciImage = CIImage(image: image) else {
            return "Image"
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("Vision error: \(error)")
                    continuation.resume(returning: "Image")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "Image")
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                let template = self.settings.altTextTemplate.rawValue
                let result = template.replacingOccurrences(of: "{objects}", with: recognizedText.isEmpty ? "content" : recognizedText)
                continuation.resume(returning: result)
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            try? handler.perform([request])
        }
    }
    
private func generateAltTextWithAPI(_ image: UIImage) async -> String {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        return "Invalid image"
    }

    let base64Image = imageData.base64EncodedString()

    let requestBody: [String: Any] = [
        "model": "gpt-4-vision-preview",
        "messages": [
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": "請幫我生成這張圖片的 alt text（簡潔描述這張圖）。"
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)"
                        ]
                    ]
                ]
            ]
        ],
        "max_tokens": 100
    ]

    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
        return "Invalid API URL"
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        let (data, _) = try await URLSession.shared.data(for: request)

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        } else {
            return "Failed to parse API response"
        }

    } catch {
        return "Error: \(error.localizedDescription)"
    }
}
}

