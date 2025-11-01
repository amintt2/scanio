import SwiftUI

// MARK: - Placeholder SupabaseManager
final class SupabaseManager {
    static let shared = SupabaseManager()
    // Toggle this to simulate authentication state in previews/tests
    var isAuthenticated: Bool = false
}

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
                SupabaseManager.shared.isAuthenticated = true
                onAuthenticated()
            }
        }
        .padding()
    }
}

// MARK: - Placeholder CommentsView
struct CommentsView: View {
    let chapterId: String

    var body: some View {
        VStack(spacing: 12) {
            Text("Comments (Stub)")
                .font(.headline)
            Text("Chapter ID: \(chapterId)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("This is a placeholder comments view.")
                .font(.footnote)
                .foregroundStyle(.secondary)
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

#Preview("CommentsView") {
    CommentsView(chapterId: "example-chapter")
}
#endif
