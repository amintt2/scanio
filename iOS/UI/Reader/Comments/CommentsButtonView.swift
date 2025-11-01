//
//  CommentsButtonView.swift
//  Scanio
//
//  Floating button to open comments
//

import SwiftUI

struct CommentsButtonView: View {
    let commentCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 18, weight: .medium))
                
                if commentCount > 0 {
                    Text("\(commentCount)")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct CommentsFloatingButton: UIViewRepresentable {
    let commentCount: Int
    let onTap: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let hostingController = UIHostingController(
            rootView: CommentsButtonView(commentCount: commentCount, onTap: onTap)
        )
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            hostingController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -80),
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}

