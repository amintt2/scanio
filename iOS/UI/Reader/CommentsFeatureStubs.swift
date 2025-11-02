import SwiftUI

// MARK: - Placeholder CommentsButtonView
struct CommentsButtonView: View {
    let commentCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble")
                if commentCount > 0 {
                    Text("\(commentCount)")
                        .font(.footnote)
                }
            }
            .padding(8)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder AuthView
struct AuthView: View {
    var onAuthenticated: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Authentication Required")
                .font(.headline)
            Button("Sign In (Stub)") {
                // Note: This is a stub - real authentication is handled by SupabaseManager
                onAuthenticated()
            }
        }
        .padding()
    }
}

// MARK: - Previews (optional)
#if DEBUG
#Preview("Comments Button") {
    CommentsButtonView(commentCount: 3) {}
        .padding()
}

#Preview("AuthView") {
    AuthView(onAuthenticated: {})
}
#endif
