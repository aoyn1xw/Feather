import SwiftUI
import NimbleViews

// MARK: - Guide Detail View
struct GuideDetailView: View {
    let guide: Guide
    @State private var content: String = ""
    @State private var parsedContent: ParsedGuideContent?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading guide...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.red)
                    
                    Text("Failed to load guide")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        Task {
                            await loadContent()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let parsed = parsedContent {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(parsed.elements) { element in
                        renderElement(element)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(guide.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContent()
        }
    }
    
    private func loadContent() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedContent = try await GitHubGuidesService.shared.fetchGuideContent(guide: guide)
            content = fetchedContent
            parsedContent = GuideParser.parse(markdown: fetchedContent)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    @ViewBuilder
    private func renderElement(_ element: GuideElement) -> some View {
        switch element {
        case .heading(let level, let text):
            renderHeading(level: level, text: text)
            
        case .paragraph(let text):
            renderParagraph(text: text)
            
        case .codeBlock(let language, let code):
            renderCodeBlock(language: language, code: code)
            
        case .image(let url, let altText):
            renderImage(url: url, altText: altText)
            
        case .link(let url, let text):
            renderLink(url: url, text: text)
            
        case .listItem(let text):
            renderListItem(text: text)
            
        case .blockquote(let text):
            renderBlockquote(text: text)
        }
    }
    
    private func renderHeading(level: Int, text: String) -> some View {
        Text(text)
            .font(headingFont(for: level))
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, level == 1 ? 8 : 4)
    }
    
    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        case 4: return .headline
        default: return .subheadline
        }
    }
    
    private func renderParagraph(text: String) -> some View {
        Text(parseInlineMarkdown(text))
            .font(.body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func renderCodeBlock(language: String?, code: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let lang = language, !lang.isEmpty {
                Text(lang.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(12)
            }
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func renderImage(url: String, altText: String?) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(8)
            case .failure:
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    if let alt = altText {
                        Text(alt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private func renderLink(url: String, text: String) -> some View {
        Link(destination: URL(string: url) ?? URL(string: "about:blank")!) {
            HStack {
                Text(text)
                    .foregroundStyle(.blue)
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private func renderListItem(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
            Text(parseInlineMarkdown(text))
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(.leading, 8)
    }
    
    private func renderBlockquote(text: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.blue.opacity(0.5))
                .frame(width: 4)
            
            Text(parseInlineMarkdown(text))
                .font(.body)
                .foregroundStyle(.secondary)
                .italic()
        }
        .padding(.vertical, 8)
    }
    
    // Simple inline markdown parser for bold, italic, and inline code
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Handle inline code first (backticks)
        let codePattern = "`([^`]+)`"
        if let regex = try? NSRegularExpression(pattern: codePattern) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    if let attrRange = Range(range, in: attributedString) {
                        attributedString[attrRange].font = .system(.body, design: .monospaced)
                        attributedString[attrRange].backgroundColor = Color.secondary.opacity(0.2)
                    }
                }
            }
        }
        
        // Handle bold (**text** or __text__)
        let boldPattern = "(\\*\\*|__)([^*_]+)(\\*\\*|__)"
        if let regex = try? NSRegularExpression(pattern: boldPattern) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if match.numberOfRanges >= 3 {
                    if let range = Range(match.range(at: 2), in: text),
                       let attrRange = Range(range, in: attributedString) {
                        attributedString[attrRange].font = .body.bold()
                    }
                }
            }
        }
        
        // Handle italic (*text* or _text_)
        let italicPattern = "(\\*|_)([^*_]+)(\\*|_)"
        if let regex = try? NSRegularExpression(pattern: italicPattern) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if match.numberOfRanges >= 3 {
                    if let range = Range(match.range(at: 2), in: text),
                       let attrRange = Range(range, in: attributedString) {
                        attributedString[attrRange].font = .body.italic()
                    }
                }
            }
        }
        
        return attributedString
    }
}
