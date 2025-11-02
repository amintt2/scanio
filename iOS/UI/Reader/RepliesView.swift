//
//  RepliesView.swift
//  Scanio
//
//  Vue modale pour afficher et répondre aux commentaires (style YouTube)
//

import SwiftUI

struct RepliesView: View {
    let parentComment: Comment
    let canonicalMangaId: String
    let chapterNumber: String

    @Environment(\.dismiss) private var dismiss
    @State private var replies: [Comment] = []
    @State private var newReplyText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Parent comment card
                        ParentCommentCard(comment: parentComment)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                        Divider()
                            .padding(.vertical, 16)

                        // Replies section
                        if isLoading {
                            ProgressView()
                                .padding()
                        } else if replies.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("Aucune réponse")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Soyez le premier à répondre !")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(replies) { reply in
                                    ReplyRow(
                                        reply: reply,
                                        onDelete: { deleteReply(reply) }
                                    )
                                    .padding(.horizontal, 16)

                                    if reply.id != replies.last?.id {
                                        Divider()
                                            .padding(.leading, 64)
                                    }
                                }
                            }
                        }
                    }
                }

                // Reply input field
                replyInputField
            }
            .navigationTitle("Réponses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text("Retour")
                        }
                    }
                }
            }
        }
        .onAppear {
            loadReplies()
        }
    }

    private var replyInputField: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(SupabaseManager.shared.currentUser?.userName?.prefix(1).uppercased() ?? "?")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                    )

                TextField("Ajouter une réponse...", text: $newReplyText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                    .focused($isTextFieldFocused)

                Button(action: postReply) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(newReplyText.isEmpty ? .secondary : .accentColor)
                }
                .disabled(newReplyText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }

    private func loadReplies() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                replies = try await SupabaseManager.shared.fetchReplies(
                    canonicalMangaId: canonicalMangaId,
                    chapterNumber: chapterNumber,
                    parentCommentId: parentComment.id
                )
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func postReply() {
        guard !newReplyText.isEmpty else { return }

        let content = newReplyText
        newReplyText = ""
        isTextFieldFocused = false

        Task {
            do {
                let newReply = try await SupabaseManager.shared.createComment(
                    canonicalMangaId: canonicalMangaId,
                    chapterNumber: chapterNumber,
                    content: content,
                    parentCommentId: parentComment.id
                )
                replies.append(newReply)
            } catch {
                errorMessage = error.localizedDescription
                newReplyText = content
            }
        }
    }

    private func deleteReply(_ reply: Comment) {
        Task {
            do {
                try await SupabaseManager.shared.deleteComment(commentId: reply.id)
                replies.removeAll { $0.id == reply.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Parent Comment Card

struct ParentCommentCard: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(comment.userName?.prefix(1).uppercased() ?? "?")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.userName ?? "Anonyme")
                        .font(.subheadline.weight(.semibold))
                    Text(timeAgoString(from: comment.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Text(comment.content)
                .font(.body)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                Label("\(comment.score)", systemImage: "hand.thumbsup")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label("\(comment.repliesCount)", systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Reply Row

struct ReplyRow: View {
    let reply: Comment
    let onDelete: () -> Void

    @State private var userVote: Int? = nil
    @State private var score: Int
    @State private var showUserProfile = false  // PHASE 5, Task 5.4

    init(reply: Comment, onDelete: @escaping () -> Void) {
        self.reply = reply
        self.onDelete = onDelete
        self._score = State(initialValue: reply.score)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 2)
                .padding(.leading, 20)

            VStack(alignment: .leading, spacing: 8) {
                // Header - PHASE 5, Task 5.4: Clickable avatar and username
                HStack(spacing: 8) {
                    Button {
                        showUserProfile = true
                    } label: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.6), Color.orange.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(reply.userName?.prefix(1).uppercased() ?? "?")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(.white)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        showUserProfile = true
                    } label: {
                        Text(reply.userName ?? "Anonyme")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)

                    Text("• \(timeAgoString(from: reply.createdAt))")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    if reply.userId == SupabaseManager.shared.currentUser?.id {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                // Content
                Text(reply.content)
                    .font(.callout)
                    .foregroundColor(.primary)

                // Vote buttons
                HStack(spacing: 12) {
                    // Upvote
                    Button(action: { vote(1) }) {
                        Image(systemName: userVote == 1 ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.caption)
                            .foregroundColor(userVote == 1 ? .blue : .secondary)
                    }

                    // Score
                    Text("\(score)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(scoreColor)
                        .monospacedDigit()

                    // Downvote
                    Button(action: { vote(-1) }) {
                        Image(systemName: userVote == -1 ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.caption)
                            .foregroundColor(userVote == -1 ? .orange : .secondary)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .onAppear {
            loadUserVote()
        }
        // PHASE 5, Task 5.4: User profile sheet
        .sheet(isPresented: $showUserProfile) {
            UserProfileSheet(userId: reply.userId)
        }
    }

    private var scoreColor: Color {
        if score > 0 { return .blue }
        if score < 0 { return .orange }
        return .secondary
    }

    private func loadUserVote() {
        Task {
            userVote = try? await SupabaseManager.shared.getUserVote(commentId: reply.id)
        }
    }

    private func vote(_ value: Int) {
        let previousVote = userVote
        let previousScore = score

        if userVote == value {
            // Remove vote
            userVote = nil
            score -= value

            Task {
                do {
                    try await SupabaseManager.shared.removeVote(commentId: reply.id)
                } catch {
                    userVote = previousVote
                    score = previousScore
                }
            }
        } else {
            // Add or change vote
            if let prev = userVote {
                score -= prev
            }
            userVote = value
            score += value

            Task {
                do {
                    try await SupabaseManager.shared.voteComment(
                        commentId: reply.id,
                        voteType: value
                    )
                } catch {
                    userVote = previousVote
                    score = previousScore
                }
            }
        }
    }
}

// MARK: - Helper Functions

private func timeAgoString(from date: Date) -> String {
    let interval = Date().timeIntervalSince(date)

    if interval < 60 {
        return "À l'instant"
    } else if interval < 3600 {
        let minutes = Int(interval / 60)
        return "Il y a \(minutes) min"
    } else if interval < 86400 {
        let hours = Int(interval / 3600)
        return "Il y a \(hours)h"
    } else if interval < 604800 {
        let days = Int(interval / 86400)
        return "Il y a \(days)j"
    } else {
        let weeks = Int(interval / 604800)
        return "Il y a \(weeks)sem"
    }
}

