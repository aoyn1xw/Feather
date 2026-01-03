import CoreData
import AltSourceKit
import OSLog

// MARK: - Class extension: Sources
extension Storage {
	/// Retrieve sources in an array, we don't normally need this in swiftUI but we have it for the copy sources action
	func getSources() -> [AltSource] {
		let request: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		return (try? context.fetch(request)) ?? []
	}
	
	func addSource(
		_ url: URL,
		name: String? = "Unknown",
		identifier: String,
		iconURL: URL? = nil,
		deferSave: Bool = false,
		completion: @escaping (Error?) -> Void
	) {
		if sourceExists(identifier) {
			completion(nil)
			Logger.misc.debug("ignoring \(identifier)")
			return
		}
		
		// Get the maximum order value from existing sources
		let request: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \AltSource.order, ascending: false)]
		request.fetchLimit = 1
		let maxOrder = (try? context.fetch(request).first?.order ?? 0) ?? 0
		
		let new = AltSource(context: context)
		new.name = name
		new.date = Date()
		new.identifier = identifier
		new.sourceURL = url
		new.iconURL = iconURL
		new.order = maxOrder + 1
		
		do {
			if !deferSave {
				try context.save()
				HapticsManager.shared.impact()
			}
			completion(nil)
		} catch {
			completion(error)
		}
	}
	
	func addSource(
		_ url: URL,
		repository: ASRepository,
		id: String = "",
		deferSave: Bool = false,
		completion: @escaping (Error?) -> Void
	) {
		addSource(
			url,
			name: repository.name,
			identifier: !id.isEmpty
						? id
						: (repository.id ?? url.absoluteString),
			iconURL: repository.currentIconURL,
			deferSave: deferSave,
			completion: completion
		)
	}

	func addSources(
		repos: [URL: ASRepository],
		completion: @escaping (Error?) -> Void
	) {
		
		for (url, repo) in repos {
			addSource(
				url,
				repository: repo,
				deferSave: true,
				completion: { error in
					if let error {
						completion(error)
					}
				}
			)
		}
		
		saveContext()
		HapticsManager.shared.impact()
		completion(nil)
	}

	func deleteSource(for source: AltSource) {
		context.delete(source)
		saveContext()
	}

	func sourceExists(_ identifier: String) -> Bool {
		let fetchRequest: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)

		do {
			let count = try context.count(for: fetchRequest)
			return count > 0
		} catch {
			Logger.misc.error("Error checking if repository exists: \(error)")
			return false
		}
	}
	
	func reorderSources(_ sources: [AltSource]) {
		for (index, source) in sources.enumerated() {
			source.order = Int16(index)
		}
		saveContext()
	}
	
	/// Initialize order values for existing sources that don't have one
	func initializeSourceOrders() {
		let request: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \AltSource.date, ascending: true)]
		
		guard let sources = try? context.fetch(request) else { return }
		
		// Check if any source has order == 0 (uninitialized)
		let needsInitialization = sources.contains { $0.order == 0 }
		
		if needsInitialization {
			for (index, source) in sources.enumerated() {
				source.order = Int16(index)
			}
			saveContext()
		}
	}
}
