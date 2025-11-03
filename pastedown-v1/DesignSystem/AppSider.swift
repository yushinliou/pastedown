//
//  IndentControlComponents.swift
//  pastedown-v1
//
//  Indent level control components with previews
//

import SwiftUI

// MARK: - Style 1: Horizontal Bar Slider

struct IndentLevelSlider: View {
    @Binding var level: Int
    let maxLevel: Int = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 14))
                    .foregroundColor(.theme.textSecondary)
                
                ForEach(0...maxLevel, id: \.self) { index in
                    Rectangle()
                        .fill(index <= level ? Color.theme.primary : Color.gray.opacity(0.3))
                        .frame(width: 30, height: index <= level ? 24 : 20)
                        .cornerRadius(4)
                        .animation(.spring(response: 0.3), value: level)
                }
                
                Text("\(level)")
                    .font(.app.calloutSemibold)
                    .foregroundColor(.theme.textPrimary)
                    .frame(minWidth: 20)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let barWidth: CGFloat = 38
                        let newLevel = Int(value.location.x / barWidth)
                        level = min(max(0, newLevel), maxLevel)
                    }
            )
            
            Text("Drag to adjust indent level (0-\(maxLevel))")
                .font(.app.caption)
                .foregroundColor(.theme.textSecondary)
        }
    }
}

// MARK: - Style 2: Vertical Volume Style

struct VerticalIndentControl: View {
    @Binding var level: Int
    let maxLevel: Int = 3
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0...maxLevel, id: \.self) { index in
                    VStack(spacing: 2) {
                        ForEach(0..<(index + 1), id: \.self) { barIndex in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index <= level ? Color.theme.primary : Color.gray.opacity(0.2))
                                .frame(width: 20, height: 8)
                        }
                    }
                    .frame(height: 50, alignment: .bottom)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            level = index
                        }
                    }
                }
            }
            .padding(AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(Color.gray.opacity(0.1))
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Level \(level)")
                    .font(.app.calloutSemibold)
                    .foregroundColor(.theme.textPrimary)
                
                Text(levelDescription)
                    .font(.app.caption)
                    .foregroundColor(.theme.textSecondary)
            }
        }
    }
    
    private var levelDescription: String {
        switch level {
        case 0: return "No indent"
        case 1: return "1 level"
        case 2: return "2 levels"
        case 3: return "3 levels"
        default: return ""
        }
    }
}

// MARK: - Style 3: iOS Volume Style

struct VolumeStyleIndentControl: View {
    @Binding var level: Int
    let maxLevel: Int = 3
    @State private var isDragging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: 3) {
                ForEach(0...maxLevel, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= level ? Color.theme.primary : Color.gray.opacity(0.25))
                        .frame(width: 40, height: barHeight(for: index))
                        .animation(.spring(response: 0.25), value: level)
                }
            }
            .frame(height: 50, alignment: .bottom)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(Color.gray.opacity(0.08))
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let barWidth: CGFloat = 43
                        let newLevel = Int(value.location.x / barWidth)
                        level = min(max(0, newLevel), maxLevel)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            
            HStack {
                Image(systemName: "arrow.right")
                    .foregroundColor(.theme.textSecondary)
                Text("Indent Level: \(level)")
                    .font(.app.callout)
                    .foregroundColor(.theme.textPrimary)
            }
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [20, 28, 36, 44]
        return heights[index]
    }
}

// MARK: - Style 4: Segmented Control

struct SegmentedIndentControl: View {
    @Binding var level: Int
    let maxLevel: Int = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: 0) {
                ForEach(0...maxLevel, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            level = index
                        }
                    } label: {
                        VStack(spacing: 4) {
                            HStack(spacing: 2) {
                                ForEach(0...index, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(level == index ? Color.white : Color.theme.primary)
                                        .frame(width: 3, height: 16)
                                }
                            }
                            
                            Text("\(index)")
                                .font(.app.caption)
                                .foregroundColor(level == index ? .white : .theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .fill(level == index ? Color.theme.primary : Color.clear)
                        )
                    }
                    
                    if index < maxLevel {
                        Divider()
                            .frame(height: 30)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            Text("Tap to select indent level")
                .font(.app.caption)
                .foregroundColor(.theme.textSecondary)
        }
    }
}

