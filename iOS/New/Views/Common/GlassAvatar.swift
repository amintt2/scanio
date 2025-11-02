//
//  GlassAvatar.swift
//  Scanio
//
//  Liquid Glass design system - Avatar component with glass effect
//

import SwiftUI

/// Beautiful avatar with glass border and gradient ring
struct GlassAvatar: View {
    let imageURL: URL?
    let initials: String
    var size: CGFloat = 60
    var ringColors: [Color] = [.accentColor, .accentColor.opacity(0.6)]
    var showRing: Bool = true
    
    init(
        imageURL: URL? = nil,
        initials: String,
        size: CGFloat = 60,
        ringColors: [Color] = [.accentColor, .accentColor.opacity(0.6)],
        showRing: Bool = true
    ) {
        self.imageURL = imageURL
        self.initials = initials
        self.size = size
        self.ringColors = ringColors
        self.showRing = showRing
    }
    
    var body: some View {
        ZStack {
            // Gradient ring
            if showRing {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: ringColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: size + 6, height: size + 6)
                    .shadow(color: ringColors[0].opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // Avatar content
            Group {
                if let imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure, .empty:
                            fallbackAvatar
                        @unknown default:
                            fallbackAvatar
                        }
                    }
                } else {
                    fallbackAvatar
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(
                        Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
    }
    
    private var fallbackAvatar: some View {
        ZStack {
            // Gradient background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.6),
                            Color.accentColor.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Initials
            Text(initials.prefix(2).uppercased())
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

/// Animated avatar with pulse effect
struct AnimatedGlassAvatar: View {
    let imageURL: URL?
    let initials: String
    var size: CGFloat = 60
    var ringColors: [Color] = [.accentColor, .accentColor.opacity(0.6)]
    
    @State private var isPulsing = false
    
    var body: some View {
        GlassAvatar(
            imageURL: imageURL,
            initials: initials,
            size: size,
            ringColors: ringColors,
            showRing: true
        )
        .scaleEffect(isPulsing ? 1.05 : 1.0)
        .animation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear {
            isPulsing = true
        }
    }
}

/// Small avatar for comments and lists
struct SmallGlassAvatar: View {
    let imageURL: URL?
    let initials: String
    var size: CGFloat = 40
    
    var body: some View {
        GlassAvatar(
            imageURL: imageURL,
            initials: initials,
            size: size,
            showRing: false
        )
    }
}

#Preview {
    VStack(spacing: 30) {
        GlassAvatar(
            imageURL: nil,
            initials: "JD",
            size: 80,
            ringColors: [.blue, .purple]
        )
        
        AnimatedGlassAvatar(
            imageURL: nil,
            initials: "AB",
            size: 60,
            ringColors: [.orange, .red]
        )
        
        HStack(spacing: 16) {
            SmallGlassAvatar(imageURL: nil, initials: "A")
            SmallGlassAvatar(imageURL: nil, initials: "B")
            SmallGlassAvatar(imageURL: nil, initials: "C")
        }
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

