import Foundation

// MARK: - Guide Model
struct Guide: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    let type: GuideType
    var content: String?
    
    enum GuideType: String, Codable {
        case file
        case directory = "dir"
    }
    
    var displayName: String {
        // Remove .md extension and format name
        let nameWithoutExtension = name.replacingOccurrences(of: ".md", with: "")
        return nameWithoutExtension.replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - GitHub API Response
struct GitHubContent: Codable {
    let name: String
    let path: String
    let sha: String
    let size: Int?
    let url: String
    let htmlUrl: String?
    let gitUrl: String?
    let downloadUrl: String?
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case name, path, sha, size, url, type
        case htmlUrl = "html_url"
        case gitUrl = "git_url"
        case downloadUrl = "download_url"
    }
}

// MARK: - Parsed Guide Content
struct ParsedGuideContent {
    var elements: [GuideElement]
}

enum GuideElement: Identifiable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String?, code: String)
    case image(url: String, altText: String?)
    case link(url: String, text: String)
    case listItem(text: String)
    case blockquote(text: String)
    
    var id: String {
        switch self {
        case .heading(let level, let text):
            return "heading-\(level)-\(text.hashValue)"
        case .paragraph(let text):
            return "paragraph-\(text.hashValue)"
        case .codeBlock(let language, let code):
            return "code-\(language ?? "none")-\(code.hashValue)"
        case .image(let url, _):
            return "image-\(url.hashValue)"
        case .link(let url, let text):
            return "link-\(url)-\(text.hashValue)"
        case .listItem(let text):
            return "list-\(text.hashValue)"
        case .blockquote(let text):
            return "quote-\(text.hashValue)"
        }
    }
}
