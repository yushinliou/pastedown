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

    static let defaultPrompt = "Generate a concise, descriptive alt text for this image. Focus on the main content, objects, and context that would be useful for someone who cannot see the image. Keep it under 100 characters."

    init(settings: SettingsStore) {
        self.settings = settings
    }
    
    func generateAltText(for image: UIImage) async -> String {
        guard settings.enableAutoAlt else { return "Image" }

        // Check if using fixed alt text (when altTextTemplate is .objects and not using external API)
        if settings.altTextTemplate == .objects && !settings.useExternalAPI {
            return settings.fixedAltText
        }

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
    switch settings.llmProvider {
    case .openai:
        return await generateAltTextWithOpenAI(image)
    case .anthropic:
        return await generateAltTextWithAnthropic(image)
    case .custom:
        return await generateAltTextWithCustomAPI(image)
    }
}

private func generateAltTextWithOpenAI(_ image: UIImage) async -> String {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        print("Failed to convert image to JPEG data")
        return await generateAltTextWithVision(image)
    }

    let base64Image = imageData.base64EncodedString()
    let prompt = settings.customPrompt.isEmpty ?
        ImageAnalyzer.defaultPrompt :
        settings.customPrompt

    let requestBody: [String: Any] = [
        "model": "gpt-4o",
        "messages": [
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": prompt
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
        "max_tokens": 150,
        "temperature": 0.3
    ]

    return await makeAPIRequest(
        url: "https://api.openai.com/v1/chat/completions",
        requestBody: requestBody,
        headers: ["Authorization": "Bearer \(settings.apiKey)"],
        responseParser: parseOpenAIResponse
    )
}

private func generateAltTextWithAnthropic(_ image: UIImage) async -> String {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        print("Failed to convert image to JPEG data")
        return await generateAltTextWithVision(image)
    }

    let base64Image = imageData.base64EncodedString()
    let prompt = settings.customPrompt.isEmpty ?
        ImageAnalyzer.defaultPrompt :
        settings.customPrompt

    let requestBody: [String: Any] = [
        "model": "claude-3-5-sonnet-20240620",
        "max_tokens": 150,
        "messages": [
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": prompt
                    ],
                    [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": base64Image
                        ]
                    ]
                ]
            ]
        ]
    ]

    return await makeAPIRequest(
        url: "https://api.anthropic.com/v1/messages",
        requestBody: requestBody,
        headers: [
            "x-api-key": settings.apiKey,
            "anthropic-version": "2023-06-01"
        ],
        responseParser: parseAnthropicResponse
    )
}

private func generateAltTextWithCustomAPI(_ image: UIImage) async -> String {
    // For custom API, fallback to Vision since we don't have endpoint configuration yet
    print("Custom API not yet implemented, falling back to Vision")
    return await generateAltTextWithVision(image)
}

private func makeAPIRequest(
    url: String,
    requestBody: [String: Any],
    headers: [String: String],
    responseParser: @escaping ([String: Any]) -> String?
) async -> String {
    guard let requestURL = URL(string: url) else {
        print("Invalid API URL: \(url)")
        return await generateAltTextWithVision(UIImage())
    }

    var request = URLRequest(url: requestURL)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 30

    for (key, value) in headers {
        request.addValue(value, forHTTPHeaderField: key)
    }

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("API Response Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                if let errorData = String(data: data, encoding: .utf8) {
                    print("API Error Response: \(errorData)")
                }
                return await generateAltTextWithVision(UIImage())
            }
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("Failed to parse JSON response")
            return await generateAltTextWithVision(UIImage())
        }
        
        if let content = responseParser(json) {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            print("Failed to extract content from API response")
            return await generateAltTextWithVision(UIImage())
        }

    } catch {
        print("API request failed: \(error.localizedDescription)")
        return await generateAltTextWithVision(UIImage())
    }
}

private func parseOpenAIResponse(_ json: [String: Any]) -> String? {
    if let error = json["error"] as? [String: Any],
       let message = error["message"] as? String {
        print("OpenAI API Error: \(message)")
        return nil
    }
    
    if let choices = json["choices"] as? [[String: Any]],
       let message = choices.first?["message"] as? [String: Any],
       let content = message["content"] as? String {
        return content
    }
    
    return nil
}

private func parseAnthropicResponse(_ json: [String: Any]) -> String? {
    if let error = json["error"] as? [String: Any],
       let message = error["message"] as? String {
        print("Anthropic API Error: \(message)")
        return nil
    }
    
    if let content = json["content"] as? [[String: Any]],
       let firstContent = content.first,
       let text = firstContent["text"] as? String {
        return text
    }
    
    return nil
}
}