// MARK: - Style 5: Arrow Indicator

struct ArrowIndentControl: View {
    @Binding var level: Int
    let maxLevel: Int = 3
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0...maxLevel, id: \.self) { index in
                VStack(spacing: 2) {
                    HStack(spacing: 1) {
                        ForEach(0...index, id: \.self) { _ in
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(index <= level ? .theme.primary : .gray.opacity(0.3))
                        }
                    }
                    
                    Text("\(index)")
                        .font(.app.caption)
                        .foregroundColor(index <= level ? .theme.primary : .theme.textSecondary)
                    
                    Rectangle()
                        .fill(index <= level ? Color.theme.primary : Color.gray.opacity(0.2))
                        .frame(width: 30, height: 3)
                        .cornerRadius(1.5)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        level = index
                    }
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color.gray.opacity(0.05))
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let segmentWidth: CGFloat = 50
                    let newLevel = Int(value.location.x / segmentWidth)
                    level = min(max(0, newLevel), maxLevel)
                }
        )
    }
}

// MARK: - Preview Showcase

struct IndentControlShowcase: View {
    @State private var level1: Int = 1
    @State private var level2: Int = 2
    @State private var level3: Int = 0
    @State private var level4: Int = 3
    @State private var level5: Int = 1
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                
                VStack(spacing: AppSpacing.xs) {
                    Text("Indent Level Controls")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.theme.textPrimary)
                    
                    Text("Choose your favorite style")
                        .font(.app.body)
                        .foregroundColor(.theme.textSecondary)
                }
                .padding(.top, AppSpacing.lg)
                
                Divider()
                
                styleSection(
                    title: "Style 1: Horizontal Bar Slider",
                    content: IndentLevelSlider(level: $level1)
                )
                
                styleSection(
                    title: "Style 2: Vertical Volume Style",
                    content: VerticalIndentControl(level: $level2)
                )
                
                styleSection(
                    title: "Style 3: iOS Volume Style (Recommended)",
                    content: VolumeStyleIndentControl(level: $level3)
                )
                
                styleSection(
                    title: "Style 4: Segmented Control",
                    content: SegmentedIndentControl(level: $level4)
                )
                
                styleSection(
                    title: "Style 5: Arrow Indicator",
                    content: ArrowIndentControl(level: $level5)
                )
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Current Values")
                        .font(.app.titleMedium)
                        .foregroundColor(.theme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        valueRow(title: "Style 1", value: level1)
                        valueRow(title: "Style 2", value: level2)
                        valueRow(title: "Style 3", value: level3)
                        valueRow(title: "Style 4", value: level4)
                        valueRow(title: "Style 5", value: level5)
                    }
                    .padding(AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(Color.theme.background)
    }
    
    private func styleSection<Content: View>(title: String, content: Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.app.titleMedium)
                .foregroundColor(.theme.textPrimary)
            
            content
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(Color.theme.surfaceCard)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                )
        }
        .padding(.horizontal)
    }
    
    private func valueRow(title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .font(.app.callout)
                .foregroundColor(.theme.textSecondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(0..<value, id: \.self) { _ in
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.theme.primary)
                }
            }
            
            Text("Level \(value)")
                .font(.app.calloutSemibold)
                .foregroundColor(.theme.textPrimary)
        }
    }
}

// MARK: - Previews

#Preview("All Styles") {
    IndentControlShowcase()
}

#Preview("All Styles - Dark") {
    IndentControlShowcase()
        .preferredColorScheme(.dark)
}

#Preview("Style 1") {
    VStack {
        IndentLevelSlider(level: .constant(2))
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.theme.background)
}

#Preview("Style 2") {
    VStack {
        VerticalIndentControl(level: .constant(1))
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.theme.background)
}

#Preview("Style 3") {
    VStack {
        VolumeStyleIndentControl(level: .constant(3))
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.theme.background)
}

#Preview("Style 4") {
    VStack {
        SegmentedIndentControl(level: .constant(0))
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.theme.background)
}

#Preview("Style 5") {
    VStack {
        ArrowIndentControl(level: .constant(2))
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.theme.background)
}