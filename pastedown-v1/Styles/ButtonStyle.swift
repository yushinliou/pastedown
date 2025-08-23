//
//  ButtonStyle.swift
//  pastedown-v1
//
//  Created by 劉羽芯 on 2025/7/6.
//

import SwiftUI

struct PasteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color("primaryColour")) // primaryColour
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("backgroundColour")) // secondaryColour
                    .shadow(color: .black.opacity(configuration.isPressed ? 0.2 : 0.3),
                            radius: configuration.isPressed ? 6 : 10,
                            x: 0,
                            y: configuration.isPressed ? 4 : 6)
            )
            .scaleEffect(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: configuration.isPressed)
    }
}
