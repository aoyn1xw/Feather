import Foundation

// MARK: - GitHub Guides Service
class GitHubGuidesService {
    static let shared = GitHubGuidesService()
    
    private let baseURL = "https://api.github.com/repos/WSF-Team/WSF/contents/Portal/Guides"
    private let rawBaseURL = "https://raw.githubusercontent.com/WSF-Team/WSF/main/Portal/Guides"
    
    private init() {}
    
    enum ServiceError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case noData
        case decodingError(Error)
        case contentNotAvailable
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .noData:
                return "No data received"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .contentNotAvailable:
                return "Content not available"
            }
        }
    }
    
    // Fetch list of guides from the GitHub repository
    func fetchGuides() async throws -> [Guide] {
        guard let url = URL(string: baseURL) else {
            throw ServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let contents = try JSONDecoder().decode([GitHubContent].self, from: data)
            
            // Convert to Guide models, filtering for .md files and directories
            let guides = contents.compactMap { content -> Guide? in
                // Only include markdown files and directories
                if content.type == "file" && !content.name.hasSuffix(".md") {
                    return nil
                }
                
                return Guide(
                    id: content.sha,
                    name: content.name,
                    path: content.path,
                    type: content.type == "dir" ? .directory : .file,
                    content: nil
                )
            }.sorted { $0.displayName < $1.displayName }
            
            return guides
        } catch {
            throw ServiceError.decodingError(error)
        }
    }
    
    // Fetch content of a specific guide
    func fetchGuideContent(guide: Guide) async throws -> String {
        // For files, use the raw GitHub URL
        guard guide.type == .file else {
            throw ServiceError.contentNotAvailable
        }
        
        let contentURL = "\(rawBaseURL)/\(guide.name)"
        
        guard let url = URL(string: contentURL) else {
            throw ServiceError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw ServiceError.noData
        }
        
        return content
    }
}
