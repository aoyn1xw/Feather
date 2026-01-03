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
		let maxOrder = (try? context.fetch(request).first?.order ?? -1) ?? -1
		
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
		// Create a snapshot of the original order in case we need to revert
		let originalOrders = sources.map { ($0, $0.order) }
		
		// Update the order
		for (index, source) in sources.enumerated() {
			source.order = Int16(index)
		}
		
		// Save with error handling
		do {
			try context.save()
		} catch {
			// Revert changes on failure
			for (source, originalOrder) in originalOrders {
				source.order = originalOrder
			}
			Logger.misc.error("Error reordering sources: \(error)")
			// Refresh context to ensure consistency
			context.rollback()
		}
	}
	
	/// Initialize order values for existing sources that don't have one
	/// This is called once on app launch to migrate existing data
	func initializeSourceOrders() {
		// Check if migration has already been done
		let migrationKey = "SourceOrderMigrationCompleted"
		guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
		
		let request: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \AltSource.date, ascending: true)]
		
		do {
			let sources = try context.fetch(request)
			
			// Check if any source has order == -1 (uninitialized)
			let needsInitialization = sources.contains { $0.order == -1 }
			
			if needsInitialization {
				for (index, source) in sources.enumerated() {
					source.order = Int16(index)
				}
				try context.save()
			}
			
			// Mark migration as complete
			UserDefaults.standard.set(true, forKey: migrationKey)
		} catch {
			Logger.misc.error("Error initializing source orders: \(error)")
			// Don't set migration flag if it failed - we'll try again next time
		}
	}
}
