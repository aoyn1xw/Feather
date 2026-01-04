import SwiftUI
import NimbleViews

// MARK: - Guide Detail View
struct GuideDetailView: View {
    let guide: Guide
    @State private var content: String = ""
    @State private var parsedContent: ParsedGuideContent?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @AppStorage("Feather.userTintColor") private var selectedColorHex: String = "#0077BE"
    @AppStorage("Feather.userTintColorType") private var colorType: String = "solid"
    @AppStorage("Feather.userTintGradientStart") private var gradientStartHex: String = "#0077BE"
    @AppStorage("Feather.userTintGradientEnd") private var gradientEndHex: String = "#848ef9"
    
    var accentColor: Color {
        if colorType == "gradient" {
            return Color(hex: gradientStartHex)
        } else {
            return Color(hex: selectedColorHex)
        }
    }
    
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
        case .heading(let level, let text, let isAccent):
            renderHeading(level: level, text: text, isAccent: isAccent)
            
        case .paragraph(let content):
            renderParagraph(content: content)
            
        case .codeBlock(let language, let code):
            renderCodeBlock(language: language, code: code)
            
        case .image(let url, let altText):
            renderImage(url: url, altText: altText)
            
        case .link(let url, let text):
            renderLink(url: url, text: text)
            
        case .listItem(let level, let content):
            renderListItem(level: level, content: content)
            
        case .blockquote(let content):
            renderBlockquote(content: content)
        }
    }
    
    private func renderHeading(level: Int, text: String, isAccent: Bool) -> some View {
        return Text(text)
            .font(headingFont(for: level))
            .fontWeight(.bold)
            .foregroundStyle(isAccent ? accentColor : .primary)
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
    
    private func renderParagraph(content: [InlineContent]) -> some View {
        renderInlineContent(content)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func renderInlineContent(_ content: [InlineContent]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ForEach(content) { segment in
                switch segment {
                case .text(let text):
                    Text(parseInlineMarkdown(text))
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                case .link(let url, let text):
                    if let validURL = URL(string: url) {
                        Link(destination: validURL) {
                            Text(text)
                                .font(.body)
                                .foregroundStyle(.blue)
                                .underline()
                        }
                    } else {
                        Text(text)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                case .accentText(let text):
                    Text(parseInlineMarkdown(text))
                        .font(.body)
                        .foregroundStyle(accentColor)
                    
                case .accentLink(let url, let text):
                    if let validURL = URL(string: url) {
                        Link(destination: validURL) {
                            Text(text)
                                .font(.body)
                                .foregroundStyle(accentColor)
                                .underline()
                        }
                    } else {
                        Text(text)
                            .font(.body)
                            .foregroundStyle(accentColor)
                    }
                }
            }
        }
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
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
            case .failure:
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    if let alt = altText {
                        Text(alt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 150)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private func renderLink(url: String, text: String) -> some View {
        if let validURL = URL(string: url) {
            return AnyView(
                Link(destination: validURL) {
                    HStack {
                        Text(text)
                            .foregroundStyle(.blue)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        } else {
            return AnyView(
                Text(text)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        }
    }
    
    private func renderListItem(level: Int, content: [InlineContent]) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
                .frame(width: 16)
            renderInlineContent(content)
        }
        .padding(.leading, CGFloat(level) * 20)
    }
    
    private func renderBlockquote(content: [InlineContent]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.blue.opacity(0.5))
                .frame(width: 4)
            
            renderInlineContent(content)
                .italic()
        }
        .padding(.vertical, 8)
    }
    
    // Static regex patterns for better performance
    private static let codeRegex = try? NSRegularExpression(pattern: "`([^`]+)`", options: [])
    private static let boldRegex = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*|__(.+?)__", options: [])
    private static let italicRegex = try? NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)|(?<!_)_(?!_)(.+?)(?<!_)_(?!_)", options: [])
    
    // Simple inline markdown parser for bold, italic, and inline code
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var resultText = text
        var ranges: [(range: Range<String.Index>, type: FormatType)] = []
        
        enum FormatType {
            case code
            case bold
            case italic
        }
        
        // Process code first (highest priority)
        if let regex = Self.codeRegex {
            let matches = regex.matches(in: resultText, options: [], range: NSRange(resultText.startIndex..., in: resultText))
            // Process in reverse to maintain indices
            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: resultText),
                   match.numberOfRanges >= 2,
                   let contentRange = Range(match.range(at: 1), in: resultText) {
                    let content = String(resultText[contentRange])
                    resultText.replaceSubrange(matchRange, with: content)
                    
                    // Calculate new range after replacement
                    let newStart = matchRange.lowerBound
                    let newEnd = resultText.index(newStart, offsetBy: content.count)
                    ranges.append((range: newStart..<newEnd, type: .code))
                }
            }
        }
        
        // Process bold (before italic to handle ** vs *)
        if let regex = Self.boldRegex {
            let matches = regex.matches(in: resultText, options: [], range: NSRange(resultText.startIndex..., in: resultText))
            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: resultText) {
                    // Try group 1 (for **text**) or group 2 (for __text__)
                    var content = ""
                    var contentRange: Range<String.Index>?
                    
                    if match.numberOfRanges >= 2, let range1 = Range(match.range(at: 1), in: resultText), !resultText[range1].isEmpty {
                        contentRange = range1
                        content = String(resultText[range1])
                    } else if match.numberOfRanges >= 3, let range2 = Range(match.range(at: 2), in: resultText), !resultText[range2].isEmpty {
                        contentRange = range2
                        content = String(resultText[range2])
                    }
                    
                    if let _ = contentRange {
                        resultText.replaceSubrange(matchRange, with: content)
                        
                        let newStart = matchRange.lowerBound
                        let newEnd = resultText.index(newStart, offsetBy: content.count)
                        ranges.append((range: newStart..<newEnd, type: .bold))
                    }
                }
            }
        }
        
        // Process italic last
        if let regex = Self.italicRegex {
            let matches = regex.matches(in: resultText, options: [], range: NSRange(resultText.startIndex..., in: resultText))
            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: resultText) {
                    var content = ""
                    var contentRange: Range<String.Index>?
                    
                    if match.numberOfRanges >= 2, let range1 = Range(match.range(at: 1), in: resultText), !resultText[range1].isEmpty {
                        contentRange = range1
                        content = String(resultText[range1])
                    } else if match.numberOfRanges >= 3, let range2 = Range(match.range(at: 2), in: resultText), !resultText[range2].isEmpty {
                        contentRange = range2
                        content = String(resultText[range2])
                    }
                    
                    if let _ = contentRange {
                        resultText.replaceSubrange(matchRange, with: content)
                        
                        let newStart = matchRange.lowerBound
                        let newEnd = resultText.index(newStart, offsetBy: content.count)
                        ranges.append((range: newStart..<newEnd, type: .italic))
                    }
                }
            }
        }
        
        // Create attributed string
        var result = AttributedString(resultText)
        
        // Apply formatting
        for (range, type) in ranges {
            if let attrRange = Range(range, in: result) {
                switch type {
                case .code:
                    result[attrRange].font = .system(.body, design: .monospaced)
                    result[attrRange].backgroundColor = Color.secondary.opacity(0.2)
                case .bold:
                    result[attrRange].font = .body.bold()
                case .italic:
                    result[attrRange].font = .body.italic()
                }
            }
        }
        
        return result
    }
}
