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
            // Background
            Color.theme.background.ignoresSafeArea()

            // Content layer
            VStack(spacing: AppSpacing.md) {
                // File Status Indicator (if file was created)
                if let result = processingResult,
                   let fileURL = result.fileURL {
                    InfoCard(icon: result.fileType == .zip ? "archivebox" : "doc.text") {
                        HStack {
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("File created: \(fileURL.lastPathComponent)")
                                    .font(.app.captionMedium)
                                    .foregroundColor(.theme.textPrimary)
                                Text("Size: \(FileManagerUtilities.getFileSize(url: fileURL))")
                                    .font(.app.caption)
                                    .foregroundColor(.theme.textSecondary)
                            }

                            Spacer()

                            Text(result.fileType == .zip ? "ZIP" : "MD")
                                .font(.app.captionSemibold)
                                .padding(.horizontal, AppSpacing.xs)
                                .padding(.vertical, AppSpacing.xxs)
                                .background(Color.theme.infoBackground)
                                .foregroundColor(.theme.info)
                                .cornerRadius(AppRadius.xs)
                        }
                    }
                }
                
                // Card with TextEditor
                VStack(spacing: 0) {
                    TextEditor(text: $convertedMarkdown)
                        .font(.app.monoBody)
                        .foregroundColor(.theme.textPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(AppSpacing.sm)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .fill(Color.theme.surfaceCard.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(Color.theme.surfaceBorder, lineWidth: 1)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)
            .ignoresSafeArea(.keyboard)

            // Floating copy button (bottom right)
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
                            .font(.app.title)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.theme.primary)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(.trailing, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
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
