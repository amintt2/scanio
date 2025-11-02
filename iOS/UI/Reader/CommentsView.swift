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
                                Color.blue.opacity(0.2),
                                Color.blue.opacity(0.1)
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
                            colors: [.blue, .blue.opacity(0.7)],
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
            LazyVStack(spacing: 0) {
                ForEach(comments.filter { $0.parentCommentId == nil }) { comment in
                    VStack(spacing: 0) {
                        YouTubeCommentRow(
                            comment: comment,
                            canonicalMangaId: canonicalMangaId ?? "",
                            chapterNumber: chapter.chapterNumber.map { String(format: "%.1f", $0) } ?? "0",
                            onDelete: { deleteComment(comment) }
                        )

                        // Subtle divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 0.5)
                            .padding(.leading, 52)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Reply Indicator

    private func replyIndicator(for comment: Comment) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrowshape.turn.up.left.fill")
                .font(.caption)
                .foregroundColor(.blue)

            Text("Répondre à ")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            +
            Text(comment.userName ?? "Anonyme")
                .font(.caption.weight(.semibold))
                .foregroundColor(.blue)

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
                Button(action: {
                    print("🟡 Send button tapped!")
                    print("🟡 Text: '\(newCommentText)'")
                    print("🟡 Is disabled: \(newCommentText.isEmpty || isLoading)")
                    postComment()
                }) {
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
    }

    private func loadComments() {
        print("🟢 loadComments called")
        print("🟢 Manga title: \(manga.title)")
        print("🟢 Manga sourceKey: \(manga.sourceKey)")
        print("🟢 Manga key: \(manga.key)")

        isLoading = true
        errorMessage = nil

        Task {
            do {
                print("🟢 Getting or creating canonical manga...")
                // Get or create canonical manga
                let canonicalId = try await SupabaseManager.shared.getOrCreateCanonicalManga(
                    title: manga.title,
                    sourceId: manga.sourceKey,
                    mangaId: manga.key
                )
                print("🟢 Got canonical ID: \(canonicalId)")
                canonicalMangaId = canonicalId
                print("🟢 Set canonicalMangaId to: \(canonicalMangaId ?? "nil")")

                // Fetch comments using canonical manga ID and chapter number
                let chapterNumber = chapter.chapterNumber.map { String(format: "%.1f", $0) } ?? "0"
                print("🟢 Fetching comments for chapter: \(chapterNumber)")
                comments = try await SupabaseManager.shared.fetchComments(
                    canonicalMangaId: canonicalId,
                    chapterNumber: chapterNumber
                )
                print("🟢 Fetched \(comments.count) comments")
                isLoading = false
            } catch {
                print("🔴 Error loading comments: \(error)")
                print("🔴 Error localized: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func postComment() {
        print("🟢 postComment called")
        print("🟢 newCommentText: '\(newCommentText)'")
        print("🟢 canonicalMangaId: \(canonicalMangaId ?? "nil")")

        guard !newCommentText.isEmpty else {
            print("🔴 Text is empty, returning")
            return
        }

        guard let canonicalId = canonicalMangaId else {
            print("🔴 No canonical manga ID")
            errorMessage = "Impossible de créer un commentaire pour le moment"
            return
        }

        let content = newCommentText
        newCommentText = ""
        errorMessage = nil

        print("🟢 Starting Task to create comment")
        print("🟢 Content: '\(content)'")
        print("🟢 Canonical ID: \(canonicalId)")
        print("🟢 Reply to: \(replyingTo?.id ?? "nil")")

        Task {
            do {
                let chapterNumber = chapter.chapterNumber.map { String(format: "%.1f", $0) } ?? "0"
                print("🟢 Chapter number: \(chapterNumber)")
                print("🟢 Calling SupabaseManager.createComment...")

                let newComment = try await SupabaseManager.shared.createComment(
                    canonicalMangaId: canonicalId,
                    chapterNumber: chapterNumber,
                    content: content,
                    parentCommentId: replyingTo?.id
                )

                print("🟢 Comment created successfully: \(newComment.id)")

                // Only add to list if it's a top-level comment (no parent)
                if newComment.parentCommentId == nil {
                    comments.insert(newComment, at: 0)
                }

                replyingTo = nil
            } catch {
                print("🔴 Error creating comment: \(error)")
                print("🔴 Error localized: \(error.localizedDescription)")
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

// MARK: - YouTube-Style Comment Row

struct YouTubeCommentRow: View {
    let comment: Comment
    let canonicalMangaId: String
    let chapterNumber: String
    let onDelete: () -> Void

    @State private var userVote: Int? = nil
    @State private var score: Int
    @State private var showRepliesSheet = false
    @State private var showUserProfile = false  // PHASE 5, Task 5.4

    init(comment: Comment, canonicalMangaId: String, chapterNumber: String, onDelete: @escaping () -> Void) {
        self.comment = comment
        self.canonicalMangaId = canonicalMangaId
        self.chapterNumber = chapterNumber
        self.onDelete = onDelete
        self._score = State(initialValue: comment.score)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Avatar + User Info + Menu
            HStack(alignment: .top, spacing: 10) {
                // Avatar (smaller) - PHASE 5, Task 5.4: Clickable
                Button {
                    showUserProfile = true
                } label: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(comment.userName?.prefix(1).uppercased() ?? "?")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                        )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    // Username + Time - PHASE 5, Task 5.4: Clickable username
                    HStack(spacing: 6) {
                        Button {
                            showUserProfile = true
                        } label: {
                            Text(comment.userName ?? "Anonyme")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)

                        Text("• \(timeAgoString(from: comment.createdAt))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Rich content with expansion
                    RichTextView(text: comment.content, maxLines: 4)

                    // Actions bar
                    HStack(spacing: 16) {
                        // Vote buttons (compact)
                        HStack(spacing: 8) {
                            Button(action: { vote(1) }) {
                                Image(systemName: userVote == 1 ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .font(.caption)
                                    .foregroundColor(userVote == 1 ? .orange : .secondary)
                            }

                            Text(formatScore(score))
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.secondary)
                                .frame(minWidth: 20)

                            Button(action: { vote(-1) }) {
                                Image(systemName: userVote == -1 ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .font(.caption)
                                    .foregroundColor(userVote == -1 ? .blue : .secondary)
                            }
                        }

                        // Reply/View Replies button
                        Button(action: { showRepliesSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .font(.caption)
                                if comment.repliesCount > 0 {
                                    Text("\(comment.repliesCount) réponse\(comment.repliesCount > 1 ? "s" : "") >")
                                        .font(.caption.weight(.medium))
                                } else {
                                    Text("Répondre")
                                        .font(.caption.weight(.medium))
                                }
                            }
                            .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Delete button (only for own comments)
                        if comment.userId == SupabaseManager.shared.currentUser?.id {
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 12)
        .task {
            // Load user's vote status
            userVote = try? await SupabaseManager.shared.getUserVote(commentId: comment.id)
        }
        .sheet(isPresented: $showRepliesSheet) {
            RepliesView(
                parentComment: comment,
                canonicalMangaId: canonicalMangaId,
                chapterNumber: chapterNumber
            )
        }
        // PHASE 5, Task 5.4: User profile sheet
        .sheet(isPresented: $showUserProfile) {
            UserProfileSheet(userId: comment.userId)
        }
    }

    private func formatScore(_ score: Int) -> String {
        if score >= 1000 {
            return String(format: "%.1fk", Double(score) / 1000.0)
        }
        return "\(score)"
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
