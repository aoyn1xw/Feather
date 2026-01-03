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
    private static let italicRegex = try? NSRegularExpression(pattern: "(?<!\\*|_)(\\*|_)([^*_]+?)\\1(?!\\*|_)")
    
    // Simple inline markdown parser for bold, italic, and inline code
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var workingText = text
        
        // Track formatting information with adjusted positions
        struct FormattingInfo {
            var startIndex: Int
            var length: Int
            let type: FormatType
        }
        
        enum FormatType {
            case code
            case bold
            case italic
        }
        
        var formatInfos: [FormattingInfo] = []
        
        // Find inline code (backticks) - process first as they take precedence
        if let regex = Self.codeRegex {
            let matches = regex.matches(in: workingText, range: NSRange(location: 0, length: (workingText as NSString).length))
            for match in matches {
                if match.numberOfRanges >= 2,
                   let contentRange = Range(match.range(at: 1), in: workingText) {
                    let content = String(workingText[contentRange])
                    formatInfos.append(FormattingInfo(
                        startIndex: match.range.location,
                        length: content.count,
                        type: .code
                    ))
                }
            }
        }
        
        // Find bold (**text** or __text__)
        if let regex = Self.boldRegex {
            let matches = regex.matches(in: workingText, range: NSRange(location: 0, length: (workingText as NSString).length))
            for match in matches {
                if match.numberOfRanges >= 3 {
                    let fullRange = match.range
                    let contentRange = match.range(at: 2)
                    
                    // Check if this range overlaps with code ranges
                    let overlapsWithCode = formatInfos.contains { info in
                        info.type == .code &&
                        !(fullRange.location + fullRange.length <= info.startIndex || fullRange.location >= info.startIndex + info.length)
                    }
                    
                    if !overlapsWithCode, let content = Range(contentRange, in: workingText) {
                        formatInfos.append(FormattingInfo(
                            startIndex: fullRange.location,
                            length: String(workingText[content]).count,
                            type: .bold
                        ))
                    }
                }
            }
        }
        
        // Find italic (*text* or _text_)
        if let regex = Self.italicRegex {
            let matches = regex.matches(in: workingText, range: NSRange(location: 0, length: (workingText as NSString).length))
            for match in matches {
                if match.numberOfRanges >= 3 {
                    let fullRange = match.range
                    let contentRange = match.range(at: 2)
                    
                    // Check if this range overlaps with code or bold ranges
                    let overlaps = formatInfos.contains { info in
                        (info.type == .code || info.type == .bold) &&
                        !(fullRange.location + fullRange.length <= info.startIndex || fullRange.location >= info.startIndex + info.length)
                    }
                    
                    if !overlaps, let content = Range(contentRange, in: workingText) {
                        formatInfos.append(FormattingInfo(
                            startIndex: fullRange.location,
                            length: String(workingText[content]).count,
                            type: .italic
                        ))
                    }
                }
            }
        }
        
        // Sort by position (descending) to replace from end to start
        let sortedFormats = formatInfos.sorted { $0.startIndex > $1.startIndex }
        
        // Collect replacements to apply in reverse order
        struct Replacement {
            let range: NSRange
            let content: String
            let type: FormatType
        }
        
        var replacements: [Replacement] = []
        
        // First pass: collect all replacements with their content
        for info in sortedFormats {
            let nsRange: NSRange
            
            // Find the actual markdown range based on type
            if info.type == .code {
                // Code: `content` - need to find backticks
                let searchStart = max(0, info.startIndex - 1)
                let searchEnd = info.startIndex + info.length + 1
                let searchRange = NSRange(location: searchStart, length: min(searchEnd - searchStart, (workingText as NSString).length - searchStart))
                
                if let codeMatch = Self.codeRegex?.matches(in: workingText, range: searchRange).first,
                   codeMatch.numberOfRanges >= 2 {
                    nsRange = codeMatch.range
                    if let contentRange = Range(codeMatch.range(at: 1), in: workingText) {
                        replacements.append(Replacement(
                            range: nsRange,
                            content: String(workingText[contentRange]),
                            type: .code
                        ))
                    }
                }
            } else if info.type == .bold {
                // Bold: **content** or __content__
                let searchStart = max(0, info.startIndex - 2)
                let searchEnd = info.startIndex + info.length + 2
                let searchRange = NSRange(location: searchStart, length: min(searchEnd - searchStart, (workingText as NSString).length - searchStart))
                
                if let boldMatch = Self.boldRegex?.matches(in: workingText, range: searchRange).first,
                   boldMatch.numberOfRanges >= 3 {
                    nsRange = boldMatch.range
                    if let contentRange = Range(boldMatch.range(at: 2), in: workingText) {
                        replacements.append(Replacement(
                            range: nsRange,
                            content: String(workingText[contentRange]),
                            type: .bold
                        ))
                    }
                }
            } else { // italic
                // Italic: *content* or _content_
                let searchStart = max(0, info.startIndex - 1)
                let searchEnd = info.startIndex + info.length + 1
                let searchRange = NSRange(location: searchStart, length: min(searchEnd - searchStart, (workingText as NSString).length - searchStart))
                
                if let italicMatch = Self.italicRegex?.matches(in: workingText, range: searchRange).first,
                   italicMatch.numberOfRanges >= 3 {
                    nsRange = italicMatch.range
                    if let contentRange = Range(italicMatch.range(at: 2), in: workingText) {
                        replacements.append(Replacement(
                            range: nsRange,
                            content: String(workingText[contentRange]),
                            type: .italic
                        ))
                    }
                }
            }
        }
        
        // Second pass: apply replacements from end to start
        var nsWorkingText = workingText as NSString
        for replacement in replacements {
            nsWorkingText = nsWorkingText.replacingCharacters(in: replacement.range, with: replacement.content) as NSString
        }
        workingText = nsWorkingText as String
        
        // Create attributed string with cleaned text
        var result = AttributedString(workingText)
        
        // Third pass: apply formatting to the cleaned string
        // Adjust positions based on cumulative offset from replacements
        var cumulativeOffset = 0
        let sortedReplacements = replacements.sorted { $0.range.location < $1.range.location }
        
        for replacement in sortedReplacements {
            let adjustedStart = replacement.range.location - cumulativeOffset
            let adjustedLength = replacement.content.count
            
            if adjustedStart >= 0 && adjustedStart + adjustedLength <= workingText.count {
                let startIndex = workingText.index(workingText.startIndex, offsetBy: adjustedStart)
                let endIndex = workingText.index(startIndex, offsetBy: adjustedLength)
                
                if let attrRange = Range(startIndex..<endIndex, in: result) {
                    switch replacement.type {
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
            
            // Update offset: removed characters - added characters
            cumulativeOffset += replacement.range.length - replacement.content.count
        }
        
        return result
    }
}
