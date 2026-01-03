import Foundation
import AltSourceKit
import SwiftUI
import NimbleJSON

// MARK: - Class
final class SourcesViewModel: ObservableObject {
	static let shared = SourcesViewModel()
	
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	
	private let _dataService = NBFetchService()
	private let _cacheManager = RepositoryCacheManager.shared
	
	var isFinished = true
	@Published var sources: [AltSource: ASRepository] = [:]
	
	@Published var pinnedSourceIDs: [String] = UserDefaults.standard.stringArray(forKey: "pinnedSources") ?? [] {
		didSet {
			UserDefaults.standard.set(pinnedSourceIDs, forKey: "pinnedSources")
		}
	}
	
	func togglePin(for source: AltSource) {
		guard let id = source.sourceURL?.absoluteString else { return }
		if pinnedSourceIDs.contains(id) {
			pinnedSourceIDs.removeAll { $0 == id }
		} else {
			pinnedSourceIDs.append(id)
		}
	}
	
	func isPinned(_ source: AltSource) -> Bool {
		guard let id = source.sourceURL?.absoluteString else { return false }
		return pinnedSourceIDs.contains(id)
	}
	
	func fetchSources(_ sources: FetchedResults<AltSource>, refresh: Bool = false, batchSize: Int = 4) async {
		guard isFinished else { return }
		
		// check if sources to be fetched are the same as before, if yes, return
		// also skip check if refresh is true
		if !refresh, sources.allSatisfy({ self.sources[$0] != nil }) { return }
		
		// isfinished is used to prevent multiple fetches at the same time
		isFinished = false
		defer { isFinished = true }
		
		// Load from cache first if not refreshing
		if !refresh {
			await MainActor.run {
				self.sources = [:]
			}
			
			// Load cached data
			for source in sources {
				if let url = source.sourceURL, let cachedRepo = _cacheManager.getCachedRepository(for: url) {
					await MainActor.run {
						self.sources[source] = cachedRepo
					}
				}
			}
		} else {
			await MainActor.run {
				self.sources = [:]
			}
		}
		
		let sourcesArray = Array(sources)
		
		for startIndex in stride(from: 0, to: sourcesArray.count, by: batchSize) {
			let endIndex = min(startIndex + batchSize, sourcesArray.count)
			let batch = sourcesArray[startIndex..<endIndex]
			
			let batchResults = await withTaskGroup(of: (AltSource, ASRepository?).self, returning: [AltSource: ASRepository].self) { group in
				for source in batch {
					group.addTask {
						guard let url = source.sourceURL else {
							return (source, nil)
						}
						
						return await withCheckedContinuation { continuation in
							self._dataService.fetch(from: url) { (result: RepositoryDataHandler) in
								switch result {
								case .success(let repo):
									// Cache the successful repository
									self._cacheManager.cacheRepository(repo, for: url)
									continuation.resume(returning: (source, repo))
								case .failure(_):
									continuation.resume(returning: (source, nil))
								}
							}
						}
					}
				}
				
				var results = [AltSource: ASRepository]()
				for await (source, repo) in group {
					if let repo {
						results[source] = repo
					}
				}
				return results
			}
			
			await MainActor.run {
				for (source, repo) in batchResults {
					self.sources[source] = repo
				}
			}
		}
	}
}

// MARK: - Repository Cache Manager
final class RepositoryCacheManager {
	static let shared = RepositoryCacheManager()
	
	private let cacheDirectory: URL
	private let fileManager = FileManager.default
	private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
	
	private init() {
		let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
		cacheDirectory = cachesDirectory.appendingPathComponent("RepositoryCache", isDirectory: true)
		
		// Create cache directory if it doesn't exist
		try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
	}
	
	private func cacheFilePath(for url: URL) -> URL {
		let fileName = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "unknown"
		return cacheDirectory.appendingPathComponent(fileName).appendingPathExtension("json")
	}
	
	func cacheRepository(_ repository: ASRepository, for url: URL) {
		let filePath = cacheFilePath(for: url)
		
		do {
			let encoder = JSONEncoder()
			let data = try encoder.encode(repository)
			try data.write(to: filePath)
		} catch {
			print("Failed to cache repository: \(error)")
		}
	}
	
	func getCachedRepository(for url: URL) -> ASRepository? {
		let filePath = cacheFilePath(for: url)
		
		guard fileManager.fileExists(atPath: filePath.path) else {
			return nil
		}
		
		// Check if cache is expired
		if let attributes = try? fileManager.attributesOfItem(atPath: filePath.path),
		   let modificationDate = attributes[.modificationDate] as? Date {
			if Date().timeIntervalSince(modificationDate) > cacheExpirationInterval {
				// Cache expired, remove it
				try? fileManager.removeItem(at: filePath)
				return nil
			}
		}
		
		do {
			let data = try Data(contentsOf: filePath)
			let decoder = JSONDecoder()
			let repository = try decoder.decode(ASRepository.self, from: data)
			return repository
		} catch {
			print("Failed to load cached repository: \(error)")
			// If decoding fails, remove the corrupted cache file
			try? fileManager.removeItem(at: filePath)
			return nil
		}
	}
	
	func clearCache() {
		try? fileManager.removeItem(at: cacheDirectory)
		try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
	}
}
