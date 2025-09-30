import SwiftUI

struct ResultView: View {
    @Binding var convertedMarkdown: String
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    @Binding var showingAdvancedSettings: Bool
    @ObservedObject var settings: SettingsStore
    var processingResult: ImageUtilities.ProcessingResult?

    var body: some View {
        ZStack {
            // 背景（確保整頁）
            Color(.systemBackground).ignoresSafeArea()

            // 內容層：讓卡片吃滿
            VStack(spacing: 16) {
                // File Status Indicator (if file was created)
                if let result = processingResult,
                   let fileURL = result.fileURL {
                    HStack {
                        Image(systemName: result.fileType == .zip ? "archivebox" : "doc.text")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("File created: \(fileURL.lastPathComponent)")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Size: \(FileManagerUtilities.getFileSize(url: fileURL))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(result.fileType == .zip ? "ZIP" : "MD")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
                
                // 卡片：包住 TextEditor，背景/圓角在卡片上，別直接加在 TextEditor 身上
                VStack(spacing: 0) {
                    TextEditor(text: $convertedMarkdown)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.quaternary, lineWidth: 1)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .ignoresSafeArea(.keyboard) // 鍵盤彈出時不要亂擠版

            // 懸浮：右下角 Copy
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        UIPasteboard.general.string = convertedMarkdown
                        alertMessage = "Markdown copied to clipboard!"
                        showingAlert = true
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color("primaryColour"))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 30)
        }
    }
}

struct ResultView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var convertedMarkdown = """
        # Example Markdown
        This is a preview of converted text.

        - Item 1
        - Item 2
        """
        @State private var showingAlert = false
        @State private var alertMessage = ""
        @State private var showingAdvancedSettings = false
        @StateObject private var settings = SettingsStore()

        var body: some View {
            ResultView(
                convertedMarkdown: $convertedMarkdown,
                showingAlert: $showingAlert,
                alertMessage: $alertMessage,
                showingAdvancedSettings: $showingAdvancedSettings,
                settings: settings,
                processingResult: mockProcessingResult
            )
        }

        /// 模擬一個假的檔案結果（可以看到上面的 file status bar）
        private var mockProcessingResult: ImageUtilities.ProcessingResult {
            let dummyURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("example.md")
            return ImageUtilities.ProcessingResult(
                markdown: """
                # Example Markdown from ProcessingResult
                This is the markdown that would normally come from processing.
                """,
                fileURL: dummyURL,
                fileType: .markdown,

            )
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .previewDisplayName("Result View (Preview)")
    }
}
