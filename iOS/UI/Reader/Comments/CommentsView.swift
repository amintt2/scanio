//
//  CommentsView.swift
//  Scanio
//
//  SwiftUI view for displaying chapter comments
//

import SwiftUI

struct CommentsView: View {
    let chapterId: String

    @Environment(\.dismiss) var dismiss

    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var newCommentText = ""
    @State private var errorMessage: String?
    @State private var replyingTo: Comment?

    var body: some View {
        VStack(spacing: 0) {
            // Header with liquid glass effect
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Commentaires")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("\(comments.count) commentaire\(comments.count > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding()
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 0)
            )

            Divider()

            // Comments list
            if isLoading && comments.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if comments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Aucun commentaire")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Soyez le premier à commenter ce chapitre")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(comments) { comment in
                            CommentRowView(
                                comment: comment,
                                onReply: { replyingTo = comment },
                                onDelete: { deleteComment(comment) }
                            )
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }

            // Error message
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            // Reply indicator
            if let replyingTo {
                HStack {
                    Text("Répondre à \(replyingTo.userName ?? "Anonyme")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Annuler") {
                        self.replyingTo = nil
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
            }

            // Input field with liquid glass effect
            HStack(spacing: 12) {
                TextField("Ajouter un commentaire...", text: $newCommentText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button(action: postComment) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(newCommentText.isEmpty ? .secondary : .accentColor)
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(newCommentText.isEmpty || isLoading)
            }
            .padding()
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 0)
            )
        }
        .onAppear {
            loadComments()
        }
    }

    private func loadComments() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                comments = try await SupabaseManager.shared.fetchComments(for: chapterId)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func postComment() {
        guard !newCommentText.isEmpty else { return }

        let content = newCommentText
        newCommentText = ""
        errorMessage = nil

        Task {
            do {
                let newComment = try await SupabaseManager.shared.createComment(
                    chapterId: chapterId,
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

struct CommentRowView: View {
    let comment: Comment
    let onReply: () -> Void
    let onDelete: () -> Void

    @State private var isLiked = false
    @State private var likesCount: Int

    init(comment: Comment, onReply: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.comment = comment
        self.onReply = onReply
        self.onDelete = onDelete
        self._likesCount = State(initialValue: comment.likesCount)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(comment.userName?.prefix(1).uppercased() ?? "?")
                        .font(.headline)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                // Username and time
                HStack {
                    Text(comment.userName ?? "Anonyme")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("• \(timeAgoString(from: comment.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                // Comment content
                Text(comment.content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                // Actions
                HStack(spacing: 20) {
                    Button(action: toggleLike) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.subheadline)
                            if likesCount > 0 {
                                Text("\(likesCount)")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(isLiked ? .red : .secondary)
                    }

                    Button(action: onReply) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .font(.subheadline)
                            if comment.repliesCount > 0 {
                                Text("\(comment.repliesCount)")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Delete button (only for own comments)
                    if comment.userId == SupabaseManager.shared.currentUser?.id {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
    }

    private func toggleLike() {
        Task {
            do {
                if isLiked {
                    try await SupabaseManager.shared.unlikeComment(commentId: comment.id)
                    likesCount -= 1
                } else {
                    try await SupabaseManager.shared.likeComment(commentId: comment.id)
                    likesCount += 1
                }
                isLiked.toggle()
            } catch {
                // Handle error silently or show toast
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
