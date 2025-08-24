import SwiftUI

struct ResultView: View {
    @Binding var convertedMarkdown: String
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    @Binding var showingAdvancedSettings: Bool
    @ObservedObject var settings: SettingsStore

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Editor - takes full space
                VStack(alignment: .leading, spacing: 8) {

                    // Done (close) button
                    Button(action: {
                        convertedMarkdown = ""
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)      .padding(.horizontal)
                            .padding(.top)
                    }
                    
//                    Text("Markdown Output")
//                        .font(.headline)
//                        .fontWeight(.semibold)
//                        .padding(.horizontal)
//                        .padding(.top)
                    
                    TextEditor(text: $convertedMarkdown)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .cornerRadius(15)
                        .padding(.horizontal)
                      .background(Color.gray.opacity(0.05))
                }
            }
            
            // Floating action buttons in bottom right
            VStack(spacing: 12) {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Copy button
                        Button(action: {
                            UIPasteboard.general.string = convertedMarkdown
                            alertMessage = "Markdown copied to clipboard!"
                            showingAlert = true
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color("primaryColour"))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        

                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 30)
            }
        }
   }
}


#Preview {
    // 先準備一些假的 Binding 和設定物件來讓 Preview 可以跑
    ResultView(
        convertedMarkdown: .constant("# Hello World\nThis is a preview.# "),
        showingAlert: .constant(false),
        alertMessage: .constant(""),
        showingAdvancedSettings: .constant(false),
        settings: SettingsStore()
    )
}
