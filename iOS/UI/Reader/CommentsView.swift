//
//  CommentsView.swift
//  Scanio
//
//  SwiftUI view for displaying chapter comments with Liquid Glass design
//

import SwiftUI
import AidokuRunner

struct CommentsView: View {
    let manga: AidokuRunner.Manga
    let chapter: AidokuRunner.Chapter

    @Environment(\.dismiss) var dismiss

    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var newCommentText = ""
    @State private var errorMessage: String?
    @State private var replyingTo: Comment?
    @State private var canonicalMangaId: String?

    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color(uiColor: .systemBackground),
                    Color.accentColor.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Modern header with glass effect
                headerView

                // Comments content
                commentsContent

                // Reply indicator
                if let replyingTo {
                    replyIndicator(for: replyingTo)
                }

                // Modern input field
                inputField
            }
        }
        .onAppear {
            loadComments()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Commentaires")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(comments.count) commentaire\(comments.count > 1 ? "s" : "")")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)

                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                Color(uiColor: .systemBackground)
                    .opacity(0.8)
                    .background(.ultraThinMaterial)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
    }

    // MARK: - Comments Content

    private var commentsContent: some View {
        Group {
            if isLoading && comments.isEmpty {
                loadingView
            } else if comments.isEmpty {
                emptyStateView
            } else {
                commentsList
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Chargement...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.2),
                                Color.accentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Aucun commentaire")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)

                Text("Soyez le premier à commenter ce chapitre")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var commentsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(comments) { comment in
                    ModernCommentRow(
                        comment: comment,
                        onReply: { replyingTo = comment },
                        onDelete: { deleteComment(comment) }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Reply Indicator

    private func replyIndicator(for comment: Comment) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrowshape.turn.up.left.fill")
                .font(.caption)
                .foregroundStyle(.accentColor)

            Text("Répondre à ")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            +
            Text(comment.userName ?? "Anonyme")
                .font(.caption.weight(.semibold))
                .foregroundColor(.accentColor)

            Spacer()

            Button(action: { replyingTo = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            GlassCard(padding: 0, cornerRadius: 0) {
                Color.clear
            }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Input Field

    private var inputField: some View {
        VStack(spacing: 0) {
            // Error message
            if let errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(errorMessage)
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 12) {
                // Text input
                HStack(spacing: 8) {
                    TextField("Ajouter un commentaire...", text: $newCommentText, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: 20)
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

                // Send button
                Button(action: postComment) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: newCommentText.isEmpty ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)] : [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "arrow.up")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: newCommentText.isEmpty ? .clear : Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(newCommentText.isEmpty || isLoading)
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    .ultraThinMaterial

                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
        }
    }

    private func loadComments() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Get or create canonical manga
                let canonicalId = try await SupabaseManager.shared.getOrCreateCanonicalManga(
                    title: manga.title,
                    sourceId: manga.sourceKey,
                    mangaId: manga.key
                )
                canonicalMangaId = canonicalId

                // Fetch comments using canonical manga ID and chapter number
                let chapterNumber = chapter.chapterNumber.map { String(format: "%.1f", $0) } ?? "0"
                comments = try await SupabaseManager.shared.fetchComments(
                    canonicalMangaId: canonicalId,
                    chapterNumber: chapterNumber
                )
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func postComment() {
        guard !newCommentText.isEmpty else { return }
        guard let canonicalId = canonicalMangaId else {
            errorMessage = "Impossible de créer un commentaire pour le moment"
            return
        }

        let content = newCommentText
        newCommentText = ""
        errorMessage = nil

        Task {
            do {
                let chapterNumber = chapter.chapterNumber.map { String(format: "%.1f", $0) } ?? "0"
                let newComment = try await SupabaseManager.shared.createComment(
                    canonicalMangaId: canonicalId,
                    chapterNumber: chapterNumber,
                    content: content,
                    parentCommentId: replyingTo?.id
                )
                comments.insert(newComment, at: 0)
                replyingTo = nil
            } catch {
                errorMessage = error.localizedDescription
                newCommentText = content // Restore text on error
            }
        }
    }

    private func deleteComment(_ comment: Comment) {
        Task {
            do {
                try await SupabaseManager.shared.deleteComment(commentId: comment.id)
                comments.removeAll { $0.id == comment.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Modern Comment Row

struct ModernCommentRow: View {
    let comment: Comment
    let onReply: () -> Void
    let onDelete: () -> Void

    @State private var userVote: Int? // -1 = downvote, 1 = upvote, nil = no vote
    @State private var score: Int

    init(comment: Comment, onReply: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.comment = comment
        self.onReply = onReply
        self.onDelete = onDelete
        self._score = State(initialValue: comment.score)
    }

    var body: some View {
        GlassCard(padding: 16, cornerRadius: 16, shadowRadius: 5) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Avatar + User Info
                HStack(spacing: 12) {
                    SmallGlassAvatar(
                        imageURL: comment.userAvatar.flatMap { URL(string: $0) },
                        initials: comment.userName?.prefix(1).uppercased().description ?? "?",
                        size: 44
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(comment.userName ?? "Anonyme")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)

                            if let karma = comment.userKarma, karma > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                    Text("\(karma)")
                                        .font(.caption2.weight(.medium))
                                }
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .orange.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.1))
                                )
                            }
                        }

                        Text(timeAgoString(from: comment.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Delete button (only for own comments)
                    if comment.userId == SupabaseManager.shared.currentUser?.id {
                        Button(action: onDelete) {
                            Image(systemName: "trash.fill")
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.red, .red.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.red.opacity(0.1))
                                )
                        }
                    }
                }

                // Comment content
                Text(comment.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                GlassDivider()
                    .padding(.vertical, 4)

                // Actions
                HStack(spacing: 16) {
                    // Upvote/Downvote
                    HStack(spacing: 12) {
                        Button(action: { vote(1) }) {
                            HStack(spacing: 4) {
                                Image(systemName: userVote == 1 ? "arrow.up.circle.fill" : "arrow.up.circle")
                                    .font(.body)
                            }
                            .foregroundStyle(
                                userVote == 1 ?
                                LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [.secondary, .secondary.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Text("\(score)")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(
                                userVote == 1 ? .orange :
                                userVote == -1 ? .blue :
                                .secondary
                            )
                            .frame(minWidth: 24)
                            .animation(.spring(response: 0.3), value: score)

                        Button(action: { vote(-1) }) {
                            HStack(spacing: 4) {
                                Image(systemName: userVote == -1 ? "arrow.down.circle.fill" : "arrow.down.circle")
                                    .font(.body)
                            }
                            .foregroundStyle(
                                userVote == -1 ?
                                LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [.secondary, .secondary.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    // Reply button
                    Button(action: onReply) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.fill")
                                .font(.body)
                            if comment.repliesCount > 0 {
                                Text("\(comment.repliesCount)")
                                    .font(.callout.weight(.medium))
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Spacer()
                }
            }
        }
        .task {
            // Load user's vote status
            userVote = try? await SupabaseManager.shared.getUserVote(commentId: comment.id)
        }
    }

    private func vote(_ voteType: Int) {
        Task {
            do {
                if userVote == voteType {
                    // Remove vote if clicking same button
                    try await SupabaseManager.shared.removeVote(commentId: comment.id)
                    withAnimation(.spring(response: 0.3)) {
                        score -= voteType
                        userVote = nil
                    }
                } else {
                    // Add or change vote
                    let previousVote = userVote
                    try await SupabaseManager.shared.voteComment(commentId: comment.id, voteType: voteType)

                    // Update score
                    withAnimation(.spring(response: 0.3)) {
                        if let previous = previousVote {
                            score -= previous // Remove previous vote effect
                        }
                        score += voteType // Add new vote effect
                        userVote = voteType
                    }
                }
            } catch {
                print("Error voting: \(error)")
            }
        }
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "à l'instant"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "il y a \(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "il y a \(hours)h"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "il y a \(days)j"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}
