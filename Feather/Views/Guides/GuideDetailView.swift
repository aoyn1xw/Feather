import SwiftUI
import NimbleViews

// MARK: - Guide Detail View
struct GuideDetailView: View {
    let guide: Guide
    @State private var content: String = ""
    @State private var parsedContent: ParsedGuideContent?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @AppStorage("Feather.userTintColor") private var selectedColorHex: String = "#B496DC"
    @AppStorage("Feather.userTintColorType") private var colorType: String = "solid"
    @AppStorage("Feather.userTintGradientStart") private var gradientStartHex: String = "#B496DC"
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
        case .heading(let level, let text):
            renderHeading(level: level, text: text)
            
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
    private static let codeRegex = try? NSRegularExpression(pattern: "`([^`]+)`")
    private static let boldRegex = try? NSRegularExpression(pattern: "(\\*\\*|__)([^*_]+)(\\*\\*|__)")
    private static let italicRegex = try? NSRegularExpression(pattern: "(\\*|_)([^*_]+)(\\*|_)")
    
    // Simple inline markdown parser for bold, italic, and inline code
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString()
        var workingText = text
        
        // Track formatting information
        struct FormattingInfo {
            let range: Range<String.Index>
            let type: FormatType
        }
        
        enum FormatType {
            case code
            case bold
            case italic
        }
        
        var formatRanges: [(range: Range<String.Index>, type: FormatType, content: String)] = []
        
        // Find inline code (backticks)
        if let regex = Self.codeRegex {
            let matches = regex.matches(in: workingText, range: NSRange(location: 0, length: (workingText as NSString).length))
            for match in matches {
                if match.numberOfRanges >= 2,
                   let fullRange = Range(match.range, in: workingText),
                   let contentRange = Range(match.range(at: 1), in: workingText) {
                    formatRanges.append((range: fullRange, type: .code, content: String(workingText[contentRange])))
                }
            }
        }
        
        // Find bold (**text** or __text__)
        if let regex = Self.boldRegex {
            let matches = regex.matches(in: workingText, range: NSRange(location: 0, length: (workingText as NSString).length))
            for match in matches {
                if match.numberOfRanges >= 3,
                   let fullRange = Range(match.range, in: workingText),
                   let contentRange = Range(match.range(at: 2), in: workingText) {
                    // Check if this range overlaps with code ranges
                    let overlapsWithCode = formatRanges.contains { $0.type == .code && $0.range.overlaps(fullRange) }
                    if !overlapsWithCode {
                        formatRanges.append((range: fullRange, type: .bold, content: String(workingText[contentRange])))
                    }
                }
            }
        }
        
        // Find italic (*text* or _text_) - need to avoid matching bold markers
        if let regex = try? NSRegularExpression(pattern: "(?<!\\*|_)(\\*|_)([^*_]+?)\\1(?!\\*|_)") {
            let matches = regex.matches(in: workingText, range: NSRange(location: 0, length: (workingText as NSString).length))
            for match in matches {
                if match.numberOfRanges >= 3,
                   let fullRange = Range(match.range, in: workingText),
                   let contentRange = Range(match.range(at: 2), in: workingText) {
                    // Check if this range overlaps with code or bold ranges
                    let overlaps = formatRanges.contains { ($0.type == .code || $0.type == .bold) && $0.range.overlaps(fullRange) }
                    if !overlaps {
                        formatRanges.append((range: fullRange, type: .italic, content: String(workingText[contentRange])))
                    }
                }
            }
        }
        
        // Sort ranges by position (reversed for replacement)
        formatRanges.sort { $0.range.lowerBound > $1.range.lowerBound }
        
        // Replace markdown syntax with clean text
        for info in formatRanges {
            workingText.replaceSubrange(info.range, with: info.content)
        }
        
        // Create attributed string with the clean text
        result = AttributedString(workingText)
        
        // Apply formatting based on original positions
        // Re-sort by position for applying formatting
        formatRanges.sort { $0.range.lowerBound < $1.range.lowerBound }
        
        for info in formatRanges {
            // Find the content in the cleaned string
            if let range = result.range(of: info.content) {
                switch info.type {
                case .code:
                    result[range].font = .system(.body, design: .monospaced)
                    result[range].backgroundColor = Color.secondary.opacity(0.2)
                case .bold:
                    result[range].font = .body.bold()
                case .italic:
                    result[range].font = .body.italic()
                }
            }
        }
        
        return result
    }
}
