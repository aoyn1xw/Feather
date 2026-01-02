import Foundation

// MARK: - Guide Parser
class GuideParser {
    static func parse(markdown: String) -> ParsedGuideContent {
        var elements: [GuideElement] = []
        let lines = markdown.components(separatedBy: .newlines)
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            
            // Skip empty lines
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
                continue
            }
            
            // Parse headings
            if line.hasPrefix("#") {
                let heading = parseHeading(line)
                if let heading = heading {
                    elements.append(heading)
                }
                i += 1
                continue
            }
            
            // Parse code blocks
            if line.hasPrefix("```") {
                let (codeBlock, linesConsumed) = parseCodeBlock(lines: lines, startIndex: i)
                if let codeBlock = codeBlock {
                    elements.append(codeBlock)
                    i += linesConsumed
                    continue
                }
            }
            
            // Parse blockquotes
            if line.hasPrefix(">") {
                let quote = parseBlockquote(line)
                elements.append(quote)
                i += 1
                continue
            }
            
            // Parse list items
            if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                let listItem = parseListItem(line)
                elements.append(listItem)
                i += 1
                continue
            }
            
            // Parse numbered lists
            if let match = line.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let text = String(line[match.upperBound...])
                elements.append(.listItem(text: text))
                i += 1
                continue
            }
            
            // Parse images
            if line.contains("![") {
                if let image = parseImage(line) {
                    elements.append(image)
                    i += 1
                    continue
                }
            }
            
            // Parse links (standalone)
            if line.hasPrefix("[") && line.contains("](") {
                if let link = parseLink(line) {
                    elements.append(link)
                    i += 1
                    continue
                }
            }
            
            // Default: treat as paragraph
            let paragraph = parseParagraph(line)
            elements.append(paragraph)
            i += 1
        }
        
        return ParsedGuideContent(elements: elements)
    }
    
    private static func parseHeading(_ line: String) -> GuideElement? {
        var level = 0
        var text = line
        
        while text.hasPrefix("#") {
            level += 1
            text = String(text.dropFirst())
        }
        
        text = text.trimmingCharacters(in: .whitespaces)
        
        if level > 0 && !text.isEmpty {
            return .heading(level: level, text: text)
        }
        
        return nil
    }
    
    private static func parseCodeBlock(lines: [String], startIndex: Int) -> (GuideElement?, Int) {
        let firstLine = lines[startIndex]
        let language = String(firstLine.dropFirst(3).trimmingCharacters(in: .whitespaces))
        
        var codeLines: [String] = []
        var i = startIndex + 1
        
        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("```") {
                // End of code block
                let code = codeLines.joined(separator: "\n")
                return (.codeBlock(language: language.isEmpty ? nil : language, code: code), i - startIndex + 1)
            }
            codeLines.append(line)
            i += 1
        }
        
        // If we reach here, the code block wasn't closed properly
        let code = codeLines.joined(separator: "\n")
        return (.codeBlock(language: language.isEmpty ? nil : language, code: code), i - startIndex)
    }
    
    private static func parseBlockquote(_ line: String) -> GuideElement {
        let text = line.dropFirst().trimmingCharacters(in: .whitespaces)
        return .blockquote(text: String(text))
    }
    
    private static func parseListItem(_ line: String) -> GuideElement {
        var text = line
        if text.hasPrefix("- ") || text.hasPrefix("* ") || text.hasPrefix("+ ") {
            text = String(text.dropFirst(2))
        }
        return .listItem(text: text)
    }
    
    private static func parseImage(_ line: String) -> GuideElement? {
        // Pattern: ![alt text](url)
        guard let altStart = line.range(of: "!["),
              let altEnd = line.range(of: "](", range: altStart.upperBound..<line.endIndex),
              let urlEnd = line.range(of: ")", range: altEnd.upperBound..<line.endIndex) else {
            return nil
        }
        
        let altText = String(line[altStart.upperBound..<altEnd.lowerBound])
        let url = String(line[altEnd.upperBound..<urlEnd.lowerBound])
        
        return .image(url: url, altText: altText)
    }
    
    private static func parseLink(_ line: String) -> GuideElement? {
        // Pattern: [text](url)
        guard let textStart = line.range(of: "["),
              let textEnd = line.range(of: "](", range: textStart.upperBound..<line.endIndex),
              let urlEnd = line.range(of: ")", range: textEnd.upperBound..<line.endIndex) else {
            return nil
        }
        
        let text = String(line[textStart.upperBound..<textEnd.lowerBound])
        let url = String(line[textEnd.upperBound..<urlEnd.lowerBound])
        
        return .link(url: url, text: text)
    }
    
    private static func parseParagraph(_ line: String) -> GuideElement {
        return .paragraph(text: line)
    }
}
