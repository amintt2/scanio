//
//  RichTextView.swift
//  Scanio
//
//  Rich text renderer for comments with Markdown, URLs, and GIF support
//

import SwiftUI

/// Rich text view that supports Markdown, clickable URLs, and embedded GIFs
struct RichTextView: View {
    let text: String
    var maxLines: Int? = 3
    @State private var isExpanded = false
    @State private var needsExpansion = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Render content
            if isExpanded {
                contentView
            } else {
                contentView
                    .frame(maxHeight: maxHeight, alignment: .top)
                    .clipped()
                    .overlay(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: HeightPreferenceKey.self,
                                value: geo.size.height
                            )
                        }
                    )
                    .onPreferenceChange(HeightPreferenceKey.self) { height in
                        if let maxH = maxHeight, height >= maxH {
                            needsExpansion = true
                        }
                    }
            }

            // "... plus" / "... moins" button
            if needsExpansion {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Text(isExpanded ? "... moins" : "... plus")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private var maxHeight: CGFloat? {
        guard let lines = maxLines else { return nil }
        return CGFloat(lines) * 20 // Approximate line height
    }
    
    private var contentView: some View {
        let components = parseContent(text)
        
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(components.enumerated()), id: \.offset) { _, component in
                switch component {
                case .text(let string):
                    Text(string)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                    
                case .url(let urlString):
                    if isGifURL(urlString) {
                        // Render GIF with limited size
                        GIFView(url: URL(string: urlString)!)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300, maxHeight: 150)
                            .cornerRadius(8)
                            .clipped()
                    } else {
                        // Clickable URL
                        Link(destination: URL(string: urlString)!) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                    .font(.caption)
                                Text(urlString)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                    
                case .markdown(let string):
                    // Simple markdown rendering
                    Text(parseMarkdown(string))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                }
            }
        }
    }
    
    private func isGifURL(_ urlString: String) -> Bool {
        urlString.lowercased().hasSuffix(".gif") ||
        urlString.contains("giphy.com") ||
        urlString.contains("tenor.com")
    }
}

// MARK: - Height Preference Key

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Content Parsing

enum ContentComponent {
    case text(String)
    case url(String)
    case markdown(String)
}

func parseContent(_ text: String) -> [ContentComponent] {
    var components: [ContentComponent] = []
    
    // Regex to detect URLs
    let urlPattern = #"https?://[^\s]+"#
    guard let regex = try? NSRegularExpression(pattern: urlPattern) else {
        return [.text(text)]
    }
    
    let nsString = text as NSString
    let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
    
    var lastIndex = 0
    
    for match in matches {
        // Add text before URL
        if match.range.location > lastIndex {
            let textRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
            let textPart = nsString.substring(with: textRange)
            if !textPart.isEmpty {
                components.append(.text(textPart))
            }
        }
        
        // Add URL
        let urlString = nsString.substring(with: match.range)
        components.append(.url(urlString))
        
        lastIndex = match.range.location + match.range.length
    }
    
    // Add remaining text
    if lastIndex < nsString.length {
        let textRange = NSRange(location: lastIndex, length: nsString.length - lastIndex)
        let textPart = nsString.substring(with: textRange)
        if !textPart.isEmpty {
            components.append(.text(textPart))
        }
    }
    
    // If no URLs found, return as text
    if components.isEmpty {
        components.append(.text(text))
    }
    
    return components
}

func parseMarkdown(_ text: String) -> AttributedString {
    var attributedString = AttributedString(text)
    
    // Bold: **text**
    if let boldRegex = try? NSRegularExpression(pattern: #"\*\*(.+?)\*\*"#) {
        let nsString = text as NSString
        let matches = boldRegex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        for match in matches.reversed() {
            if match.numberOfRanges > 1 {
                let contentRange = match.range(at: 1)
                let content = nsString.substring(with: contentRange)
                
                if let range = Range(match.range, in: text),
                   let attrRange = Range(range, in: attributedString) {
                    attributedString.replaceSubrange(attrRange, with: AttributedString(content))
                    if let boldRange = attributedString.range(of: content) {
                        attributedString[boldRange].font = .subheadline.bold()
                    }
                }
            }
        }
    }
    
    // Italic: *text*
    if let italicRegex = try? NSRegularExpression(pattern: #"\*(.+?)\*"#) {
        let nsString = text as NSString
        let matches = italicRegex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        for match in matches.reversed() {
            if match.numberOfRanges > 1 {
                let contentRange = match.range(at: 1)
                let content = nsString.substring(with: contentRange)
                
                if let range = Range(match.range, in: text),
                   let attrRange = Range(range, in: attributedString) {
                    attributedString.replaceSubrange(attrRange, with: AttributedString(content))
                    if let italicRange = attributedString.range(of: content) {
                        attributedString[italicRange].font = .subheadline.italic()
                    }
                }
            }
        }
    }
    
    return attributedString
}

// MARK: - GIF View

struct GIFView: View {
    let url: URL
    @State private var isLoading = true
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .onAppear { isLoading = false }
            case .failure:
                failureView
            case .empty:
                loadingView
            @unknown default:
                loadingView
            }
        }
    }
    
    private var loadingView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
            
            ProgressView()
        }
    }
    
    private var failureView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
            
            VStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Impossible de charger le GIF")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RichTextView(
            text: "Ceci est un **texte en gras** et *italique* avec un lien https://example.com",
            maxLines: 3
        )
        
        RichTextView(
            text: "Voici un GIF : https://media.giphy.com/media/3o7btPCcdNniyf0ArS/giphy.gif"
        )
    }
    .padding()
}

