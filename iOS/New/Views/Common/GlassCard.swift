//
//  GlassCard.swift
//  Scanio
//
//  Liquid Glass design system - Glass morphism card component
//

import SwiftUI

/// A beautiful glass morphism card with blur effect and subtle borders
struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    var shadowRadius: CGFloat = 10
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Glass effect with blur
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border with gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 5)
    }
}

/// A pressable glass card with scale animation
struct GlassPressableCard<Content: View>: View {
    let content: Content
    let action: () -> Void
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    
    @State private var isPressed = false
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 20,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            GlassCard(padding: padding, cornerRadius: cornerRadius) {
                content
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Button style with scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Glass section header with accent color
struct GlassSectionHeader: View {
    let title: String
    let icon: String?
    var accentColor: Color = .accentColor
    
    init(_ title: String, icon: String? = nil, accentColor: Color = .accentColor) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}

/// Glass divider with gradient
struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

/// Glass button with gradient background
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: GlassButtonStyle = .primary
    var isLoading: Bool = false
    
    enum GlassButtonStyle {
        case primary
        case secondary
        case destructive
        
        var colors: [Color] {
            switch self {
            case .primary:
                return [Color.accentColor, Color.accentColor.opacity(0.8)]
            case .secondary:
                return [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
            case .destructive:
                return [Color.red, Color.red.opacity(0.8)]
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive:
                return .white
            case .secondary:
                return .primary
            }
        }
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: GlassButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.body.weight(.semibold))
                    }
                    
                    Text(title)
                        .font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: style.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Shine effect
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                }
            )
            .foregroundColor(style.foregroundColor)
            .shadow(color: style.colors[0].opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Glass Card")
                    .font(.headline)
                Text("Beautiful glass morphism effect")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        
        GlassButton("Primary Button", icon: "star.fill", style: .primary) {}
        GlassButton("Secondary Button", icon: "gear", style: .secondary) {}
        GlassButton("Destructive Button", icon: "trash", style: .destructive) {}
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

