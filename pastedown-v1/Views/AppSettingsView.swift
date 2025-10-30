//  Meta setting page
//  AppSettingsView.swift
//  pastedown-v1
//
//  Last modify: 2025/09/24 Yu Shin Liou
//

import SwiftUI

struct AppSettingsView: View {
    @Binding var isPresented: Bool
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    @AppStorage("colorScheme") private var colorScheme = "system"

    private let languages = [
        ("en", "English"),
        ("es", "Español"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("zh", "中文"),
        ("ja", "日本語"),
        ("ko", "한국어")
    ]

    private let colorSchemes = [
        ("system", "System", "gear"),
        ("light", "Light", "sun.max"),
        ("dark", "Dark", "moon")
    ]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Appearance")
                            .font(.headline)
                            .fontWeight(.medium)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(colorSchemes, id: \.0) { scheme in
                                AppearanceOptionView(
                                    title: scheme.1,
                                    iconName: scheme.2,
                                    isSelected: colorScheme == scheme.0
                                ) {
                                    colorScheme = scheme.0
                                    applyColorScheme(scheme.0)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Display")
                } footer: {
                    Text("Choose how the app appears on your device")
                }

//                Section {
//                    Picker("Language", selection: $selectedLanguage) {
//                        ForEach(languages, id: \.0) { language in
//                            HStack {
//                                Text(language.1)
//                                Spacer()
//                                if language.0 == selectedLanguage {
//                                    Image(systemName: "checkmark")
//                                        .foregroundColor(.blue)
//                                }
//                            }
//                            .tag(language.0)
//                        }
//                    }
//                    .pickerStyle(NavigationLinkPickerStyle())
//                } header: {
//                    Text("Language")
//                } footer: {
//                    Text("Select your preferred language for the app interface")
//                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("App Version")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text(getAppVersion())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("v\(getAppVersion())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Build Number")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Internal build identifier")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(getBuildNumber())
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("About")
                } footer: {
                    Text("Pastedown v1 - Convert rich text clipboard content to Markdown format")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func applyColorScheme(_ scheme: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        switch scheme {
        case "light":
            window.overrideUserInterfaceStyle = .light
        case "dark":
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }

    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

struct AppearanceOptionView: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AppSettingsView(isPresented: .constant(true))
}
